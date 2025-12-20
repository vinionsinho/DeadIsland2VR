--Hand component system for VR hand tracking and animation in Unreal Engine VR mods

--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    To create hands for a game, add code like this in your script:
		local uevrUtils = require('libs/uevr_utils')
		local hands = require('libs/hands')
		hands.enableConfigurationTool()
	To use hands created with the configuration tool, just comment out the enableConfigurationTool() line.

    This module provides comprehensive hand tracking, animation, and attachment management for VR applications.
    It supports skeletal mesh hands, finger animations, weapon attachments, and integration with controller input.
        
    Available functions:
    
    hands.enableConfigurationTool() - enables the in-game configuration tool for hands
        example:
            hands.enableConfigurationTool()

    hands.createFromConfig(configuration, profileName, animationName) - creates hands from configuration data
        This call is optional. If not used then the module will attempt to automatically load the configuration
		from hands_parameters.json if it exists in the data folder
		example:
			local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
			local configName = 'Main' -- the name you gave your config
			local animationName = 'Shared' -- the name you gave your animation
			hands.createFromConfig(paramsFile, configName, animationName)

    hands.setAutoHandleInput(val) - enables/disables automatic input handling for hand animations.
		Automatic input handling is enabled by default. If you do not want automatic input handling then you will need 
		to call hands.handleInput() or hands.handleInputForHands() manually each tick, like this
			function on_xinput_get_state(retval, user_index, state)
				if hands.exists() then
					local isHoldingWeapon = false
					local hand = Handed.Right
					hands.handleInput(state, isHoldingWeapon, hand)
				end
			end

        example:
            hands.setAutoHandleInput(false)  -- Disable automatic input handling
    
    hands.setAutoCreateHands(val) - enables/disables automatic creation of hands from configuration
		Automatic hand creation is enabled by default. If disabled, hands will not be automatically created
		from hands_parameters.json and you will need to call hands.createFromConfig() manually.
        example:
            hands.setAutoCreateHands(false)  -- Disable automatic hand creation
    
	hands.handleInput(state, attachment, hand, overrideTrigger) - processes controller input for single hand
		You only need to call this if you are not using automatic input handling. Call either handleInput or handleInputForHands, not both
        examples:
            hands.handleInput(inputState, true, Handed.Right, false)
            hands.handleInput(inputState, "pistol", Handed.Right, false)

    hands.handleInputForHands(state, rightAttachment, leftAttachment, overrideTrigger) -- processes input for both hands
		You only need to call this if you are not using automatic input handling. Call either handleInput or handleInputForHands, not both
        example:
            hands.handleInputForHands(inputState, "rifle", nil, false) -- right hand rifle attachment grip
            hands.handleInputForHands(inputState, nil, true, false) -- left hand default attachment grip
            hands.handleInputForHands(inputState, "rifle", true, false) -- right hand rifle attachment grip and left hand default attachment grip

    hands.setHoldingAttachment(hand, val) - sets what attachment a hand is holding. If you are using
		automatic input handling then you can use this to set which hand is holding what attachment.
		If you are not using automatic input handling then hands.handleInput(state, isHoldingWeapon, hand)
		determines what the hand is holding.
        example:
            hands.setHoldingAttachment(Handed.Left, true)  -- Left hand the default attachment
            hands.setHoldingAttachment(Handed.Right, "rifle")  -- Right hand holding rifle attachment

    hands.exists() - returns true if hand components exist and are valid
        example:
            if hands.exists() then
                -- Do something with hands
            end

    hands.getHandComponent(hand, (optional)componentName) - gets the skeletal mesh component for a specific hand
        example:
            local rightHand = hands.getHandComponent(Handed.Right)

    hands.setInitialTransform(hand, (optional)componentName) - resets hand to initial transform/pose
        example:
            hands.setInitialTransform(Handed.Left)

    hands.updateAnimationFromMesh(hand, mesh, (optional)componentName) - updates hand animation from external mesh
		The hands mesh is a copy of an original player mesh. The original player mesh has animations but the 
		copy does not. While this function is being called on the tick, it copies the bone transforms from the 
		original mesh to the hand mesh, thereby animating the hands as if they were the original mesh. If you
		do not want to do this manually, call hands.setAnimationMesh(mesh) and then implement hands.registerIsAnimatingFromMeshCallback(func)
        example:
			uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
            	hands.updateAnimationFromMesh(Handed.Right, originalArmsMesh)
			end)
    
    hands.setAnimationMesh(mesh) - sets the default animation mesh for hands
        example:
            hands.setAnimationMesh(originalArmsMesh)

	hands.registerIsAnimatingFromMeshCallback(func) - registers callback for external animation state changes
		Return nil if no change, true/false to set animating state
        example:
            hands.setAnimationMesh(originalArmsMesh)
			local isLeftHandAnimating = true --change this param at runtime based on game logic
            hands.registerIsAnimatingFromMeshCallback(function(hand, isAnimating)
				return hand == Handed.Left and isLeftHandAnimating or nil
            end)

    hands.hideHands(val) - shows/hides hand components
        example:
            hands.hideHands(true)  -- Hide hands

    hands.registerIsHiddenCallback(func) - registers callback for when hands are shown/hidden
        example:
            hands.registerIsHiddenCallback(function(isHidden)
                print("Hands hidden:", isHidden)
            end)

    hands.destroyHands() - destroys all hand components and cleans up resources
        example:
            hands.destroyHands()
		
	hands.reset() - resets the hand system to default state
        example:
            hands.reset()

    hands.setLogLevel(val) - sets the logging level for hand system messages
        example:
            hands.setLogLevel(LogLevel.Debug)


--]]

local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local attachments = require("libs/attachments")
local pawnModule = require("libs/pawn")

local M = {}

local autoHandleInput = true
local autoCreateHands = true
local autoCreateConfigName = nil
local autoCreateAnimationName = nil

local handComponents = {}
local handDefinitions = {}
local handBoneList = {} --used for debugging
local offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}
local inputHandlerAnimID = {} --list of animID only used for the default input handler
local handsConfig = nil -- the configuration tool for creating hands in game
local holdingAttachment = {}

--externally controlled animations
local armsAnimationMeshes = {}
armsAnimationMeshes[Handed.Left] = {animating=false, mesh=nil, componentName=nil}
armsAnimationMeshes[Handed.Right] = {animating=false, mesh=nil, componentName=nil}
local defaultAnimationMesh = nil

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[hands] " .. text, logLevel)
	end
end

local function executeOnCreatedCallback(...)
	return uevrUtils.executeUEVRCallbacks("on_hands_created", table.unpack({...}))
end
function M.onCreatedCallback(func)
	uevrUtils.registerUEVRCallback("on_hands_created", func)
end

local function executeIsHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_hands_hidden", table.unpack({...}))
end
function M.registerIsHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_hands_hidden", func)
end

local function executeIsAnimatingFromMeshCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_hands_animating_from_mesh", table.unpack({...}))
end
function M.registerIsAnimatingFromMeshCallback(func)
	uevrUtils.registerUEVRCallback("is_hands_animating_from_mesh", func)
end

local createInputHandler = doOnce(function()
	attachments.registerOnGripAnimationCallback(function(gripAnimation, gripHand)
		M.print("Grip animation changed to " .. (gripAnimation and tostring(gripAnimation) or "None") .. " for " .. (gripHand == Handed.Left and "Left" or "Right") .. " hand", LogLevel.Debug)
		--print("Grip animation changed to ", gripAnimation, gripHand)
		M.updateAnimationState(gripHand)
	end)

	uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
		if autoHandleInput and M.exists() then
			local rightAttachment = holdingAttachment[Handed.Right] or attachments.getCurrentGripAnimation(Handed.Right)
			local leftAttachment = holdingAttachment[Handed.Left] or attachments.getCurrentGripAnimation(Handed.Left)
			--M.handleInput(state, attachment, Handed.Right, nil, true)
			M.handleInputForHands(state, rightAttachment, leftAttachment, nil, true)
		end
	end, 10) --high priority to intercept messages before possible remapper
end, Once.EVER)

local function getValidVector(definition, id, default)
	if definition == nil or id == nil or definition[id] == nil then
		return uevrUtils.vector(default[1], default[2], default[3])
	end
	return uevrUtils.vector(definition[id][1], definition[id][2], definition[id][3])
end

local function getValidRotator(definition, id, default)
	if definition == nil or id == nil or definition[id] == nil then
		return uevrUtils.rotator(default[1], default[2], default[3])
	end
	return uevrUtils.rotator(definition[id][1], definition[id][2], definition[id][3])
end

local function getComponentName(componentName)
	local foundName = componentName
	if componentName == nil then --just get the first one
		for name, component in pairs(handComponents) do
			foundName = name
			break
		end
	end
	return foundName == nil and "" or foundName
end

local function getAnimIDSuffix(animID)
	local arr = uevrUtils.splitStr(animID, "_")
	return #arr > 0 and arr[#arr] or nil
end

function M.enableConfigurationTool()
	handsConfig = require('libs/config/hands_config')
end

function M.setAutoHandleInput(val)
	autoHandleInput = val
end

function M.setAutoCreateHands(val)
	autoCreateHands = val
end

function M.setHoldingAttachment(hand, val)
	holdingAttachment[hand] = val
	M.updateAnimationState(hand)
end

function M.reset()
	handComponents = {}
	handDefinitions = {}
	handBoneList = {}
	offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}
	inputHandlerAnimID = {}
	armsAnimationMeshes[Handed.Left] = {animating=false, mesh=nil, componentName=nil}
	armsAnimationMeshes[Handed.Right] = {animating=false, mesh=nil, componentName=nil}
	defaultAnimationMesh = nil
end

function M.exists()
	return M.getHandComponent(Handed.Left) ~= nil or M.getHandComponent(Handed.Right) ~= nil
end

function M.resetAutoCreate()
	autoCreateHands = true
	autoCreateConfigName = nil
	autoCreateAnimationName = nil
end

-- if using multiple components like hands and gloves then include componentName or which one is picked will be random
function M.getHandComponent(hand, componentName)
	componentName = getComponentName(componentName)
	if handComponents[componentName] ~= nil then
		return handComponents[componentName][hand]
	end
end

local fixEnabled = false
local currentProfile = nil
local function registerFOVFix(profile)
	currentProfile = profile

	if currentProfile ~= nil and fixEnabled == false then
		setInterval(1000, function()
			if currentProfile ~= nil then
				for name, components in pairs(handComponents) do
					local fovFixParam = currentProfile[name]["FOV"]
					--print(name, profileName, fovFixParam, components[0], components[1])
					if fovFixParam ~= nil and fovFixParam ~= "" then
						uevrUtils.fixMeshFOV(components[Handed.Left], fovFixParam, 0.0, true, true, false)
						uevrUtils.fixMeshFOV(components[Handed.Right], fovFixParam, 0.0, true, true, false)
					end
				end
			end
		end)
		fixEnabled = true
	end
end

local function getAttachmentStateAndExtension(attachment)
	local isHoldingAttachment = false
	local attachmentExtension = ""
	if type(attachment) == "boolean" then
		isHoldingAttachment = attachment
	elseif type(attachment) == "string" and attachment ~= "attachment_none" then
		isHoldingAttachment = true
		if attachment ~= "" then
			attachmentExtension = "_" .. attachment
		end
	end
	return isHoldingAttachment, attachmentExtension
end

function M.updateAnimationState(hand)
	if M.exists() then
		local attachment = holdingAttachment[hand]
		if attachment == nil then
			attachment = attachments.getCurrentGripAnimation(hand)
		end
		M.print("Updating animation state for " .. (hand == Handed.Left and "Left" or "Right") .. " hand with attachment: " .. (type(attachment) == "string" and attachment or tostring(attachment)), LogLevel.Debug)
		local isHoldingAttachment, attachmentExtension = getAttachmentStateAndExtension(attachment)
		M.print("Is holding attachment: " .. tostring(isHoldingAttachment), LogLevel.Debug)

		if isHoldingAttachment then
			for id, target in pairs(inputHandlerAnimID) do
				local handStr = hand == Handed.Left and "left" or "right"
				animation.resetAnimation(handStr.."_"..target, handStr.."_grip_weapon" .. attachmentExtension, true) --forces an update regardless of current state
				animation.resetAnimation(handStr.."_"..target, handStr.."_trigger_weapon" .. attachmentExtension, true) --forces an update regardless of current state
				animation.pose(handStr .. "_" .. target, "grip_" .. handStr .. "_weapon" .. attachmentExtension)
			end
		else
			for id, target in pairs(inputHandlerAnimID) do
				local handStr = hand == Handed.Left and "left" or "right"
				animation.pose(handStr .. "_" .. target, "open_" .. handStr)
			end
		end
	end
end

function M.createFromConfig(configuration, profileName, animationName)
	if type(configuration) == "string" then
		configuration = json.load_file(configuration .. ".json")
	end
	if configuration ~= nil and configuration["profiles"] ~= nil then
		local profile = configuration["profiles"][profileName]
		if profile ~= nil then
			local components = {}
			for key, mesh in pairs(profile) do
				--key = "Arms"
				local meshPropertyName = mesh["Mesh"]
				if meshPropertyName ~= "" then
					local component = uevrUtils.getObjectFromDescriptor(meshPropertyName) -- "Pawn.Mesh(Arm).Glove")
					if component ~= nil then
						components[key] = component
					end
				end
			end

			local animations = nil
			if configuration["animations"] ~= nil and animationName ~= nil and animationName ~= "" then
				animations = configuration["animations"][animationName]
				-- animDef = {}
				-- local poses = {}
				-- poses["open_left"] = { {"left_grip","off"}, {"left_trigger","off"}, {"left_thumb","off"} }
				-- poses["open_right"] = { {"right_grip","off"}, {"right_trigger","off"}, {"right_thumb","off"} }
				-- poses["grip_right_weapon"] = { {"right_grip_weapon","on"}, {"right_trigger_weapon","off"} }
				-- poses["grip_left_weapon"] = { {"left_grip_weapon","on"}, {"left_trigger_weapon","off"} }

				-- animDef.positions = animations
				-- animDef.poses = poses
			end

			M.create(components, profile, animations)

			--if M.exists() then
				attachments.setAnimationIDs(configuration["attachments"])
				--going to need to call fixMeshFOV on lazy poll
				for name, components in pairs(handComponents) do
					--print(name, profileName, components[0], components[1])
					local fovFixParam = configuration["profiles"][profileName][name]["FOV"]
					if fovFixParam ~= nil and fovFixParam ~= "" then
						uevrUtils.fixMeshFOV(components[Handed.Left], fovFixParam, 0.0, true, true, false)
						uevrUtils.fixMeshFOV(components[Handed.Right], fovFixParam, 0.0, true, true, false)
						registerFOVFix(profile)
					end
				end
			--end

		end
	else
		M.print("Could not create from config because configuration is invalid")
		--json.dump_file("debug.json", configuration, 4)
	end
end

--skeletalMeshComponent can either be a single component or a table of components
function M.create(skeletalMeshComponent, definition, handAnimations)
	if definition ~= nil then
		for name, skeletalMeshDefinition in pairs(definition) do
			if skeletalMeshDefinition["Offset"] ~= nil then
				offset = skeletalMeshDefinition["Offset"]
			end
			M.print("Creating hand component: " .. name )
			local component = nil
			if type(skeletalMeshComponent) == "table" then
				component = skeletalMeshComponent[name]
			else
				component = skeletalMeshComponent
			end
			if uevrUtils.validate_object(component) ~= nil then
				handComponents[name] = {}
				for index = Handed.Left , Handed.Right do
					handComponents[name][index] = M.createComponent(component, name, index, skeletalMeshDefinition[index==Handed.Left and "Left" or "Right"])
					if handComponents[name][index] ~= nil then
						M.print("Created " .. name .. " component: " .. (index==Handed.Left and "Left" or "Right"), LogLevel.Info )
						if skeletalMeshDefinition["FOV"] ~= nil and skeletalMeshDefinition["FOV"] ~= "" then
							uevrUtils.fixMeshFOV(handComponents[name][index], skeletalMeshDefinition["FOV"], 0.0, true, true, false)
						end

						local initialTransform = skeletalMeshDefinition["InitialTransform"]
						if initialTransform ~= nil then
							animation.initializeBones(handComponents[name][index], initialTransform[index==Handed.Left and "left_hand" or "right_hand"])
						end

						local animID = skeletalMeshDefinition[index==Handed.Left and "Left" or "Right"]["AnimationID"]
						if animID ~= nil then
							local suffix = getAnimIDSuffix(animID)
							if suffix ~= nil then inputHandlerAnimID[animID] = suffix end
							animation.add(animID, handComponents[name][index], handAnimations)
							animation.initialize(animID, handComponents[name][index])
						end
						executeOnCreatedCallback(index, handComponents[name][index])
					end
				end
				if autoHandleInput == true then
					createInputHandler()
					M.updateAnimationState(Handed.Left)
					M.updateAnimationState(Handed.Right)
				end
			else
				M.print("Call to create " .. name .. " failed, invalid skeletalMeshComponent", LogLevel.Info )
			end
		end

		handDefinitions = definition
	else
		M.print("Call to create failed, invalid definiton", LogLevel.Warning )
	end
end

function M.createComponent(skeletalMeshComponent, name, hand, definition)
	local component = nil
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		--not using an existing actor as owner. Mesh affects the hands opacity so its not appropriate
		component = animation.createPoseableComponent(skeletalMeshComponent, nil, definition ~= nil and definition["UseDefaultPose"] == true)
		if component ~= nil then
			--fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
			--a better way to do this should be found
			component.BoundsScale = 16.0
			component.bCastDynamicShadow = false

			controllers.attachComponentToController(hand, component)
			local baseRotation = skeletalMeshComponent.RelativeRotation
			uevrUtils.set_component_relative_transform(component, offset, {Pitch=baseRotation.Pitch+offset.Pitch, Yaw=baseRotation.Yaw+offset.Yaw,Roll=baseRotation.Roll+offset.Roll})

			if definition ~= nil then
				local jointName = definition["Name"]
				if jointName ~= nil and jointName ~= "" then
					local location = getValidVector(definition, "Location", {0,0,0})
					local rotation = getValidRotator(definition, "Rotation", {0,0,0})
					local scale = getValidVector(definition, "Scale", {1,1,1})
					local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
					animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)
				else
					M.print("Could not initialize bone in createComponent() because joint name is invalid" )
				end
			end
		end
	else
		M.print("SkeletalMesh component is nil in createComponent()" )
	end
	return component
end

function M.setInitialTransform(hand, componentName)
	componentName = getComponentName(componentName)
	if componentName == nil or componentName == "" or handDefinitions[componentName] == nil then
		M.print("Could not update set initial transform because component is undefined")
	else
		local initialTransform = handDefinitions[componentName]["InitialTransform"]
		if initialTransform ~= nil then
			local component = M.getHandComponent(hand, componentName)
			local handStr = hand == Handed.Left and "left_hand" or "right_hand"
			animation.initializeBones(component, initialTransform[handStr])
		end
	end
end

-- function M.enableOptimizedAnimations(val)
-- 	optimizeAnimationFromMesh = val
-- end

--if, in debug mode, the skeleton is not pointed forward when the wrist is pointed forward then make adjustments with this function
function  M.setOffset(newOffset)
	offset = newOffset
end

--only for debugging
function M.updateOffset(skeletalMeshComponent, newOffset)
	if skeletalMeshComponent ~= nil then
		local baseRotation = skeletalMeshComponent.RelativeRotation
		local component = handComponents["Arms"][Handed.Right]
		uevrUtils.set_component_relative_transform(component, newOffset, {Pitch=baseRotation.Pitch+newOffset.Pitch, Yaw=baseRotation.Yaw+newOffset.Yaw,Roll=baseRotation.Roll+newOffset.Roll})
	end
end

function M.addRealism()

end

function M.setAnimationMesh(mesh)
	defaultAnimationMesh = mesh
end

function M.updateAnimationFromMesh(hand, mesh, componentName)
	--print("Updating animation from mesh", hand, mesh:get_full_name(), componentName)
	if mesh ~= nil then
		componentName = getComponentName(componentName)
		if componentName == nil or componentName == "" or handDefinitions[componentName] == nil then
			M.print("Could not update Animation From Mesh because component is undefined")
		else
			local component = M.getHandComponent(hand, componentName)
			local handStr = hand == Handed.Left and "Left" or "Right"
			local definition = handDefinitions[componentName][handStr]
			if definition ~= nil then
				local jointName = definition["Name"]
				if jointName ~= nil and jointName ~= "" then
					local success, response = pcall(function()		
						component:CopyPoseFromSkeletalComponent(mesh)
						--component:SetLeaderPoseComponent(mesh, true)
						local location = getValidVector(definition, "Location", {0,0,0})
						local rotation = getValidRotator(definition, "Rotation", {0,0,0})
						local scale = getValidVector(definition, "Scale", {1,1,1})
						local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
						--When an animation is applied, every bone in the entire skeleton is moved, so we need to reapply the transform from wrist to root
						local optimizeAnimationFromMesh = handDefinitions[componentName]["OptimizeAnimations"] ~= false
						local optimizationRootBone = definition["OptimizeAnimationsRootBone"]
						animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset, optimizeAnimationFromMesh, optimizationRootBone)
						--component:SetLeaderPoseComponent(nil, false)
					end)
					if success == false then
						M.print("[hands] " .. response, LogLevel.Error)
					end
				end
			end
		end
	end
end

function M.setHandsAreAnimatingFromMesh(isLeftAnimating, isRightAnimating, leftMesh, rightMesh, componentName)
	if isLeftAnimating ~= nil then
		if isLeftAnimating == true and armsAnimationMeshes[Handed.Left].animating ~= true then
			armsAnimationMeshes[Handed.Left].mesh = leftMesh and leftMesh or (uevrUtils.getValid(defaultAnimationMesh) ~= nil and defaultAnimationMesh or pawnModule.getArmsAnimationMesh())
			armsAnimationMeshes[Handed.Left].componentName = componentName
		elseif isLeftAnimating == false and armsAnimationMeshes[Handed.Left].animating == true then
			M.setInitialTransform(Handed.Left)
			armsAnimationMeshes[Handed.Left].mesh = nil
			armsAnimationMeshes[Handed.Left].componentName = nil
		end
		armsAnimationMeshes[Handed.Left].animating = isLeftAnimating
	end

	if isRightAnimating ~= nil then
		if isRightAnimating == true and armsAnimationMeshes[Handed.Right].animating ~= true then
			armsAnimationMeshes[Handed.Right].mesh = rightMesh and rightMesh or (uevrUtils.getValid(defaultAnimationMesh) ~= nil and defaultAnimationMesh or pawnModule.getArmsAnimationMesh())
			armsAnimationMeshes[Handed.Right].componentName = componentName
		elseif isRightAnimating == false and armsAnimationMeshes[Handed.Right].animating == true then
			M.setInitialTransform(Handed.Right)
			armsAnimationMeshes[Handed.Right].mesh = nil
			armsAnimationMeshes[Handed.Right].componentName = nil
		end
		armsAnimationMeshes[Handed.Right].animating = isRightAnimating
	end
end


--set overrideTrigger to true if the default triggers have already been swapped (ie a plugin or code aleady makes the game do right trigger actions when the left trigger is pulled)
function M.handleInput(state, attachment, hand, overrideTrigger, allowAutoHandle)
	if allowAutoHandle ~= true then
		autoHandleInput = false --if something else is calling this then dont auto handle input
	end

	local isHoldingAttachment, attachmentExtension = getAttachmentStateAndExtension(attachment)

	if hand == nil then hand = Handed.Right end
	if overrideTrigger == nil then overrideTrigger = false end
	local isRightHanded = hand == Handed.Right
	local weaponHandStr = isRightHanded and "right" or "left"
	local offHandStr = isRightHanded and "left" or "right"
	local animDuration = 0.1
	for id, target in pairs(inputHandlerAnimID) do
		local offhandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bLeftTrigger or state.Gamepad.bRightTrigger
		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_trigger", offhandTriggerValue > 100, {duration=animDuration})

		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_grip", uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_LEFT_SHOULDER or XINPUT_GAMEPAD_RIGHT_SHOULDER), {duration=animDuration})

		local offhandController = uevr.params.vr.get_left_joystick_source()
		if not isRightHanded then offhandController = uevr.params.vr.get_right_joystick_source() end
		local offhandRest = uevr.params.vr.get_action_handle(isRightHanded and "/actions/default/in/ThumbrestTouchLeft" or "/actions/default/in/ThumbrestTouchRight")
		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_thumb", uevr.params.vr.is_action_active(offhandRest, offhandController), {duration=animDuration})

		if not isHoldingAttachment then
			local weaponHandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_trigger", weaponHandTriggerValue > 100, {duration=animDuration})

			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip", uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER), {duration=animDuration})

			local weaponhandController = uevr.params.vr.get_right_joystick_source()
			if not isRightHanded then weaponhandController = uevr.params.vr.get_left_joystick_source() end
			local weaponhandRest = uevr.params.vr.get_action_handle(isRightHanded and "/actions/default/in/ThumbrestTouchRight" or "/actions/default/in/ThumbrestTouchLeft")
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_thumb", uevr.params.vr.is_action_active(weaponhandRest, weaponhandController), {duration=animDuration})
		else
			local weaponHandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_trigger_weapon" .. attachmentExtension, weaponHandTriggerValue > 100, {duration=animDuration})
			if uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER) then
				animation.resetAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip_weapon" .. attachmentExtension, false) --forces an update regardless of current state
--print("Here",weaponHandStr.."_"..target,weaponHandStr.."_grip_weapon" .. attachmentExtension)
				animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip_weapon" .. attachmentExtension, true, {duration=animDuration})
			end
		end
	end
end

function M.handleInputForHands(state, rightAttachment, leftAttachment, overrideTrigger, allowAutoHandle)
	if allowAutoHandle ~= true then
		autoHandleInput = false --if something else is calling this then dont auto handle input
	end

	if overrideTrigger == nil then overrideTrigger = false end
	local animDuration = 0.1
	for id, target in pairs(inputHandlerAnimID) do
		for hand = Handed.Left, Handed.Right do
			local handStr = hand == Handed.Right and "right" or "left"
			--do not use ternary operators like this. If right attachment is nil then it will always pick leftAttachment for Handed.Right == true
			--local attachment = hand == Handed.Right and rightAttachment or leftAttachment
			local attachment = nil
			if hand == Handed.Right then attachment = rightAttachment else attachment = leftAttachment end
			local isHoldingAttachment, attachmentExtension = getAttachmentStateAndExtension(attachment)
			--print("Handling input for " .. handStr .. " hand, attachment: " .. (type(attachment) == "string" and attachment or tostring(attachment)) .. ", isHoldingAttachment: " .. tostring(isHoldingAttachment) .. ", attachmentExtension: " .. attachmentExtension)

			if not isHoldingAttachment then
				local weaponHandTriggerValue = (hand == Handed.Right or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
				animation.updateAnimation(handStr.."_"..target, handStr.."_trigger", weaponHandTriggerValue > 100, {duration=animDuration})
				animation.updateAnimation(handStr.."_"..target, handStr.."_grip", uevrUtils.isButtonPressed(state, hand == Handed.Right and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER), {duration=animDuration})

				local weaponhandController = uevr.params.vr.get_right_joystick_source()
				if not (hand == Handed.Right) then weaponhandController = uevr.params.vr.get_left_joystick_source() end
				local weaponhandRest = uevr.params.vr.get_action_handle(hand == Handed.Right and "/actions/default/in/ThumbrestTouchRight" or "/actions/default/in/ThumbrestTouchLeft")
				animation.updateAnimation(handStr.."_"..target, handStr.."_thumb", uevr.params.vr.is_action_active(weaponhandRest, weaponhandController), {duration=animDuration})
			else
				local weaponHandTriggerValue = (hand == Handed.Right or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
				animation.updateAnimation(handStr.."_"..target, handStr.."_trigger_weapon" .. attachmentExtension, weaponHandTriggerValue > 100, {duration=animDuration})
				local isButtonPressed = uevrUtils.isButtonPressed(state, hand == Handed.Right and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER)
				animation.updateAnimation(handStr.."_"..target, handStr.."_grip_weapon" .. attachmentExtension, isButtonPressed, {duration=animDuration})
			end
		end
	end
end

function M.hideHand(hand, val)
	if val == nil then return end
	for name, components in pairs(handComponents) do
		if uevrUtils.getValid(components[hand]) ~= nil and components[hand].SetVisibility ~= nil then
			M.print((val and "Hiding " or "Showing ") .. components[hand]:get_full_name() .. " hand component " .. tostring(hand), LogLevel.Debug)
			components[hand]:SetVisibility(not val, true)
		end
	end
end


function M.hideHands(val)
	if val == nil then return end
	for name, components in pairs(handComponents) do
		if uevrUtils.getValid(components[0]) ~= nil and components[0].SetVisibility ~= nil then
			M.print((val and "Hiding " or "Showing ") .. components[0]:get_full_name() .. " hand components", LogLevel.Debug)
			components[0]:SetVisibility(not val, true)
		end
		if uevrUtils.getValid(components[1]) ~= nil and components[1].SetVisibility ~= nil then
			components[1]:SetVisibility(not val, true)
		end
	end
end


function M.destroyHands()
	--since we didnt use an existing actor as parent in createComponent(), destroy the owner actor too
	for name, components in pairs(handComponents) do
		M.print("Destroying " .. name .. " hand components", LogLevel.Debug)
		uevrUtils.detachAndDestroyComponent(components[0], true)
		uevrUtils.detachAndDestroyComponent(components[1], true)
	end
	M.reset()
end

local visualCallbackExists = false
function M.createSkeletalVisualization(hand, scale, componentName)
	animation.destroySkeletalVisualization()
	if M.exists() then
		if hand == nil then hand = Handed.Right end
		if scale == nil then scale = 0.003 end
		animation.createSkeletalVisualization(M.getHandComponent(hand, componentName), scale)
		if not visualCallbackExists then
			uevrUtils.registerPostEngineTickCallback(function()
				if M.exists() then
					animation.updateSkeletalVisualization(M.getHandComponent(hand, componentName))
				end
			end)
		end
		visualCallbackExists = true
	end
end

local adjustMode = 1  -- 1-hand rotation  2-hand location  3-finger angles
local adjustModeLabels = {"Hand Rotation", "Hand Location", "Finger Angles"}
local currentHand = 1 -- 0-left  1-right
local currentHandLabels = {"Left", "Right"}
local currentIndex = 1	--1-knuckle 
local currentFinger = 1 -- 1-10
local currentFingerLabels = {"Left Thumb", "Left Index", "Left Middle", "Left Ring", "Left Pinky", "Right Thumb", "Right Index", "Right Middle", "Right Ring", "Right Pinky"}
local positionDelta = 0.2
local rotationDelta = 45
local jointAngleDelta = 5

function M.enableHandAdjustments(boneList, componentName)
	handBoneList = boneList
	local logLevel = LogLevel.Critical
	M.print("Adjust Mode " .. adjustModeLabels[adjustMode], logLevel)
	if adjustMode == 3 then
		M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, logLevel)
	else
		M.print("Current hand: " .. currentHandLabels[currentHand+1], logLevel)
	end

	register_key_bind("NumPadFive", function()
		M.print("Num5 pressed")
		adjustMode = (adjustMode % 3) + 1
		M.print("Adjust Mode " .. adjustModeLabels[adjustMode], logLevel)
		if adjustMode == 3 then
			M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, logLevel)
		else
			M.print("Current hand: " .. currentHandLabels[currentHand+1], logLevel)
		end
	end)

	register_key_bind("NumPadNine", function()
		M.print("Num9 pressed")
		currentIndex = (currentIndex % 3) + 1
		M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, logLevel)
	end)

	register_key_bind("NumPadSeven", function()
		M.print("Num7 pressed")
		if adjustMode == 3 then
			currentFinger = (currentFinger % 10) + 1
			M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, logLevel)
		else
			currentHand = (currentHand + 1) % 2
			M.print("Current hand: " .. currentHandLabels[currentHand+1], logLevel)
		end
	end)

	register_key_bind("NumPadEight", function()
		M.print("Num8 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 1, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 1, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 0, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadTwo", function()
		M.print("Num2 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 1, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 1, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 0, -jointAngleDelta, componentName)
		end
	end)

	register_key_bind("NumPadFour", function()
		M.print("Num4 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 2, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 2, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 1, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadSix", function()
		M.print("Num6 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 2, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 2, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 1, -jointAngleDelta, componentName)
		end
	end)

	register_key_bind("NumPadThree", function()
		M.print("Num3 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 3, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 3, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 2, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadOne", function()
		M.print("Num1 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 3, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 3, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 2, -jointAngleDelta, componentName)
		end
	end)
end

function M.setFingerAngles(fingerIndex, jointIndex, angleID, angle, componentName)
	if handBoneList == nil or #handBoneList ==0 then
		M.print("Could not adjust fingers because hand bonelist in invalid")
	else
		componentName = getComponentName(componentName)
		if componentName == "" then
			M.print("Could not adjust rotation because component is undefined")
		else
			local component = M.getHandComponent(fingerIndex < 6 and 0 or 1, componentName)
			animation.setFingerAngles(component, handBoneList, fingerIndex, jointIndex, angleID, angle)
		end
	end
end

uevrUtils.registerUEVRCallback("gunstock_transform_change", function(id, newLocation, newRotation)
	local initialRotation = uevrUtils.rotator(0,0,0)
	if handDefinitions["Arms"] ~= nil and handDefinitions["Arms"]["InitialTransform"] ~= nil and handDefinitions["Arms"]["InitialTransform"]["right_hand"] ~= nil and handDefinitions["Arms"]["InitialTransform"]["right_hand"]["hand_r"] ~= nil and handDefinitions["Arms"]["InitialTransform"]["right_hand"]["hand_r"]["rotation"] ~= nil then
		local rot = handDefinitions["Arms"]["InitialTransform"]["right_hand"]["hand_r"]["rotation"]
		initialRotation = uevrUtils.rotator(rot[1], rot[2], rot[3])
	end
	initialRotation.Pitch = initialRotation.Pitch - newRotation.Yaw
	initialRotation.Yaw = initialRotation.Yaw + newRotation.Pitch
	initialRotation.Roll = initialRotation.Roll - newRotation.Roll
	animation.setBoneRotation(M.getHandComponent(Handed.Right), "hand_r", initialRotation, false)
end)

function M.printHandTranforms(transforms)
	local logLevel = LogLevel.Critical
	if transforms["Rotation"] ~= nil then
		M.print("Rotation = {" .. transforms["Rotation"][1] .. ", " .. transforms["Rotation"][2] .. ", "  .. transforms["Rotation"][3] ..  "}", logLevel)
	end
	if transforms["Location"] ~= nil then
		M.print("Location = {" .. transforms["Location"][1] .. ", " .. transforms["Location"][2] .. ", "  .. transforms["Location"][3] ..  "}", logLevel)
	end
end

-- local function getValidRotator(definition, id, default)
	-- if definition == nil or id == nil or definition[id] == nil then
		-- return uevrUtils.rotator(default[1], default[2], default[3])
	-- end
	-- return uevrUtils.rotator(definition[id][1], definition[id][2], definition[id][3])
-- end

local function getValidArray(definition, id, default)
	if definition == nil or id == nil or definition[id] == nil then
		return default
	end
	return definition[id]
end

--transformType "Rotation", "Location", "Scale"
function M.setTransform(hand, axis, val, transformType, isDelta, componentName)
--print(hand, axis, val, transformType, isDelta, componentName)
	componentName = getComponentName(componentName)
	--print(componentName)
	if componentName == nil or componentName == "" or handDefinitions[componentName] == nil then
		M.print("Could not adjust transform because component is undefined")
	else
		local handStr = hand == Handed.Left and "Left" or "Right"
		local definition = handDefinitions[componentName][handStr]
		if definition ~= nil then
			local jointName = definition["Name"]
			if jointName ~= nil and jointName ~= "" then
				local currentTransforms = {}
				currentTransforms["Location"] = getValidArray(definition, "Location", {0,0,0})
				currentTransforms["Rotation"] = getValidArray(definition, "Rotation", {0,0,0})
				currentTransforms["Scale"] = getValidArray(definition, "Scale", {1,1,1})
				handDefinitions[componentName][handStr][transformType] = currentTransforms[transformType]
				if isDelta then
					handDefinitions[componentName][handStr][transformType][axis] = handDefinitions[componentName][handStr][transformType][axis] + val
				else
					handDefinitions[componentName][handStr][transformType][axis] = val
				end

				local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				local component = M.getHandComponent(hand, componentName)
				animation.transformBoneToRoot(component, jointName, uevrUtils.vector(currentTransforms["Location"]), uevrUtils.rotator(currentTransforms["Rotation"]), uevrUtils.vector(currentTransforms["Scale"]), taperOffset)
				-- print(handDefinitions[componentName][handStr]["Rotation"][1], handDefinitions[componentName][handStr]["Rotation"][2], handDefinitions[componentName][handStr]["Rotation"][3])
				-- print(handDefinitions[componentName][handStr]["Location"][1], handDefinitions[componentName][handStr]["Location"][2], handDefinitions[componentName][handStr]["Location"][3])
				-- print(handDefinitions[componentName][handStr]["Scale"][1], handDefinitions[componentName][handStr]["Scale"][2], handDefinitions[componentName][handStr]["Scale"][3])
				M.printHandTranforms(handDefinitions[componentName][handStr])
			else
				M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			end
		end
	end

end


function M.setRotation(hand, axis, rot, componentName)
	M.setTransform(hand, axis, rot, "Rotation", false, componentName)

	-- componentName = getComponentName(componentName)
	-- print(componentName)
	-- if componentName == nil or componentName == "" or handDefinitions[componentName] == nil then
		-- M.print("Could not adjust rotation because component is undefined")
	-- else	
		-- local handStr = hand == Handed.Left and "Left" or "Right"
		-- local definition = handDefinitions[componentName][handStr]
		-- if definition ~= nil then
			-- local jointName = definition["Name"]
			-- if jointName ~= nil and jointName ~= "" then
				-- local location = getValidVector(definition, "Location", {0,0,0})
				-- --local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				-- if handDefinitions[componentName][handStr]["Rotation"] == nil then
					-- handDefinitions[componentName][handStr]["Rotation"] = {0,0,0}
				-- end
				-- handDefinitions[componentName][handStr]["Rotation"][axis] = rot
				-- local rotation = uevrUtils.rotator(handDefinitions[componentName][handStr]["Rotation"][1], handDefinitions[componentName][handStr]["Rotation"][2], handDefinitions[componentName][handStr]["Rotation"][3])
				-- local scale = getValidVector(definition, "Scale", {1,1,1})
				-- local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				-- local component = M.getHandComponent(hand, componentName)
				-- animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				-- M.printHandTranforms(handDefinitions[componentName][handStr])
			-- else
				-- M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			-- end
		-- end
	-- end
end

function M.adjustRotation(hand, axis, delta, componentName)
	M.setTransform(hand, axis, delta, "Rotation", true, componentName)

	-- componentName = getComponentName(componentName)
	-- if componentName == "" then
		-- M.print("Could not adjust rotation because component is undefined")
	-- else	
		-- local handStr = hand == Handed.Left and "Left" or "Right"
		-- local definition = handDefinitions[componentName][handStr]
		-- if definition ~= nil then
			-- local jointName = definition["Name"]
			-- if jointName ~= nil and jointName ~= "" then
				-- local location = getValidVector(definition, "Location", {0,0,0})
				-- --local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				-- if handDefinitions[componentName][handStr]["Rotation"] == nil then
					-- handDefinitions[componentName][handStr]["Rotation"] = {0,0,0}
				-- end
				-- handDefinitions[componentName][handStr]["Rotation"][axis] = handDefinitions[componentName][handStr]["Rotation"][axis] + delta
				-- local rotation = uevrUtils.rotator(handDefinitions[componentName][handStr]["Rotation"][1], handDefinitions[componentName][handStr]["Rotation"][2], handDefinitions[componentName][handStr]["Rotation"][3])
				-- local scale = getValidVector(definition, "Scale", {1,1,1})
				-- local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				-- local component = M.getHandComponent(hand, componentName)
				-- animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				-- M.printHandTranforms(handDefinitions[componentName][handStr])
			-- else
				-- M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			-- end
		-- end
	-- end
end

function M.setLocation(hand, axis, loc, componentName)
	M.setTransform(hand, axis, loc, "Location", false, componentName)

	-- componentName = getComponentName(componentName)
	-- if componentName == nil or componentName == "" or handDefinitions[componentName] == nil then
		-- M.print("Could not adjust rotation because component is undefined")
	-- else	
		-- local handStr = hand == Handed.Left and "Left" or "Right"
		-- local definition = handDefinitions[componentName][handStr]
		-- if definition ~= nil then
			-- local jointName = definition["Name"]
			-- if jointName ~= nil and jointName ~= "" then
				-- --local location = getValidVector(definition, "Location", {0,0,0})
				-- if handDefinitions[componentName][handStr]["Location"] == nil then
					-- handDefinitions[componentName][handStr]["Location"] = {0,0,0}
				-- end
				-- handDefinitions[componentName][handStr]["Location"][axis] = loc
				-- local location = uevrUtils.vector(handDefinitions[componentName][handStr]["Location"][1], handDefinitions[componentName][handStr]["Location"][2], handDefinitions[componentName][handStr]["Location"][3])
				-- local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				-- local scale = getValidVector(definition, "Scale", {1,1,1})
				-- local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				-- local component = M.getHandComponent(hand, componentName)
				-- animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				-- M.printHandTranforms(handDefinitions[componentName][handStr])
			-- else
				-- M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			-- end
		-- end
	-- end
end


function M.adjustLocation(hand, axis, delta, componentName)
	M.setTransform(hand, axis, delta, "Location", true, componentName)

	-- componentName = getComponentName(componentName)
	-- if componentName == "" then
		-- M.print("Could not adjust rotation because component is undefined")
	-- else	
		-- local handStr = hand == Handed.Left and "Left" or "Right"
		-- local definition = handDefinitions[componentName][handStr]
		-- if definition ~= nil then
			-- local jointName = definition["Name"]
			-- if jointName ~= nil and jointName ~= "" then
				-- --local location = getValidVector(definition, "Location", {0,0,0})
				-- if handDefinitions[componentName][handStr]["Location"] == nil then
					-- handDefinitions[componentName][handStr]["Location"] = {0,0,0}
				-- end
				-- handDefinitions[componentName][handStr]["Location"][axis] = handDefinitions[componentName][handStr]["Location"][axis] + delta
				-- local location = uevrUtils.vector(handDefinitions[componentName][handStr]["Location"][1], handDefinitions[componentName][handStr]["Location"][2], handDefinitions[componentName][handStr]["Location"][3])
				-- local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				-- local scale = getValidVector(definition, "Scale", {1,1,1})
				-- local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				-- local component = M.getHandComponent(hand, componentName)
				-- animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				-- M.printHandTranforms(handDefinitions[componentName][handStr])
			-- else
				-- M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			-- end
		-- end
	-- end
end

function M.setScale(hand, axis, scale, componentName)
	M.setTransform(hand, axis, scale, "Scale", false, componentName)
end

function M.adjustScale(hand, axis, delta, componentName)
	M.setTransform(hand, axis, delta, "Scale", true, componentName)
end

function M.debug(skeletalMeshComponent, hand, rightTargetJoint, disableVisualization)
	local definition = nil
	if rightTargetJoint ~= nil then
		definition = { Name = rightTargetJoint }
	end
	if hand == nil then hand = Handed.Right end
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )
		handComponents["Arms"] = {}
		handComponents["Arms"][hand] = M.createComponent(skeletalMeshComponent, "Arms", hand, definition)

		animation.logBoneNames(skeletalMeshComponent)
		if disableVisualization ~= true then
			M.createSkeletalVisualization(hand)
		end
	else
		M.print("SkeletalMesh component is nil in create" )
	end
end

local isHiddenLast = nil
uevrUtils.setInterval(100, function()
	if M.exists() then
		local isHidden, priority = executeIsHiddenCallback()
		if isHidden ~= isHiddenLast then
			isHiddenLast = isHidden
			M.hideHands(isHidden or false)
		end
	end
end)

local isLeftAnimatingLast = nil
local isRightAnimatingLast = nil
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if M.exists() then
		local isLeftAnimating,  leftPriority = executeIsAnimatingFromMeshCallback(Handed.Left)
		local isRightAnimating, rightPriority = executeIsAnimatingFromMeshCallback(Handed.Right)
		--print(isLeftAnimating, isRightAnimating)
		local left = isLeftAnimating
		if isLeftAnimatingLast ~= nil and isLeftAnimating == nil then left = false end
		local right = isRightAnimating
		if isRightAnimatingLast ~= nil and isRightAnimating == nil then right = false end
		M.setHandsAreAnimatingFromMesh(left, right)
		isLeftAnimatingLast = isLeftAnimating
		isRightAnimatingLast = isRightAnimating

		if armsAnimationMeshes[Handed.Left] ~= nil and armsAnimationMeshes[Handed.Left].mesh ~= nil then
			M.updateAnimationFromMesh(Handed.Left, armsAnimationMeshes[Handed.Left].mesh,  armsAnimationMeshes[Handed.Left].componentName)
		end
		if armsAnimationMeshes[Handed.Right] ~= nil and armsAnimationMeshes[Handed.Right].mesh ~= nil then
			M.updateAnimationFromMesh(Handed.Right, armsAnimationMeshes[Handed.Right].mesh,  armsAnimationMeshes[Handed.Right].componentName)
		end
	end
end)

uevr.params.sdk.callbacks.on_script_reset(function()
	M.destroyHands()
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	M.print("Pre-Level changed in hands")
	M.reset()
	isHiddenLast = false
	autoHandleInput = true
	isLeftAnimatingLast = nil
	isRightAnimatingLast = nil
	autoCreateConfigName = nil
	autoCreateAnimationName = nil
end)

local function tryAutoCreateHands()
	if autoCreateHands and not M.exists()then
		--see if the defaults params file exists
		local paramsFile = "hands_parameters"
		--if we already found it once we dont ned to keep reading from json to see if it exists
		if autoCreateConfigName ~= nil then
			M.createFromConfig(paramsFile, autoCreateConfigName, autoCreateAnimationName)
		else
			local configuration = json.load_file(paramsFile .. ".json")
			if configuration ~= nil then
				--get the first profile and animation found
				M.print("Loaded hands parameters from hands_parameters.json")
				if configuration["profiles"] ~= nil then
					for key, _ in pairs(configuration["profiles"]) do
						M.print("Found profile: " .. key)
						autoCreateConfigName = key
						break
					end
				end
				if configuration["animations"] ~= nil then
					for key, _ in pairs(configuration["animations"]) do
						M.print("Found animation: " .. key)
						autoCreateAnimationName = key
						break
					end
				end
				if autoCreateConfigName ~= nil then
					M.createFromConfig(paramsFile, autoCreateConfigName, autoCreateAnimationName)
				else
					M.print("Could not auto create hands because no profiles were found")
					autoCreateHands = false --dont keep trying
				end
			else
				M.print("Could not auto create hands")
				autoCreateHands = false --dont keep trying
			end
		end
	end
end

uevrUtils.setInterval(1000, function()
	tryAutoCreateHands()
end)

return M


--deprecated code
-- local currentRightRotation = {0, 0, 0}
-- local currentRightLocation = {0, 0, 0}
-- local currentLeftRotation = {0, 0, 0}
-- local currentLeftLocation = {0, 0, 0}
-- local currentScale = 1.0
-- 

-- local rightHandComponent = nil
-- local leftHandComponent = nil

-- local leftJointName = ""
-- local rightJointName = ""

-- function M.create(skeletalMeshComponent, leftTargetJoint, rightTargetJoint, rightRotation, rightLocation, leftRotation, leftLocation, pHandBoneList, scale)
	-- if uevrUtils.validate_object(skeletalMeshComponent) ~= nil and leftTargetJoint ~= nil and leftTargetJoint ~= "" and rightTargetJoint ~= nil and rightTargetJoint ~= "" then
		-- leftJointName = leftTargetJoint
		-- rightJointName = rightTargetJoint
		-- if pHandBoneList ~= nil then handBoneList = pHandBoneList end
		-- if rightRotation ~= nil then currentRightRotation = rightRotation end
		-- if rightLocation ~= nil then currentRightLocation = rightLocation end
		-- if leftRotation ~= nil then currentLeftRotation = leftRotation end
		-- if leftLocation ~= nil then currentLeftLocation = leftLocation end
		-- if scale ~= nil then currentScale = scale end
		-- M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )	
		-- rightHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 1)
		-- if rightHandComponent ~= nil then
			-- leftHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 0)	

			-- animation.add("right_hand", rightHandComponent, handAnimations)
			-- animation.add("left_hand", leftHandComponent, handAnimations)			
		-- end
	-- else
		-- M.print("SkeletalMesh component is nil or target joints are invalid in create" )
	-- end
-- end

-- function M.createComponent(skeletalMeshComponent, name, hand, disableInit)
	-- local component = nil
	-- if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		-- --not using an existing actor as owner. Mesh affects the hands opacity so its not appropriate
		-- component = animation.createPoseableComponent(skeletalMeshComponent, nil)
		-- if component ~= nil then
			-- --fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
			-- --a better way to do this should be found
			-- component.BoundsScale = 16.0
			-- component.bCastDynamicShadow = false

			-- controllers.attachComponentToController(hand, component)
			-- local baseRotation = skeletalMeshComponent.RelativeRotation
			-- uevrUtils.set_component_relative_transform(component, offset, {Pitch=baseRotation.Pitch+offset.Pitch, Yaw=baseRotation.Yaw+offset.Yaw,Roll=baseRotation.Roll+offset.Roll})	

			-- if disableInit ~= true then
				-- local location = hand == 1 and uevrUtils.vector(currentRightLocation[1], currentRightLocation[2], currentRightLocation[3]) or uevrUtils.vector(currentLeftLocation[1], currentLeftLocation[2], currentLeftLocation[3])
				-- local rotation = hand == 1 and uevrUtils.rotator(currentRightRotation[1], currentRightRotation[2], currentRightRotation[3]) or uevrUtils.rotator(currentLeftRotation[1], currentLeftRotation[2], currentLeftRotation[3])
				-- --animation.initPoseableComponent(component, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
				-- animation.transformBoneToRoot(component, (hand == 1) and rightJointName or leftJointName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), uevrUtils.vector(20, 0, 0))		
			-- end
		-- end
	-- end
	-- return component
-- end
