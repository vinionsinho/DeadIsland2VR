--[[ 
Input Remapping Module

Usage:
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local remap = require("libs/remap")
        local isDeveloperMode = true  
        remap.init(isDeveloperMode)

    Available functions:

    remap.init(isDeveloperMode, logLevel) - initializes the remapping system with specified mode and log level
        example:
            remap.init(true, LogLevel.Debug)

    remap.setDisabled(val) - enables/disables input remapping globally
        example:
            remap.setDisabled(false)  -- Enable remapping

    remap.applyParameterBasedRemapping(state, remapConfig) - applies parameter-based input remapping to a state
        example:
            remap.applyParameterBasedRemapping(inputState)  -- Use default config
            remap.applyParameterBasedRemapping(inputState, customConfig)  -- Use custom config

    remap.setRemapParameters(newParameters) - sets the remap configuration parameters
        example (multi-state format):
            remap.setRemapParameters({
                left_trigger = {
                    {state = remap.InputState.ON, unpress = true, threshold = 50, actions = {
                        left_shoulder = {state = remap.ActionState.ON},
                        right_trigger = {state = remap.ActionState.ON, value = 200},
                        left_stick_x = {state = remap.ActionState.ON, value = 16384}
                    }},
                    {state = remap.InputState.OFF, actions = {
                        right_shoulder = {state = remap.ActionState.OFF}
                    }}
                },
                left_stick_x = {
                    {state = remap.InputState.ON, unpress = true, threshold = 4096, actions = {
                        a_button = {state = remap.ActionState.ON}
                    }}
                }
            })

    remap.getRemapParameters() - gets the current remap configuration parameters
        example:
            local currentConfig = remap.getRemapParameters()

    remap.loadParameters(fileName) - loads remap configuration from a file
        example:
            remap.loadParameters("my_remap_config")

    remap.showDeveloperConfiguration() - creates and shows developer configuration UI
        example:
            remap.showDeveloperConfiguration()

    remap.addRemapConfigToUI(configDefinition, remapConfig) - adds remap configuration to an existing UI definition
        example:
            local configDef = getMyConfigDefinition()
            remap.addRemapConfigToUI(configDef)

    remap.addNewInputMapping(inputName) - adds a new input mapping to the configuration
        example:
            remap.addNewInputMapping("right_trigger")

    remap.removeInputMapping(inputName) - removes an input mapping from the configuration
        example:
            remap.removeInputMapping("left_trigger")

    remap.addActionToInput(inputName, actionName) - adds an action to an existing input mapping
        example:
            remap.addActionToInput("left_trigger", "right_shoulder")

    remap.removeActionFromInput(inputName, actionName) - removes an action from an input mapping
        example:
            remap.removeActionFromInput("left_trigger", "right_shoulder")

    remap.refreshUI() - refreshes the configuration UI to reflect changes
        example:
            remap.refreshUI()

    remap.setLogLevel(val) - sets the logging level for remap messages
        example:
            remap.setLogLevel(LogLevel.Debug)

    remap.print(text, logLevel) - prints a message with the specified log level
        example:
            remap.print("Remapping applied", LogLevel.Info)

]]--

--[[
			Letters: "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"

			Arrow keys: "Left", "Up", "Right", "Down"

			Numbers (above alphabet, below function keys): "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"

			NumPad: "NumPadZero", "NumPadOne", "NumPadTwo", "NumPadThree", "NumPadFour", "NumPadFive", "NumPadSix", "NumPadSeven", "NumPadEight", "NumPadNine"

			NumPad operators: "Multiply", "Add", "Subtract", "Decimal", "Divide"

			Control keys: "BackSpace", "Tab", "Enter", "Pause", "NumLock", "ScrollLock", "CapsLock", "Escape", "SpaceBar", "PageUp", "PageDown", "End", "Home", "Insert", "Delete"

			Function keys: "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"

			Modifier keys: "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt", "LeftCommand", "RightCommand"

			Symbols: "Semicolon", "Equals", "Comma", "Underscore", "Period", "Slash", "Tilde", "LeftBracket", "Backslash", "RightBracket", "Quote"

			# Mouse
			Axes: "MouseX", "MouseY", "MouseScrollUp", "MouseScrollDown", "MouseWheelSpin"
			Note: There is a comment in InputCoreTypes stating that the viewport clients use "MouseScrollUp" and "MouseScrollDown" while Slate uses "MouseWheelSpin". Epic plan to merge these in the future.

			Buttons: "LeftMouseButton", "RightMouseButton", "MiddleMouseButton", "ThumbMouseButton", "ThumbMouseButton2"

			# Gamepads
			Analog sticks: "Gamepad_LeftX", "Gamepad_LeftY", "Gamepad_RightX", "Gamepad_RightY"
			Triggers: "Gamepad_LeftTriggerAxis", "Gamepad_RightTriggerAxis"
			Stick buttons: "Gamepad_LeftThumbstick", "Gamepad_RightThumbstick"
			Special buttons: "Gamepad_Special_Left", "Gamepad_Special_Right"
			Face buttons: "Gamepad_FaceButton_Bottom", "Gamepad_FaceButton_Right", "Gamepad_FaceButton_Left", "Gamepad_FaceButton_Top"
			Shoulder buttons: "Gamepad_LeftShoulder", "Gamepad_RightShoulder", "Gamepad_LeftTrigger", "Gamepad_RightTrigger"
			D-Pad: "Gamepad_DPad_Up", "Gamepad_DPad_Down", "Gamepad_DPad_Right", "Gamepad_DPad_Left"

			Virtual key codes for input axis button press/release emulation:
			Left stick: "Gamepad_LeftStick_Up", "Gamepad_LeftStick_Down", "Gamepad_LeftStick_Right", "Gamepad_LeftStick_Left"
			Right stick: "Gamepad_RightStick_Up", "Gamepad_RightStick_Down", "Gamepad_RightStick_Right", "Gamepad_RightStick_Left"

			# Touch Devices
			Motion: "Tilt", "RotationRate", "Gravity", "Acceleration"
			Gestures: "Gesture_SwipeLeftRight", "Gesture_SwipeUpDown", "Gesture_TwoFingerSwipeLeftRight", "Gesture_TwoFingerSwipeUpDown", "Gesture_Pinch", "Gesture_Flick"
			Special: "PS4_Special"
]]--
local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local CONSTANTS = {
    TRIGGER_MAX = 255,
    TRIGGER_MIN = 0,
    ANALOG_MAX = 32767,
    ANALOG_MIN = -32768,
    DEFAULT_TRIGGER_THRESHOLD = 100,
    DEFAULT_ANALOG_THRESHOLD = 8192
}

local isDisabled = false
local isDisabledOverride = false
local currentLogLevel = LogLevel.Error
local isDeveloperMode = false
local isRefreshing = false  -- Flag to prevent callback loops during UI refresh
local callbacksRegistered = false  -- Flag to ensure callbacks are only registered once

-- Profile management variables
local currentEditingProfile = "default"

function M.setLogLevel(val)
    currentLogLevel = val
end

function M.print(text, logLevel)
    if logLevel == nil then logLevel = LogLevel.Debug end
    if logLevel <= currentLogLevel then
        uevrUtils.print("[remap] " .. text, logLevel)
    end
end


M.rawRightShoulderPressed = false
M.rawLeftShoulderPressed = false
M.rawRightTriggerPressed = false
M.rawLeftTriggerPressed = false
M.rawAButtonPressed = false
M.rawBButtonPressed = false
M.rawXButtonPressed = false
M.rawYButtonPressed = false
M.rawLeftStickXPressed = false
M.rawLeftStickYPressed = false
M.rawRightStickXPressed = false
M.rawRightStickYPressed = false
M.rawLeftStickPressPressed = false
M.rawRightStickPressPressed = false
M.rawDpadUpPressed = false
M.rawDpadDownPressed = false
M.rawDpadLeftPressed = false
M.rawDpadRightPressed = false
M.rawStartButtonPressed = false
M.rawBackButtonPressed = false

M.InputState =
{
    NONE = "none",
    ON = "on",
    OFF = "off",
    TOGGLE_ON = "toggle_on",
    TOGGLE_OFF = "toggle_off"
}

M.ActionState =
{
    NONE = "none",
    ON = "on",
    OFF = "off",
    TOGGLE_ON = "toggle_on",
    TOGGLE_OFF = "toggle_off",
    COPY_VALUE = "copy_value"
}

local parametersFileName = "remap_parameters"
local isParametersDirty = false

local parameters = {}
parameters["remap"] = {
    right_shoulder = {{state = M.InputState.ON, unpress = true}, {state = M.InputState.OFF, actions = {}}},
    left_shoulder = {{state = M.InputState.ON, unpress = true, actions = {right_shoulder = {state = M.ActionState.ON}}}},
    left_trigger = {{state = M.InputState.ON, unpress = true, threshold = CONSTANTS.DEFAULT_TRIGGER_THRESHOLD, actions = {left_shoulder = {state = M.ActionState.ON}}}},
    right_trigger = {{state = M.InputState.ON, unpress = true, threshold = CONSTANTS.DEFAULT_TRIGGER_THRESHOLD, actions = {}}},
}

-- Mapping of input names to XINPUT constants and state locations
local inputMapping = {
    right_shoulder = {constant = XINPUT_GAMEPAD_RIGHT_SHOULDER, type = "button"},
    left_shoulder = {constant = XINPUT_GAMEPAD_LEFT_SHOULDER, type = "button"},
    left_trigger = {stateField = "bLeftTrigger", type = "trigger"},
    right_trigger = {stateField = "bRightTrigger", type = "trigger"},
    a_button = {constant = XINPUT_GAMEPAD_A, type = "button"},
    b_button = {constant = XINPUT_GAMEPAD_B, type = "button"},
    x_button = {constant = XINPUT_GAMEPAD_X, type = "button"},
    y_button = {constant = XINPUT_GAMEPAD_Y, type = "button"},
    left_stick_x = {stateField = "sThumbLX", type = "analog", axis = "x"},
    left_stick_y = {stateField = "sThumbLY", type = "analog", axis = "y"},
    right_stick_x = {stateField = "sThumbRX", type = "analog", axis = "x"},
    right_stick_y = {stateField = "sThumbRY", type = "analog", axis = "y"},
    left_stick_press = {constant = XINPUT_GAMEPAD_LEFT_THUMB, type = "button"},
    right_stick_press = {constant = XINPUT_GAMEPAD_RIGHT_THUMB, type = "button"},
    dpad_up = {constant = XINPUT_GAMEPAD_DPAD_UP, type = "button"},
    dpad_down = {constant = XINPUT_GAMEPAD_DPAD_DOWN, type = "button"},
    dpad_left = {constant = XINPUT_GAMEPAD_DPAD_LEFT, type = "button"},
    dpad_right = {constant = XINPUT_GAMEPAD_DPAD_RIGHT, type = "button"},
    start_button = {constant = XINPUT_GAMEPAD_START, type = "button"},
    back_button = {constant = XINPUT_GAMEPAD_BACK, type = "button"}
}

-- State value constants used throughout the module
local actionStateSelections = {"None", "Press", "Unpress", "Toggle On", "Toggle Off"}
local actionStateValues = {M.ActionState.NONE, M.ActionState.ON, M.ActionState.OFF, M.ActionState.TOGGLE_ON, M.ActionState.TOGGLE_OFF}

-- Separate value arrays for different action types to ensure proper index mapping
local buttonActionStateValues = {M.ActionState.NONE, M.ActionState.ON, M.ActionState.OFF, M.ActionState.TOGGLE_ON, M.ActionState.TOGGLE_OFF}
local triggerActionStateValues = {M.ActionState.NONE, M.ActionState.ON, M.ActionState.OFF, M.ActionState.TOGGLE_ON, M.ActionState.TOGGLE_OFF, M.ActionState.COPY_VALUE}
local analogActionStateValues = {M.ActionState.NONE, M.ActionState.ON, M.ActionState.OFF, M.ActionState.COPY_VALUE}

-- Configurable input states - can be extended in the future
local inputStates = {
    {
        key = M.InputState.ON,
        labels = {
            button = "While Pressed",
            trigger = "While Pressed",
            analog = "While Active"
        }
    },
    {
        key = M.InputState.OFF,
        labels = {
            button = "While Unpressed",
            trigger = "While Unpressed",
            analog = "While Inactive"
        }
    },
    {
        key = M.InputState.TOGGLE_ON,
        labels = {
            button = "When Toggled On",
            trigger = "When Toggled On",
            analog = "When Toggled Active"
        }
    },
    {
        key = M.InputState.TOGGLE_OFF,
        labels = {
            button = "When Toggled Off",
            trigger = "When Toggled Off",
            analog = "When Toggled Inactive"
        }
    }
    -- Future states can be added here, e.g.:
    -- {
    --     key = "held",
    --     labels = {
    --         button = "Held",
    --         trigger = "Held",
    --         analog = "Held"
    --     }
    -- }
}

-- Input processing order - ensures consistent UI layout and processing
local inputOrder = {"right_shoulder", "left_shoulder", "left_trigger", "right_trigger", "a_button", "b_button", "x_button", "y_button", "left_stick_x", "left_stick_y", "right_stick_x", "right_stick_y", "left_stick_press", "right_stick_press", "dpad_up", "dpad_down", "dpad_left", "dpad_right", "start_button", "back_button"}

-- All available actions (same as inputs since any input can trigger any other input)
local allActions = {"right_shoulder", "left_shoulder", "left_trigger", "right_trigger", "a_button", "b_button", "x_button", "y_button", "left_stick_x", "left_stick_y", "right_stick_x", "right_stick_y", "left_stick_press", "right_stick_press", "dpad_up", "dpad_down", "dpad_left", "dpad_right", "start_button", "back_button"}

-- Pre-compiled optimization tables (regenerated when parameters change)
local compiledRemapConfig = nil
local compiledInputs = {}
local compiledActions = {}

-- Previous state tracking for momentary input detection
local previousInputStates = {}

-- Pre-compile the remap configuration for optimal performance
local function compileRemapConfig(remapConfig)
    compiledInputs = {}

    for inputName, configs in pairs(remapConfig) do
        local mapping = inputMapping[inputName]
        if mapping then
            -- Handle both array format and legacy single config format
            local configArray = configs
            if not configs[1] then
                -- Legacy format: single config object, convert to array
                configArray = {configs}
            end

            -- Pre-compile thresholds and action executors for each config
            local precompiledConfigs = {}
            for _, config in ipairs(configArray) do
                local compiledConfig = {
                    state = config.state,
                    unpress = config.unpress,
                    threshold = config.threshold or (mapping.type == "analog" and CONSTANTS.DEFAULT_ANALOG_THRESHOLD or CONSTANTS.DEFAULT_TRIGGER_THRESHOLD),
                    actionExecutors = {}  -- Pre-compiled action execution functions
                }

                -- Pre-compile action executors for maximum runtime performance
                if config.actions then
                    for actionName, actionConfig in pairs(config.actions) do
                        local actionMapping = inputMapping[actionName]
                        if actionMapping then
                            -- Create optimized action executor closures
                            local actionExecutor = nil
                            
                            if actionConfig.state == M.ActionState.ON or actionConfig.state == M.ActionState.TOGGLE_ON then
                                if actionMapping.type == "button" then
                                    actionExecutor = function(state, sourceValues) uevrUtils.pressButton(state, actionMapping.constant) end
                                elseif actionMapping.type == "trigger" then
                                    local value = actionConfig.value or CONSTANTS.TRIGGER_MAX
                                    actionExecutor = function(state, sourceValues) state.Gamepad[actionMapping.stateField] = value end
                                elseif actionMapping.type == "analog" then
                                    local value = actionConfig.value or CONSTANTS.ANALOG_MAX
                                    actionExecutor = function(state, sourceValues) state.Gamepad[actionMapping.stateField] = value end
                                end
                            elseif actionConfig.state == M.ActionState.OFF or actionConfig.state == M.ActionState.TOGGLE_OFF then
                                if actionMapping.type == "button" then
                                    actionExecutor = function(state, sourceValues) uevrUtils.unpressButton(state, actionMapping.constant) end
                                elseif actionMapping.type == "trigger" then
                                    local value = actionConfig.value or 0
                                    actionExecutor = function(state, sourceValues) state.Gamepad[actionMapping.stateField] = value end
                                elseif actionMapping.type == "analog" then
                                    local value = actionConfig.value or 0
                                    actionExecutor = function(state, sourceValues) state.Gamepad[actionMapping.stateField] = value end
                                end
                            elseif actionConfig.state == M.ActionState.COPY_VALUE then
                                if actionMapping.type == "analog" and mapping.type == "analog" then
                                    actionExecutor = function(state, sourceValues) 
                                        local sourceValue = sourceValues[inputName] or 0
                                        state.Gamepad[actionMapping.stateField] = sourceValue
                                    end
                                elseif actionMapping.type == "trigger" and mapping.type == "analog" then
                                    actionExecutor = function(state, sourceValues)
                                        local sourceValue = sourceValues[inputName] or 0
                                        local normalizedValue = math.max(0, sourceValue + math.abs(CONSTANTS.ANALOG_MIN)) / (CONSTANTS.ANALOG_MAX - CONSTANTS.ANALOG_MIN)
                                        state.Gamepad[actionMapping.stateField] = math.floor(normalizedValue * CONSTANTS.TRIGGER_MAX)
                                    end
                                end
                            end
                            
                            if actionExecutor then
                                compiledConfig.actionExecutors[actionName] = actionExecutor
                            end
                        end
                    end
                end

                table.insert(precompiledConfigs, compiledConfig)
            end

            -- Pre-compile input detection info
            compiledInputs[inputName] = {
                mapping = mapping,
                configs = precompiledConfigs,
                rawStateVar = "raw" .. inputName:gsub("_(%l)", string.upper):gsub("^%l", string.upper) .. "Pressed",
                -- Pre-compile activation threshold for previous state tracking
                activationThreshold = precompiledConfigs[1] and precompiledConfigs[1].threshold or (mapping.type == "analog" and CONSTANTS.DEFAULT_ANALOG_THRESHOLD or CONSTANTS.DEFAULT_TRIGGER_THRESHOLD)
            }
        end
    end

    compiledRemapConfig = remapConfig
end

-- Optimized reusable function to process input remapping based on parameters
local function processInputRemapping(state, remapConfig)
    -- Only recompile if config changed
    if compiledRemapConfig ~= remapConfig then
        compileRemapConfig(remapConfig)
    end

    -- Reset all raw state variables at the start of each frame
    for inputName, compiledInput in pairs(compiledInputs) do
        M[compiledInput.rawStateVar] = false
    end

    local sourceValues = {}  -- Store original source values for copy_value functionality

    -- First pass: capture all original input states before any modifications
    for inputName, compiledInput in pairs(compiledInputs) do
        local mapping = compiledInput.mapping

        if mapping.type == "button" then
            sourceValues[inputName] = uevrUtils.isButtonPressed(state, mapping.constant)
        elseif mapping.type == "trigger" then
            sourceValues[inputName] = state.Gamepad[mapping.stateField]
        elseif mapping.type == "analog" then
            sourceValues[inputName] = state.Gamepad[mapping.stateField]
        end
    end

    -- Second pass: process inputs and execute pre-compiled actions
    for inputName, compiledInput in pairs(compiledInputs) do
        local mapping = compiledInput.mapping
        local configs = compiledInput.configs
        local currentInputValue = sourceValues[inputName]

        -- Check each state configuration for this input
        for _, config in ipairs(configs) do
            local isActivated = false

            -- Check activation state using pre-compiled threshold
            if mapping.type == "button" then
                isActivated = currentInputValue
                if isActivated and config.unpress then
                    uevrUtils.unpressButton(state, mapping.constant)
                end
            elseif mapping.type == "trigger" then
                isActivated = currentInputValue > config.threshold
                if isActivated and config.unpress then
                    state.Gamepad[mapping.stateField] = 0
                end
            elseif mapping.type == "analog" then
                isActivated = math.abs(currentInputValue) > config.threshold
                if isActivated and config.unpress then
                    state.Gamepad[mapping.stateField] = 0
                end
            end

            -- Get previous state for momentary detection
            local previousState = previousInputStates[inputName] or false
            local shouldExecuteActions = false

            -- Determine if actions should be executed based on state logic
            if config.state == M.InputState.ON and isActivated then
                shouldExecuteActions = true
            elseif config.state == M.InputState.OFF and not isActivated then
                shouldExecuteActions = true
            elseif config.state == M.InputState.TOGGLE_ON and isActivated and not previousState then
                shouldExecuteActions = true
            elseif config.state == M.InputState.TOGGLE_OFF and not isActivated and previousState then
                shouldExecuteActions = true
            end

            if shouldExecuteActions then
                -- Store raw state for external access
                M[compiledInput.rawStateVar] = true

                -- Execute all pre-compiled action executors for this config
                for actionName, actionExecutor in pairs(config.actionExecutors) do
                    actionExecutor(state, sourceValues)
                end
            end
        end
    end

    -- Update previous states for next frame using pre-compiled thresholds
    for inputName, compiledInput in pairs(compiledInputs) do
        local mapping = compiledInput.mapping
        local currentValue = sourceValues[inputName]
        local isCurrentlyActivated = false

        if mapping.type == "button" then
            isCurrentlyActivated = currentValue
        elseif mapping.type == "trigger" then
            isCurrentlyActivated = currentValue > compiledInput.activationThreshold
        elseif mapping.type == "analog" then
            isCurrentlyActivated = math.abs(currentValue) > compiledInput.activationThreshold
        end

        previousInputStates[inputName] = isCurrentlyActivated
    end
end

-- Stub function to process FKEY actions (to be implemented)
-- local function processFKeyActions(state)
--     -- TODO: Implement FKEY action processing
--     -- This function will handle keyboard input simulation
--     -- User will provide the implementation details later
-- end

local helpText = "This module allows you to configure input remapping for VR controllers. You can remap buttons (pressed/unpressed), triggers (pressed/unpressed), and analog sticks (active/inactive) to different actions, set trigger and stick thresholds, and enable/disable specific inputs. The system processes input remapping on every frame for optimal responsiveness."

-- Function to add FKEY actions UI
-- local function addFKeyActionsUI(configDefinition)
--     -- FKEY Selection dropdown
--     table.insert(configDefinition[1]["layout"], {
--         widgetType = "indent",
--         width = 10
--     })
--     
--     table.insert(configDefinition[1]["layout"], {
--         id = "fkey_selection",
--         label = "FKEY",
--         widgetType = "combo",
--         selections = {
--             -- Function keys
--             "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
--             -- Letters
--             "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
--             -- Numbers (above alphabet)
--             "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
--             -- NumPad
--             "NumPadZero", "NumPadOne", "NumPadTwo", "NumPadThree", "NumPadFour", "NumPadFive", "NumPadSix", "NumPadSeven", "NumPadEight", "NumPadNine",
--             -- NumPad operators
--             "Multiply", "Add", "Subtract", "Decimal", "Divide",
--             -- Control keys
--             "BackSpace", "Tab", "Enter", "Pause", "NumLock", "ScrollLock", "CapsLock", "Escape", "SpaceBar", "PageUp", "PageDown", "End", "Home", "Insert", "Delete",
--             -- Arrow keys
--             "Left", "Up", "Right", "Down",
--             -- Modifier keys
--             "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt", "LeftCommand", "RightCommand",
--             -- Symbols
--             "Semicolon", "Equals", "Comma", "Underscore", "Period", "Slash", "Tilde", "LeftBracket", "Backslash", "RightBracket", "Quote"
--         },
--         initialValue = 1,
--         width = 120
--     })
--     
--     table.insert(configDefinition[1]["layout"], {
--         widgetType = "same_line"
--     })
--     
--     -- Add FKEY Action button
--     table.insert(configDefinition[1]["layout"], {
--         widgetType = "button",
--         id = "add_fkey_action",
--         label = "Add FKEY Action"
--     })
--     
--     table.insert(configDefinition[1]["layout"], { widgetType = "new_line" })
--     
--     -- TODO: Add existing FKEY actions list here
--     table.insert(configDefinition[1]["layout"], {
--         widgetType = "text",
--         label = "FKEY actions will be listed here (implementation pending)",
--         wrapped = true
--     })
--     
--     table.insert(configDefinition[1]["layout"], {
--         widgetType = "unindent",
--         width = 10
--     })
-- end

function M.addRemapConfigToUI(configDefinition, m_remapConfig)
    if m_remapConfig == nil then m_remapConfig = parameters[currentEditingProfile] end

    table.insert(configDefinition[1]["layout"], {
        widgetType = "checkbox",
        id = "remap_disabled",
        label = "Disable Input Remapping",
        initialValue = isDisabledOverride
    })
    table.insert(configDefinition[1]["layout"], { widgetType = "new_line" })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "indent",
        width = 10
    })


        -- Profile Management Section
    -- Current profile display and selector
    local profileList = M.getProfileList()
    local profileLabels = M.getProfileLabels()
    local currentProfileIndex = 1
    for i, profile in ipairs(profileList) do
        if profile == currentEditingProfile then
            currentProfileIndex = i
            break
        end
    end

    table.insert(configDefinition[1]["layout"], {
        widgetType = "combo",
        id = "remap_active_profile",
        label = "Profile",
        selections = profileLabels,
        initialValue = currentProfileIndex,
        width = 200
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "same_line"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "button",
        id = "remap_rename_profile",
        label = "Rename"
    })

    -- Rename input field (initially hidden)
    table.insert(configDefinition[1]["layout"], {
        widgetType = "begin_group",
        id = "remap_rename_group",
        isHidden = true
    })
    
    table.insert(configDefinition[1]["layout"], {
        widgetType = "input_text",
        id = "remap_rename_input",
        label = "",
        initialValue = "",
        width = 200
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "same_line"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "button",
        id = "remap_rename_update",
        label = "Update"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "end_group"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "tree_node",
        id = "remap_configuration",
        initialOpen = true,
        label = "Input Remap Configuration"
    })

    -- Always show all available inputs, regardless of whether they have configurations
    -- Process inputs in a specific order to ensure consistency
    for _, inputName in ipairs(inputOrder) do
        local mapping = inputMapping[inputName]
        if mapping then
            -- Always use the current editing profile for UI state determination
            -- This ensures we always reflect the actual current state
            local currentConfigArray = parameters[currentEditingProfile] and parameters[currentEditingProfile][inputName]

            -- Handle both array format and legacy format, get first config for UI display
            local currentConfig = nil
            if currentConfigArray then
                if currentConfigArray[1] then
                    -- Array format
                    currentConfig = currentConfigArray[1]
                else
                    -- Legacy format
                    currentConfig = currentConfigArray
                end
            end

            -- Determine which states are currently configured
            local configuredStates = {}
            local stateConfigs = {}

            if currentConfigArray then
                local configs = currentConfigArray
                if not configs[1] then
                    -- Legacy format: convert to array for checking
                    configs = {configs}
                end

                for _, config in ipairs(configs) do
                    if config.state then
                        configuredStates[config.state] = true
                        stateConfigs[config.state] = config
                    end
                end
            end

            local treeNodeConfig = {
                id = "remap_" .. inputName,
                label = inputName:gsub("_", " "):gsub("^%l", string.upper),
                widgetType = "tree_node"
            }

            -- Only color inputs that have at least one configured state (pressed or unpressed checkbox checked)
            if next(configuredStates) ~= nil then
                treeNodeConfig.color = "#0088FFFF"
            end

            table.insert(configDefinition[1]["layout"], treeNodeConfig)

            -- Helper function to add actions for a specific state
            local function addActionsForState(stateType, stateLabel, stateConfig)
                -- Always show actions section when state is enabled, even if no config exists yet

                -- Check if any actions are configured (not "None") for this state
                local hasConfiguredActions = false
                if stateConfig and stateConfig.actions then
                    for actionName, actionConfig in pairs(stateConfig.actions) do
                        if actionConfig and actionConfig.state and actionConfig.state ~= M.ActionState.NONE then
                            hasConfiguredActions = true
                            break
                        end
                    end
                end

                local actionsTreeConfig = {
                    id = "remap_" .. inputName .. "_" .. stateType .. "_actions",
                    label = "Actions",
                    widgetType = "tree_node",
                    initialOpen = false,
                }

                -- Apply blue coloring if any actions are configured
                if hasConfiguredActions then
                    actionsTreeConfig.color = "#0088FFFF"
                end

                table.insert(configDefinition[1]["layout"], actionsTreeConfig)

                -- List all possible actions for this state
                for _, actionName in ipairs(allActions) do
                    -- Don't show an action targeting itself
                    if actionName ~= inputName then
                        local actionConfig = stateConfig and stateConfig.actions and stateConfig.actions[actionName]
                        local actionLabel = actionName:gsub("_", " "):gsub("^%l", string.upper)
                        local currentActionStateIndex = 1  -- Default to "None"

                        -- Use the action's current state if it exists
                        if actionConfig and actionConfig.state then
                            for i, value in ipairs(actionStateValues) do
                                if actionConfig.state == value then
                                    currentActionStateIndex = i
                                    break
                                end
                            end
                        end

                        table.insert(configDefinition[1]["layout"], {
                            label = actionLabel,
                            widgetType = "text"
                        })
                        table.insert(configDefinition[1]["layout"], {
                            widgetType = "same_line",
                        })

                        table.insert(configDefinition[1]["layout"], {
                            widgetType = "set_x",
                            x = 210
                        })

                        -- Use action-type specific state labels  
                        local actionStateSelectionsToUse = actionStateSelections
                        local actionMapping = inputMapping[actionName]
                        local sourceMapping = inputMapping[inputName]

                        if actionMapping and (actionMapping.type == "analog" or actionMapping.type == "trigger") then
                            if sourceMapping and (sourceMapping.type == "analog" or sourceMapping.type == "trigger") then
                                -- Show Copy Value for analog/trigger inputs targeting analog/trigger actions
                                if actionMapping.type == "analog" then
                                    actionStateSelectionsToUse = {"None", "Activate", "Deactivate", "Copy Value"}
                                else -- trigger
                                    actionStateSelectionsToUse = {"None", "Press", "Unpress", "Toggle On", "Toggle Off", "Copy Value"}
                                end
                            else
                                if actionMapping.type == "analog" then
                                    actionStateSelectionsToUse = {"None", "Activate", "Deactivate"}
                                else -- trigger
                                    actionStateSelectionsToUse = {"None", "Press", "Unpress", "Toggle On", "Toggle Off"}
                                end
                            end
                        end

                        table.insert(configDefinition[1]["layout"], {
                            id = "remap_" .. inputName .. "_" .. stateType .. "_action_" .. actionName .. "_state",
                            label = " ",
                            widgetType = "combo",
                            selections = actionStateSelectionsToUse,
                            initialValue = currentActionStateIndex,
                            width = 100
                        })

                        -- Add value input for trigger and analog actions
                        if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") then
                            local currentValue = actionConfig and actionConfig.value
                            local defaultValue, label

                            -- Check if current action state is copy_value or none
                            local isCurrentlyCopyValue = actionConfig and actionConfig.state == M.ActionState.COPY_VALUE
                            local isCurrentlyNone = not actionConfig or actionConfig.state == M.ActionState.NONE

                            if actionMapping.type == "trigger" then
                                defaultValue = tostring(currentValue or CONSTANTS.TRIGGER_MAX)
                                label = "Value"
                            else -- analog
                                defaultValue = tostring(currentValue or CONSTANTS.ANALOG_MAX)
                                label = "Value"
                            end

                            -- Always add value input wrapped in group, but may be hidden initially
                            table.insert(configDefinition[1]["layout"], {
                                widgetType = "begin_group",
                                id = "remap_" .. inputName .. "_" .. stateType .. "_action_" .. actionName .. "_value_group",
                                isHidden = isCurrentlyCopyValue or isCurrentlyNone  -- Hide if copy_value or none
                            })
                            table.insert(configDefinition[1]["layout"], {
                                widgetType = "same_line",
                            })
                            table.insert(configDefinition[1]["layout"], {
                                id = "remap_" .. inputName .. "_" .. stateType .. "_action_" .. actionName .. "_value",
                                label = label,
                                widgetType = "input_text",
                                initialValue = defaultValue,
                                width = 60
                            })
                            table.insert(configDefinition[1]["layout"], {
                                widgetType = "end_group"
                            })
                        end
                    end
                end

                table.insert(configDefinition[1]["layout"], {
                    widgetType = "tree_pop"
                })
            end

            -- Generate UI for each possible input state
            for _, inputState in ipairs(inputStates) do
                local stateKey = inputState.key
                local stateLabel = inputState.labels[mapping.type] or inputState.labels.button
                local hasStateConfig = configuredStates[stateKey] or false
                local stateConfig = stateConfigs[stateKey]

                -- State checkbox
                table.insert(configDefinition[1]["layout"], {
                    id = "remap_" .. inputName .. "_" .. stateKey,
                    label = stateLabel,
                    widgetType = "checkbox",
                    initialValue = hasStateConfig
                })

                -- State actions group (always added, but may be hidden)
                table.insert(configDefinition[1]["layout"], {
                    widgetType = "begin_group",
                    id = "remap_" .. inputName .. "_" .. stateKey .. "_group",
                    isHidden = not hasStateConfig
                })

                -- Add shared configuration options for this state
                table.insert(configDefinition[1]["layout"], {
                    widgetType = "indent",
                    width = 20
                })

                -- Threshold for triggers and analog sticks (only for first state to avoid duplicates)
                if stateKey == inputStates[1].key then
                    if mapping.type == "trigger" then
                        table.insert(configDefinition[1]["layout"], {
                            id = "remap_" .. inputName .. "_threshold",
                            label = "Deadzone",
                            widgetType = "drag_int",
                            speed = 1,
                            range = {1, CONSTANTS.TRIGGER_MAX},
                            initialValue = (stateConfig and stateConfig.threshold) or CONSTANTS.DEFAULT_TRIGGER_THRESHOLD,
                            width = 60
                        })
                        table.insert(configDefinition[1]["layout"], {
                            widgetType = "same_line"
                        })
                    elseif mapping.type == "analog" then
                        table.insert(configDefinition[1]["layout"], {
                            id = "remap_" .. inputName .. "_threshold",
                            label = "Stick Threshold",
                            widgetType = "drag_int",
                            speed = 100,
                            range = {1, CONSTANTS.ANALOG_MAX},
                            initialValue = (stateConfig and stateConfig.threshold) or CONSTANTS.DEFAULT_ANALOG_THRESHOLD,
                            width = 120
                        })
                        table.insert(configDefinition[1]["layout"], {
                            widgetType = "same_line"
                        })
                    end
                end

                -- Unpress configuration (only for active states - on and toggled_on)
                if stateKey == M.InputState.ON or stateKey == M.InputState.TOGGLE_ON then
                    table.insert(configDefinition[1]["layout"], {
                        id = "remap_" .. inputName .. "_" .. stateKey .. "_unpress",
                        label = "Unpress Original Input",
                        widgetType = "checkbox",
                        initialValue = (stateConfig and stateConfig.unpress) == true
                    })
                end

                -- Add actions for this state (always add, visibility controlled by hideWidget)
                addActionsForState(stateKey, stateLabel, stateConfig)

                table.insert(configDefinition[1]["layout"], {
                    widgetType = "unindent",
                    width = 20
                })

                table.insert(configDefinition[1]["layout"], {
                    widgetType = "end_group"
                })
            end

            table.insert(configDefinition[1]["layout"], {
                widgetType = "tree_pop"
            })
        end  -- End of if mapping then
    end  -- End of for _, inputName in ipairs(inputOrder) do

    table.insert(configDefinition[1]["layout"], {
        widgetType = "tree_pop"
    })

    table.insert(configDefinition[1]["layout"], { widgetType = "new_line" })

    -- Profile management buttons
    table.insert(configDefinition[1]["layout"], {
        widgetType = "button",
        id = "remap_new_profile",
        label = "New Profile"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "same_line"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "button",
        id = "remap_duplicate_profile",
        label = "Duplicate Profile"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "same_line"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "button",
        id = "remap_delete_profile", 
        label = "Delete Profile"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "unindent",
        width = 10
    })

    table.insert(configDefinition[1]["layout"], { widgetType = "new_line" })

    -- FKEY Actions tree node
    -- table.insert(configDefinition[1]["layout"], {
    --     widgetType = "tree_node",
    --     id = "remap_fkey_actions_tree",
    --     initialOpen = false,
    --     label = "FKEY Actions"
    -- })

    -- Add FKEY actions UI here
    -- addFKeyActionsUI(configDefinition)

    -- table.insert(configDefinition[1]["layout"], {
    --     widgetType = "tree_pop"
    -- })

    -- table.insert(configDefinition[1]["layout"], { widgetType = "new_line" })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "tree_node",
        id = "remap_help_tree",
        initialOpen = true,
        label = "Help"
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "text",
        id = "remap_help",
        label = helpText,
        wrapped = true
    })

    table.insert(configDefinition[1]["layout"], {
        widgetType = "tree_pop"
    })

    return configDefinition
end

-- Separate function to register callbacks (should only be called once)
function M.registerUICallbacks()
    if callbacksRegistered then return end  -- Prevent duplicate registration
    callbacksRegistered = true
    
    configui.onUpdate("remap_disabled", function(value)
        M.setDisabled(value)
    end)

    -- Profile management callbacks
    configui.onUpdate("remap_active_profile", function(value)
        if isRefreshing then return end
        local profileList = M.getProfileList()
        local selectedProfile = profileList[value]
        if selectedProfile and selectedProfile ~= currentEditingProfile then
            M.setCurrentEditingProfile(selectedProfile)
            -- Refresh UI but preserve the profile combo selection
            M.refreshUI()
            -- Restore the combo selection after refresh
            configui.setValue("remap_active_profile", value)
        end
    end)

    configui.onUpdate("remap_new_profile", function()
        -- Generate human-readable profile name
        local profileList = M.getProfileList()
        local profileNumber = #profileList + 1
        local newId = "profile_" .. profileNumber
        local newLabel = "Profile " .. profileNumber
        
        -- Ensure unique ID
        while parameters[newId] do
            profileNumber = profileNumber + 1
            newId = "profile_" .. profileNumber
            newLabel = "Profile " .. profileNumber
        end
        
        if M.createNewProfile(newId) then
            M.setProfileLabel(newId, newLabel)
            currentEditingProfile = newId
            
            -- Update combo box options to include the new profile
            local profileLabels = M.getProfileLabels()
            configui.setSelections("remap_active_profile", profileLabels)
            
            -- Find the index of the new profile and select it
            local profileList = M.getProfileList()
            local newProfileIndex = 1
            for i, profile in ipairs(profileList) do
                if profile == newId then
                    newProfileIndex = i
                    break
                end
            end
            
            -- Set the combo to the new profile and refresh UI
            configui.setValue("remap_active_profile", newProfileIndex)
            M.refreshUI()
        end
    end)

    configui.onUpdate("remap_duplicate_profile", function()
        local currentLabel = M.getProfileLabel(currentEditingProfile)
        local baseNewId = currentEditingProfile .. "_copy"
        local baseNewLabel = currentLabel .. " Copy"
        
        local newId = baseNewId
        local newLabel = baseNewLabel
        local counter = 1
        
        while parameters[newId] do
            counter = counter + 1
            newId = currentEditingProfile .. "_copy_" .. counter
            newLabel = currentLabel .. " Copy " .. counter
        end
        
        if M.duplicateProfile(currentEditingProfile, newId) then
            M.setProfileLabel(newId, newLabel)
            currentEditingProfile = newId
            
            -- Update combo box options to include the new profile
            local profileLabels = M.getProfileLabels()
            configui.setSelections("remap_active_profile", profileLabels)
            
            -- Find the index of the new profile and select it
            local profileList = M.getProfileList()
            local newProfileIndex = 1
            for i, profile in ipairs(profileList) do
                if profile == newId then
                    newProfileIndex = i
                    break
                end
            end
            
            -- Set the combo to the new profile and refresh UI
            configui.setValue("remap_active_profile", newProfileIndex)
            M.refreshUI()
        end
    end)

    configui.onUpdate("remap_delete_profile", function()
         -- Don't allow deleting the last remaining profile
        local profileList = M.getProfileList()
        if #profileList <= 1 then
            M.print("Cannot delete the last remaining profile", LogLevel.Warning)
            return
        end
                
        local profileToDelete = currentEditingProfile
        M.print("Starting delete of profile: " .. profileToDelete, LogLevel.Info)
        
        -- Delete directly from parameters without using the M.deleteProfile function
        if parameters[profileToDelete] then
            parameters[profileToDelete] = nil
            
            -- Clean up profile label
            if parameters._profileLabels and parameters._profileLabels[profileToDelete] then
                parameters._profileLabels[profileToDelete] = nil
            end
            
            M.print("Successfully deleted profile: " .. profileToDelete, LogLevel.Info)
            
            -- Mark as dirty immediately since we're protected by the flag
            isParametersDirty = true
            
            -- Switch to the first remaining profile
            local remainingProfiles = M.getProfileList()
            if #remainingProfiles > 0 then
                currentEditingProfile = remainingProfiles[1]
                M.print("Switched to profile: " .. currentEditingProfile, LogLevel.Info)
                
                -- Update UI to reflect the deletion and new current profile
                local profileLabels = M.getProfileLabels()
                configui.setSelections("remap_active_profile", profileLabels)
                
                -- Set the combo to the new current profile (index 1)
                configui.setValue("remap_active_profile", 1)
                
                -- Refresh the entire UI to show the new profile's configuration
                M.refreshUI()
            end
            
        else
            M.print("Failed to delete profile: " .. profileToDelete, LogLevel.Error)
        end
    end)

    -- Profile rename callbacks
    configui.onUpdate("remap_rename_profile", function()
        -- Show the rename input field and populate it with current profile label
        local currentLabel = M.getProfileLabel(currentEditingProfile)
        configui.setValue("remap_rename_input", currentLabel)
        configui.hideWidget("remap_rename_group", false)
    end)

    configui.onUpdate("remap_rename_update", function()
        -- Get the new name from the input field
        local newLabel = configui.getValue("remap_rename_input")
        if newLabel and newLabel:match("%S") then  -- Check if not empty/whitespace only
            -- Update the profile label
            M.setProfileLabel(currentEditingProfile, newLabel)
            
            -- Update the combo box options with the new label
            local profileLabels = M.getProfileLabels()
            configui.setSelections("remap_active_profile", profileLabels)
            
            -- Find the current profile index and restore selection
            local profileList = M.getProfileList()
            local currentProfileIndex = 1
            for i, profile in ipairs(profileList) do
                if profile == currentEditingProfile then
                    currentProfileIndex = i
                    break
                end
            end
            configui.setValue("remap_active_profile", currentProfileIndex)
            
            -- Hide the rename input field
            configui.hideWidget("remap_rename_group", true)
            
            M.print("Renamed profile to: " .. newLabel, LogLevel.Info)
        else
            M.print("Profile name cannot be empty", LogLevel.Warning)
        end
    end)

    -- Set up callbacks for checkbox states (dynamic based on inputStates)
    for _, inputName in ipairs(inputOrder) do
        local mapping = inputMapping[inputName]
        if mapping then
            for _, inputState in ipairs(inputStates) do
                local stateKey = inputState.key
                configui.onUpdate("remap_" .. inputName .. "_" .. stateKey, function(value)
                    if isRefreshing then return end
                    M.updateInputStateConfig(inputName, stateKey, value)
                    -- Show/hide the state group based on checkbox state
                    configui.hideWidget("remap_" .. inputName .. "_" .. stateKey .. "_group", not value)

                    -- Update tree node color based on current checkbox states
                    local anyStateChecked = false
                    for _, checkState in ipairs(inputStates) do
                        local checkStateKey = checkState.key
                        local isChecked = configui.getValue("remap_" .. inputName .. "_" .. checkStateKey)
                        if isChecked then
                            anyStateChecked = true
                            break
                        end
                    end

                    -- Update tree node color dynamically
                    if anyStateChecked then
                        configui.setColor("remap_" .. inputName, "#0088FFFF")
                    else
                        configui.setColor("remap_" .. inputName, nil) -- Reset to default
                    end
                end)
            end

            -- Always register configuration callbacks (since elements are always present)
            -- Register unpress callbacks for each state
            for _, inputState in ipairs(inputStates) do
                local stateKey = inputState.key
                configui.onUpdate("remap_" .. inputName .. "_" .. stateKey .. "_unpress", function(value)
                    M.updateStateSpecificConfig(inputName, stateKey, "unpress", value)
                end)
            end

            if mapping.type == "trigger" then
                configui.onUpdate("remap_" .. inputName .. "_threshold", function(value)
                    M.updateRemapConfig(inputName, "threshold", value)
                end)
            elseif mapping.type == "analog" then
                configui.onUpdate("remap_" .. inputName .. "_threshold", function(value)
                    M.updateRemapConfig(inputName, "threshold", value)
                end)
            end

            -- Always set up callbacks for action state combos (since elements are always present)
            for _, actionName in ipairs(allActions) do
                if actionName ~= inputName then
                    local actionMapping = inputMapping[actionName]

                    -- Generate callbacks for each possible state
                    for _, inputState in ipairs(inputStates) do
                        local stateKey = inputState.key

                        -- State action combo callbacks
                        configui.onUpdate("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_state", function(value)
                            if isRefreshing then return end

                            -- Use the correct value array based on action type
                            local selectedState = M.ActionState.NONE
                            if actionMapping then
                                if actionMapping.type == "button" then
                                    selectedState = buttonActionStateValues[value] or M.ActionState.NONE
                                elseif actionMapping.type == "trigger" then
                                    selectedState = triggerActionStateValues[value] or M.ActionState.NONE
                                elseif actionMapping.type == "analog" then
                                    selectedState = analogActionStateValues[value] or M.ActionState.NONE
                                end
                            else
                                selectedState = actionStateValues[value] or M.ActionState.NONE
                            end
                            
                            M.updateStateSpecificActionConfig(inputName, stateKey, actionName, "state", selectedState)

                            -- When enabling an action (not "none"), also set the current UI value
                            if selectedState ~= M.ActionState.NONE and selectedState ~= M.ActionState.COPY_VALUE then
                                if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") then
                                    local currentUIValue = configui.getValue("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_value")
                                    if currentUIValue then
                                        local numValue = tonumber(currentUIValue)
                                        if numValue then
                                            -- Clamp to valid range
                                            if actionMapping.type == "trigger" then
                                                numValue = math.max(CONSTANTS.TRIGGER_MIN, math.min(CONSTANTS.TRIGGER_MAX, numValue))
                                            else -- analog
                                                numValue = math.max(CONSTANTS.ANALOG_MIN, math.min(CONSTANTS.ANALOG_MAX, numValue))
                                            end
                                            M.updateStateSpecificActionConfig(inputName, stateKey, actionName, "value", numValue)
                                        end
                                    end
                                end
                            end

                            -- Show/hide value input based on selected state
                            if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") then
                                local shouldHide = (selectedState == M.ActionState.NONE or selectedState == M.ActionState.COPY_VALUE)
                                configui.hideWidget("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_value_group", shouldHide)
                            end

                            -- Update actions tree node color based on current action states
                            local hasConfiguredActions = false
                            for _, checkActionName in ipairs(allActions) do
                                if checkActionName ~= inputName then
                                    local currentActionStateIndex = configui.getValue("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. checkActionName .. "_state") or 1
                                    
                                    -- Use the correct value array based on action type
                                    local checkActionMapping = inputMapping[checkActionName]
                                    local currentActionState = M.ActionState.NONE
                                    if checkActionMapping then
                                        if checkActionMapping.type == "button" then
                                            currentActionState = buttonActionStateValues[currentActionStateIndex] or M.ActionState.NONE
                                        elseif checkActionMapping.type == "trigger" then
                                            currentActionState = triggerActionStateValues[currentActionStateIndex] or M.ActionState.NONE
                                        elseif checkActionMapping.type == "analog" then
                                            currentActionState = analogActionStateValues[currentActionStateIndex] or M.ActionState.NONE
                                        end
                                    else
                                        currentActionState = actionStateValues[currentActionStateIndex] or M.ActionState.NONE
                                    end
                                    
                                    if currentActionState ~= M.ActionState.NONE then
                                        hasConfiguredActions = true
                                        break
                                    end
                                end
                            end

                            -- Update actions tree node color dynamically
                            if hasConfiguredActions then
                                configui.setColor("remap_" .. inputName .. "_" .. stateKey .. "_actions", "#0088FFFF")
                            else
                                configui.setColor("remap_" .. inputName .. "_" .. stateKey .. "_actions", nil) -- Reset to default
                            end
                        end)

                        -- Value callback for trigger and analog actions
                        if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") then
                            configui.onUpdate("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_value", function(value)
                                -- Convert text input to number and validate
                                local numValue = tonumber(value)
                                if numValue then
                                    -- Clamp to valid range
                                    if actionMapping.type == "trigger" then
                                        numValue = math.max(CONSTANTS.TRIGGER_MIN, math.min(CONSTANTS.TRIGGER_MAX, numValue))
                                    else -- analog
                                        numValue = math.max(CONSTANTS.ANALOG_MIN, math.min(CONSTANTS.ANALOG_MAX, numValue))
                                    end
                                    M.updateStateSpecificActionConfig(inputName, stateKey, actionName, "value", numValue)
                                end
                            end)
                        end
                    end
                end
            end
        end  -- End of if mapping then
    end  -- End of for _, inputName in ipairs(inputOrder) do
end

function M.addNewInputMapping(inputName)
    if not parameters[currentEditingProfile] then
        parameters[currentEditingProfile] = {}
    end

    if not parameters[currentEditingProfile][inputName] then
        local mapping = inputMapping[inputName]
        if mapping then
            local newConfig = {
                state = M.InputState.ON,
                unpress = true
            }

            -- Add threshold for triggers and analog sticks
            if mapping.type == "trigger" then
                newConfig.threshold = CONSTANTS.DEFAULT_TRIGGER_THRESHOLD
            elseif mapping.type == "analog" then
                newConfig.threshold = CONSTANTS.DEFAULT_ANALOG_THRESHOLD
            end

            -- Create array format with single configuration
            parameters[currentEditingProfile][inputName] = {newConfig}
            isParametersDirty = true
            compiledRemapConfig = nil

            -- Refresh the UI
            M.refreshUI()
        else
            M.print("Unknown input name: " .. inputName, LogLevel.Error)
        end
    else
        M.print("Input mapping already exists for " .. inputName, LogLevel.Warning)
    end
end

function M.removeInputMapping(inputName)
    if isRefreshing then return end  -- Avoid operations during UI refresh

    if parameters[currentEditingProfile] and parameters[currentEditingProfile][inputName] then
        parameters[currentEditingProfile][inputName] = nil
        isParametersDirty = true
        compiledRemapConfig = nil

        -- Refresh the UI
        M.refreshUI()
    end
    -- Note: Silently ignore attempts to remove non-existent mappings
    -- This can happen during UI refresh when callbacks are re-registered
end

function M.addActionToInput(inputName, actionName)
    if isRefreshing then return end  -- Avoid operations during UI refresh

    local profile = currentEditingProfile or "default"
    if parameters[profile] and parameters[profile][inputName] then
        -- Handle both array format and legacy format
        local configs = parameters[profile][inputName]
        if not configs[1] then
            -- Legacy format: convert to array
            configs = {configs}
            parameters[profile][inputName] = configs
        end

        -- Add action to the first state configuration for now
        local config = configs[1]
        if not config.actions then
            config.actions = {}
        end

        if not config.actions[actionName] then
            -- Get the current state from the UI combo, defaulting to "on"
            local stateComboValue = configui.getValue("remap_" .. inputName .. "_action_" .. actionName .. "_state") or 1
            local selectedState = actionStateValues[stateComboValue] or M.ActionState.ON

            -- Create action config with state
            local actionConfig = {
                state = selectedState
            }

            -- Set default value for trigger and analog actions (but not for COPY_VALUE)
            local actionMapping = inputMapping[actionName]
            if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") and selectedState ~= M.ActionState.COPY_VALUE then
                if actionMapping.type == "trigger" then
                    actionConfig.value = CONSTANTS.TRIGGER_MAX  -- Full trigger press
                else -- analog
                    actionConfig.value = CONSTANTS.ANALOG_MAX  -- Full stick deflection
                end
            end

            config.actions[actionName] = actionConfig
            isParametersDirty = true
            compiledRemapConfig = nil

            -- No need to refresh UI since state combo is already visible
        else
            M.print("Action " .. actionName .. " already exists for input " .. inputName, LogLevel.Warning)
        end
    end
    -- Note: Silently ignore attempts to add actions to non-existent inputs
    -- This can happen during UI refresh when callbacks are re-registered
end

function M.removeActionFromInput(inputName, actionName)
    if isRefreshing then return end  -- Avoid operations during UI refresh

    local profile = currentEditingProfile or "default"
    if parameters[profile] and parameters[profile][inputName] then
        -- Handle both array format and legacy format
        local configs = parameters[profile][inputName]
        if not configs[1] then
            -- Legacy format: convert to array
            configs = {configs}
            parameters[profile][inputName] = configs
        end

        -- Remove action from the first state configuration for now
        local config = configs[1]
        if config.actions and config.actions[actionName] then
            config.actions[actionName] = nil

            -- If no actions remain, remove the actions table
            if next(config.actions) == nil then
                config.actions = nil
            end

            isParametersDirty = true
            compiledRemapConfig = nil

            -- No need to refresh UI since state combo remains visible
        end
    end
    -- Note: Silently ignore attempts to remove non-existent actions
    -- This can happen during UI refresh when callbacks are re-registered
end

function M.refreshUI()
    -- Regenerate and update the configuration UI by recreating it
    -- This is a simple approach that ensures the UI reflects current state
    if M.isDeveloperMode then
        isRefreshing = true  -- Set flag to prevent callback loops

        local configDefinition = {
            {
                panelLabel = "Remap Config Dev",
                saveFile = "remap_config_dev",
                layout = {}
            }
        }
        configDefinition = M.addRemapConfigToUI(configDefinition, parameters[currentEditingProfile or "default"])
        M.registerUICallbacks()  -- Register callbacks only once
        configui.update(configDefinition)

        -- After updating the UI definition, explicitly set the values for all checkboxes and combos
        -- since configui.update() might not properly handle initialValue changes
        
        -- Set the profile combo to the correct value
        local profileList = M.getProfileList()
        local currentProfileIndex = 1
        for i, profile in ipairs(profileList) do
            if profile == currentEditingProfile then
                currentProfileIndex = i
                break
            end
        end
        configui.setValue("remap_active_profile", currentProfileIndex)
        
        for _, inputName in ipairs(inputOrder) do
            local profile = currentEditingProfile or "default"
            local currentConfigArray = parameters[profile] and parameters[profile][inputName]

            -- Determine which states are currently configured (state-agnostic)
            local configuredStates = {}
            local stateConfigs = {}

            if currentConfigArray then
                local configs = currentConfigArray
                if not configs[1] then
                    -- Legacy format: convert to array for checking
                    configs = {configs}
                end

                for _, config in ipairs(configs) do
                    if config.state then
                        configuredStates[config.state] = true
                        stateConfigs[config.state] = config
                    end
                end
            end

            -- Set checkbox values for each possible state
            for _, inputState in ipairs(inputStates) do
                local stateKey = inputState.key
                local hasStateConfig = configuredStates[stateKey] or false
                configui.setValue("remap_" .. inputName .. "_" .. stateKey, hasStateConfig)
            end

            -- Set action state combo values for each configured state
            for _, inputState in ipairs(inputStates) do
                local stateKey = inputState.key
                local hasStateConfig = configuredStates[stateKey]
                local stateConfig = stateConfigs[stateKey]

                if hasStateConfig and stateConfig then
                    for _, actionName in ipairs(allActions) do
                        if actionName ~= inputName then
                            local currentActionStateIndex = 1  -- Default to "None"

                            -- Check if action exists and get its state
                            if stateConfig.actions and stateConfig.actions[actionName] then
                                local actionConfig = stateConfig.actions[actionName]
                                if actionConfig and actionConfig.state then
                                    -- Use the correct value array based on action type
                                    local actionMapping = inputMapping[actionName]
                                    local valueArray = actionStateValues  -- default
                                    if actionMapping then
                                        if actionMapping.type == "button" then
                                            valueArray = buttonActionStateValues
                                        elseif actionMapping.type == "trigger" then
                                            valueArray = triggerActionStateValues
                                        elseif actionMapping.type == "analog" then
                                            valueArray = analogActionStateValues
                                        end
                                    end
                                    
                                    for i, value in ipairs(valueArray) do
                                        if actionConfig.state == value then
                                            currentActionStateIndex = i
                                            break
                                        end
                                    end
                                end
                            end

                            configui.setValue("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_state", currentActionStateIndex)
                        end
                    end
                end
            end
        end

        isRefreshing = false  -- Clear flag after refresh is complete
    end
end

function M.updateRemapConfig(inputName, configType, value)
    local profile = currentEditingProfile or "default"
    if parameters[profile] and parameters[profile][inputName] then
        -- Handle both array format and legacy format
        local configs = parameters[profile][inputName]
        if not configs[1] then
            -- Legacy format: convert to array
            configs = {configs}
            parameters[profile][inputName] = configs
        end

        -- Update the first state configuration for now
        local config = configs[1]
        if configType == "state" then
            config.state = value
        elseif configType == "unpress" then
            config.unpress = value
        elseif configType == "threshold" then
            config.threshold = value
        end
        isParametersDirty = true
        -- Force recompilation
        compiledRemapConfig = nil
    end
end

function M.updateStateSpecificConfig(inputName, stateType, configType, value)
    local profile = currentEditingProfile or "default"
    if not parameters[profile] then
        parameters[profile] = {}
    end

    if not parameters[profile][inputName] then
        parameters[profile][inputName] = {}
    end

    local configs = parameters[profile][inputName]

    -- Handle legacy format
    if not configs[1] and configs.state then
        -- Convert legacy format to array
        configs = {configs}
        parameters[profile][inputName] = configs
    end

    -- Find the configuration for the specified state
    local targetConfig = nil
    for _, config in ipairs(configs) do
        if config.state == stateType then
            targetConfig = config
            break
        end
    end

    if targetConfig then
        if configType == "unpress" then
            targetConfig.unpress = value
        elseif configType == "threshold" then
            targetConfig.threshold = value
        end
        isParametersDirty = true
        compiledRemapConfig = nil
    end
end

function M.updateRemapActionConfig(inputName, actionName, configType, value)
    local profile = currentEditingProfile or "default"
    if parameters[profile] and parameters[profile][inputName] then
        -- Handle both array format and legacy format
        local configs = parameters[profile][inputName]
        if not configs[1] then
            -- Legacy format: convert to array
            configs = {configs}
            parameters[profile][inputName] = configs
        end

        -- Update action in the first state configuration for now
        local config = configs[1]
        if config.actions and config.actions[actionName] then
            if configType == "state" then
                config.actions[actionName].state = value
                -- Remove value parameter when switching to COPY_VALUE since it's not needed
                if value == M.ActionState.COPY_VALUE and config.actions[actionName].value then
                    config.actions[actionName].value = nil
                end
            elseif configType == "value" then
                config.actions[actionName].value = value
            end
            isParametersDirty = true
            -- Force recompilation
            compiledRemapConfig = nil
        end
    end
end

function M.updateStateSpecificActionConfig(inputName, stateType, actionName, configType, value)
    if isRefreshing then return end

    local profile = currentEditingProfile or "default"
    if not parameters[profile] then
        parameters[profile] = {}
    end

    -- Ensure input configuration exists
    if not parameters[profile][inputName] then
        parameters[profile][inputName] = {}
    end

    local configs = parameters[profile][inputName]

    -- Handle legacy format
    if not configs[1] and configs.state then
        -- Convert legacy format to array
        configs = {configs}
        parameters[profile][inputName] = configs
    end

    -- Find the configuration for the specified state
    local targetConfig = nil
    for _, config in ipairs(configs) do
        if config.state == stateType then
            targetConfig = config
            break
        end
    end

    -- If no config exists for this state and we're setting an action, create one
    if not targetConfig and value ~= M.ActionState.NONE then
        local mapping = inputMapping[inputName]
        if mapping then
            targetConfig = {
                state = stateType,
                unpress = true
            }

            -- Add threshold for triggers and analog sticks
            if mapping.type == "trigger" then
                targetConfig.threshold = CONSTANTS.DEFAULT_TRIGGER_THRESHOLD
            elseif mapping.type == "analog" then
                targetConfig.threshold = CONSTANTS.DEFAULT_ANALOG_THRESHOLD
            end

            table.insert(configs, targetConfig)
        end
    end

    if targetConfig then
        if configType == "state" then
            if value == M.ActionState.NONE then
                -- Remove the action if "None" is selected
                if targetConfig.actions and targetConfig.actions[actionName] then
                    targetConfig.actions[actionName] = nil

                    -- If no actions remain, remove the actions table
                    if next(targetConfig.actions) == nil then
                        targetConfig.actions = nil
                    end

                    -- UI will update on next user interaction (no automatic refresh to prevent loops)
                end
            else
                -- Add or update the action
                if not targetConfig.actions then
                    targetConfig.actions = {}
                end

                local wasEnabled = targetConfig.actions[actionName] ~= nil
                local currentState = wasEnabled and targetConfig.actions[actionName].state

                if not targetConfig.actions[actionName] then
                    targetConfig.actions[actionName] = {}

                    -- Set default value for trigger and analog actions (but not for COPY_VALUE)
                    local actionMapping = inputMapping[actionName]
                    if actionMapping and (actionMapping.type == "trigger" or actionMapping.type == "analog") and value ~= M.ActionState.COPY_VALUE then
                        if actionMapping.type == "trigger" then
                            targetConfig.actions[actionName].value = CONSTANTS.TRIGGER_MAX
                        else -- analog
                            targetConfig.actions[actionName].value = CONSTANTS.ANALOG_MAX
                        end
                    end
                end

                targetConfig.actions[actionName].state = value
                
                -- Remove value parameter when switching to COPY_VALUE since it's not needed
                if value == M.ActionState.COPY_VALUE and targetConfig.actions[actionName].value then
                    targetConfig.actions[actionName].value = nil
                end

                -- UI will update on next user interaction (no automatic refresh to prevent loops)
            end
        elseif configType == "value" then
            -- Update action value
            if targetConfig.actions and targetConfig.actions[actionName] then
                targetConfig.actions[actionName].value = value
            end
        end

        isParametersDirty = true
        compiledRemapConfig = nil
    end
end

function M.updateInputStateConfig(inputName, stateType, isEnabled)
    if isRefreshing then return end

    local profile = currentEditingProfile or "default"
    if not parameters[profile] then
        parameters[profile] = {}
    end

    -- Get current configurations
    local currentConfigs = parameters[profile][inputName]
    if not currentConfigs then
        currentConfigs = {}
        parameters[profile][inputName] = currentConfigs
    end

    -- Handle legacy format
    if not currentConfigs[1] and currentConfigs.state then
        -- Convert legacy format to array
        currentConfigs = {currentConfigs}
        parameters[profile][inputName] = currentConfigs
    end

    -- Find existing config for this state type
    local configIndex = nil
    for i, config in ipairs(currentConfigs) do
        if config.state == stateType then
            configIndex = i
            break
        end
    end

    if isEnabled then
        -- Add or ensure config exists for this state
        if not configIndex then
            local mapping = inputMapping[inputName]
            if mapping then
                local newConfig = {
                    state = stateType,
                    unpress = true
                }

                -- Add threshold for triggers and analog sticks
                if mapping.type == "trigger" then
                    newConfig.threshold = CONSTANTS.DEFAULT_TRIGGER_THRESHOLD
                elseif mapping.type == "analog" then
                    newConfig.threshold = CONSTANTS.DEFAULT_ANALOG_THRESHOLD
                end

                table.insert(currentConfigs, newConfig)
            end
        end
    else
        -- Remove config for this state if it exists
        if configIndex then
            table.remove(currentConfigs, configIndex)
        end

        -- If no configs remain, remove the input entirely
        if #currentConfigs == 0 then
            parameters[profile][inputName] = nil
            -- Clean up previous state tracking for this input
            previousInputStates[inputName] = nil
        end
    end

    isParametersDirty = true
    compiledRemapConfig = nil

    -- Don't automatically refresh UI to prevent recursive loops
    -- UI will be updated on next user interaction or manual refresh
end

function M.loadParameters(fileName)
    if fileName ~= nil then parametersFileName = fileName end
    M.print("Loading remap parameters " .. parametersFileName)
    local loadedParams = json.load_file(parametersFileName .. ".json")

    if loadedParams == nil then
        loadedParams = {}
        M.print("Creating remap parameters")
    end

    -- Handle backward compatibility: migrate "remap" to "default" profile if needed
    if loadedParams["remap"] and not loadedParams["default"] then
        loadedParams["default"] = loadedParams["remap"]
        loadedParams["remap"] = nil  -- Remove old format
        isParametersDirty = true
        M.print("Migrated remap configuration to default profile")
    end

    -- Initialize default profile if it doesn't exist
    if loadedParams["default"] == nil then
        loadedParams["default"] = parameters["remap"] or {}  -- Use initial config as default
        isParametersDirty = true
    end

    parameters = loadedParams
    
    -- Restore profile state if it exists
    if parameters._profileState then
        if parameters._profileState.currentEditingProfile then
            currentEditingProfile = parameters._profileState.currentEditingProfile
        end
    end
    
    -- Validate and set profiles, ensuring they exist in the loaded parameters
    local availableProfiles = M.getProfileList()
    
    -- Validate currentEditingProfile
    if not currentEditingProfile or not parameters[currentEditingProfile] then
        if #availableProfiles > 0 then
            currentEditingProfile = availableProfiles[1]  -- Use first available profile
        else
            currentEditingProfile = "default"
        end
    end
    
    -- Initialize default labels for profiles that don't have them
    if not parameters._profileLabels then
        parameters._profileLabels = {}
    end
    
    for _, profileId in ipairs(availableProfiles) do
        if not parameters._profileLabels[profileId] then
            -- Create human-readable labels for existing profiles
            if profileId == "default" then
                parameters._profileLabels[profileId] = "Default"
            elseif profileId == "remap" then
                parameters._profileLabels[profileId] = "Default" -- Legacy remap profile
            elseif profileId:match("^profile_(%d+)$") then
                local number = profileId:match("^profile_(%d+)$")
                parameters._profileLabels[profileId] = "Profile " .. number
            else
                -- For any other profiles, use the ID as the label
                parameters._profileLabels[profileId] = profileId
            end
            isParametersDirty = true
        end
    end
    
    -- Clean up any existing COPY_VALUE actions that have value parameters
    for _, profileId in ipairs(availableProfiles) do
        local profile = parameters[profileId]
        if profile and type(profile) == "table" then
            for inputName, inputConfigs in pairs(profile) do
                if type(inputConfigs) == "table" then
                    -- Handle both array and legacy formats
                    local configs = inputConfigs
                    if not configs[1] and configs.state then
                        -- Legacy format: convert to array for processing
                        configs = {configs}
                    end
                    
                    for _, config in ipairs(configs) do
                        if config.actions then
                            for actionName, actionConfig in pairs(config.actions) do
                                if actionConfig.state == M.ActionState.COPY_VALUE and actionConfig.value then
                                    actionConfig.value = nil
                                    isParametersDirty = true
                                    M.print("Cleaned up unnecessary value parameter from COPY_VALUE action: " .. inputName .. " -> " .. actionName, LogLevel.Info)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function saveParameters()
    M.print("Saving remap parameters " .. parametersFileName)
    
    -- Add profile state to parameters before saving
    parameters._profileState = {
        currentEditingProfile = currentEditingProfile
    }
    
    json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)
end, Once.EVER)

local function getDefaultConfig()
    return {
        {
            panelLabel = "Remap Config Dev",
            saveFile = "remap_config_dev",
            layout = {}
        }
    }
end

function M.showDeveloperConfiguration()
    local profile = currentEditingProfile or "default"
    local configDefinition = M.addRemapConfigToUI(getDefaultConfig(), parameters[profile])
    M.registerUICallbacks()  -- Register callbacks only once
    configui.create(configDefinition)

    -- After creating the UI, explicitly set the values for all checkboxes
    -- to ensure they display the correct initial state
    for _, inputName in ipairs(inputOrder) do
        local currentConfigArray = parameters[profile] and parameters[profile][inputName]

        -- Determine which states are currently configured (state-agnostic)
        local configuredStates = {}
        local stateConfigs = {}

        if currentConfigArray then
            local configs = currentConfigArray
            if not configs[1] then
                -- Legacy format: convert to array for checking
                configs = {configs}
            end

            for _, config in ipairs(configs) do
                if config.state then
                    configuredStates[config.state] = true
                    stateConfigs[config.state] = config
                end
            end
        end

        -- Set checkbox values for each possible state
        for _, inputState in ipairs(inputStates) do
            local stateKey = inputState.key
            local hasStateConfig = configuredStates[stateKey] or false
            configui.setValue("remap_" .. inputName .. "_" .. stateKey, hasStateConfig)
        end
        if currentConfigArray then
            local configs = currentConfigArray
            if not configs[1] then
                -- Legacy format: convert to array for checking
                configs = {configs}
            end

        end

        -- Set action state combo values for each configured state
        for _, inputState in ipairs(inputStates) do
            local stateKey = inputState.key
            local hasStateConfig = configuredStates[stateKey]
            local stateConfig = stateConfigs[stateKey]

            if hasStateConfig and stateConfig then
                for _, actionName in ipairs(allActions) do
                    if actionName ~= inputName then
                        local currentActionStateIndex = 1  -- Default to "None"

                        -- Check if action exists and get its state
                        if stateConfig.actions and stateConfig.actions[actionName] then
                            local actionConfig = stateConfig.actions[actionName]
                            if actionConfig and actionConfig.state then
                                -- Use the correct value array based on action type
                                local actionMapping = inputMapping[actionName]
                                local valueArray = actionStateValues  -- default
                                if actionMapping then
                                    if actionMapping.type == "button" then
                                        valueArray = buttonActionStateValues
                                    elseif actionMapping.type == "trigger" then
                                        valueArray = triggerActionStateValues
                                    elseif actionMapping.type == "analog" then
                                        valueArray = analogActionStateValues
                                    end
                                end
                                
                                for i, value in ipairs(valueArray) do
                                    if actionConfig.state == value then
                                        currentActionStateIndex = i
                                        break
                                    end
                                end
                            end
                        end

                        configui.setValue("remap_" .. inputName .. "_" .. stateKey .. "_action_" .. actionName .. "_state", currentActionStateIndex)
                    end
                end
            end
        end
    end
end

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    -- Store the developer mode state for later use
    M.isDeveloperMode = isDeveloperMode


    if isDeveloperMode then
        M.showDeveloperConfiguration()
        createDevMonitor()
    end
end

-- Separate reusable function to apply parameter-based input remapping
function M.applyParameterBasedRemapping(state, remapConfig)
    local profile = currentEditingProfile or "default"
    processInputRemapping(state, remapConfig or parameters[profile])
    
    -- Process FKEY actions (stub implementation)
    -- processFKeyActions(state)
end

function M.setRemapParameters(newParameters, profileName)
    local profile = profileName or currentEditingProfile or "default"
    parameters[profile] = newParameters
    isParametersDirty = true
    -- Force recompilation on next call to processInputRemapping
    compiledRemapConfig = nil
    M.refreshUI()
end

function M.getRemapParameters()
    return parameters[currentEditingProfile]
end

-- Profile Management Functions

function M.getProfileList()
    local profiles = {}
    
    -- Skip system/internal keys and collect actual profiles
    local systemKeys = {
        ["saveFile"] = true,
        ["panelLabel"] = true,
        ["layout"] = true,
        ["_profileState"] = true,  -- Skip profile state metadata
        ["_profileLabels"] = true, -- Skip profile labels metadata
        -- Add other system keys if needed
    }
    
    for key, value in pairs(parameters) do
        -- Include only keys that are profile configurations (tables with remap data)
        if type(value) == "table" and not systemKeys[key] then
            table.insert(profiles, key)
        end
    end
    
    table.sort(profiles)
    return profiles
end

function M.getProfileLabels()
    local profiles = M.getProfileList()
    local labels = {}
    
    -- Initialize profile labels if not exists
    if not parameters._profileLabels then
        parameters._profileLabels = {}
    end
    
    for _, profileId in ipairs(profiles) do
        -- Use label if exists, otherwise use the profile ID as label
        local label = parameters._profileLabels[profileId] or profileId
        table.insert(labels, label)
    end
    
    return labels
end

function M.getProfileLabel(profileId)
    if not parameters._profileLabels then
        return profileId
    end
    return parameters._profileLabels[profileId] or profileId
end

function M.setProfileLabel(profileId, label)
    if not parameters._profileLabels then
        parameters._profileLabels = {}
    end
    parameters._profileLabels[profileId] = label
    isParametersDirty = true
end

function M.getCurrentEditingProfile()
    return currentEditingProfile
end

function M.setCurrentEditingProfile(profileName)
    M.print("setCurrentEditingProfile called with: " .. (profileName or "nil"), LogLevel.Info)
    M.print("Current profile before switch: " .. currentEditingProfile, LogLevel.Info)
    
    if parameters[profileName] then
        currentEditingProfile = profileName
        isParametersDirty = true  -- Mark for saving
        M.print("Successfully switched to profile: " .. profileName, LogLevel.Info)
    else
        M.print("Profile not found: " .. profileName .. ", keeping current: " .. currentEditingProfile, LogLevel.Warning)
    end
end

function M.createNewProfile(profileName)
    if not profileName or profileName == "" then
        M.print("Profile name cannot be empty", LogLevel.Error)
        return false
    end
    
    if parameters[profileName] then
        M.print("Profile already exists: " .. profileName, LogLevel.Warning)
        return false
    end
    
    -- Create new empty profile
    parameters[profileName] = {}
    isParametersDirty = true
    M.print("Created new profile: " .. profileName, LogLevel.Info)
    return true
end

function M.duplicateProfile(sourceProfile, newProfileName)
    if not sourceProfile or not parameters[sourceProfile] then
        M.print("Source profile not found: " .. (sourceProfile or "nil"), LogLevel.Error)
        return false
    end
    
    if not newProfileName or newProfileName == "" then
        M.print("New profile name cannot be empty", LogLevel.Error)
        return false
    end
    
    if parameters[newProfileName] then
        M.print("Profile already exists: " .. newProfileName, LogLevel.Warning)
        return false
    end
    
    -- Deep copy the source profile
    local function deepCopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in pairs(orig) do
                copy[orig_key] = deepCopy(orig_value)
            end
        else
            copy = orig
        end
        return copy
    end
    
    parameters[newProfileName] = deepCopy(parameters[sourceProfile])
    isParametersDirty = true
    M.print("Duplicated profile " .. sourceProfile .. " to " .. newProfileName, LogLevel.Info)
    return true
end

function M.deleteProfile(profileName)
    M.print("deleteProfile called with: " .. (profileName or "nil"), LogLevel.Info)
    
    if not profileName or profileName == "" then
        M.print("Profile name cannot be empty", LogLevel.Error)
        return false
    end
    
    if not parameters[profileName] then
        M.print("Profile not found: " .. profileName, LogLevel.Warning)
        return false
    end
    
    M.print("About to delete profile from parameters: " .. profileName, LogLevel.Info)
    
    -- Note: Don't change currentEditingProfile here - let the caller handle that
    -- since the caller has better context about what profile to switch to
    
    parameters[profileName] = nil
    
    -- Clean up profile label
    if parameters._profileLabels and parameters._profileLabels[profileName] then
        parameters._profileLabels[profileName] = nil
    end
    
    isParametersDirty = true
    M.print("Deleted profile: " .. profileName, LogLevel.Info)
    return true
end

function M.renameProfile(oldName, newName)
    if not oldName or not parameters[oldName] then
        M.print("Source profile not found: " .. (oldName or "nil"), LogLevel.Error)
        return false
    end
    
    if not newName or newName == "" then
        M.print("New profile name cannot be empty", LogLevel.Error)
        return false
    end
    
    if oldName == "remap" then
        M.print("Cannot rename the default 'remap' profile", LogLevel.Error)
        return false
    end
    
    if parameters[newName] then
        M.print("Profile already exists: " .. newName, LogLevel.Warning)
        return false
    end
    
    -- Copy data to new key and delete old key
    parameters[newName] = parameters[oldName]
    parameters[oldName] = nil
    
    -- Update profile label if it exists
    if parameters._profileLabels and parameters._profileLabels[oldName] then
        parameters._profileLabels[newName] = parameters._profileLabels[oldName]
        parameters._profileLabels[oldName] = nil
    end
    
    -- Update active profile references
    if currentEditingProfile == oldName then
        currentEditingProfile = newName
    end
    
    isParametersDirty = true
    M.print("Renamed profile " .. oldName .. " to " .. newName, LogLevel.Info)
    return true
end

function M.setDisabled(val)
	M.print("Remap Disabled:" .. tostring(val))
	isDisabledOverride = val
	configui.setValue("remap_disabled", isDisabledOverride, true)
end

function M.isDisabled()
	return isDisabledOverride or isDisabled
end

function M.registerIsDisabledCallback(func)
	uevrUtils.registerUEVRCallback("is_remap_disabled", func)
end

local function executeIsDisabledCallback(...)
	local result, priority = uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_remap_disabled", table.unpack({...}))
	return result
end

local function updateIsDisabled()
	local disabled = isDisabledOverride or executeIsDisabledCallback() or false
	-- if isDisabled ~= disabled then
	-- end
	isDisabled = disabled
end

uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
    updateIsDisabled()
    if not isDisabled then
        processInputRemapping(state, parameters[currentEditingProfile])
    end
end)


M.loadParameters()

return M