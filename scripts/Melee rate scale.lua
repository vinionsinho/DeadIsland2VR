local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.sdk.callbacks
local pawn = api:get_local_pawn(0)
local swinging_fast = nil


local melee_data = {
    cooldown_time = 0.0,
    accumulated_time = 0.0,
    last_tried_melee_time = 1000.0,
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    first = true,
}


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

local weapon_class_path = nil
local is_melee = false
local equipped_weapon_actor = nil
local weapon_class_path = nil

    local pawn = api:get_local_pawn(0)
    if not pawn then
        return
    end

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

    if velocity.y < 0 then
		swinging_fast = vel_len >= 2.5
    else
        swinging_fast = false
    end


    local cur_mon = pawn:GetCurrentMontage()
    
    if cur_mon then
    -- print(cur_mon:get_full_name())
        if is_melee and not string.find(cur_mon:get_full_name(), "Knockdown") then
            cur_mon.RateScale = 5.0
        else
            cur_mon.RateScale = 1.0
        end
    end


end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

	if (state ~= nil) then					
		if swinging_fast == true then
			if state.Gamepad.bRightTrigger >= 200 then 
				state.Gamepad.bRightTrigger = 0
			else	
				state.Gamepad.bRightTrigger = 200
			end			
		end				
	end
end)