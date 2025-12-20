local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")

local reloadTriggerDistance = 20.0
local earGripTriggerDistance = 25.0
local earGripForwardDotThreshold = 0.8
local mouthTriggerDistance = 25.0
local mouthForwardDotMaxThreshold = 0.65
local mouthForwardDotMinThreshold = 0.35
local headTriggerDistance = 20.0
local headForwardDotMaxThreshold = 0.65
local headForwardDotMinThreshold = 0.0
local eyesTriggerDistance = 15.0
local eyesForwardDotThreshold = 0.85
local holsterTriggerAngle = -65.0

local M = {}

M.Gesture = 
{
	PUNCH = 0,
	HOLSTER = 1,
	RELOAD = 2,
	EARGRAB = 3,
	EAT = 4,
	GLASSESGRAB = 5,
	HATGRAB = 6,
	EARSCRATCH = 7,
	HEADSCRATCH = 8,
	LIPSCRATCH = 9,
	EYESCRATCH = 10,
	SWIPE_LEFT = 11,
	SWIPE_RIGHT = 12,
	SWIPE_UP = 13,
	SWIPE_DOWN = 14,
	SNATCH = 15,
	GRIP_COMPONENT = 16,
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[gestures] " .. text, logLevel)
	end
end

local autoDetect = {}
local hasPunchGesture = false
local punchStrengthPercent = 0
local hasSwipeLeft = false
local hasSwipeRight = false
local hasSwipeUp = false
local hasSwipeDown = false
local hasSnatch = false
local swipeStrengthPercent = 0

local punchDetector = {
    prevLocalPos = nil,
    cooldown = 0,
    minThresholdSpeed = 180, -- units/sec min speed needed to register as a punch
    maxThresholdSpeed = 320, -- units/sec speed at which a punch is cosidered hardest. Use max-min to get a scale of hardness
    forwardDotThreshold = 0.75,
    cooldownTime = 0.8,
	currentPunchSpeed = 0.0
}

-- local function degToRad(deg)
    -- return deg * math.pi / 180
-- end

-- local function rotatorToMatrix(rotator)
    -- local Pitch = degToRad(rotator.Pitch)
    -- local Yaw   = degToRad(rotator.Yaw)
    -- local Roll  = degToRad(rotator.Roll)

    -- local cosP, sinP = math.cos(Pitch), math.sin(Pitch)
    -- local cosY, sinY = math.cos(Yaw), math.sin(Yaw)
    -- local cosR, sinR = math.cos(Roll), math.sin(Roll)

    -- local matrix = {
        -- {
            -- cosY * cosR,
            -- cosY * sinR,
            -- -sinY
        -- },
        -- {
            -- sinP * sinY * cosR - cosP * sinR,
            -- sinP * sinY * sinR + cosP * cosR,
            -- sinP * cosY
        -- },
        -- {
            -- cosP * sinY * cosR + sinP * sinR,
            -- cosP * sinY * sinR - sinP * cosR,
            -- cosP * cosY
        -- }
    -- }
    -- return matrix
-- end

-- local function rotateVector(vector, m)
    -- --local m = rotatorToMatrix(rotator)
    -- return {
        -- X = vector.X * m[1][1] + vector.Y * m[1][2] + vector.Z * m[1][3],
        -- Y = vector.X * m[2][1] + vector.Y * m[2][2] + vector.Z * m[2][3],
        -- Z = vector.X * m[3][1] + vector.Y * m[3][2] + vector.Z * m[3][3]
    -- }
-- end

local function rotationToForwardVector(rot)
    local pitchRad = math.rad(rot.Pitch)
    local yawRad = math.rad(rot.Yaw)
    return {
        X = math.cos(pitchRad) * math.cos(yawRad),
        Y = math.cos(pitchRad) * math.sin(yawRad),
        Z = math.sin(pitchRad)
    }
end

local function subtract(a, b)
    return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
end

local function magnitude(v)
    return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z)
end

local function normalize(v)
    local mag = magnitude(v)
    if mag == 0 then return {X=0, Y=0, Z=0} end
    return { X = v.X / mag, Y = v.Y / mag, Z = v.Z / mag }
end

local function dot(a, b)
    return a.X*b.X + a.Y*b.Y + a.Z*b.Z
end

-- Rotate a vector by negative yaw to get local space
local function rotateVectorInverseYaw(vec, yawDeg)
    local yawRad = -math.rad(yawDeg)
    local cosY = math.cos(yawRad)
    local sinY = math.sin(yawRad)
    return {
        X = vec.X * cosY - vec.Y * sinY,
        Y = vec.X * sinY + vec.Y * cosY,
        Z = vec.Z -- Z remains unchanged for yaw-only
    }
end

local function getLocalForwardVector(controllerRot, pawnRot)
    return rotationToForwardVector({
        Pitch = controllerRot.Pitch,
        Yaw = controllerRot.Yaw - pawnRot.Yaw,
        Roll = controllerRot.Roll
    })
end

-- Get controller position relative to pawn
local function getLocalControllerPos(controllerPos, pawnPos, pawnRot)
    local offset = subtract(controllerPos, pawnPos)
    return rotateVectorInverseYaw(offset, pawnRot.Yaw)
end

local function getSpeedPercent(speed, minThresholdSpeed, maxThresholdSpeed)
    if maxThresholdSpeed == minThresholdSpeed then
        return 0 -- avoid division by zero
    end
    local clampedSpeed = math.max(minThresholdSpeed, math.min(speed, maxThresholdSpeed))
    return (clampedSpeed - minThresholdSpeed) / (maxThresholdSpeed - minThresholdSpeed)
end

function punchDetector:update(controllerPos, controllerRot, pawnPos, pawnRot, deltaTime)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - deltaTime
 		self.prevLocalPos = getLocalControllerPos(controllerPos, pawnPos, pawnRot)
       return false, 0, 0
    end

    if not self.prevLocalPos then
 		self.prevLocalPos = getLocalControllerPos(controllerPos, pawnPos, pawnRot)
        return false, 0, 0
    end
	
	local localPos = getLocalControllerPos(controllerPos, pawnPos, pawnRot)
	
    local localDelta = subtract(localPos, self.prevLocalPos)
    local speed = magnitude(localDelta) / deltaTime
    --local forward = rotationToForwardVector(controllerRot)
	local forward = getLocalForwardVector(controllerRot, pawnRot)
    local motionDir = normalize(localDelta)
    local forwardDot = dot(forward, motionDir)

	local isPunch = false
	local punchSpeed = 0
	local punchSpeedPercent = 0
    local punchDetected = speed > self.minThresholdSpeed and forwardDot > self.forwardDotThreshold
	if self.currentPunchSpeed > 0 or punchDetected then
		if speed > self.currentPunchSpeed then
			self.currentPunchSpeed = speed
		else
			isPunch = true
			punchSpeed = self.currentPunchSpeed
			punchSpeedPercent = getSpeedPercent(punchSpeed, self.minThresholdSpeed, self.maxThresholdSpeed)
			self.currentPunchSpeed = 0
		end
	end

    if isPunch then
		--print(punchSpeed, forwardDot, punchSpeedPercent)
        self.cooldown = self.cooldownTime
    end

    -- Update history
    self.prevLocalPos = localPos

    return isPunch, punchSpeedPercent, punchSpeed
end

local swipeDetector = {
    prevControllerPos = nil,
    prevPawnPos = nil,
    prevPawnRot = nil,
    cooldown = 0,
    minThresholdSpeed = 180, -- units/sec min speed needed to register as a swipe
    maxThresholdSpeed = 320, -- units/sec speed at which a swipe is considered strongest
    directionThreshold = 0.001, -- minimum component magnitude to count as swipe direction (very small = any significant movement)
    cooldownTime = 0.5,
	peakMotionVector = nil,
	peakSpeed = 0
}

function swipeDetector:update(controllerPos, controllerRot, pawnPos, pawnRot, deltaTime)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - deltaTime
 		self.prevControllerPos = controllerPos
 		self.prevPawnPos = pawnPos
       return false, false, false, false, false, false, 0
    end

    if not self.prevControllerPos or not self.prevPawnPos or not self.prevPawnRot then
 		self.prevControllerPos = controllerPos
 		self.prevPawnPos = pawnPos
 		self.prevPawnRot = pawnRot
        return false, false, false, false, false, false, 0
    end
	
	local controllerDelta = subtract(controllerPos, self.prevControllerPos)
	local pawnDelta = subtract(pawnPos, self.prevPawnPos)
	
	-- Skip detection if it looks like a snap turn (sudden large rotation)
	if math.abs(pawnRot.Yaw - self.prevPawnRot.Yaw) > math.rad(45) then
		self.prevControllerPos = controllerPos
		self.prevPawnPos = pawnPos
		self.prevPawnRot = pawnRot
		return false, false, false, false, false, false, 0
	end
	
    local localDelta = subtract(controllerDelta, pawnDelta)
    local speed = magnitude(localDelta) / deltaTime
    local motionDir = normalize(localDelta)

	local isSwipeLeft = false
	local isSwipeRight = false
	local isSwipeUp = false
	local isSwipeDown = false
	local isPunch = false
	local isSnatch = false
	
	local swipeSpeedPercent = 0
	
	-- Track peak motion during acceleration
	local swipeDetected = false
	if speed > self.minThresholdSpeed then
		if speed > self.peakSpeed then
			self.peakSpeed = speed
			self.peakMotionVector = motionDir
		end
		swipeDetected = true
	end
	
	-- Check if movement has peaked and is now slowing down
	if not swipeDetected and self.peakSpeed > 0 and self.peakMotionVector then
		-- Analyze the peak motion vector for directional components
		local peakVector = self.peakMotionVector
		
		-- Always classify horizontal (left/right) - use sign of Y component, default to right if Y ≈ 0
		if peakVector and peakVector.Y < -self.directionThreshold then
			isSwipeLeft = true
		else
			isSwipeRight = true  -- Default to right for Y >= -threshold
		end
		
		-- Always classify vertical (up/down) - use sign of Z component, default to up if Z ≈ 0
		if peakVector and peakVector.Z > self.directionThreshold then
			isSwipeUp = true
		else
			isSwipeDown = true  -- Default to down for Z <= threshold
		end
		
		-- Check forward/backward components (punch/snatch) - only if significant
		if peakVector and math.abs(peakVector.X) > self.directionThreshold then
			if peakVector.X > 0 then
				isPunch = true
			else
				isSnatch = true
			end
		end
		
		swipeSpeedPercent = getSpeedPercent(self.peakSpeed, self.minThresholdSpeed, self.maxThresholdSpeed)
		
		-- Reset for next gesture
		self.peakSpeed = 0
		self.peakMotionVector = nil
	end

    if isSwipeLeft or isSwipeRight or isSwipeUp or isSwipeDown or isPunch or isSnatch then
        self.cooldown = self.cooldownTime
    end

    -- Update history
    self.prevControllerPos = controllerPos
    self.prevPawnPos = pawnPos
    self.prevPawnRot = pawnRot

    return isSwipeLeft, isSwipeRight, isSwipeUp, isSwipeDown, isPunch, isSnatch, swipeSpeedPercent
end

local holsterGripOn = false
local function detectHolster(state, hand, continuous)
	local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	end
	if (continuous == true or not holsterGripOn) and uevrUtils.isButtonPressed(state, gripButton) then
		holsterGripOn = true
		local rotation = controllers.getControllerRotation(hand)
		--print(rotation.Pitch,rotation.Yaw,rotation.Roll)
		--only holster if the hand is pointing down
		if rotation ~= nil and rotation.Pitch < holsterTriggerAngle then
			return true
		end
	elseif holsterGripOn and uevrUtils.isButtonNotPressed(state, gripButton)  then
		holsterGripOn = false
	end
	return false
end

local reloadGripOn = false
local function detectReload(state, hand, continuous)
	local gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	end
	if (continuous == true or not reloadGripOn) and uevrUtils.isButtonPressed(state, gripButton) then
		reloadGripOn = true
		local gripLocation = controllers.getControllerLocation(1-hand)
		local targetLocation = controllers.getControllerLocation(hand)
		if gripLocation ~= nil and targetLocation ~= nil then
			local distance = magnitude(subtract(gripLocation, targetLocation))
			--print(distance)
			--only reload if one hand is close to the other when grip is pulled
			if distance < reloadTriggerDistance then
				return true
			end
		end
	elseif reloadGripOn and uevrUtils.isButtonNotPressed(state, gripButton) then
		reloadGripOn = false
	end
	return false
end

-- local earGrabGripOn = false
-- function detectEarGrab(state, hand, continuous)
	-- local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	-- if hand == Handed.Left then
		-- gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	-- end
	-- if (continuous == true or not earGrabGripOn) and uevrUtils.isButtonPressed(state, gripButton)  then
		-- earGrabGripOn = true
		-- local headLocation = controllers.getControllerLocation(2)
		-- local handLocation = controllers.getControllerLocation(hand)
		-- if headLocation ~= nil and handLocation ~= nil then
			-- local headRightVector = controllers.getControllerRightVector(2)
			-- local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			-- local forwardDot = dot(headRightVector, headToHandForwardVector) * (hand == Handed.Left and -1 or 1)
			-- local distance = magnitude(subtract(handLocation, headLocation))
			-- --local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			-- --print(distance,forwardDot)
			-- if distance < earGripTriggerDistance and forwardDot > earGripForwardDotThreshold then	
				-- return true
			-- end
		-- end
	-- elseif earGrabGripOn and uevrUtils.isButtonNotPressed(state, gripButton) then
		-- earGrabGripOn = false
	-- end
	-- return false
-- end

local headGripOn = false
local function detectFace(state, hand, continuous)
	local gripMouth, gripEyes, gripHead, gripEar = false, false, false, false
	local triggerMouth, triggerEyes, triggerHead, triggerEar = false, false, false, false
	
	local isGripped, isTriggerred = false, false
	if hand == Handed.Right then
		isGripped = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
		isTriggerred = state.Gamepad.bRightTrigger > 128
	else
		isGripped = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
		isTriggerred = state.Gamepad.bLeftTrigger > 128
	end
	
	local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	end
	if (continuous == true or not headGripOn) and (isGripped or isTriggerred)  then
		headGripOn = true
		local headLocation = controllers.getControllerLocation(2)
		local handLocation = controllers.getControllerLocation(hand)
		if headLocation ~= nil and handLocation ~= nil then
			local headForwardVector = controllers.getControllerDirection(2)
			local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			local forwardDot = dot(headForwardVector, headToHandForwardVector)
			local distance = magnitude(subtract(handLocation, headLocation))
			--local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			--print(distance, forwardDot, headLocation.Z-handLocation.Z)
			if distance < mouthTriggerDistance and forwardDot > mouthForwardDotMinThreshold and forwardDot < mouthForwardDotMaxThreshold and headLocation.Z-handLocation.Z > 0 then	
				gripMouth = isGripped
				triggerMouth = isTriggerred
			elseif distance < headTriggerDistance and forwardDot > headForwardDotMinThreshold and forwardDot < headForwardDotMaxThreshold and headLocation.Z-handLocation.Z < 0 then	
				gripHead = isGripped
				triggerHead = isTriggerred
			elseif distance < eyesTriggerDistance and forwardDot > eyesForwardDotThreshold then	
				gripEyes = isGripped
				triggerEyes = isTriggerred
			end		

			local headRightVector = controllers.getControllerRightVector(2)
			--local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			forwardDot = dot(headRightVector, headToHandForwardVector) * (hand == Handed.Left and -1 or 1)
			--local distance = magnitude(subtract(handLocation, headLocation))
			--local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			--print(distance,forwardDot)
			if distance < earGripTriggerDistance and forwardDot > earGripForwardDotThreshold then	
				gripEar = isGripped
				triggerEar = isTriggerred
			end
			
		end
	elseif headGripOn and not (isGripped or isTriggerred) then
		headGripOn = false
	end
	return gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar
end

function M.getGesture(id)
	if id == M.Gesture.PUNCH then
		 return hasPunchGesture, punchStrengthPercent
	elseif id == M.Gesture.SWIPE_LEFT then
		return hasSwipeLeft, swipeStrengthPercent
	elseif id == M.Gesture.SWIPE_RIGHT then
		return hasSwipeRight, swipeStrengthPercent
	elseif id == M.Gesture.SWIPE_UP then
		return hasSwipeUp, swipeStrengthPercent
	elseif id == M.Gesture.SWIPE_DOWN then
		return hasSwipeDown, swipeStrengthPercent
	elseif id == M.Gesture.SNATCH then
		return hasSnatch, swipeStrengthPercent
	end
end

function M.detectGesture(id, deltaTime, hand, currentPos, currentRot, pawnPos, pawnRot )
	if hand == nil then hand = Handed.Right end
	if currentPos == nil then 
		currentPos = controllers.getControllerLocation(hand)
	end
	if currentRot == nil then 
		currentRot = controllers.getControllerRotation(hand)
	end
	if pawnPos == nil then 
		pawnPos = controllers.getControllerLocation(2)
	end
	if pawnRot == nil then 
		pawnRot = controllers.getControllerRotation(2)
	end
	if currentPos == nil or currentRot == nil or pawnPos == nil or pawnRot == nil then
		M.print("Call to detectGesture() failed because controller was invalid")
		return false
	else
		if id == M.Gesture.PUNCH then
			 hasPunchGesture, punchStrengthPercent = punchDetector:update(currentPos, currentRot, pawnPos, pawnRot, deltaTime)
			 return hasPunchGesture, punchStrengthPercent
		elseif id == M.Gesture.SWIPE_LEFT or id == M.Gesture.SWIPE_RIGHT or id == M.Gesture.SWIPE_UP or 
		       id == M.Gesture.SWIPE_DOWN or id == M.Gesture.SNATCH then
			hasSwipeLeft, hasSwipeRight, hasSwipeUp, hasSwipeDown, _, hasSnatch, swipeStrengthPercent = swipeDetector:update(currentPos, currentRot, pawnPos, pawnRot, deltaTime)
			if id == M.Gesture.SWIPE_LEFT then
				return hasSwipeLeft, swipeStrengthPercent
			elseif id == M.Gesture.SWIPE_RIGHT then
				return hasSwipeRight, swipeStrengthPercent
			elseif id == M.Gesture.SWIPE_UP then
				return hasSwipeUp, swipeStrengthPercent
			elseif id == M.Gesture.SWIPE_DOWN then
				return hasSwipeDown, swipeStrengthPercent
			elseif id == M.Gesture.SNATCH then
				return hasSnatch, swipeStrengthPercent
			end
		end
	end
	return false
end

function M.detectGestureWithState(id, state, hand, continuous)
	if id == M.Gesture.HOLSTER then
		return detectHolster(state, hand, continuous)
	elseif id == M.Gesture.RELOAD then
		return detectReload(state, hand, continuous)
	elseif id == M.Gesture.EAT then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripMouth
	elseif id == M.Gesture.GLASSESGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripEyes
	elseif id == M.Gesture.HATGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripHead
	elseif id == M.Gesture.EARGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripEar
	elseif id == M.Gesture.LIPSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerMouth
	elseif id == M.Gesture.EYESCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerEyes
	elseif id == M.Gesture.HEADSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerHead
	elseif id == M.Gesture.EARSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerEar
	end
end

function M.detectComponentGrab(state, hand, component, maxDistance)
	if component ~= nil then
		if uevrUtils.isButtonPressed(state, hand == Handed.Left and XINPUT_GAMEPAD_LEFT_SHOULDER or XINPUT_GAMEPAD_RIGHT_SHOULDER) then 
			--check if the hand is close to a component
			local distance = controllers.getDistanceFromController(hand, component)
			--print(distance)
			if distance ~= nil and distance < (maxDistance or 10) then
				--print("Grabbing component")
				return true, distance
			end
		end
	end
	return false, nil
end

function M.getHeadGestures(state, hand, continuous)
	return detectFace(state, hand, continuous)
end

function M.getSwipeGestures(deltaTime, hand, currentPos, currentRot, pawnPos, pawnRot)
	if hand == nil then hand = Handed.Right end
	if currentPos == nil then 
		currentPos = controllers.getControllerLocation(hand)
	end
	if currentRot == nil then 
		currentRot = controllers.getControllerRotation(hand)
	end
	if pawnPos == nil then 
		pawnPos = controllers.getControllerLocation(2)
	end
	if pawnRot == nil then 
		pawnRot = controllers.getControllerRotation(2)
	end
	if currentPos == nil or currentRot == nil or pawnPos == nil or pawnRot == nil then
		return false, false, false, false, false, false, 0
	else
		return swipeDetector:update(currentPos, currentRot, pawnPos, pawnRot, deltaTime)
	end
end

function M.autoDetectGesture(id, val)
	if val == nil then val = true end
	autoDetect[id] = val
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if autoDetect[M.Gesture.PUNCH] == true then
		M.detectGesture(M.Gesture.PUNCH, delta)
	end
	if autoDetect[M.Gesture.SWIPE_LEFT] == true or autoDetect[M.Gesture.SWIPE_RIGHT] == true or autoDetect[M.Gesture.SWIPE_UP] == true or autoDetect[M.Gesture.SWIPE_DOWN] == true or autoDetect[M.Gesture.SNATCH] == true then
		local left, right, up, down, punch, snatch, strength = M.getSwipeGestures(delta)
		
		if left then uevrUtils.executeUEVRCallbacks("on_gesture_swipe_left", strength) end
		if right then uevrUtils.executeUEVRCallbacks("on_gesture_swipe_right", strength) end
		if up then uevrUtils.executeUEVRCallbacks("on_gesture_swipe_up", strength) end
		if down then uevrUtils.executeUEVRCallbacks("on_gesture_swipe_down", strength) end
		-- if left or right or up or down or punch or snatch then
		-- 	print("Swipe Left: "..tostring(left)..", Right: "..tostring(right)..", Up: "..tostring(up)..", Down: "..tostring(down)..", Punch: "..tostring(punch)..", Snatch: "..tostring(snatch)..", Strength: "..tostring(strength))
		-- end
	end
end)

function M.registerSwipeLeftCallback(callback)
	M.autoDetectGesture(M.Gesture.SWIPE_LEFT, true)
	uevrUtils.registerUEVRCallback("on_gesture_swipe_left", callback)
end
function M.registerSwipeRightCallback(callback)
	M.autoDetectGesture(M.Gesture.SWIPE_RIGHT, true)
	uevrUtils.registerUEVRCallback("on_gesture_swipe_right", callback)
end
function M.registerSwipeUpCallback(callback)
	M.autoDetectGesture(M.Gesture.SWIPE_UP, true)
	uevrUtils.registerUEVRCallback("on_gesture_swipe_up", callback)
end
function M.registerSwipeDownCallback(callback)
	M.autoDetectGesture(M.Gesture.SWIPE_DOWN, true)
	uevrUtils.registerUEVRCallback("on_gesture_swipe_down", callback)
end
return M