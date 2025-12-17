-- Decoupled Yaw code courtesy of Pande4360

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")
local bodyYaw = require("libs/body_yaw")
local pawnModule = require("libs/pawn")

local M = {}

M.AimMethod =
{
    UEVR = 1,
    HEAD = 2,
    RIGHT_CONTROLLER = 3,
    LEFT_CONTROLLER = 4,
    RIGHT_WEAPON = 5,
    LEFT_WEAPON = 6
}

M.PawnRotationMode =
{
    NONE = 1,
    RIGHT_CONTROLLER = 2,
    LEFT_CONTROLLER = 3,
	LOCKED = 4,
    SIMPLE = 5,
    ADVANCED = 6,
}

M.PawnPositionMode =
{
    NONE = 1,
    FOLLOWS = 2,
    ANIMATED = 3
}

local aimMethod = M.AimMethod.UEVR
local isDisabledOverride = false
local isDisabled = false

local rootComponent = nil
local decoupledYaw = nil
local bodyRotationOffset = 0

local rxState = 0
local snapTurnDeadZone = 8000

local rootOffset = uevrUtils.vector(0,0,0)
---@cast rootOffset -nil
local headOffset = uevrUtils.vector(0,0,0)
---@cast headOffset -nil
local aimRotationOffset = uevrUtils.rotator(0,0,0)
local weaponRotation = nil -- externally set for WEAPON aim method

local useSnapTurn = false
local smoothTurnSpeed = 50
local snapAngle = 30
local pawnPositionAnimationScale = 0.2
local pawnPositionSweepMovement = true
local eyeOffset = 0
local pawnPositionMode = M.PawnPositionMode.FOLLOWS
local pawnRotationMode = M.PawnRotationMode.RIGHT_CONTROLLER
local adjustForAnimation = false
local adjustForEyeOffset = false
local fixSpatialAudio = true

local currentHeadRotator = uevrUtils.rotator(0,0,0)
local headBoneName = ""
local rootBoneName = ""
local boneList = {}

--this module is designed to work with these UEVR settings 
uevrUtils.set_decoupled_pitch(true)
uevrUtils.set_decoupled_pitch_adjust_ui(true)

local configWidgets = spliceableInlineArray{
	{
		widgetType = "checkbox",
		id = "uevr_input_disabled",
		label = "Disabled",
		initialValue = isDisabledOverride
	},
	{
		widgetType = "tree_node",
		id = "uevr_input_handedness",
		initialOpen = true,
		label = "Handedness"
	},
		{
			widgetType = "combo",
			id = "uevr_handedness",
			label = "Hand",
			selections = {"Left", "Right"},
			initialValue = uevrUtils.getHandedness()
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_input_aim_method",
		initialOpen = true,
		label = "Aim Method"
	},
		{
			widgetType = "combo",
			id = "aimMethod",
			label = "Type",
			selections = {"UEVR", "Head/HMD", "Right Controller", "Left Controller", "Right Weapon", "Left Weapon"},
			initialValue = aimMethod
		},
		{
			widgetType = "checkbox",
			id = "fixSpatialAudio",
			label = "Fix Spatial Audio",
			initialValue = fixSpatialAudio
		},
		{
			widgetType = "drag_float3",
			id = "rootOffset",
			label = "Root Offset",
			speed = .1,
			range = {-200, 200},
			initialValue = {rootOffset.X, rootOffset.Y, rootOffset.Z}
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "begin_group",
		id = "advanced_input",
		isHidden = false
	},
		{
			widgetType = "tree_node",
			id = "uevr_input_turning",
			initialOpen = true,
			label = "Turning"
		},
			{
				widgetType = "checkbox",
				id = "useSnapTurn",
				label = "Use Snap Turn",
				initialValue = useSnapTurn
			},
			{
				widgetType = "slider_int",
				id = "snapAngle",
				label = "Snap Turn Angle",
				speed = 1.0,
				range = {2, 180},
				initialValue = snapAngle
			},
			{
				widgetType = "slider_int",
				id = "smoothTurnSpeed",
				label = "Smooth Turn Speed",
				speed = 1.0,
				range = {1, 200},
				initialValue = smoothTurnSpeed
			},
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = "uevr_input_movement",
			initialOpen = true,
			label = "Movement Orientation"
		},
				{
					widgetType = "combo",
					id = "pawnRotationMode",
					label = "Type",
					selections = {"Game", "Right Controller", "Left Controller", "Head/HMD", "Follows Body (Simple)", "Follows Body (Advanced)"},
					initialValue = pawnRotationMode
				},
				expandArray(bodyYaw.getConfigurationWidgets),
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = "uevr_input_roomscale",
			initialOpen = true,
			label = "Roomscale Movement"
		},
			{
				widgetType = "combo",
				id = "pawnPositionMode",
				label = "Type",
				selections = {"None", "Follows HMD", "Follows HMD With Animation"},
				initialValue = pawnPositionMode
			},
			{
				widgetType = "checkbox",
				id = "pawnPositionSweepMovement",
				label = "Sweep Movement",
				initialValue = pawnPositionSweepMovement
			},
			{
				widgetType = "slider_float",
				id = "pawnPositionAnimationScale",
				label = "Animation Scale",
				speed = .01,
				range = {0, 1},
				initialValue = pawnPositionAnimationScale,
			},
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = "uevr_input_pawn",
			initialOpen = true,
			label = "Player Body"
		},
			{
				widgetType = "drag_float3",
				id = "headOffset",
				label = "Head Offset",
				speed = .1,
				range = {-200, 200},
				initialValue = {headOffset.X, headOffset.Y, headOffset.Z}
			},
			{
				widgetType = "checkbox",
				id = "adjustForAnimation",
				label = "Animation Movement Compensation",
				initialValue = adjustForAnimation
			},
			{
				widgetType = "combo",
				id = "headBones",
				label = "Head Bone",
				selections = {"None"},
				initialValue = 1
			},
			{
				widgetType = "checkbox",
				id = "adjustForEyeOffset",
				label = "Eye Offset Compensation",
				initialValue = adjustForEyeOffset
			},
			{
				widgetType = "slider_float",
				id = "eyeOffset",
				label = "Eye Offset",
				speed = .1,
				range = {-40, 40},
				initialValue = eyeOffset
			},
		{
			widgetType = "tree_pop"
		},
	{
		widgetType = "end_group",
	},
	-- {
		-- widgetType = "slider_float",
		-- id = "neckOffset",
		-- label = "Neck Offset",
		-- speed = .1,
		-- range = {-40, 40},
		-- initialValue = 10
	-- },

}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[input] " .. text, logLevel)
	end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	local configDefinition = {
		{
			panelLabel = "Input Config",
			saveFile = saveFileName,
			layout = spliceableInlineArray{
				expandArray(M.getConfigurationWidgets, options)
			}
		}
	}
	configui.create(configDefinition)
end

function M.setDisabled(val)
	print("Input Disabled:", val)
	isDisabledOverride = val
	if isDisabledOverride then
		--this ensures the camera gets reset to the current pawn orientation when input is re-enabled
		decoupledYaw = nil
		bodyRotationOffset = 0
	end
	configui.setValue("uevr_input_disabled", isDisabledOverride, true)
end

function M.isDisabled()
	return isDisabledOverride or isDisabled
end

local function executeIsDisabledCallback(...)
	local result, priority = uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_input_disabled", table.unpack({...}))
	return result
end

function M.registerIsDisabledCallback(func)
	uevrUtils.registerUEVRCallback("is_input_disabled", func)
end

local function doFixSpatialAudio()
	if fixSpatialAudio then
		local playerController = uevr.api:get_player_controller(0)
		local hmdController = controllers.getController(2)
		if playerController ~= nil and hmdController ~= nil then
			playerController:SetAudioListenerOverride(hmdController,uevrUtils.vector(0,0,0),uevrUtils.rotator(0,0,0))
		end
	else
		local playerController = uevr.api:get_player_controller(0)
		if playerController ~= nil then
			playerController:ClearAudioListenerOverride()
		end
	end
end


function M.setAimMethod(val)
	aimMethod = val
end

function M.setUseSnapTurn(val)
	useSnapTurn = val
end

function M.setSmoothTurnSpeed(val)
	smoothTurnSpeed = val
end

function M.setSnapAngle(val)
	snapAngle = val
end

function M.setPawnRotationMode(val)
	pawnRotationMode = val
end

function M.setPawnPositionMode(val)
	pawnPositionMode = val
end

function M.setPawnPositionAnimationScale(val)
	pawnPositionAnimationScale = val
end

function M.setAdjustForAnimation(val)
	adjustForAnimation = val
end

function M.setAdjustForEyeOffset(val)
	adjustForEyeOffset = val
end

function M.setEyeOffset(val)
	eyeOffset = val
end

function M.setFixSpatialAudio(val)
	fixSpatialAudio = val
	doFixSpatialAudio()
end

function M.setPawnPositionSweepMovement(val)
	pawnPositionSweepMovement = val
end



function M.setHeadOffset(...)
	headOffset = uevrUtils.vector(table.unpack({...}))
end

function M.setRootOffset(...)
	rootOffset = uevrUtils.vector(table.unpack({...}))
end

--This function sets the global rootComponent variable 
local function getRootComponent()
	rootComponent = nil
	local component = uevrUtils.getValid(pawn,{"RootComponent"})
	if component ~= nil and component.K2_GetComponentLocation ~= nil and component.K2_GetComponentRotation ~= nil and component.K2_SetWorldRotation ~= nil then
		rootComponent = component
	end
	return rootComponent
end

--VR_SwapControllerInputs check this to see if user has chosen left hand full input swap in the UEVR UI
local function updateDecoupledYaw(state, rotationHand)
	if rotationHand == nil then rotationHand = Handed.Right end
	local yawChange = 0
	if decoupledYaw ~= nil then
		local thumbLX = state.Gamepad.sThumbLX
		local thumbLY = state.Gamepad.sThumbLY
		local thumbRX = state.Gamepad.sThumbRX
		local thumbRY = state.Gamepad.sThumbRY

		if rotationHand == Handed.Left then
			thumbLX = state.Gamepad.sThumbRX
			thumbLY = state.Gamepad.sThumbRY
			thumbRX = state.Gamepad.sThumbLX
			thumbRY = state.Gamepad.sThumbLY
		end

		if useSnapTurn then
			if thumbRX > snapTurnDeadZone and rxState == 0 then
				yawChange = snapAngle
				rxState=1
			elseif thumbRX < -snapTurnDeadZone and rxState == 0 then
				yawChange = -snapAngle
				rxState=1
			elseif thumbRX <= snapTurnDeadZone and thumbRX >=-snapTurnDeadZone then
				rxState=0
			end
		else
			local smoothTurnRate = smoothTurnSpeed / 12.5
			local rate = thumbRX/32767
			rate =  rate*rate*rate*rate
			if thumbRX > 2200 then
				yawChange = (rate * smoothTurnRate)
			end
			if thumbRX < -2200 then
				yawChange =  -(rate * smoothTurnRate)
			end
		end

		--keep the decoupled yaw in the range of -180 to 180
		decoupledYaw = uevrUtils.clampAngle180(decoupledYaw + yawChange)
	end
	return yawChange
end

local function initDecoupledYaw()
	if decoupledYaw == nil then
		if rootComponent ~= nil then
			local rotator = rootComponent:K2_GetComponentRotation()
			decoupledYaw = rotator.Yaw
		end
	end
end

local function setCurrentHeadBone(value)
	headBoneName = boneList[value]
	local mesh = pawnModule.getBodyMesh()
	if mesh ~= nil then
		local rootBoneFName = uevrUtils.getRootBoneOfBone(mesh, headBoneName)
		if rootBoneFName ~= nil then
			rootBoneName = rootBoneFName:to_string()
		end
	end
end

local function setBoneNames()
	local mesh = pawnModule.getBodyMesh()
	if mesh ~= nil then
		boneList = uevrUtils.getBoneNames(mesh)
		if boneList ~= nil and #boneList > 0 then 
			configui.setSelections("headBones", boneList)
		end
	end
	local currentHeadBoneIndex = configui.getValue("headBones")
	if currentHeadBoneIndex~= nil and currentHeadBoneIndex > 1 then
		setCurrentHeadBone(currentHeadBoneIndex)
	end
end

configui.onCreateOrUpdate("selectedPawnBodyMesh", function(value)
	setBoneNames()
end)


-- When a pawn runs, the animation can move the mesh ahead of the pawn, allowing you to
-- see down the neck hole if you are looking down. This function calculates an offset by which a pawn's
-- mesh can be moved to keep the neck in its proper place with respect to the pawn. Concept courtesy of Pande4360
local function getAnimationHeadDelta(pawn, pawnYaw)
	if headBoneName ~= "" and rootBoneName ~= "" and adjustForAnimation == true then
		local mesh = pawnModule.getBodyMesh()
		if mesh ~= nil then
			local baseRotationOffsetRotatorYaw = 0
			if pawn.BaseRotationOffset ~= nil then
				local baseRotationOffsetRotator = kismet_math_library:Quat_Rotator(pawn.BaseRotationOffset)
				if baseRotationOffsetRotator ~= nil then
					baseRotationOffsetRotatorYaw = baseRotationOffsetRotator.Yaw
				end
			end

			local headSocketLocation = mesh:GetSocketLocation(uevrUtils.fname_from_string(headBoneName))
			local rootSocketLocation = mesh:GetSocketLocation(uevrUtils.fname_from_string(rootBoneName))
			local socketDelta = uevrUtils.vector(headSocketLocation.Y - rootSocketLocation.Y, headSocketLocation.X - rootSocketLocation.X, headSocketLocation.Z - rootSocketLocation.Z)
			socketDelta = kismet_math_library:RotateAngleAxis(socketDelta, pawnYaw - baseRotationOffsetRotatorYaw, uevrUtils.vector(0,0,1))
			return socketDelta
		end
	end
	return uevrUtils.vector(0,0,0)
end

--because the eyes may not be centered on the origin, an hmd rotation can cause unexpected movement of the pawn mesh. This compensates for that movement
local function getEyeOffsetDelta(pawn, pawnYaw)
	if adjustForEyeOffset == true then
		local eyeOffsetScale = (pawn.BaseTranslationOffset and pawn.BaseTranslationOffset.X or 0) + eyeOffset
		local eyeVector = kismet_math_library:Conv_RotatorToVector(uevrUtils.rotator(currentHeadRotator.Pitch, pawnYaw - currentHeadRotator.Yaw, currentHeadRotator.Roll))
		eyeVector = eyeVector * eyeOffsetScale
		--print("EYE1",eyeVector.X,eyeVector.Y,eyeVector.Z)
		return eyeVector
	else
		return uevrUtils.vector(0,0,0)
	end
end

local function getAimOffsetAdjustedRotation(rotation)
	if (aimRotationOffset.Pitch == nil or aimRotationOffset.Pitch == 0) and (aimRotationOffset.Yaw == nil or aimRotationOffset.Yaw == 0) and (aimRotationOffset.Roll == nil or aimRotationOffset.Roll == 0) then
		return rotation
	end
	--Quat_MakeFromEuler expects Roll Pitch Yaw
	local quat1 = kismet_math_library:Quat_MakeFromEuler(uevrUtils.vector(aimRotationOffset.Roll, aimRotationOffset.Pitch, aimRotationOffset.Yaw))
	local quat2 = kismet_math_library:Quat_MakeFromEuler(uevrUtils.vector(rotation.Roll, rotation.Pitch, rotation.Yaw))
	local quat3 = kismet_math_library:Multiply_QuatQuat(quat2, quat1)
	local final = kismet_math_library:Quat_Rotator(quat3)
	return final
end

--this is called from both on_pre_engine_tick and on_early_calculate_stereo_view_offset but K2_SetWorldRotation can only be called once per tick
--because of the currentOffset ~= bodyRotationOffset check
local function updateBodyYaw(delta)
	if pawnRotationMode ~= M.PawnRotationMode.NONE then
		if decoupledYaw~= nil and rootComponent ~= nil then
			local currentOffset = bodyRotationOffset
			if delta ~= nil then
				if pawnRotationMode == M.PawnRotationMode.SIMPLE then
					bodyRotationOffset = bodyYaw.update(bodyRotationOffset, currentHeadRotator.Yaw - decoupledYaw, delta)
				elseif pawnRotationMode == M.PawnRotationMode.ADVANCED then
					bodyRotationOffset = bodyYaw.updateAdvanced(bodyRotationOffset, currentHeadRotator.Yaw - decoupledYaw, controllers.getControllerLocation(2), controllers.getControllerLocation(0),  controllers.getControllerLocation(1), delta)
				end
			else
				if pawnRotationMode == M.PawnRotationMode.LOCKED then
					bodyRotationOffset = currentHeadRotator.Yaw - decoupledYaw
				elseif pawnRotationMode == M.PawnRotationMode.LEFT_CONTROLLER then
					local rotation = (aimMethod == M.AimMethod.LEFT_WEAPON and weaponRotation ~= nil and weaponRotation.left ~= nil) and weaponRotation.left or controllers.getControllerRotation(Handed.Left)
					--did this to fix robocop. what happens with hello neighbor?
					if rotation ~= nil then
						local final = aimMethod ~= M.AimMethod.LEFT_WEAPON and getAimOffsetAdjustedRotation(rotation) or rotation
						bodyRotationOffset = final.Yaw - decoupledYaw
					end
					--if rotation ~= nil then bodyRotationOffset = rotation.Yaw - decoupledYaw end
				elseif pawnRotationMode == M.PawnRotationMode.RIGHT_CONTROLLER then
					local rotation = (aimMethod == M.AimMethod.RIGHT_WEAPON and weaponRotation ~= nil and weaponRotation.right ~= nil) and weaponRotation.right or controllers.getControllerRotation(Handed.Right)
--					local rotation = controllers.getControllerRotation(Handed.Right)
					--did this to fix robocop. what happens with hello neighbor? (even though hello neighbor doesnt need gunstock adjustments)
					if rotation ~= nil then
						local final = aimMethod ~= M.AimMethod.RIGHT_WEAPON and getAimOffsetAdjustedRotation(rotation) or rotation
						bodyRotationOffset = final.Yaw - decoupledYaw
					end
					--if rotation ~= nil then bodyRotationOffset = rotation.Yaw - decoupledYaw end
				end
			end
			if currentOffset ~= bodyRotationOffset then
				rootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
			end
		end
	end
end

local function updatePawnPositionRoomscale(world_to_meters)
	if pawnPositionMode ~= M.PawnPositionMode.NONE and rootComponent ~= nil and decoupledYaw ~= nil then
		uevr.params.vr.get_standing_origin(temp_vec3f)

		local origin = {X=temp_vec3f.X,Y=temp_vec3f.Y,Z=temp_vec3f.Z}
		temp_quatf:set(0,0,0,0)
		uevr.params.vr.get_pose(uevr.params.vr.get_hmd_index(), temp_vec3f, temp_quatf)

		--delta is how much the real world position of the hmd is changed from the real world origin
		local delta = {X=(temp_vec3f.X-origin.X)*world_to_meters, Y=(temp_vec3f.Y-origin.Y)*world_to_meters, Z=(temp_vec3f.Z-origin.Z)*world_to_meters}

		-- temp_quatf contains how much the rotation of the hmd is relative to the real world vr coordinate system
		--local poseQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, -temp_quatf.W)  --reordered terms to convert UEVR to unreal coord system
		--local poseRotator = kismet_math_library:Quat_Rotator(poseQuat)
		--print("POSE",poseRotator.Pitch, poseRotator.Yaw, poseRotator.Roll) --this is in the Unreal coord system

		temp_quatf:set(0,0,0,0)
		uevr.params.vr.get_rotation_offset(temp_quatf) --This is how much the head was twisted from the pose quat the last time "recenter view" was performed
		local headQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, temp_quatf.W) --reordered terms to convert UEVR to unreal coord system
		--local headRotator = kismet_math_library:Quat_Rotator(headQuat)
		--print("HEAD",headRotator.Pitch, headRotator.Yaw, headRotator.Roll) --this is in the Unreal coord system

		--rotate the delta by the amount of the hmd offset
		local forwardVector = kismet_math_library:Quat_RotateVector(headQuat, uevrUtils.vector(-delta.Z, delta.X, delta.Y)) --converts UEVR to Unreal coord system

		--add the decoupledYaw yaw rotation to the delta vector
		forwardVector = kismet_math_library:RotateAngleAxis( forwardVector,  decoupledYaw, uevrUtils.vector(0,0,1))
		forwardVector.Z = 0 --do not affect up/down
		if pawnPositionMode == M.PawnPositionMode.ANIMATED  then
			if uevrUtils.getValid(pawn) ~= nil and pawn.AddMovementInput ~= nil then
				pawn:AddMovementInput(forwardVector, pawnPositionAnimationScale, false) --dont need to check for pawn because if rootComponent exists then pawn exists
			end
		elseif pawnPositionMode == M.PawnPositionMode.FOLLOWS and rootComponent.K2_AddWorldOffset ~= nil then
			--pcall(function()
			if uevrUtils.getValid(rootComponent) ~= nil then
				rootComponent:K2_AddWorldOffset(forwardVector, pawnPositionSweepMovement, reusable_hit_result, false)
			end
			--end)
			--rootComponent:K2_SetWorldLocation(uevrUtils.vector(pawnPos.X+forwardVector.X,pawnPos.Y+forwardVector.Y,pawnPos.Z),pawnPositionSweepMovement,reusable_hit_result,false)
		end

		--temp_vec3f has the get_pose location
		temp_vec3f.Y = origin.Y --dont affect the up_down position
		uevr.params.vr.set_standing_origin(temp_vec3f)
	end
end

local function updateMeshRelativePosition()
	if rootComponent ~= nil and decoupledYaw ~= nil then
		local mesh = pawnModule.getBodyMesh()
		if mesh ~= nil then
			pcall(function()
				--the next line can fail even when checking for rootComprootComponent.K2_GetComponentRotation ~= nil so wrap in pcall
				local pawnRot = rootComponent:K2_GetComponentRotation()
				local animationDelta = getAnimationHeadDelta(pawn, pawnRot.Yaw)
				local eyeOffsetDelta = getEyeOffsetDelta(pawn, pawnRot.Yaw)

				temp_vec3:set(0, 0, 1) --the axis to rotate around
				--headOffset is a global defining how far the head is offset from the mesh
				local forwardVector = kismet_math_library:RotateAngleAxis(headOffset, pawnRot.Yaw - bodyRotationOffset - decoupledYaw, temp_vec3)
				local x = -forwardVector.X
				local y = -forwardVector.Y
				if animationDelta ~= nil and eyeOffsetDelta ~= nil then
					x = x + animationDelta.X + eyeOffsetDelta.X
					y = y + animationDelta.Y - eyeOffsetDelta.Y
				end
				--dont worry about Z here. Z is applied directly to the RootComponent later
				mesh.RelativeLocation.X = x
				mesh.RelativeLocation.Y = y
			end)
		end
	end
end

local function updateAim()
	local rotation = nil
	if aimMethod == M.AimMethod.RIGHT_WEAPON then
		rotation = (weaponRotation ~= nil and weaponRotation.right ~= nil) and weaponRotation.right or controllers.getControllerRotation(Handed.Right)
	elseif aimMethod == M.AimMethod.LEFT_WEAPON then
		rotation = (weaponRotation ~= nil and weaponRotation.left ~= nil) and weaponRotation.left or controllers.getControllerRotation(Handed.Left)
	else
		local controllerID = aimMethod == M.AimMethod.LEFT_CONTROLLER and 0 or (aimMethod == M.AimMethod.HEAD and 2 or 1)
		rotation = controllers.getControllerRotation(controllerID)
		--only use aim offset adjust if aimMethod is left or right controller
		if aimMethod == M.AimMethod.LEFT_CONTROLLER or aimMethod == M.AimMethod.RIGHT_CONTROLLER then
			rotation = getAimOffsetAdjustedRotation(rotation)
		end
	end
	--local forwardVector = controllers.getControllerDirection(controllerID)
	--print(pawn,pawn.Controller,rotation)
	if uevrUtils.getValid(pawn) ~= nil and pawn.Controller ~= nil and pawn.Controller.SetControlRotation ~= nil and rotation ~= nil then
		--disassociates the rotation of the pawn from the rotation set by pawn.Controller:SetControlRotation()
		pawn.bUseControllerRotationPitch = false
		pawn.bUseControllerRotationYaw = false
		pawn.bUseControllerRotationRoll = false

		if pawn.CharacterMovement ~= nil then
			pawn.CharacterMovement.bOrientRotationToMovement = false
			pawn.CharacterMovement.bUseControllerDesiredRotation = false
		end
		
		--Pitch is actually the only part of the rotation that is used here in games like Robocop
		--Yaw is controlled by Movement Orientation for those games
		pawn.Controller:SetControlRotation(rotation) --because the previous booleans were set, aiming with the hand or head doesnt affect the rotation of the pawn
	end
end

function M.setAimRotationOffset(offset)
	aimRotationOffset = uevrUtils.rotator(offset)
end

function M.setWeaponRotation(leftRotation, rightRotation)
	weaponRotation = {
		left = uevrUtils.rotator(leftRotation),
		right = uevrUtils.rotator(rightRotation)
	}
	-- if weaponRotation.right ~= nil then
	-- 	weaponRotation.right.Yaw = weaponRotation.right.Yaw + 90
	-- 	local roll = weaponRotation.right.Pitch
	-- 	weaponRotation.right.Pitch = -weaponRotation.right.Roll
	-- 	weaponRotation.right.Roll = roll
	-- end
	--print("Weapon Rotation Set", weaponRotation.left.Pitch, weaponRotation.left.Yaw, weaponRotation.left.Roll, weaponRotation.right.Pitch, weaponRotation.right.Yaw, weaponRotation.right.Roll)
end

local function updateIsDisabled()
	local disabled = isDisabledOverride or executeIsDisabledCallback() or false
	if isDisabled ~= disabled then
		--uevr.params.vr.recenter_view()
		M.resetView()
	end
	isDisabled = disabled
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	--set the global rootComponent variable on the earliest tick callback so it will be valid everywhere
	getRootComponent()

	--calculate the controller rotation here so it is available for updateBodyYaw and updateAim?

	updateIsDisabled()

	if not isDisabled and aimMethod ~= M.AimMethod.UEVR then
		initDecoupledYaw()
		updateAim()
		updateBodyYaw(delta)
	end

end)

uevr.params.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	if not isDisabled and aimMethod ~= M.AimMethod.UEVR then
		if view_index == 1 then
			updateBodyYaw()
			updatePawnPositionRoomscale(world_to_meters)
			updateMeshRelativePosition()
		end

		--Change the UEVR camera position and rotation to align with the pawn
		if bodyRotationOffset ~= nil and rootComponent ~= nil and uevrUtils.getValid(rootComponent) ~= nil and rootComponent.K2_GetComponentLocation ~= nil then
			local pawnPos = rootComponent:K2_GetComponentLocation()
			local pawnRot = rootComponent:K2_GetComponentRotation()

			local capsuleHeight = rootComponent.CapsuleHalfHeight or 0

			local forwardVector = {X=0,Y=0,Z=0}
			if rootOffset.X ~= 0 and rootOffset.Y ~= 0 then
				temp_vec3f:set(rootOffset.X, rootOffset.Y, rootOffset.Z) -- the vector representing the offset adjustment
				temp_vec3:set(0, 0, 1) --the axis to rotate around
				forwardVector = kismet_math_library:RotateAngleAxis(temp_vec3f, pawnRot.Yaw - bodyRotationOffset, temp_vec3)
			end

			position.x = pawnPos.x + forwardVector.X
			position.y = pawnPos.y + forwardVector.Y
			position.z = pawnPos.z + rootOffset.Z + capsuleHeight + headOffset.Z
			rotation.Pitch = 0--pawnRot.Pitch 
			rotation.Yaw = pawnRot.Yaw - bodyRotationOffset
			rotation.Roll = 0--pawnRot.Roll 	
		end
	end

	--Change the UEVR camera position and rotation to align with the pawn root component
	-- if rootComponent ~= nil then
	-- 	local offsetYaw = 0
	-- 	if not isDisabled and aimMethod ~= M.AimMethod.UEVR and bodyRotationOffset ~= nil then
	-- 		offsetYaw = bodyRotationOffset
	-- 	end

	-- 	local pawnPos = rootComponent:K2_GetComponentLocation()	
	-- 	local pawnRot = rootComponent:K2_GetComponentRotation()					

	-- 	temp_vec3f:set(rootOffset.X, rootOffset.Y, rootOffset.Z) -- the vector representing the offset adjustment
	-- 	temp_vec3:set(0, 0, 1) --the axis to rotate around
	-- 	local forwardVector = kismet_math_library:RotateAngleAxis(temp_vec3f, pawnRot.Yaw - offsetYaw, temp_vec3)

	-- 	position.x = pawnPos.x + forwardVector.X
	-- 	position.y = pawnPos.y + forwardVector.Y
	-- 	position.z = pawnPos.z + forwardVector.Z

	-- 	rotation.Pitch = 0--pawnRot.Pitch 
	-- 	rotation.Yaw = pawnRot.Yaw - offsetYaw
	-- 	rotation.Roll = 0--pawnRot.Roll 	
	-- end

end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--currentHeadRotator = rotation -- this doesnt work	
	currentHeadRotator.Pitch = rotation.Pitch
	currentHeadRotator.Yaw = rotation.Yaw
	currentHeadRotator.Roll = rotation.Roll
end)

-- uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
-- end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if not isDisabled and aimMethod ~= M.AimMethod.UEVR then
		local yawChange = updateDecoupledYaw(state)

		if yawChange~= 0 and decoupledYaw~= nil and rootComponent ~= nil then
			rootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
		end
	end
end)


-- register_key_bind("F1", function()
    -- print("F1 pressed\n")
	-- --pawn:StartBulletTime(0.0, 50.0, false, 1.0, 0.4, 2.0)
	-- --rootComponent:K2_SetWorldLocation(uevrUtilsvector(lastPosition),false,reusable_hit_result,false)
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- rootComponent:K2_AddWorldOffset(uevrUtils.vector(deltaX,deltaY,0), true, reusable_hit_result, false);
	-- end
-- end)

configui.onCreateOrUpdate("uevr_input_disabled", function(value)
	M.setDisabled(value)
end)

configui.onCreateOrUpdate("headOffset", function(value)
	M.setHeadOffset(value)
end)

configui.onCreateOrUpdate("rootOffset", function(value)
	M.setRootOffset(value)
end)

configui.onUpdate("headBones", function(value)
	setCurrentHeadBone(value)
end)

configui.onCreateOrUpdate("aimMethod", function(value)
	M.setAimMethod(value)
	configui.hideWidget("advanced_input", value == M.AimMethod.UEVR)
	if value ~= M.AimMethod.UEVR then
		controllers.createController(0)
		controllers.createController(1)
		controllers.createController(2)
	end
end)

configui.onCreateOrUpdate("useSnapTurn", function(value)
	M.setUseSnapTurn(value)
	configui.hideWidget("snapAngle", not value)
	configui.hideWidget("smoothTurnSpeed", value)
end)

configui.onCreateOrUpdate("snapAngle", function(value)
	M.setSnapAngle(value)
end)

configui.onCreateOrUpdate("smoothTurnSpeed", function(value)
	M.setSmoothTurnSpeed(value)
end)

configui.onCreateOrUpdate("pawnRotationMode", function(value)
	M.setPawnRotationMode(value)
	configui.hideWidget("minAngularDeviation", not (value == M.PawnRotationMode.SIMPLE or value == M.PawnRotationMode.ADVANCED))
	configui.hideWidget("alignConfidenceThreshold",  value ~= M.PawnRotationMode.ADVANCED)
end)

configui.onCreateOrUpdate("pawnPositionMode", function(value)
	M.setPawnPositionMode(value)
	configui.hideWidget("pawnPositionAnimationScale", value ~= M.PawnPositionMode.ANIMATED)
	configui.hideWidget("pawnPositionSweepMovement", value ~= M.PawnPositionMode.FOLLOWS)
end)

configui.onCreateOrUpdate("pawnPositionAnimationScale", function(value)
	M.setPawnPositionAnimationScale(value)
end)

configui.onCreateOrUpdate("adjustForAnimation", function(value)
	M.setAdjustForAnimation(value)
	configui.hideWidget("headBones", not value)
end)

configui.onCreateOrUpdate("adjustForEyeOffset", function(value)
	M.setAdjustForEyeOffset(value)
	configui.hideWidget("eyeOffset", not value)
end)

configui.onCreateOrUpdate("eyeOffset", function(value)
	M.setEyeOffset(value)
end)

configui.onCreateOrUpdate("pawnPositionSweepMovement", function(value)
	M.setPawnPositionSweepMovement(value)
end)

configui.onCreateOrUpdate("fixSpatialAudio", function(value)
	M.setFixSpatialAudio(value)
end)

configui.onCreateOrUpdate("uevr_handedness", function(value)
	uevrUtils.setHandedness(value-1)
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	decoupledYaw = nil
	bodyRotationOffset = 0
end)

function M.resetView()
	decoupledYaw = nil
	bodyRotationOffset = 0
	uevr.params.vr.recenter_view()
end

uevrUtils.registerLevelChangeCallback(function(level)
	setBoneNames()
	if aimMethod ~= M.AimMethod.UEVR then
		controllers.createController(0)
		controllers.createController(1)
		controllers.createController(2)
	end

	doFixSpatialAudio()
end)

uevrUtils.registerUEVRCallback("gunstock_transform_change", function(id, newLocation, newRotation)
	M.setAimRotationOffset(newRotation)
end)

uevrUtils.registerUEVRCallback("attachment_grip_rotation_change", function(leftRotation, rightRotation)
	M.setWeaponRotation(leftRotation, rightRotation)
end)

uevrUtils.registerHandednessChangeCallback(function(handed)
	configui.setValue("uevr_handedness", handed + 1, true)
end)

return M

	-- local controllerID = 1
	-- local rotation1 = controllers.getControllerRotation(controllerID)
	-- local direction1 = controllers.getControllerDirection(controllerID)
	-- local location1 = controllers.getControllerLocation(controllerID)
	-- local rotation2 = nil
	-- local location2 = nil
	-- local direction2 = nil
	-- local index = uevrUtils.getControllerIndex(controllerID)
	-- if index ~= nil then
		-- uevr.params.vr.get_pose(index, temp_vec3f, temp_quatf)
		-- local poseQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, -temp_quatf.W)  --reordered terms to convert UEVR to unreal coord system
		-- print(temp_quatf.X,temp_quatf.Y,temp_quatf.Z,temp_quatf.W)
		-- direction2 = kismet_math_library:Quat_RotateVector(poseQuat, uevrUtils.vector(1, 0, 0)) --converts UEVR to Unreal coord system
		-- location2 = uevrUtils.vector(temp_vec3f.X*100,temp_vec3f.Z*100,temp_vec3f.Y*100)
		-- location2 = kismet_math_library:Quat_RotateVector(poseQuat,location2) --converts UEVR to Unreal coord system
		-- rotation2 = kismet_math_library:Quat_Rotator(poseQuat)
	-- end	
	-- uevr.params.vr.get_rotation_offset(temp_quatf) --This is how much the head was twisted from the pose quat the last time "recenter view" was performed
	-- local headQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, temp_quatf.W) --reordered terms to convert UEVR to unreal coord system
	-- local headRotator = kismet_math_library:Quat_Rotator(headQuat)

	-- if rotation1 ~= nil then
		-- print("ROT1",rotation1.Pitch,rotation1.Yaw,rotation1.Roll)
	-- end
	-- -- if rotation2 ~= nil then
		-- -- print("ROT2",rotation2.Pitch,rotation2.Yaw,rotation2.Roll)
	-- -- end
	-- -- if location1 ~= nil then
		-- -- print("LOC1",location1.X,location1.Y,location1.Z)
	-- -- end
	-- -- if location2 ~= nil then
		-- -- print("LOC2",location2.X,location2.Y,location2.Z)
	-- -- end
	-- -- if direction1 ~= nil then
		-- -- print("DIR1",direction1.X,direction1.Y,direction1.Z)
	-- -- end
	-- -- if direction2 ~= nil then
		-- -- print("DIR2",direction2.X,direction2.Y,direction2.Z)
	-- -- end
	-- -- if headRotator ~= nil then
		-- -- print("HEAD",headRotator.Pitch,headRotator.Yaw,headRotator.Roll)
	-- -- end
