local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.sdk.callbacks
local pawn = api:get_local_pawn(0)
local swinging_fast = nil
local is_melee = nil
local melee_data = {
    cooldown_time = 0.0,
    accumulated_time = 0.0,
    last_tried_melee_time = 1000.0,
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    swing_active_time = 0.0,
    first = true,
}

--Credits to Markmon. All the charged attack logic was taken from his Avowed6dof.lua file.

local CHARGE_THRESHOLD = 0.25 -- 25 cm
local was_gesture_active = false

-- Function to check distance between a hand and the head
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

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    is_melee = false 
    local weapon_class_path = nil
    local equipped_weapon_actor = nil
    local weapon_class_path = nil

    local pawn = api:get_local_pawn(0)
    if not pawn then
        return
    end
    
    -- God mode

    if pawn then
        local health_component = pawn.HealthComponent
        if health_component then
           health_component.Health = 3500.0 
        end
    end


    if pawn.BPC_Player_PaperDoll then
            local paper_doll_comp = pawn.BPC_Player_PaperDoll
            local active_slot_name = paper_doll_comp.WeaponSlot

        if active_slot_name then
            local equippable_component = paper_doll_comp:GetEquippableAssignedToSlot(active_slot_name)
            if equippable_component then
                equipped_weapon_actor = equippable_component:get_outer()
            end
        end
    end

    if equipped_weapon_actor then
        -- print (equipped_weapon_actor:get_full_name())
        weapon_class_path = equipped_weapon_actor:get_class():get_outer()
    end

    
    if weapon_class_path then
        -- print (weapon_class_path:get_full_name())
        if string.find (weapon_class_path:get_full_name(), "Melee") then
            is_melee = true
        end
    end

    -- print (is_melee)



   vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)

    -- Copy without creating new userdata
    melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)

    if melee_data.first then
        melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
        melee_data.first = false
    end

    local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)

    -- Clone without creating new userdata
    melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
    melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
    melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z

    local vel_len = velocity:length()

    -- Decrement timers
    if melee_data.cooldown_time > 0 then 
        melee_data.cooldown_time = melee_data.cooldown_time - delta 
    end
    
    if melee_data.swing_active_time > 0 then
        melee_data.swing_active_time = melee_data.swing_active_time - delta
    end

    -- Detection: Check direction, speed, and cooldown
    if velocity.y < 0 and vel_len >= 2.5 and melee_data.cooldown_time <= 0 then
         melee_data.cooldown_time = 0.5 -- Cooldown of 0.5 seconds between hits
         melee_data.swing_active_time = 0.1 -- Hold trigger for 0.1 seconds
    end

    -- State setting
    if melee_data.swing_active_time > 0 then
        swinging_fast = true
    else
        swinging_fast = false 
    end
    local cur_mon = pawn:GetCurrentMontage()
    if cur_mon then
    -- print(cur_mon:get_full_name())
        if is_melee and not string.find(cur_mon:get_full_name(), "Knockdown") then
            cur_mon.RateScale = 4.0 -- Maximum working value of 5.0. Lower values may work better
        else
            cur_mon.RateScale = 1.0
        end
    end
    
end)


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

    
	if (state ~= nil) and is_melee then			
		if swinging_fast == true then
			if state.Gamepad.bRightTrigger >= 200 then 
				state.Gamepad.bRightTrigger = 0
			else	
				state.Gamepad.bRightTrigger = 200
			end			
		end
        
        -- Charged attack check and button hold
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
        
	end
end)

