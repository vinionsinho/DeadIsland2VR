--Script written by Letmein50   

local uevrUtils = require("libs/uevr_utils")
uevrUtils.initUEVR(uevr)

local params = uevr.params

-- Native Stereo Constants
local METHOD_NATIVE = 0
local METHOD_SEQUENTIAL = 1

local state = {
    is_loading = false,
    is_stabilizing = false,
    current_rendering_method = -1
}

-- LogicState Constants
local LogicState = {
    Gameplay = 0,
    Menu = 1,
    Loading = 2,
    Stabilizing = 3
}
local current_logic_state = -1

local function set_rendering_mode(mode)
    -- Only call UEVR API if our internal state mismatch
    if state.current_rendering_method ~= mode then
        if mode == METHOD_NATIVE then
             uevrUtils.print("[RenderingFix] Switching to Native Stereo (Gameplay)", LogLevel.Info)
             params.vr.set_mod_value("VR_RenderingMethod", tostring(METHOD_NATIVE))
             params.vr.set_mod_value("VR_NativeStereoFix", "true")
             params.vr.set_mod_value("VR_NativeStereoFixSamePass", "true")
        else
             uevrUtils.print("[RenderingFix] Switching to Synced Sequential (Menu/Loading/Stabilizing)", LogLevel.Info)
             params.vr.set_mod_value("VR_RenderingMethod", tostring(METHOD_SEQUENTIAL))
        end
        state.current_rendering_method = mode
    end
end

-- Handle Level Load
uevrUtils.registerLevelChangeCallback(function(levelName)
    uevrUtils.print("[RenderingFix] Level change detected. Forcing Sequential.", LogLevel.Info)
    state.is_loading = true
    state.is_stabilizing = false
    
    -- Invalidate cache to force re-apply
    state.current_rendering_method = -1
    
    current_logic_state = LogicState.Loading
    set_rendering_mode(METHOD_SEQUENTIAL)
end)

-- Per-frame check
uevrUtils.registerPreEngineTickCallback(function(engine, delta)
    -- 1. Check Pawn Existence
    local pawn = uevrUtils.get_local_pawn()

    -- 2. State Machine
    if state.is_loading then
        if pawn then
            -- Level loaded in (Pawn found). Start Stabilization Timer.
            uevrUtils.print("[RenderingFix] Pawn found. Starting 2s stability timer.", LogLevel.Info)
            state.is_loading = false
            state.is_stabilizing = true
            
            -- Wait 3 seconds before allowing Native Stereo
            uevrUtils.setTimeout(3000, function()
                uevrUtils.print("[RenderingFix] Stability timer ended.", LogLevel.Info)
                state.is_stabilizing = false
            end)
            
            -- Keep Sequential during stabilization
            if current_logic_state ~= LogicState.Stabilizing then
                current_logic_state = LogicState.Stabilizing
                set_rendering_mode(METHOD_SEQUENTIAL)
            end
        else
            -- Still loading/No Pawn
            if current_logic_state ~= LogicState.Loading then
                current_logic_state = LogicState.Loading
                set_rendering_mode(METHOD_SEQUENTIAL)
            end
        end
        return
    end

    if state.is_stabilizing then
        -- Enforce Sequential during stabilization
        if current_logic_state ~= LogicState.Stabilizing then
             current_logic_state = LogicState.Stabilizing
             set_rendering_mode(METHOD_SEQUENTIAL)
        end
        return
    end

    -- 3. Standard Logic (Gameplay vs Menu)
    if pawn then
        -- Gameplay
        if current_logic_state ~= LogicState.Gameplay then
            current_logic_state = LogicState.Gameplay
            set_rendering_mode(METHOD_NATIVE)
        end
    else
        -- Menu
        if current_logic_state ~= LogicState.Menu then
            current_logic_state = LogicState.Menu
            set_rendering_mode(METHOD_SEQUENTIAL)
        end
    end
end)

uevrUtils.print("[RenderingFix] Script loaded (Delay after Pawn).", LogLevel.Info)
