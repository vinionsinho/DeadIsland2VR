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
		reticule.setReticuleType(reticule.ReticuleType.Custom)
		reticule.registerOnCustomCreateCallback(function()
			local AHStatics = uevrUtils.find_default_instance("Class /Script/AtomicHeart.AHGameplayStatics")
			if AHStatics ~= nil then
				local hud = AHStatics:GetPlayerHUD(uevrUtils.getWorld(), 0)
				if hud ~= nil then
					return reticule.ReticuleType.Widget, hud.CrosshairWidget,  { removeFromViewport = true, twoSided = true }
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
			reticule.setReticuleType(reticule.ReticuleType.None) --disable auto creation
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
                return M.ReticuleType.Mesh, "StaticMesh /Game/MyMesh", {scale = {1,1,1}}
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

    reticule.hide(val) - sets reticule visibility
        example:
            reticule.hide(true)  -- Hide reticule

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

    reticule.setDefaultWidgetClass(val) - sets the default widget class for widget reticules
        example:
            reticule.setDefaultWidgetClass("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/WBP_Crosshair.WBP_Crosshair_C")

    reticule.setDefaultMeshClass(val) - sets the default mesh class to use for mesh-type reticules
        example:
            reticule.setDefaultMeshClass("StaticMesh /Engine/BasicShapes/Sphere.Sphere")

    reticule.setDefaultMeshMaterialClass(val) - sets the default material class for mesh-type reticules
        example:
            reticule.setDefaultMeshMaterialClass("Material /Engine/EngineMaterials/Widget3DPassThrough")

    reticule.getConfigurationWidgets(options) - gets configuration UI widgets for basic settings
        example:
            local widgets = reticule.getConfigurationWidgets()

    reticule.getDeveloperConfigurationWidgets(options) - gets configuration UI widgets including developer options
        example:
            local widgets = reticule.getDeveloperConfigurationWidgets()

    reticule.showConfiguration(saveFileName, options) - creates and shows basic configuration UI
        example:
            reticule.showConfiguration("reticule_config")

    reticule.showDeveloperConfiguration(saveFileName, options) - creates and shows developer configuration UI
        example:
            reticule.showDeveloperConfiguration("reticule_config_dev")

    reticule.loadConfiguration(fileName) - loads reticule configuration from a file
        example:
            reticule.loadConfiguration("reticule_config")

    reticule.setLogLevel(val) - sets the logging level for reticule messages
        example:
            reticule.setLogLevel(LogLevel.Debug)

    reticule.print(text, logLevel) - prints a message with the specified log level
        example:
            reticule.print("Reticule created", LogLevel.Info)

    reticule.reset() - resets the reticule system state, clearing components and widgets
        example:
            reticule.reset()

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

    reticule.setReticulePosition(pos) - sets the reticule position offset from the target location
        pos - position offset as {X, Y} or vector2D
        example:
            reticule.setReticulePosition({1.5, -2.0})

]]--

local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local configui = require("libs/configui")

local M = {}

M.ReticuleType = {
	None = 1,
	Default = 2,
	Mesh = 3,
	Widget = 4,
	Custom = 5
}

local parametersFileName = "reticule_parameters"
local parameters = {}
local isParametersDirty = false

parameters = {
	reticuleList = {
		{
			label = "WB_ReticleLaser_C",
			id = "WB_ReticleLaser_C",
			type = "Widget",
			class = "WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/WB_ReticleLaser.WB_ReticleLaser_C",
			material = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough",
			options = { removeFromViewport = true, twoSided = true  },
			position = {X = 0.0, Y = 0.0},
		}
	}
}

local reticuleWidgetLabelList = {}
local reticuleWidgetIDList = {}

---@class reticuleComponent
---@field [any] any
local reticuleComponent = nil
local reticuleRotation = nil
local reticulePosition = {X = 0.0, Y = 0.0}
local reticuleScale = nil
local reticuleCollisionChannel = 0
local reticuleIgnoreActors = {}
local reticuleTraceComplex = false
local reticuleMinHitDistance = 10
local restoreWidgetPosition = nil
local reticuleCollisionOffset = 10 --distance to offset reticule from hit location to avoid z-fighting (so the reticule isnt embedded in a wall)

local reticuleUpdateDistance = 200
local reticuleUpdateScale = 1.0
local reticuleUpdateRotation = {0.0, 0.0, 0.0}

local reticuleAutoCreationType = M.ReticuleType.None
local autoHandleInput = true

local possibleReticuleNames = {}
local currentReticuleSelectionIndex = 0
local selectedReticuleWidget = nil
local selectedReticuleWidgetDefaultVisibility = nil
local autoReticuleRemoveFromViewport = true
local autoReticuleTwoSided = true
local autoReticuleCollisionChannel = 0
local autoReticulePosition = {X = 0.0, Y = 0.0}
local autoReticuleScale = {0.1, 0.1}
--local autoReticuleDrawSize = {X = 0.0, Y = 0.0}
local reticuleDefaultWidgetClass = ""
local reticuleDefaultMeshMaterialClass = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
local reticuleDefaultMeshClass = "StaticMesh /Engine/BasicShapes/Plane.Plane"

local systemMeshes = {
	"Custom",
	"StaticMesh /Engine/BasicShapes/Sphere.Sphere",
	"StaticMesh /Engine/BasicShapes/Cube.Cube",
	"StaticMesh /Engine/BasicShapes/Plane.Plane",
	"StaticMesh /Engine/BasicShapes/Cone.Cone",
	"StaticMesh /Engine/BasicShapes/Cylinder.Cylinder",
	"StaticMesh /Engine/BasicShapes/Torus.Torus",
	"StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
}

local systemMaterials = {
	"Custom",
	"Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough",
	"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial",
	"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial",
	"Material /Engine/EngineMaterials/UnlitGeneric.UnlitGeneric",
	"Material /Engine/EngineMaterials/VertexColorMaterial.VertexColorMaterial",
	"Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial"
}


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

local helpText = "This module allows you to configure the reticule system. If you want the reticule to be created automatically, select the type of reticule you want. You can choose a default reticule, a mesh-based reticule, or a widget-based reticule. If you choose Custom, you will need to implement the RegisterOnCustomCreateCallback function in your code and return the type of reticule to create along with any parameters needed for creation. If you do not want the reticule to be created automatically, set the type to None and create the reticule manually in your code using the Create, CreateFromWidget or CreateFromMesh functions."

local configWidgets = spliceableInlineArray{
	{
		widgetType = "slider_int",
		id = "reticuleUpdateDistance",
		label = "Distance",
		speed = 1.0,
		range = {0, 1000},
		initialValue = reticuleUpdateDistance
	},
	{
		widgetType = "slider_float",
		id = "reticuleUpdateScale",
		label = "Scale",
		speed = 0.01,
		range = {0.01, 5.0},
		initialValue = reticuleUpdateScale
	},
	{
		widgetType = "drag_float3",
		id = "reticuleUpdateRotation",
		label = "Rotation",
		speed = 1,
		range = {0, 360},
		initialValue = reticuleUpdateRotation
	}
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_reticle_config",
		initialOpen = true,
		label = "Reticule Automatic Configuration"
	},
		{
			widgetType = "combo",
			id = "uevr_reticule_type",
			selections = {"None", "Default", "Mesh",  "Widget", "Custom"},
			label = "Type",
			initialValue = reticuleAutoCreationType
		},
		{ widgetType = "begin_group", id = "uevr_reticule_widget_group", isHidden = false },
			{ widgetType = "new_line" },
--			{ widgetType = "indent", width = 40 },
			{
				widgetType = "button",
				id = "uevr_reticule_find_add_button",
				label = "Add Using Finder",
				size = {150,22},
				color = "#888888FF",
				hoveredColor = "#888888FF",
				--activeColor = "#0000FFFF",
			},
			{ widgetType = "same_line", },
			{ widgetType = "space_horizontal", space = -8 },
			{
				widgetType = "button",
				id = "uevr_reticule_manual_add_button",
				label = "Add Manually",
				size = {150,22},
			},
--			{ widgetType = "unindent", width = 40 },
--			{ widgetType = "new_line" },
			{ widgetType = "space_vertical", space = 8 },
			{ widgetType = "begin_group", id = "uevr_reticule_add_with_finder", isHidden = false }, { widgetType = "indent", width = 10 }, { widgetType = "begin_rect", },
				{
					widgetType = "tree_node",
					id = "uevr_reticle_widget_finder_tree",
					initialOpen = false,
					label = "Reticule Widget Finder Instructions"
				},
					{
						widgetType = "text",
						id = "uevr_reticule_finder_instructions",
						label = "Perform the search when the game reticule is currently visible on the screen. The finder will automatically search for widgets that contain the words Cursor, Reticule, Reticle or Crosshair in their name. You can also enter text in the Find box to search for other widgets. Press Refresh to see an updated list of widgets. After selecting a widget press Toggle Visibility to see if it is the correct one. If it is, press Use Selected Reticule to set it as the attached reticule.",
						wrapped = true
					},
				{ widgetType = "tree_pop" },
				{
					widgetType = "input_text",
					id = "uevr_reticule_filter",
					label = "Find",
					initialValue = ""
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "button",
					id = "uevr_reticule_refresh_button",
					label = "Refresh",
					size = {80,22}
				},
				{
					widgetType = "combo",
					id = "uevr_reticule_possibilities_list",
					label = "Possible Reticules",
					selections = {"None"},
					initialValue = 1,
				},
				{
					widgetType = "text_colored",
					id = "uevr_reticule_error",
					color = "#FF0000FF",
					isHidden = true,
					label = "Selected item not found. Press Refresh and try again."
				},
				{ widgetType = "indent", width = 60 },
				{
					widgetType = "button",
					id = "uevr_reticule_toggle_visibility_button",
					label = "Toggle Visibility",
					size = {150,22}
				},
				{ widgetType = "same_line", },
				{
					widgetType = "button",
					id = "uevr_reticule_use_button",
					label = "Add Selected Reticule",
					size = {150,22}
				},
				{ widgetType = "unindent", width = 60 },
				{
					widgetType = "input_text",
					id = "uevr_reticule_selected_name",
					label = "Selected Reticule",
					isHidden = true,
					initialValue = ""
				},
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
			{ widgetType = "begin_group", id = "uevr_reticule_add_manually", isHidden = true }, { widgetType = "indent", width = 10 },  { widgetType = "begin_rect", },
				{
					widgetType = "input_text",
					id = "uevr_reticule_manual_add_widget_class",
					label = "Widget Class",
					initialValue = "",
				},		
				{ widgetType = "indent", width = 120 },
				{
					widgetType = "button",
					id = "uevr_reticule_manual_add_widget_class_button",
					label = "Add Reticule",
					size = {150,22}
				},
				{ widgetType = "unindent", width = 120 },
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
			{ widgetType = "new_line" },
			{ widgetType = "new_line" },
			{
				widgetType = "combo",
				id = "uevr_reticule_widget_list",
				label = "Current Reticule",
				selections = {"None"},
				initialValue = 1,
			},
			{ widgetType = "begin_group", id = "uevr_reticule_current_widget_info", isHidden = true }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "Current Reticule Settings" }, { widgetType = "begin_rect", },
				{
					widgetType = "input_text",
					id = "uevr_reticule_widget_class",
					label = "Widget Class",
					initialValue = "",
--					disabled = true
				},
				{
					widgetType = "drag_float2",
					id = "autoReticulePosition",
					label = "Position",
					speed = .1,
					range = {-20, 20},
					initialValue = {autoReticulePosition.X, autoReticulePosition.Y}
				},
				{
					widgetType = "drag_float2",
					id = "autoReticuleScale",
					label = "Scale",
					speed = .001,
					range = {0.001, 10},
					initialValue = {autoReticuleScale[1], autoReticuleScale[2]}
				},
				{
					widgetType = "checkbox",
					id = "autoReticuleRemoveFromViewport",
					label = "Remove From Viewport",
					initialValue = autoReticuleRemoveFromViewport
				},
				{
					widgetType = "checkbox",
					id = "autoReticuleTwoSided",
					label = "Two Sided",
					initialValue = autoReticuleTwoSided
				},
				{
					widgetType = "slider_int",
					id = "autoReticuleCollisionChannel",
					label = "Collision Channel",
					speed = 0.1,
					range = {0, 100},
					initialValue = autoReticuleCollisionChannel
				},
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
			{ widgetType = "new_line" },
		{ widgetType = "end_group", },
		{ widgetType = "begin_group", id = "uevr_reticule_mesh_group", isHidden = false },
--			{ widgetType = "begin_group", id = "uevr_reticule_widget_finder", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Mesh Reticule" }, { widgetType = "begin_rect", },
				{ widgetType = "new_line" },
				{
					widgetType = "combo",
					id = "uevr_reticule_mesh_class_list",
					label = "System Meshes",
					selections = systemMeshes,
					initialValue = 1,
				},
				{
					widgetType = "input_text",
					id = "uevr_reticule_mesh_class",
					label = "Custom Mesh Class",
					initialValue = reticuleDefaultMeshClass
				},
				{
					widgetType = "combo",
					id = "uevr_reticule_mesh_material_class_list",
					label = "System Material",
					selections = systemMaterials,
					initialValue = 1,
				},
				{
					widgetType = "input_text",
					id = "uevr_reticule_mesh_material_class",
					label = "Custom Material Class",
					initialValue = reticuleDefaultMeshMaterialClass
				},
--			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
		{ widgetType = "end_group", },
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

local function destroyReticuleComponent()
	M.print("destroyReticuleComponent() called")
	if uevrUtils.getValid(reticuleComponent) ~= nil then
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
    ---@diagnostic disable-next-line: cast-local-type
	reticuleComponent = nil
end

local function setSelectedReticuleWidgetListItem(id)
	if id == nil or id == "" or id == "None" then
		configui.setValue("uevr_reticule_widget_list", 1)
	else
		for i = 1, #reticuleWidgetIDList do
			if reticuleWidgetIDList[i] == id then
				configui.setValue("uevr_reticule_widget_list", i, true)
				return
			end
		end
	end
end

local function updateSelectedReticleWidget(reticuleWidgetID)
	if reticuleWidgetID == nil or reticuleWidgetID == "" or reticuleWidgetID == "None" then
		configui.hideWidget("uevr_reticule_current_widget_info", true)
		configui.setValue("uevr_reticule_widget_class", "")
	else
		configui.hideWidget("uevr_reticule_current_widget_info", false)
		for i = 1, #reticuleWidgetIDList do
			if reticuleWidgetIDList[i] == reticuleWidgetID then
				if parameters ~= nil and parameters.reticuleList ~= nil then
					for j = 1, #parameters.reticuleList do
						if parameters.reticuleList[j].id == reticuleWidgetID then
							configui.setValue("uevr_reticule_widget_class", parameters.reticuleList[j]["id"])
							configui.setValue("autoReticulePosition", {parameters.reticuleList[j].position.X, parameters.reticuleList[j].position.Y})
							configui.setValue("autoReticuleRemoveFromViewport", parameters.reticuleList[j].options.removeFromViewport)
							configui.setValue("autoReticuleTwoSided", parameters.reticuleList[j].options.twoSided)
							configui.setValue("autoReticuleCollisionChannel", parameters.reticuleList[j].collisionChannel or 0)
							configui.setValue("autoReticuleScale", parameters.reticuleList[j].scale or {0.1, 0.1})

							setSelectedReticuleWidgetListItem(parameters.reticuleList[j]["id"])

							destroyReticuleComponent() --destroy previous reticule if any
							return
						end
					end
				end
			end
		end
	end
end

local function updateReticuleWidgetList()
	reticuleWidgetLabelList = {}
	reticuleWidgetIDList = {}
	if parameters ~= nil and parameters.reticuleList ~= nil then
		for i = 1, #parameters.reticuleList do
			if parameters.reticuleList[i].type == "Widget" then
				table.insert(reticuleWidgetLabelList, parameters.reticuleList[i].label)
				table.insert(reticuleWidgetIDList, parameters.reticuleList[i].id)
			end
		end
	end
	table.insert(reticuleWidgetLabelList, 1, "None")
	table.insert(reticuleWidgetIDList, 1, "None")
	configui.setSelections("uevr_reticule_widget_list", reticuleWidgetLabelList)
end

local function updatePossibileReticuleList()
	local searchText = configui.getValue("uevr_reticule_filter")
	local widgets = uevrUtils.find_all_instances("Class /Script/UMG.Widget", false)
	possibleReticuleNames = {}
	--local activeWidgets = {}

	if widgets ~= nil then
		for name, widget in pairs(widgets) do
			local widgetName = widget:get_full_name()
			if not (widgetName:sub(1, 5) == "Image" or widgetName:sub(1, 7) == "Overlay" or widgetName:sub(1, 11) == "CanvasPanel" or widgetName:sub(1, 13) == "HorizontalBox" or widgetName:sub(1, 8) == "ScaleBox" or widgetName:sub(1, 7) == "SizeBox" or widgetName:sub(1, 11) == "VerticalBox" or widgetName:sub(1, 6) == "Border" or widgetName:sub(1, 9) == "TextBlock" or widgetName:sub(1, 6) == "Spacer") then
				if string.find(widgetName, "Cursor") or string.find(widgetName, "Reticule") or string.find(widgetName, "Reticle") or string.find(widgetName, "Crosshair") or (searchText ~= nil and searchText ~= "" and string.find(widgetName, searchText)) then
					if configui.getValue("uevr_dev_reticule_active") == true then
						local isActive = false
						if uevrUtils.getValid(pawn) ~= nil and widget.GetOwningPlayerPawn ~= nil then
							isActive = widget:GetOwningPlayerPawn() == pawn
							if isActive then
								--table.insert(activeWidgets, widget)
								table.insert(possibleReticuleNames, widgetName)
							end
						end
						--print(widget:get_full_name(), isActive and "true" or "false")
					else
						table.insert(possibleReticuleNames, widgetName)
					end
				end
			end
		end
	end

	--configui.setLabel("uevr_dev_reticule_total_count", "Reticule count:" .. #reticuleNames)
	table.insert(possibleReticuleNames, 1, "Custom")
	configui.setSelections("uevr_reticule_possibilities_list", possibleReticuleNames)
end

local function updateMeshLists()
	configui.setSelections("uevr_reticule_mesh_class_list", systemMeshes)
	configui.setSelections("uevr_reticule_mesh_material_class_list", systemMaterials)
	local index = 1
	for i = 1, #systemMeshes do
		if systemMeshes[i] == reticuleDefaultMeshClass then
			index = i
			break
		end
	end
	configui.setValue("uevr_reticule_mesh_class_list", index)
	local matIndex = 1
	for i = 1, #systemMaterials do
		if systemMaterials[i] == reticuleDefaultMeshMaterialClass then
			matIndex = i
			break
		end
	end
	configui.setValue("uevr_reticule_mesh_material_class_list", matIndex)
end

local function resetSelectedWidget()
	if selectedReticuleWidget ~= nil and uevrUtils.getValid(selectedReticuleWidget) ~= nil then
		--reset previous widget visibility
		if selectedReticuleWidgetDefaultVisibility ~= nil then
			selectedReticuleWidget:SetVisibility(selectedReticuleWidgetDefaultVisibility)
		end
		selectedReticuleWidget = nil
		selectedReticuleWidgetDefaultVisibility = nil
	end
end

local function getSelectedPossibleReticuleWidget()
	if possibleReticuleNames ~= nil and currentReticuleSelectionIndex <= #possibleReticuleNames and currentReticuleSelectionIndex > 1 then
		--local widget = uevrUtils.getLoadedAsset(reticuleNames[currentReticuleSelectionIndex])	
		return uevrUtils.find_instance_of("Class /Script/UMG.Widget", possibleReticuleNames[currentReticuleSelectionIndex])
	end
	return nil
end

local function updateSelectedPossibleReticule()
	resetSelectedWidget()
	if currentReticuleSelectionIndex == 1 then
		--custom widget do callback
		configui.setValue("uevr_reticule_selected_name", "")
	else
		--local widget = uevrUtils.getLoadedAsset(reticuleNames[currentReticuleSelectionIndex])	
		local widget = getSelectedPossibleReticuleWidget()
		if widget == nil then
			configui.hideWidget("uevr_reticule_error" ,false)
			delay(3000, function()
				configui.hideWidget("uevr_reticule_error" ,true)
			end)
		else
			selectedReticuleWidget = widget
			selectedReticuleWidgetDefaultVisibility = widget:GetVisibility()
			--print("Widget is",widget)
			configui.setValue("uevr_reticule_selected_name", widget:get_full_name())
			-- print(reticuleNames[currentReticuleSelectionIndex])
			-- print(widget:get_full_name())
			-- print("Has function", widget.HandleShowTargetReticule ~= nil)

			-- currentComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=false, twoSided=true})--, drawSize=vector_2(620, 620)})
			-- if uevrUtils.getValid(currentComponent) ~= nil then
			-- 	--setCurrentComponentScale(1.0)
			-- 	uevrUtils.set_component_relative_transform(currentComponent, {X=0.0, Y=0.0, Z=0.0}, {Pitch=0,Yaw=0 ,Roll=0}, {X=-0.1, Y=-0.1, Z=0.1})
			-- 	local leftConnected = controllers.attachComponentToController(Handed.Left, currentComponent, nil, nil, nil, true)
			-- 	M.print("Added reticule to controller " .. (leftConnected and "true" or "false"))
			-- end
		end
	end
end

local function toggleSelectedPossibleReticuleVisibility()
	local widget = getSelectedPossibleReticuleWidget()
	if uevrUtils.getValid(widget) ~= nil then
		---@cast widget -nil
		local vis = widget:GetVisibility()
		--print("Current visibility is " .. tostring(vis))
		if vis == 0 or vis == 4 or vis == 3 then
			vis = 1
		else
			vis = 0
		end
		widget:SetVisibility(vis)
		--print("Post visibility is " .. tostring(vis))
	else
		M.print("Selected widget is not valid in toggleSelectedReticuleVisibility")
	end
end

local function autoCreateReticule()
	M.print("Auto creating reticule of type " .. tostring(reticuleAutoCreationType))
	destroyReticuleComponent()
	if reticuleAutoCreationType == M.ReticuleType.Default then
		M.create()
	elseif reticuleAutoCreationType == M.ReticuleType.Widget  then
		if reticuleDefaultWidgetClass ~= nil and reticuleDefaultWidgetClass ~= "" then
			local options = { removeFromViewport = autoReticuleRemoveFromViewport, twoSided = autoReticuleTwoSided, collisionChannel = autoReticuleCollisionChannel, scale = {1, autoReticuleScale[1] and autoReticuleScale[1] or 0.1, autoReticuleScale[2] and autoReticuleScale[2] or 0.1} }
			M.createFromWidget(reticuleDefaultWidgetClass, options)
		else
			M.print("Reticule default widget class is empty, not creating reticule")
		end
	elseif reticuleAutoCreationType == M.ReticuleType.Mesh then
		if reticuleDefaultMeshClass ~= nil and reticuleDefaultMeshClass ~= "" then
			local options = {
				materialName = reticuleDefaultMeshMaterialClass,
				scale = {.03, .03, .03},
				rotation = {Pitch=0,Yaw=0,Roll=0},
	--			collisionChannel = configui.getValue("reticuleCollisionChannel")
			}
			M.createFromMesh(reticuleDefaultMeshClass, options )
		else
			M.print("Reticule default mesh class is empty, not creating reticule")
		end
	end
end

configui.onUpdate("uevr_reticule_toggle_visibility_button", function()
	toggleSelectedPossibleReticuleVisibility()
end)

--WidgetBlueprintGeneratedClass /Game/HNMain/UI/Widgets/WBP_Cursor.WBP_Cursor_C
configui.onUpdate("uevr_reticule_use_button", function()
	local widget = getSelectedPossibleReticuleWidget()
	local widgetClassName = ""
	---@cast widget -nil
	if uevrUtils.getValid(widget) ~= nil and widget:get_class() ~= nil then
		widgetClassName = widget:get_class():get_full_name()
	end
	M.addReticuleByClassName(widgetClassName)
	--M.setDefaultWidgetClass(widgetClassName)
end)

configui.onUpdate("uevr_reticule_possibilities_list", function(value)
	if value ~= nil and possibleReticuleNames ~= nil and possibleReticuleNames[value] ~= nil then
		M.print("Using reticule at index " .. value .. " - " .. possibleReticuleNames[value])
	end
	currentReticuleSelectionIndex = value
	updateSelectedPossibleReticule()
end)

configui.onUpdate("uevr_reticule_mesh_class_list", function(value)
	if value ~= nil and systemMeshes ~= nil and systemMeshes[value] ~= nil then
		M.print("Selecting systemMeshes index " .. value .. " - " .. systemMeshes[value])
		if value == 1 then
			configui.setValue("uevr_reticule_mesh_class", "")
		else
			configui.setValue("uevr_reticule_mesh_class", systemMeshes[value])
		end
		configui.setHidden("uevr_reticule_mesh_class", value ~= 1)
	end
end)

configui.onUpdate("uevr_reticule_mesh_material_class_list", function(value)
	if value ~= nil and systemMaterials ~= nil and systemMaterials[value] ~= nil then
		M.print("Selecting systemMaterials index " .. value .. " - " .. systemMaterials[value])
		if value == 1 then
			configui.setValue("uevr_reticule_mesh_material_class", "")
		else
			configui.setValue("uevr_reticule_mesh_material_class", systemMaterials[value])
		end
		configui.setHidden("uevr_reticule_mesh_material_class", value ~= 1)
	end
end)

function M.setDistance(val)
	reticuleUpdateDistance = val
	configui.setValue("reticuleUpdateDistance", val, true)
end

function M.setScale(val)
	reticuleUpdateScale = val
	configui.setValue("reticuleUpdateScale", val, true)
end

function M.setRotation(val)
	reticuleUpdateRotation = val
	configui.setValue("reticuleUpdateRotation", val, true)
end

local function saveParameters()
	M.print("Saving reticule parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)

	uevrUtils.registerLevelChangeCallback(function(level)
		print("Level changed, updating reticule list")
		updatePossibileReticuleList()
	end)
end, Once.EVER)

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("reticule_config_dev")
        createDevMonitor()
        updatePossibileReticuleList()
        updateMeshLists()
    else
        M.loadConfiguration("reticule_config_dev")
    end
	updateReticuleWidgetList()
	updateSelectedReticleWidget(reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")])
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading reticule parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating reticule parameters")
	end

end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Reticule Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Reticule Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.setReticuleType(value)
	reticuleAutoCreationType = value
	configui.setHidden("uevr_reticule_widget_group", value ~= M.ReticuleType.Widget)
	configui.setHidden("uevr_reticule_mesh_group", value ~= M.ReticuleType.Mesh)
	configui.setValue("uevr_reticule_type", value, true)
	destroyReticuleComponent()
	--uevr_reticule_group
	--M.ReticuleConfigType
end

function M.setSelectedReticulePosition(pos)
	if pos ~= nil then
		local reticulePos = uevrUtils.vector2D(pos)
		if reticulePos ~= nil then
			local reticuleWidgetID = reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")]
			if reticuleWidgetID ~= nil and reticuleWidgetID ~= "" and reticuleWidgetID ~= "None" then
				if parameters ~= nil and parameters.reticuleList ~= nil then
					for j = 1, #parameters.reticuleList do
						if parameters.reticuleList[j].id == reticuleWidgetID then
							parameters.reticuleList[j].position.X = reticulePos.X
							parameters.reticuleList[j].position.Y = reticulePos.Y
							isParametersDirty = true
							M.setReticulePosition(pos)
							return
						end
					end
				end
			end
		end
	end
end

function M.setSelectedReticuleRemoveFromViewport(val)
	autoReticuleRemoveFromViewport = val
	configui.setValue("autoReticuleRemoveFromViewport", val, true)
	local reticuleWidgetID = reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")]
	if reticuleWidgetID ~= nil and reticuleWidgetID ~= "" and reticuleWidgetID ~= "None" then
		if parameters ~= nil and parameters.reticuleList ~= nil then
			for j = 1, #parameters.reticuleList do
				if parameters.reticuleList[j].id == reticuleWidgetID then
					parameters.reticuleList[j].options.removeFromViewport = val
					isParametersDirty = true
					destroyReticuleComponent()
					return
				end
			end
		end
	end
end

function M.setSelectedReticuleTwoSided(val)
	autoReticuleTwoSided = val
	configui.setValue("autoReticuleTwoSided", val, true)
	local reticuleWidgetID = reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")]
	if reticuleWidgetID ~= nil and reticuleWidgetID ~= "" and reticuleWidgetID ~= "None" then
		if parameters ~= nil and parameters.reticuleList ~= nil then
			for j = 1, #parameters.reticuleList do
				if parameters.reticuleList[j].id == reticuleWidgetID then
					parameters.reticuleList[j].options.twoSided = val
					isParametersDirty = true
					destroyReticuleComponent()
					return
				end
			end
		end
	end
end

function M.setSelectedReticuleCollisionChannel(val)
	autoReticuleCollisionChannel = val
	configui.setValue("autoReticuleCollisionChannel", val, true)
	local reticuleWidgetID = reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")]
	if reticuleWidgetID ~= nil and reticuleWidgetID ~= "" and reticuleWidgetID ~= "None" then
		if parameters ~= nil and parameters.reticuleList ~= nil then
			for j = 1, #parameters.reticuleList do
				if parameters.reticuleList[j].id == reticuleWidgetID then
					parameters.reticuleList[j].collisionChannel = val
					isParametersDirty = true
					reticuleCollisionChannel = val
					return
				end
			end
		end
	end
end

function M.setSelectedReticuleScale(val)
	if val ~= nil then
		--print("Setting reticule scale to ", val.x, val.y)
		autoReticuleScale = {val.x, val.y}
		configui.setValue("autoReticuleScale", {val.x, val.y}, true)
		local reticuleWidgetID = reticuleWidgetIDList[configui.getValue("uevr_reticule_widget_list")]
		if reticuleWidgetID ~= nil and reticuleWidgetID ~= "" and reticuleWidgetID ~= "None" then
			if parameters ~= nil and parameters.reticuleList ~= nil then
				for j = 1, #parameters.reticuleList do
					if parameters.reticuleList[j].id == reticuleWidgetID then
						parameters.reticuleList[j].scale = {val.x, val.y}
						isParametersDirty = true
						reticuleScale = uevrUtils.vector(-1, -val.x, val.y)
						return
					end
				end
			end
		end
	end
end

function M.setReticulePosition(pos)
	if pos ~= nil then
		reticulePosition = uevrUtils.vector2D(pos)
		if reticulePosition ~= nil then
			configui.setValue("autoReticulePosition", {reticulePosition.X, reticulePosition.Y}, true)
		end
	end
end

function M.setDefaultWidgetClass(val)
	reticuleDefaultWidgetClass = val
	configui.setValue("uevr_reticule_widget_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.setDefaultMeshClass(val)
	reticuleDefaultMeshClass = val
	configui.setValue("uevr_reticule_mesh_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.setDefaultMeshMaterialClass(val)
	reticuleDefaultMeshMaterialClass = val
	configui.setValue("uevr_reticule_mesh_material_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.registerOnCustomCreateCallback(callback)
	uevrUtils.registerUEVRCallback("on_reticule_create", callback)
end

function M.reset()
    ---@diagnostic disable-next-line: cast-local-type
	reticuleComponent = nil
	restoreWidgetPosition = nil
	possibleReticuleNames = {}
	resetSelectedWidget()
end

function M.exists()
	return reticuleComponent ~= nil
end

function M.getComponent()
	return reticuleComponent
end

function M.destroy()
	-- if uevrUtils.getValid(reticuleComponent) ~= nil then
	-- 	uevrUtils.detachAndDestroyComponent(reticuleComponent, false)
	-- end
	destroyReticuleComponent()
	M.reset()
end

function M.hide(val)
	if val == nil then val = true end
	if uevrUtils.getValid(reticuleComponent) ~= nil then reticuleComponent:SetVisibility(not val) end
end

function M.addReticuleByClassName(className)
	if parameters == nil then
		parameters = {}
	end
	if parameters.reticuleList == nil then
		parameters.reticuleList = {}
	end
	if className ~= nil and className ~= "" then
		local widget = uevrUtils.getLoadedAsset(className)
		if uevrUtils.getValid(widget) ~= nil then
			local alreadyExists = false
			for i = 1, #parameters.reticuleList do
				if parameters.reticuleList[i].type == "Widget" and parameters.reticuleList[i].id == className then
					alreadyExists = true
					break
				end
			end
			if not alreadyExists then
				table.insert(parameters.reticuleList, { type = "Widget", id = className, label = uevrUtils.getShortName(widget), options = { removeFromViewport = true, twoSided = true }, position = {X=0.0, Y=0.0} })
				isParametersDirty = true
				updateReticuleWidgetList()
				updateSelectedReticleWidget(className)
				M.print("Added reticule widget class " .. className)
			else
				M.print("Reticule widget class already exists " .. className)
			end
		else
			M.print("Reticule widget class is not valid " .. className)
		end
	else
		M.print("Reticule widget class is empty, not adding reticule")
	end
end

-- widget can be string or object
-- options can be removeFromViewport, twoSided, drawSize, scale, rotation, position, collisionChannel, ignoreActors, traceComplex, minHitDistance
function M.createFromWidget(widget, options)
	M.print("Creating reticule from widget")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if options.ignoreActors ~= nil then reticuleIgnoreActors = options.ignoreActors else reticuleIgnoreActors = {} end
	if options.traceComplex ~= nil then reticuleTraceComplex = options.traceComplex else reticuleTraceComplex = false end
	if options.minHitDistance ~= nil then reticuleMinHitDistance = options.minHitDistance else reticuleMinHitDistance = 10 end
	if widget ~= nil then
    	---@diagnostic disable-next-line: cast-local-type
		reticuleComponent, restoreWidgetPosition = uevrUtils.createWidgetComponent(widget, options)
		if uevrUtils.getValid(reticuleComponent) ~= nil then
			---@cast reticuleComponent -nil
			--reticuleComponent:SetDrawAtDesiredSize(true)

			reticuleComponent.BoundsScale = 10 --without this object can disappear when small

			uevrUtils.set_component_relative_transform(reticuleComponent, options.position, options.rotation, options.scale)
			reticuleRotation = uevrUtils.rotator(options.rotation)
			if options.position ~= nil then M.setReticulePosition(options.position) end
			if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
				reticuleScale = kismet_math_library:Multiply_VectorVector(uevrUtils.vector(options.scale), uevrUtils.vector(-1,-1, 1))
			else
				reticuleScale = uevrUtils.vector(-0.1,-0.1,0.1)
			end

			M.print("Created reticule " .. reticuleComponent:get_full_name())
		end
	else
		M.print("Reticule component could not be created, widget is invalid")
	end

	return reticuleComponent
end

-- mesh can be string or object
-- options can be materialName, scale, rotation, position, collisionChannel
function M.createFromMesh(mesh, options)
	M.print("Creating reticule from mesh")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if mesh == nil or mesh == "DEFAULT" then
		if options.scale == nil then options.scale = {.01, .01, .01} end
		mesh = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		if options.materialName == nil or options.materialName == "" then
			options.materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
		end
	end

	local component = uevrUtils.createStaticMeshComponent(mesh, {tag="uevrlib_reticule"})
	if uevrUtils.getValid(component) ~= nil then
			---@cast component -nil
		if options.materialName ~= nil and options.materialName ~= "" then
			M.print("Adding material to reticule component")
			local material = uevrUtils.getLoadedAsset(options.materialName)
			--debugModule.dump(material)
			--local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", options.materialName) 
			if uevrUtils.getValid(material) ~= nil then
				component:SetMaterial(0, material)
			else
				M.print("Reticule material was invalid " .. options.materialName)
			end
		end

		component.BoundsScale = 10 -- without this object can disappear when small

		uevrUtils.set_component_relative_transform(component, options.position, options.rotation, options.scale)
		reticuleRotation = uevrUtils.rotator(options.rotation)
		if options.position ~= nil then M.setReticulePosition(options.position) end
		--reticulePosition = uevrUtils.vector(options.position)
		if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
			reticuleScale = uevrUtils.vector(options.scale)
		else
			reticuleScale = uevrUtils.vector(1,1,1)
		end

		M.print("Created reticule " .. component:get_full_name())
	else
		M.print("Reticule component could not be created")
	end

    ---@diagnostic disable-next-line: cast-local-type
	reticuleComponent = component
	return reticuleComponent

	-- local component = nil
	-- if meshName == nil or meshName == "DEFAULT" then
		-- if scale == nil then scale = {.01, .01, .01} end
		-- --alternates
		-- --"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"
		-- --"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial"
		-- --Not useful here but cool
		-- --Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial
		-- --Material /Engine/EditorMeshes/ColorCalibrator/M_ChromeBall.M_ChromeBall
		-- local materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough" 
		-- meshName = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
		-- if uevrUtils.getValid(component) ~= nil then
			-- M.print("Crosshair is valid. Adding material")
			-- local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", materialName) 
			-- if uevrUtils.getValid(material) ~= nil then
				-- component:SetMaterial(0, material)
			-- else
				-- M.print("Crosshair material was invalid " .. materialName)
			-- end
		-- end
	-- else		
		-- if scale == nil then scale = {1, 1, 1} end
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
	-- end


	-- if uevrUtils.getValid(component) ~= nil then
		-- component.BoundsScale = 10 --without this object can disappear when small
		-- component:SetWorldScale3D(uevrUtils.vector(scale))
		-- M.print("Created crosshair " .. component:get_full_name())
	-- end
	--crosshairComponent = component
end

function M.create()
	return M.createFromMesh()
end

-- function M.update_old(wandDirection, wandTargetLocation, originPosition, distanceAdjustment, crosshairScale, pitchAdjust, crosshairScaleAdjust)
	-- if distanceAdjustment == nil then distanceAdjustment = 200 end
	-- if crosshairScale == nil then crosshairScale = 1 end
	-- if pitchAdjust == nil then pitchAdjust = 0 end
	-- if crosshairScaleAdjust == nil then crosshairScaleAdjust = {0.01, 0.01, 0.01} end

	-- if  wandDirection ~= nil and wandTargetLocation ~= nil and originPosition ~= nil and uevrUtils.getValid(crosshairComponent) ~= nil then

		-- local maxDistance =  kismet_math_library:Vector_Distance(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- local targetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- if distanceAdjustment > maxDistance then distanceAdjustment = maxDistance end
		-- temp_vec3f:set(wandDirection.X,wandDirection.Y,wandDirection.Z) 
		-- local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
		-- rot.Pitch = rot.Pitch + pitchAdjust
		-- temp_vec3f:set(originPosition.X + (targetDirection.X * distanceAdjustment), originPosition.Y + (targetDirection.Y * distanceAdjustment), originPosition.Z + (targetDirection.Z * distanceAdjustment))

		-- crosshairComponent:GetOwner():K2_SetActorLocation(temp_vec3f, false, reusable_hit_result, false)	
		-- crosshairComponent:K2_SetWorldLocationAndRotation(temp_vec3f, rot, false, reusable_hit_result, false)
		-- temp_vec3f:set(crosshairScale * crosshairScaleAdjust[1],crosshairScale * crosshairScaleAdjust[2],crosshairScale * crosshairScaleAdjust[3])
		-- crosshairComponent:SetWorldScale3D(temp_vec3f)	
	-- end
-- end

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
	return controllers.getControllerTargetLocation(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance)
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

	if uevrUtils.getValid(reticuleComponent) ~= nil and reticuleComponent.K2_SetWorldLocationAndRotation ~= nil then
		if drawDistance == nil then drawDistance = reticuleUpdateDistance end
		if scale == nil then scale = {reticuleUpdateScale,reticuleUpdateScale,reticuleUpdateScale} end
		if rotation == nil then rotation = reticuleUpdateRotation end
		rotation = uevrUtils.rotator(rotation)

		if originLocation == nil or targetLocation == nil then
			local playerController = uevr.api:get_player_controller(0)
			local playerCameraManager = nil
			if playerController ~= nil then
				playerCameraManager = playerController.PlayerCameraManager
			end
--TODO add options to target from camera, target from controllers, or target from attachment
-- default to from controllers
			if originLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraLocation ~= nil then
					originLocation = playerCameraManager:GetCameraLocation()
				else
					originLocation = M.getOriginPositionFromController()
				end
			end

			if targetLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraRotation ~= nil then
					local direction = kismet_math_library:GetForwardVector(playerCameraManager:GetCameraRotation())
					targetLocation = M.getTargetLocation(originLocation, direction, reticuleCollisionChannel, reticuleIgnoreActors, reticuleTraceComplex, reticuleMinHitDistance)
				else
					targetLocation = M.getTargetLocationFromController(Handed.Right, reticuleCollisionChannel, reticuleIgnoreActors, reticuleTraceComplex, reticuleMinHitDistance)
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
			rot = uevrUtils.sumRotators(rot, reticuleRotation, rotation)
			---@cast reticulePosition -nil
			temp_vec3f:set(originLocation.X + (hmdToTargetDirection.X * drawDistance), originLocation.Y + (hmdToTargetDirection.Y * drawDistance), originLocation.Z + (hmdToTargetDirection.Z * drawDistance))
--print("Reticule position at ", reticulePosition.X, reticulePosition.Y)
			local adjustedPosition = getOffsetWorldPosition(temp_vec3f, rot, reticulePosition.X, reticulePosition.Y)
			reticuleComponent:K2_SetWorldLocationAndRotation(adjustedPosition, rot, false, reusable_hit_result, false)
			if scale ~= nil then
				reticuleComponent:SetWorldScale3D(kismet_math_library:Multiply_VectorVector(uevrUtils.vector(scale), reticuleScale))
			end
		end
	else
		--M.print("Update failed component not valid")
	end
end

configui.onCreateOrUpdate("reticuleUpdateDistance", function(value)
	M.setDistance(value)
end)

configui.onCreateOrUpdate("reticuleUpdateScale", function(value)
	M.setScale(value)
end)

configui.onCreateOrUpdate("reticuleUpdateRotation", function(value)
	M.setRotation(value)
end)

configui.onCreateOrUpdate("autoReticuleRemoveFromViewport", function(value)
	M.setSelectedReticuleRemoveFromViewport(value)
end)

configui.onCreateOrUpdate("autoReticuleTwoSided", function(value)
	M.setSelectedReticuleTwoSided(value)
end)

configui.onCreateOrUpdate("autoReticuleCollisionChannel", function(value)
	M.setSelectedReticuleCollisionChannel(value)
end)

configui.onCreateOrUpdate("autoReticuleScale", function(value)
	M.setSelectedReticuleScale(value)
end)

configui.onUpdate("uevr_reticule_refresh_button", function(value)
	updatePossibileReticuleList()
end)

configui.onCreateOrUpdate("uevr_reticule_widget_class", function(value)
	M.setDefaultWidgetClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_mesh_class", function(value)
	M.setDefaultMeshClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_mesh_material_class", function(value)
	M.setDefaultMeshMaterialClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_type", function(value)
	M.setReticuleType(value)
end)
--updateSelectedReticleWidget     1.7999999523163 -3.5999999046326
configui.onCreateOrUpdate("autoReticulePosition", function(value)
	M.setSelectedReticulePosition(value)
end)

configui.onUpdate("uevr_reticule_manual_add_button", function(value)
	configui.setHidden("uevr_reticule_add_manually", false)
	configui.setHidden("uevr_reticule_add_with_finder", true)
	configui.setColor("uevr_reticule_manual_add_button", "#888888FF")
	configui.setHoveredColor("uevr_reticule_manual_add_button", "#888888FF")
	configui.setColor("uevr_reticule_find_add_button", nil)
	configui.setHoveredColor("uevr_reticule_find_add_button", nil)
end)

configui.onUpdate("uevr_reticule_find_add_button", function(value)
	configui.setHidden("uevr_reticule_add_manually", true)
	configui.setHidden("uevr_reticule_add_with_finder", false)
	configui.setColor("uevr_reticule_manual_add_button", nil)
	configui.setHoveredColor("uevr_reticule_manual_add_button", nil)
	configui.setColor("uevr_reticule_find_add_button", "#888888FF")
	configui.setHoveredColor("uevr_reticule_find_add_button", "#888888FF")
end)

configui.onUpdate("uevr_reticule_manual_add_widget_class_button", function(value)
	M.addReticuleByClassName(configui.getValue("uevr_reticule_manual_add_widget_class"))
	configui.setValue("uevr_reticule_manual_add_widget_class", "")
end)

configui.onUpdate("uevr_reticule_widget_list", function(value)
	if value ~= nil and reticuleWidgetIDList[value] ~= nil then
		updateSelectedReticleWidget(reticuleWidgetIDList[value])
	end
end)


--WidgetBlueprintGeneratedClass /Game/UI/WeaponsWidgets/WB_ReticleLaser.WB_ReticleLaser_C


uevrUtils.setInterval(1000, function()
	if reticuleAutoCreationType ~= M.ReticuleType.None and not M.exists() then
		if reticuleAutoCreationType == M.ReticuleType.Custom then
			local reticuleType, element, options = uevrUtils.executeUEVRCallbacks("on_reticule_create")
			if reticuleType == M.ReticuleType.Widget then
				M.createFromWidget(element, options)
			elseif reticuleType == M.ReticuleType.Mesh then
				M.createFromMesh(element, options)
			elseif reticuleType == M.ReticuleType.Default then
				M.create()
			end
		else
			autoCreateReticule()
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
	resetSelectedWidget()
	destroyReticuleComponent()
end)

M.loadParameters()

return M
