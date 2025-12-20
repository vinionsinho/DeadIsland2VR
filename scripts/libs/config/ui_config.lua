local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local configFileName = "ui_config"
local configTabLabel = "UI Config"
local widgetPrefix = "uevr_ui_"

local headLockedUI = false
local headLockedUISize = 2.0
local headLockedUIPosition = {X=0, Y=0, Z=2.0}
local reduceMotionSickness = false
local parameterNames = {
	"headLockedUI",
	"headLockedUISize",
	"headLockedUIPosition",
	"reduceMotionSickness"
}

local configWidgets = spliceableInlineArray{
	-- {
	-- 	widgetType = "tree_node",
	-- 	id = "uevr_ui",
	-- 	initialOpen = true,
	-- 	label = "UI Configuration"
	-- },
        {
            widgetType = "checkbox",
            id = widgetPrefix .. "headLockedUI",
            label = "Enable Head Locked UI",
            initialValue = headLockedUI
        },
		{
			widgetType = "drag_float3",
			id = widgetPrefix .. "headLockedUIPosition",
			label = "UI Position",
			speed = .01,
			range = {-10, 10},
			initialValue = {headLockedUIPosition.X, headLockedUIPosition.Y, headLockedUIPosition.Z}
		},
		{
			widgetType = "drag_float",
			id = widgetPrefix .. "headLockedUISize",
			label = "UI Size",
			speed = .01,
			range = {-10, 10},
			initialValue = headLockedUISize
		},
        {
            widgetType = "checkbox",
            id = widgetPrefix .. "reduceMotionSickness",
            label = "Reduce Motion Sickness in Cutscenes",
            initialValue = reduceMotionSickness
        },
	-- {
	-- 	widgetType = "tree_pop"
	-- },
}

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	if saveFileName == nil then saveFileName = configFileName end
	configui.createConfigPanel(configTabLabel, saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end


local registeredCallback = nil
local createParamChangeCallbacks = doOnce(function()
	for _, name in ipairs(parameterNames) do
		configui.onCreateOrUpdate(widgetPrefix .. name, function(value)
			if registeredCallback ~= nil then registeredCallback(name, value) end
		end)
	end
end, Once.EVER)

function M.registerParametersChangedCallback(callback)
    registeredCallback = callback
	createParamChangeCallbacks()
end

function M.setValue(parameterName, value, skipCallback)
	configui.setValue(widgetPrefix .. parameterName, value, skipCallback)
end

configui.onCreateOrUpdate(widgetPrefix .. "headLockedUI", function(value)
    configui.setHidden(widgetPrefix .. "headLockedUIPosition", not value)
    configui.setHidden(widgetPrefix .. "headLockedUISize", not value)
end)

return M