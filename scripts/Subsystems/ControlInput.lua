require(".\\Subsystems\\UEHelper")
QuickMenu=false --needs to be global so other scripts like RadialQuickMenu can access state
local api = uevr.api
local BbuttonNotPressedAfterMenu=false
local SprintState=false

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


if Ybutton and  QuickMenu==false then
	unpressButton(state,XINPUT_GAMEPAD_Y)
	api:get_player_controller():QuickMenuInput_Pressed()
	QuickMenu=true
elseif not Ybutton  then
	if QuickMenu== true then
		api:get_player_controller():QuickMenuInput_Released()
		QuickMenu=false
	end
end
if isMenu==false then
	if Ybutton then
		unpressButton(state,XINPUT_GAMEPAD_Y)
		--pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	end
	if not Bbutton then
	BbuttonNotPressedAfterMenu=true
	end
	if Xbutton  then
		--XbuttonNotPressedAfterMenu=true
		unpressButton(state,XINPUT_GAMEPAD_X)
		pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	end
	if rShoulder then
		unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	end
	if Bbutton and BbuttonNotPressedAfterMenu then
		unpressButton(state,XINPUT_GAMEPAD_B)
		pressButton(state,XINPUT_GAMEPAD_X)
	end

	if lThumb then
	unpressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	--pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
	end
	if lShoulder then
		unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		pressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	end
	
	if ThumbRY > 30000 then
		pressButton(state,XINPUT_GAMEPAD_Y)
	end
	if ThumbRY < -30000 then
		pressButton(state,XINPUT_GAMEPAD_B)
	end
else BbuttonNotPressedAfterMenu=false end

--Do not take over stick if riding, otherwise cannot move horse
if not isMenu and not isRiding then
	if not isSprinting then
		state.Gamepad.sThumbLX=0
		state.Gamepad.sThumbLY=0

	end
end

end)