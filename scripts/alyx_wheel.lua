local uevrUtils = require('libs/uevr_utils')
local mathLib = require('libs/core/math_lib')
local controllers = require('libs/controllers')
local configui = require('libs/configui')

local M = {}

---------------------------------------------------------------------------
-- Half-Life: Alyx Style Weapon Wheel Interaction for Dead Island 2 (VR)
--
-- Standalone helper module for UEVR.
--
-- Controls:
-- 1. Open Wheel: Move your hand in 3D to select radial slots (Alyx style).
--    Includes crisp haptic vibration on crossing between weapon slots.
-- 2. Hold X Button: Suspends Alyx hand tracking and returns control to
--    the physical Right Stick so you can flick left/right to cycle
--    inventory weapons in that slot (jbusfield D-Pad cycle feature).
---------------------------------------------------------------------------

local config = {
    enabled = true,
    bBypassEnabled = true, -- Hold X to return control to analog stick for inventory cycle
    hapticsEnabled = true, -- Trigger haptic pulse when changing selected slot
    deadzoneCm = 2.0,      -- 2.0 cm deadzone before moving off center
    maxRadiusCm = 6.5,     -- 6.5 cm displacement for 100% thumbstick deflection
}

local status = {
    isWheelOpen = false,
    originHandPos = nil,
    currentStickX = 0,
    currentStickY = 0,
    lastSelectedSector = -1,
}

-- UI Configuration Panel in UEVR ImGui Overlay
local configDefinition = {
    {
        panelLabel = "Alyx Weapon Wheel",
        saveFile = "alyx_weapon_wheel_config",
        layout = {
            { widgetType = "text", label = "Half-Life: Alyx Weapon Wheel Mod" },
            { widgetType = "new_line" },
            { widgetType = "indent", width = 15 },
            {
                widgetType = "checkbox",
                id = "alyx_wheel_enabled",
                label = "Enable Alyx Wheel",
                initialValue = true,
            },
            {
                widgetType = "checkbox",
                id = "alyx_wheel_b_bypass",
                label = "Hold X for Stick Inventory Cycle",
                initialValue = true,
            },
            {
                widgetType = "checkbox",
                id = "alyx_wheel_haptics",
                label = "Haptic Feedback on Slot Change",
                initialValue = true,
            },
            {
                widgetType = "drag_float",
                id = "alyx_wheel_deadzone",
                label = "Deadzone (cm)",
                speed = 0.1,
                range = {0.5, 8.0},
                initialValue = 2.0,
            },
            {
                widgetType = "drag_float",
                id = "alyx_wheel_radius",
                label = "Max Reach Radius (cm)",
                speed = 0.1,
                range = {3.0, 15.0},
                initialValue = 6.5,
            },
            { widgetType = "new_line" },
            { widgetType = "text", label = "Controls Breakdown:" },
            {
                widgetType = "text",
                wrapped = true,
                label = "- Normal Wheel Open: Move hand physically in 3D space towards the weapon slot to highlight it (with haptic feedback).",
            },
            {
                widgetType = "text",
                wrapped = true,
                label = "- Hold B / Y while Wheel is Open: Hand tracking is paused; use Right Thumbstick left/right to cycle through weapons available in inventory for that slot.",
            },
            { widgetType = "unindent", width = 15 },
        }
    }
}

configui.onCreateOrUpdate("alyx_wheel_enabled", function(val)
    config.enabled = val == true
end)

configui.onCreateOrUpdate("alyx_wheel_b_bypass", function(val)
    config.bBypassEnabled = val == true
end)

configui.onCreateOrUpdate("alyx_wheel_haptics", function(val)
    config.hapticsEnabled = val == true
end)

configui.onCreateOrUpdate("alyx_wheel_deadzone", function(val)
    config.deadzoneCm = val or 2.0
end)

configui.onCreateOrUpdate("alyx_wheel_radius", function(val)
    config.maxRadiusCm = val or 6.5
end)

configui.create(configDefinition)

-- Calculate HMD Right and Up vectors in world space
local function getHmdScreenBasis()
    local hmdRot = controllers.getControllerRotation(2)
    if hmdRot == nil then
        return nil, nil
    end

    local rot = uevrUtils.rotator(hmdRot)
    local rightVec = nil
    local upVec = nil

    if kismet_math_library ~= nil then
        if kismet_math_library.GetRightVector ~= nil then
            rightVec = kismet_math_library:GetRightVector(rot)
        end
        if kismet_math_library.GetUpVector ~= nil then
            upVec = kismet_math_library:GetUpVector(rot)
        end
    end

    -- Fallback manual Euler rotation basis if Kismet is unavailable
    if rightVec == nil or upVec == nil then
        local p = math.rad(rot.Pitch or 0)
        local y = math.rad(rot.Yaw or 0)
        local r = math.rad(rot.Roll or 0)

        local sinP, cosP = math.sin(p), math.cos(p)
        local sinY, cosY = math.sin(y), math.cos(y)
        local sinR, cosR = math.sin(r), math.cos(r)

        -- Unreal Engine coordinate system (X=Forward, Y=Right, Z=Up)
        if rightVec == nil then
            rightVec = {
                X = -sinR * sinP * cosY + cosR * sinY,
                Y = -sinR * sinP * sinY - cosR * cosY,
                Z = sinR * cosP
            }
        end
        if upVec == nil then
            upVec = {
                X = -cosR * sinP * cosY - sinR * sinY,
                Y = -cosR * sinP * sinY + sinR * cosY,
                Z = cosR * cosP
            }
        end
    end

    return rightVec, upVec
end

local function getActiveHandId()
    -- Follows primary handedness (Right hand = 1, Left hand = 0)
    return uevrUtils.getHandedness() or Handed.Right
end

-- Official UEVR Haptic Vibration using UEVR_VRData source handles
local function triggerHapticClick()
    if not config.hapticsEnabled then return end
    local vr = uevr.params and uevr.params.vr
    if vr == nil or vr.trigger_haptic_vibration == nil then return end

    local hand = getActiveHandId()
    local sourceHandle = nil
    if hand == Handed.Left and vr.get_left_joystick_source ~= nil then
        sourceHandle = vr.get_left_joystick_source()
    elseif vr.get_right_joystick_source ~= nil then
        sourceHandle = vr.get_right_joystick_source()
    end

    if sourceHandle ~= nil and sourceHandle ~= 0 then
        -- vr.trigger_haptic_vibration(seconds_from_now, duration, frequency, amplitude, source_handle)
        vr.trigger_haptic_vibration(0.0, 0.02, 1.0, 0.5, sourceHandle)
    end
end

function M.setWheelState(isOpen)
    if status.isWheelOpen == isOpen then return end
    status.isWheelOpen = isOpen

    if isOpen then
        local hand = getActiveHandId()
        local handPos = controllers.getControllerLocation(hand)
        if handPos ~= nil then
            status.originHandPos = { X = handPos.X, Y = handPos.Y, Z = handPos.Z }
        else
            status.originHandPos = nil
        end
        status.currentStickX = 0
        status.currentStickY = 0
        status.lastSelectedSector = -1
    else
        status.originHandPos = nil
        status.currentStickX = 0
        status.currentStickY = 0
        status.lastSelectedSector = -1
    end
end

local function updateHandMovement()
    if not config.enabled or not status.isWheelOpen then return end

    local hand = getActiveHandId()
    local handPos = controllers.getControllerLocation(hand)
    if handPos == nil or status.originHandPos == nil then
        status.currentStickX = 0
        status.currentStickY = 0
        return
    end

    local deltaVec = {
        X = handPos.X - status.originHandPos.X,
        Y = handPos.Y - status.originHandPos.Y,
        Z = handPos.Z - status.originHandPos.Z
    }

    local rightVec, upVec = getHmdScreenBasis()
    if rightVec == nil or upVec == nil then return end

    -- Project 3D displacement onto 2D HMD View Plane
    local screenX = mathLib.vectorDot(deltaVec, rightVec)
    local screenY = mathLib.vectorDot(deltaVec, upVec)

    local distance = math.sqrt(screenX * screenX + screenY * screenY)

    if distance < config.deadzoneCm then
        status.currentStickX = 0
        status.currentStickY = 0
        status.lastSelectedSector = -1
        return
    end

    -- Scale distance beyond deadzone to full stick range [0..1]
    local span = math.max(0.1, config.maxRadiusCm - config.deadzoneCm)
    local normalizedIntensity = math.min(1.0, (distance - config.deadzoneCm) / span)
    local dirX = screenX / distance
    local dirY = screenY / distance

    status.currentStickX = dirX * normalizedIntensity * 32767.0
    status.currentStickY = dirY * normalizedIntensity * 32767.0

    -- 8-Sector calculation for haptic notch clicks (each slot is 45 degrees / pi/4)
    local angle = math.atan(dirY, dirX) -- [-pi, pi]
    local sector = math.floor(((angle + (math.pi / 8.0)) % (2.0 * math.pi)) / (math.pi / 4.0))
    if sector ~= status.lastSelectedSector then
        status.lastSelectedSector = sector
        triggerHapticClick()
    end
end

-- Listen to the Scaleform UI callback from Dead Island 2 profile
uevrUtils.registerUEVRCallback("scaleform_ui_change", function(className, visible)
    if className == "BP_HUDObject_EquippedItemsWheel_C" then
        M.setWheelState(visible == true)
    end
end)

-- Direct hooks for maximum reliability
hook_function("BlueprintGeneratedClass /Game/DI2/UI/HUD/Objects/WeaponWheel/BP_HUDObject_EquippedItemsWheel.BP_HUDObject_EquippedItemsWheel_C", "OnOpenWheel", false, nil,
    function()
        M.setWheelState(true)
    end, true)

hook_function("BlueprintGeneratedClass /Game/DI2/UI/HUD/Objects/WeaponWheel/BP_HUDObject_EquippedItemsWheel.BP_HUDObject_EquippedItemsWheel_C", "OnCloseWheel", false, nil,
    function()
        M.setWheelState(false)
    end, true)

-- Calculate physical hand displacement on post engine tick
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
    if status.isWheelOpen and config.enabled then
        updateHandMovement()
    end
end)

-- Inject calculated stick values into XInput
uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
    if not config.enabled or not status.isWheelOpen or status.originHandPos == nil then
        return
    end

    -- Check if B button (X on Quest / XINPUT_GAMEPAD_B) is pressed for D-Pad weapon cycling
    local isBModifierHeld = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_B)
    if config.bBypassEnabled and isBModifierHeld then
        -- User is holding X to cycle weapons using the physical thumbstick.
        -- We do NOT override sThumbRX/sThumbRY, allowing jbusfield's logic and the stick to work untouched!
        return
    end

    -- Otherwise, apply Alyx physical hand navigation to the radial wheel
    state.Gamepad.sThumbRX = math.floor(math.max(-32767, math.min(32767, status.currentStickX)))
    state.Gamepad.sThumbRY = math.floor(math.max(-32767, math.min(32767, status.currentStickY)))
end, 10)

return M
