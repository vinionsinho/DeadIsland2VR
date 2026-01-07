local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks
local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local pawn = require("libs/pawn")
local inCutsceneState = false


uevrUtils.setInterval(200, function()
    local controller = uevrUtils.get_player_controller()
    if not controller then
        return
    end
    local camera_manager = controller.PlayerCameraManager
    if not camera_manager then
        return
    end
    local cutscene_component = camera_manager.CutsceneComponent
    if not cutscene_component then
        return
    end
    if cutscene_component.CurrentViewTargetCameraComponent then
        inCutsceneState = true
    else
        inCutsceneState = false
    end
end)


local function IsInCutscene()
    return inCutsceneState
end

local lastInCutsceneState = nil

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    
    -- pawn.hideBodyMesh(true)
    -- pawn.hideArms(true)

    local inCutscene = IsInCutscene()

    if inCutscene ~= lastInCutsceneState then
        lastInCutsceneState = inCutscene

        if inCutscene then 
            print("Entering cutscene")
            -- Cutscene enter actions
            hands.hideHands(true)
            -- pawn.hideArms(false) 
            vr.set_aim_method(0)
            -- vr.set_decoupled_pitch_enabled(true)
            
        else
            print("Exiting cutscene")
            -- Cutscene exit actions
            hands.hideHands(false)
            -- pawn.hideArms(true)    
            vr.set_aim_method(2)
            -- vr.set_decoupled_pitch_enabled(true)
        end
    end
end)
    


