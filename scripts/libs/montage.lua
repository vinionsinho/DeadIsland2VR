--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local montage = require("libs/montage")
        local isDeveloperMode = true  
        montage.init(isDeveloperMode)

    This module allows you to configure how animations (montages) are handled in VR. You can track recently
    played montages and configure various settings for montage playback. In developer mode, you can use the 
    configuration panel to adjust settings for specific montages.

    Available functions:

    montage.init(isDeveloperMode, logLevel) - initializes the montage system
        example:
            montage.init(true, LogLevel.Debug)

    montage.setLogLevel(val) - sets the logging level for montage messages
        example:
            montage.setLogLevel(LogLevel.Debug)

    montage.loadParameters(fileName) - loads montage parameters from a file
        example:
            montage.loadParameters("montage_config")

    montage.showConfiguration(saveFileName, options) - shows basic configuration UI
        example:
            montage.showConfiguration("montage_config")

    montage.showDeveloperConfiguration(saveFileName, options) - shows developer configuration UI
        example:
            montage.showDeveloperConfiguration("montage_config_dev")

    montage.addRecentMontage(montageName) - manually adds a montage to the recent history
        example:
            montage.addRecentMontage("AM_PlayerCharacterHands_Telekinesis")

    montage.getRecentMontages() - returns array of recent montages, newest first
        example:
            local montages = montage.getRecentMontages()
            for _, name in ipairs(montages) do
                print(name)
            end

    montage.getMostRecentMontage() - returns the name of the most recently played montage
        example:
            local lastMontage = montage.getMostRecentMontage()

    montage.getRecentMontagesAsString() - returns recent montages as a newline-delimited string
        example:
            local montagesString = montage.getRecentMontagesAsString()

    montage.clearRecentMontages() - clears the montage history
        example:
            montage.clearRecentMontages()

    montage.getConfigurationWidgets(options) - gets configuration UI widgets
        example:
            local widgets = montage.getConfigurationWidgets()

    montage.getDeveloperConfigurationWidgets(options) - gets developer configuration UI widgets
        example:
            local widgets = montage.getDeveloperConfigurationWidgets()
]]--

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local hands = require("libs/hands")
local ui = require("libs/ui")
local pawnModule = require("libs/pawn")

local M = {}

-- Configuration for recent montages tracking
local MAX_RECENT_MONTAGES = 10
local recentMontages = {}  -- Queue of recent montages, newest first

local parametersFileName = "montage_parameters"
local parameters = {}
local isParametersDirty = false

local montageList = {}
local montageIDList = {}

local montageState = {hands = nil, leftArm = nil, rightArm = nil, pawnBody = nil, pawnArms = nil, pawnArmBones = nil, motionSicknessCompensation = nil}

local stateConfig = {
    {stateKey = "hands", valueKey = "handsWhenActive"},
    {stateKey = "leftArm", valueKey = "leftArmWhenActive"},
    {stateKey = "rightArm", valueKey = "rightArmWhenActive"},
    {stateKey = "pawnBody", valueKey = "pawnBodyWhenActive"},
    {stateKey = "pawnArms", valueKey = "pawnArmsWhenActive"},
    {stateKey = "pawnArmBones", valueKey = "pawnArmBonesWhenActive"},
    {stateKey = "motionSicknessCompensation", valueKey = "motionSicknessCompensationWhenActive"},
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
    if logLevel == nil then logLevel = LogLevel.Debug end
    if logLevel <= currentLogLevel then
        uevrUtils.print("[montage] " .. text, logLevel)
    end
end

local helpText = "This module allows you to configure how montages (animations) are handled. You can view a list of recently played montages to see what montage is triggered for actions you perform in the game. You can use the configuration panel of a selected montage to adjust settings such as whether the montage will trigger hand animations or cause motion sickness compensation to kick in. Priority settings can b e useful if you have written a general purpose montage handler in code but want to override certain montages manually"
local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_montage",
		initialOpen = true,
		label = "Montage Configuration"
	},
		{
			widgetType = "combo",
			id = "knownMontageList",
			label = "Montages",
			selections = {"Any"},
			initialValue = 1,
--			width = 400
		},
        {
            widgetType = "begin_group",
            id = "knowMontageSettings",
            isHidden = false
        },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = "montage_behavior_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "When Active" }, { widgetType = "begin_rect", },
				{ widgetType = "text", label = "State                                       Priority"},
				{
					widgetType = "combo",
					id = "handsWhenActive",
					label = "",
					selections = {"No effect", "Hidden", "Visibile"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "handsWhenActivePriority",
					label = " Hands Visibility",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "leftArmWhenActive",
					label = "",
					selections = {"No effect", "Enable Animation", "Disable Animation"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "leftArmWhenActivePriority",
					label = " Left Arm Animation",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "rightArmWhenActive",
					label = "",
					selections = {"No effect", "Enable Animation", "Disable Animation"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "rightArmWhenActivePriority",
					label = " Right Arm Animation",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "pawnBodyWhenActive",
					label = "",
					selections = {"No effect", "Hidden", "Visible"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "pawnBodyWhenActivePriority",
					label = " Pawn Body Visibility",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "pawnArmsWhenActive",
					label = "",
					selections = {"No effect", "Hidden", "Visible"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "pawnArmsWhenActivePriority",
					label = " Pawn Arms Visibility",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "pawnArmBonesWhenActive",
					label = "",
					selections = {"No effect", "Hidden", "Visible"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "pawnArmBonesWhenActivePriority",
					label = " Pawn Arm Bones Visibility",
					initialValue = "0",
					width = 35,
				},
				{
					widgetType = "combo",
					id = "motionSicknessCompensationWhenActive",
					label = "",
					selections = {"No effect", "Enable", "Disable"},
					initialValue = 1,
					width = 150,
				},
				{ widgetType = "same_line" },
				{
					widgetType = "input_text",
					id = "motionSicknessCompensationWhenActivePriority",
					label = " Motion Sickness Compensation",
					initialValue = "0",
					width = 35,
				},
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },	
            { widgetType = "unindent", width = 20 },
        {
            widgetType = "end_group",
        },
		{ widgetType = "new_line" },
       	{
            widgetType = "input_text_multiline",
            id = "recentMontagesPlayed",
            label = " ",
            initialValue = "",
            size = {440, 230} -- optional, will default to full size without it
        },
		-- {
		-- 	widgetType = "input_text",
		-- 	id = "lastMontagePlayed",
		-- 	label = "Last Montage Played",
		-- 	initialValue = "",
		-- },
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

local function showMontageEditFields()
    local index = configui.getValue("knownMontageList")
    if index == nil then --or index == 1 then
        configui.setHidden("knowMontageSettings", true)
        return
    end
    configui.setHidden("knowMontageSettings", false)

    local id = montageIDList[index]
    if id ~= "" and parameters ~= nil and parameters["montagelist"] ~= nil and parameters["montagelist"][id] ~= nil then
        local data = parameters["montagelist"][id]
        if data ~= nil then
            -- Initialize and set values for all state configs
            for _, config in ipairs(stateConfig) do
                local valueKey = config.valueKey
                if data[valueKey] == nil then data[valueKey] = 1 end
                configui.setValue(valueKey, data[valueKey], true)
                
                local priorityKey = valueKey .. "Priority"
                if data[priorityKey] == nil or data[priorityKey] == "" then data[priorityKey] = "0" end
                configui.setValue(priorityKey, data[priorityKey], true)
            end
        end
    end
end

local function updateMontageList()
    montageList = {}
	montageIDList = {}
    if parameters ~= nil and parameters["montagelist"] ~= nil then
        for id, data in pairs(parameters["montagelist"]) do
            if data ~= nil and data["label"] ~= nil then
                table.insert(montageList, data["label"])
                table.insert(montageIDList, id)
            end
        end
		--can only do this because key and label are the same
        table.sort(montageList)
        table.sort(montageIDList)

        --table.insert(montageList, 1, "Any")
        --table.insert(montageIDList, 1, "Any")
        configui.setSelections("knownMontageList", montageList)
		configui.setValue("knownMontageList", 1)

		showMontageEditFields()
    end
end

local function saveParameters()
	M.print("Saving montage parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)

	uevrUtils.registerMontageChangeCallback(function(montage, montageName)
		if parameters ~= nil and montageName ~= nil and montageName ~= "" then
			if parameters["montagelist"] == nil then
				parameters["montagelist"] = {}
				isParametersDirty = true
			end
			if parameters["montagelist"][montageName] == nil then
				parameters["montagelist"][montageName] = {}
				parameters["montagelist"][montageName]["label"] = montageName
				parameters["montagelist"][montageName]["class_name"] = montage:get_full_name()
				isParametersDirty = true
				updateMontageList()
			elseif parameters["montagelist"][montageName]["class_name"] == nil then
				parameters["montagelist"][montageName]["class_name"] = montage:get_full_name()
				isParametersDirty = true
			end
			--configui.setValue("lastMontagePlayed", montageName)
            M.addRecentMontage(montageName)  -- Track in recent history
			configui.setValue("recentMontagesPlayed", M.getRecentMontagesAsString())
		end
	end)
end, Once.EVER)

local function updateCurrentMontageFields()
    local index = configui.getValue("knownMontageList")
    if index ~= nil then --and index ~= 1 then
        local id = montageIDList[index]
        if id ~= "" and  parameters ~= nil and parameters["montagelist"] ~= nil and parameters["montagelist"][id] ~= nil then
            for _, config in ipairs(stateConfig) do
                local valueKey = config.valueKey
                parameters["montagelist"][id][valueKey] = configui.getValue(valueKey)
                parameters["montagelist"][id][valueKey .. "Priority"] = configui.getValue(valueKey .. "Priority")
            end
            isParametersDirty = true
        end
    end
end

local function updateStateIfHigherPriority(data, stateKey, valueKey)
	local priority = tonumber(data[valueKey .. "Priority"]) or 0
	if priority >= montageState[stateKey .. "Priority"] then
		if data[valueKey] == 2 then
			montageState[stateKey] = true
			montageState[stateKey .. "Priority"] = priority
		elseif data[valueKey] == 3 then
			montageState[stateKey] = false
			montageState[stateKey .. "Priority"] = priority
		end
	end
end

uevrUtils.registerMontageChangeCallback(function(montage, montageName)
	for _, config in ipairs(stateConfig) do
		montageState[config.stateKey] = nil
		montageState[config.stateKey .. "Priority"] = 0
	end

	if parameters ~= nil and montageName ~= nil and montageName ~= "" and parameters["montagelist"] ~= nil and parameters["montagelist"][montageName] ~= nil  then
		local data = parameters["montagelist"][montageName]
		for _, config in ipairs(stateConfig) do
			updateStateIfHigherPriority(data, config.stateKey, config.valueKey)
		end
	end
end)

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("montage_config_dev")
        createDevMonitor()
        updateMontageList()
    end
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading montage parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating montage parameters")
	end

	if parameters["montagelist"] == nil then
		parameters["montagelist"] = {}
		isParametersDirty = true
	end
	if parameters["montagelist"]["Any"] == nil then
		parameters["montagelist"]["Any"] = {}
		parameters["montagelist"]["Any"]["label"] = "Any"
		isParametersDirty = true
	end

    updateMontageList()
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Montage Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Montage Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

-- Functions for managing recent montages
function M.addRecentMontage(montageName)
    -- Remove if already in list (to move it to front)
    -- for i = #recentMontages, 1, -1 do
    --     if recentMontages[i] == montageName then
    --         table.remove(recentMontages, i)
    --         break
    --     end
    -- end
    
    -- Add to front
    table.insert(recentMontages, 1, montageName)
    
    -- Trim if exceeds max size
    while #recentMontages > MAX_RECENT_MONTAGES do
        table.remove(recentMontages)
    end
    
    M.print("Recent montage added: " .. montageName, LogLevel.Debug)
end

function M.getRecentMontages()
    return recentMontages
end

function M.getMostRecentMontage()
    return recentMontages[1]
end

function M.clearRecentMontages()
    recentMontages = {}
end

function M.playMontage(montageName, speed)
	if uevrUtils.getValid(pawn) ~= nil and parameters ~= nil and montageName ~= nil and montageName ~= "" and parameters["montagelist"][montageName] ~= nil then
		local className = parameters["montagelist"][montageName]["class_name"]
		if className ~= nil then
			local montage = uevrUtils.find_required_object(className)
			if montage ~= nil then
				local result = pawn:PlayAnimMontage(montage, speed or 1.0, uevrUtils.fname_from_string(""))
			end
		end
	end
end
-- Returns recent montages as a newline-delimited string
function M.getRecentMontagesAsString()
    return table.concat(recentMontages, "\n")
end

hands.registerIsAnimatingFromMeshCallback(function(hand)
	--print("IsAnimatingFromMesh", hand, montageState["leftArm"], montageState["leftArmPriority"], montageState["rightArm"], montageState["rightArmPriority"])
	if hand == Handed.Right then
		return montageState["rightArm"], montageState["rightArmPriority"]
	end
	return montageState["leftArm"], montageState["leftArmPriority"]
end)

ui.registerIsInMotionSicknessCausingSceneCallback(function()
	return montageState["motionSicknessCompensation"], montageState["motionSicknessCompensationPriority"]
end)

pawnModule.registerIsArmBonesHiddenCallback(function()
	return montageState["pawnArmBones"], montageState["pawnArmBonesPriority"]
end)

pawnModule.registerIsPawnBodyHiddenCallback(function()
	return montageState["pawnBody"], montageState["pawnBodyPriority"]
end)

pawnModule.registerIsPawnArmsHiddenCallback(function()
	return montageState["pawnArms"], montageState["pawnArmsPriority"]
end)

hands.registerIsHiddenCallback(function()
	return montageState["hands"], montageState["handsPriority"]
end)

-- Register update handlers for all state configs and their priorities
for _, config in ipairs(stateConfig) do
    local valueKey = config.valueKey
    configui.onUpdate(valueKey, function(value)
        updateCurrentMontageFields()
    end)
    configui.onUpdate(valueKey .. "Priority", function(value)
        updateCurrentMontageFields()
    end)
end

configui.onUpdate("knownMontageList", function(value)
	showMontageEditFields()
end)


M.loadParameters()

return M