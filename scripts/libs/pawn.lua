--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local pawnModule = require("libs/pawn")
        local isDeveloperMode = true
        pawnModule.init(isDeveloperMode)

    Typical usage would be to run this code with developerMode set to true, then use the configuration tab
    to set parameters the way you want them, then set developerMode to false for production use. Be sure
    to ship your code with the data folder as well as the script folder because the data folder will contain
    your parameter settings.
        
    Available functions:

    pawnModule.init(isDeveloperMode, logLevel) - initializes the pawn management system with specified mode and log level
        example:
            pawnModule.init(true, LogLevel.Debug)

    pawnModule.registerIsArmBonesHiddenCallback(func) - registers a callback for when arm bones visibility changes
        example:
			pawnModule.registerIsArmBonesHiddenCallback(function()
				return isPlayerPlaying(), 0
			end)

    pawnModule.setBodyMeshName(val) - sets the name of the body mesh
        example:
            pawnModule.setBodyMeshName("Character.Body")

    pawnModule.getBodyMesh() - gets the body mesh object
        example:
            local mesh = pawnModule.getBodyMesh()

    pawnModule.getArmsMesh() - gets the arms mesh object
        example:
            local mesh = pawnModule.getArmsMesh()

    pawnModule.getArmsAnimationMesh() - gets the arms animation mesh object (used for weapon animations)
        example:
            local mesh = pawnModule.getArmsAnimationMesh()

    pawnModule.hideBodyMesh(val) - shows/hides the body mesh
        example:
            pawnModule.hideBodyMesh(true)  -- hides the body mesh
            pawnModule.hideBodyMesh(false) -- shows the body mesh

    pawnModule.hideAnimationArms(val) - shows/hides the animation arms
        example:
            pawnModule.hideAnimationArms(true)  -- hides animation arms
            pawnModule.hideAnimationArms(false) -- shows animation arms

    pawnModule.hideArms(val) - shows/hides the arms
        example:
            pawnModule.hideArms(true)  -- hides the arms
            pawnModule.hideArms(false) -- shows the arms

    pawnModule.hideArmsBones(val) - shows/hides the arm bones
        example:
            pawnModule.hideArmsBones(true)  -- hides arm bones
            pawnModule.hideArmsBones(false) -- shows arm bones

	pawnModule.setLogLevel(val) - sets the logging level for the pawn module
        example:
            pawnModule.setLogLevel(LogLevel.Debug)

    pawnModule.print(text, logLevel) - prints a message with optional log level
        example:
            pawnModule.print("Message", LogLevel.Debug)

    pawnModule.getConfigurationWidgets(options) - gets configuration UI widgets for user settings
        example:
            local widgets = pawnModule.getConfigurationWidgets({})

    pawnModule.getDeveloperConfigurationWidgets(options) - gets configuration UI widgets for developer settings
        example:
            local widgets = pawnModule.getDeveloperConfigurationWidgets({})

    pawnModule.showConfiguration(saveFileName, options) - shows user configuration UI
        example:
            pawnModule.showConfiguration("pawn_config.json", {})

    pawnModule.showDeveloperConfiguration(saveFileName, options) - shows developer configuration UI
        example:
            pawnModule.showDeveloperConfiguration("pawn_dev_config.json", {})


]]

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
--local hands = require("libs/hands")

local M = {}

local bodyMeshName = "Pawn.Mesh"
local armsMeshName = "Pawn.Mesh"
local armsAnimationMeshName = "Pawn.Mesh"
local pawnUpperArmRight = ""
local pawnUpperArmLeft = ""

local hidePawnArmsBones = false
local hidePawnBodyMesh = false
local hidePawnArmsMesh = false
local hideAnimationArms = false

local bodyMeshFOVFixID = ""
local armsMeshFOVFixID = ""

local pawnMeshList = {}
local boneList = {}
local includeChildrenInMeshList = false

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[pawn] " .. text, logLevel)
	end
end

local helpText = "This module allows you to configure the pawn body and arms meshes. You can hide/show the meshes in order to help locate them, select different meshes if your game has multiple meshes, and hide the arm bones if they are visible using the arms mesh. If your game has a separate mesh for first person arms animation (e.g. when using weapons), you can also configure that mesh separately. If your game uses the same mesh for everything, then just select that mesh in each dropdown box"

local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_pawn_body",
		initialOpen = true,
		label = "Pawn Body"
	},
		{
			widgetType = "combo",
			id = "pawnBodyMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnBodyMesh",
			label = "Hide",
			initialValue = hidePawnBodyMesh
		},
		{
			widgetType = "input_text",
			id = "selectedPawnBodyMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
		{
			widgetType = "input_text",
			id = "pawnBodyFOVFix",
			label = "FOV Fix ID",
			initialValue = bodyMeshFOVFixID,
			isHidden = false
		},

	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_pawn_arms",
		initialOpen = true,
		label = "Pawn Arms"
	},
		{
			widgetType = "combo",
			id = "pawnArmsMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnArmsMesh",
			label = "Hide",
			initialValue = hidePawnArmsMesh
		},
		{
			widgetType = "input_text",
			id = "selectedPawnArmsMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
		{
			widgetType = "combo",
			id = "pawnUpperArmLeft",
			label = "Left Upper Arm Bone",
			selections = {"None"},
			initialValue = 1
		},
		{
			widgetType = "combo",
			id = "pawnUpperArmRight",
			label = "Right Upper Arm Bone",
			selections = {"None"},
			initialValue = 1
		},
		{
			widgetType = "checkbox",
			id = "hidePawnArmsBones",
			label = "Hide Arm Bones",
			initialValue = hidePawnArmsBones
		},
		{
			widgetType = "input_text",
			id = "pawnArmsFOVFix",
			label = "FOV Fix ID",
			initialValue = armsMeshFOVFixID,
			isHidden = false
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_pawn_arms_animation",
		initialOpen = true,
		label = "Pawn Arms Animation"
	},
		{
			widgetType = "combo",
			id = "pawnArmsAnimationMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnArmsAnimationMesh",
			label = "Hide",
			initialValue = hideAnimationArms
		},
		{
			widgetType = "input_text",
			id = "selectedPawnArmsAnimationMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
	{
		widgetType = "tree_pop"
	},
	{ widgetType = "new_line" },
	{
		widgetType = "tree_node",
		id = "uevr_pawn_help_tree",
		initialOpen = true,
		label = "Help"
	},
		{
			widgetType = "text",
			id = "uevr_pawn_help",
			label = helpText,
			wrapped = true
		},
	{
		widgetType = "tree_pop"
	},
}

local function setPawnUpperArmLeft(value)
	pawnUpperArmLeft = boneList[value]
end

local function setPawnUpperArmRight(value)
	pawnUpperArmRight = boneList[value]
end

local function setBoneNames()
	local mesh = M.getArmsMesh()
	if mesh ~= nil then
		boneList = uevrUtils.getBoneNames(mesh)
		if #boneList == 0 then error() end
		configui.setSelections("pawnUpperArmLeft", boneList)
		configui.setSelections("pawnUpperArmRight", boneList)
	end
	local currentBoneIndex = configui.getValue("pawnUpperArmLeft")
	if currentBoneIndex ~= nil and currentBoneIndex > 1 then
		setPawnUpperArmLeft(currentBoneIndex)
	end
	currentBoneIndex = configui.getValue("pawnUpperArmRight")
	if currentBoneIndex ~= nil and  currentBoneIndex > 1 then
		setPawnUpperArmRight(currentBoneIndex)
	end
end

local function updateMeshUI(pawnMeshList, listName, selectedName, defaultValue)
	configui.setSelections(listName, pawnMeshList)

	local selectedPawnBodyMesh = configui.getValue(selectedName)
	if selectedPawnBodyMesh == nil or selectedPawnBodyMesh == "" then
		selectedPawnBodyMesh = defaultValue
	end

	for i = 1, #pawnMeshList do
		if pawnMeshList[i] == selectedPawnBodyMesh then
			configui.setValue(listName, i)
			break
		end
	end

end

local function setPawnMeshList()
	M.print("Setting pawn mesh list", LogLevel.Debug)
	pawnMeshList = uevrUtils.getPropertyPathDescriptorsOfClass(pawn, "Pawn", "Class /Script/Engine.SkeletalMeshComponent", includeChildrenInMeshList)
	M.print("Found " .. #pawnMeshList .. " meshes", LogLevel.Debug)
	updateMeshUI(pawnMeshList, "pawnBodyMeshList", "selectedPawnBodyMesh", bodyMeshName)
	updateMeshUI(pawnMeshList, "pawnArmsMeshList", "selectedPawnArmsMesh", armsMeshName)
	updateMeshUI(pawnMeshList, "pawnArmsAnimationMeshList", "selectedPawnArmsAnimationMesh", armsAnimationMeshName)

end

local function doHideArmsBones(val)
	local armsMesh = M.getArmsMesh()
	if armsMesh ~= nil then
		M.print("Hiding arms bones: " .. tostring(val))
		if val then
			if pawnUpperArmRight ~= nil and pawnUpperArmRight ~= "" then
				armsMesh:HideBoneByName(uevrUtils.fname_from_string(pawnUpperArmRight), 0)
			end
			if pawnUpperArmLeft ~= nil and pawnUpperArmLeft ~= "" then
				armsMesh:HideBoneByName(uevrUtils.fname_from_string(pawnUpperArmLeft), 0)
			end
		else
			if pawnUpperArmRight ~= nil and pawnUpperArmRight ~= "" then
				armsMesh:UnHideBoneByName(uevrUtils.fname_from_string(pawnUpperArmRight))
			end
			if pawnUpperArmLeft ~= nil and pawnUpperArmLeft ~= "" then
				armsMesh:UnHideBoneByName(uevrUtils.fname_from_string(pawnUpperArmLeft))
			end
		end
	end
end

local function fixFOV()
	local bodyMesh = nil
	if hidePawnBodyMesh == false and bodyMeshFOVFixID ~= nil and bodyMeshFOVFixID ~= "" then
		bodyMesh = M.getBodyMesh()
		if bodyMesh ~= nil then
			uevrUtils.fixMeshFOV(bodyMesh, bodyMeshFOVFixID, 0.0, true, true, false)
		end
	end
	if hidePawnArmsMesh == false and armsMeshFOVFixID ~= nil and armsMeshFOVFixID ~= "" then
		local armsMesh = M.getArmsMesh()
		--dont do it again if it was already done on the body and body and arms are the same
		if (bodyMesh == nil or bodyMesh ~= armsMesh) and armsMesh ~= nil then
			uevrUtils.fixMeshFOV(armsMesh, armsMeshFOVFixID, 0.0, true, true, false)
		end
	end
end

local function doHideBodyMesh(val)
	local mesh = M.getBodyMesh()
	if mesh ~= nil then
		M.print("Hiding body mesh: " .. tostring(val))
		-- mesh:SetVisibility(not val, true)
		-- mesh:SetHiddenInGame(val, true)
		mesh:call("SetRenderInMainPass", not val)
		fixFOV()
	end
end

local function doHideArms(val)
	local mesh = M.getArmsMesh()
	if mesh ~= nil then
		M.print("Hiding arms mesh: " .. tostring(val))
		-- mesh:SetVisibility(not val, true)
		-- mesh:SetHiddenInGame(val, true)
		mesh:call("SetRenderInMainPass", not val)
		fixFOV()
	end
end

local function doHideAnimationArms(val)
	local mesh = M.getArmsAnimationMesh()
	if mesh ~= nil then
		M.print("Hiding animation arms mesh: " .. tostring(val))
		-- mesh:SetVisibility(not val, true)
		-- mesh:SetHiddenInGame(val, true)
		mesh:call("SetRenderInMainPass", not val)
		fixFOV()
	end
end

local createDevMonitor = doOnce(function()
	uevrUtils.registerLevelChangeCallback(function(level)
		setPawnMeshList()
		setBoneNames()
	end)
end, Once.EVER)

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("pawn_config_dev")
        createDevMonitor()
		setPawnMeshList()
		setBoneNames()
   	else
        M.loadConfiguration("pawn_config_dev")
    end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Pawn Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Pawn Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end


-- function M.showConfiguration(saveFileName, options)
-- 	local configDefinition = {
-- 		{
-- 			panelLabel = "Pawn Config", 
-- 			saveFile = saveFileName, 
-- 			layout = spliceableInlineArray{
-- 				expandArray(M.getConfigurationWidgets, options)
-- 			}
-- 		}
-- 	}
-- 	configui.create(configDefinition)
-- end

function M.setBodyMeshName(val)
	bodyMeshName = "Pawn." .. val
end

function M.getBodyMesh()
	return uevrUtils.getObjectFromDescriptor(bodyMeshName)
end

function M.getArmsMesh()
	return uevrUtils.getObjectFromDescriptor(armsMeshName)
end

function M.getArmsAnimationMesh()
	return uevrUtils.getObjectFromDescriptor(armsAnimationMeshName)
end

function M.setBodyMeshFOVFixID(val)
	bodyMeshFOVFixID = val
end
function M.setArmsMeshFOVFixID(val)
	armsMeshFOVFixID = val
end


configui.onUpdate("pawnBodyMeshList", function(value)
	configui.setValue("selectedPawnBodyMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnBodyMesh", function(value)
	if value ~= "" then
		bodyMeshName = value
	end
end)

configui.onUpdate("pawnArmsMeshList", function(value)
	configui.setValue("selectedPawnArmsMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnArmsMesh", function(value)
	if value ~= "" then
		armsMeshName = value
		setBoneNames()
	end
end)

configui.onUpdate("pawnArmsAnimationMeshList", function(value)
	configui.setValue("selectedPawnArmsAnimationMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnArmsAnimationMesh", function(value)
	if value ~= "" then
		armsAnimationMeshName = value
	end
end)

configui.onCreateOrUpdate("hidePawnBodyMesh", function(value)
	M.hideBodyMesh(value)
end)

configui.onCreateOrUpdate("hidePawnArmsMesh", function(value)
	M.hideArms(value)
end)

configui.onCreateOrUpdate("hidePawnArmsBones", function(value)
	M.hideArmsBones(value)
end)


configui.onCreateOrUpdate("hidePawnArmsAnimationMesh", function(value)
	M.hideAnimationArms(value)
end)

configui.onCreateOrUpdate("pawnUpperArmRight", function(value)
	setPawnUpperArmRight(value)
end)

configui.onCreateOrUpdate("pawnUpperArmLeft", function(value)
	setPawnUpperArmLeft(value)
end)

configui.onCreateOrUpdate("pawnBodyFOVFix", function(value)
	M.setBodyMeshFOVFixID(value)
end)

configui.onCreateOrUpdate("pawnArmsFOVFix", function(value)
	M.setArmsMeshFOVFixID(value)
end)

-- Since multiple settings can affect the same mesh, this function keeps the visibility states synchronized
local function syncMeshVisibilityStates(isHidden, mesh)
	local bodyMesh = M.getBodyMesh()
	local armsMesh = M.getArmsMesh()
	local armsAnimationMesh = M.getArmsAnimationMesh()
	if mesh == bodyMesh then
		hidePawnBodyMesh = isHidden
		configui.setValue("hidePawnBodyMesh", isHidden, true)
	end
	if mesh == armsMesh then
		hidePawnArmsMesh = isHidden
		configui.setValue("hidePawnArmsMesh", isHidden, true)
	end
	if mesh == armsAnimationMesh then
		hideAnimationArms = isHidden
		configui.setValue("hidePawnArmsAnimationMesh", isHidden, true)
	end
end

function M.hideBodyMesh(val)
	syncMeshVisibilityStates(val, M.getBodyMesh())
	doHideBodyMesh(val)
end

function M.hideAnimationArms(val)
	syncMeshVisibilityStates(val, M.getArmsAnimationMesh())
	doHideAnimationArms(val)
end

function M.hideArms(val)
	syncMeshVisibilityStates(val, M.getArmsMesh())
	doHideArms(val)
end

function M.hideArmsBones(val)
	configui.setValue("hidePawnArmsBones", val, true)
	hidePawnArmsBones = val
	doHideArmsBones(val)
end

local function executeIsArmBonesHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_arms_bones_hidden", table.unpack({...}))
end
function M.registerIsArmBonesHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_arms_bones_hidden", func)
end

local function executeIsPawnBodyHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_pawn_body_hidden", table.unpack({...}))
end
function M.registerIsPawnBodyHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_pawn_body_hidden", func)
end

local function executeIsPawnArmsHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_pawn_arms_hidden", table.unpack({...}))
end
function M.registerIsPawnArmsHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_pawn_arms_hidden", func)
end

local function executeIsPawnAnimationArmsHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_pawn_animation_arms_hidden", table.unpack({...}))
end
function M.registerIsPawnAnimationArmsHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_pawn_animation_arms_hidden", func)
end


local pawnState = {}
uevrUtils.setInterval(100, function()
	local isHidden, priority = executeIsArmBonesHiddenCallback()
	if isHidden == nil then isHidden = hidePawnArmsBones end
	if pawnState.hideArmsBones ~= isHidden then
		doHideArmsBones(isHidden)
		pawnState.hideArmsBones = isHidden
	end

	isHidden, priority = executeIsPawnAnimationArmsHiddenCallback()
	if isHidden == nil then isHidden = hideAnimationArms end
	if pawnState.hideAnimationArms ~= isHidden then
		doHideAnimationArms(isHidden)
		pawnState.hideAnimationArms = isHidden
	end

	isHidden, priority = executeIsPawnBodyHiddenCallback()
	if isHidden == nil then isHidden = hidePawnBodyMesh end
	if pawnState.hideBodyMesh ~= isHidden then
		doHideBodyMesh(isHidden)
		pawnState.hideBodyMesh = isHidden
	end

	isHidden, priority = executeIsPawnArmsHiddenCallback()
	if isHidden == nil then isHidden = hidePawnArmsMesh end
	if pawnState.hideArmsMesh ~= isHidden then
		doHideArms(isHidden)
		pawnState.hideArmsMesh = isHidden
	end

end)

uevrUtils.setInterval(2000, function()
	fixFOV()
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	pawnState = {}
end)

return M



-- local armsMesh = pawnModule.getArmsMesh()
-- if armsMesh ~= nil then
	-- print("IsAnyMontagePlaying",armsMesh.AnimScriptInstance:IsAnyMontagePlaying())
	-- print("AnimToPlay",armsMesh.AnimationData.AnimToPlay)
	-- print("GetAnimationMode",armsMesh:GetAnimationMode())
	-- print("IsPlaying",armsMesh:IsPlaying())
	-- --print("IsAnyMontagePlaying2",armsMesh["As ABP PLayer Character Hands"]:IsAnyMontagePlaying())
	-- local component = uevrUtils.find_first_instance("AnimBlueprintGeneratedClass /Game/Development/Characters/PlayerCharacterHands/ABP_PLayerCharacterHands.ABP_PLayerCharacterHands_C", true)
	-- print(component:IsAnyMontagePlaying())
-- end
-- local armsMesh = pawn.FPHandsMesh
-- if armsMesh ~= nil then
	-- print("IsAnyMontagePlaying",armsMesh.AnimScriptInstance:IsAnyMontagePlaying())
	-- print("AnimToPlay",armsMesh.AnimationData.AnimToPlay)
	-- print("GetAnimationMode",armsMesh:GetAnimationMode())
	-- print("IsPlaying",armsMesh:IsPlaying())
	-- --print("IsAnyMontagePlaying2",armsMesh["As ABP PLayer Character Hands"]:IsAnyMontagePlaying())
	-- local component = uevrUtils.find_first_instance("AnimBlueprintGeneratedClass /Game/Development/Characters/PlayerCharacterHands/ABP_PLayerCharacterHands.ABP_PLayerCharacterHands_C", true)
	-- print(component:IsAnyMontagePlaying())
-- end
