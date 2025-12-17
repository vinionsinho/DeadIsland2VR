local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}
--local printDebug = false

local BASE_LERP_SPEED   = 10      -- minimum lerp speed
local MAX_LERP_SPEED    = 150     -- maximum lerp speed
local SPEED_SCALE       = 5       -- multiplier for head velocity

local minAngularDeviation = 50  -- Minimum yaw difference to trigger rotation. Prevents small movements of the head from triggering body rotation

-- alignConfidenceThreshold is the minimum confidence value required to trigger body yaw alignment. It acts as a gatekeeper for gesture 
-- intent ensuring that the body only begins rotating when the hands are clearly aligned with the head’s facing direction.
-- Confidence is calculated using the dot product between:
-- - The vector from left hand to right hand (projected onto the XY plane, Unreal-style)
-- - The head’s forward vector (also projected onto the XY plane)
-- This dot product ranges from -1 to 1, where:
-- 	1.0 Hand span is strongly aligned with head yaw
-- 	0.0 Hand span is orthogonal to head yaw
-- 	-1.0 Hand span is opposite to head yaw
local alignConfidenceThreshold = 0.8   -- Dot product threshold for alignment
--local motionConfidenceThreshold = 0.7

-- ALIGN_THRESHOLD is the snap-to-stop threshold for body yaw alignment. It defines how close the body yaw must be to the headset
-- yaw before the system considers the alignment "good enough" and stops lerping.
-- When the body is rotating to match the headset, you don’t want it to endlessly chase tiny differences—like 0.1° of drift. That would cause:
-- • 	Visual jitter
-- • 	Unnecessary micro-adjustments
-- • 	Wasted computation
-- So  sets a dead zone: once the body yaw is within, say, 0.5° of the headset yaw, the system snaps to the target and stops smoothing.
local ALIGN_THRESHOLD   = 3.0     -- degrees to stop lerping

local configWidgets = spliceableInlineArray{
	-- {
		-- widgetType = "slider_int",
		-- id = "alignThreshhold",
		-- label = "Align Threshhold",
		-- speed = 0.1,
		-- range = {0, 100},
		-- initialValue = 80
	-- },
	{
		widgetType = "slider_int",
		id = "minAngularDeviation",
		label = "Min Angular Deviation",
		speed = 1.0,
		range = {1, 90},
		initialValue = minAngularDeviation
	},
	{
		widgetType = "slider_float",
		id = "alignConfidenceThreshold",
		label = "Align Confidence Threshold",
		speed = 0.01,
		range = {0, 1},
		initialValue = alignConfidenceThreshold
	},
	-- {
		-- widgetType = "slider_float",
		-- id = "motionConfidenceThreshold",
		-- label = "Motion Confidence Threshold",
		-- speed = 0.01,
		-- range = {0, 1},
		-- initialValue = motionConfidenceThreshold
	-- },
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[bodyyaw] " .. text, logLevel)
	end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.setAlignmentConfidenceThreshold(val)
	alignConfidenceThreshold = val
end
function M.setMinAngularDeviation(val)
	minAngularDeviation = val
end
-- function M.setMotionConfidenceThreshold(val)
	-- motionConfidenceThreshold = val
-- end

configui.onCreateOrUpdate("alignConfidenceThreshold", function(value)
	M.setAlignmentConfidenceThreshold(value)
end)

configui.onCreateOrUpdate("minAngularDeviation", function(value)
	M.setMinAngularDeviation(value)
end)

-- configui.onCreateOrUpdate("motionConfidenceThreshold", function(value)
	-- M.setMotionConfidenceThreshold(value)
-- end)


-- Persistent state
local lerping = false
local prevHeadsetYaw = nil
local prevHeadPos, prevLeftHandPos, prevRightHandPos = nil, nil, nil

local function normalizeYaw(yaw)
    return uevrUtils.clampAngle180(yaw)
end

local function angularDifference(a, b)
    return normalizeYaw(b - a)
end

local function lerpAngle(current, target, alpha)
    local diff = angularDifference(current, target)
    return normalizeYaw(current + diff * alpha)
end

local function normalize2D(v)
    local mag = math.sqrt(v.x^2 + v.y^2)
    if mag == 0 then return {x=0, y=0} end
    return { x = v.x / mag, y = v.y / mag }
end

local function dot2D(a, b)
    return a.x * b.x + a.y * b.y
end


-- Position-based confidence: average hand position vs head forward
local function positionAlignmentConfidence(headPos, leftHandPos, rightHandPos, headForward)
    local avgHandPos = {
        x = (leftHandPos.x + rightHandPos.x) / 2,
        y = (leftHandPos.y + rightHandPos.y) / 2
    }

    local headToHands = {
        x = avgHandPos.x - headPos.x,
        y = avgHandPos.y - headPos.y
    }

    local nHeadToHands = normalize2D(headToHands)
    local nForward = normalize2D({ x = headForward.x, y = headForward.y })

    return dot2D(nHeadToHands, nForward)
end


local MIN_HEAD_YAW_VELOCITY = 5          -- degrees/sec
local MIN_HAND_ANGULAR_VELOCITY = 0.1    -- radians/sec
local MAX_HAND_TO_HEAD_RATIO = 30

local function signedAngularVelocity(center, prevPos, currPos, deltaTime)
    local r = { x = currPos.x - center.x, y = currPos.y - center.y }
    local v = { x = currPos.x - prevPos.x, y = currPos.y - prevPos.y }

    local rMagSq = r.x^2 + r.y^2
    if rMagSq == 0 then return 0 end

    local cross = r.x * v.y - r.y * v.x
    return cross / rMagSq / deltaTime
end

local function isRotationSynchronized(headsetYaw, prevHeadsetYaw, headPos, leftHandPos, prevLeftHandPos, rightHandPos, prevRightHandPos, deltaTime)
    if not (prevHeadsetYaw and prevLeftHandPos and prevRightHandPos) then
        return false
    end

    -- Head angular velocity
    local headYawVel = angularDifference(prevHeadsetYaw, headsetYaw) / deltaTime
    local headYawDir = headYawVel >= 0 and 1 or -1
    local absHeadYawVel = math.abs(headYawVel)

    if absHeadYawVel < MIN_HEAD_YAW_VELOCITY then
        return false
    end

    -- Hand angular velocities around head
    local leftAngularVel = signedAngularVelocity(headPos, prevLeftHandPos, leftHandPos, deltaTime)
    local rightAngularVel = signedAngularVelocity(headPos, prevRightHandPos, rightHandPos, deltaTime)

    local avgHandAngularVel = (leftAngularVel + rightAngularVel) / 2
    local handDir = avgHandAngularVel >= 0 and 1 or -1
    local absHandAngularVel = math.abs(avgHandAngularVel)

    -- Directional agreement
    local directionAligned = headYawDir == handDir

    -- Velocity ratio check
    local ratio = absHandAngularVel / absHeadYawVel
    local velocityAligned = absHandAngularVel > MIN_HAND_ANGULAR_VELOCITY and ratio <= MAX_HAND_TO_HEAD_RATIO

    return directionAligned and velocityAligned
end


-- uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	-- printDebug = false
	-- if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_X) then
		-- printDebug = true
	-- end
-- end)


function M.update(bodyYaw, headsetYaw, deltaTime)
    bodyYaw = normalizeYaw(bodyYaw)
    headsetYaw = normalizeYaw(headsetYaw)

    -- Estimate headset angular velocity
    local headVelocity = 0
    if prevHeadsetYaw then
        headVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    end
    prevHeadsetYaw = headsetYaw

    -- Compute dynamic lerp speed
    local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headVelocity * SPEED_SCALE)

    local diff = angularDifference(bodyYaw, headsetYaw)
    local absDiff = math.abs(diff)

    if lerping then
        if absDiff <= ALIGN_THRESHOLD then
            lerping = false
            return headsetYaw
        else
            local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
            return lerpAngle(bodyYaw, headsetYaw, alpha)
        end
    elseif absDiff >= minAngularDeviation then
        lerping = true
        local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
        return lerpAngle(bodyYaw, headsetYaw, alpha)
    else
        return bodyYaw
    end
end

function M.updateAdvanced(bodyYaw, headsetYaw, headPos, leftHandPos, rightHandPos, deltaTime)
	if headsetYaw == nil or headPos == nil or leftHandPos == nil or rightHandPos == nil then
		return bodyYaw
	end
	
    bodyYaw = normalizeYaw(bodyYaw)
    headsetYaw = normalizeYaw(headsetYaw)

    -- Head angular velocity
    local headAngularVelocity = 0
    if prevHeadsetYaw then
        headAngularVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    end

    -- Dynamic lerp speed
    local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headAngularVelocity * SPEED_SCALE)

    -- Confidence checks
    local confidence = positionAlignmentConfidence(headPos, leftHandPos, rightHandPos, uevrUtils.getForwardVector(uevrUtils.rotator(0,headsetYaw,0)))
	local rotationSynced = isRotationSynchronized( headsetYaw, prevHeadsetYaw, headPos, leftHandPos, prevLeftHandPos, rightHandPos, prevRightHandPos, deltaTime )
--print(rotationSynced)
    -- Update previous positions
    prevHeadsetYaw = headsetYaw
    prevHeadPos = headPos
    prevLeftHandPos = leftHandPos
    prevRightHandPos = rightHandPos

    local diff = angularDifference(bodyYaw, headsetYaw)
    local absDiff = math.abs(diff)
--print(confidence,alignConfidenceThreshold,rotationSynced)
    local shouldRotate = (confidence >= alignConfidenceThreshold or rotationSynced)

    if lerping then
        if absDiff <= ALIGN_THRESHOLD then
            lerping = false
            return headsetYaw
        else
            local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, minAngularDeviation))
            return lerpAngle(bodyYaw, headsetYaw, alpha)
        end
    elseif shouldRotate then
        -- If rotation is synced, skip angular deviation check
        if rotationSynced or absDiff >= minAngularDeviation then
            lerping = true
            local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, minAngularDeviation))
            return lerpAngle(bodyYaw, headsetYaw, alpha)
        end
    end

    return bodyYaw
end

return M


-- -----------------------
-- local MAX_DEVIATION     = 40      -- degrees to trigger lerp
-- local ALIGN_THRESHOLD   = 0.5     -- degrees to stop lerping
-- local BASE_LERP_SPEED   = 10      -- minimum lerp speed
-- local MAX_LERP_SPEED    = 150     -- maximum lerp speed
-- local SPEED_SCALE       = 5       -- multiplier for head velocity

-- -- Persistent state
-- local lerping = false
-- local prevHeadsetYaw = nil

-- local function normalizeYaw(yaw)
    -- yaw = yaw % 360
    -- if yaw > 180 then yaw = yaw - 360 end
    -- return yaw
-- end

-- local function angularDifference(a, b)
    -- return normalizeYaw(b - a)
-- end

-- local function lerpAngle(current, target, alpha)
    -- local diff = angularDifference(current, target)
    -- return normalizeYaw(current + diff * alpha)
-- end

-- function UpdateBodyYaw(bodyYaw, headsetYaw, deltaTime)
    -- bodyYaw = normalizeYaw(bodyYaw)
    -- headsetYaw = normalizeYaw(headsetYaw)

    -- -- Estimate headset angular velocity
    -- local headVelocity = 0
    -- if prevHeadsetYaw then
        -- headVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    -- end
    -- prevHeadsetYaw = headsetYaw

    -- -- Compute dynamic lerp speed
    -- local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headVelocity * SPEED_SCALE)

    -- local diff = angularDifference(bodyYaw, headsetYaw)
    -- local absDiff = math.abs(diff)

    -- if lerping then
        -- if absDiff <= ALIGN_THRESHOLD then
            -- lerping = false
            -- return headsetYaw
        -- else
            -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
            -- return lerpAngle(bodyYaw, headsetYaw, alpha)
        -- end
    -- elseif absDiff >= MAX_DEVIATION then
        -- lerping = true
        -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
        -- return lerpAngle(bodyYaw, headsetYaw, alpha)
    -- else
        -- return bodyYaw
    -- end
-- end

	-- -- -- ALIGN_CONFIDENCE_THRESHOLD = configui.getValue("alignConfidenceThreshhold") / 100
	-- -- -- ALIGN_THRESHOLD = configui.getValue("alignThreshhold") / 100

-- -- Configurable parameters
-- -- ALIGN_CONFIDENCE_THRESHOLD is the minimum confidence value required to trigger body yaw alignment. It acts as a gatekeeper for gesture 
-- -- intent ensuring that the body only begins rotating when the hands are clearly aligned with the head’s facing direction.
-- -- What It Measures
-- -- Confidence is calculated using the dot product between:
-- -- - The vector from left hand to right hand (projected onto the XY plane, Unreal-style)
-- -- - The head’s forward vector (also projected onto the XY plane)
-- -- This dot product ranges from -1 to 1, where:
-- -- 	1.0 Hand span is strongly aligned with head yaw
-- -- 	0.0 Hand span is orthogonal to head yaw
-- -- 	-1.0 Hand span is opposite to head yaw
-- local ALIGN_CONFIDENCE_THRESHOLD = 0.8   -- Dot product threshold for alignment
-- local MIN_ANGULAR_DEVIATION = 15         -- Minimum yaw difference to trigger rotation
-- -- ALIGN_THRESHOLD is the snap-to-stop threshold for body yaw alignment. It defines how close the body yaw must be to the headset
-- -- yaw before the system considers the alignment “good enough” and stops lerping.
-- -- Why It Matters
-- -- When the body is rotating to match the headset, you don’t want it to endlessly chase tiny differences—like 0.1° of drift. That would cause:
-- -- • 	Visual jitter
-- -- • 	Unnecessary micro-adjustments
-- -- • 	Wasted computation
-- -- So  sets a dead zone: once the body yaw is within, say, 0.5° of the headset yaw, the system snaps to the target and stops smoothing.
-- -- local ALIGN_THRESHOLD = 0.5              -- Degrees to stop lerping
-- -- local BASE_LERP_SPEED = 10               -- Minimum lerp speed
-- -- local MAX_LERP_SPEED = 150               -- Maximum lerp speed
-- -- local SPEED_SCALE = 5                    -- Multiplier for head angular velocity

-- -- Persistent state
-- -- local prevHeadsetYaw = nil
-- -- local lerping = false

-- -- Utility functions
-- -- local function normalizeYaw(yaw)
    -- -- yaw = yaw % 360
    -- -- if yaw > 180 then yaw = yaw - 360 end
    -- -- return yaw
-- -- end

-- -- local function angularDifference(a, b)
    -- -- return normalizeYaw(b - a)
-- -- end

-- -- local function lerpAngle(current, target, alpha)
    -- -- local diff = angularDifference(current, target)
    -- -- return normalizeYaw(current + diff * alpha)
-- -- end

-- local function normalize2D(v)
    -- local mag = math.sqrt(v.x^2 + v.y^2)
    -- if mag == 0 then return {x=0, y=0} end
    -- return { x = v.x / mag, y = v.y / mag }
-- end

-- local function dot2D(a, b)
    -- return a.x * b.x + a.y * b.y
-- end

-- -- Position-based confidence: average hand position vs head forward
-- local function positionAlignmentConfidence(headPos, leftHandPos, rightHandPos, headForward)
    -- local avgHandPos = {
        -- x = (leftHandPos.x + rightHandPos.x) / 2,
        -- y = (leftHandPos.y + rightHandPos.y) / 2
    -- }

    -- local headToHands = {
        -- x = avgHandPos.x - headPos.x,
        -- y = avgHandPos.y - headPos.y
    -- }

    -- local nHeadToHands = normalize2D(headToHands)
    -- local nForward = normalize2D({ x = headForward.x, y = headForward.y })

    -- return dot2D(nHeadToHands, nForward)
-- end


-- function UpdateBodyYaw_Advanced(bodyYaw, headsetYaw, headPos, leftHandPos, rightHandPos, headForward, deltaTime)
	-- ALIGN_CONFIDENCE_THRESHOLD = configui.getValue("alignConfidenceThreshhold") / 100
	-- ALIGN_THRESHOLD = configui.getValue("alignThreshhold") / 100
	-- MIN_ANGULAR_DEVIATION = configui.getValue("minAngularDeviation")
	
    -- bodyYaw = normalizeYaw(bodyYaw)
    -- headsetYaw = normalizeYaw(headsetYaw)

    -- -- Estimate headset angular velocity
    -- local headAngularVelocity = 0
    -- if prevHeadsetYaw then
        -- headAngularVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    -- end
    -- prevHeadsetYaw = headsetYaw

    -- -- Compute dynamic lerp speed
    -- local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headAngularVelocity * SPEED_SCALE)

    -- -- Compute position-based alignment confidence
    -- local confidence = positionAlignmentConfidence(headPos, leftHandPos, rightHandPos, headForward)
	-- print(confidence)

    -- local diff = angularDifference(bodyYaw, headsetYaw)
    -- local absDiff = math.abs(diff)

    -- local shouldRotate = confidence >= ALIGN_CONFIDENCE_THRESHOLD and absDiff >= MIN_ANGULAR_DEVIATION

    -- if lerping then
        -- if absDiff <= ALIGN_THRESHOLD then
            -- lerping = false
            -- return headsetYaw
        -- else
            -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, MIN_ANGULAR_DEVIATION))
            -- return lerpAngle(bodyYaw, headsetYaw, alpha)
        -- end
    -- elseif shouldRotate then
        -- lerping = true
        -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, MIN_ANGULAR_DEVIATION))
        -- return lerpAngle(bodyYaw, headsetYaw, alpha)
    -- else
        -- return bodyYaw
    -- end
-- end

-----------------------

-- local function normalize2D(v)
    -- local mag = math.sqrt(v.X * v.X + v.Y * v.Y)
    -- if mag == 0 then return {X = 1, Y = 0} end
    -- return {X = v.X / mag, Y = v.Y / mag}
-- end

-- local function dot2D(a, b)
    -- return a.X * b.X + a.Y * b.Y
-- end

-- local function cross2D(a, b)
    -- return a.X * b.Y - a.Y * b.X
-- end

-- local function midpoint(a, b)
    -- return {
        -- X = (a.X + b.X) * 0.5,
        -- Y = (a.Y + b.Y) * 0.5,
        -- Z = (a.Z + b.Z) * 0.5
    -- }
-- end

-- local function radiansToDegrees(rad)
    -- return rad * (180 / math.pi)
-- end

-- local function computeRelativeYaw(headPos, headForward, leftHand, rightHand)
    -- if not headPos or not headForward or not leftHand or not rightHand then
        -- return nil -- Safe fallback
    -- end

    -- local handMid = midpoint(leftHand, rightHand)
    -- local handDir = {
        -- X = handMid.X - headPos.X,
        -- Y = handMid.Y - headPos.Y
    -- }

    -- local fwd = normalize2D(headForward)
    -- local handVec = normalize2D(handDir)

    -- local dot = dot2D(fwd, handVec)
    -- local cross = cross2D(fwd, handVec)

    -- local angleRad = math.atan(cross, dot) -- Relative angle
    -- return -radiansToDegrees(angleRad)
-- end

-- local function shortestYawDelta(currentYaw, targetYaw)
    -- local delta = targetYaw - currentYaw
    -- delta = (delta + 180) % 360 - 180
    -- return delta
-- end
