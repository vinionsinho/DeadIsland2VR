	--CONFIG
	--require(".\\Subsystems\\UEHelper")
	--require(".\\Config\\CONFIG")
	--local MeleePower = 500 --Default = 1000
	---------------------------------------
	local MeleeDistance=1 -- 30cm + MeleeDistance per meter,e.g. 30cm+ 0.4*1m = 70cm
	local api = uevr.api
	local vr = uevr.params.vr
	--local params = uevr.params
	local callbacks = uevr.params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local WeaponHand_Pos=UEVR_Vector3f.new()
	local WeaponHand_Rot=UEVR_Quaternionf.new()
	local SecondaryHand_Pos=UEVR_Vector3f.new()
	local SecondaryHand_Rot=UEVR_Quaternionf.new()
	local SecondaryHand_Joy=UEVR_Vector2f.new()
	local PosZOld=0
	local PosYOld=0
	local PosXOld=0
	local PosZOldSecondary=0
	local PosYOldSecondary=0
	local PosXOldSecondary=0
	local tickskip=0
	 PosDiffWeaponHand=0
	 PosDiffSecondaryHand=0
	local WeaponHandCanPunch=false
	local SecondaryHandCanPunch=false
	
--VR to key functions
local function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then 
        key_up_string = "up"
    end
    
    api:dispatch_custom_event(key_value, key_up_string)
end

local function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

local function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end
	
function isButtonPressed(state, button)
	return state.Gamepad.wButtons & button ~= 0
end
function isButtonNotPressed(state, button)
	return state.Gamepad.wButtons & button == 0
end
function pressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function unpressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end

--Helper functions
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end
local swinging_fast = nil

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

local isHit1=false
local isHit2=false
local isHit3=false
local isHit4=false
local isHit5=false



--Library
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

local UGameplayStatics_library= find_static_class("Class /Script/Engine.GameplayStatics")
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")

local zero_color = nil
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local    actor_c = find_required_object("Class /Script/Engine.Actor")
local zero_color = StructObject.new(color_c)
	
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local GameplayStaticsDefault= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
--local VWeaponClass= find_static_class("Class /Script/Altar.VWeapon")
--local VHitBoxClass= find_required_object("Class /Script/Altar.VHitBoxComponent")
local ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")



local reusable_hit_result1 = StructObject.new(hitresult_c)
local reusable_hit_result2=  StructObject.new(hitresult_c)
local reusable_hit_result3 = StructObject.new(hitresult_c)
local reusable_hit_result4 = StructObject.new(hitresult_c)
local reusable_hit_result5 = StructObject.new(hitresult_c)

local DeltaCheck=0
local Mouse1=false
local DeltaAimMethod =0
local isAimMethodSwitched=false
local Hittest = nil

local isBlock=false
local DeltaBlock=0
local DeltaBlock2Activator=0
local DeltaBlockActivator=0
local ShieldAngle=0
local HeadAngle=0
local BoxX=10
local BoxZ=1
local AttackCount=0
local isAttacking=false
local BoxYLast=0
local BoxY=0
local tgm=false
local AttackDelta=0
local ActorFound=false
local HitBoxReset=true
local HitBoxDelta=0
local SendAttack=false
local Init=false
local InitDelta=0

local LeftController=		 uevr.params.vr.get_left_joystick_source()
local RightController=		 uevr.params.vr.get_right_joystick_source()



uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
--print(isRiding)

	DeltaCheck=DeltaCheck+delta
	--print(DeltaCheck)
	player= api:get_player_controller(0)
	pawn = api:get_local_pawn(0)
	if isRhand then
		WHandIndex=2
		SHandIndex=1
	else HandIndex=1
		SHandIndex=2
	end
	--print(isRiding)
	--local SecondaryHandIndex = uevr.params.vr.get_right_controller_index()
	uevr.params.vr.get_pose(WHandIndex, WeaponHand_Pos, WeaponHand_Rot)
	
	local PosXNew=WeaponHand_Pos.x
	local PosYNew=WeaponHand_Pos.y
	local PosZNew=WeaponHand_Pos.z
	
	PosDiffWeaponHand = math.sqrt((PosXNew-PosXOld)^2+(PosYNew-PosYOld)^2+(PosZNew-PosZOld)^2)*(1/delta)*10
	PosZOld=PosZNew
	PosYOld=PosYNew
	PosXOld=PosXNew
	
	uevr.params.vr.get_pose(SHandIndex, SecondaryHand_Pos, SecondaryHand_Rot)
	local PosXNewSecondary=SecondaryHand_Pos.x
	local PosYNewSecondary=SecondaryHand_Pos.y
	local PosZNewSecondary=SecondaryHand_Pos.z
	
	PosDiffSecondaryHand = math.sqrt((PosXNewSecondary-PosXOldSecondary)^2+(PosYNewSecondary-PosYOldSecondary)^2+(PosZNewSecondary-PosZOldSecondary)^2)*(1/delta)
	PosZOldSecondary=PosZNewSecondary
	PosYOldSecondary=PosYNewSecondary
	PosXOldSecondary=PosXNewSecondary

end)