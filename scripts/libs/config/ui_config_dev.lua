local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local configFileName = "dev/ui_config_dev"
local configTabLabel = "UI Dev Config"
local widgetPrefix = "uevr_ui_"

local M = {}

local viewportWidgetList = {}
local viewportWidgetIDList = {}
local parameters = {}

local currentViewportWidgetsStr = ""
local currentGameStateText = ""

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

local helpText = "This module allows you to configure how the system behaves when the game state changes or UI overlays such as dialogs and menus are active. You can set whether the view is locked when a widget is active, whether 2D mode is enabled, whether pitch is decoupled, whether input is enabled, and whether hands are shown. Settings are applied based on priority, so if multiple widgets are active, the one with the highest priority for a given setting takes precedence. For example, if one active widget sets 'Screen 2D' to 'Enable' with priority 5, and another active widget sets it to 'Disable' with priority 10, the screen will not be 2D because the second widget has a higher priority."
local function getConfigWidgets()
    return spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = widgetPrefix .. "cutscene",
		initialOpen = true,
		label = "Game State Configuration"
	},
		{ widgetType = "text", id = "currentGameStateText", label = "Current Game State:"},
        {
            widgetType = "combo",
            id = widgetPrefix .. "gameStateList",
            label = "Game State",
            selections = {"In Cutscene", "Game Paused", "Character Hidden"},
            initialValue = 1,
            --width = 150,
        },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = widgetPrefix .. "paused_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", id = widgetPrefix .. "game_state_description", label = "When in Cutscene" }, { widgetType = "begin_rect", },
            { widgetType = "text", label = "State                                       Priority"},
            {
                widgetType = "combo",
                id = widgetPrefix .. "lockedUIWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "lockedUIWhenInGameStatePriority",
                label = " Locked UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "screen2DWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "screen2DWhenInGameStatePriority",
                label = " Screen 2D",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "decouplePitchWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "decouplePitchWhenInGameStatePriority",
                label = " Decoupled Pitch",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "autoAdjustUIWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "autoAdjustUIWhenInGameStatePriority",
                label = " Auto Adjust UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "inputWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "inputWhenInGameStatePriority",
                label = " Input",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "handsWhenInGameState",
                label = "",
                selections = {"No effect", "Show", "Hide"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "handsWhenInGameStatePriority",
                label = " Hands",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "remapWhenInGameState",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "remapWhenInGameStatePriority",
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
		id = widgetPrefix .. "widgets",
		initialOpen = true,
		label = "UI Widget Configuration"
	},
		{
			widgetType = "combo",
			id = widgetPrefix .. "knownViewportWidgetList",
			label = "Config Widget",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
        {
            widgetType = "begin_group",
            id = widgetPrefix .. "knownViewportWidgetSettings",
            isHidden = false
        },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = widgetPrefix .. "viewport_widget_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "When Active" }, { widgetType = "begin_rect", },
            { widgetType = "text", label = "State                                       Priority"},
            {
                widgetType = "combo",
                id = widgetPrefix .. "lockedUIWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "lockedUIWhenActivePriority",
                label = " Locked UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "screen2DWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "screen2DWhenActivePriority",
                label = " Screen 2D",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "decouplePitchWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "decouplePitchWhenActivePriority",
                label = " Decoupled Pitch",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "autoAdjustUIWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "autoAdjustUIWhenActivePriority",
                label = " Auto Adjust UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "inputWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "inputWhenActivePriority",
                label = " Input",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "handsWhenActive",
                label = "",
                selections = {"No effect", "Show", "Hide"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "handsWhenActivePriority",
                label = " Hands",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = widgetPrefix .. "remapWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "remapWhenActivePriority",
                label = " Remap",
                initialValue = "0",
                width = 35,
            },
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
            { widgetType = "unindent", width = 20 },
		    { widgetType = "new_line" },
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = widgetPrefix .. "viewport_widget_settings", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Settings" }, { widgetType = "begin_rect", },
                {
                    widgetType = "drag_float2",
                    id = widgetPrefix .. "widget_scale_2d",
                    label = "Scale 2D",
                    speed = .01,
                    range = {0.01, 2},
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
            id = widgetPrefix .. "currentViewportWidgets",
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
		id = widgetPrefix .. "help_tree",
		initialOpen = true,
		label = "Help"
	},
		{
			widgetType = "text",
			id = widgetPrefix .. "help",
			label = helpText,
			wrapped = true
		},
	{
		widgetType = "tree_pop"
	},
    }
end

local function updateSetting(key, value)
    uevrUtils.executeUEVRCallbacks("on_ui_config_param_change", key, value)
end

local function showViewportWidgetEditFields()
    local index = configui.getValue(widgetPrefix .. "knownViewportWidgetList")
    if index == nil or index == 1 then
        configui.setHidden(widgetPrefix .. "knownViewportWidgetSettings", true)
        return
    end
    configui.setHidden(widgetPrefix .. "knownViewportWidgetSettings", false)

    local id = viewportWidgetIDList[index]
    if id ~= "" and parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
        local data = parameters["widgetlist"][id]
        if data ~= nil then
            -- Initialize and set values for all state configs
            for _, config in ipairs(stateConfigWidget) do
                local valueKey = config.valueKey
                if data[valueKey] == nil then data[valueKey] = 1 end
                configui.setValue(widgetPrefix .. valueKey, data[valueKey], true)

                local priorityKey = valueKey .. "Priority"
                if data[priorityKey] == nil or data[priorityKey] == "" then data[priorityKey] = "0" end
                configui.setValue(widgetPrefix .. priorityKey, data[priorityKey], true)
            end

            configui.setValue(widgetPrefix .. "widget_scale_2d", parameters["widgetlist"][id]["scale"] or {1,1}, true)
            configui.setValue(widgetPrefix .. "widget_alignment_2d", parameters["widgetlist"][id]["alignment"] or {0,0}, true)
        end
    end
end

local function showGameStateEditFields()
    local index = configui.getValue(widgetPrefix .. "gameStateList")
    local state = gameStates[index] or "cutscene"
    configui.setLabel(widgetPrefix .. "game_state_description", "When " .. (state == "cutscene" and "in Cutscene" or ((state == "paused" and "Game is Paused" or "Character is Hidden"))))
    if parameters ~= nil then
        for _, config in ipairs(stateConfigGame) do
            local valueKey = config.valueKey
            local value = 1
            if parameters[state] ~= nil and parameters[state][valueKey] ~= nil then
                value = parameters[state][valueKey]
            end
            configui.setValue(widgetPrefix .. valueKey, value, true)

            local priorityKey = valueKey .. "Priority"
            local priority = "0"
            if parameters[state] ~= nil and parameters[state][priorityKey] ~= nil then
                priority = parameters[state][priorityKey]
            end
            configui.setValue(widgetPrefix .. priorityKey, priority, true)
        end
    end
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
        configui.setSelections(widgetPrefix .. "knownViewportWidgetList", viewportWidgetList)
        configui.setValue(widgetPrefix .. "knownViewportWidgetList", 1)

        showViewportWidgetEditFields()
    end
end

local function registerViewportWidget(widgetClassName, widgetShortName)
   if widgetClassName ~= nil and widgetClassName ~= "" then
        if parameters["widgetlist"] == nil or parameters["widgetlist"][widgetClassName] == nil then
            updateSetting({"widgetlist", widgetClassName, "label"}, widgetShortName)
            updateViewportWidgetList()
        end
    end
end

local function registerViewportWidgets()
	local foundWidgets = {}
	local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
    ---@diagnostic disable-next-line: undefined-field
    WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
	for index, widget in pairs(foundWidgets) do
		--print(widget:get_full_name(), widget:get_class():get_full_name(), widget:IsInViewport())
        registerViewportWidget(widget:get_class():get_full_name(), uevrUtils.getShortName(widget:get_class()))
 	end
end

local function getCurrentSelectedWidgetClass()
    local index = configui.getValue(widgetPrefix .. "knownViewportWidgetList")
    if index ~= nil and index ~= 1 then
        return viewportWidgetIDList[index]
    end
    return ""
end

local function updateCurrentViewportWidgetFields()
    local id = getCurrentSelectedWidgetClass()
    for _, config in ipairs(stateConfigWidget) do
        local valueKey = config.valueKey
        updateSetting({ "widgetlist", id, valueKey }, configui.getValue(widgetPrefix .. valueKey))
        updateSetting({ "widgetlist", id, valueKey .. "Priority" }, configui.getValue(widgetPrefix .. valueKey .. "Priority"))
    end
    updateSetting({ "widgetlist", id, "scale" }, uevrUtils.getNativeValue(configui.getValue(widgetPrefix .. "widget_scale_2d")))
    updateSetting({ "widgetlist", id, "alignment" }, uevrUtils.getNativeValue(configui.getValue(widgetPrefix .. "widget_alignment_2d")))    
end

local function updateGameStateFields()
    local index = configui.getValue(widgetPrefix .. "gameStateList")
    local state = gameStates[index] or "cutscene"
    for _, config in ipairs(stateConfigGame) do
        local valueKey = config.valueKey
        updateSetting({state, valueKey}, configui.getValue(widgetPrefix .. valueKey))
        updateSetting({state, valueKey .. "Priority"}, configui.getValue(widgetPrefix .. valueKey .. "Priority"))
    end

    --createGameStateMonitor()
end

local function getCurrentSelectedWidget()
    local id = getCurrentSelectedWidgetClass()
    if id ~= "" then
        print(id)
        return uevrUtils.find_first_of(id, false)
    end
end

local function updateWidgetLayout()
    updateCurrentViewportWidgetFields()
    local widget = getCurrentSelectedWidget()
    if widget ~= nil then
        uevrUtils.setWidgetLayout(widget, configui.getValue(widgetPrefix .. "widget_scale_2d"), configui.getValue(widgetPrefix .. "widget_alignment_2d"))
    end
end

for _, config in ipairs(stateConfigWidget) do
    local valueKey = config.valueKey
    configui.onUpdate(widgetPrefix .. valueKey, function(value)
        updateCurrentViewportWidgetFields()
    end)
    configui.onUpdate(widgetPrefix .. valueKey .. "Priority", function(value)
        updateCurrentViewportWidgetFields()
    end)
end

for _, config in ipairs(stateConfigGame) do
    local valueKey = config.valueKey
    configui.onUpdate(widgetPrefix .. valueKey, function(value)
        updateGameStateFields()
    end)
    configui.onUpdate(widgetPrefix .. valueKey .. "Priority", function(value)
        updateGameStateFields()
    end)
end

configui.onCreateOrUpdate(widgetPrefix .. "gameStateList", function(value)
	showGameStateEditFields()
end)

configui.onUpdate(widgetPrefix .. "knownViewportWidgetList", function(value)
	showViewportWidgetEditFields()
end)

configui.onUpdate(widgetPrefix .. "widget_scale_2d", function(value)
    updateWidgetLayout()
end)

configui.onUpdate(widgetPrefix .. "widget_alignment_2d", function(value)
    updateWidgetLayout()
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

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(500, function()
        registerViewportWidgets()
        configui.setValue(widgetPrefix .. "currentViewportWidgets", currentViewportWidgetsStr)
        configui.setLabel(widgetPrefix .. "currentGameStateText", currentGameStateText)
    end)
end, Once.EVER)

function M.setCurrentViewportWidgetsStr(str)
	currentViewportWidgetsStr = str
end

function M.setCurrentGameStateText(str)
	currentGameStateText = str
end

function M.updateParameters(inParameters)
    parameters = inParameters
end

function M.init(inParameters)
    M.updateParameters(inParameters)
    M.showConfiguration(configFileName)
    createDevMonitor()
    updateViewportWidgetList()
end

function M.registerParameterChangedCallback(callback)
    uevrUtils.registerUEVRCallback("on_ui_config_param_change", callback)
end

return M