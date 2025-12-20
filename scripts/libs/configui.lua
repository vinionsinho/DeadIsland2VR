--[[ 
Usage
	Drop the lib folder containing this file into your project folder
	Add code like this in any file. For example this could be added to a standalone file called config_hands.lua
		local configui = require("libs/configui")
		local configDefinition = {
			{
				panelLabel = "Hands", 
				saveFile = "config_hands", 
				layout = 
				{
					{
						widgetType = "checkbox",
						id = "use_hands",
						label = "Use Hands",
						initialValue = true
					}
				}
			}
		}
		configui.create(configDefinition)
	
	Available functions:
	
	configui.create(configDefinition) creates the imgui UI in the UEVR overlay based on the layout provided in the configDefinition
		example: 
			configui.create(configDefinition)
			
	configui.update(configDefinition) updates the imgui UI in the UEVR overlay based on the layout provided in the configDefinition
		example: 
			configui.update(configDefinition)

	configui.getValue(itemID) -- gets the current value of the item with the id field matching itemID. When creating id values in a configuration
		layout try to ensure uniqueness so that if multiple people are creating configs for the same project, the ids wont conflict. Be aware that
		the itemID can be that of any configDefiniton if multiple configDefinitons are used in the project. Also note
		the the itemID doesn't have to exist in a configDefiniton. If you want to keep track of config settings without providing a UI for it the the user, then
		you can do that as well.
		example
			local usingHands = configui.getValue("use_hands")
			local myVal = configui.getValue("some_id_that_doesnt_exist_in_any_config") -- returns nil until you set that value
			
	configui.setValue(itemID, value) -- sets the value of the given itemID
		example
			configui.setValue("use_hands", true)
			configui.setValue("some_id_that_doesnt_exist_in_any_config", 1) -- now getValue() will return 1

	configui.setLabel(itemID, newLabel) -- sets the label of the given itemID
		example
			configui.setLabel("use_hands", "Use Hands")

	configui.hideWidget(widgetID, value) -- hides widget if value is true or shows widget if value is false
		example
			configui.hideWidget("use_hands", true)

	configui.setSelections(widgetID, selections) --changes the available selections in a dropdown
		example
			configui.setSelections("selection_list", {"One","Two","Three"})
	
	configui.onUpdate(itemID, callbackFunction) -- allows you to define a callback function that triggers any time the value for the itemID changes for any reason,
		including being changed in the UI or being changed with code.
		example:
			configui.onUpdate("use_hands", function(value)
				if value == false then
					local count = configui.getValue("false_count")
					print("Current count", count)
					if count == nil then count = 0 end
					configui.setValue("false_count", count + 1)
					count = configui.getValue("false_count")
					print("New count", count)
				end
			end)

	configui.onCreate(widgetID, callbackFunction) -- registers a callback function that triggers when a widget is first created
		example:
			configui.onCreate("use_hands", function(value)
				print("Hands widget created with initial value:", value)
			end)

	configui.onCreateOrUpdate(widgetID, callbackFunction) -- registers a callback that triggers both on widget creation and value updates
		example:
			configui.onCreateOrUpdate("use_hands", function(value)
				print("Hands widget created or updated:", value)
			end)


	configui.updatePanel(panelDefinition) -- updates an existing panel with new layout or configuration
		example:
			local updatedDef = {
				panelLabel = "Updated Panel",
				layout = {
					{
						widgetType = "checkbox",
						id = "new_option",
						label = "New Option",
						initialValue = true
					}
				}
			}
			configui.updatePanel(updatedDef)

	configui.load(panelID, fileName) -- loads configuration values from a JSON file for a specific panel
		example:
			configui.load("hands_panel", "config_hands")

	configui.save(panelID) -- saves current configuration values for a panel to its associated JSON file
		example:
			configui.save("hands_panel")

	configui.getPanelID(widgetID) -- gets the panel ID associated with a widget ID
		example:
			local panelID = configui.getPanelID("use_hands")

	configui.setHidden(widgetID, value) -- sets whether a widget is hidden (alias for hideWidget)
		example:
			configui.setHidden("use_hands", true)

	configui.disableWidget(widgetID, value) -- sets whether a widget is disabled/grayed out
		example:
			configui.disableWidget("use_hands", true)

	configui.setColor(widgetID, colorString) -- sets the base color of a button (in #BBGGRRAA format)
		example:
			configui.setColor("my_button", "#FF0000FF") -- Set to blue

	configui.setHoveredColor(widgetID, colorString) -- sets the hover color of a button (in #BBGGRRAA format)
		example:
			configui.setHoveredColor("my_button", "#FF4444FF") -- Set to lighter blue

	configui.setActiveColor(widgetID, colorString) -- sets the pressed color of a button (in #BBGGRRAA format)
		example:
			configui.setActiveColor("my_button", "#FF8888FF") -- Set to even lighter blue

	configui.hidePanel(panelID, value) -- sets whether an entire panel is hidden
		example:
			configui.hidePanel("hands_panel", true)

	configui.togglePanel(panelID) -- toggles visibility of a panel
		example:
			configui.togglePanel("hands_panel")

	configui.applyOptionsToConfigWidgets(configWidgets, options) -- applies a set of options to multiple config widgets
		example:
			local widgets = {{id="eyeOffset"}, {id="use_hands"}}
			local options = {{id="eyeOffset",isHidden=false}, {id="use_hands", disabled=true}}
			configui.applyOptionsToConfigWidgets(widgets, options)

	configui.createConfigPanel(label, saveFileName, widgets) -- creates a new config panel with specified widgets
		example:
			local widgets = {{
				widgetType = "checkbox",
				id = "headLockedUI",
				label = "Enable Head Locked UI",
			}}
			configui.createConfigPanel("My Panel", "my_config", widgets)

Available Widget Types:

	1. Basic Input Widgets:
	- checkbox - Boolean checkbox input
		properties: id, label, initialValue
		example: { widgetType = "checkbox", id = "use_hands", label = "Use Hands", initialValue = true }

	- combo - Dropdown selection menu
		properties: id, label, selections, initialValue, width
		example: { widgetType = "combo", id = "animation_hand", label = "Hand", selections = {"Left","Right","Both"}, initialValue = 1, width = 150 }

	- button - Regular button
		properties: id, label, size, color, hoveredColor, activeColor
		example: { 
			widgetType = "button", 
			id = "generate_code_button", 
			label = "Generate code", 
			size = {140,24},
			color = "#FF0000FF",       -- Base button color (#RRGGBBAA format)
			hoveredColor = "#FF4444FF", -- Color when mouse hovers over button
			activeColor = "#FF8888FF"   -- Color when button is pressed
		}

	- small_button - Smaller sized button
		properties: id, label, size
		example: { widgetType = "small_button", id = "refresh_button", label = "↻", size = {20,20} }

	- input_text - Single line text input
		properties: id, label, initialValue, width
		example: { widgetType = "input_text", id = "widget_class", label = "Widget Class", initialValue = "", width = 200 }

	- input_text_multiline - Multi-line text input area
		properties: id, label, initialValue, size
		example: { widgetType = "input_text_multiline", id = "description", label = "Description", initialValue = "", size = {440, 180} }

	- text - Static text display
		properties: label, wrapped, textWidth
		example: { widgetType = "text", label = "Configuration Help", wrapped = true, textWidth = 60 }

	2. Numeric Input Widgets:
	- slider_int - Integer slider
		properties: id, label, range, initialValue
		example: { widgetType = "slider_int", id = "priority", label = "Priority", range = {0, 10}, initialValue = 5 }

	- slider_float - Float slider
		properties: id, label, range, initialValue, speed
		example: { widgetType = "slider_float", id = "scale", label = "Scale", range = {0.1, 2.0}, initialValue = 1.0, speed = 0.01 }

	- drag_int - Draggable integer input
		properties: id, label, speed, range, initialValue
		example: { widgetType = "drag_int", id = "count", label = "Count", speed = 1, range = {0, 100}, initialValue = 0 }

	- drag_float - Draggable float input
		properties: id, label, speed, range, initialValue
		example: { widgetType = "drag_float", id = "distance", label = "Distance", speed = 0.1, range = {0, 100}, initialValue = 50 }

	- drag_float2 - 2D vector input (X,Y)
		properties: id, label, speed, range, initialValue
		example: { widgetType = "drag_float2", id = "position_2d", label = "Position", speed = 0.1, range = {-10, 10}, initialValue = {0, 0} }

	- drag_float3 - 3D vector input (X,Y,Z)
		properties: id, label, speed, range, initialValue
		example: { widgetType = "drag_float3", id = "position_3d", label = "Position", speed = 0.1, range = {-10, 10}, initialValue = {0, 0, 0} }

	- drag_float4 - 4D vector input (X,Y,Z,W)
		properties: id, label, speed, range, initialValue
		example: { widgetType = "drag_float4", id = "rotation", label = "Rotation", speed = 1, range = {0, 360}, initialValue = {0, 0, 0, 1} }

	3. Visual Widgets:
	- color_picker - Color selection widget
		properties: id, label, initialValue
		example: { widgetType = "color_picker", id = "text_color", label = "Text Color", initialValue = "#FFFFFFFF" }

	- text_colored - Colored text display
		properties: label, color
		example: { widgetType = "text_colored", label = "Warning!", color = "#FF0000FF" }

	- tree_node - Collapsible tree node
		properties: id, label, initialOpen
		example: { widgetType = "tree_node", id = "settings_group", label = "Settings", initialOpen = true }

	- tree_node_ptr_id - Tree node with pointer ID
		properties: id, label, initialOpen
		example: { widgetType = "tree_node_ptr_id", id = "ptr_settings", label = "Pointer Settings", initialOpen = true }

	- tree_node_str_id - Tree node with string ID
		properties: id, label, initialOpen
		example: { widgetType = "tree_node_str_id", id = "str_settings", label = "String Settings", initialOpen = true }

	- tree_pop - End of tree node
		no properties required
		example: { widgetType = "tree_pop" }
		
	- collapsing_header - Collapsible header element
		properties: label
		example: { widgetType = "collapsing_header", label = "Advanced Settings" }

	- begin_group - Start a group of widgets
		properties: id, isHidden
		example: { widgetType = "begin_group", id = "advanced_settings", isHidden = false }

	- end_group - End a group of widgets
		no properties required
		example: { widgetType = "end_group" }

	- begin_rect - Start a rectangle container
		properties: additionalSize, rounding (both optional)
		example: { widgetType = "begin_rect", additionalSize = 12, rounding = 5 }

	- end_rect - End a rectangle container
		properties: additionalSize, rounding (both optional)
		example: { widgetType = "end_rect", additionalSize = 12, rounding = 5 }

	- begin_child_window - Start a scrollable child window
		properties: size, border
		example: { widgetType = "begin_child_window", size = {400, 300}, border = true }

	- end_child_window - End a child window
		no properties required
		example: { widgetType = "end_child_window" }

	4. Layout Widgets:
	- indent - Increase indentation
		properties: width
		example: { widgetType = "indent", width = 20 }

	- unindent - Decrease indentation
		properties: width
		example: { widgetType = "unindent", width = 20 }

	- same_line - Place next widget on same line
		no properties required
		example: { widgetType = "same_line" }

	- new_line - Force next widget to new line
		no properties required
		example: { widgetType = "new_line" }

	- spacing - Add a standard amount of vertical space between widgets
		no properties required
		example: { widgetType = "spacing" }

	- space_vertical - Add a specific amount of vertical space
		properties: space (required, in pixels)
		example: { widgetType = "space_vertical", space = 20 }

	- space_horizontal - Add a specific amount of horizontal space
		properties: space (required, in pixels)
		example: { widgetType = "space_horizontal", space = 50 }

	- set_x - Set the x position of the cursor
		properties: x (required, in pixels)
		example: { widgetType = "set_x", x = 200 }

	- set_y - Set the y position of the cursor
		properties: y (required, in pixels)
		example: { widgetType = "set_y", y = 100 }

	Common Properties:
	- id: Unique identifier for the widget (required for interactive widgets)
	- label: Display text
	- initialValue: Starting value
	- width: Widget width in pixels
	- size: Widget size as {width, height}
	- range: Value limits as {min, max} for numeric widgets
	- speed: Adjustment speed for numeric widgets
	- selections: Array of options for combo widgets
	- isHidden: Boolean to control visibility
	- wrapped: Boolean to enable text wrapping (for text widgets)
	- disabled: Boolean to make the widget grayed out and/or non-interactive
		example: { widgetType = "button", id = "save_button", label = "Save", disabled = true }


]]--

local M = {}

ImGui = {
    Text = 0,
    TextDisabled = 1,
    TextSelectedBg = 47,
    WindowBg = 2,
    ChildBg = 3,
    PopupBg = 4,
    Border = 5,
    BorderShadow = 6,
    FrameBg = 7,
    FrameBgHovered = 8,
    FrameBgActive = 9,
    TitleBg = 10,
    TitleBgActive = 11,
    TitleBgCollapsed = 12,
    MenuBarBg = 13,
    ScrollbarBg = 14,
    ScrollbarGrab = 15,
    ScrollbarGrabHovered = 16,
    ScrollbarGrabActive = 17,
    CheckMark = 18,
    SliderGrab = 19,
    SliderGrabActive = 20,
    Button = 21,
    ButtonHovered = 22,
    ButtonActive = 23,
    Header = 24,
    HeaderHovered = 25,
    HeaderActive = 26,
    Separator = 27,
    SeparatorHovered = 28,
    SeparatorActive = 29,
    ResizeGrip = 30,
    ResizeGripHovered = 31,
    ResizeGripActive = 32,
    Tab = 33,
    TabHovered = 34,
    TabActive = 35,
    TabUnfocused = 36,
    TabUnfocusedActive = 37,
    DockingPreview = 38,
    DockingEmptyBg = 39,
    PlotLines = 40,
    PlotLinesHovered = 41,
    PlotHistogram = 42,
    PlotHistogramHovered = 43,
    TableHeaderBg = 44,
    TableBorderStrong = 45,
    TableBorderLight = 46,
    TableRowBg = 48,
    TableRowBgAlt = 49,
    DragDropTarget = 50,
    NavHighlight = 51,
    NavWindowingHighlight = 52,
    NavWindowingDimBg = 53,
    ModalWindowDimBg = 54,
    COUNT = 55
}

ImGuiWindowFlags = {
    None = 0, -- No flags
    NoTitleBar = 1 << 0, -- Disable title-bar
    NoResize = 1 << 1, -- Disable user resizing with the lower-right grip
    NoMove = 1 << 2, -- Disable user moving the window
    NoScrollbar = 1 << 3, -- Disable scrollbars (window can still scroll programmatically)
    NoScrollWithMouse = 1 << 4, -- Disable user vertically scrolling with the mouse wheel
    NoCollapse = 1 << 5, -- Disable user collapsing window by double-clicking on it
    AlwaysAutoResize = 1 << 6, -- Resize every window to its content every frame
    NoBackground = 1 << 7, -- Disable drawing background color and outside border
    NoSavedSettings = 1 << 8, -- Never load/save settings in the .ini file
    NoMouseInputs = 1 << 9, -- Disable catching mouse events, window becomes a pass-through
    MenuBar = 1 << 10, -- Has a menu-bar
    HorizontalScrollbar = 1 << 11, -- Allow horizontal scrollbar to appear
    NoFocusOnAppearing = 1 << 12, -- Disable taking focus when transitioning from hidden to visible
    NoBringToFrontOnFocus = 1 << 13, -- Disable bringing window to front when taking focus
    AlwaysVerticalScrollbar = 1 << 14, -- Always show vertical scrollbar
    AlwaysHorizontalScrollbar = 1 << 15, -- Always show horizontal scrollbar
    AlwaysUseWindowPadding = 1 << 16, -- Ensure child windows without border use style.WindowPadding
    NoNavInputs = 1 << 18, -- No gamepad/keyboard navigation inputs will affect this window
    NoNavFocus = 1 << 19, -- No focusing toward this window with gamepad/keyboard navigation
    UnsavedDocument = 1 << 20, -- Append '*' to title to indicate an unsaved document
    NoNav = 1 << 18 | 1 << 19, -- Alias for NoNavInputs and NoNavFocus
    NoDecoration = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 5, -- Alias for NoTitleBar, NoResize, NoMove, NoCollapse
    NoInputs = 1 << 9 | 1 << 18 | 1 << 19, -- Alias for NoMouseInputs and NoNav
}

local configValues = {}
local itemMap = {}
local panelList = {}
local layoutDefinitions = {}
local updateFunctions = {}
local createFunctions = {}
local createOrUpdateFunctions = {}
local defaultFilename = "config_default"
local treeInitialized = {}

local defaultPanelList = {}
local framePanelList = {}
local customPanelList = {}

local function doUpdate(panelID, widgetID, value, updateConfigValue, noCallbacks)
	--print("doUpdate called for panelID:", panelID, " widgetID:", widgetID, " value:", tostring(value), " updateConfigValue:", tostring(updateConfigValue), " noCallbacks:", tostring(noCallbacks))
	if panelID ~= nil then
		if updateConfigValue == nil then updateConfigValue = true end
		if updateConfigValue == true then
			if configValues[panelID] == nil then
				configValues[panelID] = {}
				itemMap[widgetID] = panelID
			end
			configValues[panelID][widgetID] = value
		end

		if noCallbacks ~= true then
			local funcList = updateFunctions[widgetID]
			if funcList ~= nil and #funcList > 0 then
				for i = 1, #funcList do
					funcList[i](value)
				end
			end
			funcList = createOrUpdateFunctions[widgetID]
			if funcList ~= nil and #funcList > 0 then
				for i = 1, #funcList do
					funcList[i](value)
				end
			end
		end
		if panelList[panelID] ~= nil then panelList[panelID].isDirty = true end
	else
		print("[configui] panelID is nil in doUpdate")
	end
end

--RRGGBBAA in
local function colorStringToInteger(colorString)
	if colorString == nil then
		return 0
	end
    -- Remove the '#' character 
    local hex = colorString:sub(2)
    local b = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local r = tonumber(hex:sub(5,6), 16)
    local a = tonumber(hex:sub(7,8), 16)

    return (a << 24) | (r << 16) | (g << 8) | b
end

local function getVector2FromArray(arr)
	local vec = UEVR_Vector2f.new()
	if arr == nil then
		vec.x = 0
		vec.y = 0
	elseif #arr < 2 then
		if arr.X ~= nil then
			vec.x = arr.X
			vec.y = arr.Y or 0
		elseif arr.x ~= nil then
			vec.x = arr.x
			vec.y = arr.y or 0
		else
			vec.x = 0
			vec.y = 0
		end
	else
		vec.x = arr[1]
		vec.y = arr[2]
	end
	return vec
end

local function getVector3FromArray(arr)
	if arr == nil then
		return Vector3f.new(0, 0, 0)
	end
	if #arr < 3 then
		if arr.X ~= nil then
			return Vector3f.new(arr.X, arr.Y or 0, arr.Z or 0)
		elseif arr.x ~= nil then
			return Vector3f.new(arr.x, arr.y or 0, arr.z or 0)
		else
			return Vector3f.new(0, 0, 0)
		end
	end
	return Vector3f.new(arr[1], arr[2], arr[3])
end

local function getVector4FromArray(arr)
	if arr == nil then
		return Vector4f.new(0, 0, 0, 0)
	end
	if #arr < 4 then
		if arr.X ~= nil then
			return Vector4f.new(arr.X, arr.Y or 0, arr.Z or 0, arr.W or 0)
		elseif arr.x ~= nil then
			return Vector4f.new(arr.x, arr.y or 0, arr.z or 0, arr.w or 0)
		else
			return Vector4f.new(0, 0, 0, 0)
		end
	end
	return Vector4f.new(arr[1], arr[2], arr[3], arr[4])
end

local function getArrayFromVector2(vec)
	if vec == nil then
		return {0,0}
	end
	return {vec.x, vec.y}
end

local function getArrayFromVector3(vec)
	if vec == nil then
		return {0,0,0}
	end
	return {vec.X, vec.Y, vec.Z}
end

local function getArrayFromVector4(vec)
	if vec == nil then
		return {0, 0, 0, 0}
	end
	return {vec.X, vec.Y, vec.Z, vec.W}
end

local function getCleanValue(value)
	if type(value) == "table" then
		if #value == 0 then
			if value.X ~= nil then
				if value.W ~= nil then
					value = Vector4f.new(value.X, value.Y or 0, value.Z or 0, value.W)
				elseif value.Z ~= nil then
					value = Vector3f.new(value.X, value.Y or 0, value.Z)
				elseif value.Y ~= nil then
					local vec = UEVR_Vector2f.new()
					vec.X = value.X
					vec.Y = value.Y
					value = vec
				end
			elseif value.x ~= nil then
				if value.w ~= nil then
					value = Vector4f.new(value.x, value.y or 0, value.z or 0, value.w)
				elseif value.z ~= nil then
					value = Vector3f.new(value.x, value.y or 0, value.z)
				elseif value.y ~= nil then
					local vec = UEVR_Vector2f.new()
					vec.X = value.x
					vec.Y = value.y
					value = vec
				end
			end
		elseif #value == 2 then
			value = getVector2FromArray(value)
		elseif #value == 3 then
			value = getVector3FromArray(value)
		elseif #value == 4 then
			value = getVector4FromArray(value)
		end
	end
	return value
end

local function drawUI(panelID)
	local treeDepth = 0
	local treeState = {}
	local groupHide = 0
	local isTreeOpen = false

	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.widgetType == "begin_group" and (groupHide > 0 or item.isHidden) then
			groupHide = groupHide + 1
		end
		if groupHide > 0 then goto continue end

		if item.isHidden ~= true and (treeDepth == 0 or treeState[treeDepth] == true or item.widgetType == "tree_node" or item.widgetType == "tree_node_ptr_id" or item.widgetType == "tree_node_str_id" or item.widgetType == "tree_pop") then
			if item.label == "" then item.label = " " end --with an empty label, combos wont open
			if item.disabled == true then
				imgui.begin_disabled()
			end

			if item.id ~= nil and item.id ~= "" then
				imgui.push_id(item.id)
			end

			if item.width ~= nil and item.widgetType ~= "unindent" and item.widgetType ~= "indent" then
				imgui.set_next_item_width(item.width)
			end

			if item.widgetType == "checkbox" then
				local changed, newValue = imgui.checkbox(item.label, configValues[panelID][item.id])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "button" then
				if item.color ~= nil then imgui.push_style_color(ImGui.Button, colorStringToInteger(item.color)) end
				if item.hoveredColor ~= nil then imgui.push_style_color(ImGui.ButtonHovered, colorStringToInteger(item.hoveredColor)) end
				if item.activeColor ~= nil then imgui.push_style_color(ImGui.ButtonActive, colorStringToInteger(item.activeColor)) end
				--imgui.push_style_color(ImGui.Button, colorStringToInteger("#FF00FFFF"))
				local changed, newValue = imgui.button(item.label, item.size)
				if changed then
					doUpdate(panelID, item.id, true, false)
				end
				if item.color ~= nil then imgui.pop_style_color(1) end
				if item.hoveredColor ~= nil then imgui.pop_style_color(1) end
				if item.activeColor ~= nil then imgui.pop_style_color(1) end
			elseif item.widgetType == "small_button" then
				local changed, newValue = imgui.small_button(item.label, item.size)
				if changed then
					doUpdate(panelID, item.id, true, false)
				end
			elseif item.widgetType == "combo" then
				local changed, newValue = imgui.combo(item.label, configValues[panelID][item.id], item.selections)
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "slider_int" then
				local changed, newValue = imgui.slider_int(item.label, configValues[panelID][item.id], item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "slider_float" then
				local changed, newValue = imgui.slider_float(item.label, configValues[panelID][item.id], item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "drag_int" then
				local changed, newValue = imgui.drag_int(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "drag_float" then
				local changed, newValue = imgui.drag_float(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "drag_float2" then
				local changed, newValue = imgui.drag_float2(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "drag_float3" then
				local changed, newValue = imgui.drag_float3(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "drag_float4" then
				local changed, newValue = imgui.drag_float4(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "input_text" then
				local changed, newValue, selectionStart, selectionEnd = imgui.input_text(item.label, configValues[panelID][item.id])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "input_text_multiline" then
				local changed, newValue, selectionStart, selectionEnd = imgui.input_text_multiline(item.label, configValues[panelID][item.id], item.size)
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "color_picker" then
				local changed, newValue = imgui.color_picker(item.label, configValues[panelID][item.id])
				if changed then
					doUpdate(panelID, item.id, newValue)
				end
			elseif item.widgetType == "begin_rect" then
				imgui.begin_rect()
			elseif item.widgetType == "end_rect" then
				imgui.end_rect(item.additionalSize ~= nil and item.additionalSize or 0, item.rounding ~= nil and item.rounding or 0)
			elseif item.widgetType == "begin_group" then
				imgui.begin_group()
			elseif item.widgetType == "end_group" then
				imgui.end_group()
			elseif item.widgetType == "begin_child_window" then
				imgui.begin_child_window(getVector2FromArray(item.size), item.border, item.flags)
			elseif item.widgetType == "end_child_window" then
				imgui.end_child_window()
			elseif item.widgetType == "tree_node" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					if item.color ~= nil then imgui.push_style_color(ImGui.Text, colorStringToInteger(item.color)) end
					treeState[treeDepth] = imgui.tree_node(item.label)
					if item.color ~= nil then imgui.pop_style_color(1) end
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_node_ptr_id" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					treeState[treeDepth] = imgui.tree_node_ptr_id(item.id,item.label)
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_node_str_id" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					treeState[treeDepth] = imgui.tree_node_str_id(item.id,item.label)
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_pop" then
				if treeState[treeDepth] == true then
					imgui.tree_pop()
				end
				treeDepth = treeDepth - 1
			elseif item.widgetType == "collapsing_header" then
				imgui.collapsing_header(item.label)
			elseif item.widgetType == "new_line" then
				imgui.new_line()
			elseif item.widgetType == "spacing" then
				imgui.spacing()
			elseif item.widgetType == "space_vertical" then
				local current = imgui.get_cursor_pos()
				current.y = current.y + item.space
				imgui.set_cursor_pos(current)
			elseif item.widgetType == "space_horizontal" then
				local current = imgui.get_cursor_pos()
				current.x = current.x + item.space
				imgui.set_cursor_pos(current)
			elseif item.widgetType == "set_x" then
				local current = imgui.get_cursor_pos()
				current.x = item.x
				imgui.set_cursor_pos(current)
			elseif item.widgetType == "set_y" then
				local current = imgui.get_cursor_pos()
				current.y = item.y
				imgui.set_cursor_pos(current)
			elseif item.widgetType == "same_line" then
				if item.spacing ~= nil then
					imgui.same_line(item.spacing)
				else
					imgui.same_line()
				end
			-- elseif item.widgetType == "spacing" then
			-- 	if item.spacing ~= nil then
			-- 		imgui.spacing(item.spacing)
			-- 	else
			-- 		imgui.spacing()
			-- 	end
			elseif item.widgetType == "text" then
				imgui.text(item.label_wrapped or item.label)
			elseif item.widgetType == "indent" then
				imgui.indent(item.width)
			elseif item.widgetType == "unindent" then
				imgui.unindent(item.width)
			elseif item.widgetType == "text_colored" then
				imgui.text_colored(item.label_wrapped or item.label, colorStringToInteger(item.color))
			end

			if item.id ~= nil and item.id ~= "" then
				imgui.pop_id()
			end

			if item.disabled == true then
				imgui.end_disabled()
			end
		end
		::continue::

		if item.widgetType == "end_group" then
			if groupHide > 0 then
				groupHide = groupHide - 1
			end
		end
	end
end

local function getDefinitionElement(panelID, id)
	--print(panelID)
	local definition = layoutDefinitions[panelID]
	if definition ~= nil then
		for _, element in ipairs(definition) do
			if element.id == id then
				return element
			end
		end
	end
    return nil -- Return nil if the id is not found
end

local function wrapTextOnWordBoundary(text, maxCharsPerLine)
	if text == nil then text = "" end
 	if maxCharsPerLine == nil then maxCharsPerLine = 73 end
    local wrapped_text = ""
    local current_line_length = 0
    local words = {}

    -- Split the text into words, preserving spaces
    for word in string.gmatch(text .. " ", "([^%s]+%s*)") do
        table.insert(words, word)
    end

    for i, word in ipairs(words) do
        local word_length = string.len(word)

        if current_line_length + word_length > maxCharsPerLine and current_line_length > 0 then
            wrapped_text = wrapped_text .. "\n"
            current_line_length = 0
        end

        wrapped_text = wrapped_text .. word
        current_line_length = current_line_length + word_length
    end

    return wrapped_text
end

function M.updatePanel(panelDefinition)
	local label = panelDefinition["panelLabel"]
	local fileName = panelDefinition["saveFile"]
	if label == nil or label == "" or label == "Script UI" then
		label = "__default__"
		fileName = defaultFilename
	end

	local panelID = panelDefinition["id"]
	if panelID == nil or panelID == "" then
		panelID = fileName
		if panelID == nil or panelID == "" then
			panelID = label
		end
	end

	layoutDefinitions[panelID] = panelDefinition["layout"]

	panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=fileName, isHidden=panelDefinition["isHidden"]}

	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.id ~= nil then
			if item.widgetType == "drag_float2" then
				configValues[panelID][item.id] = getVector2FromArray(item.initialValue)
			elseif item.widgetType == "drag_float3" then
				configValues[panelID][item.id] = getVector3FromArray(item.initialValue)
			elseif item.widgetType == "drag_float4" then
				configValues[panelID][item.id] = getVector4FromArray(item.initialValue)
			elseif item.widgetType == "color_picker" then
				configValues[panelID][item.id] = colorStringToInteger(item.initialValue)
			else
				configValues[panelID][item.id] = item.initialValue
			end
			itemMap[item.id] = panelID
		end
		if item.widgetType == "text" and item.wrapped == true then
			item.label_wrapped = wrapTextOnWordBoundary(item.label, item.textWidth)
		end
	end


	M.load(panelID, fileName)
end

function M.createPanel(panelDefinition)
	local label = panelDefinition["panelLabel"]
	local fileName = panelDefinition["saveFile"]
	if label == nil or label == "" or label == "Script UI" then
		label = "__default__"
		fileName = defaultFilename
	end

	local panelID = panelDefinition["id"]
	if panelID == nil or panelID == "" then
		panelID = fileName
		if panelID == nil or panelID == "" then
			panelID = label
		end
	end

	layoutDefinitions[panelID] = panelDefinition["layout"]

	panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=fileName, isHidden=panelDefinition["isHidden"]}

	--print("[configui] Creating panel", label, fileName)
	if configValues[panelID] == nil then
		configValues[panelID] = {}

		if label == "__default__" then
			--table.insert(defaultPanelList, panelID)
			uevr.sdk.callbacks.on_draw_ui(function()
				drawUI(panelID)
			end)
		elseif panelDefinition["windowed"] == true then
			--table.insert(framePanelList, panelID)
			uevr.sdk.callbacks.on_frame(function()
				if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
					local opened = imgui.begin_window(label, true, panelDefinition["flags"] or ImGuiWindowFlags.None)
					drawUI(panelID)
					imgui.end_window()
					if not opened then
						panelList[panelID]["isHidden"] = true
						panelList[panelID]["userClosed"] = true
					end
				end
				if panelDefinition["stateFollowsParent"] == true and uevr.params.functions.is_drawing_ui ~= nil then
					local isDrawingUI = uevr.params.functions.is_drawing_ui()
					if isDrawingUI and panelList[panelID]["userClosed"] ~= true then
						panelList[panelID]["isHidden"] = false
					end
					if isDrawingUI == false then
						panelList[panelID]["userClosed"] = false
						panelList[panelID]["isHidden"] = true
					end
				end
			end)
		elseif uevr.lua ~= nil then
			--table.insert(customPanelList, panelID)
			if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
				uevr.lua.add_script_panel(label, function()
					drawUI(panelID)
				end)
			end
		end
	end


	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.id ~= nil then
			if item.widgetType == "drag_float2" then
				configValues[panelID][item.id] = getVector2FromArray(item.initialValue)
			elseif item.widgetType == "drag_float3" then
				configValues[panelID][item.id] = getVector3FromArray(item.initialValue)
			elseif item.widgetType == "drag_float4" then
				configValues[panelID][item.id] = getVector4FromArray(item.initialValue)
			elseif item.widgetType == "color_picker" then
				configValues[panelID][item.id] = colorStringToInteger(item.initialValue)
			else
				configValues[panelID][item.id] = item.initialValue
			end
			itemMap[item.id] = panelID
		end
		if item.widgetType == "text" and item.wrapped == true then
			item.label_wrapped = wrapTextOnWordBoundary(item.label, item.textWidth)
		end
	end


	M.load(panelID, fileName)

end

function M.update(configDefinition)

	if configDefinition ~= nil then
		for _, panel in ipairs(configDefinition) do
			M.updatePanel(panel)
		end
	else
		print("[configui] Cant create create UI because no definition provided")
	end

	--Makes sure the default file is loaded if it exists so that dynamic config items can be loaded if necessary
	if configValues[defaultFilename] == nil then
		M.load(defaultFilename, defaultFilename)
	end
end

function M.create(configDefinition)

	if configDefinition ~= nil then
		for _, panel in ipairs(configDefinition) do
			M.createPanel(panel)
		end
	else
		print("[configui] Cant create create UI because no definition provided")
	end

	--Makes sure the default file is loaded if it exists so that dynamic config items can be loaded if necessary
	if configValues[defaultFilename] == nil then
		M.load(defaultFilename, defaultFilename)
	end
end

function M.load(panelID, fileName)
	if configValues[panelID] == nil then
		configValues[panelID] = {}
	end
	if fileName ~= nil and fileName ~= "" and json ~= nil then
		local loadConfig = json.load_file(fileName .. ".json")
		if loadConfig ~= nil then
			for key, val in pairs(loadConfig) do
				-- local item = getDefinitionElement(panelID, key)
				-- print("The item is ", item)
				-- if item ~= nil then
				-- 	if item.widgetType == "drag_float2" then
				-- 		configValues[panelID][key] = getVector2FromArray(val)
				-- 	elseif item.widgetType == "drag_float3" then
				-- 		configValues[panelID][key] = getVector3FromArray(val)
				-- 	elseif item.widgetType == "drag_float4" then
				-- 		configValues[panelID][key] = getVector4FromArray(val)
				-- 	else
				-- 		configValues[panelID][key] = val
				-- 	end
				-- else
				-- 	configValues[panelID][key] = val
				-- end
				configValues[panelID][key] = getCleanValue(val)
				-- if type(val) == "table" then
				-- 	if #val == 2 then
				-- 		configValues[panelID][key] = getVector2FromArray(val)
				-- 	elseif #val == 3 then
				-- 		configValues[panelID][key] = getVector3FromArray(val)
				-- 	elseif #val == 4 then
				-- 		configValues[panelID][key] = getVector4FromArray(val)
				-- 	end
				-- else
				-- 	configValues[panelID][key] = val
				-- end

				itemMap[key] = panelID

			--print("[configui] ", fileName, panelID, key, configValues[panelID][key])
			end
		end
	end

	for widgetID, value in pairs(configValues[panelID]) do
		local funcList = createFunctions[widgetID]
		if funcList ~= nil and #funcList > 0 then
			for i = 1, #funcList do
				funcList[i](value)
			end
		end
		funcList = createOrUpdateFunctions[widgetID]
		if funcList ~= nil and #funcList > 0 then
			for i = 1, #funcList do
				funcList[i](value)
			end
		end
	end
end

--convert userdata types to native lua types for json saving
--this function exists in uevrUtils but since we dont include that here we need to redefine it
function M.getNativeValue(val, useTable)
	local returnValue = val
	if type(val) == "userdata" then
---@diagnostic disable-next-line: undefined-field
		if val.x ~= nil and val.y ~= nil and val.z == nil and val.w == nil then
			returnValue = getArrayFromVector2(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2]}
			end
---@diagnostic disable-next-line: undefined-field
		elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w == nil then
			returnValue = getArrayFromVector3(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2], Z=returnValue[3]}
			end
---@diagnostic disable-next-line: undefined-field
		elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w ~= nil then
			returnValue = getArrayFromVector4(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2], Z=returnValue[3], W=returnValue[4]}
			end
		end
	end
	return returnValue
end

function M.save(panelID)
	local panel = panelList[panelID]
	if panel ~= nil then
		local fileName = panel.fileName
		if fileName ~= nil and fileName ~= "" and json ~= nil then
			local saveConfig = {}
			for key, val in pairs(configValues[panelID]) do
				--print("Saving ", key, val, type(val))
				--things like vector3 need to be converted into a json friendly format
				saveConfig[key] = M.getNativeValue(val)

-- 				if type(val) == "userdata" then
-- 					--print(val.x,val.y,val.z,val.w)
-- ---@diagnostic disable-next-line: undefined-field
-- 					if val.x ~= nil and val.y ~= nil and val.z == nil and val.w == nil then
-- 						saveConfig[key] = getArrayFromVector2(val)
-- ---@diagnostic disable-next-line: undefined-field
-- 					elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w == nil then
-- 						saveConfig[key] = getArrayFromVector3(val)
-- ---@diagnostic disable-next-line: undefined-field
-- 					elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w ~= nil then
-- 						saveConfig[key] = getArrayFromVector4(val)
-- 					end
-- 				else
-- 					saveConfig[key] = val
-- 				end

				-- local item = getDefinitionElement(panelID, key)
				-- if item ~= nil then
				-- 	if item.widgetType == "drag_float2" then
				-- 		saveConfig[key] = getArrayFromVector2(val)
				-- 	elseif item.widgetType == "drag_float3" then
				-- 		saveConfig[key] = getArrayFromVector3(val)
				-- 	elseif item.widgetType == "drag_float4" then
				-- 		saveConfig[key] = getArrayFromVector4(val)
				-- 	else
				-- 		saveConfig[key] = val
				-- 	end
				-- else
				-- 	saveConfig[key] = val
				-- end
			end

			json.dump_file(fileName .. ".json", saveConfig, 4)
		end
	end
end

function M.onUpdate(widgetID, funcDef)
	if updateFunctions[widgetID] == nil then
		updateFunctions[widgetID] = {}
	end
	table.insert(updateFunctions[widgetID], funcDef)
end

function M.onCreate(widgetID, funcDef)
	if createFunctions[widgetID] == nil then
		createFunctions[widgetID] = {}
	end
	table.insert(createFunctions[widgetID], funcDef)
end

function M.onCreateOrUpdate(widgetID, funcDef)
	if createOrUpdateFunctions[widgetID] == nil then
		createOrUpdateFunctions[widgetID] = {}
	end
	table.insert(createOrUpdateFunctions[widgetID], funcDef)
end

function M.getPanelID(widgetID)
	local panelID = itemMap[widgetID]
	if panelID == nil then
		panelID = defaultFilename
		panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=defaultFilename}
	end
	return panelID
end

-- function M.setPanelWindowed(panelID, value)
-- change the configDefinition and then destroy existing an call create to create a new one
-- end

function M.getValue(widgetID)
	local panelID = itemMap[widgetID]
	if panelID == nil then
		panelID = defaultFilename
	end
	--print("[configui] getValue", panelID, widgetID, #configValues or 0, configValues[panelID] and configValues[panelID][widgetID])
	if configValues[panelID] ~= nil then
		return configValues[panelID][widgetID]
	else
		--print("getValue no configValues for panelID",panelID)
	end
	return nil
end

function M.setValue(widgetID, value, noCallbacks)
	-- print("[configui] setValue", widgetID, value, type(value), type(value) == "table" and #value or "none")
	-- local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	-- if item ~= nil then
	-- 	if item.widgetType == "drag_float2" and type(value) == "table" then
	-- 		value = getVector2FromArray(value)
	-- 	elseif item.widgetType == "drag_float3" and type(value) == "table" then
	-- 		value = getVector3FromArray(value)
	-- 	elseif item.widgetType == "drag_float4" and type(value) == "table" then
	-- 		value = getVector4FromArray(value)
	-- 	elseif item.widgetType == "color_picker" and type(value) == "table" then
	-- 		value = colorStringToInteger(value)
	-- 	end
	-- 	doUpdate(M.getPanelID(widgetID), widgetID, value, nil, noCallbacks)
	-- end

	-- if type(value) == "table" then
	-- 	if #value == 0 then
	-- 		if value.X ~= nil then
	-- 			if value.W ~= nil then
	-- 				value = Vector4f.new(value.X, value.Y, value.Z, value.W)
	-- 			elseif value.Z ~= nil then
	-- 				value = Vector3f.new(value.X, value.Y, value.Z)
	-- 			elseif value.Y ~= nil then
	-- 				local vec = UEVR_Vector2f.new()
	-- 				vec.X = value.X
	-- 				vec.Y = value.Y
	-- 				value = vec
	-- 			end
	-- 		end
	-- 	elseif #value == 2 then
	-- 		value = getVector2FromArray(value)
	-- 	elseif #value == 3 then
	-- 		value = getVector3FromArray(value)
	-- 	elseif #value == 4 then
	-- 		value = getVector4FromArray(value)
	-- 	end
	-- end
	doUpdate(M.getPanelID(widgetID), widgetID, getCleanValue(value), nil, noCallbacks)
end

function M.setSelections(widgetID, selections)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.selections = selections
	end
end

function M.hideWidget(widgetID, value)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.isHidden = value
	end
end

function M.setHidden(widgetID, value)
	M.hideWidget(widgetID, value)
end

function M.disableWidget(widgetID, value)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.disabled = value
	end
end

function M.hidePanel(panelID, value)
	panelList[panelID]["isHidden"] = value
end

function M.togglePanel(panelID)
	if panelList[panelID]["isHidden"] == nil then panelList[panelID]["isHidden"] = false end
	panelList[panelID]["isHidden"] = not panelList[panelID]["isHidden"]
end

function M.setLabel(widgetID, newLabel)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		if item.widgetType == "text" and item.wrapped == true then
			item.label_wrapped = wrapTextOnWordBoundary(newLabel, item.textWidth)
		end
		item.label = newLabel
	end
end

function M.setColor(widgetID, colorString)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.color = colorString
	end
end

function M.setHoveredColor(widgetID, colorString)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.hoveredColor = colorString
	end
end

function M.setActiveColor(widgetID, colorString)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.activeColor = colorString
	end
end

function M.applyOptionsToConfigWidgets(configWidgets, options)
	if options ~= nil then
		for index, item in ipairs(options) do
			local id = item.id
			if id ~= nil then
				for j, configItem in ipairs(configWidgets) do
					if configItem.id == id then
						for name, value in pairs(item) do
							configItem[name] = value
						end
					end
				end
			end
		end
	end
	return configWidgets
end

function M.createConfigPanel(label, saveFileName, widgets)
	local configDefinition = {
		{
			panelLabel = label,
			saveFile = saveFileName,
			layout = widgets
		}
	}
	M.create(configDefinition)
end

function M.intToAARRGGBB(num)
    local a = (num >> 24) & 0xFF
    local r = (num >> 16) & 0xFF
    local g = (num >> 8) & 0xFF
    local b = num & 0xFF
    -- Convert from AARRGGBB to BBGGRRAA format
    return string.format("#%02X%02X%02X%02X", b, g, r, a)
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	for panelID, element in pairs(panelList) do
		element.timeSinceLastSave = element.timeSinceLastSave + delta
		--prevent spamming save
		if element.isDirty == true and element.timeSinceLastSave > 1.0 then
			M.save(panelID)
			element.isDirty = false
			element.timeSinceLastSave = 0
        end
    end
end)



-- uevr.sdk.callbacks.on_draw_ui(function()
	-- for index, panelID in ipairs(defaultPanelList) do
		-- drawUI(panelID)
	-- end
-- end)

-- uevr.sdk.callbacks.on_frame(function()
-- --print(#framePanelList)
	-- for index, panelID in ipairs(framePanelList) do
		-- if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
			-- local opened = imgui.begin_window(label, true)
			-- drawUI(panelID)
			-- imgui.end_window()
			-- if not opened then 
				-- panelList[panelID]["isHidden"] = true
			-- end
		-- end
	-- end
-- end)

-- uevr.lua.add_script_panel(label, function()
-- print(#customPanelList)
	-- for index, panelID in ipairs(customPanelList) do
	-- print("here",panelID)
		-- if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
			-- drawUI(panelID)
		-- end
	-- end
-- end)

return M

