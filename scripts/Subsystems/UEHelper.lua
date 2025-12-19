
local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local vr=uevr.params.vr



function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
function find_static_class(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function find_required_object_no_cache(class, full_name)


    local matches = class:get_objects_matching(false)


    for i, obj in ipairs(matches) do


        if obj ~= nil and obj:get_full_name() == full_name then


            return obj


        end


    end


    return nil


end

function SearchSubObjectArrayForObject(ObjArray, string_partial)
local FoundItem= nil
	for i, InvItems in ipairs(ObjArray) do
				if string.find(InvItems:get_fname():to_string(), string_partial) then
				--	print("found")
					FoundItem=InvItems
					--return FoundItem
				break
				end
	end
return	FoundItem
end

--INPUT functions:-------------
-------------------------------

--VR to key functions
function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then 
        key_up_string = "up"
    end
    
    api:dispatch_custom_event(key_value, key_up_string)
end

function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end

function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end
--
--Xinput helpers
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
--
--Library
local GameplayStDef= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
--local CameraMAnager_C= find_required_object("Class /Script/RsGameTechRT.RsCameraManager")
--local CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraMAnager_C)
local viewport = game_engine.GameViewport
local world = viewport.World

--GLOBAL VARIABLES
isMenu=false
isCinematic =false
isSaberExtended=false
isNavMode=true
--Dynamic helper functions:
 ThumbLX   = 0
 ThumbLY   = 0
 ThumbRX   = 0
 ThumbRY   = 0
 LTrigger  = 0
 RTrigger  = 0
 rShoulder = false
 lShoulder = false
 lThumb    = false
 rThumb    = false
 Abutton = false
 Bbutton = false
 Xbutton = false
 Ybutton = false
 SelectButton=false

--local variables
local isRecentered=false


function UpdateInput(state)

--Read Gamepad stick input 
	ThumbLX = state.Gamepad.sThumbLX
	ThumbLY = state.Gamepad.sThumbLY
	ThumbRX = state.Gamepad.sThumbRX
	ThumbRY = state.Gamepad.sThumbRY
	LTrigger= state.Gamepad.bLeftTrigger
	RTrigger= state.Gamepad.bRightTrigger
	rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
	rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
	Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
	Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
	Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
	Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)

	

	
--UnpressButton

end







uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
local dpawn=nil
dpawn=api:get_local_pawn(0)


	--UpdateDriveStatus(dpawn)
	


--Read Gamepad stick input 
--if PhysicalDriving then
	UpdateInput(state)

--end

end)

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
--local	dpawn=api:get_local_pawn(0)
	viewport = game_engine.GameViewport
	world = viewport.World
	local dpawn=api:get_local_pawn(0)	
	local Player=api:get_player_controller(0)	
	

		
		--isMenu=GameplayStDef:IsGamePaused(world)
		
		--local PMesh=pawn.FirstPersonSkeletalMeshComponent

end)