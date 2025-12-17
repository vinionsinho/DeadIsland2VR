local uevrUtils = require("libs/uevr_utils")
uevrUtils.setLogLevel(LogLevel.Debug)
uevrUtils.setLogToFile(true)
local configui = require("libs/configui")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local hands = require("libs/hands")
hands.setLogLevel(LogLevel.Debug)
animation.setLogLevel(LogLevel.Debug)

local M = {}

local bones = {}
local meshList = {}
local selectedMeshIndex = 0
local knuckles = {mesh="", names={"left_thumb_knuckle","left_index_knuckle","left_middle_knuckle","left_ring_knuckle","left_pinky_knuckle","right_thumb_knuckle","right_index_knuckle","right_middle_knuckle","right_ring_knuckle","right_pinky_knuckle"}}
local knuckleBoneList = {}
local defaultAnimationRotators = {}
local copyRotators = {}
local copyFingerRotators = {}
local isConfigurationDirty = false
local handConfigurationFileName = "hands_parameters"
local animationPositions = {}
local configuration = {}
local profileNames = {}
local selectedProfileName = ""
local profileMeshNames = {}
local selectedMeshName = ""
local animationNames = {}
local selectedAnimationName = ""
local lastFingerIndex = 1

local ancestorBonesLeft = {}
local ancestorBonesRight = {}

-- local weaponMeshList = {}
-- local weaponMesh = nil
local attachmentLabels = {}
local attachmentIDs = {}

local isTesting = false

local copiedBoneRotation = nil

local currentStep = 1
local totalSteps = 14
local textWidth = 73
local configDefinition = {
	{
		panelLabel = "Hand Config",
		saveFile = "hands_creator_config",
		layout =
		{
			{ widgetType = "text", id = "not_initialized_warning", label = "Hands Creation Tool is not initialized"},
			{
				widgetType = "begin_group",
				id = "Step_1",
				isHidden = true
			},
				{ widgetType = "text", label = "Hands Creation Tool"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, textWidth = textWidth, label = "Create a new configuration or select the one you wish to edit. A game may have multiple characters, each with its own hand configuration"},
				{
					widgetType = "combo",
					id = "hands_profile_list",
					label = "Config",
					selections = {"Create new configuration"},
					initialValue = 1
				},
				{ widgetType = "new_line" },
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_2",
				isHidden = true
			},
				{ widgetType = "text", id = "edit_configuration_title", label = "Selected Configuration"},
				{ widgetType = "indent", width = 60 },
				{ widgetType = "new_line" },
				{
					widgetType = "button",
					id = "edit_config_button",
					label = "Edit Configuration",
					size = {140,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "create_animations_button",
					label = "Create Animations",
					size = {140,24},
				},
				{ widgetType = "unindent", width = 60 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_3",
				isHidden = true
			},
				{ widgetType = "text", id = "hands_profile_title", label = "New Configuration"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "hands_profile_name_instructions", wrapped = true, textWidth = textWidth, label = "Name your configuration. A good choice would be the name of the character this configuration represents."},
				{
					widgetType = "input_text",
					id = "hands_profile_name",
					label = "Config Name",
					initialValue = "Main",
				},
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, textWidth = textWidth, label = "Create a new mesh or select the one you wish to edit. A single hands configuration may contain multiple meshes, for example, when there are separate meshes for arms and gloves."},
				{
					widgetType = "combo",
					id = "hands_profile_mesh_list",
					label = "Mesh",
					selections = {"Create new mesh"},
					initialValue = 1
				},
				{
					widgetType = "new_line"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_4",
				isHidden = true
			},
				{ widgetType = "text", id = "hands_profile_mesh_title", label = "New Mesh"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "hands_profile_mesh_name_instructions", wrapped = true, textWidth = textWidth, label = "Name your mesh. A good choice would be the name of the body part or piece of clothing that this mesh represents such as Arms or Gloves."},
				{
					widgetType = "input_text",
					id = "hands_profile_mesh_name",
					label = "Mesh Name",
					initialValue = "Arms",
				},
				{
					widgetType = "new_line"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_5",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 1 of 4: Find the hands mesh"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "Select the mesh that you wish to use. With you VR helmet on you should see the selected mesh connected to your right hand. If not, try selecting another. You may have to look way above your head to see it."},
				{
					widgetType = "combo",
					id = "character_mesh",
					label = "Character Mesh",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "checkbox",
					id = "include_children_in_mesh_search",
					label = "Include children in Search",
					initialValue = false
				},
				-- {
					-- widgetType = "input_text",
					-- id = "mesh_property_name",
					-- label = "Selected Mesh",
					-- initialValue = "",
					-- isHidden = true
				-- },
				{
					widgetType = "new_line"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_6",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 2 of 4: Set the correct orientation"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "The mesh should now be attached to your hand and facing forward when your hand is pointing forward. If it is not facing forward, adjust the rotation until it is. Usually this is done with the second entry box below"},
				{
					widgetType = "drag_float3",
					id = "mesh_rotation",
					label = "Rotation",
					speed = 45,
					range = {-180, 180},
					initialValue = {0.0, 0.0, 0.0}
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_7",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 3 of 4: (Optional) Fix FOV issues"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "While keeping your hand steady, move your head around and see if the mesh attached to your hand appears to shift slightly, even though your hand is not moving. If this is the case then the game is using some type of FOV adjustment of the mesh that may be needed for the flat game but is a problem in VR. You can enter the FOV parameter name below if this is the case."},
				{
					widgetType = "tree_node",
					id = "more_info_tree_node",
					label = "More Information"
				},
					{ widgetType = "text", wrapped = true, label = "This FOV adjustment will have to be corrected on the mesh before hands will work properly. The Outer Worlds has this issue. If you are running this tutorial in TOW, set the FOV parameter name to ForegroundPriorityEnabled. If you are running under RoboCop and use the parameter UsePanini then this will fix RoboCop. But this string replacement may not work for all games and if that's the case you will need to figure a separate fix for your particular game."},
				{
					widgetType = "tree_pop"
				},
				{
					widgetType = "input_text",
					id = "fov_param_name",
					label = "FOV parameter name",
					initialValue = ""
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_8",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 4 or 4: Select target joints and position hands"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "Find the left and right bones that you wish to target. If you want to see only hands then the bone name will probably be something with 'wrist' in the name. If you want to see the forearm and hand then it will likely have 'lowerarm' in the name"},
				{
					widgetType = "combo",
					id = "left_cutoff_bone",
					label = "Left Hand Target Bone",
					selections = {"None"},
					initialValue = 1
				},
				-- {
					-- widgetType = "input_text",
					-- id = "left_cutoff_bone_name",
					-- label = "Selected Left Bone",
					-- initialValue = "",
					-- isHidden = true
				-- },
				{
					widgetType = "drag_float3",
					id = "left_hand_rotation",
					label = "Rotation",
					speed = 5,
					range = {-180, 180},
					initialValue = {0.0, 0.0, 0.0},
					isHidden = true
				},
				{
					widgetType = "drag_float3",
					id = "left_hand_location",
					label = "Location",
					speed = 0.1,
					range = {-100, 100},
					initialValue = {0.0, 0.0, 0.0},
					isHidden = true
				},
				{
					widgetType = "drag_float3",
					id = "left_hand_scale",
					label = "Scale",
					speed = 0.1,
					range = {0, 10},
					initialValue = {1.0, 1.0, 1.0},
					isHidden = true
				},
				{
					widgetType = "combo",
					id = "right_cutoff_bone",
					label = "Right Hand Target Bone",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "input_text",
					id = "right_cutoff_bone_name",
					label = "Selected Right Bone",
					initialValue = "",
					isHidden = true
				},
				{
					widgetType = "drag_float3",
					id = "right_hand_rotation",
					label = "Rotation",
					speed = 5,
					range = {-180, 180},
					initialValue = {0.0, 0.0, 0.0},
					isHidden = true
				},
				{
					widgetType = "drag_float3",
					id = "right_hand_location",
					label = "Location",
					speed = 0.1,
					range = {-100, 100},
					initialValue = {0.0, 0.0, 0.0},
					isHidden = true
				},
				{
					widgetType = "drag_float3",
					id = "right_hand_scale",
					label = "Scale",
					speed = 0.1,
					range = {0, 10},
					initialValue = {1.0, 1.0, 1.0},
					isHidden = true
				},
				{
					widgetType = "tree_node",
					id = "advanced_tree_node",
					label = "Advanced"
				},
--					{ widgetType = "text", wrapped = true, label = "Adjust all child bones"},
					{ widgetType = "begin_group", id = "advanced_child_bone_group", isHidden = false }, { widgetType = "text", label = "Adjust Individual Child Bone Transforms" }, { widgetType = "begin_rect", },
						{
							widgetType = "checkbox",
							id = "use_default_pose",
							label = "Use Default Pose",
							initialValue = true
						},
						{
							widgetType = "combo",
							id = "cutoff_children_hand_picker",
							label = "Hand",
							selections = {"Left", "Right"},
							initialValue = 1,
							width = 130
						},
						{ widgetType = "same_line" },
						{ widgetType = "text", label = "    "},
						{ widgetType = "same_line" },
						{
							widgetType = "combo",
							id = "cutoff_children_bone_picker",
							label = "Child Bone",
							selections = {"None"},
							initialValue = 1,
							width = 130
						},
						{
							widgetType = "drag_float3",
							id = "cutoff_children_rotation",
							label = "Rotation",
							speed = 1,
							range = {-180, 180},
							initialValue = {0.0, 0.0, 0.0},
							isHidden = true,
							width = 270
						},
						{ widgetType = "same_line" },
						{
							widgetType = "button",
							id = "cutoff_children_zero_current_button",
							label = "Zero",
							size = {40,24},
						},
						{ widgetType = "same_line" },
						{
							widgetType = "button",
							id = "cutoff_children_copy_current_button",
							label = "Copy",
							size = {40,24},
						},
						{ widgetType = "same_line" },
						{
							widgetType = "button",
							id = "cutoff_children_paste_current_button",
							label = "Paste",
							size = {40,24},
						},
						{
							widgetType = "drag_float3",
							id = "cutoff_children_location",
							label = "Location",
							speed = 0.05,
							range = {-50, 50},
							initialValue = {0.0, 0.0, 0.0},
							isHidden = true,
							width = 270
						},
						{ widgetType = "indent", width = 30 },
						{
							widgetType = "button",
							id = "cutoff_children_capture_hand_button",
							label = "Capture Hand Transforms",
							size = {180,24},
						},
						{ widgetType = "same_line" },
						{
							widgetType = "button",
							id = "cutoff_children_revert_all_button",
							label = "Revert All Child Transforms",
							size = {180,24},
						},
						--{ widgetType = "unindent", width = 120 },
					{ widgetType = "end_rect", additionalSize = 12, rounding = 5 },  { widgetType = "end_group", },
					{ widgetType = "new_line" },
					{ widgetType = "begin_group", id = "advanced_animation_settings_group", isHidden = false }, { widgetType = "text", label = "Animations" }, { widgetType = "begin_rect", },
						{
							widgetType = "checkbox",
							id = "optimize_animations",
							label = "Optimize Animations",
							initialValue = true
						},
						{
							widgetType = "combo",
							id = "optimize_animations_root_bone_left",
							label = "Optimization Root Bone Left",
							selections = {"None"},
							initialValue = 1,
							width = 130
						},
						{
							widgetType = "combo",
							id = "optimize_animations_root_bone_right",
							label = "Optimization Root Bone Right",
							selections = {"None"},
							initialValue = 1,
							width = 130
						},
					{ widgetType = "end_rect", additionalSize = 12, rounding = 5 },  { widgetType = "end_group", },
				{
					widgetType = "tree_pop"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_9",
				isHidden = true
			},
				{ widgetType = "text", label = "Finshed"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, textWidth = textWidth, label = "Congratualtions, the game now has hands! If you don't want the fingers of the hands to animate then there is nothing else to do. You can press 'Generate Code' to put the code required for showing hands in your scripts directory. You can press 'Show Code' to see an example of how to use hands in your own code. If you do want the fingers to animate, press 'Create Animations'"},
				{ widgetType = "new_line" },
				{
					widgetType = "button",
					id = "generate_code_button",
					label = "Generate code",
					size = {140,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "show_code_button",
					label = "Show code",
					size = {140,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "create_animations_button_2",
					label = "Create Animations",
					size = {140,24},
				},
				-- { widgetType = "same_line" },
				-- {
					-- widgetType = "button",
					-- id = "exit_button_config",
					-- label = "Done",
					-- size = {140,24},
				-- },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "generate_code_instructions", isHidden = true, wrapped = true, textWidth = textWidth, label = "A file named hands.lua has been created in the scripts directory. Include the '/scipts/lib' folder and its contents, '/scripts/hands.lua' and '/data/hands_parameters.json' in your profile to add hands to your game. No other files are needed."},
				{ widgetType = "new_line" },
				{
					widgetType = "input_text_multiline",
					id = "code_text",
					label = "",
					initialValue = "",
					isHidden = true,
					size = {450, 230} -- optional, will default to full size without it
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_10",
				isHidden = true
			},
				{ widgetType = "text", id = "start_animation_title", label = "Animations"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "animation_instructions", wrapped = true, textWidth = textWidth, label = "Select an existing animation to edit or create a new one."},
				{
					widgetType = "combo",
					id = "animations_list",
					label = "Animation",
					selections = {"Create new animation"},
					initialValue = 1
				},
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "animation_mesh_instructions", wrapped = true, textWidth = textWidth, label = "Select the mesh you wish to use for animations."},
				{
					widgetType = "combo",
					id = "animation_hands_profile_mesh_list",
					label = "Mesh",
					selections = {""},
					initialValue = 1
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_11",
				isHidden = true
			},
				{ widgetType = "text", id = "new_animation_title", label = "New Animation"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "new_animation_instructions", wrapped = true, textWidth = textWidth, label = "Name your animation. Often a single animation profile can be applied to all of the meshes in the game but sometimes each mesh requires a different animation."},
				{
					widgetType = "input_text",
					id = "animation_name",
					label = "Animation Name",
					initialValue = "Shared",
				},
				{
					widgetType = "new_line"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_12",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 1 of 2: Locate knuckle bones"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "Find the knuckle bones of each finger. The knuckle bones will be named like 'RightHandThumb1_JNT' or 'thumb_01_r' and should be the ones with a '1' in the name for that finger"},
				{
					widgetType = "tree_node",
					id = "search_tree_node",
					label = "Search Pattern"
				},
					{ widgetType = "text", label = "A search pattern can be used to find all the bones at once."},
					{ widgetType = "text", label = "(Hh) (hh) (HH) (H) (h) - hand, (Ff) (FF) (ff) - finger, (i) (ii) (iii) - number of digits in index"},
					{ widgetType = "text", label = "Example:"},
					{ widgetType = "text", label = "(ff)_(ii)_(h) will find thumb_01_r, etc"},
					{ widgetType = "text", label = "(Hh)Hand(Ff)(i)_JNT will find RightHandThumb1_JNT, etc"},
					{
						widgetType = "input_text",
						id = "knuckle_bone_search_pattern",
						label = "Pattern",
						initialValue = "",
						isHidden = false
					},
				{
					widgetType = "tree_pop"
				},
				{ widgetType = "new_line" },
				{
					widgetType = "combo",
					id = "left_thumb_knuckle",
					label = "Left Thumb",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "left_index_knuckle",
					label = "Left Index",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "left_middle_knuckle",
					label = "Left Middle",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "left_ring_knuckle",
					label = "Left Ring",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "left_pinky_knuckle",
					label = "Left Pinky",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "right_thumb_knuckle",
					label = "Right Thumb",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "right_index_knuckle",
					label = "Right Index",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "right_middle_knuckle",
					label = "Right Middle",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "right_ring_knuckle",
					label = "Right Ring",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "combo",
					id = "right_pinky_knuckle",
					label = "Right Pinky",
					selections = {"None"},
					initialValue = 1
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_13",
				isHidden = true
			},
				{ widgetType = "text", label = "Step 2 of 2: Create hand animations"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "While wearing your VR helmet and watching the hands, for each animation type and state, rotate the joints of each finger using the sliders until the hands simulate that type and state."},
				{ widgetType = "new_line" },
				{
					widgetType = "tree_node",
					id = "weapon_tree_node",
					label = "Attachments"
				},
					{ widgetType = "text", wrapped = true, label = "In the UEVR UObjectHook UI, find your attachment (weapon) mesh and attach it to your controller by pressing 'Attach Right' or 'Attach Left'. You can then add an attachment name below and create specific grips for that attachment."},
					{
						widgetType = "input_text",
						id = "new_attachment_name",
						label = " ",
						initialValue = "",
					},
					{ widgetType = "same_line" },
					{
						widgetType = "button",
						id = "add_attachment_button",
						label = "Add Attachment",
						size = {120,24},
					},
					{ widgetType = "text_colored", id = "new_attachment_error", isHidden = true, wrapped = true, color = "#FF0000FF", label = "Please type the attachment name to be added."},

					-- {
						-- widgetType = "combo",
						-- id = "weapon_mesh",
						-- label = "Weapon Mesh",
						-- selections = {"None"},
						-- initialValue = 1
					-- },
					-- { widgetType = "same_line" },
					-- {
						-- widgetType = "button",
						-- id = "refresh_weapon_mesh_button",
						-- label = "Refresh",
						-- size = {50,24},
					-- },
					-- {
						-- widgetType = "drag_float3",
						-- id = "weapon_offset_rotation",
						-- label = "Rotation",
						-- speed = 1,
						-- range = {-360, 360},
						-- initialValue = {0.0, 0.0, 0.0},
					-- },
					-- {
						-- widgetType = "drag_float3",
						-- id = "weapon_offset_location",
						-- label = "Location",
						-- speed = 0.05,
						-- range = {-50, 50},
						-- initialValue = {0.0, 0.0, 0.0},
					-- },
				{
					widgetType = "tree_pop"
				},
				{ widgetType = "new_line" },
				{
					widgetType = "combo",
					id = "animation_hand",
					label = "Hand",
					selections = {"Left","Right","Both"},
					initialValue = 3,
					width = 70
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "    "},
				{ widgetType = "same_line" },
				{
					widgetType = "combo",
					id = "animation_type",
					label = "Type",
					selections = {"Grip", "Trigger", "Thumb", "Attachment Grip", "Attachment Trigger"},
					initialValue = 1,
					width = 150
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "    "},
				{ widgetType = "same_line" },
				{
					widgetType = "combo",
					id = "animation_state",
					label = "State",
					selections = {"On", "Off"},
					initialValue = 1,
					width = 50
				},
				{
					widgetType = "combo",
					id = "attachments_list",
					label = "Attachment",
					selections = {"Default"},
					initialValue = 1
				},

				-- { widgetType = "same_line" },
				-- { widgetType = "text", label = "    "},
				-- { widgetType = "same_line" },
				-- {
					-- widgetType = "combo",
					-- id = "animation_hand",
					-- label = "Hand",
					-- selections = {"Left","Right","Both"},
					-- initialValue = 3,
					-- width = 100
				-- },
				{ widgetType = "text", wrapped = true, textWidth = textWidth, id = "animation_description", label = ""},
				{
					widgetType = "new_line"
				},
				{
					widgetType = "combo",
					id = "animation_finger",
					label = "Finger",
					selections = {"Thumb","Index","Middle","Ring","Pinky"},
					initialValue = 1,
					width = 100
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "  "},
				{ widgetType = "same_line" },
				{
					widgetType = "combo",
					id = "animation_joint",
					label = "Joint",
					selections = {"1 (Knuckle)", "2", "3"},
					initialValue = 1,
					width = 100
				},
				{
					widgetType = "slider_float",
					id = "animation_finger_bone_pitch",
					label = "Pitch",
					range = {-180, 180},
					initialValue = 0
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "  "},
				{ widgetType = "same_line" },
				{
					widgetType = "checkbox",
					id = "animation_finger_bone_pitch_mirror",
					label = "Mirror",
					initialValue = false
				},
				{
					widgetType = "slider_float",
					id = "animation_finger_bone_yaw",
					label = "Yaw",
					range = {-180, 180},
					initialValue = 0
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "   "},
				{ widgetType = "same_line" },
				{
					widgetType = "checkbox",
					id = "animation_finger_bone_yaw_mirror",
					label = "Mirror",
					initialValue = false
				},
				{
					widgetType = "slider_float",
					id = "animation_finger_bone_roll",
					label = "Roll",
					range = {-180, 180},
					initialValue = 0
				},
				{ widgetType = "same_line" },
				{ widgetType = "text", label = "    "},
				{ widgetType = "same_line" },
				{
					widgetType = "checkbox",
					id = "animation_finger_bone_roll_mirror",
					label = "Mirror",
					initialValue = false
				},
				{
					widgetType = "new_line"
				},
				{
					widgetType = "button",
					id = "copy_finger_button",
					label = "Copy Finger",
					size = {90,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "paste_finger_button",
					label = "Paste Finger",
					size = {90,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "revert_finger_button",
					label = "Set Finger to Default",
					size = {140,24},
				},
				{
					widgetType = "button",
					id = "copy_hand_button",
					label = "Copy Hand",
					size = {90,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "paste_hand_button",
					label = "Paste Hand",
					size = {90,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "revert_hand_button",
					label = "Set Hand to Default",
					size = {140,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "capture_hand_button",
					label = "Get Hand from Current Mesh",
					size = {180,24},
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "step_testing",
				isHidden = true
			},
				{ widgetType = "text", label = "Testing"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "Close the UEVR window and try it out."},
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, label = "You can simulate the animation as if you are left handed and/or holding a weapon."},
				{
					widgetType = "checkbox",
					id = "animation_test_active_weapon_mode",
					label = "Holding Weapon",
					initialValue = false
				},
				{
					widgetType = "checkbox",
					id = "animation_test_left_handed_mode",
					label = "Left Handed",
					initialValue = false
				},
				{
					widgetType = "new_line"
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "begin_group",
				id = "Step_14",
				isHidden = true
			},
				{ widgetType = "text", label = "Finshed"},
				{ widgetType = "indent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "text", wrapped = true, textWidth = textWidth, label = "Congratualtions, the game now has hands with animated fingers! You can press 'Generate Code' to put the code required for showing hands in your scripts directory. You can press 'Show Code' to see an example of how to use hands in your own code."},
				{ widgetType = "new_line" },
				{ widgetType = "indent", width = 60 },
				{
					widgetType = "button",
					id = "generate_code_button_2",
					label = "Generate code",
					size = {140,24},
				},
				{ widgetType = "same_line" },
				{
					widgetType = "button",
					id = "show_code_button_2",
					label = "Show code",
					size = {140,24},
				},
				-- { widgetType = "same_line" },
				-- {
					-- widgetType = "button",
					-- id = "exit_button_config_2",
					-- label = "Done",
					-- size = {140,24},
				-- },
				{ widgetType = "unindent", width = 60 },
				{ widgetType = "new_line" },
				{ widgetType = "text", id = "generate_code_instructions_2", isHidden = true, wrapped = true, textWidth = textWidth, label = "A file named hands.lua has been created in the scripts directory. Include the '/scipts/lib' folder and its contents, '/scripts/hands.lua' and '/data/hands_parameters.json' in your profile to add hands to your game. No other files are needed."},
				{ widgetType = "new_line" },
				{
					widgetType = "input_text_multiline",
					id = "code_text_2",
					label = "",
					initialValue = "",
					isHidden = true,
					size = {450, 230} -- optional, will default to full size without it
				},
				{ widgetType = "unindent", width = 20 },
			{
				widgetType = "end_group",
			},
			{
				widgetType = "new_line"
			},
			{
				widgetType = "new_line"
			},
			{
				widgetType = "button",
				id = "exit_button",
				label = "Exit Animations",
				size = {120,24},
				isHidden = true,
			},
			{ widgetType = "same_line" },
			{
				widgetType = "button",
				id = "prev_button",
				label = "Previous Step",
				size = {120,24},
				isHidden = true,
			},
			{ widgetType = "same_line" },
			{
				widgetType = "button",
				id = "next_button",
				label = "Next Step",
				size = {120,24},
				disabled = false,
				isHidden = true,
			},
			{ widgetType = "same_line" },
			{
				widgetType = "button",
				id = "done_button",
				label = "Done",
				size = {120,24},
				isHidden = true,
			},
			{ widgetType = "same_line" },
			{
				widgetType = "button",
				id = "test_button",
				label = "Test",
				size = {120,24},
				isHidden = true,
			},
			{ widgetType = "data", id="animation_data", initialValue = {} },
			-- {
				-- widgetType = "tree_pop"
			-- },

		}
	},
}
configui.create(configDefinition)

local function updateSteps(direction)
	local previousStep = currentStep
	currentStep = currentStep + direction
	if currentStep < 1 then
		currentStep = 1
	end
	if currentStep > totalSteps then
		currentStep = totalSteps
	end

	configui.hideWidget("next_button", currentStep == totalSteps)
	configui.hideWidget("prev_button", currentStep == 1)

	for i = 1, totalSteps do
		configui.hideWidget("Step_" .. i, currentStep ~= i)
	end

	configui.hideWidget("exit_button", true)
	M.updateCurrentStep(previousStep, currentStep)

end


local function updateAttachmentListVisibility()
	configui.setHidden("attachments_list", #attachmentLabels == 1 or (configui.getValue("animation_type") ~= 4 and configui.getValue("animation_type") ~= 5))
end

local function updateAttachmentListUI()
	attachmentLabels = {}
	attachmentIDs = {}
	if configuration ~= nil and configuration["attachments"] ~= nil then
		for id, data in pairs(configuration["attachments"]) do
			table.insert(attachmentLabels, data["label"])
			table.insert(attachmentIDs, id)
		end
	end
	table.insert(attachmentLabels, 1, "Default")
	table.insert(attachmentIDs, 1, "")

	configui.setSelections("attachments_list", attachmentLabels)
	updateAttachmentListVisibility()
end

local function getFingerIndexesForCurrentAnimationType()
	local typeIndex = configui.getValue("animation_type")
	local indexes = {
		{1,3,4,5},
		{2},
		{1},
		{1,3,4,5},
		{2}
	}
	return indexes[typeIndex]
end

local function getFingerNamesForCurrentAnimationType()
	local selections = {"Thumb","Index","Middle","Ring","Pinky"}
	local names = {}
	local arr = getFingerIndexesForCurrentAnimationType()
	if arr ~= nil then
		for i = 1, #arr do
			table.insert(names, selections[arr[i]])
		end
	end
	return names

	-- local names = {
		-- {"Thumb","Middle","Ring","Pinky"},
		-- {"Index"},
		-- {"Thumb"},
		-- {"Thumb","Middle","Ring","Pinky"},
		-- {"Index"}
	-- }
	-- return names[typeIndex]
end

local function getFingerIndexForCurrentAnimationType()
	local selectedFingerIndex = configui.getValue("animation_finger")
	local indexes = getFingerIndexesForCurrentAnimationType()
	return indexes[selectedFingerIndex]
end

local function getSelectionIndexForCurrentAnimationType(fingerIndex)
	local indexes = getFingerIndexesForCurrentAnimationType()
	for i = 1, #indexes do
		if indexes[i] == fingerIndex then
			return i
		end
	end
	return 1
end

--called when hand or finger or joint change occurs
local function updateBoneRotationUI()
	local hand = Handed.Left
	local fingerIndexOffset = 0
	if configui.getValue("animation_hand") == 2 then
		hand = Handed.Right
		fingerIndexOffset = 5
	end
	local component = hands.getHandComponent(hand)
	if component ~= nil then
		local fingerIndex = getFingerIndexForCurrentAnimationType() + fingerIndexOffset --configui.getValue("animation_finger") + fingerIndexOffset
		local jointIndex = configui.getValue("animation_joint")
		local rotator = animation.getBoneRotator(component, knuckleBoneList, fingerIndex, jointIndex)
		if rotator ~= nil then
			configui.setValue("animation_finger_bone_pitch", rotator.Pitch, true)
			configui.setValue("animation_finger_bone_yaw", rotator.Yaw, true)
			configui.setValue("animation_finger_bone_roll", rotator.Roll, true)
		end
	end
end

local function getRelevantBonesForAnimationType(handIndex, typeIndex)
	local index = (handIndex * 5) + 1
	if typeIndex == 1 then
		return {knuckleBoneList[index + 0], knuckleBoneList[index + 2], knuckleBoneList[index + 3], knuckleBoneList[index + 4]}
	elseif typeIndex == 2 then
		return {knuckleBoneList[index + 1]}
	elseif typeIndex == 3 then
		return {knuckleBoneList[index + 0]}
	elseif typeIndex == 4 then
		return {knuckleBoneList[index + 0], knuckleBoneList[index + 2], knuckleBoneList[index + 3], knuckleBoneList[index + 4]}
	elseif typeIndex == 5 then
		return {knuckleBoneList[index + 1]}
	end
end

local function getAttachmentExtension(typeIndex, prepend)
	local attachmentExt = ""
	if prepend == nil then prepend = "_" end
	local selectedAttachment = configui.getValue("attachments_list")
	if selectedAttachment ~= 1 and (typeIndex == 4 or typeIndex == 5) then
		attachmentExt = prepend .. attachmentIDs[selectedAttachment]
	end
	return attachmentExt
end

--update the structure that holds all current rotators for each hand state (what hand_animations.lua does)
local function updateAnimationsDefinition(handIndex, typeIndex, stateIndex)
	if handIndex == nil then handIndex = configui.getValue("animation_hand") end
	if typeIndex == nil then typeIndex = configui.getValue("animation_type") end
	if stateIndex == nil then stateIndex = configui.getValue("animation_state") end
	local typeText = {"grip", "trigger", "thumb", "grip_weapon", "trigger_weapon"}
	local stateText = {"on", "off"}
	local attachmentExt = getAttachmentExtension(typeIndex)
	if handIndex == 1 or handIndex == 3 then
		local handStr = "left"
		local typeStr = handStr .. "_" .. typeText[typeIndex] .. attachmentExt
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			if animationPositions[typeStr] == nil then animationPositions[typeStr] = {} end
			animationPositions[typeStr][stateText[stateIndex]] = animation.getBoneTransforms(component, getRelevantBonesForAnimationType(Handed.Left, typeIndex) , true, false, false)
			--animationPositions[typeStr][stateText[stateIndex]] = animation.getBoneTransforms(component, uevrUtils.getArrayRange(knuckleBoneList, 1, 5) , true, false, false)
		end
	end
	if handIndex == 2 or handIndex == 3 then
		local handStr = "right"
		local typeStr = handStr .. "_" .. typeText[typeIndex] .. attachmentExt
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			if animationPositions[typeStr] == nil then animationPositions[typeStr] = {} end
			animationPositions[typeStr][stateText[stateIndex]] = animation.getBoneTransforms(component, getRelevantBonesForAnimationType(Handed.Right, typeIndex) , true, false, false)
			--animationPositions[typeStr][stateText[stateIndex]] = animation.getBoneTransforms(component, uevrUtils.getArrayRange(knuckleBoneList, 6, 10) , true, false, false)
--json.dump_file("debug.json", animationPositions[typeStr][stateText[stateIndex]], 4)
		end
	end

	configuration["animations"][selectedAnimationName]["positions"] = animationPositions
	--configui.setValue("animation_data", animations)

	isConfigurationDirty = true

end

local function createHands()
	if isTesting then
		hands.createFromConfig(configuration, selectedProfileName, selectedAnimationName)
	else
		hands.createFromConfig(configuration, selectedProfileName)

		-- --class UStaticMeshSocket* FindSocket(FName InSocketName)
		-- local sphere = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
		-- local scale = 0.02
		-- uevrUtils.set_component_relative_transform(sphere, nil, nil, {X=scale, Y=scale, Z=scale})
		-- sphere:K2_AttachTo(hands.getHandComponent(Handed.Right), uevrUtils.fname_from_string("items_hand_r") , 0, false) --items_hand_r "items_R"
		-- local meshComponent = getMeshComponent()
		-- if meshComponent ~= nil then
			-- local sphere = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			-- uevrUtils.set_component_relative_transform(sphere, nil, nil, {X=scale, Y=scale, Z=scale})
			-- sphere:K2_AttachTo(meshComponent, uevrUtils.fname_from_string("items_R") , 0, false) --items_hand_r
		-- end
	end
	--attachWeapon(weaponMesh)
end

local function getMeshComponent()
	if configuration ~= nil and configuration["profiles"] ~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		local meshPropertyName = configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"] --configui.getValue("mesh_property_name")
		if meshPropertyName ~= "" then
			return uevrUtils.getObjectFromDescriptor(meshPropertyName)
		end
		-- local property, childName = uevrUtils.splitOnLastPeriod(meshPropertyName)
			-- if childName ~= nil then
				-- return uevrUtils.getChildComponent(pawn[property], childName) 
			-- else
				-- return pawn[property]
			-- end
		-- end
	end
	return nil
end

local handsWereCreated = false
local function updateHands()
	hands.destroyHands()
	if not hands.exists() then
		if currentStep > 7 then
			createHands()
		else
			local rot = configui.getValue("mesh_rotation")
			if rot ~= nil then
				hands.setOffset({X=0, Y=0, Z=0, Pitch=rot.X, Yaw=rot.Y, Roll=rot.Z})
			end
			hands.debug(getMeshComponent(), nil, nil, true)

			local fovParam = configui.getValue("fov_param_name")
			if fovParam ~= nil and fovParam ~= "" then
				uevrUtils.fixMeshFOV(hands.getHandComponent(Handed.Right), fovParam, 0.0, true, true, false)
			end
		end
		handsWereCreated = true
	end
end

local function captureAnimationFromMesh()
	local meshComponent = getMeshComponent()
	if meshComponent ~= nil then
		local tempPoseableMesh = uevrUtils.createPoseableMeshFromSkeletalMesh(meshComponent)
		if tempPoseableMesh ~= nil then
			for hand = Handed.Left, Handed.Right do
				if configui.getValue("animation_hand") == (hand + 1) or configui.getValue("animation_hand") == 3 then
					local component = hands.getHandComponent(hand)
					if component ~= nil then
						local minBoneIndex = (hand == Handed.Left and 1 or 6)
						local maxBoneIndex = (hand == Handed.Left and 5 or 10)
						local handStr = (hand == Handed.Left and "left_hand" or "right_hand")
						local boneList = uevrUtils.getArrayRange(knuckleBoneList, minBoneIndex, maxBoneIndex)
						for j = 1, #boneList do
							for i = 1 , 3 do
								local fName = tempPoseableMesh:GetBoneName(boneList[j] + i - 1)
								local rotation, location, scale = animation.getBoneSpaceLocalTransform(tempPoseableMesh, fName, 0)
								animation.setBoneSpaceLocalRotator(component, fName, rotation)
								--captured animation may difer from assigned hand pose because animators will sometimes
								--change bone locations. This does not happen in real life so it is not currently supported
								--animation.setBoneSpaceLocalLocation(component, fName, location)
							end
						end
					end
				-- json.dump_file("debug.json", boneRotators, 4)
				end
			end
			uevrUtils.destroyComponent(tempPoseableMesh, true, true)
		end
--		FTransform meshComponent:GetDeltaTransformFromRefPose(FName BoneName, FName BaseName);
	end

	updateBoneRotationUI()
	updateAnimationsDefinition()
end

local function getHandRotatorsArray(component, knuckleBoneList)
	local boneRotators = {}
	for j = 1, #knuckleBoneList do
		for index = 1 , 3 do
			local fName = component:GetBoneName(knuckleBoneList[j] + index - 1)
			local rotation, location, scale = animation.getBoneSpaceLocalTransform(component, fName, 0)
			if rotation ~= nil then
				table.insert(boneRotators, {rotation.Pitch, rotation.Yaw, rotation.Roll})
			end
		end
	end
		-- json.dump_file("debug.json", boneRotators, 4)
	return boneRotators
end

local function convertHandRotatorsArrayToTable(component, knuckleBoneList, array)
	local boneRotators = {}
	local index = 1
	for j = 1, #knuckleBoneList do
		for i = 1 , 3 do
			local rotation = array[index]
			index = index + 1
			local fName = component:GetBoneName(knuckleBoneList[j] + i - 1)
			boneRotators[fName:to_string()] = rotation
		end
	end
	return boneRotators
end

local function copyHandAnimation()
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			copyRotators["hand"] = Handed.Left
			copyRotators["rotators"] = getHandRotatorsArray(component, uevrUtils.getArrayRange(knuckleBoneList, 1, 5))
		end
	else
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			copyRotators["hand"] = Handed.Right
			copyRotators["rotators"] = getHandRotatorsArray(component, uevrUtils.getArrayRange(knuckleBoneList, 6, 10))
		end
	end
end

local function pasteHandAnimation()
	local mirrorPitch = configui.getValue("animation_finger_bone_pitch_mirror")
	local mirrorYaw = configui.getValue("animation_finger_bone_yaw_mirror")
	local mirrorRoll = configui.getValue("animation_finger_bone_roll_mirror")
	--load existing animation from animations
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		if copyRotators["hand"] == Handed.Left then
			mirrorPitch = false
			mirrorYaw = false
			mirrorRoll = false
		end
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			animation.doAnimate(convertHandRotatorsArrayToTable(component, uevrUtils.getArrayRange(knuckleBoneList, 1, 5), copyRotators["rotators"]), component, mirrorPitch, mirrorYaw, mirrorRoll)
		end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		if copyRotators["hand"] == Handed.Right then
			mirrorPitch = false
			mirrorYaw = false
			mirrorRoll = false
		end
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			animation.doAnimate(convertHandRotatorsArrayToTable(component, uevrUtils.getArrayRange(knuckleBoneList, 6, 10), copyRotators["rotators"]), component, mirrorPitch, mirrorYaw, mirrorRoll)
		end
	end

	updateBoneRotationUI()
	updateAnimationsDefinition()
end

local function copyFingerAnimation()
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() --configui.getValue("animation_finger")
			copyFingerRotators["hand"] = Handed.Left
			copyFingerRotators["rotators"] = getHandRotatorsArray(component, uevrUtils.getArrayRange(knuckleBoneList, fingerIndex, fingerIndex))
		end
	else
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() + 5 --configui.getValue("animation_finger") + 5
			copyFingerRotators["hand"] = Handed.Right
			copyFingerRotators["rotators"] = getHandRotatorsArray(component, uevrUtils.getArrayRange(knuckleBoneList, fingerIndex, fingerIndex))
		end
	end
end

local function pasteFingerAnimation()
	local mirrorPitch = configui.getValue("animation_finger_bone_pitch_mirror")
	local mirrorYaw = configui.getValue("animation_finger_bone_yaw_mirror")
	local mirrorRoll = configui.getValue("animation_finger_bone_roll_mirror")
	--load existing animation from animations
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		if copyFingerRotators["hand"] == Handed.Left then
			mirrorPitch = false
			mirrorYaw = false
			mirrorRoll = false
		end
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() --configui.getValue("animation_finger")
			animation.doAnimate(convertHandRotatorsArrayToTable(component, uevrUtils.getArrayRange(knuckleBoneList, fingerIndex, fingerIndex), copyFingerRotators["rotators"]), component, mirrorPitch, mirrorYaw, mirrorRoll)
		end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		if copyFingerRotators["hand"] == Handed.Right then
			mirrorPitch = false
			mirrorYaw = false
			mirrorRoll = false
		end
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() + 5 --configui.getValue("animation_finger") + 5
			animation.doAnimate(convertHandRotatorsArrayToTable(component, uevrUtils.getArrayRange(knuckleBoneList, fingerIndex, fingerIndex), copyFingerRotators["rotators"]), component, mirrorPitch, mirrorYaw, mirrorRoll)
		end
	end

	updateBoneRotationUI()
	updateAnimationsDefinition()
end

local cutoffChildBoneNames = {}
local function saveInitialTransform()
	if selectedProfileName ~= nil and selectedMeshName ~= nil and configuration ~= nil and configuration["profiles"] ~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil  then
		configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"] = {}
		configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"]["left_hand"] = {}
		configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"]["right_hand"] = {}
		for hand = Handed.Left, Handed.Right do
			local index = configui.getValue(hand == Handed.Left and "left_cutoff_bone" or "right_cutoff_bone")
			local cutoffBone = bones["names"][index]
			local handedCutoffChildBoneNames = animation.getDescendantBones(hands.getHandComponent(hand), cutoffBone, false)
			for index, cutoffChildBoneName in ipairs(handedCutoffChildBoneNames) do
				local rotation, location, scale = animation.getBoneSpaceLocalTransform(hands.getHandComponent(hand), uevrUtils.fname_from_string(cutoffChildBoneName))
				if rotation ~= nil and location ~= nil then
					configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"][hand == Handed.Left and "left_hand" or "right_hand"][cutoffChildBoneName] = {rotation = {rotation.Pitch, rotation.Yaw, rotation.Roll}, location = {location.X, location.Y, location.Z}}
				end
			end
		end
		isConfigurationDirty = true
	end
end

local function loadInitialTransform()
	if selectedProfileName ~= nil and selectedMeshName ~= nil and configuration ~= nil and configuration["profiles"] ~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		local initialTransform = configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"]
		if initialTransform ~= nil then
			for hand = Handed.Left, Handed.Right do
				animation.initializeBones(hands.getHandComponent(hand), initialTransform[hand == Handed.Left and "left_hand" or "right_hand"])
			end
		end
	end
end

local function copyCurrentCutoffChildBoneRotations()
	copiedBoneRotation = configui.getValue("cutoff_children_rotation")
end

local function pasteCurrentCutoffChildBoneRotations()
	if copiedBoneRotation ~= nil then
		configui.setValue("cutoff_children_rotation", copiedBoneRotation)
	end
end

local function updateCutoffChildBoneTransformsUI()
	local index = configui.getValue("cutoff_children_bone_picker")
	if #cutoffChildBoneNames >= index and cutoffChildBoneNames[index] ~= "None" then
		local cutoffChildBone = cutoffChildBoneNames[index]
		local rotation, location, scale = animation.getBoneSpaceLocalTransform(hands.getHandComponent(configui.getValue("cutoff_children_hand_picker") - 1), uevrUtils.fname_from_string(cutoffChildBone))
		if rotation ~= nil then
			configui.setValue("cutoff_children_rotation", {rotation.Pitch,rotation.Yaw,rotation.Roll})
		end
		if location ~= nil then
			configui.setValue("cutoff_children_location", {location.X,location.Y,location.Z})
		end
	end
end

local function revertAllCutoffChildBoneTransforms()
	-- for index, cutoffChildBone in ipairs(cutoffChildBoneNames) do
		-- animation.setBoneSpaceLocalRotator(hands.getHandComponent(configui.getValue("cutoff_children_hand_picker") - 1), uevrUtils.fname_from_string(cutoffChildBone), uevrUtils.rotator(0,0,0))	
	-- end
	-- updateCutoffChildBoneTransformsUI()
	if selectedProfileName ~= nil and selectedMeshName ~= nil and configuration ~= nil and configuration["profiles"] ~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"] = {}
	end
	updateHands()
	updateCutoffChildBoneTransformsUI()

end

local function zeroCurrentCutoffChildBoneRotations()
	local index = configui.getValue("cutoff_children_bone_picker")
	if #cutoffChildBoneNames >= index and cutoffChildBoneNames[index] ~= "None" then
		local cutoffChildBone = cutoffChildBoneNames[index]
		animation.setBoneSpaceLocalRotator(hands.getHandComponent(configui.getValue("cutoff_children_hand_picker") - 1), uevrUtils.fname_from_string(cutoffChildBone), uevrUtils.rotator(0,0,0))
	end
	updateCutoffChildBoneTransformsUI()
end

local function updateCutoffChildBoneTransforms()
	local index = configui.getValue("cutoff_children_bone_picker")
	if #cutoffChildBoneNames >= index and cutoffChildBoneNames[index] ~= "None" then
		local cutoffChildBone = cutoffChildBoneNames[index]
		local rotation = configui.getValue("cutoff_children_rotation")
		local location = configui.getValue("cutoff_children_location")
		animation.setBoneSpaceLocalRotator(hands.getHandComponent(configui.getValue("cutoff_children_hand_picker") - 1), uevrUtils.fname_from_string(cutoffChildBone), rotation)
		animation.setBoneSpaceLocalLocation(hands.getHandComponent(configui.getValue("cutoff_children_hand_picker") - 1), uevrUtils.fname_from_string(cutoffChildBone), location)
	end
end

local function updateCutoffChildBonePicker()
	local handed = configui.getValue("cutoff_children_hand_picker") - 1
	local index = configui.getValue(handed == Handed.Left and "left_cutoff_bone" or "right_cutoff_bone")
	local cutoffBone = bones["names"][index]
	cutoffChildBoneNames = animation.getDescendantBones(hands.getHandComponent(handed), cutoffBone, false)
	configui.setSelections("cutoff_children_bone_picker", cutoffChildBoneNames)

	configui.hideWidget("cutoff_children_rotation", #cutoffChildBoneNames < 2 )
	configui.hideWidget("cutoff_children_location", #cutoffChildBoneNames < 2 )

	updateCutoffChildBoneTransformsUI()
end

local function updateAnimationDescription()
	local currentAttachment = "an attachment (weapon)"
	local selectedAttachment = configui.getValue("attachments_list")
	if selectedAttachment ~= 1 then
		currentAttachment = "the '" .. attachmentLabels[selectedAttachment] .. "' attachment"
	end

	local handText = {"the left hand", "the right hand", "both hands"}
	local typeText = {"gripping while not holding " .. currentAttachment, "triggering while not holding " .. currentAttachment, "thumbing while not holding " .. currentAttachment, "gripping while holding " .. currentAttachment, "triggering while holding " .. currentAttachment}
	local stateText = {" ", " not "}
	local text = "You are creating the animation state used by " -- "left hand is not gripping\n the grab button"
	text = text .. handText[configui.getValue("animation_hand")] .. " when" .. stateText[configui.getValue("animation_state")] .. typeText[configui.getValue("animation_type")]
	configui.setLabel("animation_description", text)
end

local function createDefaultAnimations()
	local typeText = {"grip", "trigger", "thumb", "grip_weapon", "trigger_weapon"}
	for handIndex = 1, 2 do
		local component = hands.getHandComponent(handIndex - 1)
		for typeIndex = 1, #typeText do
			local handStr = handIndex == 1 and "left" or "right"
			if component ~= nil and animationPositions[handStr .. "_" .. typeText[typeIndex]] == nil or animationPositions[handStr .. "_" .. typeText[typeIndex]]["on"] == nil then
				updateAnimationsDefinition(handIndex, typeIndex, 1)
			end
			if component ~= nil and animationPositions[handStr .. "_" .. typeText[typeIndex]] == nil or animationPositions[handStr .. "_" .. typeText[typeIndex]]["off"] == nil then
				updateAnimationsDefinition(handIndex, typeIndex, 2)
			end
		end
	end
end

local function updateHandAnimationType(handed, animType)
	local typeText = {"grip", "trigger", "thumb", "grip_weapon", "trigger_weapon"}
	local stateText = {"on", "off"}
	local handStr = handed == Handed.Left and "left" or "right"
	local typeStr = handStr .. "_" .. typeText[animType] .. getAttachmentExtension(animType)
	local component = hands.getHandComponent(handed)
	if component ~= nil and animationPositions[typeStr] ~= nil then
		local currentAnimation = animationPositions[typeStr][stateText[configui.getValue("animation_state")]]
		animation.doAnimate(currentAnimation, component)
	end
end
--called when animation type or state is changed
local function updateHandAnimation()
	--load existing animation from animations
	--local typeText = {"grip", "trigger", "thumb", "grip_weapon", "trigger_weapon"}
	--local stateText = {"on", "off"}
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		if configui.getValue("animation_type") == 1 or configui.getValue("animation_type") == 2 or configui.getValue("animation_type") == 3 then
			updateHandAnimationType(Handed.Left, 1)
			updateHandAnimationType(Handed.Left, 2)
			updateHandAnimationType(Handed.Left, 3)
		elseif configui.getValue("animation_type") == 4 or configui.getValue("animation_type") == 5 then
			updateHandAnimationType(Handed.Left, 4)
			updateHandAnimationType(Handed.Left, 5)
		end
		-- local handStr = "left"
		-- local typeStr = handStr .. "_" .. typeText[configui.getValue("animation_type")] .. getAttachmentExtension(configui.getValue("animation_type"))
		-- local component = hands.getHandComponent(Handed.Left)
		-- if component ~= nil and animationPositions[typeStr] ~= nil then
		-- 	local currentAnimation = animationPositions[typeStr][stateText[configui.getValue("animation_state")]]
		-- 	animation.doAnimate(currentAnimation, component)
		-- end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		if configui.getValue("animation_type") == 1 or configui.getValue("animation_type") == 2 or configui.getValue("animation_type") == 3 then
			updateHandAnimationType(Handed.Right, 1)
			updateHandAnimationType(Handed.Right, 2)
			updateHandAnimationType(Handed.Right, 3)
		elseif configui.getValue("animation_type") == 4 or configui.getValue("animation_type") == 5 then
			updateHandAnimationType(Handed.Right, 4)
			updateHandAnimationType(Handed.Right, 5)
		end
		-- local handStr = "right"
		-- local typeStr = handStr .. "_" .. typeText[configui.getValue("animation_type")] .. getAttachmentExtension(configui.getValue("animation_type"))
		-- local component = hands.getHandComponent(Handed.Right)
		-- if component ~= nil  and animationPositions[typeStr] ~= nil then
		-- 	local currentAnimation = animationPositions[typeStr][stateText[configui.getValue("animation_state")]]
		-- 	animation.doAnimate(currentAnimation, component)
		-- end
	end

	updateBoneRotationUI()
	updateAnimationDescription()
end

local function revertFingerAnimation()
	--load existing animation from animations
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		local fingerIndex = getFingerIndexForCurrentAnimationType() --configui.getValue("animation_finger")
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			animation.doAnimateForFinger(defaultAnimationRotators["left_hand"], component, knuckleBoneList, fingerIndex)
		end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		local fingerIndex = getFingerIndexForCurrentAnimationType() + 5 --configui.getValue("animation_finger") + 5
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			animation.doAnimateForFinger(defaultAnimationRotators["right_hand"], component, knuckleBoneList, fingerIndex)
		end
	end

	updateBoneRotationUI()
	updateAnimationsDefinition()
end

local function revertHandAnimation()
	--load existing animation from animations
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			animation.doAnimate(defaultAnimationRotators["left_hand"], component)
		end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			animation.doAnimate(defaultAnimationRotators["right_hand"], component)
		end
	end

	updateBoneRotationUI()
	updateAnimationsDefinition()
end


local function setFingerAngles(angleID, angle)
	if configui.getValue("animation_hand") == 1 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Left)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() --configui.getValue("animation_finger")
			animation.setFingerAngles(component, knuckleBoneList, fingerIndex, configui.getValue("animation_joint"), angleID, angle, false, false)
		end
	end
	if configui.getValue("animation_hand") == 2 or configui.getValue("animation_hand") == 3 then
		local component = hands.getHandComponent(Handed.Right)
		if component ~= nil then
			local fingerIndex = getFingerIndexForCurrentAnimationType() + 5 --configui.getValue("animation_finger") + 5
			if configui.getValue("animation_hand") == 3 then
				if angleID == 0 and configui.getValue("animation_finger_bone_pitch_mirror") == true then
					angle = -angle
				end
				if angleID == 1 and configui.getValue("animation_finger_bone_yaw_mirror") == true then
					angle = -angle
				end
				if angleID == 2 and configui.getValue("animation_finger_bone_roll_mirror") == true then
					angle = -angle
				end
			end
			animation.setFingerAngles(component, knuckleBoneList, fingerIndex, configui.getValue("animation_joint"), angleID, angle, false, false)
		end
	end

	updateAnimationsDefinition()
end

local function getKnuckleBones()
	knuckleBoneList = {}
	for index, knuckleName in ipairs(knuckles["names"]) do
		local boneIndex = configui.getValue(knuckles["names"][index]) - 1
		table.insert(knuckleBoneList, boneIndex)
	end
	return knuckleBoneList
end

local function scanForKnuckleBonesUsingPattern(pattern)
	--"(ff)_(ii)_(h)" -- thumb_01_r 
	--"(Hh)Hand(Ff)(i)_JNT" -- RightHandThumb1_JNT
	--"(Hh)Hand(Ff)(i)" -- RightHandThumb1

	local fingers = {"Thumb","Index","Middle","Ring","Pinky"}
	for index, knuckleName in ipairs(knuckles["names"]) do
		local finger = fingers[((index-1) % 5) + 1]
		local hand = index > 5 and "Right" or "Left"
		local scanPattern = pattern
		local jointIndex = 1
		--print("Pattern before",scanPattern)
		scanPattern = string.gsub(scanPattern, "%(Ff%)", finger)
		scanPattern = string.gsub(scanPattern, "%(ff%)", string.lower(finger))
		scanPattern = string.gsub(scanPattern, "%(FF%)", string.upper(finger))
		scanPattern = string.gsub(scanPattern, "%(h%)", string.sub(string.lower(hand), 1, 1))
		scanPattern = string.gsub(scanPattern, "%(H%)", string.sub(string.upper(hand), 1, 1))
		scanPattern = string.gsub(scanPattern, "%(Hh%)", hand)
		scanPattern = string.gsub(scanPattern, "%(hh%)", string.lower(hand))
		scanPattern = string.gsub(scanPattern, "%(HH%)", string.upper(hand))
		scanPattern = string.gsub(scanPattern, "%(i%)", string.format("%01d", jointIndex))
		scanPattern = string.gsub(scanPattern, "%(ii%)", string.format("%02d", jointIndex))
		scanPattern = string.gsub(scanPattern, "%(iii%)", string.format("%03d", jointIndex))
		scanPattern = string.gsub(scanPattern, "%(iiii%)", string.format("%04d", jointIndex))
		--print("Pattern after",scanPattern)

		for i, boneName in ipairs(bones["names"]) do
			if boneName == scanPattern then
				if configui.getValue(knuckles["names"][index]) == 1 then
					configui.setValue(knuckles["names"][index], i)
				end
			end
		end
	end
end

local function updateBoneTransformVisibility()
	local leftParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]
	local rightParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]
	configui.hideWidget("left_hand_location", leftParams["Name"] == nil or leftParams["Name"] == "")
	configui.hideWidget("left_hand_rotation", leftParams["Name"] == nil or leftParams["Name"] == "")
	configui.hideWidget("left_hand_scale", leftParams["Name"] == nil or leftParams["Name"] == "")
	configui.hideWidget("right_hand_location", rightParams["Name"] == nil or rightParams["Name"] == "")
	configui.hideWidget("right_hand_rotation", rightParams["Name"] == nil or rightParams["Name"] == "")
	configui.hideWidget("right_hand_scale", rightParams["Name"] == nil or rightParams["Name"] == "")
end

local function setHandLocation(hand, value)
	hands.setLocation(hand, 1, value.X)
	hands.setLocation(hand, 2, value.Y)
	hands.setLocation(hand, 3, value.Z)

	configuration["profiles"][selectedProfileName][selectedMeshName][hand == Handed.Right and "Right" or "Left"]["Location"] = {value.X, value.Y, value.Z}
	isConfigurationDirty = true
end

local function setHandRotation(hand, value)
	hands.setRotation(hand, 1, value.X)
	hands.setRotation(hand, 2, value.Y)
	hands.setRotation(hand, 3, value.Z)

	configuration["profiles"][selectedProfileName][selectedMeshName][hand == Handed.Right and "Right" or "Left"]["Rotation"] = {value.X, value.Y, value.Z}
	isConfigurationDirty = true
end

local function setHandScale(hand, value)
	hands.setScale(hand, 1, value.X)
	hands.setScale(hand, 2, value.Y)
	hands.setScale(hand, 3, value.Z)

	configuration["profiles"][selectedProfileName][selectedMeshName][hand == Handed.Right and "Right" or "Left"]["Scale"] = {value.X, value.Y, value.Z}
	isConfigurationDirty = true
end

local function loadCharacterMeshList()
	meshList = {}
	if uevrUtils.getValid(pawn) ~= nil then
		meshList = uevrUtils.getPropertiesOfClass(pawn, "Class /Script/Engine.SkeletalMeshComponent")
		for index, name in ipairs(meshList) do
			meshList[index] = "Pawn." .. meshList[index]
		end

		if configui.getValue("include_children_in_mesh_search") then
			for _, prop in ipairs(meshList) do
				local parent = uevrUtils.getObjectFromDescriptor(prop)
				if parent ~= nil then
					local children = parent.AttachChildren
					if children ~= nil then
						for i, child in ipairs(children) do
							if child:is_a(uevrUtils.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
								local prefix, shortName = uevrUtils.splitOnLastPeriod(child:get_full_name())
								if shortName ~= nil then
									table.insert(meshList, prop .. "(" .. shortName .. ")")
								end
							end
						end
					end
				end
			end
		end
	end

	table.insert(meshList, 1,  "None")
	configui.setSelections("character_mesh", meshList)
	local meshPropertyName = configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"]
	configui.setValue("character_mesh", 1)

	if meshPropertyName ~= "" then
		for index, name in ipairs(meshList) do
			if name == meshPropertyName then
				configui.setValue("character_mesh", index)
				break
			end
		end
	end

end

local function captureCurrentHandTransforms()
	local meshComponent = getMeshComponent()
	if meshComponent ~= nil then
		hands.updateAnimationFromMesh(configui.getValue("cutoff_children_hand_picker") - 1, meshComponent, selectedMeshName)
		updateCutoffChildBoneTransformsUI()
	end
end

local function setOptimizeAnimations(value)
	if configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		configuration["profiles"][selectedProfileName][selectedMeshName]["OptimizeAnimations"] = value
	end
	isConfigurationDirty = true
end

local function setOptimizationRootBone(hand, value)
	if hand == Handed.Left then
		if configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName]["Left"] ~= nil then
			configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["OptimizeAnimationsRootBone"] = ancestorBonesLeft[value]
		end
	else
		if configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName]["Right"] ~= nil then
			configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["OptimizeAnimationsRootBone"] = ancestorBonesRight[value]
		end
	end
	isConfigurationDirty = true
end

local function updateOptimizationBoneList()
	local leftParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]
	local rightParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]
	local currentLeftBone = leftParams and leftParams["OptimizeAnimationsRootBone"] or ""
	local currentRightBone = rightParams and rightParams["OptimizeAnimationsRootBone"] or ""

	ancestorBonesLeft = animation.getAncestorBones(getMeshComponent(), leftParams and leftParams["Name"] or nil)
	for i = 1, math.floor(#ancestorBonesLeft / 2) do
		ancestorBonesLeft[i], ancestorBonesLeft[#ancestorBonesLeft - i + 1] = ancestorBonesLeft[#ancestorBonesLeft - i + 1], ancestorBonesLeft[i]
	end

	ancestorBonesRight = animation.getAncestorBones(getMeshComponent(), rightParams and rightParams["Name"] or nil)
	for i = 1, math.floor(#ancestorBonesRight / 2) do
		ancestorBonesRight[i], ancestorBonesRight[#ancestorBonesRight - i + 1] = ancestorBonesRight[#ancestorBonesRight - i + 1], ancestorBonesRight[i]
	end

	configui.setSelections("optimize_animations_root_bone_left", ancestorBonesLeft)
	configui.setSelections("optimize_animations_root_bone_right", ancestorBonesRight)
	local leftIndex = 1
	local rightIndex = 1
	for index, name in ipairs(ancestorBonesLeft) do
		if name == currentLeftBone then
			leftIndex = index
			break
		end
	end
	for index, name in ipairs(ancestorBonesRight) do
		if name == currentRightBone then
			rightIndex = index
			break
		end
	end
	configui.setValue("optimize_animations_root_bone_left", leftIndex)
	configui.setValue("optimize_animations_root_bone_right", rightIndex)
end

local function updateOptimizationUI()
	updateOptimizationBoneList()
	if configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		configui.setValue("optimize_animations", configuration["profiles"][selectedProfileName][selectedMeshName]["OptimizeAnimations"] ~= false)
	end
end

local function updateTestingAnimation()
	if configui.getValue("animation_test_left_handed_mode") then
		if configui.getValue("animation_test_active_weapon_mode") then
			local attachmentExt = getAttachmentExtension(configui.getValue("animation_type"),"")
			hands.setHoldingAttachment(Handed.Left, attachmentExt)
			hands.setHoldingAttachment(Handed.Right, nil)
		else
			hands.setHoldingAttachment(Handed.Left, nil)
			hands.setHoldingAttachment(Handed.Right, nil)
		end
	else
		if configui.getValue("animation_test_active_weapon_mode") then
			local attachmentExt = getAttachmentExtension(configui.getValue("animation_type"),"")
			hands.setHoldingAttachment(Handed.Right, attachmentExt)
			hands.setHoldingAttachment(Handed.Left, nil)
		else
			hands.setHoldingAttachment(Handed.Right, nil)
			hands.setHoldingAttachment(Handed.Left, nil)
		end
	end
end

configui.onUpdate("animation_test_left_handed_mode", function(value)
	updateTestingAnimation()
end)

configui.onUpdate("animation_test_active_weapon_mode", function(value)
	updateTestingAnimation()
end)

configui.onUpdate("test_button", function(value)
	isTesting = not isTesting
	updateHands()
	updateTestingAnimation()

	configui.hideWidget("prev_button", isTesting)
	configui.hideWidget("next_button", isTesting)
	configui.hideWidget("Step_13", isTesting)
	configui.hideWidget("step_testing", not isTesting)
	configui.setLabel("test_button", isTesting and "Stop Testing" or "Test")

	if not isTesting then
		updateHandAnimation()
	end
end)


configui.onUpdate("mesh_rotation", function(value)
	hands.updateOffset(getMeshComponent(), {X=0, Y=0, Z=0, Pitch=value.X, Yaw=value.Y, Roll=value.Z})
end)

configui.onUpdate("exit_button_config", function(value)
	hands.destroyHands()
	updateSteps(-(currentStep-1))
end)

configui.onUpdate("exit_button_config_2", function(value)
	hands.destroyHands()
	updateSteps(-(currentStep-1))
end)

configui.onUpdate("exit_button", function(value)
	hands.destroyHands()
	updateSteps(-(currentStep-1))
end)

configui.onUpdate("done_button", function(value)
	hands.destroyHands()
	updateSteps(-(currentStep-1))
end)

configui.onUpdate("generate_code_button", function(value)
	local text = "local uevrUtils = require('libs/uevr_utils')\nlocal hands = require('libs/hands')\nlocal controllers = require('libs/controllers')\n\nfunction on_level_change(level)\n\tcontrollers.createController(0)\n\tcontrollers.createController(1)\n\thands.reset()\n\n\tlocal paramsFile = 'hands_parameters' -- found in the [game profile]/data directory\n\tlocal configName = '".. selectedProfileName .. "' -- the name you gave your config\n\tlocal animationName = '".. selectedAnimationName .. "' -- the name you gave your animation\n\thands.createFromConfig(paramsFile, configName, animationName)\nend"
	fs.write("$scripts/hands.lua", text)
	configui.hideWidget("generate_code_instructions", false)
end)

configui.onUpdate("generate_code_button_2", function(value)
	local text = "local uevrUtils = require('libs/uevr_utils')\nlocal hands = require('libs/hands')\nlocal controllers = require('libs/controllers')\n\nfunction on_level_change(level)\n\tcontrollers.createController(0)\n\tcontrollers.createController(1)\n\thands.reset()\n\n\tlocal paramsFile = 'hands_parameters' -- found in the [game profile]/data directory\n\tlocal configName = '".. selectedProfileName .. "' -- the name you gave your config\n\tlocal animationName = '".. selectedAnimationName .. "' -- the name you gave your animation\n\thands.createFromConfig(paramsFile, configName, animationName)\nend\n\nfunction on_xinput_get_state(retval, user_index, state)\n\tif hands.exists() then\n\t\tlocal isHoldingWeapon = false\n\t\tlocal hand = Handed.Right\n\t\thands.handleInput(state, isHoldingWeapon, hand)\n\tend\nend"
	fs.write("$scripts/hands.lua", text)
	configui.hideWidget("generate_code_instructions_2", false)
end)

configui.onUpdate("show_code_button", function(value)
	configui.hideWidget("code_text", false)
	local text = "local uevrUtils = require('libs/uevr_utils')\nlocal hands = require('libs/hands')\nlocal controllers = require('libs/controllers')\n\nfunction on_level_change(level)\n\tcontrollers.createController(0)\n\tcontrollers.createController(1)\n\thands.reset()\n\n\tlocal paramsFile = 'hands_parameters' -- found in the [game profile]/data directory\n\tlocal configName = '".. selectedProfileName .. "' -- the name you gave your config\n\tlocal animationName = '".. selectedAnimationName .. "' -- the name you gave your animation\n\thands.createFromConfig(paramsFile, configName, animationName)\nend"
	configui.setValue("code_text", text)
end)

configui.onUpdate("show_code_button_2", function(value)
	configui.hideWidget("code_text_2", false)
	local text = "local uevrUtils = require('libs/uevr_utils')\nlocal hands = require('libs/hands')\nlocal controllers = require('libs/controllers')\n\nfunction on_level_change(level)\n\tcontrollers.createController(0)\n\tcontrollers.createController(1)\n\thands.reset()\n\n\tlocal paramsFile = 'hands_parameters' -- found in the [game profile]/data directory\n\tlocal configName = '".. selectedProfileName .. "' -- the name you gave your config\n\tlocal animationName = '".. selectedAnimationName .. "' -- the name you gave your animation\n\thands.createFromConfig(paramsFile, configName, animationName)\nend\n\nfunction on_xinput_get_state(retval, user_index, state)\n\tif hands.exists() then\n\t\tlocal isHoldingWeapon = false\n\t\tlocal hand = Handed.Right\n\t\thands.handleInput(state, isHoldingWeapon, hand)\n\tend\nend"
	configui.setValue("code_text_2", text)
end)

configui.onUpdate("include_children_in_mesh_search", function(value)
	loadCharacterMeshList()
end)

configui.onUpdate("animation_type", function(value)
	local fingerIndex = getFingerIndexForCurrentAnimationType()
	configui.setSelections("animation_finger", getFingerNamesForCurrentAnimationType())
	configui.setValue("animation_finger", getSelectionIndexForCurrentAnimationType(fingerIndex))

	updateHandAnimation()
	updateAttachmentListVisibility()
end)

configui.onUpdate("animation_state", function(value)
	updateHandAnimation()
end)

configui.onUpdate("animation_hand", function(value)
	updateHandAnimation()
	--updateBoneRotationUI() -- this is called by updateHandAnimation
end)

configui.onUpdate("animation_finger", function(value)
	lastFingerIndex = getFingerIndexForCurrentAnimationType()
	updateBoneRotationUI()
end)

configui.onUpdate("animation_joint", function(value)
	updateBoneRotationUI()
end)


configui.onUpdate("animation_finger_bone_pitch", function(value)
	setFingerAngles(0, value)
end)

configui.onUpdate("animation_finger_bone_yaw", function(value)
	setFingerAngles(1, value)
end)

configui.onUpdate("animation_finger_bone_roll", function(value)
	setFingerAngles(2, value)
end)

configui.onUpdate("knuckle_bone_search_pattern", function(value)
	scanForKnuckleBonesUsingPattern(value)
end)

configui.onUpdate("prev_button", function(value)
	updateSteps(-1)
end)
configui.onUpdate("next_button", function(value)
	updateSteps(1)
end)
configui.onUpdate("edit_config_button", function(value)
	updateSteps(1)
end)
configui.onUpdate("create_animations_button", function(value)
	updateSteps(8)
end)
configui.onUpdate("create_animations_button_2", function(value)
	updateSteps(1)
end)

configui.onUpdate("add_attachment_button", function(value)
	local newAttachmentName = configui.getValue("new_attachment_name")
	if newAttachmentName == nil then newAttachmentName = "" end
	if newAttachmentName == "" then
		configui.hideWidget("new_attachment_error", false)
		delay(3000, function()
			configui.hideWidget("new_attachment_error", true)
		end)
	else
		if configuration~= nil then
			if configuration["attachments"] == nil then configuration["attachments"] = {} end
			local id = string.gsub(newAttachmentName, "%s+", "_")
			id = string.lower(id)
			configuration["attachments"][id] = {label = newAttachmentName}

			if configuration["animations"] ~= nil and configuration["animations"][selectedAnimationName] ~= nil and configuration["animations"][selectedAnimationName]["poses"] ~= nil then
				configuration["animations"][selectedAnimationName]["poses"]["grip_right_weapon_" .. id] = { {"right_grip_weapon_" .. id,"on"}, {"right_trigger_weapon_" .. id,"off"} }
				configuration["animations"][selectedAnimationName]["poses"]["grip_left_weapon_" .. id] = { {"left_grip_weapon_" .. id,"on"}, {"left_trigger_weapon_" .. id,"off"} }
			end

			isConfigurationDirty = true
			configui.setValue("new_attachment_name", "")
			updateAttachmentListUI()
		end
	end
end)


configui.onUpdate("character_mesh", function(value)
	--configui.setValue("mesh_property_name", value == 1 and "" or meshList[value])
	if configuration~= nil and configuration["profiles"]~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
		configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"] = value == 1 and "" or meshList[value]
		isConfigurationDirty = true
	end
	updateHands()
	configui.disableWidget("next_button", value == 1)
end)

configui.onUpdate("left_cutoff_bone", function(value)
	configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["Name"] = bones["names"][value]
	isConfigurationDirty = true
	--configui.setValue("left_cutoff_bone_name", bones["names"][value])
	--if configui.getValue("left_cutoff_bone_name") ~= "" then
		updateHands()
	--end
	updateOptimizationBoneList()
	updateBoneTransformVisibility()
end)

configui.onUpdate("right_cutoff_bone", function(value)
	configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["Name"] = bones["names"][value]
	isConfigurationDirty = true
	--configui.setValue("right_cutoff_bone_name", bones["names"][value])
	--if configui.getValue("right_cutoff_bone_name") ~= "" then
		updateHands()
	--end
	updateOptimizationBoneList()
	updateBoneTransformVisibility()
end)

configui.onUpdate("optimize_animations_root_bone_left", function(value)
	setOptimizationRootBone(Handed.Left, value)
end)

configui.onUpdate("optimize_animations_root_bone_right", function(value)
	setOptimizationRootBone(Handed.Right, value)
end)

configui.onUpdate("optimize_animations", function(value)
	setOptimizeAnimations(value)
end)

configui.onUpdate("left_hand_rotation", function(value)
	setHandRotation(Handed.Left, value)
end)

configui.onUpdate("left_hand_location", function(value)
	setHandLocation(Handed.Left, value)
end)

configui.onUpdate("left_hand_scale", function(value)
	setHandScale(Handed.Left, value)
end)

configui.onUpdate("right_hand_rotation", function(value)
	setHandRotation(Handed.Right, value)
end)

configui.onUpdate("right_hand_location", function(value)
	setHandLocation(Handed.Right, value)
end)

configui.onUpdate("right_hand_scale", function(value)
	setHandScale(Handed.Right, value)
end)

configui.onUpdate("left_cutoff_bone", function(value)
	updateCutoffChildBonePicker()
end)

configui.onUpdate("right_cutoff_bone", function(value)
	updateCutoffChildBonePicker()
end)

configui.onUpdate("cutoff_children_hand_picker", function(value)
	updateCutoffChildBonePicker()
end)

configui.onUpdate("cutoff_children_bone_picker", function(value)
	updateCutoffChildBoneTransformsUI()
end)

configui.onUpdate("cutoff_children_rotation", function(value)
	updateCutoffChildBoneTransforms()
end)

configui.onUpdate("cutoff_children_location", function(value)
	updateCutoffChildBoneTransforms()
end)

configui.onUpdate("cutoff_children_revert_all_button", function(value)
	revertAllCutoffChildBoneTransforms()
end)

configui.onUpdate("cutoff_children_capture_hand_button", function(value)
	captureCurrentHandTransforms()
end)

configui.onUpdate("cutoff_children_zero_current_button", function(value)
	zeroCurrentCutoffChildBoneRotations()
end)

configui.onUpdate("copy_hand_button", function(value)
	copyCurrentCutoffChildBoneRotations()
end)

configui.onUpdate("paste_hand_button", function(value)
	pasteCurrentCutoffChildBoneRotations()
end)

configui.onUpdate("use_default_pose", function(value)
	configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["UseDefaultPose"] = configui.getValue("use_default_pose")
	configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["UseDefaultPose"] = configui.getValue("use_default_pose")
	--updateHands()
	--updateCutoffChildBoneTransformsUI()
end)

configui.onUpdate("copy_hand_button", function(value)
	copyHandAnimation()
end)

configui.onUpdate("paste_hand_button", function(value)
	pasteHandAnimation()
end)

configui.onUpdate("revert_hand_button", function(value)
	revertHandAnimation()
end)

configui.onUpdate("copy_finger_button", function(value)
	copyFingerAnimation()
end)

configui.onUpdate("paste_finger_button", function(value)
	pasteFingerAnimation()
end)

configui.onUpdate("revert_finger_button", function(value)
	revertFingerAnimation()
end)

-- configui.onUpdate("weapon_mesh", function(value)
	-- attachWeapon()
	-- updateWeaponTransform()
-- end)

-- configui.onUpdate("weapon_offset_rotation", function(value)
	-- updateWeaponTransform()
-- end)

-- configui.onUpdate("weapon_offset_location", function(value)
	-- updateWeaponTransform()
-- end)

-- configui.onUpdate("refresh_weapon_mesh_button", function(value)
	-- loadWeaponMeshList()
-- end)

configui.onUpdate("capture_hand_button", function(value)
	captureAnimationFromMesh()
end)

configui.onUpdate("attachments_list", function(value)
	updateHandAnimation()
	--updateAnimationDescription() --already called by updateHandAnimation
end)



-- function updateWeaponTransform()
	-- if uevrUtils.getValid(weaponMesh) ~= nil then
		-- local rotation = configui.getValue("weapon_offset_rotation")
		-- local location = configui.getValue("weapon_offset_location")
		-- uevrUtils.set_component_relative_transform(weaponMesh, location, rotation)
	-- end
-- end

-- function attachWeapon(component)
	-- if component == nil then
		-- local meshPropertyName = weaponMeshList[configui.getValue("weapon_mesh")]
		-- component = uevrUtils.getObjectFromDescriptor(meshPropertyName) -- "Pawn.Mesh(Arm).Glove")
	-- end
	-- if component ~= nil then
		-- -- print("Got weapon", component.AttachSocketName)
		-- -- local location = component:K2_GetComponentLocation()
		-- -- local rotation = component:K2_GetComponentRotation()
		-- -- print(location.X,location.Y,location.Z)
		-- -- print(rotation.Pitch,rotation.Yaw,rotation.Roll)
		-- component:K2_AttachTo(hands.getHandComponent(Handed.Right), component.AttachSocketName, 0, false)
		-- -- local location = component:K2_GetComponentLocation()
		-- -- local rotation = component:K2_GetComponentRotation()
		-- -- print("After")
		-- -- print(location.X,location.Y,location.Z)
		-- -- print(rotation.Pitch,rotation.Yaw,rotation.Roll)
	-- end
	-- weaponMesh = component
-- end


lastFingerIndex = getFingerIndexForCurrentAnimationType()


-- function loadWeaponMeshList()
	-- weaponMeshList = {}
	-- local meshName = configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"]
	-- local parent = uevrUtils.getObjectFromDescriptor(meshName)
	-- if uevrUtils.getValid(parent) ~= nil then
		-- local children = parent.AttachChildren
		-- if children ~= nil then
			-- for i, child in ipairs(children) do
				-- if child:is_a(uevrUtils.get_class("Class /Script/Engine.StaticMeshComponent")) or child:is_a(uevrUtils.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
					-- local prefix, shortName = uevrUtils.splitOnLastPeriod(child:get_full_name())
					-- print("Found weapon candidate",child:get_fname())
					-- if shortName ~= nil then
						-- table.insert(weaponMeshList, meshName .. "(" .. shortName .. ")") 
					-- end
				-- end
			-- end	
		-- end
	-- end

	-- table.insert(weaponMeshList, 1,  "None") 
	-- configui.setSelections("weapon_mesh", weaponMeshList)
	-- configui.setValue("weapon_mesh", 1)

	-- -- local meshPropertyName = configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"]
	-- -- if meshPropertyName ~= "" then
		-- -- for index, name in ipairs(meshList) do
			-- -- if name == meshPropertyName then
				-- -- configui.setValue("character_mesh", index)
				-- -- break
			-- -- end
		-- -- end
	-- -- end
-- end

local function loadProfileNames()
	profileNames = {}
	if configuration["profiles"] == nil then
		configuration["profiles"] = {}
		isConfigurationDirty = true
	end
	for key, profile in pairs(configuration["profiles"]) do
		table.insert(profileNames, key)
	end
	table.insert(profileNames, 1,  "Create new configuration")
	configui.setSelections("hands_profile_list", profileNames)
end

local function loadAnimationNames()
	animationNames = {}
	if configuration["animations"] == nil then
		configuration["animations"] = {}
		isConfigurationDirty = true
	end
	for key, animation in pairs(configuration["animations"]) do
		table.insert(animationNames, key)
	end
	table.insert(animationNames, 1,  "Create new animation")
	configui.setSelections("animations_list", animationNames)
end

local function getProfileMeshNames()
	local profileMeshNames = {}
	local profileMeshes = configuration["profiles"][selectedProfileName]
	if profileMeshes == nil then profileMeshes = {} end
	for key, mesh in pairs(profileMeshes) do
		table.insert(profileMeshNames, key)
	end
	table.insert(profileMeshNames, 1,  "Create new mesh")
	return profileMeshNames
end

local function loadProfile(index)
	selectedProfileName = profileNames[index]
	if configuration["profiles"][selectedProfileName] == nil then
		configuration["profiles"][selectedProfileName] = {}
		isConfigurationDirty = true
	end
	--profile = configuration["profiles"][selectedProfileName]
	configui.setLabel("hands_profile_title", "Edit Configuration")
	configui.setValue("hands_profile_name", selectedProfileName)
	configui.hideWidget("hands_profile_name_instructions", selectedProfileName ~= nil and selectedProfileName ~= "")

	profileMeshNames = getProfileMeshNames()
	configui.setSelections("hands_profile_mesh_list", profileMeshNames)
end

local function loadMesh(index)
	selectedMeshName = profileMeshNames[index]
	if configuration["profiles"][selectedProfileName][selectedMeshName] == nil then
		configuration["profiles"][selectedProfileName][selectedMeshName] = {}
		isConfigurationDirty = true
	end
	--mesh = configuration["profiles"][selectedProfileName][selectedMeshName]
	configui.setLabel("hands_profile_mesh_title", "Edit Mesh")
	configui.setValue("hands_profile_mesh_name", selectedMeshName)
	configui.hideWidget("hands_profile_mesh_name_instructions", selectedMeshName ~= nil and selectedMeshName ~= "")

end

local function getDefaultRotatorsForAnimations()
	--first get the current state of the hands as the default, then override that with InitialTransform if that exists
	for hand = Handed.Left, Handed.Right do
		local component = hands.getHandComponent(hand)
		local minBoneIndex = (hand == Handed.Left and 1 or 6)
		local maxBoneIndex = (hand == Handed.Left and 5 or 10)
		local handStr = (hand == Handed.Left and "left_hand" or "right_hand")
		if component ~= nil then
			local boneList = uevrUtils.getArrayRange(knuckleBoneList, minBoneIndex, maxBoneIndex)
			defaultAnimationRotators[handStr] = animation.getBoneTransforms(component, boneList , true, false, false)
			if selectedProfileName ~= nil and selectedMeshName ~= nil and configuration ~= nil and configuration["profiles"] ~= nil and configuration["profiles"][selectedProfileName] ~= nil and configuration["profiles"][selectedProfileName][selectedMeshName] ~= nil then
				local initialTransform = configuration["profiles"][selectedProfileName][selectedMeshName]["InitialTransform"]
				if initialTransform ~= nil and initialTransform[handStr] ~= nil then
					for j = 1, #boneList do
						for i = 1 , 3 do
							local fName = component:GetBoneName(boneList[j] + i - 1)
							if fName ~= nil then
								local boneName = fName:to_string()
								if initialTransform[handStr][boneName] ~= nil and initialTransform[handStr][boneName]["rotation"] ~= nil then
									defaultAnimationRotators[handStr][boneName] = initialTransform[handStr][boneName]["rotation"]
								end
							end
						end
					end
				end
			end
		end
	end
	-- component = hands.getHandComponent(Handed.Right)
	-- if component ~= nil then
		-- defaultAnimationRotators["right_hand"] = animation.getBoneTransforms(component, uevrUtils.getArrayRange(knuckleBoneList, 6, 10), true, false, false)		
	-- end

--json.dump_file("debug.json", defaultAnimationRotators, 4)

end

function M.updateCurrentStep(previousStep, currentStep)
print("Current Step",currentStep)
	if currentStep == 1 then
		loadProfileNames()
		configui.hideWidget("next_button", false)
		configui.disableWidget("next_button", false)
		if not hands.exists() then
			hands.createFromConfig(configuration, selectedProfileName, selectedAnimationName)
		end
		hands.resetAutoCreate()
	end
	if currentStep == 2 then
		hands.destroyHands()
		configui.hideWidget("next_button", true)
		selectedProfileName = profileNames[configui.getValue("hands_profile_list")]
		local hasValidProfile = false
		local profile = configuration["profiles"][selectedProfileName]
		if profile ~= nil then
			for name, mesh in pairs(profile) do
				if mesh["Left"] ~= nil and mesh["Left"]["AnimationID"] ~= nil then
					loadProfile(configui.getValue("hands_profile_list"))

					hasValidProfile = true
					break
				end
			end
		end
		if hasValidProfile then
			configui.setLabel("edit_configuration_title", "Selected Configuration: " .. selectedProfileName)
		else
			updateSteps(previousStep == 1 and 1 or -1)
		end
	end
	if currentStep == 3 then
		configui.hideWidget("next_button", false)
		configui.setLabel("hands_profile_title", "New Configuration")
		configui.setValue("hands_profile_name", "Main")
		if configui.getValue("hands_profile_list") ~= 1 then
			loadProfile(configui.getValue("hands_profile_list"))
		end
	end
	if currentStep == 4 then
		--handle possible name change from previous screen
		if previousStep == 3 then
			local profileName = configui.getValue("hands_profile_name")
			if configuration["profiles"][profileName] == nil then
				local profile = configuration["profiles"][selectedProfileName]
				if profile == nil then profile = {} end
				configuration["profiles"][profileName] = profile
				configuration["profiles"][selectedProfileName] = nil
				isConfigurationDirty = true
			end
			selectedProfileName = profileName
		end

		configui.setLabel("hands_profile_mesh_title", "New Mesh")
		configui.setValue("hands_profile_mesh_name", "Arms")
		if configui.getValue("hands_profile_mesh_list") ~= 1 then
			loadMesh(configui.getValue("hands_profile_mesh_list"))
		end

		configui.disableWidget("next_button", false)
	end
	if currentStep == 5 then
		if previousStep == 4 then
			local profileMeshName = configui.getValue("hands_profile_mesh_name")
			if configuration["profiles"][selectedProfileName][profileMeshName] == nil then
				local profileMesh = configuration["profiles"][selectedProfileName][selectedMeshName]
				if profileMesh == nil then profileMesh = {} end
				configuration["profiles"][selectedProfileName][profileMeshName] = profileMesh
				configuration["profiles"][selectedProfileName][selectedMeshName] = nil
				isConfigurationDirty = true
			end
			selectedMeshName = profileMeshName
		end

		loadCharacterMeshList()
		--configui.disableWidget("next_button", configui.getValue("mesh_property_name") == "")
		configui.disableWidget("next_button", configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"] == nil or configuration["profiles"][selectedProfileName][selectedMeshName]["Mesh"] == "")
	end
	if currentStep == 6 then
		if configuration["profiles"][selectedProfileName][selectedMeshName]["Offset"] ~= nil then
			local offset = configuration["profiles"][selectedProfileName][selectedMeshName]["Offset"]
			configui.setValue("mesh_rotation", {offset.Pitch,offset.Yaw,offset.Roll})
		end
	end
	if currentStep == 7 then
		--save changes from previous step
		if previousStep == 6 then
			local offset = configui.getValue("mesh_rotation")
			if offset ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Offset"] = {X=0, Y=0, Z=0, Pitch=offset.X, Yaw=offset.Y, Roll=offset.Z}
				isConfigurationDirty = true
			end
		end

		if configuration["profiles"][selectedProfileName][selectedMeshName]["FOV"] ~= nil then
			configui.setValue("fov_param_name", configuration["profiles"][selectedProfileName][selectedMeshName]["FOV"])
		end

		updateHands()
	end
	if currentStep == 8 then
		--save changes from previous step
		if previousStep == 7 then
			configuration["profiles"][selectedProfileName][selectedMeshName]["FOV"] = configui.getValue("fov_param_name")
			isConfigurationDirty = true
		end

		if configuration["profiles"][selectedProfileName][selectedMeshName]["Left"] == nil then
			configuration["profiles"][selectedProfileName][selectedMeshName]["Left"] = {}
			isConfigurationDirty = true
		end
		if configuration["profiles"][selectedProfileName][selectedMeshName]["Right"] == nil then
			configuration["profiles"][selectedProfileName][selectedMeshName]["Right"] = {}
			isConfigurationDirty = true
		end

		configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["UseDefaultPose"] = configui.getValue("use_default_pose")
		configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["UseDefaultPose"] = configui.getValue("use_default_pose")


		local leftParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]
		local rightParams = configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]
		if leftParams ~= nil  then
			if leftParams["Rotation"] ~= nil then
				configui.setValue("left_hand_rotation", leftParams["Rotation"]) --{X=leftParams["Rotation"][1], Y=leftParams["Rotation"][2], Z=leftParams["Rotation"][3]})
			end
			if leftParams["Location"] ~= nil then
				configui.setValue("left_hand_location", leftParams["Location"]) -- {X=leftParams["Location"][1], Y=leftParams["Location"][2], Z=leftParams["Location"][3]})
			end
			if leftParams["Scale"] ~= nil then
				configui.setValue("left_hand_scale", leftParams["Scale"]) -- {X=leftParams["Scale"][1], Y=leftParams["Scale"][2], Z=leftParams["Scale"][3]})
			end
		end
		if rightParams ~= nil  then
			if rightParams["Rotation"] ~= nil then
				configui.setValue("right_hand_rotation", rightParams["Rotation"]) --{X=rightParams["Rotation"][1], Y=rightParams["Rotation"][2], Z=rightParams["Rotation"][3]})
			end
			if rightParams["Location"] ~= nil then
				configui.setValue("right_hand_location", rightParams["Location"])  -- {X=rightParams["Location"][1], Y=rightParams["Location"][2], Z=rightParams["Location"][3]})
			end
			if rightParams["Scale"] ~= nil then
				configui.setValue("right_hand_scale", rightParams["Scale"])  --  {X=rightParams["Scale"][1], Y=rightParams["Scale"][2], Z=rightParams["Scale"][3]})
			end
		end

		bones = {}
		--bones["mesh"] = meshList[selectedMeshIndex]
		bones["names"] = animation.getBoneNames(getMeshComponent())
		configui.setSelections("left_cutoff_bone", bones["names"])
		configui.setSelections("right_cutoff_bone", bones["names"])

		if leftParams ~= nil then
			local currentName = leftParams["Name"]
			local index = configui.getValue("left_cutoff_bone")
			if currentName ~= bones["names"][index] then
				configui.setValue("left_cutoff_bone", 1)
				--configui.setValue("left_cutoff_bone_name" , "")
				leftParams["Name"] = ""
			end
		end

		if rightParams ~= nil then
			local currentName = rightParams["Name"]
			local index = configui.getValue("right_cutoff_bone")
			if currentName ~= bones["names"][index] then
				configui.setValue("right_cutoff_bone", 1)
				--configui.setValue("right_cutoff_bone_name" , "")
				rightParams["Name"] = ""
			end
		end

		updateOptimizationUI()
		updateBoneTransformVisibility()
		updateHands()

		loadInitialTransform()
		updateCutoffChildBonePicker()

		configui.hideWidget("next_button", false)

	end
	if currentStep == 9 then --and knuckles["mesh"] ~= meshList[selectedMeshIndex] then
		--save changes from previous step
		if previousStep == 8 then
			local value = configui.getValue("left_hand_location")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["Location"] = {value.X, value.Y, value.Z}
			end
			value = configui.getValue("left_hand_rotation")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["Rotation"] = {value.X, value.Y, value.Z}
			end
			value = configui.getValue("left_hand_scale")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["Scale"] = {value.X, value.Y, value.Z}
			end

			value = configui.getValue("right_hand_location")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["Location"] = {value.X, value.Y, value.Z}
			end
			value = configui.getValue("right_hand_rotation")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["Rotation"] = {value.X, value.Y, value.Z}
			end
			value = configui.getValue("right_hand_scale")
			if value ~= nil then
				configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["Scale"] = {value.X, value.Y, value.Z}
			end

			configuration["profiles"][selectedProfileName][selectedMeshName]["Right"]["AnimationID"] = "right_" .. string.lower(selectedMeshName)
			configuration["profiles"][selectedProfileName][selectedMeshName]["Left"]["AnimationID"] = "left_" .. string.lower(selectedMeshName)

			saveInitialTransform()

			isConfigurationDirty = true
		end

		configui.hideWidget("code_text", true)
		configui.hideWidget("next_button", true)
		configui.hideWidget("generate_code_instructions", true)

	end
	if currentStep == 10 then
		loadAnimationNames()
		configui.hideWidget("exit_button", false)
		configui.hideWidget("prev_button", true)

		profileMeshNames = getProfileMeshNames()
		configui.setSelections("animation_hands_profile_mesh_list", uevrUtils.getArrayRange(profileMeshNames, 2, #profileMeshNames) )
	end
	if currentStep == 11 then
		if configui.getValue("animations_list") ~= 1 then
			selectedAnimationName = animationNames[configui.getValue("animations_list")]
			configui.setValue("animation_name", selectedAnimationName)
		end
		configui.setLabel("new_animation_title", configui.getValue("animations_list") == 1 and "New Animation" or "Edit Animation")
		configui.hideWidget("new_animation_instructions", configui.getValue("animations_list") ~= 1 )

		selectedMeshName = uevrUtils.getArrayRange(profileMeshNames, 2, #profileMeshNames)[configui.getValue("animation_hands_profile_mesh_list")]
		updateHands()
	end
	if currentStep == 12 then
		selectedAnimationName = configui.getValue("animation_name")
		if configuration["animations"][selectedAnimationName] == nil then
			configuration["animations"][selectedAnimationName] = {}
			isConfigurationDirty = true
		end
		if configuration["animations"][selectedAnimationName]["positions"] == nil then
			configuration["animations"][selectedAnimationName]["positions"] = {}
			isConfigurationDirty = true
		end
		if configuration["animations"][selectedAnimationName]["poses"] == nil then
			local poses = {}
			poses["open_left"] = { {"left_grip","off"}, {"left_trigger","off"}, {"left_thumb","off"} }
			poses["open_right"] = { {"right_grip","off"}, {"right_trigger","off"}, {"right_thumb","off"} }
			poses["grip_right_weapon"] = { {"right_grip_weapon","on"}, {"right_trigger_weapon","off"} }
			poses["grip_left_weapon"] = { {"left_grip_weapon","on"}, {"left_trigger_weapon","off"} }
			configuration["animations"][selectedAnimationName]["poses"] = poses
			isConfigurationDirty = true
		end
		animationPositions = configuration["animations"][selectedAnimationName]["positions"]

		bones = {}
		bones["names"] = animation.getBoneNames(getMeshComponent())

		for _, knuckleName in ipairs(knuckles["names"]) do
			configui.setSelections(knuckleName, bones["names"])
		end
		scanForKnuckleBonesUsingPattern("(ff)_(ii)_(h)")
		scanForKnuckleBonesUsingPattern("(Hh)Hand(Ff)(i)_JNT")
		scanForKnuckleBonesUsingPattern("(Hh)Hand(Ff)(i)")
	end
	if currentStep == 13 then
		updateAttachmentListUI()
		knuckleBoneList = getKnuckleBones()
		-- for index, knuckleIndex in ipairs(knuckleBoneList) do
			-- --print(index, knuckleIndex)
		-- end

		getDefaultRotatorsForAnimations()

		configui.setSelections("animation_finger", getFingerNamesForCurrentAnimationType())

		updateHandAnimation()

		--create default hand states if they dont exist
		createDefaultAnimations()

		--loadWeaponMeshList()
	end
	if currentStep == 14 then
		configui.hideWidget("generate_code_instructions_2", true)
	end

	configui.hideWidget("done_button", not (currentStep == 9 or currentStep == 14))
	configui.hideWidget("test_button", currentStep ~= 13)

end

local function loadConfiguration()
--print("Loading configuration")
	configuration = json.load_file(handConfigurationFileName .. ".json")

	if configuration == nil then
		configuration = {}
	else
		print("Hands configuration found")
	end
	return configuration
end

local function saveConfiguration()
--print("Saving configuration", handConfigurationFileName)
	json.dump_file(handConfigurationFileName .. ".json", configuration, 4)
end

local function initHandsCreator()
	loadConfiguration()
	currentStep = 1
	updateSteps(0)
	configui.hideWidget("not_initialized_warning", true)
end

uevrUtils.registerLevelChangeCallback(function(level)
	controllers.createController(0)
	controllers.createController(1)
	if handsWereCreated then
		hands.reset()
		handsWereCreated = false
	end

	initHandsCreator()
end)

-- uevrUtils.registerOnInputGetStateCallback(function(retval, user_index, state)
-- 	if isTesting then
-- 		if hands.exists() then
-- 			hands.handleInput(state, configui.getValue("animation_test_active_weapon_mode"), configui.getValue("animation_test_left_handed_mode") and Handed.Left or Handed.Right)
-- 		end
-- 	end
-- end)

local timeSinceLastSave = 0
uevrUtils.registerPreEngineTickCallback(function(engine, delta)
	timeSinceLastSave = timeSinceLastSave + delta
	if isConfigurationDirty == true and timeSinceLastSave > 1.0 then
		saveConfiguration()
		isConfigurationDirty = false
		timeSinceLastSave = 0
	end
end)

uevrUtils.registerLevelChangeCallback(function(level)
	if currentStep == 1 then
		controllers.createController(0)
		controllers.createController(1)
		controllers.createController(2)
	end
end)

-- register_key_bind("F1", function()
    -- print("F1 pressed\n")
	-- local descriptor = "Pawn.Mesh(GrenadeMesh).ClothingSimulationFactory"
	-- local component = uevrUtils.getObjectFromDescriptor(descriptor, true)
	-- print(component:get_full_name())
-- end)

return M