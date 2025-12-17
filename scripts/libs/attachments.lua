--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local attachments = require("libs/attachments")
        local isDeveloperMode = true  
        attachments.init(isDeveloperMode)

    Available functions:

    attachments.init(isDeveloperMode, logLevel, defaultLocation, defaultRotation, defaultScale) - initializes the attachments system
        example:
            attachments.init(true, LogLevel.Debug, {0,0,0}, {0,0,0}, {1,1,1})

    attachments.attachToMesh(attachment, mesh, socketName, gripHand, detachFromParent) - attaches an object to a mesh at a specified socket
		The parameter gripHand is used to determine which hand's grip animation to use for the attachment. Set to nil if there is no animation 
		needed or if this is not a grip attachment.
        example:
            attachments.attachToMesh(myAttachment, targetMesh, "hand_socket", Handed.Right, true)

    attachments.attachToController(attachment, controllerID, detachFromParent) - attaches an object to a VR controller
        example:
            attachments.attachToController(myAttachment, Handed.Right, true)

    attachments.detach(attachment, parent) - detaches an object from its parent
        example:
            attachments.detach(myAttachment)

    attachments.registerOnGripUpdateCallback(callback) - registers a callback function that handles automatic grip updates.
		Your callback will be called periodically to request the item that is being gripped in the right or left hand as
		well as the mesh or component being used for the right and left hands. If no item is currently being gripped then return nil.
        If rightMesh or leftMesh are nil then the attachments will be directly attached to the raw controller instead of a component.
		Return parameters are rightAttachment, rightMesh, rightSocketName, leftAttachment, leftMesh, leftSocketName, detachFromParent, allowReattach
		rightAttachment - the object being held in the right hand (or nil if nothing is held)
		rightMesh (optional) - the mesh or component to attach the right attachment to (or nil to attach to raw controller)
		rightSocketName (optional) - the socket name on the right mesh to attach to (or nil for no socket)
		leftAttachment (optional) - the object being held in the left hand (or nil if nothing is held)
		leftMesh (optional) - the mesh or component to attach the left attachment to (or nil to attach to raw controller)
		leftSocketName (optional) - the socket name on the left mesh to attach to (or nil for no socket)
		detachFromParent (optional) - boolean value indicating whether to detach the attachment from its current parent before attaching. Defaults to true
		allowReattach (optional) - boolean value indicating whether to allow reattaching the attachment to its previous parent when detaching from the current mesh/controller. Defaults to false
			Note that when attaching to raw controller, allowReattach is passed to set_permanent() function of UEVR_UObjectHook so
			if you dont want permananent attachment to controller (eg the object will be thrown), allowReattach should be false.
		example:
			attachments.registerOnGripUpdateCallback(function()
				if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
					local currentWeapon = pawn:GetCurrentWeapon()
					if currentWeapon ~= nil and currentWeapon.RootComponent ~= nil then
						return currentWeapon.RootComponent, hands.getHandComponent(Handed.Right), nil, nil, nil, nil, true
					end
				end
			end)

    attachments.registerOnGripAnimationCallback(callbackFunc) - registers a callback function that will be called when grip animation changes, 
		for example when a new weapon is equipped.
        example:
            attachments.registerOnGripAnimationCallback(function(animationID, gripHand)
                -- Handle grip animation change
                print("Grip animation " .. animationID .. " activated for hand " .. gripHand)
            end)

    attachments.detachAttachmentFromMeshes(attachment, reattachToParent) - detaches an object from all meshes
        example:
            attachments.detachAttachmentFromMeshes(myAttachment, true)

    attachments.detachAttachmentsFromMesh(mesh, reattachToParent) - detaches all objects from a specific mesh
        example:
            attachments.detachAttachmentsFromMesh(targetMesh, true)

    attachments.setAttachmentOffset(id, location, rotation) - sets the offset for an attachment relative to its parent
        example:
            attachments.setAttachmentOffset("WP_BerettaAuto9_C_Beretta_Mesh", {0,0,10}, {0,90,0})

    attachments.getAttachmentOffset(attachment) - gets the current position, rotation and scale for an attachment
        example:
            local pos, rot, scale = attachments.getAttachmentOffset(myAttachment)

    attachments.updateAttachmentTransform(pos, rot, scale, id) - updates an attachment's transform
        example:
            attachments.updateAttachmentTransform({0,0,0}, {0,0,0}, {1,1,1}, "WP_BerettaAuto9_C_Beretta_Mesh")

    attachments.setActiveAnimation(attachment, gripHand) - sets the active grip animation for an attachment
        example:
            attachments.setActiveAnimation(myAttachment, Handed.Right)

    attachments.getCurrentGripAnimation(handed) - gets the current grip animation for a controller
        example:
            local anim = attachments.getCurrentGripAnimation(Handed.Right)

    attachments.updateAttachmentAnimation(id, animationIndex) - updates the animation for an attachment
        example:
            attachments.updateAttachmentAnimation("WP_BerettaAuto9_C_Beretta_Mesh", 1)

    attachments.setLogLevel(val) - sets the logging level for attachment messages
        example:
            attachments.setLogLevel(LogLevel.Debug)

    attachments.setAttachmentNames(attachmentNamesList) - sets the list of available attachment names
        example:
            attachments.setAttachmentNames({"weapon", "tool", "item"})

    attachments.setAnimationIDs(animationIDList) - sets the available animation IDs and their display labels
        example:
            attachments.setAnimationIDs({
                grip_pistol = {label = "Pistol Grip"},
                grip_rifle = {label = "Rifle Grip"}
            })

    attachments.isActiveAttachmentMelee(hand) - checks if the attachment gripped by the specified hand is marked as melee
        example:
            local isMelee = attachments.isActiveAttachmentMelee(Handed.Right)

    attachments.isActiveAttachmentScoped(hand) - checks if the attachment gripped by the specified hand is marked as scoped
        example:
            local isScoped = attachments.isActiveAttachmentScoped(Handed.Right)

    attachments.isActiveAttachmentTwoHanded(hand) - checks if the attachment gripped by the specified hand is marked as two-handed
        example:
            local isTwoHanded = attachments.isActiveAttachmentTwoHanded(Handed.Right)

    attachments.print(text, logLevel) - prints a debug/log message with the specified log level
        example:
            attachments.print("Attachment created", LogLevel.Info)

    attachments.allowChildVisibilityHandling(value) - sets whether attachments will control the visibility of their child components
        value - boolean, true to allow child visibility handling, false to disable
        example:
            attachments.allowChildVisibilityHandling(true)

]]--

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")

local M = {}

M.AttachType =
{
    MESH = 0,
    CONTROLLER = 1,
    RAW_CONTROLLER = 2,
}

local parametersFileName = "attachments_parameters"
local parameters = {}
local isParametersDirty = false

local attachmentNames = {}
local attachmentOffsets = {}
--local activeAttachment = nil
local defaultLocation = nil
local defaultRotation = nil
local defaultScale = nil
local animationLabels = {"Default", "None"}
local animationIDs = {"", "attachment_none"}
--local activeAnimationID = false

local gunstockRotationOffset = uevrUtils.rotator(0,0,0)

local meshAttachmentList = {}
local activeGripAnimations = {}
--local attachmentCallbacks = {}

local stripParentNameNumericSuffix = false
local allowChildVisibilityHandling = true --attachments will set the visibility of child components based on this flag

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[attachments] " .. text, logLevel)
	end
end

--called when an attachment that is a grip attachment has changed
local function executeGripAttachmentChanged(...)
	uevrUtils.executeUEVRCallbacks("attachment_grip_changed", table.unpack({...}))
end

local function executeGripAttachmentRotationChange(...)
	uevrUtils.executeUEVRCallbacks("attachment_grip_rotation_change", table.unpack({...}))
end

local function executeGripAnimationChange(...)
	uevrUtils.executeUEVRCallbacks("attachment_grip_animation_changed", table.unpack({...}))
end


local helpText = "This module allows you to configure attachment offsets for objects attached to meshes or controllers. You can specify position, rotation, scale, and grip animation for each attachment. New entries are added each time a new mesh is attached."

function M.addAttachmentOffsetsToConfigUI(configDefinition, m_attachmentOffsets)
	if m_attachmentOffsets == nil then m_attachmentOffsets = attachmentOffsets end
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_node",
			id = "attachment_offsets",
			initialOpen = true,
			label = "Attachment Configuration"
		}
	)

	if #m_attachmentOffsets == 0 then
		table.insert(configDefinition[1]["layout"],
			{
				widgetType = "text",
				id = "no_attachments_configured",
				label = "No attachments configured yet. Either implement the attachments.registerOnGripUpdateCallback(callback) function or manually call the attachments.attachToMesh() function as described in attachments.lua.",
				wrapped = true
			}
		)
	end

	for i = 1, #m_attachmentOffsets do
		local parent = m_attachmentOffsets[i]["parent"]
		local child = m_attachmentOffsets[i]["child"]
		local id = m_attachmentOffsets[i]["id"]
		if id == nil then id = parent .. "_" .. child end
		m_attachmentOffsets[i]["id"] = id
		local name = id
		local pos = m_attachmentOffsets[i]["location"]
		local rot = m_attachmentOffsets[i]["rotation"]
		local scale = m_attachmentOffsets[i]["scale"]
		local isMelee = m_attachmentOffsets[i]["melee"]
		local isTwoHanded = m_attachmentOffsets[i]["two_handed"]
		local isScoped = m_attachmentOffsets[i]["scoped"]
		local animation = m_attachmentOffsets[i]["animation"]
		local anyChild = m_attachmentOffsets[i]["any_child"] and true or false
		local anyParent = m_attachmentOffsets[i]["any_parent"] and true or false
		local selectedIndex = 1
		for j = 1, #animationIDs do
			if animation == animationIDs[j] then
				selectedIndex = j
			end
		end

		table.insert(configDefinition[1]["layout"],
				{
					id = "attachment_" .. name, label = name, widgetType = "tree_node",
				}
		)
		table.insert(configDefinition[1]["layout"],
					{
						id = "attachment_" .. name .. "_position", label = "Position",
						widgetType = "drag_float3", speed = .1, range = {-500, 500}, initialValue = pos
					}
		)
		table.insert(configDefinition[1]["layout"],
					{
						id = "attachment_" .. name .. "_rotation", label = "Rotation",
						widgetType = "drag_float3", speed = .1, range = {-360, 360}, initialValue = rot
					}
		)
		table.insert(configDefinition[1]["layout"],
					{
						id = "attachment_" .. name .. "_scale", label = "Scale",
						widgetType = "drag_float3", speed = .1, range = {0.01, 10}, initialValue = scale
					}
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "checkbox",
                id =  "attachment_" .. name .. "_is_melee",
                label = "Melee",
                initialValue = isMelee
            }
		)
		table.insert(configDefinition[1]["layout"],
            { widgetType = "same_line" }
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "checkbox",
                id =  "attachment_" .. name .. "_is_two_handed",
                label = "Two Handed",
                initialValue = isTwoHanded
            }
		)
		table.insert(configDefinition[1]["layout"],
            { widgetType = "same_line" }
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "checkbox",
                id =  "attachment_" .. name .. "_is_scoped",
                label = "Scoped",
                initialValue = isScoped
            }
		)
		table.insert(configDefinition[1]["layout"],
					{
						id = "attachment_" .. name .. "_grip_animation", label = "Grip Animation",
						widgetType = "combo", selections = animationLabels, initialValue = selectedIndex
					}
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "checkbox",
                id =  "attachment_" .. name .. "_any_child",
                label = "Use for all children",
                initialValue = anyChild
            }
		)
		table.insert(configDefinition[1]["layout"],
            { widgetType = "same_line" }
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "checkbox",
                id =  "attachment_" .. name .. "_any_parent",
                label = "Use for all parents",
                initialValue = anyParent
            }
		)
		table.insert(configDefinition[1]["layout"],
				{
					widgetType = "tree_pop"
				}
		)

		configui.onUpdate("attachment_" .. name .. "_position", function(value)
			M.updateAttachmentTransform(value, nil, nil, id)
		end)
		configui.onUpdate("attachment_" .. name .. "_rotation", function(value)
			M.updateAttachmentTransform(nil, value, nil, id)
		end)
		configui.onUpdate("attachment_" .. name .. "_scale", function(value)
			M.updateAttachmentTransform(nil, nil, value, id)
		end)
		configui.onCreateOrUpdate("attachment_" .. name .. "_is_melee", function(value)
			M.updateAttachmentIsMelee(id, value)
		end)
		configui.onCreateOrUpdate("attachment_" .. name .. "_is_two_handed", function(value)
			M.updateAttachmentIsTwoHanded(id, value)
		end)
		configui.onCreateOrUpdate("attachment_" .. name .. "_is_scoped", function(value)
			M.updateAttachmentIsScoped(id, value)
		end)
		configui.onCreateOrUpdate("attachment_" .. name .. "_any_child", function(value)
			M.updateAttachmentUseAnyChild(id, value)
		end)
		configui.onCreateOrUpdate("attachment_" .. name .. "_any_parent", function(value)
			M.updateAttachmentUseAnyParent(id, value)
		end)
		configui.onUpdate("attachment_" .. name .. "_grip_animation", function(value)
			M.updateAttachmentAnimation(id, value)
		end)

	end

	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_pop"
		}
	)
	table.insert(configDefinition[1]["layout"],
		{ widgetType = "new_line" }
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_node",
			id = "uevr_attachments_advanced_tree",
			initialOpen = false,
			label = "Advanced"
		}
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "checkbox",
			id = "use_uevr_attachments_strip_parent_name_numeric_suffix",
			label = "Strip numeric suffix from parent attachment names",
			initialValue = stripParentNameNumericSuffix
		}
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_pop"
		}
	)
	table.insert(configDefinition[1]["layout"],
		{ widgetType = "new_line" }
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_node",
			id = "uevr_attachments_help_tree",
			initialOpen = true,
			label = "Help"
		}
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "text",
			id = "uevr_attachments_help",
			label = helpText,
			wrapped = true
		}
	)
	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_pop"
		}
	)
	return configDefinition
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading attachments parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating attachments parameters")
	end
	if parameters["attachmentOffsets"] == nil then
		parameters["attachmentOffsets"] = {}
		isParametersDirty = true
	end
	for i = 1, #parameters["attachmentOffsets"] do
		local parent = parameters["attachmentOffsets"][i]["parent"]
		local child = parameters["attachmentOffsets"][i]["child"]
		local id = parameters["attachmentOffsets"][i]["id"]
		if id == nil then id = parent .. "_" .. child end
		parameters["attachmentOffsets"][i]["id"] = id
		isParametersDirty = true
	end
	attachmentOffsets = parameters["attachmentOffsets"]
	if parameters["stripParentNameNumericSuffix"] ~= nil then
		stripParentNameNumericSuffix = parameters["stripParentNameNumericSuffix"]
	end
end

local function saveParameters()
	M.print("Saving attachments parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)
end, Once.EVER)

local function getDefaultConfig()
	return  {
		{
			panelLabel = "Attachments Config Dev",
			saveFile = "attachments_config_dev",
			layout =
			{
			}
		}
	}
end

function M.showDeveloperConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
	defaultLocation = m_defaultLocation
	defaultRotation = m_defaultRotation
	defaultScale = m_defaultScale

	local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
	configui.create(configDefinition)
end

local function registerAttachmentCallback(callbackName, callbackFunc)
	uevrUtils.registerUEVRCallback(callbackName, callbackFunc)
	-- if attachmentCallbacks[callbackName] == nil then attachmentCallbacks[callbackName] = {} end
	-- for i, existingFunc in ipairs(attachmentCallbacks[callbackName]) do
	-- 	if existingFunc == callbackFunc then
	-- 		--print("Function already exists")
	-- 		return
	-- 	end
	-- end
	-- table.insert(attachmentCallbacks[callbackName], callbackFunc)
end
-- local function executeAttachmentCallbacks(callbackName, ...)
-- 	uevrUtils.executeUEVRCallbacks(callbackName, reusable_hit_result)
-- 	-- if attachmentCallbacks[callbackName] ~= nil then
-- 	-- 	for i, func in ipairs(attachmentCallbacks[callbackName]) do
-- 	-- 		func(table.unpack({...}))
-- 	-- 	end
-- 	-- end
-- end

function M.init(isDeveloperMode, logLevel, m_defaultLocation, m_defaultRotation, m_defaultScale)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
        createDevMonitor()
    end
end

local function strip_after_last_underscore(str)
    local last = str:match("^(.*)_.*$")
    return last or str
end
local function stripTrailingNumbers(str)
    return str:match("^(.-)%d*$")
end

local function getOverrideChildname(parentName)
	--print("getOverrideChildname for parentName " .. parentName)
	for i = 1, #attachmentOffsets do
		if attachmentOffsets[i]["parent"] == parentName and attachmentOffsets[i]["any_child"] == true then
			--print("Found any_child override for parent name " .. parentName)
			return attachmentOffsets[i]["child"]
		end
	end
	--print("No override child name found")
	return ""
end

local function getOverrideParentname(childName)
	--print("getOverrideParentname for childName " .. childName)
	for i = 1, #attachmentOffsets do
		if attachmentOffsets[i]["child"] == childName and attachmentOffsets[i]["any_parent"] == true then
			--print("Found any_parent override for child name " .. childName)
			return attachmentOffsets[i]["parent"]
		end
	end
	--print("No override parent name found")
	return ""
end

local function getAttachmentNames(attachment)
	local attachmentParentName = uevrUtils.getShortName(attachment:get_outer())
	local attachmentNameNoNumberSuffix = stripTrailingNumbers(attachmentParentName)
	if string.sub(attachmentNameNoNumberSuffix, -1, -1) ~= "_" then
		attachmentParentName = attachmentNameNoNumberSuffix
	else
		attachmentParentName = strip_after_last_underscore(attachmentParentName) -- strip off anything after the last underscore
	end
	if stripParentNameNumericSuffix then
		attachmentParentName = stripTrailingNumbers(attachmentParentName)
	end

	local attachmentChildName = getOverrideChildname(attachmentParentName)
	if attachmentChildName == "" then
		if attachment.StaticMesh ~= nil then
			attachmentChildName = uevrUtils.getShortName(attachment.StaticMesh)
		elseif attachment.SkeletalMesh ~= nil then
			attachmentChildName = uevrUtils.getShortName(attachment.SkeletalMesh)
		else
			attachmentChildName = uevrUtils.getShortName(attachment)
		end
	end
		
	
	local attachmentParentName_Alt = getOverrideParentname(attachmentChildName)
	if attachmentParentName_Alt ~= "" then
		attachmentParentName = attachmentParentName_Alt
	end

	--print("getAttachmentNames",attachmentParentName, attachmentChildName)
	return attachmentParentName, attachmentChildName, attachmentParentName .. "_" .. attachmentChildName
end

local function hasNamedObject(attachment, parentName, childName)
	--M.print("Called hasNamedObject with parent: " .. parentName .. " child: " .. childName)
	local result = false
	if parentName == nil or parentName == "" then
		result = true
	else
		result = not not string.find(attachment:get_full_name(), parentName)
	end

	if result then
		if not(childName == nil or childName == "") then
			if attachment.StaticMesh ~= nil then
				--print("Static Mesh",attachment.StaticMesh:get_full_name())
				result = not not string.find(attachment.StaticMesh:get_full_name(), childName)
			elseif attachment.SkeletalMesh ~= nil then
				--print("Skeletal Mesh",attachment.SkeletalMesh:get_full_name())
				result = not not string.find(attachment.SkeletalMesh:get_full_name(), childName)
			else
				result = not not string.find(attachment:get_full_name(), childName)
			end
		else
			result = false
		end
	end
	--M.print("hasNamedObject result is " .. (result and "true" or "false"))
	return result
end

-- function M.getActiveAttachment()
-- 	return activeAttachment
-- end

function M.addAttachmentToConfig(attachment)
	if parameters ~= nil then
		local attachmentParentName, attachmentChildName, id = getAttachmentNames(attachment)

		local exists = false
		--if configuration["attachmentOffsets"] == nil then configuration["attachmentOffsets"] = {} end
		if parameters["attachmentOffsets"] ~= nil then
			for i = 1, #parameters["attachmentOffsets"] do
				if attachmentParentName == attachmentOffsets[i]["parent"] and attachmentChildName == attachmentOffsets[i]["child"] then
					exists = true
				end
			end
			if not exists then
				M.print("Adding attachment to config " .. attachmentParentName .. " - " .. attachmentChildName)
				local attachmentLocation =  defaultLocation or {attachment.RelativeLocation.X, attachment.RelativeLocation.Y, attachment.RelativeLocation.Z}
				local attachmentRotation = defaultRotation or {attachment.RelativeRotation.Pitch, attachment.RelativeRotation.Yaw, attachment.RelativeRotation.Roll}
				local attachmentScale = defaultScale or {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}

				table.insert(parameters["attachmentOffsets"], {id = id, parent=attachmentParentName, child=attachmentChildName, location=attachmentLocation, rotation=attachmentRotation, scale=attachmentScale})
				isParametersDirty = true

				attachmentOffsets = parameters["attachmentOffsets"]
				local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
				configui.update(configDefinition)
			end
		end
	end
end

function M.setAttachmentNames(attachmentNamesList)
	attachmentNames = attachmentNamesList
	attachmentOffsets = {}
	for i, attachmentName in ipairs(attachmentNames) do
		table.insert(attachmentOffsets, {parent=attachmentName, child="", location=defaultLocation or {0,0,0}, rotation=defaultRotation or {0,0,0}, scale=defaultScale or {1,1,1}})
	end
end

function M.getAttachmentOffset(attachment)
	local attachmentLocation = {0,0,0}
	local attachmentRotation = {0,0,0}
	local attachmentScale = {1,1,1}

	if uevrUtils.getValid(attachment) ~= nil then
		for i = 1, #attachmentOffsets do
			local parent = attachmentOffsets[i]["parent"]
			local child = attachmentOffsets[i]["child"]
			local id = attachmentOffsets[i]["id"]
			--local name = parent .. "_" .. child
			--if hasNamedObject(attachment, parent, child) then
			local _, _, attachmentID = getAttachmentNames(attachment)
			if id == attachmentID then
				local position = configui.getValue("attachment_" .. id .. "_position")
				if position == nil then position = attachmentOffsets[i]["location"] end

				local rotation = configui.getValue("attachment_" .. id .. "_rotation")
				if rotation == nil then rotation = attachmentOffsets[i]["rotation"] end

				local scale = configui.getValue("attachment_" .. id .. "_scale")
				if scale == nil then scale = attachmentOffsets[i]["scale"] end
				if scale == nil then --set a fixed scale in case something else tries to change it
					attachmentOffsets[i]["scale"] = {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}
					scale = attachmentOffsets[i]["scale"]
				end

				return uevrUtils.vector(position), uevrUtils.rotator(rotation), uevrUtils.vector(scale)
			end
		end
		attachmentLocation = {attachment.RelativeLocation.X, attachment.RelativeLocation.Y, attachment.RelativeLocation.Z}
		attachmentRotation = {attachment.RelativeRotation.Pitch, attachment.RelativeRotation.Yaw, attachment.RelativeRotation.Roll}
		attachmentScale = {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}
	end

	if defaultLocation ~= nil then attachmentLocation = defaultLocation end
	if defaultRotation ~= nil then attachmentRotation = defaultRotation end
	if defaultScale ~= nil then attachmentScale = defaultScale end

	--we didnt find an existing attachment. Add it to config if config is enabled
	M.addAttachmentToConfig(attachment)

	return uevrUtils.vector(attachmentLocation), uevrUtils.rotator(attachmentRotation), uevrUtils.rotator(attachmentScale)
end

-- function M.setAttachmentOffset(parentName, childName, location, rotation)
-- 	for i = 1, #attachmentOffsets do
-- 		local parent = attachmentOffsets[i]["parent"]
-- 		local child = attachmentOffsets[i]["child"]
-- 		if parentName == parent and childName == child then
-- 			if location ~= nil then attachmentOffsets[i]["location"] = {location.X, location.Y, location.Z} end
-- 			if rotation ~= nil then attachmentOffsets[i]["rotation"] = {rotation.X, rotation.Y, rotation.Z} end
-- 		end
-- 	end
-- 	parameters["attachmentOffsets"] = attachmentOffsets
-- 	isParametersDirty = true
-- end

local function getAttachmentDataFromMeshAttachmentList(id)
	for meshName, meshData in pairs(meshAttachmentList) do
		for attachmentName, attachmentData in pairs(meshData) do
			if attachmentData == nil then
				M.print("getAttachmentDataFromMeshAttachmentList had nil attachmentData " .. id)
			elseif uevrUtils.getValid(attachmentData.attachment) ~= nil then
				local _, _, attachmentID = getAttachmentNames(attachmentData.attachment)
				M.print("Checking attachment " .. attachmentID .. " against " .. id)
				if id == attachmentID then
					M.print("Found matching attachment " .. attachmentID)
					return attachmentData --.attachment, attachmentData.attachType, attachmentData.state
				end
			end
		end
	end
	return nil --, nil, nil
end

function M.setAttachmentOffset(id, location, rotation)
	for i = 1, #attachmentOffsets do
		local attachmentID = attachmentOffsets[i]["id"]
		if id == attachmentID then
			if location ~= nil then attachmentOffsets[i]["location"] = {location.X, location.Y, location.Z} end
			if rotation ~= nil then attachmentOffsets[i]["rotation"] = {rotation.X, rotation.Y, rotation.Z} end
		end
	end
	parameters["attachmentOffsets"] = attachmentOffsets
	isParametersDirty = true
end

function M.updateAttachmentAnimation(id, animationIndex)
	for i = 1, #attachmentOffsets do
		local attachmentID = attachmentOffsets[i]["id"]
		if id == attachmentID then
			attachmentOffsets[i]["animation"] = animationIDs[animationIndex]
			--when we change the setting in configui, we also need to update the active animation
			local attachmentData = getAttachmentDataFromMeshAttachmentList(id)
			if attachmentData ~= nil and attachmentData.gripHand ~= nil then
				M.setActiveAnimation(attachmentData.attachment, attachmentData.gripHand)
			end
		end
	end
	parameters["attachmentOffsets"] = attachmentOffsets
	isParametersDirty = true
end

local function updateAttachmentProperty(id, propertyName, value)
	for i = 1, #attachmentOffsets do
		local attachmentID = attachmentOffsets[i]["id"]
		if id == attachmentID then
			attachmentOffsets[i][propertyName] = value
		end
	end
	parameters["attachmentOffsets"] = attachmentOffsets
	isParametersDirty = true
end

function M.updateAttachmentUseAnyChild(id, anyChild)
	updateAttachmentProperty(id, "any_child", anyChild)
end

function M.updateAttachmentUseAnyParent(id, anyParent)
	updateAttachmentProperty(id, "any_parent", anyParent)
end

function M.updateAttachmentIsScoped(id, isScoped)
	updateAttachmentProperty(id, "scoped", isScoped)
end

function M.updateAttachmentIsTwoHanded(id, isTwoHanded)
	updateAttachmentProperty(id, "two_handed", isTwoHanded)
end

function M.updateAttachmentIsMelee(id, isMelee)
	updateAttachmentProperty(id, "melee", isMelee)
end

local function checkAttachmentProperty(attachment, property)
	--print("checkAttachmentProperty called for property " .. property, attachment)
	if uevrUtils.getValid(attachment) ~= nil then
		local _, _, attachmentID = getAttachmentNames(attachment)
		--print("Checking attachment property " .. property .. " for attachment ID " .. attachmentID)
		for i = 1, #attachmentOffsets do
			if attachmentOffsets[i]["id"] == attachmentID then
				return attachmentOffsets[i][property] == true
			end
		end
	end
	return false
end

function M.getActiveAttachmentID(hand)
	local attachment = M.getCurrentGrippedAttachment(hand)
	if uevrUtils.getValid(attachment) ~= nil then
		local _, _, attachmentID = getAttachmentNames(attachment)
		return attachmentID
	end
	return nil
end

function M.isActiveAttachmentMelee(hand)
	return checkAttachmentProperty(M.getCurrentGrippedAttachment(hand), "melee")
end

function M.isActiveAttachmentScoped(hand)
	return checkAttachmentProperty( M.getCurrentGrippedAttachment(hand), "scoped")
end

function M.isActiveAttachmentTwoHanded(hand)
	return checkAttachmentProperty(M.getCurrentGrippedAttachment(hand), "two_handed")
end

-- local function getNamedAttachmentFromMeshAttachmentList(parentName, childName)
-- 	for meshName, meshData in pairs(meshAttachmentList) do
-- 		for attachmentName, attachmentData in pairs(meshData) do
-- 			if attachmentData == nil then
-- 				print("getNamedAttachmentFromMeshAttachmentList had nil attachmentData", parentName, childName)
-- 			elseif uevrUtils.getValid(attachmentData.attachment) ~= nil then
-- 				if hasNamedObject(attachmentData.attachment, parentName, childName) then
-- 					return attachmentData.attachment, attachmentData.attachType, attachmentData.state
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return nil, nil
-- end

--function M.updateAttachmentTransform(pos, rot, scale, parentName, childName)
function M.updateAttachmentTransform(pos, rot, scale, id)
	if id ~= nil then
		M.setAttachmentOffset(id, pos, rot)
	end

	--only using rotationOffset on the Raw Controller currently assuming if the attachment is connected to a mesh then the mesh will be rotated
	--local rotationOffset = gunstock.setActive(id)
	M.print("Updating attachment transform for id " .. tostring(id))
	local attachmentData = getAttachmentDataFromMeshAttachmentList(id)
	--local attachment, attachType, attachState = getAttachmentDataFromMeshAttachmentList(id)
	if attachmentData ~= nil then
		local attachment = attachmentData.attachment
		local attachType = attachmentData.attachType
		local attachState = attachmentData.state
		if attachType == M.AttachType.RAW_CONTROLLER then
			if attachState ~= nil then
				if pos ~= nil then attachState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
				-- if rot ~= nil then
				-- 	local final = kismet_math_library:ComposeRotators( uevrUtils.rotator(rot.X, rot.Y + 90, rot.Z), rotationOffset * 1)
				-- 	attachState:set_rotation_offset(Vector3f.new( math.rad(final.Pitch), math.rad(final.Yaw),  math.rad(final.Roll)))
				-- end
				if rot ~= nil then attachState:set_rotation_offset(Vector3f.new( math.rad(rot.X - gunstockRotationOffset.Pitch), math.rad(rot.Y + 90 - gunstockRotationOffset.Yaw),  math.rad(rot.Z - gunstockRotationOffset.Roll))) end
			end
		end
		if attachment ~= nil and (attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER) then
			M.print("Setting attachment transform for attachment " .. tostring(attachment:get_full_name()))
			if pos ~= nil then uevrUtils.set_component_relative_location(attachment, pos) end
			if rot ~= nil then uevrUtils.set_component_relative_rotation(attachment, rot + gunstockRotationOffset) end
			if scale ~= nil then uevrUtils.set_component_relative_scale(attachment, scale) end
		end
	end
	-- for id, mesh in pairs(meshAttachmentList) do
	-- 	for attachmentName, attachmentData in pairs(mesh) do
	-- 		if uevrUtils.getValid(attachmentData.attachment) ~= nil then
	-- 			if hasNamedObject(attachmentData.attachment, parentName, childName) then
	-- 				local attachType = attachmentData.attachType
	-- 				if attachType == M.AttachType.RAW_CONTROLLER then
	-- 					-- if attachmentState ~= nil then
	-- 					-- 	if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
	-- 					-- 	if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
	-- 					-- end
	-- 				end
	-- 				if attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER then
	-- 					if pos ~= nil then uevrUtils.set_component_relative_location(activeAttachment, pos) end
	-- 					if rot ~= nil then uevrUtils.set_component_relative_rotation(activeAttachment, rot) end
	-- 					if scale ~= nil then uevrUtils.set_component_relative_scale(activeAttachment, scale) end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- if uevrUtils.validate_object(activeAttachment) ~= nil then
	-- 	if parentName == nil or hasNamedObject(activeAttachment, parentName, childName) then
	-- 		if attachType == M.AttachType.RAW_CONTROLLER then
	-- 			-- if attachmentState ~= nil then
	-- 			-- 	if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
	-- 			-- 	if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
	-- 			-- end
	-- 		end
	-- 		if attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER then
	-- 			if pos ~= nil then uevrUtils.set_component_relative_location(activeAttachment, pos) end
	-- 			if rot ~= nil then uevrUtils.set_component_relative_rotation(activeAttachment, rot) end
	-- 			if scale ~= nil then uevrUtils.set_component_relative_scale(activeAttachment, scale) end
	-- 		end
	-- 	end
	-- end
end

-- uevrUtils.registerUEVRCallback("aim_rotation_offset_change", function(newRotation)
-- 	gunstockRotationOffset = newRotation
-- end)

uevrUtils.registerUEVRCallback("gunstock_transform_change", function(id, location, rotation)
	gunstockRotationOffset = rotation
	local attachmentData = getAttachmentDataFromMeshAttachmentList(id)
	--local attachment, _, _ = getAttachmentDataFromMeshAttachmentList(id)
	if attachmentData ~= nil and uevrUtils.getValid(attachmentData.attachment) ~= nil then
		local loc, rot, scale = M.getAttachmentOffset(attachmentData.attachment)
		M.updateAttachmentTransform(loc, rot, scale, id)
	end
end)

local function updateSelectedColor(id, color)
	--print("changing color", "attachment_" .. id)
	for i = 1, #attachmentOffsets do
		local parent = attachmentOffsets[i]["parent"]
		local child = attachmentOffsets[i]["child"]
		local m_id = attachmentOffsets[i]["id"]
		if m_id == nil then m_id = parent .. "_" .. child end
		configui.setColor("attachment_" .. m_id, "#FFFFFFFF")
	end
	configui.setColor("attachment_" .. id, color)
end

function M.allowChildVisibilityHandling(value)
	allowChildVisibilityHandling = value
end

function M.initAttachment(attachment, gripHand)
	if attachment ~= nil then
		attachment:SetVisibility(true, allowChildVisibilityHandling)
		attachment:SetHiddenInGame(false, allowChildVisibilityHandling)
		attachment:call("SetRenderInMainPass", true)
		local location, rotation, scale = M.getAttachmentOffset(attachment)
		local parentName, childName, id = getAttachmentNames(attachment)
		M.print("Initializing attachment " .. id)
		--TODO this seems redundant with setActiveAnimation
		if gripHand ~= nil then
			executeGripAttachmentChanged(id, gripHand)
		end
		M.updateAttachmentTransform(location, rotation, scale, id)
		M.setActiveAnimation(attachment, gripHand)

		updateSelectedColor(id, "#0088FFFF")
	end
end

function M.setActiveAnimation(attachment, gripHand)
	if gripHand ~= nil then
		if uevrUtils.getValid(attachment) ~= nil then
			activeGripAnimations[gripHand] = true
			for i = 1, #attachmentOffsets do
				local id = attachmentOffsets[i]["id"]
				-- local parent = attachmentOffsets[i]["parent"]
				-- local child = attachmentOffsets[i]["child"]
				--local name = parent .. "_" .. child
				--if attachmentOffsets[i]["animation"] is nil then its never been set so just use the default animation by returning true
				--if hasNamedObject(attachment, parent, child) and attachmentOffsets[i]["animation"] ~= nil then
				local _, _, attachmentID = getAttachmentNames(attachment)
				if id == attachmentID and attachmentOffsets[i]["animation"] ~= nil then
					activeGripAnimations[gripHand] = attachmentOffsets[i]["animation"] == "animation_none" and false or attachmentOffsets[i]["animation"]
					break
				end
			end
		else
			activeGripAnimations[gripHand] = false
		end
		--M.print("Calling callback for grip animation " .. activeGripAnimations[gripHand] .. " " .. gripHand)
		executeGripAnimationChange(activeGripAnimations[gripHand], gripHand)
		--executeAttachmentCallbacks("grip_animation", activeGripAnimations[gripHand], gripHand)
	end
end

function M.getCurrentGrippedAttachment(gripHand)
	if gripHand == nil then gripHand = Handed.Right end
	if gripHand ~= nil then
		for meshName, meshData in pairs(meshAttachmentList) do
			for attachmentName, attachmentData in pairs(meshData) do
				if attachmentData.gripHand == gripHand and uevrUtils.getValid(attachmentData.attachment) then
					return attachmentData.attachment
				end
			end
		end
	end
end

-- TODO: optimize to only send changes
function M.broadcastGrippedAttachmentRotation()
	local leftAttachment = M.getCurrentGrippedAttachment(Handed.Left)
	local rightAttachment = M.getCurrentGrippedAttachment(Handed.Right)
	executeGripAttachmentRotationChange(leftAttachment and leftAttachment:GetSocketRotation(uevrUtils.fname_from_string("MuzzleSocket")) or nil, rightAttachment and rightAttachment:GetSocketRotation(uevrUtils.fname_from_string("MuzzleSocket")) or nil)
	--print("Broadcasting gripped attachment rotation", leftAttachment, rightAttachment)
end

function M.getCurrentGripAnimation(handed)
	return activeGripAnimations[handed]
end

--for debugging
local function printMeshAttachmentList()
	M.print("Current Mesh Attachment List:")
	for meshName, meshData in pairs(meshAttachmentList) do
		M.print(" Mesh: " .. meshName)
		for attachmentName, attachmentData in pairs(meshData) do
			if attachmentData.attachment ~= nil then
				M.print("  Attachment: " .. attachmentName .. " (Type: " .. tostring(attachmentData.attachType) .. ", GripHand: " .. tostring(attachmentData.gripHand) .. ")")
			end
		end
	end
end

function M.attachToMesh(attachment, mesh, socketName, gripHand, detachFromParent, allowReattach)
	local success = false
	if uevrUtils.getValid(attachment) ~= nil and uevrUtils.getValid(mesh) ~= nil  then
		--printMeshAttachmentList()
		--see if the attachment is already a child of the mesh
		if mesh.AttachChildren ~= nil then
			for i, child in ipairs(mesh.AttachChildren) do
				if child == attachment then
					--M.print("Attachment is already a child of the mesh")
					return true
				end
			end
		end

		if gripHand ~= nil then
			M.detachGripAttachments(gripHand)
		end

		local meshName = mesh:get_full_name()
		if meshAttachmentList[meshName] ==  nil then
			meshAttachmentList[meshName] = {mesh=mesh}
		end
		local attachmentName = attachment:get_full_name()
		if meshAttachmentList[meshName][attachmentName] == nil then
			meshAttachmentList[meshName][attachmentName] = {attachment=attachment, socket=socketName, detachFromParent = detachFromParent, attachType = M.AttachType.MESH, gripHand = gripHand}
		end

		if detachFromParent == true then
			if allowReattach then
				meshAttachmentList[meshName][attachmentName].parent = attachment.AttachParent
			end
			attachment:DetachFromParent(false,false)
		end

		M.print("Attaching attachment to mesh: " .. attachment:get_full_name() .. " to " .. mesh:get_full_name())
		if type(socketName) == "string" then
			socketName = uevrUtils.fname_from_string(socketName)
		end
		if socketName == nil then socketName = attachment.AttachSocketName end
		success = attachment:K2_AttachTo(mesh, socketName, 0, false)

		M.initAttachment(attachment, gripHand)
		M.print("Attached attachment to mesh" .. (success and " successfully" or " with errors"))
	else
		M.print("Failed to attach attachment to mesh")
	end
	return success
end

function M.attachToController(attachment, controllerID, detachFromParent)
	M.attachToMesh(attachment, controllers.getController(controllerID), nil, controllerID, detachFromParent)
	-- if uevrUtils.getValid(attachment) ~= nil then
	-- 	if detachFromParent == true and attachment ~= nil and attachment.AttachParent ~= nil then
	-- 		attachment:DetachFromParent(false,false)
	-- 	end
	-- 	M.print("Attaching " .. attachment:get_full_name() .. " to controller with ID " .. controllerID)
	-- 	controllers.attachComponentToController(controllerID, attachment, nil, nil, nil, true)

	-- 	attachment:call("SetRenderInMainPass", true)
	-- 	M.updateOffset(attachment)
	-- 	M.setActiveAnimation(attachment, controllerID)
	-- 	M.print("Attached attachment to controller")
	-- else
	-- 	M.print("Failed to attach attachment to controller")
	-- end
end

function M.attachToRawController(attachment, gripHand, detachFromParent, allowReattach)
	if uevrUtils.getValid(attachment) ~= nil then
		local meshName = "Controller_Raw"
		local attachmentName = attachment:get_full_name()
		--if it's already attached then just return
		if meshAttachmentList[meshName] ~= nil and meshAttachmentList[meshName][attachmentName] ~= nil then
			if meshAttachmentList[meshName][attachmentName]["attachment"] == attachment then
				return true
			end
		end

		M.detachAttachmentsFromMesh(meshName)
		if meshAttachmentList[meshName] ==  nil then
			meshAttachmentList[meshName] = {mesh=nil}
		end
		meshAttachmentList[meshName][attachmentName] = {attachment=attachment,  detachFromParent = detachFromParent, attachType = M.AttachType.RAW_CONTROLLER, gripHand = gripHand}

		--print("Detaching", detachFromParent, attachment, attachment.AttachParent)
		if detachFromParent == true and attachment ~= nil and attachment.AttachParent ~= nil then
			if allowReattach then
				meshAttachmentList[meshName][attachmentName].parent = attachment.AttachParent
			end
			M.print("Detaching attachment from parent: " .. attachment.AttachParent:get_full_name())
			attachment:DetachFromParent(false,false)
		end
		M.print("Attaching " .. attachment:get_full_name() .. " to controller with ID " .. gripHand)
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(attachment)
		state:set_hand(gripHand)
		state:set_permanent(allowReattach)
		meshAttachmentList[meshName][attachmentName].state = state

		M.initAttachment(attachment, gripHand)
		M.print("Attached attachment to raw controller")
	else
		M.print("Failed to attach attachment to raw controller")
	end
end

function M.detach(attachment, parent, attachType)
	if uevrUtils.getValid(attachment) ~= nil then
		if attachType == M.AttachType.RAW_CONTROLLER then
			M.print("Detaching attachment from raw controller: " .. attachment:get_full_name())
			UEVR_UObjectHook.remove_motion_controller_state(attachment)
		end
		if parent ~= nil then
			M.print("Detaching attachment " .. attachment:get_full_name() .. " and reattaching to parent: " .. parent:get_full_name())
			attachment:DetachFromParent(false,false)
			attachment:K2_AttachTo(parent, attachment.AttachSocketName, 0, false)
		end
	else
		M.print("Failed to detach attachment")
	end
end

--detach only the attachments that are grip attachments
function M.detachGripAttachments(gripHand)
	if gripHand ~= nil then
		for meshName, meshData in pairs(meshAttachmentList) do
			for attachmentName, attachmentData in pairs(meshData) do
				if attachmentData.gripHand == gripHand then
					M.print("Detaching grip attachments for " .. attachmentName .. " for hand: " .. gripHand)
					activeGripAnimations[attachmentData.gripHand] = false
					M.detach(attachmentData.attachment, attachmentData.parent or nil, attachmentData.attachType)
					meshData[attachmentName] = nil
					executeGripAnimationChange(activeGripAnimations[gripHand], gripHand)
				end
			end
		end
	else
		M.print("Failed to detach grip attachments from meshes")
	end
end

function M.detachAttachmentFromMeshes(attachment, reattachToParent)
	if uevrUtils.getValid(attachment) ~= nil then
		local attachmentName = attachment:get_full_name()
		M.print("Detaching attachment from all meshes: " .. attachment:get_full_name())
		for meshName, meshData in pairs(meshAttachmentList) do
			if meshData[attachmentName] ~= nil then
				if meshData[attachmentName].gripHand ~= nil then
					activeGripAnimations[meshData[attachmentName].gripHand] = false
				end
				M.detach(meshData[attachmentName].attachment, reattachToParent and meshData[attachmentName].parent or nil,meshData[attachmentName].attachType)
				meshData[attachmentName] = nil
			end
		end
	else
		M.print("Failed to detach attachment from meshes")
	end
end

function M.detachAttachmentsFromMesh(mesh)
	local meshName = mesh
	if type(mesh) ~= "string" then
		if uevrUtils.getValid(mesh) ~= nil then
			meshName = mesh:get_full_name()
		end
	end
	if meshName ~= nil and meshName ~= "" then
		M.print("Detaching all attachments from mesh: " .. meshName)
		local meshData = meshAttachmentList[meshName]
		if meshData ~= nil then
			for attachmentName, attachmentData in pairs(meshData) do
				if attachmentData.gripHand ~= nil then
					activeGripAnimations[attachmentData.gripHand] = false
				end
				M.detach(attachmentData.attachment, attachmentData.parent or nil, attachmentData.attachType)
			end
			meshAttachmentList[meshName] = {}
		end
	else
		M.print("Failed to detach attachments from mesh")
	end
end

local function getAnimationLabelsArray(animationIDList)
	local labels = {"Default", "None"}
	for id, data in pairs(animationIDList) do
		table.insert(labels, data["label"])
	end
	return labels
end

local function getAnimationIDsArray(animationIDList)
	local ids = {"", "attachment_none"}
	for id, data in pairs(animationIDList) do
		table.insert(ids, id)
	end
	return ids
end
function M.setStripParentNameNumericSuffix(value)
	stripParentNameNumericSuffix = value
	configui.setValue("use_uevr_attachments_strip_parent_name_numeric_suffix", stripParentNameNumericSuffix, true)
	if parameters ~= nil then
		parameters["stripParentNameNumericSuffix"] = stripParentNameNumericSuffix
		isParametersDirty = true
	end
end

local function deepEqual(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end

    -- check keys in t1
    for k, v in pairs(t1) do
        if not deepEqual(v, t2[k]) then
            return false
        end
    end

    -- check keys in t2 (to catch extras)
    for k, v in pairs(t2) do
        if not deepEqual(v, t1[k]) then
            return false
        end
    end

    return true
end

local currentAnimationIDList = {}
function M.setAnimationIDs(animationIDList)
	--dont rewrite if nothing has changed
	if deepEqual(animationIDList, currentAnimationIDList) then
		return
	end
	currentAnimationIDList = animationIDList
	if animationIDList ~= nil then
		animationLabels = getAnimationLabelsArray(animationIDList)
		animationIDs = getAnimationIDsArray(animationIDList)
		for i = 1, #attachmentOffsets do
			local parent = attachmentOffsets[i]["parent"]
			local child = attachmentOffsets[i]["child"]
			local name = parent .. "_" .. child
			configui.setSelections("attachment_" .. name .. "_grip_animation", animationLabels)
			local selectedID = attachmentOffsets[i]["animation"]
			for j = 1, #animationIDs do
				if selectedID == animationIDs[j] then
					--dont think callback is needed here since we're just updating the configui to match existing settings
					configui.setValue("attachment_" .. name .. "_grip_animation", j, true)
				end
			end
		end
	end
end

configui.onUpdate("use_uevr_attachments_strip_parent_name_numeric_suffix", function(value)
	M.setStripParentNameNumericSuffix(value)
end)

local autoUpdateCallbackCreated = false
--local autoUpdateCurrentAttachment = nil
--local autoUpdateCurrentMesh = nil
function M.registerOnGripUpdateCallback(callback)
	if not autoUpdateCallbackCreated then
		uevrUtils.setInterval(200, function()
			local rightAttachment, rightMesh, rightSocketName, leftAttachment, leftMesh, leftSocketName, detachFromParent, allowReattach = callback()
			--print(attachment, mesh, autoUpdateCurrentAttachment)
			if detachFromParent == nil then detachFromParent = true end
			if allowReattach == nil then allowReattach = false end

			-- if rightAttachment is nil then remove all right grip attachments
			if rightAttachment == nil then
				M.detachGripAttachments(Handed.Right)
			elseif rightMesh == nil then
				M.attachToRawController(rightAttachment, Handed.Right, detachFromParent, allowReattach)
			else
				M.attachToMesh(rightAttachment, rightMesh, rightSocketName, Handed.Right, detachFromParent, allowReattach)
			end

			-- if leftAttachment is nil then remove all left grip attachments
			if leftAttachment == nil then
				M.detachGripAttachments(Handed.Left)
			elseif leftMesh == nil then
				M.attachToRawController(leftAttachment, Handed.Left, detachFromParent, allowReattach)
			else
				M.attachToMesh(leftAttachment, leftMesh, leftSocketName, Handed.Left, detachFromParent, allowReattach)
			end

			-- if rightMesh == nil and rightAttachment == nil then
			-- 	--do nothing
			-- elseif rightMesh == nil and rightAttachment ~= nil then
			-- 	--M.detachAttachmentFromMeshes(rightAttachment, handleParentAttachment)
			-- elseif rightMesh ~= nil and rightAttachment == nil then
			-- 	M.detachAttachmentsFromMesh(rightMesh, handleParentAttachment)
			-- elseif rightMesh ~= nil and rightAttachment ~= nil then
			-- 	M.attachToMesh(rightAttachment, rightMesh, rightSocketName, Handed.Right, handleParentAttachment)
			-- end

			-- if leftMesh == nil and leftAttachment == nil then
			-- 	--do nothing
			-- elseif leftMesh == nil and leftAttachment ~= nil then
			-- 	--M.detachAttachmentFromMeshes(leftAttachment, handleParentAttachment)
			-- 	M.attachToRawController(leftAttachment, Handed.Left, handleParentAttachment)
			-- elseif leftMesh ~= nil and leftAttachment == nil then
			-- 	M.detachAttachmentsFromMesh(leftMesh, handleParentAttachment)
			-- elseif leftMesh ~= nil and leftAttachment ~= nil then
			-- 	M.attachToMesh(leftAttachment, leftMesh, leftSocketName, Handed.Left, handleParentAttachment)
			-- end

			-- if mesh ~= nil then
			-- 	print("Children",mesh:get_full_name(),mesh.AttachChildren and #mesh.AttachChildren or 0)
			-- end
			-- if (mesh == nil and autoUpdateCurrentMesh~= nil) or (attachment == nil and autoUpdateCurrentAttachment ~= nil) then
			-- 	M.detach(autoUpdateCurrentAttachment, true)
			-- 	autoUpdateCurrentMesh = mesh
			-- 	autoUpdateCurrentAttachment = attachment
			-- elseif attachment ~= nil and mesh ~= nil and autoUpdateCurrentAttachment ~= attachment then
			-- 	M.attachToMesh(attachment, mesh, socketName, true)
			-- 	autoUpdateCurrentMesh = mesh
			-- 	autoUpdateCurrentAttachment = attachment
			-- end
		end)
	end
end

function M.registerOnGripAnimationCallback(callbackFunc)
	registerAttachmentCallback("attachment_grip_animation_changed", callbackFunc)
end

function M.registerAttachmentChangeCallback(callbackFunc)
	uevrUtils.registerUEVRCallback("attachment_grip_changed", callbackFunc)
end

uevrUtils.registerPreLevelChangeCallback(function(level)
	meshAttachmentList = {}
	activeGripAnimations = {}
end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	M.broadcastGrippedAttachmentRotation()
end)

M.loadParameters()

return M