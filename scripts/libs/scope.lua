local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local configui = require("libs/configui")

local M = {}

local settings = {}
local currentID = ""

local sceneCaptureComponent = nil
local scopeMeshComponent = nil
local currentActiveState = true
local isDisabled = true
local hideOcularLensOnDisable = false
local deactivateDistance = nil

local zoomExponential = 0.5
local zoomSpeed = 1.0
local maxZoom = 1.0
local minZoom = 0.0
local maxFOV = 30.0
local minFOV = 1.0
local currentZoom = 1.0

local brightnessSpeed = 3.0
local maxBrightness = 8.0
local minBrightness = 0.1
local currentBrightness = 1.0


local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[scope] " .. text, logLevel)
	end
end

function saveSettings()
	json.dump_file("uevrlib_scope_settings.json", settings)
	M.print("Scope settings saved")
end

local timeSinceLastSave = 0
local isDirty = false
function checkUpdates(delta)
	timeSinceLastSave = timeSinceLastSave + delta
	--prevent spamming save
	if isDirty == true and timeSinceLastSave > 1.0 then
		saveSettings()
		isDirty = false
		timeSinceLastSave = 0
	end
end

function loadSettings()
	settings = json.load_file("uevrlib_scope_settings.json")
	if settings == nil then settings = {} end
end

M.AdjustMode =
{
    ZOOM = 0,
    BRIGHTNESS = 1,
}

local ETextureRenderTargetFormat = {
    RTF_R8 = 0,
    RTF_RG8 = 1,
    RTF_RGBA8 = 2,
    RTF_RGBA8_SRGB = 3,
    RTF_R16f = 4,
    RTF_RG16f = 5,
    RTF_RGBA16f = 6,
    RTF_R32f = 7,
    RTF_RG32f = 8,
    RTF_RGBA32f = 9,
    RTF_RGB10A2 = 10,
    RTF_MAX = 11,
}

local configDefinition = {
	{
		panelLabel = "Scope Config", 
		saveFile = "uevrlib_config_scope",
		isHidden=true,
		layout = 
		{		
			{
				widgetType = "checkbox",
				id = "uevr_lib_scope_create_demo",
				label = "Create left hand demo",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "uevr_lib_scope_show_debug",
				label = "Show debug meshes",
				initialValue = false
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_fov",
				label = "FOV",
				range = {0.01, 30},
				initialValue = 2
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_brightness",
				label = "Brightness",
				range = {0, 10},
				initialValue = 2
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_ocular_lens_scale",
				label = "Scale",
				range = {0.1, 10},
				initialValue = 1
			},
			{
				widgetType = "drag_float3",
				id = "uevr_lib_scope_objective_lens_rotation",
				label = "Objective Lens Rotation",
				speed = 0.5,
				range = {-90, 90},
				initialValue = {0.0, 0.0, 0.0}
			},
			{
				widgetType = "drag_float3",
				id = "uevr_lib_scope_objective_lens_location",
				label = "Objective Lens Location",
				speed = 0.5,
				range = {-100, 100},
				initialValue = {0.0, 0.0, 0.0}
			},
			{
				widgetType = "drag_float3",
				id = "uevr_lib_scope_ocular_lens_rotation",
				label = "Ocular Lens Rotation",
				speed = 0.5,
				range = {-90, 90},
				initialValue = {0.0, 0.0, 0.0}
			},
			{
				widgetType = "drag_float3",
				id = "uevr_lib_scope_ocular_lens_location",
				label = "Ocular Lens Location",
				speed = 0.05,
				range = {-100, 100},
				initialValue = {0.0, 0.0, 0.0}
			},
			{
				widgetType = "checkbox",
				id = "uevr_lib_scope_disable",
				label = "Disable",
				initialValue = false
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_deactivate_distance",
				label = "Deactivate distance",
				range = {0, 100},
				initialValue = 15
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_zoom_speed",
				label = "Zoom Speed",
				range = {0, 2},
				initialValue = zoomSpeed
			},
			{
				widgetType = "slider_float",
				id = "uevr_lib_scope_zoom_exponential",
				label = "Zoom Exponential",
				range = {0, 1},
				initialValue = zoomExponential
			},
		}	
	}
}

configui.create(configDefinition)
configui.setValue("uevr_lib_scope_create_demo", false)
configui.setValue("uevr_lib_scope_disable", false)

configui.onUpdate("uevr_lib_scope_fov", function(value)
	M.setFOV(value)
end)

configui.onUpdate("uevr_lib_scope_zoom_speed", function(value)
	zoomSpeed = value
end)

configui.onUpdate("uevr_lib_scope_zoom_exponential", function(value)
	zoomExponential = value
end)

configui.onUpdate("uevr_lib_scope_ocular_lens_scale", function(value)
	M.setOcularLensScale(value)
end)

configui.onUpdate("uevr_lib_scope_brightness", function(value)
	M.setBrightness(value)
end)

configui.onUpdate("uevr_lib_scope_objective_lens_rotation", function(value)
	M.setObjectiveLensRelativeRotation(value)
end)

configui.onUpdate("uevr_lib_scope_objective_lens_location", function(value)
	M.setObjectiveLensRelativeLocation(value)
end)

configui.onUpdate("uevr_lib_scope_ocular_lens_rotation", function(value)
	M.setOcularLensRelativeRotation(value)
end)

configui.onUpdate("uevr_lib_scope_ocular_lens_location", function(value)
	M.setOcularLensRelativeLocation(value)
end)

configui.onUpdate("uevr_lib_scope_disable", function(value)
	M.disable(value)
end)

configui.onUpdate("uevr_lib_scope_deactivate_distance", function(value)
	M.setDeactivateDistance(value)
end)

configui.onUpdate("uevr_lib_scope_show_debug", function(value)
	M.destroy()
	if configui.getValue("uevr_lib_scope_create_demo") == true then
		M.create()
		M.attachToLeftHand()
	end
end)

configui.onUpdate("uevr_lib_scope_create_demo", function(value)
	M.destroy()
	if value == true then
		M.create()
		M.attachToLeftHand()
	end
end)

function M.setZoom(zoom)
	local ratio = zoom / maxZoom
	local exponentialRatio = ratio ^ zoomExponential -- where zoomExponential is typically less than 1 for gradual increase, >1 for steeper curve {Link: according to GitHub https://rikunert.github.io/exponential_scaler}
	currentFOV = maxFOV + exponentialRatio * (minFOV - maxFOV)

	M.setFOV(currentFOV)
	if settings[currentID] ~= nil then
		settings[currentID].zoom = zoom
		isDirty = true
	end

end

function M.updateZoom(zoomDirection, delta)
	if zoomDirection ~= 0 then
		currentZoom = currentZoom + (1 * zoomSpeed * zoomDirection * delta)
		currentZoom = math.max(minZoom, math.min(maxZoom, currentZoom))

		M.setZoom(currentZoom)
	end
end

function M.updateBrightness(brightnessDirection, delta)
	if brightnessDirection ~= 0 then
		currentBrightness = currentBrightness + (1 * brightnessSpeed * brightnessDirection * delta)
		currentBrightness = math.max(minBrightness, math.min(maxBrightness, currentBrightness))

		M.setBrightness(currentBrightness)
	end
end


-- -- zoomType - 0 in, 1 out
-- -- zoomSpeed - 1.0 is default
-- function M.zoom(zoomType, zoomSpeed)
	-- if zoomType == nil then zoomType = 0 end
	-- if zoomSpeed == nil then zoomSpeed = 1.0 end
	
	-- ratio = currentZoom / MaxZoom
	-- exponentialRatio = ratio ^ exponent_value -- where exponent_value is typically less than 1 for gradual increase, >1 for steeper curve {Link: according to GitHub https://rikunert.github.io/exponential_scaler}
	-- currentFOV = minFOV + exponentialRatio * (MaxFOV - minFOV)
-- end


-- function M.zoomIn(zoomSpeed)
	-- M.zoom(0, zoomSpeed)
-- end

-- function M.zoomOut(zoomSpeed)
	-- M.zoom(1, zoomSpeed)
-- end

function M.getOcularLensComponent()
	return scopeMeshComponent
end

function M.getObjectiveLensComponent()
	return sceneCaptureComponent
end

function M.destroy()
	uevrUtils.detachAndDestroyComponent(sceneCaptureComponent, true, true)
	uevrUtils.detachAndDestroyComponent(scopeMeshComponent, true, true)
	M.reset()
end

function M.reset()
	sceneCaptureComponent = nil
	scopeMeshComponent = nil
	currentActiveState = true
	isDisabled = true
end

function M.disable(value)
	isDisabled = true
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil and sceneCaptureComponent.SetVisibility ~= nil then
		sceneCaptureComponent:SetVisibility(not value)
		isDisabled = value
	end
	if uevrUtils.getValid(scopeMeshComponent) ~= nil and scopeMeshComponent.SetVisibility ~= nil then
		scopeMeshComponent:SetVisibility(not value or hideOcularLensOnDisable == false)
	end
end

function M.setFOV(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then
		sceneCaptureComponent.FOVAngle = value
		--M.print(sceneCaptureComponent.FOVAngle)
	end
end

function M.setOcularLensScale(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil then 
		uevrUtils.set_component_relative_scale(scopeMeshComponent, {value*0.05,value*0.05,value*0.001})
	end
end

function M.setObjectiveLensRelativeRotation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then 
		uevrUtils.set_component_relative_rotation(sceneCaptureComponent, {value.X-90,value.Y,value.Z})
		--print(value.X-90,value.Y,value.Z)
	end
end

function M.setObjectiveLensRelativeLocation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then 
		uevrUtils.set_component_relative_location(sceneCaptureComponent, {value.X,value.Y,value.Z})
	end
end

function M.setDeactivateDistance(value)
	deactivateDistance = value
end

function M.setOcularLensRelativeRotation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil then 
		uevrUtils.set_component_relative_rotation(scopeMeshComponent, {value.X,value.Y,value.Z})
	end
end

function activeStateChanged(isActive)
	M.disable(not isActive)
end

function M.updateActiveState()
	local isActive = true
	if uevrUtils.getValid(scopeMeshComponent) == nil or uevrUtils.getValid(sceneCaptureComponent) == nil or scopeMeshComponent.K2_GetComponentLocation == nil then
		isActive = false
	elseif deactivateDistance ~= nil then 
		local headLocation = controllers.getControllerLocation(2)
		local ocularLensLocation = scopeMeshComponent:K2_GetComponentLocation()
		if headLocation ~= nil and ocularLensLocation ~= nil then
			local distance = kismet_math_library:Vector_Distance(headLocation, ocularLensLocation)
			isActive = distance < deactivateDistance
			--M.disable(distance > deactivateDistance)
			--scopeMeshComponent:SetVisibility(not (distance > deactivateDistance))
		end
	end
	if isActive ~= currentActiveState then
		activeStateChanged(isActive)
	end
	currentActiveState = isActive
end

function M.isDisplaying()
	return not isDisabled
end

function M.setOcularLensRelativeLocation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil then 
		uevrUtils.set_component_relative_location(scopeMeshComponent, {value.X,value.Y,value.Z})
	end
end

function M.setBrightness(value)
	local scopeMaterial = scopeMeshComponent:GetMaterial(0)
	if scopeMaterial ~= nil then
		local color = uevrUtils.color_from_rgba(value, value, value, value)
		scopeMaterial:SetVectorParameterValue("Color", color)
	end
	if settings[currentID] ~= nil then
		settings[currentID].brightness = value
		isDirty = true
	end
end

EAttachmentRule = {
    KeepRelative = 0,
    KeepWorld = 1,
    SnapToTarget = 2,
    EAttachmentRule_MAX = 3,
}

function M.createOcularLens(renderTarget2D, options)
	if options == nil then options = {} end
	if options.scale == nil then options.scale = configui.getValue("uevr_lib_scope_ocular_lens_scale") end
	if options.brightness == nil then options.brightness = configui.getValue("uevr_lib_scope_brightness") end
	
	currentBrightness = options.brightness
	if settings[currentID] ~= nil and settings[currentID].brightness ~= nil then
		currentBrightness = settings[currentID].brightness
	end

	uevrUtils.getLoadedAsset("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")	
	scopeMeshComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder", {visible=false, collisionEnabled=false} )
	if uevrUtils.getValid(scopeMeshComponent) ~= nil then 
		M.setOcularLensScale(options.scale)

		local templateMaterial = uevrUtils.find_required_object("Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial")
		if templateMaterial ~= nil then
			--templateMaterial.BlendMode = 7
			-- templateMaterial.BlendMode = 0
			-- templateMaterial.TwoSided = 0
			templateMaterial:set_property("BlendMode", 0)
			templateMaterial:set_property("TwoSided", false)

			-- templateMaterial.bDisableDepthTest = true
			-- templateMaterial.MaterialDomain = 0
			-- templateMaterial.ShadingModel = 0
			local scopeMaterial = scopeMeshComponent:CreateDynamicMaterialInstance(0, templateMaterial, "scope_material")
			scopeMaterial:SetTextureParameterValue("LinearColor", renderTarget2D)
			M.setBrightness(currentBrightness)
		end
		M.print("scopeMeshComponent created")
	else
		M.print("Could not create scopeMeshComponent")
	end
end

function M.createObjectiveLens(renderTarget2D, options)
	if options == nil then options = {} end
	if options.fov == nil then options.fov = configui.getValue("uevr_lib_scope_fov") end
	minFOV = options.fov
	currentZoom = 1.0
	if settings[currentID] ~= nil and settings[currentID].zoom ~= nil then
		currentZoom = settings[currentID].zoom
	end
	sceneCaptureComponent = uevrUtils.createSceneCaptureComponent({visible=false, collisionEnabled=false})	
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then
		sceneCaptureComponent.TextureTarget = renderTarget2D
		--M.setFOV(minFOV)
		M.updateZoom(1, 0)
		M.setObjectiveLensRelativeRotation(configui.getValue("uevr_lib_scope_objective_lens_rotation"))
		--uevrUtils.set_component_relative_rotation(sceneCaptureComponent, {Pitch=-90, Yaw=0, Roll=0})
		
		if configui.getValue("uevr_lib_scope_show_debug") == true then
			local originComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder", {visible=true, collisionEnabled=false})
			originComponent:K2_AttachTo(sceneCaptureComponent, uevrUtils.fname_from_string(""), EAttachmentRule.KeepRelative, false)
			uevrUtils.set_component_relative_transform(originComponent, {0.5,0,0},{Pitch=90, Yaw=0, Roll=0},{0.01,0.01,0.01})
		end
		M.print("sceneCaptureComponent created")
	else
		M.print("sceneCaptureComponent not created")
	end
end

-- options example { disabled=true, fov=2.0, brightness=2.0, scale=1.0, deactivateDistance=15, hideOcularLensOnDisable=true}
function M.create(options)
	M.destroy()
	
	if options == nil then options = {} end
	if options.brightness == nil then options.brightness = 1.0 end
	
	currentID = ""
	local id = options.id
	if id ~= nil then
		if settings[id] == nil then
			settings[id] = {}
			settings[id].zoom = 1.0
			settings[id].brightness = options.brightness
		end
		currentID = id
	end
	deactivateDistance = options.deactivateDistance
	hideOcularLensOnDisable = options.hideOcularLensOnDisable == true and true or false
	
	local renderTarget2D = uevrUtils.createRenderTarget2D({width=1024, height=1024, format=ETextureRenderTargetFormat.RTF_RGBA16f})
	M.createOcularLens(renderTarget2D, options)
	M.createObjectiveLens(renderTarget2D, options)
	
	local disabled = options ~= nil and (options.disabled == true) or configui.getValue("uevr_lib_scope_disable")
	M.disable(disabled)

	return M.getOcularLensComponent(), M.getObjectiveLensComponent()
end

function M.attachToLeftHand()
	local headConnected = controllers.attachComponentToController(Handed.Left, M.getObjectiveLensComponent(), nil, nil, nil, true)
	local leftConnected = controllers.attachComponentToController(Handed.Left, M.getOcularLensComponent(), nil, nil, nil, true)
end

uevrUtils.registerPostEngineTickCallback(function(engine, delta)
	M.updateActiveState()
	checkUpdates(delta)
end)

uevrUtils.registerLevelChangeCallback(function(level)
	M.reset()
end)

loadSettings()

return M