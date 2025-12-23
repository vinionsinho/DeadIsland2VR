--Credits to Markmon. All this logic was taken from his Avowed6dof.lua file.

local api = uevr.api
local vr = uevr.params.vr

local CHARGE_THRESHOLD = 0.25 -- 20 cm
local was_gesture_active = false

-- Function to check distance between a hand and the head
-- Based on 'GetBlock' from Avowed6dof.lua
local function GetGesture(which_hand, threshold)
    local controller_index = vr.get_left_controller_index()
    if which_hand == "right" then
        controller_index = vr.get_right_controller_index()
    end
    
    local hmd_index = vr.get_hmd_index()
    
    -- Ensure both devices are connected/tracked
    if controller_index ~= -1 and hmd_index ~= -1 then
        
        -- Get Poses
        local controller_pos = UEVR_Vector3f.new()
        local controller_rot = UEVR_Quaternionf.new()
        vr.get_pose(controller_index, controller_pos, controller_rot)
        
        local hmd_pos = UEVR_Vector3f.new()
        local hmd_rot = UEVR_Quaternionf.new()
        vr.get_pose(hmd_index, hmd_pos, hmd_rot)
        
        -- Calculate the Euclidean distance between the two points
        local dx = controller_pos.x - hmd_pos.x
        local dy = controller_pos.y - hmd_pos.y
        local dz = controller_pos.z - hmd_pos.z
        
        -- Distance = sqrt(dx^2 + dy^2 + dz^2)
        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
        
        -- Check if the distance is within the threshold
        if distance <= threshold then
            return true
        -- else
        --     return false
        end
    end
    
    return false    
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    -- Check for the gesture on the RIGHT hand
    if GetGesture("right", CHARGE_THRESHOLD) == true then
        -- Gesture Active: Hold Right Trigger
        state.Gamepad.bRightTrigger = 255
        
        if was_gesture_active == false then
            was_gesture_active = true
            -- Optional: Haptic feedback when entering the pose.
            -- Dead Island 2 already provides precise haptic feedback so let's not worry with it.
            -- vr.trigger_haptic_vibration(0.0, 0.1, 300.0, 1.0, vr.get_right_joystick_source())
            print("Charged Attack Gesture: STARTED") 
        end
    else
        -- Gesture Inactive
        if was_gesture_active == true then
             -- We release the trigger naturally by not blocking it anymore, 
             -- assuming the user isn't physically holding it.
             -- If we wanted to FORCE release, we would set it to 0, 
             -- but usually we just stop overwriting it.
             was_gesture_active = false
             print("Charged Attack Gesture: ENDED (Released Trigger)")
        end
    end
end)
