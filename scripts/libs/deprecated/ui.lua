--[[ 
Usage
    Drop the lib folder containing this file into your project folder

     Add code like this in your script:
        local ui = require("libs/ui")
        local isDeveloperMode = true  
        ui.init(isDeveloperMode)

    This module provides functions to manage UI settings such as head-locked UI, viewport widget states, and motion sickness reduction.

    Available functions:

    ui.init(isDeveloperMode, logLevel) - initializes the UI system
        example:
            ui.init(true, LogLevel.Debug)

    ui.setIsHeadLocked(value) - enables/disables head-locked UI mode
        example:
            ui.setIsHeadLocked(true)

    ui.setHeadLockedUIPosition(value) - sets the position of head-locked UI
        example:
            ui.setHeadLockedUIPosition({X=0, Y=0, Z=2.0})

    ui.setHeadLockedUISize(value) - sets the size of head-locked UI
        example:
            ui.setHeadLockedUISize(2.0)

    ui.disableHeadLockedUI(value) - temporarily disables head-locked UI without changing its state
        example:
            ui.disableHeadLockedUI(true)

    ui.getViewportWidgetState() - gets the current state of viewport widgets
        example:
            local state = ui.getViewportWidgetState()
            -- state contains: viewLocked, screen2D, decouplePitch, inputEnabled, handsEnabled

    ui.setIsInMotionSicknessCausingScene(value) - sets whether current scene may cause motion sickness
        example:
            ui.setIsInMotionSicknessCausingScene(true)

    ui.registerIsInMotionSicknessCausingSceneCallback(func) - registers a callback for motion sickness scene changes
        Second param  is an optional priority. Higher priority callbacks override lower priority ones.
        If the second param is not provided it defaults to 0.
        example:
            ui.registerIsInMotionSicknessCausingSceneCallback(function()
                return isInMotionSicknessCausingScene, 0
            end)

    ui.loadParameters(fileName) - loads UI parameters from a file
        example:
            ui.loadParameters("ui_config")

    ui.getConfigurationWidgets(options) - gets configuration UI widgets
        example:
            local widgets = ui.getConfigurationWidgets()

    ui.getDeveloperConfigurationWidgets(options) - gets developer configuration UI widgets
        example:
            local widgets = ui.getDeveloperConfigurationWidgets()

    ui.showConfiguration(saveFileName, options) - shows basic configuration UI
        example:
            ui.showConfiguration("ui_config")

    ui.showDeveloperConfiguration(saveFileName, options) - shows developer configuration UI
        example:
            ui.showDeveloperConfiguration("ui_config_dev")

    ui.setLogLevel(val) - sets the logging level for UI messages
        example:
            ui.setLogLevel(LogLevel.Debug)

    ui.print(text, logLevel) - prints a debug/log message with the specified log level
        example:
            ui.print("UI initialized", LogLevel.Info)

    ui.registerWidgetChangeCallback(widgetName, func) - registers a callback for when specific high level 
        viewport widgets become active/inactive. The widgetName can be found in the UI interface list
        example:
            ui.registerWidgetChangeCallback("WBP_UniversalLockTooltipWidget_C", function(active)
                print("Widget changed:", active)
            end)


]]--


local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local input = require("libs/input")

local M = {}

local headLockedUI = false
local headLockedUISize = 2.0
local headLockedUIPosition = {X=0, Y=0, Z=2.0}
local isFollowing = true
local reduceMotionSickness = false
local isInMotionSicknessCausingScene = false

local viewportWidgetList = {}
local viewportWidgetIDList = {}
local uiState = {viewLocked = nil, screen2D = nil, decouplePitch = nil, inputEnabled = nil, handsEnabled = nil}

local widgetPrefix = "uevr_ui_"

local stateConfigWidget = {
    {stateKey = "viewLocked", valueKey = "lockedUIWhenActive"},
    {stateKey = "screen2D", valueKey = "screen2DWhenActive"},
    {stateKey = "decouplePitch", valueKey = "decouplePitchWhenActive"},
    {stateKey = "autoAdjustUI", valueKey = "autoAdjustUIWhenActive"},
    {stateKey = "inputEnabled", valueKey = "inputWhenActive"},
    {stateKey = "handsEnabled", valueKey = "handsWhenActive"},
    {stateKey = "remapEnabled", valueKey = "remapWhenActive"}
}

local stateConfigGame = {
    {stateKey = "viewLocked", valueKey = "lockedUIWhenInGameState"},
    {stateKey = "screen2D", valueKey = "screen2DWhenInGameState"},
    {stateKey = "decouplePitch", valueKey = "decouplePitchWhenInGameState"},
    {stateKey = "autoAdjustUI", valueKey = "autoAdjustUIWhenInGameState"},
    {stateKey = "inputEnabled", valueKey = "inputWhenInGameState"},
    {stateKey = "handsEnabled", valueKey = "handsWhenInGameState"},
    {stateKey = "remapEnabled", valueKey = "remapWhenInGameState"}
}

local gameStates = {"cutscene", "paused", "character_hidden"}

local parametersFileName = "ui_parameters"
local parameters = {}
local isParametersDirty = false

local currentViewportWidgetsStr = ""
local currentGameStateText = ""
local currentWidgetViewportState = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[ui] " .. text, logLevel)
	end
end

--start with lerping disabled in case it was left on accidentally
uevrUtils.enableCameraLerp(false, true, true, true)
--start with snap turn disabled in case it was left on accidentally
uevrUtils.enableSnapTurn(false)

local helpText = "This module allows you to configure how the system behaves when the game state changes or UI overlays such as dialogs and menus are active. You can set whether the view is locked when a widget is active, whether 2D mode is enabled, whether pitch is decoupled, whether input is enabled, and whether hands are shown. Settings are applied based on priority, so if multiple widgets are active, the one with the highest priority for a given setting takes precedence. For example, if one active widget sets 'Screen 2D' to 'Enable' with priority 5, and another active widget sets it to 'Disable' with priority 10, the screen will not be 2D because the second widget has a higher priority."
local configWidgets = spliceableInlineArray{
	-- {
	-- 	widgetType = "tree_node",
	-- 	id = "uevr_ui",
	-- 	initialOpen = true,
	-- 	label = "UI Configuration"
	-- },
        {
            widgetType = "checkbox",
            id = "headLockedUI",
            label = "Enable Head Locked UI",
            initialValue = headLockedUI
        },
		{
			widgetType = "drag_float3",
			id = "headLockedUIPosition",
			label = "UI Position",
			speed = .01,
			range = {-10, 10},
			initialValue = {headLockedUIPosition.X, headLockedUIPosition.Y, headLockedUIPosition.Z}
		},
		{
			widgetType = "drag_float",
			id = "headLockedUISize",
			label = "UI Size",
			speed = .01,
			range = {-10, 10},
			initialValue = headLockedUISize
		},
        {
            widgetType = "checkbox",
            id = "reduceMotionSickness",
            label = "Reduce Motion Sickness in Cutscenes",
            initialValue = reduceMotionSickness
        },
	-- {
	-- 	widgetType = "tree_pop"
	-- },
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_ui_cutscene",
		initialOpen = true,
		label = "Game State Configuration"
	},
		{ widgetType = "text", id = "currentGameStateText", label = "Current Game State:"},
        {
            widgetType = "combo",
            id = "gameStateList",
            label = "Game State",
            selections = {"In Cutscene", "Game Paused", "Character Hidden"},
            initialValue = 1,
            --width = 150,
        },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = "paused_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", id = "game_state_description", label = "When in Cutscene" }, { widgetType = "begin_rect", },
            { widgetType = "text", label = "State                                       Priority"},
            {
                widgetType = "combo",
                id = "lockedUIWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "lockedUIWhenInGameStatePriority",
                label = " Locked UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "screen2DWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "screen2DWhenInGameStatePriority",
                label = " Screen 2D",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "decouplePitchWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "decouplePitchWhenInGameStatePriority",
                label = " Decoupled Pitch",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "autoAdjustUIWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "autoAdjustUIWhenInGameStatePriority",
                label = " Auto Adjust UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "inputWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "inputWhenInGameStatePriority",
                label = " Input",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "handsWhenInGameState",
                label = "",
                selections = {"No effect", "Show", "Hide"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "handsWhenInGameStatePriority",
                label = " Hands",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "remapWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "remapWhenInGameStatePriority",
                label = " Remap",
                initialValue = "0",
                width = 35,
            },
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
	        { widgetType = "unindent", width = 20 },
	        { widgetType = "new_line" },
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_ui_widgets",
		initialOpen = true,
		label = "UI Widget Configuration"
	},
		{
			widgetType = "combo",
			id = "knownViewportWidgetList",
			label = "Config Widget",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
        {
            widgetType = "begin_group",
            id = "knownViewportWidgetSettings",
            isHidden = false
        },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = "viewport_widget_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "When Active" }, { widgetType = "begin_rect", },
            { widgetType = "text", label = "State                                       Priority"},
            {
                widgetType = "combo",
                id = "lockedUIWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "lockedUIWhenActivePriority",
                label = " Locked UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "screen2DWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "screen2DWhenActivePriority",
                label = " Screen 2D",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "decouplePitchWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "decouplePitchWhenActivePriority",
                label = " Decoupled Pitch",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "autoAdjustUIWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "autoAdjustUIWhenActivePriority",
                label = " Auto Adjust UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "inputWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "inputWhenActivePriority",
                label = " Input",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "handsWhenActive",
                label = "",
                selections = {"No effect", "Show", "Hide"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "handsWhenActivePriority",
                label = " Hands",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "remapWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "remapWhenActivePriority",
                label = " Remap",
                initialValue = "0",
                width = 35,
            },
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
            { widgetType = "unindent", width = 20 },
		    { widgetType = "new_line" },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = "viewport_widget_settings", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Settings" }, { widgetType = "begin_rect", },
                {
                    widgetType = "drag_float2",
                    id = widgetPrefix .. "widget_scale_2d",
                    label = "Scale 2D",
                    speed = .01,
                    range = {0.01, 1},
                    initialValue = {1, 1}
                },
                {
                    widgetType = "drag_float2",
                    id = widgetPrefix .. "widget_alignment_2d",
                    label = "Alignment 2D",
                    speed = .01,
                    range = {-1, 1},
                    initialValue = {0, 0}
                },
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
            { widgetType = "unindent", width = 20 },
		    { widgetType = "new_line" },
        {
            widgetType = "end_group",
        },
		{ widgetType = "new_line" },
        { widgetType = "indent", width = 1 },
		{ widgetType = "text", label = "Current Active Widgets"},
        {
            widgetType = "input_text_multiline",
            id = "currentViewportWidgets",
            label = " ",
            initialValue = "",
            size = {440, 180} -- optional, will default to full size without it
        },
        { widgetType = "unindent", width = 1 },
		-- {
		-- 	widgetType = "input_text",
		-- 	id = "lastWidgetPlayed",
		-- 	label = "Last Widget Played",
		-- 	initialValue = "",
		-- },
	    { widgetType = "new_line" },
	{
		widgetType = "tree_pop"
	},
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

local canFollowLast = nil
local function updateUI(force)
    -- local canFollowView = ((headLockedUI and uiState["viewLocked"] ~= true) or (not headLockedUI and uiState["viewLocked"] == true)) and isFollowing
    -- if force or canFollowLast ~= canFollowView then
    --     uevrUtils.enableUIFollowsView(canFollowView)
    --     if canFollowView then
    --         uevrUtils.setUIFollowsViewOffset(headLockedUIPosition)
    --         uevrUtils.setUIFollowsViewSize(headLockedUISize)
    --     else
    --         uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=2.0})
    --         uevrUtils.setUIFollowsViewSize(2.0)
    --         --if we're in a state where the view is locked, recenter the view so that we're facing the locked UI
    --         input.resetView()
    --     end
    -- end
    -- canFollowLast = canFollowView

    if force or uiState["viewLocked_last"] ~= uiState["viewLocked"] then
        local isLocked = false
        if uiState["viewLocked"] == nil then
            isLocked = headLockedUI
        else
            isLocked = not uiState["viewLocked"]
            if not isLocked then
                --if we're in a state where the view is locked, recenter the view so that we're facing the locked UI
                input.resetView()
            end
        end
        uevrUtils.enableUIFollowsView(isLocked)
        if isLocked then
            uevrUtils.setUIFollowsViewOffset(headLockedUIPosition)
            uevrUtils.setUIFollowsViewSize(headLockedUISize)
        else
            uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=2.0})
            uevrUtils.setUIFollowsViewSize(2.0)
        end
        uiState["viewLocked_last"] = uiState["viewLocked"]
        --M.print("Setting 2D mode to " .. tostring(viewportWidgetState["screen2D"]))
    end


    if uiState["screen2D_last"] ~= uiState["screen2D"] then
        if uiState["screen2D_last"] == nil then
            uiState["screen2D_cache"] = uevrUtils.get_2D_mode()
        end
        if uiState["screen2D"] == nil then
            uevrUtils.set_2D_mode(uiState["screen2D_cache"])
        else
            uevrUtils.set_2D_mode(uiState["screen2D"])
        end
        uiState["screen2D_last"] = uiState["screen2D"]
        --M.print("Setting 2D mode to " .. tostring(viewportWidgetState["screen2D"]))
    end

    if uiState["decouplePitch_last"] ~= uiState["decouplePitch"] then
        if uiState["decouplePitch_last"] == nil then
            uiState["decouplePitch_cache"] = uevrUtils.get_decoupled_pitch()
        end
        if uiState["decouplePitch"] == nil then
            uevrUtils.set_decoupled_pitch(uiState["decouplePitch_cache"])
        else
            uevrUtils.set_decoupled_pitch(uiState["decouplePitch"])
        end
        uiState["decouplePitch_last"] = uiState["decouplePitch"]
    end

    if uiState["autoAdjustUI_last"] ~= uiState["autoAdjustUI"] then
        if uiState["autoAdjustUI_last"] == nil then
            uiState["autoAdjustUI_cache"] = uevrUtils.get_decoupled_pitch_adjust_ui()
        end
        if uiState["autoAdjustUI"] == nil then
            uevrUtils.set_decoupled_pitch_adjust_ui(uiState["autoAdjustUI_cache"])
        end
        if uiState["autoAdjustUI"] == nil then
            uevrUtils.set_decoupled_pitch_adjust_ui(uiState["autoAdjustUI_cache"])
        else
            uevrUtils.set_decoupled_pitch_adjust_ui(uiState["autoAdjustUI"])
        end
        uiState["autoAdjustUI_last"] = uiState["autoAdjustUI"]
    end
end

input.registerIsDisabledCallback(function()
	return uiState["inputEnabled"] ~= nil and (not uiState["inputEnabled"]) or nil, uiState["inputEnabledPriority"]
end)

uevrUtils.registerUEVRCallback("is_remap_disabled", function()
	return uiState["remapEnabled"] ~= nil and (not uiState["remapEnabled"]) or nil, uiState["remapEnabledPriority"]
end)

uevrUtils.registerUEVRCallback("is_hands_hidden", function()
	return uiState["handsEnabled"] ~= nil and (not uiState["handsEnabled"]) or nil, uiState["handsEnabledPriority"]
end)

local function getCurrentSelectedWidgetClass()
    local index = configui.getValue("knownViewportWidgetList")
    if index ~= nil and index ~= 1 then
        return viewportWidgetIDList[index]
    end
    return ""
end


local function showViewportWidgetEditFields()
    local index = configui.getValue("knownViewportWidgetList")
    if index == nil or index == 1 then
        configui.setHidden("knownViewportWidgetSettings", true)
        return
    end
    configui.setHidden("knownViewportWidgetSettings", false)

    local id = viewportWidgetIDList[index]
    if id ~= "" and parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
        local data = parameters["widgetlist"][id]
        if data ~= nil then
            -- Initialize and set values for all state configs
            for _, config in ipairs(stateConfigWidget) do
                local valueKey = config.valueKey
                if data[valueKey] == nil then data[valueKey] = 1 end
                configui.setValue(valueKey, data[valueKey], true)

                local priorityKey = valueKey .. "Priority"
                if data[priorityKey] == nil or data[priorityKey] == "" then data[priorityKey] = "0" end
                configui.setValue(priorityKey, data[priorityKey], true)
            end

            configui.setValue(widgetPrefix .. "widget_scale_2d", parameters["widgetlist"][id]["scale"] or {1,1}, true)
            configui.setValue(widgetPrefix .. "widget_alignment_2d", parameters["widgetlist"][id]["alignment"] or {0,0}, true)
        end
    end
end

local function showGameStateEditFields()
    local index = configui.getValue("gameStateList")
    local state = gameStates[index] or "cutscene"
    configui.setLabel("game_state_description", "When " .. (state == "cutscene" and "in Cutscene" or ((state == "paused" and "Game is Paused" or "Character is Hidden"))))
    if parameters ~= nil then
        for _, config in ipairs(stateConfigGame) do
            local valueKey = config.valueKey
            local value = 1
            if parameters[state] ~= nil and parameters[state][valueKey] ~= nil then
                value = parameters[state][valueKey]
            end
            configui.setValue(valueKey, value, true)

            local priorityKey = valueKey .. "Priority"
            local priority = "0"
            if parameters[state] ~= nil and parameters[state][priorityKey] ~= nil then
                priority = parameters[state][priorityKey]
            end
            configui.setValue(priorityKey, priority, true)
        end
    end
end

local function updateCurrentViewportWidgetFields()
    -- local index = configui.getValue("knownViewportWidgetList")
    -- if index ~= nil and index ~= 1 then
    --     local id = viewportWidgetIDList[index]
        local id = getCurrentSelectedWidgetClass()
        if id ~= "" and  parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
            for _, config in ipairs(stateConfigWidget) do
                local valueKey = config.valueKey
                parameters["widgetlist"][id][valueKey] = configui.getValue(valueKey)
                parameters["widgetlist"][id][valueKey .. "Priority"] = configui.getValue(valueKey .. "Priority")
            end
            parameters["widgetlist"][id]["scale"] = uevrUtils.getNativeValue(configui.getValue(widgetPrefix .. "widget_scale_2d"))
            parameters["widgetlist"][id]["alignment"] = uevrUtils.getNativeValue(configui.getValue(widgetPrefix .. "widget_alignment_2d"))
            isParametersDirty = true
        end
    -- end
end

local function updateViewportWidgetList()
    viewportWidgetList = {}
    viewportWidgetIDList = {}
    if parameters ~= nil and parameters["widgetlist"] ~= nil then
       for id, data in pairs(parameters["widgetlist"]) do
          if data ~= nil and data["label"] ~= nil then
              table.insert(viewportWidgetList, data["label"])
              table.insert(viewportWidgetIDList, id)
          end
        end
        table.insert(viewportWidgetList, 1, "None")
        table.insert(viewportWidgetIDList, 1, "")
        configui.setSelections("knownViewportWidgetList", viewportWidgetList)
        configui.setValue("knownViewportWidgetList", 1)

        showViewportWidgetEditFields()
    end
end

local function registerViewportWidget(widgetClassName, widgetShortName)
   if parameters ~= nil and widgetClassName ~= nil and widgetClassName ~= "" then
        if parameters["widgetlist"] == nil then
            parameters["widgetlist"] = {}
            isParametersDirty = true
        end
        if parameters["widgetlist"][widgetClassName] == nil then
            parameters["widgetlist"][widgetClassName] = {}
            parameters["widgetlist"][widgetClassName]["label"] = widgetShortName
            isParametersDirty = true

            updateViewportWidgetList()
        end
        --configui.setValue("lastWidgetPlayed", widgetClassName)
    end
end

local function registerViewportWidgets()
	local foundWidgets = {}
	local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
    ---@diagnostic disable-next-line: undefined-field
    WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
	--print("Found widgets: " .. #foundWidgets)
	for index, widget in pairs(foundWidgets) do
		--print(widget:get_full_name(), widget:get_class():get_full_name(), widget:IsInViewport())
        registerViewportWidget(widget:get_class():get_full_name(), uevrUtils.getShortName(widget:get_class()))
 	end
end

local function updateStateIfHigherPriority(data, stateKey, valueKey)
    local priority = tonumber(data[valueKey .. "Priority"]) or 0
    if priority >= uiState[stateKey .. "Priority"] then
        if data[valueKey] == 2 then
            uiState[stateKey] = true
            uiState[stateKey .. "Priority"] = priority
        elseif data[valueKey] == 3 then
            uiState[stateKey] = false
            uiState[stateKey .. "Priority"] = priority
        end
    end
end

local newWidgetViewportState = {}
local function updateWidgetChangeCallbacks()
    for id, isInViewport in pairs(newWidgetViewportState) do
        if currentWidgetViewportState[id] ~= isInViewport then
            currentWidgetViewportState[id] = isInViewport
            M.print("Widget " .. id .. " change, isInViewport = " .. tostring(isInViewport))
            uevrUtils.executeUEVRCallbacks("widget_change_" .. id, isInViewport)
        end
    end
    for id, isInViewport in pairs(currentWidgetViewportState) do
       newWidgetViewportState[id] = false
    end
end


local function updateUIState()
    currentViewportWidgetsStr = ""
    if parameters ~= nil and parameters["widgetlist"] ~= nil then
        for _, config in ipairs(stateConfigWidget) do
            uiState[config.stateKey] = nil
            uiState[config.stateKey .. "Priority"] = 0
        end

        local foundWidgets = {}
        local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
        ---@diagnostic disable-next-line: undefined-field
        WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
        --print("Found widgets: " .. #foundWidgets)
        for index, widget in pairs(foundWidgets) do
            if widget:IsInViewport() then --check not really needed since GetAllWidgetsOfClass with the last param true should only return viewport widgets
                --get the widget data from the configurations
                local id = widget:get_class():get_full_name()
                local data = parameters["widgetlist"][id]
                if data ~= nil then
                    if data["label"] ~= nil then
                        currentViewportWidgetsStr = currentViewportWidgetsStr .. data["label"] .. "\n"
                    end
                    for _, config in ipairs(stateConfigWidget) do
                        updateStateIfHigherPriority(data, config.stateKey, config.valueKey)
                    end
                    newWidgetViewportState[data["label"]] = true
                    uevrUtils.setWidgetLayout(widget, data["scale"], data["alignment"])
                    --updateCurrentWidgetChangeCallbackState(data["label"], true)
                end
            -- else
            --     print ("Widget " .. id .. " not in viewport")
            end
        end
        updateWidgetChangeCallbacks()
    end

    currentGameStateText = "Current Game State: "
    local isInCutscene = uevrUtils.isInCutscene()
    local isPaused = uevrUtils.isGamePaused()
    local isCharacterHidden = uevrUtils.getValid(pawn,{ "Controller", "Character", "bHidden"}) or false
    currentGameStateText = currentGameStateText .. "Is In Cutscene = " .. tostring(isInCutscene) .. ", Is Paused = " .. tostring(isPaused) .. ", Is Character Hidden = " .. tostring(isCharacterHidden)
    for index, gameStateName in ipairs(gameStates) do
        local isActive = (gameStateName == "cutscene" and isInCutscene) or (gameStateName == "paused" and isPaused) or (gameStateName == "character_hidden" and isCharacterHidden)
        if parameters ~= nil and parameters[gameStateName] ~= nil and isActive then
            --print("Updating game state", gameStateName)
            local data = parameters[gameStateName]
            if data ~= nil then
                for _, config in ipairs(stateConfigGame) do
                    updateStateIfHigherPriority(data, config.stateKey, config.valueKey)
                end
            end
        end
    end
end


local function saveParameters()
	M.print("Saving ui parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(500, function()
        registerViewportWidgets()
        configui.setValue("currentViewportWidgets", currentViewportWidgetsStr)
        configui.setLabel("currentGameStateText", currentGameStateText)

        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)
end, Once.EVER)

local enableCutsceneDetection = doOnce(function()
    uevrUtils.registerCutsceneChangeCallback(function(inCutscene)
        updateUIState()
        updateUI()
    end)
end, Once.EVER)

local enablePauseDetection = doOnce(function()
    uevrUtils.registerGamePausedCallback(function(isPaused)
        updateUIState()
        updateUI()
    end)
end, Once.EVER)

local enableCharacterHiddenDetection = doOnce(function()
    uevrUtils.registerCharacterHiddenCallback(function(isHidden)
        updateUIState()
        updateUI()
    end)
end, Once.EVER)

local function createGameStateMonitor()
    for index, gameStateName in ipairs(gameStates) do
        if parameters ~= nil and parameters[gameStateName] ~= nil then
            local data = parameters[gameStateName]
            if data ~= nil then
                for _, config in ipairs(stateConfigGame) do
                    if data[config.valueKey] == 2 or data[config.valueKey] == 3 then
                        if gameStateName == "cutscene" then
                            enableCutsceneDetection()
                            M.print("Enabled cutscene detection")
                        end
                        if gameStateName == "paused" then
                            enablePauseDetection()
                            M.print("Enabled pause detection")
                        end
                       if gameStateName == "character_hidden" then
                            enableCharacterHiddenDetection()
                            M.print("Enabled character hidden detection")
                        end
                        break
                    end
                end
            end
        end
    end
end

local function updateGameStateFields()
    local index = configui.getValue("gameStateList")
    local state = gameStates[index] or "cutscene"
    if parameters[state] == nil then
        parameters[state] = {}
        isParametersDirty = true
    end
    for _, config in ipairs(stateConfigGame) do
        local valueKey = config.valueKey
        parameters[state][valueKey] = configui.getValue(valueKey)
        parameters[state][valueKey .. "Priority"] = configui.getValue(valueKey .. "Priority")
    end
    isParametersDirty = true

    createGameStateMonitor()
end

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("ui_config_dev")
        createDevMonitor()
        updateViewportWidgetList()
    end
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading ui parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating ui parameters")
	end

    createGameStateMonitor()
 end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("UI Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("UI Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

configui.onUpdate("knownViewportWidgetList", function(value)
	showViewportWidgetEditFields()
end)

-- configui.onCreateOrUpdate("shouldLockViewWhenVisible", function(value)
-- 	updateCurrentViewportWidgetFields()
-- end)

-- configui.onCreateOrUpdate("useControllerMouse", function(value)
-- 	updateCurrentViewportWidgetFields()
-- end)

-- Register update handlers for all state configs and their priorities
for _, config in ipairs(stateConfigWidget) do
    local valueKey = config.valueKey
    configui.onUpdate(valueKey, function(value)
        updateCurrentViewportWidgetFields()
    end)
    configui.onUpdate(valueKey .. "Priority", function(value)
        updateCurrentViewportWidgetFields()
    end)
end

for _, config in ipairs(stateConfigGame) do
    local valueKey = config.valueKey
    configui.onUpdate(valueKey, function(value)
        updateGameStateFields()
    end)
    configui.onUpdate(valueKey .. "Priority", function(value)
        updateGameStateFields()
    end)
end

configui.onCreate("reduceMotionSickness", function(value)
	reduceMotionSickness = value
end)

configui.onCreateOrUpdate("gameStateList", function(value)
	showGameStateEditFields()
end)


configui.onUpdate("reduceMotionSickness", function(value)
	if reduceMotionSickness then
		uevrUtils.enableCameraLerp(value, true, true, true)
    else
        uevrUtils.enableCameraLerp(value and isInMotionSicknessCausingScene, true, true, true)
	end
	reduceMotionSickness = value
end)

configui.onCreateOrUpdate("headLockedUI", function(value)
	M.setIsHeadLocked(value)
    configui.setHidden("headLockedUIPosition", not value)
    configui.setHidden("headLockedUISize", not value)
end)

configui.onCreateOrUpdate("headLockedUIPosition", function(value)
	M.setHeadLockedUIPosition(value)
end)

configui.onCreateOrUpdate("headLockedUISize", function(value)
    M.setHeadLockedUISize(value)
end)

local function getCurrentSelectedWidget()
    local id = getCurrentSelectedWidgetClass()
    print("ID is " .. id)
    if id ~= "" then
        return uevrUtils.find_first_of(id, false)
    end
end

--local WidgetLayoutLibrary = nil
local function updateWidgetLayout()
    updateCurrentViewportWidgetFields()
    local widget = getCurrentSelectedWidget()
    if widget ~= nil then
        uevrUtils.setWidgetLayout(widget, configui.getValue(widgetPrefix .. "widget_scale_2d"), configui.getValue(widgetPrefix .. "widget_alignment_2d"))

    --     if WidgetLayoutLibrary == nil then
    --         WidgetLayoutLibrary = uevrUtils.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary")
    --     end
    --     local desiredSize = widget:GetDesiredSize()
	-- 	local viewportAlignment = widget:GetAlignmentInViewport()
    --     local anchors = widget:GetAnchorsInViewport()

    --     -- local sx = {}
    --     -- local sy = {}
    --     --local viewportSize = uevr.api:get_player_controller(0):GetViewportSize(sx,sy)

    --     local scale = uevrUtils.vector2D(configui.getValue(widgetPrefix .. "widget_scale_2d"))
    --     local alignment = uevrUtils.vector2D(configui.getValue(widgetPrefix .. "widget_alignment_2d"))

    --     local viewportSize = WidgetLayoutLibrary:GetViewportSize(uevrUtils.get_world())
    --     local viewportScale = WidgetLayoutLibrary:GetViewportScale(uevrUtils.get_world())

    --     print("size", desiredSize.X, desiredSize.Y)
	-- 	print("alignment in viewport",viewportAlignment.X, viewportAlignment.Y)
    --     print("scale", scale.X, scale.Y)
    --     print("alignment", alignment.X, alignment.Y)
    --     --print("viewport size", sx.SizeX, sy.SizeY)
    --     print("viewport size", viewportSize.X, viewportSize.Y)
    --     print("viewport scale", viewportScale)
    --     print("anchors min", anchors.Minimum.X, anchors.Minimum.Y)
    --     print("anchors max", anchors.Maximum.X, anchors.Maximum.Y)

    --     --local newSizeX = desiredSize.X * scale.X
    --     --local newSizeY = desiredSize.Y * scale.Y
    --     local newSizeX = viewportSize.X * scale.X / viewportScale
    --     local newSizeY = viewportSize.Y * scale.Y / viewportScale
    --     print("new size", newSizeX, newSizeY)
    --     --local newAlignment = uevrUtils.vector2D(scale.X - 1 , scale.Y - 1)
    --     local newAlignmentX = scale.X - 1
    --     local newAlignmentY = scale.Y - 1
    --     print("new alignment", newAlignmentX, newAlignmentY)
    --    -- widget:SetAlignmentInViewport(uevrUtils.vector2D(newAlignmentX, newAlignmentY))
    --     widget:SetAlignmentInViewport(uevrUtils.vector2D(-alignment.X, -alignment.Y))
    --     widget:SetDesiredSizeInViewport(uevrUtils.vector2D(newSizeX, newSizeY))

    
    end

end

configui.onUpdate(widgetPrefix .. "widget_scale_2d", function(value)
    updateWidgetLayout()
end)

configui.onUpdate(widgetPrefix .. "widget_alignment_2d", function(value)
    updateWidgetLayout()
end)


function M.getViewportWidgetState()
    return uiState
end

-- function M.getActiveViewportWidget()
--     return viewportWidgetState.activeWidget
-- end

function M.disableHeadLockedUI(value)
    if not value ~= isFollowing then
        isFollowing = not value
        updateUI(true)
    end
end

function M.setIsHeadLocked(value)
    configui.setValue("headLockedUI", value, true)
    headLockedUI = value
    if uevrUtils.isGamePaused() then
        M.disableHeadLockedUI(true)
    end
    updateUI(true)
end

function M.setHeadLockedUIPosition(value)
    M.print("Setting UI Position to " .. value.X .. ", " .. value.Y .. ", " .. value.Z)
    configui.setValue("headLockedUIPosition", value, true)
    headLockedUIPosition = value
    updateUI(true)
end
function M.setHeadLockedUISize(value)
    M.print("Setting UI Size to " .. tostring(value))
    configui.setValue("headLockedUISize", value, true)
    headLockedUISize = value
    updateUI(true)
end

function M.setIsInMotionSicknessCausingScene(value)
    isInMotionSicknessCausingScene = value
    if reduceMotionSickness then
        uevrUtils.enableCameraLerp(isInMotionSicknessCausingScene, true, true, true)
    end
end

local function executeIsInMotionSicknessCausingSceneCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_in_motion_sickness_causing_scene", table.unpack({...}))
end

function M.registerIsInMotionSicknessCausingSceneCallback(func)
	uevrUtils.registerUEVRCallback("is_in_motion_sickness_causing_scene", func)
end

function M.registerWidgetChangeCallback(widgetName, func)
    if widgetName ~= nil and widgetName ~= "" and type(widgetName) == "string" then
	    uevrUtils.registerUEVRCallback("widget_change_" .. widgetName, func)
    end
end

local isInMotionSicknessCausingSceneLast = false
uevrUtils.setInterval(500, function()
    updateUIState()
    updateUI()

    local m_isInMotionSicknessCausingScene, priority = executeIsInMotionSicknessCausingSceneCallback()
	if m_isInMotionSicknessCausingScene ~= isInMotionSicknessCausingSceneLast then
		isInMotionSicknessCausingSceneLast = m_isInMotionSicknessCausingScene or false
		M.setIsInMotionSicknessCausingScene(m_isInMotionSicknessCausingScene)
	end
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	isInMotionSicknessCausingSceneLast = false
    uevrUtils.enableCameraLerp(false, true, true, true)

end)

M.loadParameters()

return M