local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local configFileName = "reticule_config"
local configTabLabel = "Reticule Config"
local widgetPrefix = "uevr_reticule_"

local isHidden = false
local reticuleUpdateDistance = 200
local reticuleUpdateScale = 1.0
local reticuleUpdateRotation = {0.0, 0.0, 0.0}

local M = {}

local parameterConfigs = {
	{
		name = "hide",
		label = "Hide Reticule",
		widgetType = "checkbox",
		initialValue = false,
		isHidden = isHidden
	},
	{
		name = "update_distance",
		label = "Distance",
		widgetType = "slider_int",
		speed = 1.0,
		range = {0, 1000},
		initialValue = reticuleUpdateDistance
	},
	{
		name = "update_scale",
		label = "Scale",
		widgetType = "slider_float",
		speed = 0.01,
		range = {0.01, 5.0},
		initialValue = reticuleUpdateScale
	},
	-- {
	-- 	name = "update_rotation",
	-- 	label = "Rotation",
	-- 	widgetType = "drag_float3",
	-- 	speed = 1,
	-- 	range = {0, 360},
	-- 	initialValue = reticuleUpdateRotation
	-- }
}

local configWidgets = spliceableInlineArray{}
for _, config in ipairs(parameterConfigs) do
	local widget = {
		widgetType = config.widgetType,
		id = widgetPrefix .. config.name,
		label = config.label,
		initialValue = config.initialValue
	}
	if config.speed then widget.speed = config.speed end
	if config.range then widget.range = config.range end
	if config.isHidden then widget.isHidden = config.isHidden end
	table.insert(configWidgets, widget)
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	if saveFileName == nil then saveFileName = configFileName end
	configui.createConfigPanel(configTabLabel, saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.registerParametersChangedCallback(callback)
	for _, config in ipairs(parameterConfigs) do
		configui.onCreateOrUpdate(widgetPrefix .. config.name, function(value)
			callback(config.name, value)
		end)
	end
end

function M.setValue(parameterName, value, skipCallback)
	configui.setValue(widgetPrefix .. parameterName, value, skipCallback)
end
return M