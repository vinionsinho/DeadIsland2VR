--require(".\\Trackers\\Trackers")
--require(".\\Config\\CONFIG")
--require(".\\Subsystems\\UEHelper")
require(".\\libs\\zones")
--require(".\\Controls")
--local utils=require(".\\libs\\uevr_utils")
HolsterInit=true
if TrackersInit and configInit then
	print("Trackers  loaded")
	print("Config Loaded")
end
--CONFIG--
--------	
	isRhand=true
	isLeftHandModeTriggerSwitchOnly=true
	        
--------
--------	
	local SeatedOffset=0 
	if SitMode then
		SeatedOffset=20
	end
		
	local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	--local vr=uevr.params.vr
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



local lControllerIndex= 1
local rControllerIndex= 2


	
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

function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end




local rGrabActive =false
local lGrabActive =false
local LZone=0
--local ThumbLX   = 0
--local ThumbLY   = 0
--local ThumbRX   = 0
--local ThumbRY   = 0
--local LTrigger  = 0
--local RTrigger  = 0
--local rShoulder = false
--local lShoulder = false
--local lThumb    = false
--local rThumb    = false
local lThumbSwitchState= 0
local lThumbOut= false
local rThumbSwitchState= 0
local rThumbOut= false
local isReloading= false
local ReadyUpTick = 0
local RZone=0
local LWeaponZone=0
local RWeaponZone=0
local inMenu=false
local LTriggerWasPressed = 0
local RTriggerWasPressed = 0
local isFlashlightToggle =false
local isButtonA =false
local isButtonB  =false
local isButtonX =false
local isButtonY  =false
local isRShoulder=false
local isCrouch = false
local StanceButton= false
local isJournal=0
local GrenadeReady=false
local KeyG=false
local KeyM=false
local KeyF=false
local KeyB=false
local KeyI=false
local KeySpace=false
local KeyCtrl=false
local vecy=0
local isJump=false
local isInventoryPDA=false
local LastWorldTime= 0.000
local WorldTime=0.000
local isRShoulderHeadR= false
local isRShoulderHeadL= false
local RZoneLast=RZone
local rGrabStart=false
local LZoneLast=LZone
local lGrabStart=false
local RWeaponZoneLast=0
local Quick1 = false
local Quick2 = false
local Quick3 = false
local Quick4 = false
local Quick5 = false
local Quick6 = false
local Quick7 = false
local Quick8 = false
local Quick9 = false
local GUIState=true

local isToggled =false	
local function ToggleUI()
	if not isToggled then
		isToggled=true
		
		local CompassClass=  uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/Compass/WBP_ModernHud_Compass.WBP_ModernHud_Compass_C")
		local CompassComponent= UEVR_UObjectHook.get_objects_by_class(CompassClass,false)	
		local HealthClass		=  uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_Health.WBP_ModernHud_Health_C")
		local HealthCOmponent	= UEVR_UObjectHook.get_objects_by_class(HealthClass,false)
		local StaminaClass		=   uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_Fatigue.WBP_ModernHud_Fatigue_C")
		local StaminaComponent	= UEVR_UObjectHook.get_objects_by_class(StaminaClass,false)
		local MagicClass=  uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_MagicIcon.WBP_ModernHud_MagicIcon_C")
		local MagicComponent= UEVR_UObjectHook.get_objects_by_class(MagicClass,false)
		local WeaponClass= uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_WeaponIcon.WBP_ModernHud_WeaponIcon_C")
		local WeaponComponent= UEVR_UObjectHook.get_objects_by_class(WeaponClass,false) 
		 if GUIState  then
			CompassComponent[2]:SetVisibility(1)
		--	HealthCOmponent[2]:SetVisibility(1)
		--	StaminaComponent[3]:SetVisibility(1)
			MagicComponent	[2]:SetVisibility(1)
			WeaponComponent	[2]:SetVisibility(1)
		 elseif GUIState == false then
			CompassComponent[2]:SetVisibility(0)
			MagicComponent  [2]:SetVisibility(0)
		--	HealthCOmponent [2]:SetVisibility(0)
		--	StaminaComponent[3]:SetVisibility(0)
			WeaponComponent [2]:SetVisibility(0)
		end
		 GUIState=not GUIState
--	print(HealthCOmponent[2]:get_full_name())
	end
end


uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


--Read Gamepad stick input 
--	ThumbLX = state.Gamepad.sThumbLX
--	ThumbLY = state.Gamepad.sThumbLY
--	ThumbRX = state.Gamepad.sThumbRX
--	ThumbRY = state.Gamepad.sThumbRY
--	LTrigger= state.Gamepad.bLeftTrigger
--	RTrigger= state.Gamepad.bRightTrigger
--	rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
--	lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
--	lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
--	rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
--	Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
--	Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
--	Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
--	Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)
	
	
	
--Checks if in menu or inventory or pda, if so doesnt change vanilla controls
if isMenu== false  then	
	--Reset variable for weapon zone Firemode switch
	if  LTrigger<10 then
		LTriggerWasPressed = 0
	end
	if  RTrigger<10 then
		RTriggerWasPressed = 0
	end
	
	--DISABLE DPAD
	--if isRhand then
	--	--if not rShoulder then
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
	--	--	--unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
	--	--end
	--else 
	--	--if not lShoulder then
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
	--	--	--unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
	--	--	unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
	--	--end
	--end
	
	--Disable BUttons:
--	if 	isRhand or isLeftHandModeTriggerSwitchOnly then
--		if lShoulder and SwapLShoulderLThumb then
--			unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
--		end
--	else
--		if rShoulder and SwapLShoulderLThumb then
--			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
--		end
--	end
	--if lThumb and SwapLShoulderLThumb then
	--	unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
	--end
	
	
	--Left Hand config (currently not used)
	if not isRhand then
		state.Gamepad.bLeftTrigger=RTrigger
		state.Gamepad.bRightTrigger=LTrigger
		if not isLeftHandModeTriggerSwitchOnly then
			state.Gamepad.sThumbRX=ThumbLX
			state.Gamepad.sThumbRY=ThumbLY
			state.Gamepad.sThumbLX=ThumbRX
			state.Gamepad.sThumbLY=ThumbRY
			state.Gamepad.bLeftTrigger=RTrigger
			state.Gamepad.bRightTrigger=LTrigger
			unpressButton(state, XINPUT_GAMEPAD_B)
			unpressButton(state, XINPUT_GAMEPAD_A				)
			unpressButton(state, XINPUT_GAMEPAD_X				)	
			unpressButton(state, XINPUT_GAMEPAD_Y				)
			----unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
			----unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
			----unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
			----unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER	)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER	)
			unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB		)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB		)
			if Ybutton then
				pressButton(state,XINPUT_GAMEPAD_X)
			end
			if Bbutton then
			--	unpressButton(state, XINPUT_GAMEPAD_B)	
				pressButton(state,XINPUT_GAMEPAD_A)
			end
			if Xbutton then
				pressButton(state,XINPUT_GAMEPAD_Y)
				--unpressButton(state, XINPUT_GAMEPAD_X)
			end	
			if Abutton then
				pressButton(state,XINPUT_GAMEPAD_B)
				--unpressButton(state, XINPUT_GAMEPAD_A)
			end		
			
			if lShoulder then
				pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	--			unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			end
			if rShoulder then
				pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
			--	unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			end
			if lThumb then
				pressButton(state,XINPUT_GAMEPAD_RIGHT_THUMB)
--				unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
			end	
			if rThumb then
				pressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	--			unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
			end
		end
	end
		--pressdpad--
	if isDpadUp then
		pressButton(state, XINPUT_GAMEPAD_DPAD_UP)
		isDpadUp=false
	end
	if isDpadRight then
		pressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT)
		isDpadRight=false
	end
	if isDpadLeft then
		pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
		isDpadLeft=false
	end
	if isDpadDown then
		pressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
		isDpadDown=false
	end
	if isButtonX then
		pressButton(state, XINPUT_GAMEPAD_X)
		isButtonX=false
	end
	if isButtonB then
		pressButton(state, XINPUT_GAMEPAD_B)
		isButtonB=false
	end
	if isButtonA then
		pressButton(state, XINPUT_GAMEPAD_A)
		isButtonA=false
	end
	if isButtonY then
		pressButton(state, XINPUT_GAMEPAD_Y)
		isButtonY=false
	end
	--if not inMenu then
	--	unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER	)		
	--	unpressButton(state, XINPUT_GAMEPAD_B)
	--	--unpressButton(state, XINPUT_GAMEPAD_A				)
	--	unpressButton(state, XINPUT_GAMEPAD_X				)	
	--	unpressButton(state, XINPUT_GAMEPAD_Y				)
	--end
	
	--Unpress when in Zone

	if isRhand or isLeftHandModeTriggerSwitchOnly then	
		if  RZone ~=0 then
			unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
			--unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
		end
	else
		if LZone ~= 0 then
			unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
			--unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
		end
	end
	--print(RWeaponZone .. "   " .. RZone)
	--disable Trigger for modeswitch
	if RWeaponZone == 2 then
		state.Gamepad.bLeftTrigger=0
	end
	
	if LWeaponZone == 3 then
		unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
	end
	--disable Thumb for flashlight

	
	-- Attachement singlepress fix
	if lThumb and lThumbSwitchState==0 then 
		lThumbOut = true 
		lThumbSwitchState=1
	elseif lThumb and lThumbSwitchState ==1 then
		lThumbOut = false
	elseif not lThumb and lThumbSwitchState ==1 then
		lThumbOut = false
		lThumbSwitchState=0
		isRShoulder=false
	end
	if rThumb and rThumbSwitchState==0 then 
		rThumbOut = true 
		rThumbSwitchState=1
	elseif rThumb and rThumbSwitchState ==1 then
		rThumbOut = false
	elseif not rThumb then
		rThumbOut = false
		rThumbSwitchState=0
		isRShoulder=false
	end
	
	if isRShoulderHeadR == true then
		pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		if rGrabActive == false then
			isRShoulderHeadR= false
		end
	end
	if isRShoulderHeadL == true then
		pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		if lGrabActive == false then
			isRShoulderHeadL= false
		end
	end
	--print(rThumbOut)
	if isReloading then
		pressButton(state, XINPUT_GAMEPAD_X)
		isReloading=false
	end
	
	
	--Ready UP
	--if lGrabActive and rGrabActive then
	--    ReadyUpTick= ReadyUpTick+1
	--	if ReadyUpTick ==120 then
	--		api:get_player_controller(0):ReadyUp()
	--	end
	--else 
	--	ReadyUpTick=0
	--end
	
	--Grab activation
	if rShoulder then
		rGrabActive= true
		if rGrabStart==false then
			RZoneLast=RZone
			rGrabStart=true
		end
	else rGrabActive =false
		rGrabStart=false	
			
	end
	if lShoulder  then
		lGrabActive =true
		if lGrabStart==false then
			LZoneLast=LZone
			RWeaponZoneLast=RWeaponZone
			lGrabStart=true
		end
		--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	else lGrabActive=false
		lGrabStart=false	
	end
	
	if not lShoulder and not rShoulder then
		isToggled=false
	end
	
	
	pawn=api:get_local_pawn(0)
	
	
	--COntrol edits:

	
		
	if Key1 and not rGrabActive then
		SendKeyUp('1')
		Key1=false
	end
	if Key2 and not rGrabActive then
		SendKeyUp('2')
		Key2=false
	end
	if Key3 and not rGrabActive then
		SendKeyUp('3')
		Key3=false
	end
	if Key4 and not rGrabActive then
		SendKeyUp('4')
		Key4=false
	end
	if Key5 and not rGrabActive then
		SendKeyUp('5')
		Key5=false
	end
	if Key6 and not rGrabActive then
		SendKeyUp('6')
		Key6=false
	end
	if Key7 and not rGrabActive then
		SendKeyUp('7')
		Key7=false
	end
	if KeyM and not rGrabActive then
		SendKeyUp('M')
		KeyM=false
	end
	if KeyI ==true  then
		SendKeyUp('I')
		KeyI=false
	end
	if KeyB then
		SendKeyUp('B')
		KeyB=false
	end
	if KeyCtrl then
		SendKeyUp('0xA2')
		KeyCtrl=false
	end
	if KeySpace then
		SendKeyUp('0x20')
		KeySpace=false
	end

	if math.abs(vecy)< 0.1 and isJump==true then
		isJump=false
		
	end
	if math.abs(vecy)< 0.1 and isCrouch==true then
		isCrouch=false
		
	end
	if vecy > 0.8 and isJump==false then
		
		KeySpace=true
		SendKeyDown('0x20')
		isJump=true
		
	end
	
	if vecy <-0.8 and isCrouch == false then
		KeyCtrl=true
		SendKeyDown('0xA2')
		isCrouch=true
	end
	
	
	if GrenadeReady then
		if rGrabActive==false then
		SendKeyDown('G')
		GrenadeReady=false
		KeyG=true
		end
	end
	
	if isRShoulder then
		--unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	end
		
		--CONTROL REMAP:
	
	--if lThumb and RWeaponZone ~= 3 then
	--	pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	--end
end	
	
--	print(VecA.x)
	
end)


	local RHandLocation=Vector3f.new (0,0,0) 
	local LHandLocation=Vector3f.new (0,0,0)
	local HmdLocation=Vector3f.new (0,0,0)
	local isHapticZoneR = false
	local isHapticZoneL = false
	local isHapticZoneWR = false
	local isHapticZoneWL = false
	local isHapticZoneRLast= false
	local isHapticZoneWRLast= false
	local isHapticZoneWLLast= false
	local LeftController=		 uevr.params.vr.get_left_joystick_source()
	local RightController=		 uevr.params.vr.get_right_joystick_source()
	local RightJoystickIndex=	 uevr.params.vr.get_right_joystick_source()
	local RAxis=UEVR_Vector2f.new()
	params.vr.get_joystick_axis(RightJoystickIndex,RAxis)
	local leanState=0 --1 =left, 2=right
	print(RightJoystickIndex)
	--print(right_hand_component:K2_GetComponentLocation())
--local LHandLocation = left_hand_actor:K2_GetActorLocation()
--local HMDLocation = hmd_actor:K2_GetActorLocation()
 RHandNewX=0
 RHandNewY=0
 RHandNewZ=0
 LHandNewX=0
 LHandNewY=0
 LHandNewZ=0
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	pawn=api:get_local_pawn(0)
	player=api:get_player_controller(0)
	if isRhand or isLeftHandModeTriggerSwitchOnly then
		params.vr.get_joystick_axis(RightJoystickIndex,RAxis)
		vecy=RAxis.y
	else 
		params.vr.get_joystick_axis(LeftController,RAxis)
		vecy=RAxis.y
	end
	--print("vecyy"..vecy)




	local RHandLocation=right_hand_component:K2_GetComponentLocation()
	local LHandLocation=left_hand_component:K2_GetComponentLocation()
	local HmdLocation= hmd_component:K2_GetComponentLocation()

	local HmdRotation= hmd_component:K2_GetComponentRotation()
	local RHandRotation = right_hand_component:K2_GetComponentRotation()
	local LHandRotation = left_hand_component:K2_GetComponentRotation()
	
	--inMenu

	
	--print(inMenu)

	--LEANING
	--if PhysicalLeaning then
	--
	--	if HmdRotation.z > 20 then
	--		leanState = 2
	--		--pawn:ToggleLeanRight(true)
	--	elseif HmdRotation.z <20 and HmdRotation.z>-20 then
	--		leanState=0
	--		--pawn:ToggleLeanRight(false) 
	--		--pawn:ToggleLeanLeft(false)
	--	elseif HmdRotation.z < -20 then 
	--		leanState=1
	--		--pawn:ToggleLeanLeft(true)
	--	end
	--	
	--	if leanState == 0 and leanStateLast ~= leanState then
	--		if leanStateLast == 1 then
	--			pawn:ToggleLeanLeft(false)
	--		elseif leanStateLast ==2 then
	--			pawn:ToggleLeanRight(false)
	--		end
	--		leanStateLast=leanState
	--		uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
	--	elseif leanState ==1 and leanStateLast ~= leanState then
	--		pawn:ToggleLeanLeft(true)
	--		leanStateLast=leanState
	--		uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
	--	elseif leanState == 2 and leanStateLast ~= leanState then
	--		pawn:ToggleLeanRight(true)
	--		leanStateLast=leanState
	--		uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
	--	end
	--
	--end	
	
	-- Y IS LEFT RIGHT, X IS BACK FORWARD, Z IS DOWN  UP
	local RotDiff= HmdRotation.y	--(z axis of location)
	 LHandNewX= (LHandLocation.x-HmdLocation.x)*math.cos(-RotDiff/180*math.pi)- (LHandLocation.y-HmdLocation.y)*math.sin(-RotDiff/180*math.pi)
			
	 LHandNewY= (LHandLocation.x-HmdLocation.x)*math.sin(-RotDiff/180*math.pi) + (LHandLocation.y-HmdLocation.y)*math.cos(-RotDiff/180*math.pi)
	
	 RHandNewX= (RHandLocation.x-HmdLocation.x)*math.cos(-RotDiff/180*math.pi)- (RHandLocation.y-HmdLocation.y)*math.sin(-RotDiff/180*math.pi)
		  
	 RHandNewY= (RHandLocation.x-HmdLocation.x)*math.sin(-RotDiff/180*math.pi) + (RHandLocation.y-HmdLocation.y)*math.cos(-RotDiff/180*math.pi)
	
	 RHandNewZ= RHandLocation.z-HmdLocation.z
	 LHandNewZ= LHandLocation.z-HmdLocation.z
	
	--for R Handed 
	--z,yaw Rotation
	local RotWeaponZ= RHandRotation.y
	local LHandWeaponX = (LHandLocation.x-RHandLocation.x)*math.cos(-RotWeaponZ/180*math.pi)- (LHandLocation.y-RHandLocation.y)*math.sin(-RotWeaponZ/180*math.pi)
	local LHandWeaponY = (LHandLocation.x-RHandLocation.x)*math.sin(-RotWeaponZ/180*math.pi) + (LHandLocation.y-RHandLocation.y)*math.cos(-RotWeaponZ/180*math.pi)
	local LHandWeaponZ = (LHandLocation.z-RHandLocation.z)
	--print(RHandRotation.z)
	-- x, Roll Rotation
	local RotWeaponX =RHandRotation.z
	LHandWeaponY = LHandWeaponY*math.cos(RotWeaponX/180*math.pi)- LHandWeaponZ*math.sin (RotWeaponX/180*math.pi)
	LHandWeaponZ = LHandWeaponY*math.sin(RotWeaponX/180*math.pi) + LHandWeaponZ*math.cos(RotWeaponX/180*math.pi)
	-- y, Pitch Rotation
	local RotWeaponY =RHandRotation.x
	LHandWeaponX = LHandWeaponX*math.cos(-RotWeaponY/180*math.pi)- LHandWeaponZ*math.sin(-RotWeaponY/180*math.pi)
	LHandWeaponZ = LHandWeaponX*math.sin(-RotWeaponY/180*math.pi) + LHandWeaponZ*math.cos(-RotWeaponY/180*math.pi)
	
	-- 3d Rotation Complete
	--print(RotWeaponX)
	--print(RotWeaponY)
	--for LEFT
	local RotWeaponLZ= LHandRotation.y
	local RHandWeaponX = (RHandLocation.x-LHandLocation.x)*math.cos(-RotWeaponLZ/180*math.pi)- 	(RHandLocation.y-LHandLocation.y)*math.sin(-RotWeaponLZ/180*math.pi)
	local RHandWeaponY = (RHandLocation.x-LHandLocation.x)*math.sin(-RotWeaponLZ/180*math.pi) + (RHandLocation.y-LHandLocation.y)*math.cos(-RotWeaponLZ/180*math.pi)
	local RHandWeaponZ = (RHandLocation.z-LHandLocation.z)
		
	local RotWeaponLX =LHandRotation.z
	RHandWeaponY = RHandWeaponY*math.cos(RotWeaponLX/180*math.pi)-  RHandWeaponZ*math.sin (RotWeaponLX/180*math.pi)
	RHandWeaponZ = RHandWeaponY*math.sin(RotWeaponLX/180*math.pi) + RHandWeaponZ*math.cos (RotWeaponLX/180*math.pi)
	
	local RotWeaponLY =LHandRotation.x
	RHandWeaponX = RHandWeaponX*math.cos(-RotWeaponLY/180*math.pi)-  RHandWeaponZ*math.sin(-RotWeaponLY/180*math.pi)
	RHandWeaponZ = RHandWeaponX*math.sin(-RotWeaponLY/180*math.pi) + RHandWeaponZ*math.cos(-RotWeaponLY/180*math.pi)
	
	--small force feedback on enter and leave
	if HapticFeedback then	
		if isHapticZoneRLast ~= isHapticZoneR  then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
			isHapticZoneRLast=isHapticZoneR
		end
		if isHapticZoneLLast ~= isHapticZoneL then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
			isHapticZoneLLast=isHapticZoneL
		end
		if isHapticZoneWRLast ~= isHapticZoneWR  then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
			isHapticZoneWRLast=isHapticZoneWR
		end
		if isHapticZoneWLLast ~= isHapticZoneWL then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
			isHapticZoneWLLast=isHapticZoneWL
		end
	end
	
	--FUNCTION FOR ZONES, dont edit this
local function RCheckZone(ZoneVec6)--Zmin,Zmax,Ymin,Ymax,Xmin,Xmax) -- Z: UP/DOWN, Y:RIGHT LEFT, X FORWARD BACKWARD, checks if RHand is in RZone
	if RHandNewZ > ZoneVec6[1] and RHandNewZ < ZoneVec6[2] and RHandNewY > ZoneVec6[3] and RHandNewY < ZoneVec6[4] and RHandNewX > ZoneVec6[5] and RHandNewX < ZoneVec6[6] then --RHandNewZ > Zmin and RHandNewZ < Zmax and RHandNewY > Ymin and RHandNewY < Ymax and RHandNewX > Xmin and RHandNewX < Xmax then
		return true
	else 
		return false
	end
end
local function LCheckZone(ZoneVec6) -- Z: UP/DOWN, Y:RIGHT LEFT, X FORWARD BACKWARD, checks if LHand is in LZone
	if LHandNewZ > ZoneVec6[1] and LHandNewZ < ZoneVec6[2] and LHandNewY > ZoneVec6[3] and LHandNewY < ZoneVec6[4] and LHandNewX > ZoneVec6[5] and LHandNewX < ZoneVec6[6] then
		return true
	else 
		return false
	end
end

local function isRZoneValidAction(RZone)
	if RZoneLast== RZone then
		return true
	else return false
	end
end


local function isLZoneValidAction(LZone)
	if LZoneLast== LZone then
		return true
	else return false
	end
end	

local function isRWeaponZoneValidAction(RWeaponZone)
	if RWeaponZoneLast== RWeaponZone then
		return true
	else return false
	end
end	
	
	-----EDIT HERE-------------
	---------------------------
	--define Haptic zones RHand Z: UP/DOWN, Y:RIGHT LEFT, X FORWARD BACKWARD, checks if RHand is in RZone
--	if 	   RCheckZone(RHZoneRSh)  then							--	-10, 15, 10, 30, -10, 20+SeatedOffset) then 
--		isHapticZoneR =true
--		RZone=1-- RShoulder
--		
--	--elseif RCheckZone(-10, 15, -30, -10, -10, 20+SeatedOffset)      then
--	--	isHapticZoneR =false
--	--	RZone=2--Left Shoulder
--		
--	elseif RCheckZone(RHZoneHead)  then
--		isHapticZoneR= true
--		RZone=3-- Over Head
--		
--	elseif RCheckZone(RHZoneRHip) then				-- -100,-60,22,50,-10,10+SeatedOffset)   then
--		isHapticZoneR= true
--		RZone=4--RHip
		
	--elseif RCheckZone(-100,-50,-30,5,-10,30+SeatedOffset)   then
	--	isHapticZoneR= false
	--	RZone=5--LHip
	--	
	--elseif RCheckZone(-40,-25,-15,-5,0,10+SeatedOffset)   then
	--	isHapticZoneR= false
	--	RZone=6--ChestLeft
	--	
--	elseif RCheckZone(RHZoneRChest)	then		 	--	-40,-25,5,15,0,10+SeatedOffset)  then
--		isHapticZoneR= true
--		RZone=7--ChestRight
	--	
	--elseif RCheckZone(-100,-50,-20,20,-30,-15)	  then
	--	isHapticZoneR= false
	--	RZone=8--LowerBack Center
		
	--elseif RCheckZone(-5,10,-10,0,0,10) then
	--	isHapticZoneR= false
	--	RZone=9--LeftEar
	--	
	--elseif RCheckZone(-5,10,0,10,0,10)  then
	--	isHapticZoneR= false
	--	RZone=10--RightEar
--	else 
--		isHapticZoneR= false
--		RZone=0--EMPTY
--	end
	--define Haptic zone Lhandx Z: UP/DOWN, Y:RIGHT LEFT, X FORWARD BACKWARD, checks if RHand is in RZone
--	if LCheckZone(LHZoneRSh) then					--	-10, 15, 10, 30, -10, 20+SeatedOffset) then
--		isHapticZoneL =true
--		LZone=1-- RShoulder
--		
--	elseif LCheckZone ( LHZoneLSh) then		---10, 15, -30, -10, -10, 20+SeatedOffset) then
--		isHapticZoneL =true
--		LZone=2--Left Shoulder
--		
--	elseif LCheckZone(LHZoneHead) then
--		isHapticZoneL= true
--		LZone=3-- Over Head
	--	
	--elseif LCheckZone(-100,-50,-5,50,-10,30+SeatedOffset)  then
	--	isHapticZoneL= true
	--	LZone=4--RPouch
		
--	elseif LCheckZone(LHZoneLHip) then 		-- -100,-60,-50,-10,-10,10+SeatedOffset)  then
--		isHapticZoneL= true
--		LZone=5--LPouch
--		
--	elseif LCheckZone(LHZoneLChest)	then-- -40,-25,-15,-5,0,10+SeatedOffset)   then
--		isHapticZoneL= true
--		LZone=6--ChestLeft
--		
--	elseif LCheckZone(LHZoneRChest) then 		-- -40,-25,5,15,0,10+SeatedOffset)  then
--		isHapticZoneL= true
--		LZone=7--ChestRight
		
	--elseif LCheckZone(-100,-50,-20,20,-30,-15) then
	--	isHapticZoneL= true
	--	LZone=8--LowerBack Center
	--	
	--elseif LCheckZone(-5,10,-10,0,0,10)  then
	--	isHapticZoneL= true
	--	LZone=9--LeftEar
	--	
	--elseif LCheckZone(-5,10,0,10,0,10) then
	--	isHapticZoneL= true
	--	LZone=10--RightEar
--	else 
--		isHapticZoneL= false
--		LZone=0--EMPTY
--	end

	
	--define Haptic Zone RWeapon
--	if isRhand then	
--		if LHandWeaponZ <-5 and LHandWeaponZ > -30 and LHandWeaponX < 20 and LHandWeaponX > -15 and LHandWeaponY < 12 and LHandWeaponY > -12 then
--			isHapticZoneWL = true
--			RWeaponZone = 1 --below gun, e.g. mag reload
--		elseif LHandWeaponZ < 10 and LHandWeaponZ > 0 and LHandWeaponX < 10 and LHandWeaponX > -5 and LHandWeaponY < 12 and LHandWeaponY > -12 then
--			isHapticZoneWL = true
--			RWeaponZone = 2 --close above RHand, e.g. WeaponModeSwitch
--		elseif LHandWeaponZ < 25 and LHandWeaponZ > 0 and LHandWeaponX < 45 and LHandWeaponX > 15 and LHandWeaponY < 15 and LHandWeaponY > -15 then
--			isHapticZoneWL = true
--			RWeaponZone = 3 --Front at barrel l, e.g. Attachement
--		else
--			RWeaponZone= 0
--			isHapticZoneWL=false
--		end
--	else
--		if RHandWeaponZ <-5 and RHandWeaponZ > -30 and RHandWeaponX < 20 and RHandWeaponX > -5 and RHandWeaponY < 12 and RHandWeaponY > -12 then
--			isHapticZoneWR = true
--	    	LWeaponZone = 1 --below gun, e.g. mag reload
--	    elseif RHandWeaponZ < 10 and RHandWeaponZ > 0 and RHandWeaponX < 10 and RHandWeaponX > -5 and RHandWeaponY < 12 and RHandWeaponY > -12 then
--	    	isHapticZoneWR = true
--	    	LWeaponZone = 2 --close above RHand, e.g. WeaponModeSwitch
--	    elseif RHandWeaponZ < 25 and RHandWeaponZ > 0 and RHandWeaponX < 45 and RHandWeaponX > 15 and RHandWeaponY < 12 and RHandWeaponY > -12 then
--	    	isHapticZoneWR = true
--	    	LWeaponZone = 3 --Front at barrel l, e.g. Attachement
--		else
--			LWeaponZone=0
--			isHapticZoneWR= false
--	    end
--	end
	
	--Code to Depress:
	if Quick1 then
		Quick1=false
		player:Quick1Input_Released()
	end
	if Quick2 then
		Quick2=false
		player:Quick2Input_Released()
	end
	if Quick3 then
		Quick3=false
		player:Quick3Input_Released()
	end
	if Quick4 then
		Quick4=false
		player:Quick4Input_Released()
	end
	if Quick5 then
		Quick5=false
		player:Quick5Input_Released()
	end
	if Quick6 then
		Quick6=false
		player:Quick6Input_Released()
	end
	if Quick7 then
		Quick7=false
		player:Quick7Input_Released()
	end
	if Quick8 then
		Quick8=false
		player:Quick8Input_Released()
	end
	if Quick9 then
		Quick9=false
		player:Quick9Input_Released()
	end
	
	
	
	
	--Code to equip
	if isRhand then
		if RZone== 1 and rGrabActive and RWeaponZone==0 then
			--local Primary= pawn.Inventory:GetPrimaryWeapon()
			player:Quick1Input_Pressed()
			Quick1=true
		elseif RZone== 2 and rGrabActive then
			Key4=true
			SendKeyDown('4')
		elseif RZone== 4 and rGrabActive then
			Quick2=true
			player:Quick2Input_Pressed()
		elseif RZone== 5 and rGrabActive then
			Key1=true
			SendKeyDown('1')
		elseif LZone== 1 and lGrabActive and RWeaponZone==0 then
			Quick8=true
			player:Quick8Input_Pressed()
		elseif RZone== 8 and rGrabActive then
			Key1=true
			SendKeyDown('1')
		elseif RZone== 6 and rGrabActive then
			
		elseif RZone== 7 and rGrabActive  then
			Quick3=true
			player:Quick3Input_Pressed()
		elseif LZone==2 and lGrabActive  then
			player:Quick7Input_Pressed()
			Quick7=true
		elseif LZone==5 and lGrabActive  then
			player:Quick6Input_Pressed()
			Quick6=true
		elseif RZone == 3 and rGrabActive  then
			ToggleUI()
			
		elseif LZone ==3 and lGrabActive and isRShoulderHeadL==false then
			
			ToggleUI()
			
		elseif LZone==7 and lGrabActive   then
	--		player:Quick5Input_Pressed()
			Quick5=true
		elseif LZone==6 and lGrabActive  then
		-- isDpadLeft=true
		--	player:Quick4Input_Pressed()
			Quick4=true
		end
	else 
		if LZone == 2 and lGrabActive then
			Key3=true
			SendKeyDown('3')
		elseif LZone== 1 and lGrabActive then
			Key4=true
			SendKeyDown('4')
		elseif LZone== 5 and lGrabActive then
			Key2=true
			SendKeyDown('2')
		elseif RZone == 3 and rGrabActive and isRShoulderHeadR== false then
			
				--print(isRShoulder)
			
		elseif LZone ==3 and lGrabActive and isRShoulderHeadL==false then
		
				--print(isRShoulder)
			
		elseif LZone== 8 and lGrabActive then
			Key1=true
			SendKeyDown('1')
		elseif LZone== 6 and lGrabActive then
			Key5=true
			SendKeyDown('5')
		elseif LZone== 7 and lGrabActive then
			Key6=true
			SendKeyDown('6')
		elseif RZone==1 and rGrabActive and LWeaponZone==0 then
			KeyI=true
			SendKeyDown('I')
		elseif RZone==2 and rGrabActive and LWeaponZone==0 then
			isDpadLeft=true
		elseif LZone==4 and lGrabActive then
			Key1=true
			SendKeyDown('1')
		elseif RZone==7 and rGrabActive and LWeaponZone==0 then
			Key7=true
			SendKeyDown('7')
		elseif RZone==6 and rGrabActive and LWeaponZone==0 then
			KeyM=true
			SendKeyDown('M')
		end
		
	end
	
	--Code to trigger Weapon
	if isRhand then
		if RWeaponZone ==1 and lGrabActive then
			--print(pawn.Equipped_Primary:Jig_CanChamberWeapon())
			isReloading=true
		elseif RWeaponZone == 2 and LTrigger > 230 and LTriggerWasPressed ==0 then
			--pawn:ChamberWeapon(false)
			KeyB=true
			SendKeyDown('B')
			LTriggerWasPressed=1
				
		elseif RWeaponZone==3 and lThumbOut then
			if string.sub(uevr.params.vr:get_mod_value("VR_AimMethod"),1,1) == "2" then
				isRShoulder=true
			end
			
		end
	else
		
		if LWeaponZone==1 then
			if rGrabActive then
				isReloading = true
			else isReloading = false
			end
		elseif LWeaponZone== 2 and RTrigger > 230 and RTriggerWasPressed ==0 then
			KeyB=true
			SendKeyDown('B')
			RTriggerWasPressed=1
		elseif LWeaponZone ==3 and rThumbOut then
			
		end
	end
--print(LWeaponZone)
--DEBUG PRINTS--
--TURN ON FOR HELP WITH COORDINATES

----COORDINATES FOR HOLSTERS
--print("RHandz: " .. RHandLocation.z .. "     Rhandx: ".. RHandLocation.x )
--print("RHandx: " .. RHandNewX .. "     Lhandx: ".. LHandNewX .."      HMDx: " .. HmdLocation.x)
--print("RHandy: " .. RHandNewY .. "     Lhandy: ".. LHandNewY .."      HMDy: " .. HmdLocation.y)
--print(HmdRotation.y)
--print("                   ")
--print("                   ")
--print("                   ")

----COORDINATES FOR WEAPON ZONES:
--print("RHandz: " .. RHandWeaponZ .. "     Lhandz: ".. LHandWeaponZ )
--print("RHandx: " .. RHandWeaponX .. "     Lhandx: ".. LHandWeaponX )
--print("RHandy: " .. RHandWeaponY .. "     Lhandy: ".. LHandWeaponY )
--print("                   ")
--print("                   ")
--print("                   ")


end)