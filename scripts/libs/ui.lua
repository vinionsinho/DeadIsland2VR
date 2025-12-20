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

    ui.getConfigurationWidgets(options) - gets configuration UI widgets
        example:
            local widgets = ui.getConfigurationWidgets()

    ui.showConfiguration(saveFileName, options) - shows basic configuration UI
        example:
            ui.showConfiguration("ui_config")

    ui.registerWidgetChangeCallback(widgetName, func) - registers a callback for when specific high level 
        viewport widgets become active/inactive. The widgetName can be found in the UI interface list
        example:
            ui.registerWidgetChangeCallback("WBP_UniversalLockTooltipWidget_C", function(active)
                print("Widget changed:", active)
            end)


]]--

local uevrUtils = require("libs/uevr_utils")
local input = require("libs/input")
local paramModule = require("libs/core/params")

local M = {}

local uiConfigDev = nil
local uiConfig = nil

local headLockedUI = false
local headLockedUISize = 2.0
local headLockedUIPosition = {X=0, Y=0, Z=2.0}

local isFollowing = true
local reduceMotionSickness = false
local isInMotionSicknessCausingScene = false

local currentWidgetViewportState = {}

local uiState = {viewLocked = nil, screen2D = nil, decouplePitch = nil, inputEnabled = nil, handsEnabled = nil}

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

local paramManager = paramModule.new(parametersFileName, parameters, true)

local function saveParameter(key, value, persist)
	paramManager:set(key, value, persist)
	if uiConfigDev ~= nil then
		uiConfigDev.updateParameters(paramManager:getAll())
	end
end

local function getParameter(key)
    return paramManager:get(key)
end


local function updateUI(force)
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

local function setCurrentViewportWidgetsStr(str)
	if uiConfigDev ~= nil then
		uiConfigDev.setCurrentViewportWidgetsStr(str)
	end
end

local function setCurrentGameStateText(str)
	if uiConfigDev ~= nil then
		uiConfigDev.setCurrentGameStateText(str)
	end
end

local function updateUIState()
    local currentViewportWidgetsStr = ""
    local widgetList = getParameter("widgetlist")
    if widgetList ~= nil then
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
                local data = widgetList[id]
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
    setCurrentViewportWidgetsStr(currentViewportWidgetsStr)

    local currentGameStateText = "Current Game State: "
    local isInCutscene = uevrUtils.isInCutscene()
    local isPaused = uevrUtils.isGamePaused()
    local isCharacterHidden = uevrUtils.getValid(pawn,{ "Controller", "Character", "bHidden"}) or false
    currentGameStateText = currentGameStateText .. "Is In Cutscene = " .. tostring(isInCutscene) .. ", Is Paused = " .. tostring(isPaused) .. ", Is Character Hidden = " .. tostring(isCharacterHidden)
    for index, gameStateName in ipairs(gameStates) do
        local isActive = (gameStateName == "cutscene" and isInCutscene) or (gameStateName == "paused" and isPaused) or (gameStateName == "character_hidden" and isCharacterHidden)
        local gameState = getParameter(gameStateName)
        if gameState ~= nil and isActive then
            --print("Updating game state", gameStateName)
            for _, config in ipairs(stateConfigGame) do
                updateStateIfHigherPriority(gameState, config.stateKey, config.valueKey)
            end
        end
    end
    setCurrentGameStateText(currentGameStateText)
end

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
        local gameState = getParameter(gameStateName)
        if gameState ~= nil then
            for _, config in ipairs(stateConfigGame) do
                if gameState[config.valueKey] == 2 or gameState[config.valueKey] == 3 then
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

function M.init(isDeveloperMode, logLevel)
    paramManager:load()

    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
       uiConfigDev = require("libs/config/ui_config_dev")
        uiConfigDev.init(paramManager:getAll())
		uiConfigDev.registerParameterChangedCallback(function(key, value)
			saveParameter(key, value, true)
		end)
    end

    createGameStateMonitor()
end

local createConfigMonitor = doOnce(function()
	if uiConfig ~= nil then
		uiConfig.registerParametersChangedCallback(function(paramName, paramValue)
			if paramName == "headLockedUI" then
				M.setIsHeadLocked(paramValue)
			elseif paramName == "headLockedUIPosition" then
				M.setHeadLockedUIPosition(paramValue)
			elseif paramName == "headLockedUISize" then
				M.setHeadLockedUISize(paramValue)
			elseif paramName == "reduceMotionSickness" then
                if reduceMotionSickness then
                    uevrUtils.enableCameraLerp(paramValue, true, true, true)
                else
                    uevrUtils.enableCameraLerp(paramValue and isInMotionSicknessCausingScene, true, true, true)
                end
				reduceMotionSickness = paramValue
			end
		end)
	end
end, Once.EVER)

function M.getConfigurationWidgets(options)
	if uiConfig == nil then
		uiConfig = require("libs/config/ui_config")
	end
	createConfigMonitor()
    return uiConfig.getConfigurationWidgets(options)
end

function M.showConfiguration(saveFileName, options)
	if uiConfig == nil then
		uiConfig = require("libs/config/ui_config")
	end
	createConfigMonitor()
	uiConfig.showConfiguration(saveFileName, options)
end

function M.disableHeadLockedUI(value)
    if not value ~= isFollowing then
        isFollowing = not value
        updateUI(true)
    end
end

function M.setIsHeadLocked(value)
    if uiConfig ~= nil then uiConfig.setValue("headLockedUI", value, true) end
    headLockedUI = value
    if uevrUtils.isGamePaused() then
        M.disableHeadLockedUI(true)
    end
    updateUI(true)
end

function M.setHeadLockedUIPosition(value)
    M.print("Setting UI Position to " .. value.X .. ", " .. value.Y .. ", " .. value.Z)
    if uiConfig ~= nil then uiConfig.setValue("headLockedUIPosition", value, true) end
    headLockedUIPosition = value
    updateUI(true)
end
function M.setHeadLockedUISize(value)
    M.print("Setting UI Size to " .. tostring(value))
    if uiConfig ~= nil then uiConfig.setValue("headLockedUISize", value, true) end
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

return M