local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local parametersFileName = ""
local parameters = {}
local isParametersDirty = false

local configFileName = "dev/reticule_config_dev"
local configTabLabel = "Reticule Dev Config"
local widgetPrefix = "uevr_reticule_"

local reticuleIDList = {}

local possibleReticuleNames = {}
local visibilityTestReticuleWidget = nil
local visibilityTestReticuleWidgetDefaultVisibility = nil


local systemMeshes = {
	"StaticMesh /Engine/BasicShapes/Sphere.Sphere",
	"StaticMesh /Engine/BasicShapes/Cube.Cube",
	"StaticMesh /Engine/BasicShapes/Plane.Plane",
	"StaticMesh /Engine/BasicShapes/Cone.Cone",
	"StaticMesh /Engine/BasicShapes/Cylinder.Cylinder",
	"StaticMesh /Engine/BasicShapes/Torus.Torus",
	"StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
}

local systemMaterials = {
	"Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough",
	"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial",
	"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial",
	"Material /Engine/EngineMaterials/UnlitGeneric.UnlitGeneric",
	"Material /Engine/EngineMaterials/VertexColorMaterial.VertexColorMaterial",
	"Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial"
}

local searchMeshList = systemMeshes
local searchMaterialList = systemMaterials

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
local reticuleTypeNameStrings = {"None", "Default", "Mesh", "Widget", "Custom"}
local reticuleTargetMethodStrings = {"Camera", "Left Controller", "Right Controller", "Left Attachment", "Right Attachment"}


local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[reticule_dev_config] " .. text, logLevel)
	end
end

local helpText = "This module allows you to configure the reticule system. If you want the reticule to be created automatically, select the type of reticule you want. You can choose a default reticule, a mesh-based reticule, or a widget-based reticule. If you choose Custom, you will need to implement the RegisterOnCustomCreateCallback function in your code and return the type of reticule to create along with any parameters needed for creation. If you do not want the reticule to be created automatically, set the type to None and create the reticule manually in your code using the Create, CreateFromWidget or CreateFromMesh functions."

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = widgetPrefix .. "config",
		initialOpen = true,
		label = "Reticule Automatic Configuration"
	},
        {
            widgetType = "combo",
            id = widgetPrefix .. "list",
            label = "Current Reticule",
            selections = {"None"},
            initialValue = 1,
        },
        { widgetType = "begin_group", id = widgetPrefix .. "current_widget_info", isHidden = true }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "Widget Reticule Settings" }, { widgetType = "begin_rect", },
            {
                widgetType = "tree_node",
                id = widgetPrefix .. "widget_id_tree",
                initialOpen = false,
                label = "Show Unique ID"
            },
                {
                    widgetType = "input_text",
                    id = widgetPrefix .. "widget_id",
                    label = "",
                    initialValue = ""
                },
            {
                widgetType = "tree_pop"
            },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "widget_label",
                label = "Widget Label",
                initialValue = "",
            },
            {
                widgetType = "tree_node",
                id = widgetPrefix .. "widget_finder_tool",
                initialOpen = false,
                label = "Widget Finder"
            },
                { widgetType = "begin_group", id = widgetPrefix .. "widget_finder_group", isHidden = false }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "" }, { widgetType = "begin_rect", },
				{
					widgetType = "tree_node",
					id = widgetPrefix .. "widget_finder_instruction_tree",
					initialOpen = false,
					label = "Reticule Widget Finder Instructions"
				},
					{
						widgetType = "text",
						id = widgetPrefix .. "widget_finder_instructions",
						label = "Perform the search when the game reticule is currently visible on the screen. The finder will automatically search for widgets that contain the words Cursor, Reticule, Reticle or Crosshair in their name. You can also enter text in the search text box to search for additional widgets. Press the Find button to see an updated list of widgets. After selecting a widget press Toggle Visibility to see if it is the correct one. If it is, press Use Selected to use it as the Widget Class.",
						wrapped = true
					},
				{ widgetType = "tree_pop" },
				{
					widgetType = "input_text",
					id = widgetPrefix .. "widget_finder_search_text",
					label = "",
					initialValue = ""
				},
				{ widgetType = "same_line", },
				{
					widgetType = "button",
					id = widgetPrefix .. "widget_finder_search_button",
					label = "Find",
					size = {80,22}
				},
				{
					widgetType = "combo",
					id = widgetPrefix .. "widget_finder_list",
					label = "Possible Reticules",
					selections = {"None"},
					initialValue = 1,
				},
				{
					widgetType = "text_colored",
					id = widgetPrefix .. "error",
					color = "#FF0000FF",
					isHidden = true,
					label = "Selected item not found. Press Refresh and try again."
				},
				{ widgetType = "indent", width = 120 },
				{
					widgetType = "button",
					id = widgetPrefix .. "toggle_visibility_button",
					label = "Toggle Visibility",
					size = {150,22}
				},
				{ widgetType = "unindent", width = 120 },
                { widgetType = "new_line" },
				{ widgetType = "indent", width = 120 },
				{
					widgetType = "text_colored",
					id = widgetPrefix .. "add_widget_error",
					color = "#FF0000FF",
					isHidden = true,
					label = ""
				},
				{
					widgetType = "button",
					id = widgetPrefix .. "widget_finder_use_button",
					label = "Use Selected",
					size = {150,22}
				},
				{ widgetType = "same_line", },
                {
                    widgetType = "checkbox",
                    id = widgetPrefix .. "add_widget_use_button_override",
                    label = "Confirm",
                    initialValue = false,
                    isHidden = true
                },
				{ widgetType = "unindent", width = 120 },
                { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
                { widgetType = "new_line" },
            {
                widgetType = "tree_pop"
            },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "widget_class",
                label = "Widget Class",
                initialValue = "",
--					disabled = true
            },
            {
                widgetType = "drag_float2",
                id = widgetPrefix .. "widget_position_2d",
                label = "Position 2D",
                speed = .1,
                range = {-20, 20},
                initialValue = {0, 0}
            },
            {
                widgetType = "drag_float2",
                id = widgetPrefix .. "widget_scale_2d",
                label = "Scale 2D",
                speed = .001,
                range = {0.001, 10},
                initialValue = {1, 1}
            },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "widget_ignorePawn",
                label = "Ignore Pawn",
                initialValue = true
            },
			{ widgetType = "same_line", },
            { widgetType = "space_horizontal", space = 20 },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "widget_removeFromViewport",
                label = "Remove From Viewport",
                initialValue = true
            },
			{ widgetType = "same_line", },
            { widgetType = "space_horizontal", space = 20 },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "widget_twoSided",
                label = "Two Sided",
                initialValue = true
            },
            {
                widgetType = "slider_int",
                id = widgetPrefix .. "widget_minHitDistance",
                label = "Min Hit Distance",
                speed = 1,
                range = {0, 1000},
                initialValue = 10
            },
            {
                widgetType = "slider_int",
                id = widgetPrefix .. "widget_collisionChannel",
                label = "Collision Channel",
                speed = 0.1,
                range = {0, 100},
                initialValue = 0
            },
            { widgetType = "indent", width = 140 },
            {
                widgetType = "button",
                id = widgetPrefix .. "delete_widget_button",
                label = "Delete",
                size = {100,22}
            },
            { widgetType = "same_line", },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "delete_widget_override",
                label = "Confirm",
                initialValue = false,
                isHidden = true
            },
            { widgetType = "unindent", width = 140 },
        { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
        { widgetType = "begin_group", id = widgetPrefix .. "current_mesh_info", isHidden = true }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "Mesh Reticule Settings" }, { widgetType = "begin_rect", },
            {
                widgetType = "tree_node",
                id = widgetPrefix .. "mesh_id_tree",
                initialOpen = false,
                label = "Show Unique ID"
            },
                {
                    widgetType = "input_text",
                    id = widgetPrefix .. "mesh_id",
                    label = "",
                    initialValue = ""
                },
            {
                widgetType = "tree_pop"
            },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "mesh_label",
                label = "Mesh Label",
                initialValue = "",
            },
            {
                widgetType = "tree_node",
                id = widgetPrefix .. "mesh_finder_tool",
                initialOpen = false,
                label = "Mesh Finder"
            },
                { widgetType = "begin_group", id = widgetPrefix .. "mesh_finder_group", isHidden = false }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "" }, { widgetType = "begin_rect", },
                {
                    widgetType = "input_text",
                    id = widgetPrefix .. "mesh_finder_search_text",
                    label = "",
                    initialValue = "",
                },
                { widgetType = "same_line", },
                {
                    widgetType = "button",
                    id = widgetPrefix .. "mesh_finder_search_button",
                    label = "Find",
                    size = {60,22}
                },
                {
                    widgetType = "combo",
                    id = widgetPrefix .. "mesh_finder_list",
                    label = "Meshes",
                    selections = searchMeshList,
                    initialValue = 1,
                },
                { widgetType = "indent", width = 120 },
                    {
                        widgetType = "button",
                        id = widgetPrefix .. "mesh_finder_use_button",
                        label = "Use Selected",
                        size = {140,22}
                    },
                { widgetType = "unindent", width = 120 },
                { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
                { widgetType = "new_line" },
            {
                widgetType = "tree_pop"
            },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "mesh_class",
                label = "Mesh Class",
                initialValue = "",
--					disabled = true
            },
            {
                widgetType = "tree_node",
                id = widgetPrefix .. "material_finder_tool",
                initialOpen = false,
                label = "Material Finder"
            },
                { widgetType = "begin_group", id = widgetPrefix .. "material_finder_group", isHidden = false }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "" }, { widgetType = "begin_rect", },
                {
                    widgetType = "input_text",
                    id = widgetPrefix .. "material_finder_search_text",
                    label = "",
                    initialValue = "",
                },
                { widgetType = "same_line", },
                {
                    widgetType = "button",
                    id = widgetPrefix .. "material_finder_search_button",
                    label = "Find",
                    size = {60,22}
                },
                {
                    widgetType = "combo",
                    id = widgetPrefix .. "material_finder_list",
                    label = "Meshes",
                    selections = searchMaterialList,
                    initialValue = 1,
                },
                { widgetType = "indent", width = 120 },
                    {
                        widgetType = "button",
                        id = widgetPrefix .. "material_finder_use_button",
                        label = "Use Selected",
                        size = {140,22}
                    },
                { widgetType = "unindent", width = 120 },
                { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
                { widgetType = "new_line" },
            {
                widgetType = "tree_pop"
            },
            {
                widgetType = "input_text",
                id = widgetPrefix .. "mesh_materialName",
                label = "Material Class",
                initialValue = "",
--					disabled = true
            },
            -- {
            --     widgetType = "drag_float3",
            --     id = widgetPrefix .. "mesh_position",
            --     label = "Position",
            --     speed = .1,
            --     range = {-20, 20},
            --     initialValue = {0, 0, 0}
            -- },
            {
                widgetType = "drag_float3",
                id = widgetPrefix .. "mesh_scale",
                label = "Scale",
                speed = .001,
                range = {0.001, 10},
                initialValue = {1, 1, 1}
            },
            {
                widgetType = "drag_float3",
                id = widgetPrefix .. "mesh_rotation",
                label = "Rotation",
                speed = .1,
                range = {-180, 180},
                initialValue = {0, 0, 0}
            },
            {
                widgetType = "drag_float2",
                id = widgetPrefix .. "mesh_position_2d",
                label = "Position 2D",
                speed = .1,
                range = {-20, 20},
                initialValue = {0, 0}
            },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "mesh_ignorePawn",
                label = "Ignore Pawn",
                initialValue = true
            },
            -- {
            --     widgetType = "drag_float2",
            --     id = widgetPrefix .. "mesh_scale_2d",
            --     label = "Scale 2D",
            --     speed = .001,
            --     range = {0.001, 10},
            --     initialValue = {1, 1}
            -- },
            {
                widgetType = "slider_int",
                id = widgetPrefix .. "mesh_minHitDistance",
                label = "Min Hit Distance",
                speed = 1,
                range = {0, 1000},
                initialValue = 10
            },
            {
                widgetType = "slider_int",
                id = widgetPrefix .. "mesh_collisionChannel",
                label = "Collision Channel",
                speed = 0.1,
                range = {0, 100},
                initialValue = 0
            },
            { widgetType = "indent", width = 140 },
            {
                widgetType = "button",
                id = widgetPrefix .. "delete_mesh_button",
                label = "Delete",
                size = {100,22}
            },
            { widgetType = "same_line", },
            {
                widgetType = "checkbox",
                id = widgetPrefix .. "delete_mesh_override",
                label = "Confirm",
                initialValue = false,
                isHidden = true
            },
            { widgetType = "unindent", width = 140 },
        { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
        { widgetType = "begin_group", id = widgetPrefix .. "current_custom_info", isHidden = true }, { widgetType = "indent", width = 10 }, { widgetType = "text", label = "Custom Reticule Settings" }, { widgetType = "begin_rect", },
            {
                widgetType = "text",
                id = widgetPrefix .. "custom_instructions",
                label = "To use Custom you will need to implement the RegisterOnCustomCreateCallback function in your code and return the type of reticule to create along with any parameters needed for creation. See the documentationn for more information",
                wrapped = true,
                isHidden = true
            },
        { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 10 }, { widgetType = "end_group", },
        { widgetType = "new_line" },
	{
		widgetType = "tree_pop"
	},
    {
        widgetType = "tree_node",
        id =  widgetPrefix .. "advanced_tree",
        initialOpen = false,
        label = "Advanced"
    },
        {
            widgetType = "combo",
            id = widgetPrefix .. "target_method",
            label = "Target From",
            selections = reticuleTargetMethodStrings,
            initialValue = 1,
        },
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

local function getLabelArrayFromList(list)
    local labelArray = {}
    for i = 1, #list do
        table.insert(labelArray, list[i].label)
    end
    return labelArray
end

local function getIndexOfID(list, id)
    for i = 1, #list do
        if list[i].id == id then
            return i
        end
    end
    return nil
end

local function getReticuleParametersByID(reticuleID)
    if parameters ~= nil and parameters.reticuleList ~= nil then
        for i = 1, #parameters.reticuleList do
            if parameters.reticuleList[i].id == reticuleID then
                return parameters.reticuleList[i]
            end
        end
    end
    return nil
end

local function createDefaultReticuleParameters()
    local reticuleParameters = nil
    if parameters ~= nil and parameters.reticuleList ~= nil then
        reticuleParameters = {
            type = "Mesh",
            class = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere",
            options = { materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough", scale = {.008, .008, .008},  position_2d = {0.0, 0.0}, scale_2d = {1.0, 1.0}, collisionChannel = 0, ignorePawn = true},
            id = "_default",
            label = "Default",
        }
        table.insert(parameters.reticuleList, 1, reticuleParameters)
        isParametersDirty = true
    end
    return reticuleParameters
end

local function setCurrentReticleParametersUI()
    local currentReticuleID = parameters["currentReticuleID"]
    local reticuleParameters = getReticuleParametersByID(currentReticuleID)
    if reticuleParameters == nil and currentReticuleID == "_default" then
        reticuleParameters = createDefaultReticuleParameters()
    end
    configui.hideWidget(widgetPrefix .. "current_mesh_info", true)
    configui.hideWidget(widgetPrefix .. "current_widget_info", true)
    configui.hideWidget(widgetPrefix .. "current_custom_info", true)
    if reticuleParameters ~= nil then
        if reticuleParameters.options == nil then
            reticuleParameters.options = {}
            isParametersDirty = true
        end
        if reticuleParameters.type == "Widget" then
            configui.hideWidget(widgetPrefix .. "current_widget_info", false)
            configui.hideWidget(widgetPrefix .. "delete_widget_override", true)
            configui.setValue(widgetPrefix .. "delete_widget_override", false)
            configui.setValue(widgetPrefix .. "widget_label", reticuleParameters.label, true)
            configui.setValue(widgetPrefix .. "widget_class", reticuleParameters.class, true)
            configui.setValue(widgetPrefix .. "widget_position_2d", reticuleParameters.options.position_2d or {0.0, 0.0}, true)
            configui.setValue(widgetPrefix .. "widget_scale_2d", reticuleParameters.options.scale_2d or {1.0, 1.0}, true)
            configui.setValue(widgetPrefix .. "widget_removeFromViewport", reticuleParameters.options and reticuleParameters.options.removeFromViewport, true)
            configui.setValue(widgetPrefix .. "widget_ignorePawn", reticuleParameters.options and reticuleParameters.options.ignorePawn, true)
            configui.setValue(widgetPrefix .. "widget_twoSided", reticuleParameters.options and reticuleParameters.options.twoSided, true)
            configui.setValue(widgetPrefix .. "widget_collisionChannel", reticuleParameters.options.collisionChannel, true)
            configui.setValue(widgetPrefix .. "widget_minHitDistance", reticuleParameters.options.minHitDistance, true)
            configui.setValue(widgetPrefix .. "widget_id", reticuleParameters.id, true)
        elseif reticuleParameters.type == "Mesh" then
            configui.hideWidget(widgetPrefix .. "current_mesh_info", false)
            configui.hideWidget(widgetPrefix .. "delete_mesh_override", true)
            configui.setValue(widgetPrefix .. "delete_mesh_override", false)
            configui.setValue(widgetPrefix .. "mesh_label", reticuleParameters.label, true)
            configui.setValue(widgetPrefix .. "mesh_class", reticuleParameters.class, true)
            configui.setValue(widgetPrefix .. "mesh_materialName", reticuleParameters.options.materialName or "", true)
            configui.setValue(widgetPrefix .. "mesh_position", reticuleParameters.options.position or {0.0, 0.0, 0.0}, true)
            configui.setValue(widgetPrefix .. "mesh_rotation", reticuleParameters.options.rotation or {0.0, 0.0, 0.0}, true)
            configui.setValue(widgetPrefix .. "mesh_scale", reticuleParameters.options.scale or {1.0, 1.0, 1.0}, true)
            configui.setValue(widgetPrefix .. "mesh_ignorePawn", reticuleParameters.options and reticuleParameters.options.ignorePawn, true)
            configui.setValue(widgetPrefix .. "mesh_position_2d", reticuleParameters.options.position_2d or {0.0, 0.0}, true)
            configui.setValue(widgetPrefix .. "mesh_scale_2d", reticuleParameters.options.scale_2d or {1.0, 1.0}, true)
            configui.setValue(widgetPrefix .. "mesh_collisionChannel", reticuleParameters.options.collisionChannel, true)
            configui.setValue(widgetPrefix .. "mesh_minHitDistance", reticuleParameters.options.minHitDistance, true)
            configui.setValue(widgetPrefix .. "mesh_id", reticuleParameters.id, true)
            --none or default reticule, no settings to show
        end
    else
        if currentReticuleID == "_custom" then
            configui.hideWidget(widgetPrefix .. "current_custom_info", false)
            if uevrUtils.hasUEVRCallbacks("on_reticule_create") == false then
                --show message that custom reticule requires callback
                configui.hideWidget(widgetPrefix .. "custom_instructions", false)
                configui.setLabel(widgetPrefix .. "custom_instructions", "To use Custom you will need to implement the RegisterOnCustomCreateCallback function in your code and return the type of reticule to create along with any parameters needed for creation. See the documentationn for more information")
            else
                local reticuleType, element, options = uevrUtils.executeUEVRCallbacks("on_reticule_create")
                configui.hideWidget(widgetPrefix .. "custom_instructions", false)
                local text = ""
                text = text .. "Reticule Type: " .. reticuleTypeNameStrings[reticuleType] .. "\n"
                text = text .. "Element: " .. (element and element:get_full_name() or "") .. "\n"
                text = text .. "Options: " .. tostring(uevrUtils.tableToString(options)) .. "\n"
                configui.setLabel(widgetPrefix .. "custom_instructions", text)
            end
            M.updateCustomReticleParametersUILock()
        end
    end
end

M.updateCustomReticleParametersUILock = doOnce(function()
    M.print("Updating custom reticle parameters UI after delay")
    setTimeout(3000, function()
        --uncomment this to get continuous updates of custom reticle parameters
        --M.updateCustomReticleParametersUILock:reset()
        setCurrentReticleParametersUI()
    end)
end, Once.EVER)



local function updateReticuleList()
	reticuleIDList = {}
	if parameters ~= nil and parameters.reticuleList ~= nil then
		for i = 1, #parameters.reticuleList do
            if parameters.reticuleList[i].id ~= "_default" and parameters.reticuleList[i].id ~= "_custom" then
 			    table.insert(reticuleIDList, {id = parameters.reticuleList[i].id, label = parameters.reticuleList[i].label})
            end
		end
	end
	table.insert(reticuleIDList, 1,{id = "_none", label = "None"})
    table.insert(reticuleIDList, 2,{id = "_default", label = "Default"})
    table.insert(reticuleIDList, 3,{id = "_custom", label = "Custom"})
    table.insert(reticuleIDList,{id = "_new_widget", label = "- Add New Widget -"})
    table.insert(reticuleIDList,{id = "_new_mesh", label = "- Add New Mesh -"})
	configui.setSelections(widgetPrefix .. "list", getLabelArrayFromList(reticuleIDList))
    configui.setValue(widgetPrefix .. "list", getIndexOfID(reticuleIDList, parameters["currentReticuleID"]) or 1)

    setCurrentReticleParametersUI()
end

local function initUI()
    if parameters["reticuleTargetMethod"] ~= nil then
        configui.setValue(widgetPrefix .. "target_method", parameters["reticuleTargetMethod"] or M.ReticuleTargetMethod.CAMERA, true)
    end
    updateReticuleList()
end


local function updatePossibileReticuleList(searchText)
	local widgets = uevrUtils.find_all_instances("Class /Script/UMG.Widget", false)
	possibleReticuleNames = {}
	--local activeWidgets = {}

	if widgets ~= nil then
		for name, widget in pairs(widgets) do
			local widgetName = widget:get_full_name()
			if not (widgetName:sub(1, 5) == "Image" or widgetName:sub(1, 7) == "Overlay" or widgetName:sub(1, 11) == "CanvasPanel" or widgetName:sub(1, 13) == "HorizontalBox" or widgetName:sub(1, 8) == "ScaleBox" or widgetName:sub(1, 7) == "SizeBox" or widgetName:sub(1, 11) == "VerticalBox" or widgetName:sub(1, 6) == "Border" or widgetName:sub(1, 9) == "TextBlock" or widgetName:sub(1, 6) == "Spacer") then
				if string.find(widgetName, "Cursor") or string.find(widgetName, "Reticule") or string.find(widgetName, "Reticle") or string.find(widgetName, "Crosshair") or (searchText ~= nil and searchText ~= "" and string.find(widgetName, searchText)) then
					--code to get only player activbe widgets
                    -- if configui.getValue("uevr_dev_reticule_active") == true then
					-- 	local isActive = false
					-- 	if uevrUtils.getValid(pawn) ~= nil and widget.GetOwningPlayerPawn ~= nil then
					-- 		isActive = widget:GetOwningPlayerPawn() == pawn
					-- 		if isActive then
					-- 			--table.insert(activeWidgets, widget)
					-- 			table.insert(possibleReticuleNames, widgetName)
					-- 		end
					-- 	end
					-- 	--print(widget:get_full_name(), isActive and "true" or "false")
					-- else
						table.insert(possibleReticuleNames, widgetName)
					-- end
				end
			end
		end
	end

	--configui.setLabel("uevr_dev_reticule_total_count", "Reticule count:" .. #reticuleNames)
	--table.insert(possibleReticuleNames, 1, "Custom")
	configui.setSelections(widgetPrefix .. "widget_finder_list", possibleReticuleNames)
end

local function saveParameters()
	M.print("Saving reticule parameters " .. parametersFileName)
    if parametersFileName ~= nil and parametersFileName ~= "" then
	    json.dump_file(parametersFileName .. ".json", parameters, 4)
    else
        M.print("Parameters file name is not set, cannot save reticule parameters", LogLevel.Warning)
    end
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
	end)
end, Once.EVER)

function M.setParametersFileName(fileName)
    parametersFileName = fileName
end

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    M.loadParameters(parametersFileName)

    if isDeveloperMode then
	    M.showDeveloperConfiguration(configFileName)
        createDevMonitor()
        initUI()
    else
    end
end


function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel(configTabLabel, saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel(configTabLabel .. " Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading reticule parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
        isParametersDirty = false
		M.print("Creating reticule parameters")
	end

	if parameters["reticuleList"] == nil then
		parameters["reticuleList"] = {}
        isParametersDirty = false
	end
end

function M.addNewReticule(label, className, reticuleType, options, override)
	if parameters == nil then
		parameters = {}
        isParametersDirty = true
	end
	if parameters.reticuleList == nil then
		parameters.reticuleList = {}
        isParametersDirty = true
	end
    if reticuleType == nil or reticuleType < 1 or reticuleType > 5 then
        return 1, "Invalid reticule type"
    end
	--if className ~= nil and className ~= "" then
        --if label == nil then label = className end
		local instance = uevrUtils.getLoadedAsset(className)
		if override ~= true and uevrUtils.getValid(instance) == nil then
            --return 2, "An instance of this class does not exist, use it anyway?"
        else
            if label == nil then label = instance and uevrUtils.getShortName(instance) or label end
        end

        local newReticuleParameters = {
            type = reticuleTypeNameStrings[reticuleType],
            class = className or "",
            options = options or {},
            id = uevrUtils.guid(),
            label = label or "New Reticule",
        }
        -- if reticuleType == M.ReticuleType.Mesh then
        --     newReticuleParameters.materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
        -- end

        table.insert(parameters.reticuleList , newReticuleParameters)
        isParametersDirty = true

        M.setCurrentReticuleByID(newReticuleParameters.id)
        updateReticuleList()
    --else
    --    return 1, "Invalid class name"
    --end
    return 0, ""
end

function M.addDefaultWidgetReticule(label, className, override)
    local options = { ignorePawn = true, removeFromViewport = true, twoSided = true, position_2d = {0.0, 0.0}, scale_2d = {1.0, 1.0}, collisionChannel = 0 }
    return M.addNewReticule(label, className, M.ReticuleType.WIDGET, options, override)
end

function M.addDefaultMeshReticule(label, className, materialClass, override)
    local options = { ignorePawn = true, materialName = materialClass, position_2d = {0.0, 0.0}, scale_2d = {1.0, 1.0}, collisionChannel = 0 }
    return M.addNewReticule(label, className, M.ReticuleType.MESH, options, override)
end


local function getSelectedPossibleReticuleWidget()
    local currentReticuleSelectionIndex = configui.getValue(widgetPrefix .. "widget_finder_list")
	if possibleReticuleNames ~= nil and currentReticuleSelectionIndex <= #possibleReticuleNames and currentReticuleSelectionIndex > 1 then
		--local widget = uevrUtils.getLoadedAsset(reticuleNames[currentReticuleSelectionIndex])	
		return uevrUtils.find_instance_of("Class /Script/UMG.Widget", possibleReticuleNames[currentReticuleSelectionIndex])
	end
	return nil
end

function M.deleteCurrentReticule()
    local currentReticuleID = parameters["currentReticuleID"]
    for i = 1, #parameters.reticuleList do
        if parameters.reticuleList[i].id == currentReticuleID then
            table.remove(parameters.reticuleList, i)
            isParametersDirty = true
            M.setCurrentReticuleByID("_none")
            return true
        end
    end
    return false
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

local function resetVisibilityTestWidget()
	if visibilityTestReticuleWidget ~= nil and uevrUtils.getValid(visibilityTestReticuleWidget) ~= nil then
		--reset previous widget visibility
		if visibilityTestReticuleWidgetDefaultVisibility ~= nil then
			visibilityTestReticuleWidget:SetVisibility(visibilityTestReticuleWidgetDefaultVisibility)
		end
		visibilityTestReticuleWidget = nil
		visibilityTestReticuleWidgetDefaultVisibility = nil
	end
end

local function updateSelectedPossibleReticule()
	resetVisibilityTestWidget()
    local widget = getSelectedPossibleReticuleWidget()
    if widget == nil then
        configui.hideWidget(widgetPrefix .. "error" ,false)
        delay(3000, function()
            configui.hideWidget(widgetPrefix .. "error" ,true)
        end)
    else
        visibilityTestReticuleWidget = widget
        visibilityTestReticuleWidgetDefaultVisibility = widget:GetVisibility()
    end
end

local function populateMeshSearchList()
    local searchText = configui.getValue(widgetPrefix .. "mesh_finder_search_text")
    local meshes = uevrUtils.find_all_instances("Class /Script/Engine.StaticMesh", false)
	searchMeshList = {}
    --copy systemMeshes to meshNames
    for _, meshName in ipairs(systemMeshes) do
        table.insert(searchMeshList, meshName)
    end
	if meshes ~= nil then
		for name, mesh in pairs(meshes) do
			if searchText == nil or searchText == "" or string.find(mesh:get_full_name(), searchText) then
				table.insert(searchMeshList, mesh:get_full_name())
			end
		end
	end

    configui.setSelections(widgetPrefix .. "mesh_finder_list", searchMeshList)
end

local function populateMaterialSearchList()
    local searchText = configui.getValue(widgetPrefix .. "material_finder_search_text")
    local materials = uevrUtils.find_all_instances("Class /Script/Engine.Material", false)
	searchMaterialList = {}
    --copy systemMaterials to materialNames
    for _, materialName in ipairs(systemMaterials) do
        table.insert(searchMaterialList, materialName)
    end
	if materials ~= nil then
		for name, material in pairs(materials) do
			if searchText == nil or searchText == "" or string.find(material:get_full_name(), searchText) then
				table.insert(searchMaterialList, material:get_full_name())
			end
		end
	end

    configui.setSelections(widgetPrefix .. "material_finder_list", searchMaterialList)
end

function M.setCurrentReticleParameter(paramName, value)
    print("Setting reticule parameter " .. paramName .. " to " .. tostring(value))
    local currentReticuleID = parameters["currentReticuleID"]
    local reticuleParameters = getReticuleParametersByID(currentReticuleID)
    if reticuleParameters ~= nil then
        if paramName == "label" then
            reticuleParameters["label"] = value
        elseif paramName == "class" then
            reticuleParameters["class"] = value
            uevrUtils.executeUEVRCallbacks("on_reticule_config_param_change", parameters)
        else
            reticuleParameters.options[paramName] = value
            local reloadParamNames = {removeFromViewport=true, twoSided=true, materialName=true}
            if reloadParamNames[paramName] ~= nil then
                uevrUtils.executeUEVRCallbacks("on_reticule_config_param_change", parameters)
            else
                uevrUtils.executeUEVRCallbacks("on_reticule_config_param_change", parameters, reticuleParameters.options)
             end
       end
        isParametersDirty = true
    end
end

function M.setTargetMethod(methodIndex)
    if parameters ~= nil then
        parameters["reticuleTargetMethod"] = methodIndex
        uevrUtils.executeUEVRCallbacks("on_reticule_config_param_change", parameters)
        isParametersDirty = true
    end
end

function M.setCurrentReticuleByID(id)
    if parameters ~= nil then
        M.print("Setting current reticule to " .. id)
        parameters["currentReticuleID"] = id
        uevrUtils.executeUEVRCallbacks("on_reticule_config_param_change", parameters)
        isParametersDirty = true
    end
end

function M.setCurrentReticuleByIndex(index)
    if #reticuleIDList >= index then
        local reticuleID = reticuleIDList[index].id
        M.setCurrentReticuleByID(reticuleID)
    end
end

local function getUniqueName(reticuleType)
    local baseName = "New " .. reticuleType
    local uniqueName = baseName
    local index = 1
    if parameters ~= nil and parameters.reticuleList ~= nil then
        for i = 1, #parameters.reticuleList do
            if parameters.reticuleList[i].label == uniqueName then
                uniqueName = baseName .. tostring(index)
                index = index + 1
            end
        end
    end
    return uniqueName
end

configui.onCreateOrUpdate(widgetPrefix .. "list", function(value)
    print("Reticule selection changed to index " .. tostring(value), #reticuleIDList)
    if #reticuleIDList >= value then
        if reticuleIDList[value].id == "_new_widget" then
            M.addDefaultWidgetReticule(getUniqueName("Widget"), "", true)
        elseif reticuleIDList[value].id == "_new_mesh" then
            M.addDefaultMeshReticule(getUniqueName("Mesh"), "StaticMesh /Engine/BasicShapes/Sphere.Sphere", "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough", true)
        else
            M.setCurrentReticuleByIndex(value)
            setCurrentReticleParametersUI()
        end
    end
end)

configui.onUpdate(widgetPrefix .. "target_method", function(value)
    M.print("Setting reticule target method to " .. tostring(value))
    M.setTargetMethod(value)
end)

configui.onUpdate(widgetPrefix .. "widget_finder_search_button", function(value)
	updatePossibileReticuleList(configui.getValue(widgetPrefix .. "widget_finder_search_text"))
end)

configui.onUpdate(widgetPrefix .. "toggle_visibility_button", function()
	toggleSelectedPossibleReticuleVisibility()
end)

configui.onUpdate(widgetPrefix .. "widget_finder_list", function(value)
	if value ~= nil and possibleReticuleNames ~= nil and possibleReticuleNames[value] ~= nil then
		M.print("Using reticule at index " .. value .. " - " .. possibleReticuleNames[value])
	end
	updateSelectedPossibleReticule()
end)

configui.onUpdate(widgetPrefix .. "delete_mesh_button", function()
    if configui.getValue(widgetPrefix .. "delete_mesh_override") == true then
        if M.deleteCurrentReticule() then
            updateReticuleList()
        end
    else
        configui.hideWidget(widgetPrefix .. "delete_mesh_override", false)
        configui.setValue(widgetPrefix .. "delete_mesh_override", false)
    end
end)

configui.onUpdate(widgetPrefix .. "delete_widget_button", function()
    if configui.getValue(widgetPrefix .. "delete_widget_override") == true then
        if M.deleteCurrentReticule() then
            updateReticuleList()
        end
    else
        configui.hideWidget(widgetPrefix .. "delete_widget_override", false)
        configui.setValue(widgetPrefix .. "delete_widget_override", false)
    end
end)

--edit fields

configui.onUpdate(widgetPrefix .. "widget_label", function(value)
	M.setCurrentReticleParameter("label", value)
    updateReticuleList()
end)

configui.onUpdate(widgetPrefix .. "mesh_label", function(value)
	M.setCurrentReticleParameter("label", value)
    updateReticuleList()
end)

configui.onUpdate(widgetPrefix .. "mesh_finder_search_button", function(value)
    populateMeshSearchList()
end)

configui.onUpdate(widgetPrefix .. "mesh_finder_use_button", function(value)
    configui.setValue(widgetPrefix .. "mesh_class", searchMeshList[configui.getValue(widgetPrefix .. "mesh_finder_list")])
end)

configui.onUpdate(widgetPrefix .. "widget_finder_use_button", function(value)
    local widgetClass = ""
    local widget = getSelectedPossibleReticuleWidget()
    if widget ~= nil then
        if uevrUtils.getValid(widget) ~= nil and widget:get_class() ~= nil then
            widgetClass = widget:get_class():get_full_name()
        end
    end

    --configui.setValue(widgetPrefix .. "widget_class", possibleReticuleNames[configui.getValue(widgetPrefix .. "widget_finder_list")])
    configui.setValue(widgetPrefix .. "widget_class", widgetClass)
end)

configui.onUpdate(widgetPrefix .. "material_finder_search_button", function(value)
    populateMaterialSearchList()
end)

configui.onUpdate(widgetPrefix .. "material_finder_use_button", function(value)
    configui.setValue(widgetPrefix .. "mesh_materialName", searchMaterialList[configui.getValue(widgetPrefix .. "material_finder_list")])
end)

local editParamNames = {"widget_class", "widget_position_2d", "widget_scale_2d", "widget_removeFromViewport", "widget_twoSided", "widget_collisionChannel", "widget_minHitDistance",
                        "mesh_class", "mesh_materialName", "mesh_position_2d", "mesh_scale_2d", "mesh_position", "mesh_scale", "mesh_rotation", "mesh_collisionChannel", "mesh_minHitDistance", "widget_ignorePawn", "mesh_ignorePawn"}
for i = 1, #editParamNames do
    configui.onUpdate(widgetPrefix .. editParamNames[i], function(value)
        local paramName = nil
        if editParamNames[i]:sub(1, 6) == "widget" then
            paramName = editParamNames[i]:sub(8)
        elseif editParamNames[i]:sub(1, 4) == "mesh" then
            paramName = editParamNames[i]:sub(6)
        end
        if paramName ~= nil then
            M.setCurrentReticleParameter(paramName, uevrUtils.getNativeValue(value))
        end
    end)
end

function M.registerParametersChangedCallback(callback)
    uevrUtils.registerUEVRCallback("on_reticule_config_param_change", callback)
end

function M.reset()
	possibleReticuleNames = {}
	resetVisibilityTestWidget()
end

uevrUtils.registerPreLevelChangeCallback(function(level)
	M.reset()
end)

uevr.params.sdk.callbacks.on_script_reset(function()
	M.reset()
end)

return M