--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local reticule = require("libs/reticule")
        local isDeveloperMode = true  
        reticule.init(isDeveloperMode)

    Typical usage would be to run this code with developerMode set to true, then use the configuration tab
    to set parameters the way you want them, then set developerMode to false for production use. Be sure
    to ship your code with the data folder as well as the script folder because the data folder will contain
    your parameter settings.
        
    Available functions:

    reticule.init(isDeveloperMode, logLevel) - initializes the reticule system with specified mode and log level
        example:
            reticule.init(true, LogLevel.Debug)

    reticule.setReticuleType(value) - sets the type of reticule to be created (None, Default, Mesh, Widget, Custom)
		Typically you would enable developer mode and set this value in the UI. You can however, override the
		developer mode setting with this function
        example: 
		reticule.setReticuleType(reticule.ReticuleType.CUSTOM)
		reticule.registerOnCustomCreateCallback(function()
			local AHStatics = uevrUtils.find_default_instance("Class /Script/AtomicHeart.AHGameplayStatics")
			if AHStatics ~= nil then
				local hud = AHStatics:GetPlayerHUD(uevrUtils.getWorld(), 0)
				if hud ~= nil then
					return reticule.ReticuleType.WIDGET, hud.CrosshairWidget,  { removeFromViewport = true, twoSided = true }
				end
			end
			return nil
		end)

    reticule.create() - creates a default sphere mesh-based reticule
        example:
            reticule.create()

    reticule.createFromWidget(widget, options) - creates a reticule from a UMG widget component
		options - removeFromViewport, twoSided, drawSize, scale, rotation, position, collisionChannel, ignoreActors, traceComplex, minHitDistance
        example:
			reticule.setReticuleType(reticule.ReticuleType.NONE) --disable auto creation
			function createReticule()
				local AHStatics = uevrUtils.find_default_instance("Class /Script/AtomicHeart.AHGameplayStatics")
				if AHStatics ~= nil then
					local hud = AHStatics:GetPlayerHUD(uevrUtils.getWorld(), 0)
					if hud ~= nil then
						local widget = hud.CrosshairWidget
						if uevrUtils.getValid(widget) ~= nil then
							local options = { removeFromViewport = true, twoSided = true, collisionChannel = 4, ignoreActors = {someactor} }
							reticule.createFromWidget(widget, options)
						end		
					end
				end
			end
			uevrUtils.setInterval(1000, function()
				if not reticule.exists() then
					createReticule()
				end
			end)

    reticule.createFromMesh(mesh, options) - creates a reticule from a static mesh
		options - materialName, scale, rotation, position, collisionChannel
        example:
			local meshName = "StaticMesh /Engine/BasicShapes/Cube.Cube"
			local options = {
				materialName = "Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial",
				scale = {.03, .03, .03},
				rotation = {Pitch=0,Yaw=0,Roll=0},
			}
			reticule.createFromMesh(meshName, options )				

    reticule.registerOnCustomCreateCallback(callback) - registers a callback function for custom reticule creation
        example:
            reticule.registerOnCustomCreateCallback(function()
                return M.ReticuleType.MESH, "StaticMesh /Game/MyMesh", {scale = {1,1,1}}
            end)

    reticule.exists() - returns true if a reticule component exists and is valid
        example:
            if reticule.exists() then
                -- Do something with reticule
            end

    reticule.getComponent() - gets the current reticule component
        example:
            local component = reticule.getComponent()

    reticule.destroy() - removes the current reticule component
		Be aware that if reticule mode is not set to None, the reticule will be recreated automatically
        example:
            reticule.destroy()

    reticule.setHidden(val) - sets reticule visibility
        example:
            reticule.setHidden(true)  -- Hide reticule

    reticule.update(originLocation, targetLocation, distance, scale, rotation, allowAutoHandle) - updates reticule position and transform
        The reticule will update automatically with default targeting but you can provide custom
		targeting information using this function
		example:
            reticule.update(nil, nil, 200, {1,1,1}, {0,0,0}, true)
			reticule.update(controllers.getControllerLocation(2), lastWandTargetLocation, distanceAdjustment, {reticuleScale,reticuleScale,reticuleScale}) 

    reticule.setDistance(val) - sets the reticule distance from origin
        example:
            reticule.setDistance(200)  -- Set to 200 units

    reticule.setScale(val) - sets the reticule scale multiplier
        example:
            reticule.setScale(1.0)

    reticule.setRotation(val) - sets the reticule rotation offset
        example:
            reticule.setRotation({0, 0, 0})

    reticule.getConfigurationWidgets(options) - gets configuration UI widgets for basic settings
        example:
            local widgets = reticule.getConfigurationWidgets({{id="uevr_reticule_update_distance",initialValue = 800},})

    reticule.showConfiguration(saveFileName, options) - creates and shows basic configuration UI
        example:
            reticule.showConfiguration("reticule_config")
			reticule.showConfiguration(nil, {{id="uevr_reticule_update_distance",initialValue = 800},})

    reticule.setLogLevel(val) - sets the logging level for reticule messages
        example:
            reticule.setLogLevel(LogLevel.Debug)

    reticule.setParametersFileName(fileName) - sets the filename for loading/saving reticule parameters
        example:
            reticule.setParametersFileName("my_reticule_params")

    reticule.reset() - resets the reticule system state, clearing components and widgets
        example:
            reticule.reset()

    reticule.setTargetMethod(value) - sets the targeting method for reticule positioning
        value - one of M.ReticuleTargetMethod constants (CAMERA, LEFT_CONTROLLER, RIGHT_CONTROLLER, LEFT_ATTACHMENT, RIGHT_ATTACHMENT)
        example:
            reticule.setTargetMethod(reticule.ReticuleTargetMethod.LEFT_CONTROLLER)

    reticule.setTargetRotationOffset(value) - sets rotation offset for targeting direction
        value - rotation table with Pitch, Yaw, Roll or array {pitch, yaw, roll}
        example:
            reticule.setTargetRotationOffset({0, 45, 0})  -- 45 degree yaw offset
	
	--The next three functions are typically used internally but can be used externally if needed
    reticule.getOriginPositionFromController() - gets the origin position from the controller
        example:
            local origin = reticule.getOriginPositionFromController()

    reticule.getTargetLocationFromController(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance) - gets the target location from a specific controller
        handed - controller hand (Handed.Left or Handed.Right)
        collisionChannel - optional collision channel for line trace (default: 0)
        ignoreActors - optional table of actors to ignore during line trace (default: empty table)
        traceComplex - optional boolean for complex collision tracing (default: true)
        minHitDistance - optional minimum hit distance threshold (default: 10)
        example:
            local target = reticule.getTargetLocationFromController(Handed.Right)
            local target = reticule.getTargetLocationFromController(Handed.Right, 4, {someActor}, false, 20)

    reticule.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance) - gets the target location from a position and direction
        originPosition - starting position for the trace
        originDirection - direction vector for the trace
        collisionChannel - optional collision channel for line trace (default: 0)
        ignoreActors - optional table of actors to ignore during line trace (default: empty table)
        traceComplex - optional boolean for complex collision tracing (default: false)
        minHitDistance - optional minimum hit distance threshold (default: 100)
        example:
            local target = reticule.getTargetLocation(origin, direction)
            local target = reticule.getTargetLocation(origin, direction, 4, {someActor}, true, 50)

    reticule.getReticuleIDList() - returns array of available reticule configurations
        returns table of {id, label} pairs from loaded parameters
        example:
            local list = reticule.getReticuleIDList()
            for i, item in ipairs(list) do
                print(item.id .. ": " .. item.label)
            end

    reticule.setActiveReticule(id) - if you have used the configuration UI to create reticules,
		this function sets the active reticule by ID. The ids can be found in the 
		reticule parameters file in the data folder, or in the config UI under Show Unique ID, or
		by using the getReticuleIDList() function.
        id - reticule ID string from the parameters file. The id is a unique id of the form
		"4c4ff925-8c10-4224-a7d5-24e45bdee13a" or can be "_default" or "_custom" for the default or custom reticules
        example:
            reticule.setActiveReticule("433c5934-a76e-423a-b2ba-25f97df3b911")

]]--


local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
--local hands = require("libs/hands")

local M = {}

local reticuleConfigDev = nil
local reticuleConfig = nil

local parametersFileName = "reticule_parameters"
local parameters = {}

M.ReticuleType = {
	NONE = 1,
	DEFAULT = 2,
	MESH = 3,
	WIDGET = 4,
	CUSTOM = 5
}
M.ReticuleTargetMethod = {
	CAMERA = 1,
	LEFT_CONTROLLER = 2,
	RIGHT_CONTROLLER = 3,
	LEFT_ATTACHMENT = 4,
	RIGHT_ATTACHMENT = 5,
}


local reticuleTargetMethod = M.ReticuleTargetMethod.CAMERA
local reticuleTargetRotationOffset = uevrUtils.rotator({0,0,0})

local reticuleAutoCreationType = M.ReticuleType.NONE
local autoHandleInput = true -- unless an external call is made to update(), in which case disable auto handling of input

local reticuleComponent = nil
local restoreWidgetPosition = nil

--this should be the options structure
-- local reticuleRotation = nil
-- local reticulePosition = {X = 0.0, Y = 0.0}
-- local reticuleScale = nil
-- local reticuleIgnoreActors = {}
-- local reticuleTraceComplex = false
-- local reticuleCollisionChannel = 0
-- local reticuleMinHitDistance = 10
local currentReticuleOptions = {}

local reticuleCollisionOffset = 10 --distance to offset reticule from hit location to avoid z-fighting (so the reticule isnt embedded in a wall)

--These three are runtime adjustments used by update() and get applied on top of currentReticuleOptions as further user controlled adjustments
local isHidden = false
local reticuleUpdateDistance = 200
local reticuleUpdateScale = 1.0
local reticuleUpdateRotation = {0.0, 0.0, 0.0}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[reticule] " .. text, logLevel)
	end
end

local function getCurrentReticuleParametersProfile()
	if parameters ~= nil and parameters["reticuleList"] ~= nil and parameters["currentReticuleID"] ~= nil then
		local list = parameters["reticuleList"]
		if list ~= nil then
			for i=1, #list do
				if list[i].id == parameters["currentReticuleID"] then
					return list[i]
				end
			end
		end
		--if request is for the default reticule but it was never created in the params file
		if parameters["currentReticuleID"] == "_default" then
			return  {
				type = "Mesh",
				class = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere",
				options = { materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough", scale = {.008, .008, .008},  position_2d = {0.0, 0.0}, scale_2d = {1.0, 1.0}, collisionChannel = 0, ignorePawn = true},
				id = "_default",
				label = "Default",
			}
		end
	end
	return nil
end

local function setReticuleAutoCreationTypeFromParameters()
    reticuleAutoCreationType = M.ReticuleType.NONE
    if parameters["currentReticuleID"] ~= nil then
        if parameters["currentReticuleID"] == "_default" then
            reticuleAutoCreationType = M.ReticuleType.DEFAULT
        elseif parameters["currentReticuleID"] == "_custom" then
            reticuleAutoCreationType = M.ReticuleType.CUSTOM
        else
			local profile = getCurrentReticuleParametersProfile()
			if profile ~= nil then
				if profile["type"] == "Mesh" then
					reticuleAutoCreationType = M.ReticuleType.MESH
				elseif profile["type"] == "Widget" then
					reticuleAutoCreationType = M.ReticuleType.WIDGET
				end
			end
        end
    end
end

local function initOptionsDefaults(options_in, isWidget)
	local options = {}
	if options_in == nil then options_in = {} end
	options.position_2d = uevrUtils.vector2D(options_in.position_2d)
	options.scale_2d = options_in.scale_2d and uevrUtils.vector2D(options_in.scale_2d) or uevrUtils.vector2D({1,1})

	options.rotation = uevrUtils.rotator(options_in.rotation)
	options.position = uevrUtils.vector(options_in.position)
	if isWidget == true then
		if options_in.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
			options.scale = kismet_math_library:Multiply_VectorVector(uevrUtils.vector(options_in.scale), uevrUtils.vector(-1,-1, 1))
		else
			options.scale = uevrUtils.vector(-0.1,-0.1,0.1)
		end
		
		options.removeFromViewport = options_in.removeFromViewport
		options.twoSided = options_in.twoSided
	else
		if options_in.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
			options.scale = uevrUtils.vector(options_in.scale)
		else
			options.scale = uevrUtils.vector(1,1,1)
		end
		options.materialName = options_in.materialName
	end
	options.collisionChannel = options_in.collisionChannel
	options.ignoreActors = options_in.ignoreActors
	options.traceComplex = options_in.traceComplex
	options.minHitDistance = options_in.minHitDistance
	options.ignorePawn = options_in.ignorePawn
	if options.collisionChannel == nil then options.collisionChannel = 0 end
	if options.ignoreActors == nil then options.ignoreActors = {} end
	if options.ignorePawn == true then
		options.ignoreActors[#options.ignoreActors + 1] = pawn
	end
	if options.traceComplex == nil then options.traceComplex = false end
	if options.minHitDistance == nil then options.minHitDistance = 10 end
	return options
end


function M.setParametersFileName(fileName)
    parametersFileName = fileName
end

local createDevConfigMonitor = doOnce(function()
	if reticuleConfigDev ~= nil then
		reticuleConfigDev.registerParametersChangedCallback(function(params, options)
			if params ~= nil then
				parameters = params
				if options ~= nil then
					M.print("Reticule parameters changed via config UI, updating parameters of current reticule")
					currentReticuleOptions = initOptionsDefaults(options, reticuleAutoCreationType == M.ReticuleType.WIDGET)
				else
					M.print("Reticule parameters changed via config UI, creating new reticule")
					M.destroy()
					M.reset()
    				setReticuleAutoCreationTypeFromParameters()
				end
			end
		end)
	end
end, Once.EVER)

local createConfigMonitor = doOnce(function()
	if reticuleConfig ~= nil then
		reticuleConfig.registerParametersChangedCallback(function(paramName, paramValue)
			if paramName == "hide" then
				isHidden = paramValue
			elseif paramName == "update_distance" then
				reticuleUpdateDistance = paramValue
			elseif paramName == "update_scale" then
				reticuleUpdateScale = paramValue
			-- elseif paramName == "update_rotation" then
			--     reticuleUpdateRotation = paramValue
			end
		end)
	end
end, Once.EVER)


function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    M.loadParameters()
    setReticuleAutoCreationTypeFromParameters()

    if isDeveloperMode then
        reticuleConfigDev = require("libs/config/reticule_dev_config")
        reticuleConfigDev.setParametersFileName(parametersFileName)
        reticuleConfigDev.init(isDeveloperMode, logLevel)
		createDevConfigMonitor()
		-- reticuleConfigDev.registerParametersChangedCallback(function(params, options)
		-- 	if params ~= nil then
		-- 		parameters = params
		-- 		if options ~= nil then
		-- 			M.print("Reticule parameters changed via config UI, updating parameters of current reticule")
		-- 			currentReticuleOptions = initOptionsDefaults(options, reticuleAutoCreationType == M.ReticuleType.WIDGET)
		-- 		else
		-- 			M.print("Reticule parameters changed via config UI, creating new reticule")
		-- 			M.destroy()
		-- 			M.reset()
    	-- 			setReticuleAutoCreationTypeFromParameters()
		-- 		end
		-- 	end
		-- end)
    else
    end
end

function M.getConfigurationWidgets(options)
	if reticuleConfig == nil then
		reticuleConfig = require("libs/config/reticule_config")
	end
	createConfigMonitor()
    return reticuleConfig.getConfigurationWidgets(options)
end

function M.showConfiguration(saveFileName, options)
	if reticuleConfig == nil then
		reticuleConfig = require("libs/config/reticule_config")
	end
	createConfigMonitor()
	reticuleConfig.showConfiguration(saveFileName, options)
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading reticule parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json") or {}
end

local function destroyReticuleComponent()
	M.print("destroyReticuleComponent() called")
	if uevrUtils.getValid(reticuleComponent) ~= nil then
        ---@cast reticuleComponent -nil
		if reticuleComponent:is_a(uevrUtils.get_class("Class /Script/UMG.WidgetComponent")) then
			local widget = reticuleComponent:GetWidget()
			if widget ~= nil then
				widget:AddToViewport(0)
				if restoreWidgetPosition ~= nil then
					widget:SetAlignmentInViewport(restoreWidgetPosition)
					restoreWidgetPosition = nil
				end
			end
		end
		uevrUtils.destroyComponent(reticuleComponent, true, true)
	else
		M.print("No valid reticule component to destroy")
	end
	reticuleComponent = nil
end

function M.setHidden(value)
	isHidden = value
	if reticuleConfig ~= nil then reticuleConfig.setValue("hide", value, true) end
end

function M.setDistance(value)
	reticuleUpdateDistance = value
	if reticuleConfig ~= nil then reticuleConfig.setValue("update_distance", value, true) end
end

function M.setScale(value)
	reticuleUpdateScale = value
	if reticuleConfig ~= nil then reticuleConfig.setValue("update_scale", value, true) end
end

function M.setRotation(val)
	reticuleUpdateRotation = val
end

function M.setTargetMethod(value)
	reticuleTargetMethod = value
end

function M.setTargetRotationOffset(value)
	reticuleTargetRotationOffset = value and uevrUtils.rotator(value) or uevrUtils.rotator({0,0,0})
end

function M.reset()
    ---@diagnostic disable-next-line: cast-local-type
	reticuleComponent = nil
	restoreWidgetPosition = nil
end

function M.exists()
	return reticuleComponent ~= nil
end

function M.getComponent()
	return reticuleComponent
end

function M.destroy()
	destroyReticuleComponent()
	M.reset()
end

--------------------------- Reticule Creation ---------------------------
-- widget can be string or object
-- options can be removeFromViewport, twoSided, drawSize, scale, rotation, position, collisionChannel, ignoreActors, traceComplex, minHitDistance
function M.createFromWidget(widget, options)
	M.print("Creating reticule from widget")
	M.destroy()

	if widget ~= nil and widget ~= "" then
		currentReticuleOptions = initOptionsDefaults(options, true)

		reticuleComponent, restoreWidgetPosition = uevrUtils.createWidgetComponent(widget, currentReticuleOptions)
		if uevrUtils.getValid(reticuleComponent) ~= nil then
			---@cast reticuleComponent -nil
			--reticuleComponent:SetDrawAtDesiredSize(true)
			reticuleComponent.BoundsScale = 10 --without this object can disappear when small

			uevrUtils.set_component_relative_transform(reticuleComponent, currentReticuleOptions.position, currentReticuleOptions.rotation, currentReticuleOptions.scale)

			M.print("Created widget reticule " .. reticuleComponent:get_full_name())
		end
	else
		M.print("Widget Reticule component could not be created, widget is invalid")
	end

	return reticuleComponent
end

-- mesh can be string or object
-- options can be materialName, scale, rotation, position, collisionChannel
function M.createFromMesh(mesh, options)
	M.print("Creating reticule from mesh")
	M.destroy()

	if mesh == nil or mesh == "DEFAULT" or mesh == "" then
		if options.scale == nil then options.scale = {.01, .01, .01} end
		mesh = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		if options.materialName == nil or options.materialName == "" then
			options.materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
		end
	end

	currentReticuleOptions = initOptionsDefaults(options, false)

	reticuleComponent = uevrUtils.createStaticMeshComponent(mesh, {tag="uevrlib_reticule"})
	if uevrUtils.getValid(reticuleComponent) ~= nil then
		---@cast reticuleComponent -nil
		if currentReticuleOptions.materialName ~= nil and currentReticuleOptions.materialName ~= "" then
			M.print("Adding material to reticule component")
			local material = uevrUtils.getLoadedAsset(currentReticuleOptions.materialName)
			if uevrUtils.getValid(material) ~= nil then
				reticuleComponent:SetMaterial(0, material)
			else
				M.print("Reticule material was invalid " .. currentReticuleOptions.materialName)
			end
		end

		reticuleComponent.BoundsScale = 10 -- without this object can disappear when small

		uevrUtils.set_component_relative_transform(reticuleComponent, currentReticuleOptions.position, currentReticuleOptions.rotation, currentReticuleOptions.scale)

		M.print("Created mesh reticule " .. reticuleComponent:get_full_name())
	else
		M.print("Mesh Reticule component could not be created")
	end

	return reticuleComponent
end

function M.create()
	return M.createFromMesh()
end

----------------------------------- End Reticule Creation ---------------------------

----------------------------------- Reticule Rendering ---------------------------
function M.getOriginPositionFromController()
	if not controllers.controllerExists(2) then
		controllers.createController(2)
	end
	return controllers.getControllerLocation(2)
end

function M.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance)
	return uevrUtils.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance)
end

function M.getTargetLocationFromController(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance)
	--return controllers.getControllerTargetLocation(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance)
	if not controllers.controllerExists(handed) then
		controllers.createController(handed)
	end

	local rot = controllers.getControllerRotation(handed)
	rot = kismet_math_library:ComposeRotators(reticuleTargetRotationOffset, rot)
	local direction = kismet_math_library:GetForwardVector(rot)

	-- local leftHand = hands.getHandComponent(Handed.Left)
	-- local rightHand = hands.getHandComponent(Handed.Right)
	-- ignoreActors = {leftHand:get_outer(), rightHand:get_outer()}

	if direction ~= nil then
		local startLocation = controllers.getControllerLocation(handed)
		if startLocation ~= nil then
			return uevrUtils.getTargetLocation(startLocation, direction, collisionChannel, ignoreActors, traceComplex, minHitDistance)
		else
			M.print("Error in getTargetLocationFromController. Controller location was nil")
		end
	else
		M.print("Error in getTargetLocationFromController. Controller direction was nil")
	end

end

local function getOffsetWorldPosition(targetPos, targetRot, offsetX, offsetY)
    local result = targetPos
    --local forward = kismet_math_library:GetForwardVector(targetRot)
	if offsetX ~= 0 then
		local right = kismet_math_library:GetRightVector(targetRot)
		result = kismet_math_library:Add_VectorVector(result, kismet_math_library:Multiply_VectorFloat(right, offsetX))
    end

	if offsetY ~= 0 then
		local up = kismet_math_library:GetUpVector(targetRot)
		result = kismet_math_library:Add_VectorVector(result, kismet_math_library:Multiply_VectorFloat(up, offsetY))
	end
    return result
end

function M.update(originLocation, targetLocation, drawDistance, scale, rotation, allowAutoHandle )
	if allowAutoHandle ~= true then
		autoHandleInput = false --if something else is calling this function then dont auto handle input
	end

	if uevrUtils.getValid(reticuleComponent) ~= nil then
		if isHidden then
			reticuleComponent:SetVisibility(false)
			return
		end

		---@cast reticuleComponent -nil
        if reticuleComponent.K2_SetWorldLocationAndRotation == nil then return end --reticule is in an invalid state
		if drawDistance == nil then drawDistance = reticuleUpdateDistance end
		if scale == nil then scale = {reticuleUpdateScale,reticuleUpdateScale,reticuleUpdateScale} end
		if rotation == nil then rotation = reticuleUpdateRotation end
		rotation = uevrUtils.rotator(rotation)

		if originLocation == nil or targetLocation == nil then
			local playerCameraManager = nil
			if reticuleTargetMethod == M.ReticuleTargetMethod.CAMERA then
				local playerController = uevr.api:get_player_controller(0)
				if playerController ~= nil then
					playerCameraManager = playerController.PlayerCameraManager
				end
			end
--TODO add options to target from camera, target from controllers, or target from attachment
-- default to from controllers
			if originLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraLocation ~= nil then
					originLocation = playerCameraManager:GetCameraLocation()
				elseif reticuleTargetMethod == M.ReticuleTargetMethod.LEFT_CONTROLLER or reticuleTargetMethod == M.ReticuleTargetMethod.RIGHT_CONTROLLER then
					originLocation = M.getOriginPositionFromController()
				end
			end

			if targetLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraRotation ~= nil then
					local direction = kismet_math_library:GetForwardVector(playerCameraManager:GetCameraRotation())
					targetLocation = M.getTargetLocation(originLocation, direction, currentReticuleOptions.collisionChannel, currentReticuleOptions.ignoreActors, currentReticuleOptions.traceComplex, currentReticuleOptions.minHitDistance)
				elseif reticuleTargetMethod == M.ReticuleTargetMethod.LEFT_CONTROLLER or reticuleTargetMethod == M.ReticuleTargetMethod.RIGHT_CONTROLLER then
					local handedness = (reticuleTargetMethod == M.ReticuleTargetMethod.LEFT_CONTROLLER and Handed.Left or Handed.Right)
					targetLocation = M.getTargetLocationFromController(handedness, currentReticuleOptions.collisionChannel, currentReticuleOptions.ignoreActors, currentReticuleOptions.traceComplex, currentReticuleOptions.minHitDistance)
				end
			end
		end

		if originLocation ~= nil and targetLocation ~= nil then
			local distanceToTarget = kismet_math_library:Vector_Distance(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			--print(maxDistance)
			local hmdToTargetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			if drawDistance > distanceToTarget - reticuleCollisionOffset then drawDistance = distanceToTarget - reticuleCollisionOffset end --move target distance back slightly so reticule doesnt go through the target
			temp_vec3f:set(hmdToTargetDirection.X,hmdToTargetDirection.Y,hmdToTargetDirection.Z)
			local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
			rot = uevrUtils.sumRotators(rot, currentReticuleOptions.rotation, rotation)

            temp_vec3f:set(originLocation.X + (hmdToTargetDirection.X * drawDistance), originLocation.Y + (hmdToTargetDirection.Y * drawDistance), originLocation.Z + (hmdToTargetDirection.Z * drawDistance))
			local adjustedPosition = getOffsetWorldPosition(temp_vec3f, rot, currentReticuleOptions.position_2d.X, currentReticuleOptions.position_2d.Y)
			reticuleComponent:K2_SetWorldLocationAndRotation(adjustedPosition, rot, false, reusable_hit_result, false)
			if scale ~= nil then
				local finalScale = kismet_math_library:Multiply_VectorVector(kismet_math_library:Multiply_VectorVector(uevrUtils.vector(scale), currentReticuleOptions.scale), uevrUtils.vector(1, currentReticuleOptions.scale_2d.X,  currentReticuleOptions.scale_2d.Y))
				--print(finalScale.X, finalScale.Y, finalScale.Z)
				reticuleComponent:SetWorldScale3D(finalScale)
				--reticuleComponent:SetWorldScale3D(kismet_math_library:Multiply_VectorVector(uevrUtils.vector(scale), uevrUtils.vector(1, currentReticuleOptions.scale_2d.X,  currentReticuleOptions.scale_2d.Y)))
			end
		end
		reticuleComponent:SetVisibility(originLocation ~= nil and targetLocation ~= nil)
	else
		--M.print("Update failed component not valid")
	end
end
----------------------------------- End Reticule Rendering ---------------------------

-- local function autoCreateReticule()
-- 	M.print("Auto creating reticule of type " .. tostring(reticuleAutoCreationType))
-- 	destroyReticuleComponent()
-- 	if reticuleAutoCreationType == M.ReticuleType.Default then
-- 		M.create()
-- 	elseif reticuleAutoCreationType == M.ReticuleType.Widget  then
-- 		if reticuleDefaultWidgetClass ~= nil and reticuleDefaultWidgetClass ~= "" then
-- 			local options = { removeFromViewport = autoReticuleRemoveFromViewport, twoSided = autoReticuleTwoSided, collisionChannel = autoReticuleCollisionChannel, scale = {1, autoReticuleScale[1] and autoReticuleScale[1] or 0.1, autoReticuleScale[2] and autoReticuleScale[2] or 0.1} }
-- 			M.createFromWidget(reticuleDefaultWidgetClass, options)
-- 		else
-- 			M.print("Reticule default widget class is empty, not creating reticule")
-- 		end
-- 	elseif reticuleAutoCreationType == M.ReticuleType.Mesh then
-- 		if reticuleDefaultMeshClass ~= nil and reticuleDefaultMeshClass ~= "" then
-- 			local options = {
-- 				materialName = reticuleDefaultMeshMaterialClass,
-- 				scale = {.03, .03, .03},
-- 				rotation = {Pitch=0,Yaw=0,Roll=0},
-- 	--			collisionChannel = configui.getValue("reticuleCollisionChannel")
-- 			}
-- 			M.createFromMesh(reticuleDefaultMeshClass, options )
-- 		else
-- 			M.print("Reticule default mesh class is empty, not creating reticule")
-- 		end
-- 	end
-- end

local function createReticuleFromProfile()
	local profile = getCurrentReticuleParametersProfile()
	if profile ~= nil then
		local options = profile["options"] or {}
		if profile["type"] == "Mesh" then
			M.createFromMesh(profile["class"], options )
		elseif profile["type"] == "Widget" then
			M.createFromWidget(profile["class"], options)
		else
			M.print("Reticule profile type is invalid: " .. tostring(profile["type"]))
		end
	else
		M.print("No valid reticule profile found for currentReticuleID: " .. tostring(parameters["currentReticuleID"]))
	end
end

local function createCustomReticule()
	local reticuleType, element, options = uevrUtils.executeUEVRCallbacks("on_reticule_create")
	if reticuleType == M.ReticuleType.WIDGET then
		M.createFromWidget(element, options)
	elseif reticuleType == M.ReticuleType.MESH then
		M.createFromMesh(element, options)
	elseif reticuleType == M.ReticuleType.DEFAULT then
		M.create()
	end
end

function M.setReticuleType(value)
	reticuleAutoCreationType = value
	destroyReticuleComponent()
end

--TODO add two more functions, one to get a label/id list of available reticules from parameters and
--one to set a current reticule by id programmatically

function M.getReticuleIDList()
	local list = {}
	if parameters ~= nil and parameters["reticuleList"] ~= nil then
		for i=1, #parameters["reticuleList"] do
			table.insert(list, {id = parameters["reticuleList"][i].id, label = parameters["reticuleList"][i].label})
		end
	end
	return list
end

function M.setActiveReticule(id)
	if parameters ~= nil then
		parameters["currentReticuleID"] = id
		M.destroy()
		M.reset()
		setReticuleAutoCreationTypeFromParameters()
	end
end

function M.registerOnCustomCreateCallback(callback)
	uevrUtils.registerUEVRCallback("on_reticule_create", callback)
end

uevrUtils.setInterval(1000, function()
	if reticuleAutoCreationType ~= M.ReticuleType.NONE and not M.exists() then
		if parameters ~= nil then
			M.setTargetMethod(parameters["reticuleTargetMethod"] or M.ReticuleTargetMethod.CAMERA)
		end
		if reticuleAutoCreationType == M.ReticuleType.CUSTOM then
			createCustomReticule()
		else
			createReticuleFromProfile()
		end
	end
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	M.print("Pre-Level changed in reticule")
	M.reset()
end)

uevrUtils.registerPreEngineTickCallback(function(engine, delta)
	if autoHandleInput == true then
		M.update(nil, nil, nil, nil, nil, true)
	end
end)

uevr.params.sdk.callbacks.on_script_reset(function()
	destroyReticuleComponent()
end)



return M