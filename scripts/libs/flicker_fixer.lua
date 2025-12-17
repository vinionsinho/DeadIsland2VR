--Courtesy of Pande4360 and gwizdek
local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}
--M.msecTimer = 5000
local configDefinition = {
	{
		panelLabel = "Flicker Fixer", 
		saveFile = "config__flicker_fixer", 
		layout = 
		{
			{
				widgetType = "checkbox",
				id = "flicker_fixer_enable",
				label = "Enable",
				initialValue = true
			},
			{
				widgetType = "slider_int",
				id = "flicker_fixer_delay",
				label = "Delay (secs)",
				speed = 1.0,
				range = {2, 30},
				initialValue = 5
			},
			{
				widgetType = "text",
				label = "Only decrease the Delay value if flickering is noticeable.\nWhile lower values for Delay can reduce flickering,\nit can also negatively impact performance."
			},
			{
				widgetType = "slider_float",
				id = "flicker_fixer_duration",
				label = "Duration (secs)",
				speed = 0.05,
				range = {0.4, 1.8},
				initialValue = 1.0
			},
			{
				widgetType = "text",
				label = "Lower values for Duration can increase performance but\nif set too low, can prevent flicker removal."
			},
		}
	}
}
local flickerFixerComponent = nil
local isTriggered = false
local isConfigured = false

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[flickerfixer] " .. text, logLevel)
	end
end

local function createFlickerFixerComponent(fov, rt)
	local component = uevrUtils.create_component_of_class("Class /Script/Engine.SceneCaptureComponent2D", false)
    if component == nil then
        print("Failed to spawn scene capture")
    else
		component.TextureTarget = rt
		component.FOVAngle = fov
		component:SetVisibility(false)
	end
	return component
end

function triggerFlickerFixer()
	if configui.getValue("flicker_fixer_enable") == true and uevrUtils.getUEVRParam_int("VR_RenderingMethod") == 0 and uevrUtils.getUEVRParam_bool("VR_NativeStereoFix") then
		if uevrUtils.validate_object(flickerFixerComponent) ~= nil then
			flickerFixerComponent:SetVisibility(true)
			M.print("Flicker Fixer triggered")
			delay(configui.getValue("flicker_fixer_duration") * 1000, function()
				flickerFixerComponent:SetVisibility(false)
				M.print("Flicker Fixer untriggered")
			end)
		end
	end
	delay(configui.getValue("flicker_fixer_delay") * 1000, triggerFlickerFixer)
end

function M.create()
	if not isConfigured then
		configui.create(configDefinition)
		isConfigured = true
	end

	local world = uevrUtils.get_world()
	local fov = 2.0
	local kismet_rendering_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetRenderingLibrary")
	local rt = kismet_rendering_library:CreateRenderTarget2D(world, 64, 64, 6, zero_color, false)
	if rt ~= nil then
		flickerFixerComponent = createFlickerFixerComponent(fov, rt)
		if flickerFixerComponent ~= nil then
			if not isTriggered then
				triggerFlickerFixer()
				isTriggered = true
			end
		else	
			print("Flicker fixer component could not be created")
		end
	else	
		print("Flicker fixer render target could not be created")
	end
end

return M