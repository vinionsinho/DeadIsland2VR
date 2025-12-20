
local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local bodyYaw = require("libs/body_yaw")
local pawnModule = require("libs/pawn")
local inputEnums = require("libs/enums/input")

local M = {}

local configFileName = "dev/input_config_dev"
local configTabLabel = "Input Dev Config"
local widgetPrefix = "uevr_input_"

M.AimMethod = inputEnums.AimMethod
M.PawnPositionMode = inputEnums.PawnPositionMode
M.PawnRotationMode = inputEnums.PawnRotationMode

local boneList = {}

--local configIDs = {"isDisabledOverride", "aimMethod", "fixSpatialAudio", "rootOffset", "useSnapTurn", "snapAngle", "smoothTurnSpeed", "pawnRotationMode", "pawnPositionMode", "pawnPositionSweepMovement", "pawnPositionAnimationScale", "headOffset", "adjustForAnimation", "adjustForEyeOffset", "eyeOffset"}
-- local configDefaults = {
--     isDisabledOverride = false,
--     aimMethod = M.AimMethod.UEVR,
--     fixSpatialAudio = true,
--     rootOffset = {X=0,Y=0,Z=0},
--     useSnapTurn = false,
--     snapAngle = 30,
--     smoothTurnSpeed = 50,
--     pawnPositionMode = M.PawnPositionMode.FOLLOWS,
--     pawnRotationMode = M.PawnRotationMode.RIGHT_CONTROLLER,
--     pawnPositionSweepMovement = true,
--     pawnPositionAnimationScale = 0.2,
--     headOffset = {X=0,Y=0,Z=0},
--     adjustForAnimation = false,
--     adjustForEyeOffset = false,
--     eyeOffset = 0
-- }
local configDefaults = {}

local function getConfigWidgets()
    return spliceableInlineArray {
	{
		widgetType = "checkbox",
		id = widgetPrefix .. "isDisabledOverride",
		label = "Disabled",
		initialValue = configDefaults["isDisabledOverride"]
	},
	-- {
	-- 	widgetType = "tree_node",
	-- 	id = widgetPrefix .. "handedness_tree",
	-- 	initialOpen = true,
	-- 	label = "Handedness"
	-- },
	-- 	{
	-- 		widgetType = "combo",
	-- 		id = widgetPrefix .. "handedness",
	-- 		label = "Hand",
	-- 		selections = {"Left", "Right"},
	-- 		initialValue = uevrUtils.getHandedness()
	-- 	},
	-- {
	-- 	widgetType = "tree_pop"
	-- },
	{
		widgetType = "tree_node",
		id = widgetPrefix .. "aim_method_tree",
		initialOpen = true,
		label = "Aim Method"
	},
		{
			widgetType = "combo",
			id = widgetPrefix .. "aimMethod",
			label = "Type",
			selections = {"UEVR", "Head/HMD", "Right Controller", "Left Controller", "Right Weapon", "Left Weapon"},
			initialValue = configDefaults["aimMethod"]
		},
        {
            widgetType = "begin_group",
            id = widgetPrefix .. "advanced_aim_group",
            isHidden = false
        },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "fixSpatialAudio",
                label = "Fix Spatial Audio",
                initialValue = configDefaults["fixSpatialAudio"]
            },
            {
                widgetType = "drag_float3",
                id = widgetPrefix .. "rootOffset",
                label = "Root Offset",
                speed = .1,
                range = {-200, 200},
                initialValue = {configDefaults["rootOffset"].X, configDefaults["rootOffset"].Y, configDefaults["rootOffset"].Z}
            },
        {
            widgetType = "end_group",
        },
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "begin_group",
		id = widgetPrefix .. "advanced_input_group",
		isHidden = false
	},
		{
			widgetType = "tree_node",
			id = widgetPrefix .. "turning_tree",
			initialOpen = true,
			label = "Turning"
		},
			{
				widgetType = "checkbox",
				id = widgetPrefix .. "useSnapTurn",
				label = "Use Snap Turn",
				initialValue = configDefaults["useSnapTurn"]
			},
			{
				widgetType = "slider_int",
				id = widgetPrefix .. "snapAngle",
				label = "Snap Turn Angle",
				speed = 1.0,
				range = {2, 180},
				initialValue = configDefaults["snapAngle"]
			},
			{
				widgetType = "slider_int",
				id = widgetPrefix .. "smoothTurnSpeed",
				label = "Smooth Turn Speed",
				speed = 1.0,
				range = {1, 200},
				initialValue = configDefaults["smoothTurnSpeed"]
			},
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = widgetPrefix .. "movement_tree",
			initialOpen = true,
			label = "Movement Orientation"
		},
				{
					widgetType = "combo",
					id = widgetPrefix .. "pawnRotationMode",
					label = "Type",
					selections = {"Game", "Right Controller", "Left Controller", "Head/HMD", "Follows Body (Simple)", "Follows Body (Advanced)"},
					initialValue = configDefaults["pawnRotationMode"]
				},
				expandArray(bodyYaw.getConfigurationWidgets),
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = widgetPrefix .. "roomscale_tree",
			initialOpen = true,
			label = "Roomscale Movement"
		},
			{
				widgetType = "combo",
				id = widgetPrefix .. "pawnPositionMode",
				label = "Type",
				selections = {"None", "Follows HMD", "Follows HMD With Animation"},
				initialValue = configDefaults["pawnPositionMode"]
			},
			{
				widgetType = "checkbox",
				id = widgetPrefix .. "pawnPositionSweepMovement",
				label = "Sweep Movement",
				initialValue = configDefaults["pawnPositionSweepMovement"]
			},
			{
				widgetType = "slider_float",
				id = widgetPrefix .. "pawnPositionAnimationScale",
				label = "Animation Scale",
				speed = .01,
				range = {0, 1},
				initialValue = configDefaults["pawnPositionAnimationScale"],
			},
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = widgetPrefix .. "uevr_input_pawn_tree",
			initialOpen = true,
			label = "Player Body"
		},
			{
				widgetType = "drag_float3",
				id = widgetPrefix .. "headOffset",
				label = "Head Offset",
				speed = .1,
				range = {-200, 200},
				initialValue = {configDefaults["headOffset"].X, configDefaults["headOffset"].Y, configDefaults["headOffset"].Z}
			},
			{
				widgetType = "checkbox",
				id = widgetPrefix .. "adjustForAnimation",
				label = "Animation Movement Compensation",
				initialValue = configDefaults["adjustForAnimation"]
			},
			{
				widgetType = "combo",
				id = widgetPrefix .. "headBones",
				label = "Head Bone",
				selections = {"None"},
				initialValue = 1
			},
			{
				widgetType = "checkbox",
				id = widgetPrefix .. "adjustForEyeOffset",
				label = "Eye Offset Compensation",
				initialValue = configDefaults["adjustForEyeOffset"]
			},
			{
				widgetType = "slider_float",
				id = widgetPrefix .. "eyeOffset",
				label = "Eye Offset",
				speed = .1,
				range = {-40, 40},
				initialValue = configDefaults["eyeOffset"]
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
end
local function updateSetting(key, value)
    uevrUtils.executeUEVRCallbacks("on_input_config_param_change", key, value)
end

local function setCurrentHeadBone(value)
	local headBoneName = boneList[value]
    updateSetting("headBoneName", headBoneName)
	local mesh = pawnModule.getBodyMesh()
	if mesh ~= nil then
		local rootBoneFName = uevrUtils.getRootBoneOfBone(mesh, headBoneName)
		if rootBoneFName ~= nil then
			local rootBoneName = rootBoneFName:to_string()
            updateSetting("rootBoneName", rootBoneName)
		end
	end
end

local function setBoneNames()
	local mesh = pawnModule.getBodyMesh()
	if mesh ~= nil then
		boneList = uevrUtils.getBoneNames(mesh)
		if boneList ~= nil and #boneList > 0 then 
			configui.setSelections(widgetPrefix .. "headBones", boneList)
		end
	end
	local currentHeadBoneIndex = configui.getValue(widgetPrefix .. "headBones")
	if currentHeadBoneIndex~= nil and currentHeadBoneIndex > 1 then
		setCurrentHeadBone(currentHeadBoneIndex)
	end
end

local function updateUIState(key)
    local exKey = widgetPrefix .. key
    if key == "aimMethod" then 
        configui.hideWidget(widgetPrefix .. "advanced_input_group", configui.getValue(exKey) == M.AimMethod.UEVR)
        configui.hideWidget(widgetPrefix .. "advanced_aim_group", configui.getValue(exKey) == M.AimMethod.UEVR)
    elseif key == "useSnapTurn" then
        configui.hideWidget(widgetPrefix .. "snapAngle", not configui.getValue(exKey))
        configui.hideWidget(widgetPrefix .. "smoothTurnSpeed", configui.getValue(exKey))
    elseif key == "pawnRotationMode" then
        configui.hideWidget("minAngularDeviation", not (configui.getValue(exKey) == M.PawnRotationMode.SIMPLE or configui.getValue(exKey) == M.PawnRotationMode.ADVANCED))
        configui.hideWidget("alignConfidenceThreshold",  configui.getValue(exKey) ~= M.PawnRotationMode.ADVANCED)
    elseif key == "pawnPositionMode" then
        configui.hideWidget(widgetPrefix .. "pawnPositionAnimationScale", configui.getValue(exKey) ~= M.PawnPositionMode.ANIMATED)
        configui.hideWidget(widgetPrefix .. "pawnPositionSweepMovement", configui.getValue(exKey) ~= M.PawnPositionMode.FOLLOWS)
    elseif key == "adjustForAnimation" then 
        configui.hideWidget(widgetPrefix .. "headBones", not configui.getValue(exKey))
    elseif key == "adjustForEyeOffset" then
        configui.hideWidget(widgetPrefix .. "eyeOffset", not configui.getValue(exKey))
    end
end

configui.onCreateOrUpdate(widgetPrefix .. "isDisabledOverride", function(value)
    updateSetting("isDisabledOverride", value)
end)

configui.onUpdate(widgetPrefix .. "headOffset", function(value)
    updateSetting("headOffset", {X=value[1],Y=value[2],Z=value[3]})
end)

configui.onUpdate(widgetPrefix .. "rootOffset", function(value)
    updateSetting("rootOffset", {X=value[1],Y=value[2],Z=value[3]})
end)

configui.onUpdate(widgetPrefix .. "headBones", function(value)
	setCurrentHeadBone(value)
end)

configui.onUpdate(widgetPrefix .. "aimMethod", function(value)
	updateSetting("aimMethod", value)
    updateUIState("aimMethod")
end)

configui.onCreate(widgetPrefix .. "aimMethod", function(value)
	updateUIState("aimMethod")
end)

configui.onUpdate(widgetPrefix .. "useSnapTurn", function(value)
	updateSetting("useSnapTurn", value)
    updateUIState("useSnapTurn")
end)

configui.onCreate(widgetPrefix .. "useSnapTurn", function(value)
    updateUIState("useSnapTurn")
end)

configui.onUpdate(widgetPrefix .. "snapAngle", function(value)
	updateSetting("snapAngle", value)
end)

configui.onUpdate(widgetPrefix .. "smoothTurnSpeed", function(value)
	updateSetting("smoothTurnSpeed", value)
end)

configui.onUpdate(widgetPrefix .. "pawnRotationMode", function(value)
	updateSetting("pawnRotationMode", value)
    updateUIState("pawnRotationMode")
end)

configui.onCreate(widgetPrefix .. "pawnRotationMode", function(value)
    updateUIState("pawnRotationMode")
end)

configui.onUpdate(widgetPrefix .. "pawnPositionMode", function(value)
	updateSetting("pawnPositionMode", value)
    updateUIState("pawnPositionMode")
end)

configui.onCreate(widgetPrefix .. "pawnPositionMode", function(value)
    updateUIState("pawnPositionMode")
end)

configui.onUpdate(widgetPrefix .. "pawnPositionAnimationScale", function(value)
	updateSetting("pawnPositionAnimationScale", value)
end)

configui.onUpdate(widgetPrefix .. "adjustForAnimation", function(value)
	updateSetting("adjustForAnimation", value)
    updateUIState("adjustForAnimation")
end)

configui.onCreate(widgetPrefix .. "adjustForAnimation", function(value)
    updateUIState("adjustForAnimation")
end)

configui.onUpdate(widgetPrefix .. "adjustForEyeOffset", function(value)
	updateSetting("adjustForEyeOffset", value)
    updateUIState("adjustForEyeOffset")
end)

configui.onCreate(widgetPrefix .. "adjustForEyeOffset", function(value)
    updateUIState("adjustForEyeOffset")
end)

configui.onUpdate(widgetPrefix .. "eyeOffset", function(value)
	updateSetting("eyeOffset", value)
end)

configui.onUpdate(widgetPrefix .. "pawnPositionSweepMovement", function(value)
	updateSetting("pawnPositionSweepMovement", value)
end)

configui.onUpdate(widgetPrefix .. "fixSpatialAudio", function(value)
	updateSetting("fixSpatialAudio", value)
end)

-- configui.onUpdate(widgetPrefix .. "handedness", function(value)
-- 	uevrUtils.setHandedness(value-1)
-- end)

uevrUtils.registerLevelChangeCallback(function(level)
	setBoneNames()
end)

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(getConfigWidgets(), options)
end

function M.showConfiguration(saveFileName, options)
	local configDefinition = {
		{
			panelLabel = configTabLabel,
			saveFile = saveFileName,
			layout = spliceableInlineArray{
				expandArray(M.getConfigurationWidgets, options)
			}
		}
	}
	configui.create(configDefinition)
end

function M.init(parameters)--paramManager)
    --M.loadParameters(parametersFileName)
    configDefaults = parameters
    M.showConfiguration(configFileName)
    for key, value in pairs(parameters) do
        print(key,value)
        --if key ~= "rootOffset" and key ~= "headOffset" then
            configui.setValue(widgetPrefix .. key, value, true)
            updateUIState(key)
        --end
    end
end

function M.updateUI(key, value)
	configui.setValue(widgetPrefix .. key, value, true)
end

function M.registerParameterChangedCallback(callback)
    uevrUtils.registerUEVRCallback("on_input_config_param_change", callback)
end

-- uevrUtils.registerHandednessChangeCallback(function(handed)
-- 	configui.setValue(widgetPrefix .. "handedness", handed + 1, true)
-- end)

return M