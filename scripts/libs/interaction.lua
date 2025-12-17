--Interaction component and laser pointer inspired by Gwizdek

--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local interaction = require("libs/interaction")
        local isDeveloperMode = true  
        interaction.init(isDeveloperMode)

    Typical usage would be to run this code with developerMode set to true, then use the configuration tab
    to set parameters the way you want them, then set developerMode to false for production use. Be sure
    to ship your code with the data folder as well as the script folder because the data folder will contain
    your parameter settings.
        
    Available functions:
    
    interaction.init(isDeveloperMode, logLevel) - initializes the interaction system with specified mode and log level
        example:
            interaction.init(true, LogLevel.Debug)

    interaction.exists() - returns true if the interaction component exists and is valid
        example:
            if interaction.exists() then
                -- Do something with interaction
            end

    interaction.registerOnHitCallback(func) - registers a callback function that triggers when interaction hits something
        example:
            interaction.registerOnHitCallback(function(rawHitResult)
                print("Hit something at", rawHitResult.Location)
            end)

    interaction.showInteractionLaser(val) - shows/hides the laser pointer
        example:
            interaction.showInteractionLaser(true)  -- Show laser pointer

    interaction.setInteractionSource(val) - sets the source of interaction (e.g., controller, pointer)
        example:
            interaction.setInteractionSource(2)  -- Set to motion controller source

    interaction.setWidgetTraceChannel(val) - sets which trace channel to use for widget interaction
        example:
            interaction.setWidgetTraceChannel(23)  -- Set widget trace channel

    interaction.setPointerIndex(val) - sets the pointer index for widget interaction
        example:
            interaction.setPointerIndex(0)  -- Set pointer index

    interaction.setWidgetInteractionDistance(val) - sets how far widget interaction can reach
        example:
            interaction.setWidgetInteractionDistance(300)  -- Set interaction distance to 300 units

    interaction.setWidgetEnableHitTesting(val) - enables/disables hit testing for widgets
        example:
            interaction.setWidgetEnableHitTesting(true)  -- Enable hit testing

    interaction.setInteractionDepthOffset(val) - sets the depth offset for interaction
        example:
            interaction.setInteractionDepthOffset(10)  -- Set depth offset

    interaction.setInteractionZOffset(val) - sets the Z offset for interaction
        example:
            interaction.setInteractionZOffset(5)  -- Set Z offset

    interaction.setLaserLengthOffset(val) - sets the length offset for the laser pointer
        example:
            interaction.setLaserLengthOffset(20)  -- Set laser length offset

    interaction.setLaserColor(val) - sets the color of the laser pointer (hex format "#RRGGBBAA")
        example:
            interaction.setLaserColor("#FF0000FF")  -- Set laser color to red

    interaction.getConfigurationWidgets(options) - gets configuration UI widgets for basic settings
        example:
            local widgets = interaction.getConfigurationWidgets()
            configui.createPanel({label="Interaction", widgets=widgets})

    interaction.getDeveloperConfigurationWidgets(options) - gets configuration UI widgets including developer options
        example:
            local widgets = interaction.getDeveloperConfigurationWidgets()
            configui.createPanel({label="Interaction Dev", widgets=widgets})

    interaction.showConfiguration(saveFileName, options) - creates and shows basic configuration UI
        example:
            interaction.showConfiguration("interaction_config")

    interaction.showDeveloperConfiguration(saveFileName, options) - creates and shows developer configuration UI
        example:
            interaction.showDeveloperConfiguration("interaction_dev_config")

    interaction.loadConfiguration(fileName) - loads interaction configuration from a file
        example:
            interaction.loadConfiguration("interaction_config")
            
    interaction.setLogLevel(val) - sets the logging level for interaction messages
        example:
            interaction.setLogLevel(LogLevel.Debug)

    interaction.print(text, logLevel) - prints a message with the specified log level
        example:
            interaction.print("Interaction created", LogLevel.Info)

    interaction.create() - manually creates the interaction component
        example:
            interaction.create()

    interaction.setInteractionType(val) - sets the type of interaction (None, Mesh, Widget, MeshAndWidget)
        example:
            interaction.setInteractionType(interaction.InteractionType.Widget)

    interaction.setMeshInteractionDistance(val) - sets how far mesh interaction can reach
        example:
            interaction.setMeshInteractionDistance(8000)  -- Set mesh interaction distance

    interaction.setMeshTraceChannel(val) - sets which trace channel to use for mesh interaction
        example:
            interaction.setMeshTraceChannel(0)  -- Set mesh trace channel

    interaction.setMeshEnableHitTesting(val) - enables/disables hit testing for mesh interaction
        example:
            interaction.setMeshEnableHitTesting(true)  -- Enable mesh hit testing

    interaction.setInteractionLocationOffset(...) - sets the location offset for interaction
        example:
            interaction.setInteractionLocationOffset(0, 0, 10)  -- Set location offset

    interaction.setInteractionRotationOffset(...) - sets the rotation offset for interaction
        example:
            interaction.setInteractionRotationOffset(0, 45, 0)  -- Set rotation offset

    interaction.setInteractionAttachment(val) - sets which hand/controller the interaction is attached to
        example:
            interaction.setInteractionAttachment(Handed.Right)  -- Attach to right hand

    interaction.setAllowMouseUpdate(val) - enables/disables mouse update functionality
        example:
            interaction.setAllowMouseUpdate(true)  -- Allow mouse updates

    interaction.setMouseCursorVisibility(visible) - sets the visibility of the mouse cursor
        example:
            interaction.setMouseCursorVisibility(true)  -- Show mouse cursor

]]--


local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")
-- local ui = require("libs/ui")

local M = {}

M.InteractionType = {
    None = 1,
    Mesh = 2,
    Widget = 3,
    MeshAndWidget = 4
}

local interactionType = M.InteractionType.None
local interactionAttachment = Handed.Right
local showInteractionLaser = true
local allowMouseUpdate = false
local mouseCursorVisible = true
local interactionLocationOffset = uevrUtils.vector(0,0,0)
---@cast interactionLocationOffset -nil
local interactionRotationOffset = uevrUtils.rotator(0,0,0)
local callbacks = {}

local meshTraceChannel = 0
local meshIgnorePawn = 0
local meshInteractionDistance = 8000
local meshEnableHitTesting = true

local widgetTraceChannel = 1
local widgetInteractionDistance = 300
local widgetEnableHitTesting = true
local interactionSource = EWidgetInteractionSource.World
local pointerIndex = 1
local virtualUserIndex = 99

local laserLengthOffset = 0
local interactionDepthOffset = 0
local interactionZOffset = 0
local laserColor = "#0000FFFF"

---@class widgetInteractionComponent
---@field [any] any
local widgetInteractionComponent = nil
local laserComponent = nil
local trackerComponent = nil

local widgetPrefix = "uevr_interaction_"


local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[interaction] " .. text, logLevel)
	end
end

local helpText = "This module allows you to configure the interaction system which provides tools to interact with the game world. You can create a Mesh interactor which will respond to meshes in the environment, or a Widget interactor which will respond to UI elements. Mesh and Widget interactors can be used at the same time. You can also show an optional laser which points where the interactor is aimed. The interactor can be attached to either hand or the head."

local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_interaction",
		initialOpen = true,
		label = "Interaction Configuration"
	},
		{
			widgetType = "combo",
			id = "interactionType",
			label = "Interaction Type",
			selections = {"None", "Mesh", "Widget", "Mesh and Widget"},
			initialValue = interactionType,
		},
        { widgetType = "begin_group", id = "interaction_settings", isHidden = false },
            {
                widgetType = "combo",
                id = "interactionAttachment",
                label = "Attach To",
                selections = {"Left Hand", "Right Hand", "Head"},
                initialValue = interactionAttachment + 1,
            },
			{
				widgetType = "drag_float3",
				id = "interactionLocationOffset",
				label = "Location",
				speed = .1,
				range = {-50, 50},
				initialValue = {interactionLocationOffset.X, interactionLocationOffset.Y, interactionLocationOffset.Z}
			},
			{
				widgetType = "drag_float3",
				id = "interactionRotationOffset",
				label = "Rotation",
				speed = .1,
				range = {-180, 180},
				initialValue = {interactionRotationOffset.Pitch, interactionRotationOffset.Yaw, interactionRotationOffset.Roll}
			},
        { widgetType = "end_group", },
	    { widgetType = "begin_group", id = "mesh_interaction", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Mesh Interaction" }, { widgetType = "begin_rect", },
            {
                widgetType = "slider_int",
                id = "meshInteractionDistance",
                label = "Interaction Distance",
                speed = 1.0,
                range = {1, 10000},
                initialValue = meshInteractionDistance
            },
            {
                widgetType = "checkbox",
                id = "meshEnableHitTesting",
                label = "Enable Hit Testing",
                initialValue = meshEnableHitTesting
            },
            {
                widgetType = "slider_int",
                id = "meshTraceChannel",
                label = "Trace Channel",
                speed = 1.0,
                range = {0, 100},
                initialValue = meshTraceChannel
            },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "meshIgnorePawn",
                label = "Ignore Pawn",
                initialValue = meshIgnorePawn
            },

        { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },	
	    { widgetType = "begin_group", id = "widget_interaction", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Widget Interaction" }, { widgetType = "begin_rect", },
            {
                widgetType = "combo",
                id = "interactionSource",
                label = "Interaction Source",
                selections = {"World", "Mouse", "CenterScreen", "Custom"},
                initialValue = interactionSource + 1,
            },
            {
                widgetType = "slider_int",
                id = "pointerIndex",
                label = "Pointer Index",
                speed = 1.0,
                range = {1, 100},
                initialValue = pointerIndex
            },
            {
                widgetType = "slider_int",
                id = "widgetInteractionDistance",
                label = "Interaction Distance",
                speed = 1.0,
                range = {1, 10000},
                initialValue = widgetInteractionDistance
            },
            {
                widgetType = "checkbox",
                id = "widgetEnableHitTesting",
                label = "Enable Hit Testing",
                initialValue = widgetEnableHitTesting
            },
            {
                widgetType = "slider_int",
                id = "widgetTraceChannel",
                label = "Trace Channel",
                speed = 1.0,
                range = {0, 100},
                initialValue = widgetTraceChannel
            },
            {
                widgetType = "slider_float",
                id = "interactionDepthOffset",
                label = "Interaction Depth Offset",
                speed = 1.0,
                range = {-50, 50},
                initialValue = interactionDepthOffset
            },
            {
                widgetType = "slider_float",
                id = "interactionZOffset",
                label = "Interaction Z Offset",
                speed = 1.0,
                range = {-20, 20},
                initialValue = interactionZOffset
            },
		{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },	
	    { widgetType = "begin_group", id = "interaction_laser", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Laser" }, { widgetType = "begin_rect", },
            {
                widgetType = "checkbox",
                id = "showInteractionLaser",
                label = "Show Laser",
                initialValue = showInteractionLaser
            },
            {
                widgetType = "slider_float",
                id = "laserLengthOffset",
                label = "Laser Length Offset",
                speed = 1.0,
                range = {-200, 200},
                initialValue = laserLengthOffset
            },
		    { widgetType = "new_line" },
            {
                widgetType = "color_picker",
                id = "laserColor",
                label = "Laser Color",
                initialValue = laserColor
            },
		{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
	    { widgetType = "begin_group", id = "interaction_mouse", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Mouse" }, { widgetType = "begin_rect", },
			{ widgetType = "text_colored", id = "mouse_interaction_warning", isHidden = false, wrapped = true, color = "#FF0000FF", label = "This is experimental and rarely works the way it should."},
            {
                widgetType = "checkbox",
                id = "allowMouseUpdate",
                label = "Update Mouse",
                initialValue = allowMouseUpdate
            },
 		{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
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

local function createLaserComponent()
    if laserComponent == nil then
        laserComponent = uevrUtils.create_component_of_class("Class /Script/Engine.CapsuleComponent")
        if laserComponent ~= nil then
            laserComponent:SetCapsuleSize(0.1, 0, true)
            laserComponent:SetVisibility(true, true)
            laserComponent:SetHiddenInGame(false, false)
            laserComponent.bAutoActivate = true
            laserComponent:SetGenerateOverlapEvents(false)
            laserComponent:SetCollisionEnabled(ECollisionEnabled.NoCollision)
            laserComponent:SetRenderInMainPass(true)
            laserComponent.bRenderInDepthPass = true
            laserComponent.ShapeColor = uevrUtils.hexToColor(laserColor)

            laserComponent:SetRenderCustomDepth(true)
            laserComponent:SetCustomDepthStencilValue(100)
            laserComponent:SetCustomDepthStencilWriteMask(ERendererStencilMask.ERSM_255)
            --uevrUtils.set_component_relative_rotation(component, uevrUtils.rotator(0, 0, 90))
        end
    end
    return laserComponent
end

local function destroyLaserComponent()
    if laserComponent ~= nil then
        uevrUtils.destroyComponent(laserComponent, true, true)
        laserComponent = nil
    end
end

local function createWidgetInteractionComponent(useTerminator)
    local component = uevrUtils.create_component_of_class("Class /Script/UMG.WidgetInteractionComponent")
    if component == nil then
        component.VirtualUserIndex = virtualUserIndex
        component.PointerIndex = pointerIndex
        component.TraceChannel = widgetTraceChannel
        component.InteractionDistance = widgetInteractionDistance
        component.InteractionSource = interactionSource
        component.bEnableHitTesting = widgetEnableHitTesting
        component:SetVisibility(false, false)
        component:SetHiddenInGame(true, true)
    end

    if useTerminator then
        trackerComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
        uevrUtils.set_component_relative_transform(trackerComponent, nil, nil, {X=0.003, Y=0.003, Z=0.003})
    end

    widgetInteractionComponent = component
    return component
end

local function destroyWidgetInteractionComponent()
    if widgetInteractionComponent ~= nil then
        uevrUtils.destroyComponent(widgetInteractionComponent, true, true)
        ---@diagnostic disable-next-line: cast-local-type
        widgetInteractionComponent = nil
    end
    if trackerComponent ~= nil then
        uevrUtils.destroyComponent(trackerComponent, true, true)
        trackerComponent = nil
    end
end

-- local function registerCallback(callbackName, callbackFunc)
--     uevrUtils.registerUEVRCallback(callbackName, callbackFunc)
-- 	-- if callbacks[callbackName] == nil then callbacks[callbackName] = {} end
-- 	-- for i, existingFunc in ipairs(callbacks[callbackName]) do
-- 	-- 	if existingFunc == callbackFunc then
-- 	-- 		--print("Function already exists")
-- 	-- 		return
-- 	-- 	end
-- 	-- end
-- 	-- table.insert(callbacks[callbackName], callbackFunc)
-- end

-- local function executeCallbacks(callbackName, ...)
--     return uevrUtils.executeUEVRCallbacks(callbackName, ...)
-- 	-- if callbacks[callbackName] ~= nil then
-- 	-- 	for i, func in ipairs(callbacks[callbackName]) do
-- 	-- 		func(table.unpack({...}))
-- 	-- 	end
-- 	-- end
-- end

function M.exists()
    return widgetInteractionComponent ~= nil
end

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("interaction_config_dev")
    else
        M.loadConfiguration("interaction_config_dev")
    end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Interaction Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Interaction Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end

function M.create()
    createWidgetInteractionComponent(false)
    if showInteractionLaser then
        createLaserComponent()
    end
    controllers.attachComponentToController(interactionAttachment, widgetInteractionComponent)
    uevrUtils.set_component_relative_transform(widgetInteractionComponent, interactionLocationOffset, interactionRotationOffset)
end

function M.registerOnHitCallback(func)
    uevrUtils.registerUEVRCallback("on_interaction_hit", func)
	--registerCallback("on_hit", func)
end

function M.setInteractionSource(val)
    interactionSource = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.InteractionSource = interactionSource
    end
end

function M.setWidgetTraceChannel(val)
    widgetTraceChannel = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.TraceChannel = widgetTraceChannel
    end
end

function M.setPointerIndex(val)
    pointerIndex = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.PointerIndex = pointerIndex
    end
end

function M.setWidgetInteractionDistance(val)
    widgetInteractionDistance = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.InteractionDistance = widgetInteractionDistance
    end
end

function M.setWidgetEnableHitTesting(val)
    widgetEnableHitTesting = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.bEnableHitTesting = widgetEnableHitTesting
    end
end

function M.setInteractionDepthOffset(val)
    interactionDepthOffset = val
end

function M.setInteractionZOffset(val)
    interactionZOffset = val
end

function M.setLaserLengthOffset(val)
    laserLengthOffset = val
end


function M.setLaserColor(val)
    laserColor = uevrUtils.intToHexString(val)
    --print("LaserColor", laserColor)
    if laserComponent ~= nil then
        laserComponent.ShapeColor = uevrUtils.hexToColor(laserColor)
    end
end

function M.showInteractionLaser(val)
    showInteractionLaser = val
    configui.setValue("showInteractionLaser", val, true)
    if showInteractionLaser == false then
        destroyLaserComponent()
    else
        createLaserComponent()
    end
end

function M.setInteractionType(val)
    interactionType = val
    configui.setValue("interactionType", val, true)
    configui.setHidden("mesh_interaction", interactionType == M.InteractionType.Widget or interactionType == M.InteractionType.None)
    configui.setHidden("widget_interaction", interactionType == M.InteractionType.Mesh or interactionType == M.InteractionType.None)
    configui.setHidden("interaction_laser", interactionType == M.InteractionType.None)
    configui.setHidden("interaction_settings", interactionType == M.InteractionType.None)
    configui.setHidden("interaction_mouse", interactionType == M.InteractionType.None)
    
    
    if interactionType == M.InteractionType.None then
        destroyWidgetInteractionComponent()
        destroyLaserComponent()
    end
end

function M.setMeshInteractionDistance(val)
    meshInteractionDistance = val
    configui.setValue("meshInteractionDistance", val, true)
end

function M.setMeshTraceChannel(val)
    meshTraceChannel = val
    configui.setValue("meshTraceChannel", val, true)
end

function M.setMeshIgnorePawn(val)
    meshIgnorePawn = val
    configui.setValue("meshIgnorePawn", val, true)
end

function M.setMeshEnableHitTesting(val)
    meshEnableHitTesting = val
    configui.setValue("meshEnableHitTesting", val, true)
end

function M.setInteractionLocationOffset(...)
	interactionLocationOffset = uevrUtils.vector(table.unpack({...}))
    if interactionLocationOffset ~= nil then
        uevrUtils.set_component_relative_transform(widgetInteractionComponent, interactionLocationOffset, interactionRotationOffset)
    end
end

function M.setInteractionRotationOffset(...)
	interactionRotationOffset = uevrUtils.rotator(table.unpack({...}))
    if interactionRotationOffset ~= nil then
        uevrUtils.set_component_relative_transform(widgetInteractionComponent, interactionLocationOffset, interactionRotationOffset)
    end
end

function M.setInteractionAttachment(val)
    interactionAttachment = val
    configui.setValue("interactionAttachment", val + 1, true)
    destroyWidgetInteractionComponent()
    destroyLaserComponent()
end

function M.setAllowMouseUpdate(val)
    allowMouseUpdate = val
    configui.setValue("allowMouseUpdate", val, true)
end

function M.setMouseCursorVisibility(visible)
    mouseCursorVisible = visible
end


configui.onCreateOrUpdate("allowMouseUpdate", function(value)
	M.setAllowMouseUpdate(value)
end)

configui.onCreateOrUpdate("interactionLocationOffset", function(value)
	M.setInteractionLocationOffset(value)
end)

configui.onCreateOrUpdate("interactionAttachment", function(value)
    M.setInteractionAttachment(value - 1)
end)

configui.onCreateOrUpdate("interactionRotationOffset", function(value)
	M.setInteractionRotationOffset(value)
end)

configui.onCreateOrUpdate("meshEnableHitTesting", function(value)
	M.setMeshEnableHitTesting(value)
end)

configui.onCreateOrUpdate("meshTraceChannel", function(value)
	M.setMeshTraceChannel(value)
end)

configui.onCreateOrUpdate("meshIgnorePawn", function(value)
	M.setMeshIgnorePawn(value)
end)

configui.onCreateOrUpdate("meshInteractionDistance", function(value)
	M.setMeshInteractionDistance(value)
end)

configui.onCreateOrUpdate("showInteractionLaser", function(value)
	M.showInteractionLaser(value)
end)

configui.onCreateOrUpdate("interactionType", function(value)
	M.setInteractionType(value)
end)

configui.onCreateOrUpdate("interactionSource", function(value)
	M.setInteractionSource(value - 1)
end)

configui.onCreateOrUpdate("widgetTraceChannel", function(value)
	M.setWidgetTraceChannel(value)
end)

configui.onCreateOrUpdate("pointerIndex", function(value)
	M.setPointerIndex(value)
end)

configui.onCreateOrUpdate("widgetInteractionDistance", function(value)
	M.setWidgetInteractionDistance(value)
end)

configui.onCreateOrUpdate("widgetEnableHitTesting", function(value)
	M.setWidgetEnableHitTesting(value)
end)

configui.onCreateOrUpdate("interactionDepthOffset", function(value)
	M.setInteractionDepthOffset(value)
end)

configui.onCreateOrUpdate("interactionZOffset", function(value)
	M.setInteractionZOffset(value)
end)

configui.onCreateOrUpdate("laserLengthOffset", function(value)
	M.setLaserLengthOffset(value)
end)

configui.onCreateOrUpdate("laserColor", function(value)
	M.setLaserColor(value)
end)


-- Projects the intersection of a vector (from origin to endpoint) onto a second plane offset toward the viewer
local function projectIntersectionOntoOffsetPlane(origin, endpoint, planePoint, planeNormal, offset)
    offset = offset or 0.1 -- default to 10cm

    -- Vector math utilities
    local function isValidVector(v)
        return v and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
    end

    local function subtract(a, b)
        return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
    end

    local function add(a, b)
        return { X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }
    end

    local function scale(v, s)
        return { X = v.X * s, Y = v.Y * s, Z = v.Z * s }
    end

    local function dot(a, b)
        return a.X * b.X + a.Y * b.Y + a.Z * b.Z
    end

    local function normalize(v)
        local mag = math.sqrt(v.X^2 + v.Y^2 + v.Z^2)
        if mag == 0 then return nil, "Cannot normalize zero-length vector" end
        return { X = v.X / mag, Y = v.Y / mag, Z = v.Z / mag }
    end

    -- Validate inputs
    if not (isValidVector(origin) and isValidVector(endpoint) and isValidVector(planePoint) and isValidVector(planeNormal)) then
        return nil, "Invalid input: all vectors must have .X, .Y, .Z components"
    end

    -- Step 1: Compute direction
    local direction = subtract(endpoint, origin)
    if direction.X == 0 and direction.Y == 0 and direction.Z == 0 then
        return nil, "Origin and endpoint are the same (zero-length vector)"
    end

    -- Step 2: Normalize plane normal
    local n, err = normalize(planeNormal)
    if not n then return nil, err end

    -- Step 3: Compute intersection
    local denom = dot(n, direction)
    if math.abs(denom) < 0.000001 then
        return nil, "Vector is parallel to plane (no intersection)"
    end

    local t = dot(n, subtract(planePoint, origin)) / denom
    local q = add(origin, scale(direction, t))

    -- Step 4: Project onto offset plane
    local qProjected = subtract(q, scale(n, offset))

    return qProjected
end

--local oldMouseCursor = 0
-- local function onHoverChanged(isHovering)
--     -- local playerController = uevr.api:get_player_controller(0)
--     -- if isHovering then
--     --     if playerController ~= nil then
--     --         oldMouseCursor = playerController.CurrentMouseCursor
--     --         playerController.CurrentMouseCursor = 0
--     --     end
--     -- else
--     --     playerController.CurrentMouseCursor = oldMouseCursor
--     -- end
--     if trackerComponent ~= nil then trackerComponent:SetVisibility(isHovering, false) end
--     if laserComponent ~= nil then laserComponent:SetVisibility(isHovering, false) end
-- end

-- local mouseMoveActive = true
-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- local WidgetLayoutLibrary = nil
-- local UIUtils = nil

--local function moveMouseCursor()
--     local activeWidget = ui.getActiveViewportWidget()
--     jiggle = false
--     if mouseMoveActive and activeWidget ~= nil then
--         print("Active widget", activeWidget:get_full_name())

--         if WidgetLayoutLibrary == nil then WidgetLayoutLibrary = uevrUtils.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary") end
--         --if UIUtils == nil then UIUtils = uevrUtils.find_default_instance("Class /Script/AtomicHeart.UIUtils") end
--         --local distance = 1000
--         local forwardVector = controllers.getControllerDirection(Handed.Right) 
--         local worldLocation = controllers.getControllerLocation(Handed.Right) + (forwardVector * 8192.0)

--         --local worldLocation = forwardVector * distance
--         print(worldLocation.X, worldLocation.Y, worldLocation.Z)
--         local playerController = uevr.api:get_player_controller(0)
--         if WidgetLayoutLibrary ~= nil and playerController ~= nil then
--             --UIUtils.SetCursorWidgetVisibility(playerController, true, 1)
--             playerController.bShowMouseCursor = true
--             playerController.bEnableMouseOverEvents = true
--             playerController.bEnableTouchOverEvents = true
--             playerController.bEnableClickEvents = true
            

--             local currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
--             print("Current mouse", currentMousePosition.X, currentMousePosition.Y)
--             local bProjected = WidgetLayoutLibrary:ProjectWorldLocationToWidgetPosition(playerController, worldLocation, g_screenLocation, false)
--             if bProjected and g_screenLocation~= nil then
--                 playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 print("Projected", bProjected, g_screenLocation.X, g_screenLocation.Y)
--             end
--             Statics:ProjectWorldToScreen(playerController, worldLocation, g_screenLocation, false)
--             if g_screenLocation~= nil and g_screenLocation.X ~= 0 and g_screenLocation.Y ~= 0 then
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                  print("Projected 2", g_screenLocation.X, g_screenLocation.Y)
--             end
--             playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
--             if g_screenLocation~= nil then
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 print("Projected 3", g_screenLocation.X, g_screenLocation.Y)
--             end
--             jiggle = true
--             -- local reply = {}
--             -- WidgetBlueprintLibrary:SetMousePosition(reply, g_screenLocation);

--             -- g_screenLocation = UIUtils:ProjectWorldLocationToScreenNormalizedCoords(uevrUtils.get_world(), playerController, worldLocation);
--             -- if g_screenLocation~= nil then
--             --     --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--             --     print("Projected 4", g_screenLocation.X, g_screenLocation.Y)
--             -- end
--         -- local success, response = pcall(function()		
--         --     bProjected = UIUtils:ProjectWorldLocationToLocalCoordsFromCenterOriginWithContainer(uevrUtils.get_world(), activeWidget, playerController, worldLocation, g_screenLocation)
--         --     if bProjected and g_screenLocation~= nil then
--         --         --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--         --         print("Projected 5", bProjected, g_screenLocation.X, g_screenLocation.Y)
--         --     end
-- 		-- end)
-- 		-- if success == false then
-- 		-- 	print("mouse move error " .. response, LogLevel.Error)
-- 		-- end

         
-- --UWidgetBlueprintLibrary
-- 	--static void GetAllWidgetsOfClass(class UObject* WorldContextObject, TArray<class UUserWidget*>* FoundWidgets, TSubclassOf<class UUserWidget> WidgetClass, bool TopLevelOnly);
-- 	--static struct FEventReply SetMousePosition(struct FEventReply& Reply, const struct FVector2D& NewMousePosition);
-- -- // ScriptStruct UMG.EventReply
-- -- // 0x00B8 (0x00B8 - 0x0000)
-- -- struct alignas(0x08) FEventReply final
-- -- {
-- -- public:
-- -- 	uint8                                         Pad_0[0xB8];                                       // 0x0000(0x00B8)(Fixing Struct Size After Last Property [ Dumper-7 ])
-- -- };

--         end
--     end

    -- if mouseMoveActive and widgetInteractionComponent ~= nil then
    --     --local isHovering = widgetInteractionComponent.HoveredWidgetComponent ~= nil
    --     --if isHovering then
    --         local screenLocation = widgetInteractionComponent:Get2DHitLocation()
    --         local playerController = uevr.api:get_player_controller(0)
    --         if playerController ~= nil then
    --             local hitResult = widgetInteractionComponent:GetLastHitResult()
    --             if hitResult ~= nil then
    --                 local bProjected = WidgetLayoutLibrary:ProjectWorldLocationToWidgetPosition(playerController, uevrUtils.vector(hitResult.TraceEnd), screenLocation, false)
    --                 print("Projected", bProjected, screenLocation.X, screenLocation.Y)
    --             end
    --         end
    --         if playerController ~= nil and screenLocation.X ~= 0 and screenLocation.Y ~= 0 then
    --             playerController:SetMouseLocation(screenLocation.X, screenLocation.Y)
    --             --playerController.bShowMouseCursor = true
    --             print("Moving mouse to", screenLocation.X, screenLocation.Y)
    --         end
    --     --end
    -- end
--end

local function lineTrace()
    if uevrUtils.getValid(widgetInteractionComponent) == nil or widgetInteractionComponent.K2_GetComponentLocation == nil then return nil, nil end

    local originPosition = widgetInteractionComponent:K2_GetComponentLocation()
    local originDirection = widgetInteractionComponent:GetForwardVector()
 	local endLocation = originPosition + (originDirection * meshInteractionDistance)
	
    if meshEnableHitTesting == true then
        local ignore_actors = meshIgnorePawn and {pawn} or {}
        local hitResult = uevrUtils.getLineTraceHitResult(originPosition, originDirection, meshTraceChannel, true, ignore_actors, 0, meshInteractionDistance, true)
        if hitResult ~= nil then
            endLocation = {X=hitResult.Location.X, Y=hitResult.Location.Y, Z=hitResult.Location.Z}
            uevrUtils.executeUEVRCallbacks("on_interaction_hit", hitResult)
        end
        -- local world = uevrUtils.get_world()
        -- if world ~= nil then
        --     local hit = kismet_system_library:LineTraceSingle(world, originPosition, endLocation, meshTraceChannel, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
        --     if hit and reusable_hit_result.Distance > 0 then
        --         endLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
        --         uevrUtils.executeUEVRCallbacks("on_interaction_hit", reusable_hit_result)
        --         --executeCallbacks("on_hit", reusable_hit_result)
        --     end
        -- end
    end
	return originPosition, endLocation
end
-- struct FHitResult final
-- {
-- public:
-- 	int32                                         FaceIndex;                                         // 0x0000(0x0004)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	float                                         Time;                                              // 0x0004(0x0004)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	float                                         Distance;                                          // 0x0008(0x0004)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantize                    Location;                                          // 0x000C(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantize                    ImpactPoint;                                       // 0x0018(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantizeNormal              Normal;                                            // 0x0024(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantizeNormal              ImpactNormal;                                      // 0x0030(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantize                    TraceStart;                                        // 0x003C(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	struct FVector_NetQuantize                    TraceEnd;                                          // 0x0048(0x000C)(NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	float                                         PenetrationDepth;                                  // 0x0054(0x0004)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	int32                                         Item;                                              // 0x0058(0x0004)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	uint8                                         ElementIndex;                                      // 0x005C(0x0001)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	uint8                                         bBlockingHit : 1;                                  // 0x005D(0x0001)(BitIndex: 0x00, PropSize: 0x0001 (NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic))
-- 	uint8                                         bStartPenetrating : 1;                             // 0x005D(0x0001)(BitIndex: 0x01, PropSize: 0x0001 (NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic))
-- 	uint8                                         Pad_5E[0x2];                                       // 0x005E(0x0002)(Fixing Size After Last Property [ Dumper-7 ])
-- 	TWeakObjectPtr<class UPhysicalMaterial>       PhysMaterial;                                      // 0x0060(0x0008)(ZeroConstructor, IsPlainOldData, NoDestructor, UObjectWrapper, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	TWeakObjectPtr<class AActor>                  Actor;                                             // 0x0068(0x0008)(ZeroConstructor, IsPlainOldData, NoDestructor, UObjectWrapper, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	TWeakObjectPtr<class UPrimitiveComponent>     Component;                                         // 0x0070(0x0008)(ExportObject, ZeroConstructor, InstancedReference, IsPlainOldData, NoDestructor, UObjectWrapper, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	class FName                                   BoneName;                                          // 0x0078(0x0008)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- 	class FName                                   MyBoneName;                                        // 0x0080(0x0008)(ZeroConstructor, IsPlainOldData, NoDestructor, HasGetValueTypeHash, NativeAccessSpecifierPublic)
-- };
local function updateLaserPointer(origin, target)
    if widgetInteractionComponent ~= nil and uevrUtils.getValid(laserComponent) ~= nil and origin ~= nil and target ~= nil then
        ---@cast laserComponent -nil
        --local screenLocation = widgetInteractionComponent:Get2DHitLocation()
        --print(screenLocation.X,screenLocation.Y)
        --local playerController = uevr.api:get_player_controller(0)
        --playerController:SetMouseLocation(screenLocation.X, screenLocation.Y)

        --local hitDistance = widgetInteractionComponent:GetHoveredWidgetComponent() ~= nil and (widgetInteractionComponent:GetLastHitResult().Distance + laserLengthOffset) or defaultLength
        local hitDistance = kismet_math_library:Vector_Distance(origin, target) + laserLengthOffset
        laserComponent:SetCapsuleHalfHeight(hitDistance / 2, false);
        --laserComponent:K2_SetRelativeLocation( uevrUtils.vector((hitDistance / 2) + laserLocationOffset, 0, 0 ), false, reusable_hit_result, false)
        laserComponent:K2_SetWorldLocation( uevrUtils.vector(origin.X + ((target.X-origin.X)/2), origin.Y + ((target.Y-origin.Y)/2), origin.Z + ((target.Z-origin.Z)/2)), false, reusable_hit_result, false)
        local rotation = kismet_math_library:Conv_VectorToRotator(uevrUtils.vector(target.X-origin.X,target.Y-origin.Y,target.Z-origin.Z))
        rotation.Pitch = rotation.Pitch + 90
        laserComponent:K2_SetWorldRotation(rotation, false, reusable_hit_result, false)
        laserComponent:SetVisibility(true, false)
        -- laserComponent.bHiddenInGame = false
        -- laserComponent.bRenderInMainPass = true
        -- laserComponent.bRenderInDepthPass = true
        -- laserComponent.bVisible = true
        -- print("Visible")
    end
end

local g_screenLocation = uevrUtils.vector_2(0,0)
local function updateMouse(target)
	local playerController = uevr.api:get_player_controller(0)
	if allowMouseUpdate and playerController ~= nil then
		playerController.bShowMouseCursor = mouseCursorVisible
		playerController.bEnableMouseOverEvents = true
		playerController.bEnableTouchOverEvents = true
		playerController.bEnableClickEvents = true
		playerController:ProjectWorldLocationToScreen(target, g_screenLocation, false)
		if g_screenLocation~= nil then
			playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
		end
    end
end

local wasHovering = false
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
    if uevrUtils.getValid(widgetInteractionComponent) == nil then return end

    --if trackerComponent ~= nil then trackerComponent:SetVisibility(false, false) end
    if uevrUtils.getValid(laserComponent) ~= nil then 
        ---@cast laserComponent -nil
        laserComponent:SetVisibility(false, false) 
    end

    if interactionType == M.InteractionType.Mesh then
        local startLocation, endLocation = lineTrace()
        --print(startLocation.X, startLocation.Y, startLocation.Z, endLocation.X, endLocation.Y, endLocation.Z)
        updateLaserPointer(startLocation, endLocation)
        updateMouse(endLocation)
    elseif interactionType == M.InteractionType.Widget or interactionType == M.InteractionType.MeshAndWidget then
		--sometimes an error is thrown "property VirtualUserIndex is not found"t
        pcall(function()
            --if you dont do this repeatedly it doesnt stay set
            widgetInteractionComponent.VirtualUserIndex = virtualUserIndex
            widgetInteractionComponent.PointerIndex = pointerIndex
            widgetInteractionComponent.TraceChannel = widgetTraceChannel
            widgetInteractionComponent.InteractionDistance = widgetInteractionDistance
            widgetInteractionComponent.InteractionSource = interactionSource
            widgetInteractionComponent.bEnableHitTesting = interactionType == (M.InteractionType.Widget or interactionType == M.InteractionType.MeshAndWidget) and widgetEnableHitTesting
		end)

        local isHovering = widgetInteractionComponent.HoveredWidgetComponent ~= nil
        --print("isHovering", isHovering, widgetInteractionComponent.HoveredWidgetComponent)
        if isHovering then
                --playerController.bShowMouseCursor = false
                --widgetInteractionComponent.HoveredWidgetComponent.Widget["NeedClickSound?"] = false
            local hitResult = widgetInteractionComponent:GetLastHitResult()
            if hitResult ~= nil then
                local projected = hitResult.Location
                if interactionDepthOffset ~= 0 then
                    projected = projectIntersectionOntoOffsetPlane(hitResult.TraceStart, hitResult.TraceEnd, hitResult.ImpactPoint, hitResult.ImpactNormal, interactionDepthOffset)
                end
                if projected ~= nil then
                    projected = uevrUtils.vector(projected)
                    if projected ~= nil then
                        projected.Z = projected.Z + interactionZOffset
                        if trackerComponent ~= nil then trackerComponent:K2_SetWorldLocation(uevrUtils.vector(projected), false, reusable_hit_result, false) end
                        updateLaserPointer(uevrUtils.vector(hitResult.TraceStart), projected)
                        updateMouse(projected)
                    end
                    --TODO does this hit result need to be cleaned?
                    uevrUtils.executeUEVRCallbacks("on_interaction_hit", hitResult)
                    --executeCallbacks("on_hit", hitResult)
                end
            end
        elseif interactionType == M.InteractionType.MeshAndWidget then
            local startLocation, endLocation = lineTrace()
            updateLaserPointer(startLocation, endLocation)
            updateMouse(endLocation)
        end
        -- if isHovering ~= wasHovering then
        --     onHoverChanged(isHovering)
        --     wasHovering = isHovering
        -- end
    end
end)


-- local parameters = {
--     controllerToGame = {
--         {
--             standard = 
--             {
--                 {
--                     label = "XINPUT_GAMEPAD_A",
--                     id = "XINPUT_GAMEPAD_A",
--                     state = "up_toggle",
--                     actions = { {action="PressPointerKey", key="LeftMouseButton"}, {action="ReleasePointerKey", key="LeftMouseButton"} }
--                 },
--                 {
--                     label = "Right Trigger",
--                     id = "right_trigger",
--                     state = "down_continuous",
--                     actions = { {action="PressPointerKey", key="RightMouseButton"} }
--                 },
--             }
--         }
--     }
-- }
-- parameters[bindings][nora][mappings]

local keyStruct
local wasButtonPressed = false
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if uevrUtils.getValid(widgetInteractionComponent) == nil then return end
    
    local isButtonPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_A)
	if isButtonPressed and isButtonPressed ~= wasButtonPressed then
		-- if keyStruct == nil then keyStruct = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key") end
		-- keyStruct.KeyName = uevrUtils.fname_from_string("LeftMouseButton")
        -- -- if widgetInteractionComponent.PressPointerKey ~= nil then
		-- --     local result = widgetInteractionComponent:PressAndReleaseKey(keyStruct)
        -- -- end
        -- if widgetInteractionComponent.PressPointerKey ~= nil then
		--     local result = widgetInteractionComponent:PressPointerKey(keyStruct)
        -- end
        -- print("Pressing left")
    elseif (not isButtonPressed) and isButtonPressed ~= wasButtonPressed then
		if keyStruct == nil then keyStruct = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key") end
		keyStruct.KeyName = uevrUtils.fname_from_string("LeftMouseButton")
		--local result = widgetInteractionComponent:PressAndReleaseKey(keyStruct)
        --press and release on button release works for Atomic Heart
        if widgetInteractionComponent.PressPointerKey ~= nil then
		    local result = widgetInteractionComponent:PressPointerKey(keyStruct)
        end
        if widgetInteractionComponent.ReleasePointerKey ~= nil then
		    local result = widgetInteractionComponent:ReleasePointerKey(keyStruct)
        end
        --print("Releasing left")
	end
    wasButtonPressed = isButtonPressed
end)

-- uevrUtils.setInterval(100, function()
--     moveMouseCursor()
-- end)
uevrUtils.registerPreLevelChangeCallback(function(level)
	wasHovering = false
    ---@diagnostic disable-next-line: cast-local-type
    widgetInteractionComponent = nil
    laserComponent = nil
    trackerComponent = nil
end)

uevrUtils.setInterval(1000, function()
	if interactionType ~= M.InteractionType.None and not M.exists() then
		M.create()
	end
end)

uevr.params.sdk.callbacks.on_script_reset(function()
	destroyLaserComponent()
    destroyWidgetInteractionComponent()
end)


-- This will move the mouse on screen but hover and interaction wont work (unless you bump the mouse)
-- local mouseMoveActive = true
-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
-- 	local forwardVector = controllers.getControllerDirection(Handed.Right)
-- 	local location = controllers.getControllerLocation(Handed.Right)
-- 	local worldLocation = location + (forwardVector * 8192.0)
-- 	local playerController = uevr.api:get_player_controller(0)
-- 	if mouseMoveActive and playerController ~= nil then
-- 		playerController.bShowMouseCursor = true
-- 		playerController.bEnableMouseOverEvents = true
-- 		playerController.bEnableTouchOverEvents = true
-- 		playerController.bEnableClickEvents = true
-- 		playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
-- 		if g_screenLocation~= nil then
-- 			playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 			playerController:SetMouseLocation(g_screenLocation.X+1, g_screenLocation.Y+1)
-- 			playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 		end
-- 	end
-- end)

-- register_key_bind("F1", function()
-- 	mouseMoveActive = not mouseMoveActive
--     M.print("Mouse move active: " .. tostring(mouseMoveActive))
-- end)

return M




-- local uevrUtils = require('libs/uevr_utils')
-- local controllers = require('libs/controllers')

-- local mouseMoveActive = false
-- --callback from uevrUtils that fires whenever the level changes
-- function on_level_change(level, levelName)
-- 	print("Level changed to " .. levelName)
-- 	controllers.createController(0)
-- 	controllers.createController(1)
-- 	controllers.createController(2)
-- end

-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- local WidgetLayoutLibrary = nil
-- uevrUtils.setInterval(200, function()
--     if WidgetLayoutLibrary == nil then WidgetLayoutLibrary = uevrUtils.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary") end
-- 	local forwardVector = controllers.getControllerDirection(Handed.Right)
-- 	local location = controllers.getControllerLocation(Handed.Right)
-- 	local worldLocation = location + (forwardVector * 8192.0)
-- 	print("Location", location.X .. ", " .. location.Y .. ", " .. location.Z)
-- 	print("Target", worldLocation.X .. ", " .. worldLocation.Y .. ", " .. worldLocation.Z)
-- 	local playerController = uevr.api:get_player_controller(0)
-- 	local currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
-- 	print("Before mouse", currentMousePosition.X, currentMousePosition.Y)
-- 	--Statics:SetViewportMouseCaptureMode(uevrUtils.get_world(), 1)
-- 	if mouseMoveActive and playerController ~= nil then
-- 		--print(playerController:get_full_name())
-- 		playerController.bShowMouseCursor = true
-- 		playerController.bEnableMouseOverEvents = true
-- 		playerController.bEnableTouchOverEvents = true
-- 		playerController.bEnableClickEvents = true
-- 		playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
-- 		if g_screenLocation~= nil then
-- 			--playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 			local reply = {}
--             WidgetBlueprintLibrary:SetMousePosition(reply, g_screenLocation)
-- 			print(reply)
-- 		end
-- 	end
-- 	currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
-- 	print("After mouse", currentMousePosition.X, currentMousePosition.Y)
-- end)

-- register_key_bind("F1", function()
-- 	mouseMoveActive = not mouseMoveActive
--     print("Mouse move active: " .. tostring(mouseMoveActive))
-- end)
