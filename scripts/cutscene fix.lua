local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local pawn = require("libs/pawn")
local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)


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

-- pawn.init(true, LogLevel.Debug)
-- uevrUtils.fname_from_string(boneName)

local pawn = uevrUtils.get_local_pawn()
if not pawn then
    return
end

local first_person_mesh = pawn.MeshFirstPerson
local thigh_l = uevrUtils.fname_from_string("thigh_l")
local thigh_r = uevrUtils.fname_from_string("thigh_r")
first_person_mesh:HideBoneByName(thigh_l, 0)
first_person_mesh:HideBoneByName(thigh_r, 0)

local lastInCutsceneState = nil

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)



    -- pawn.hideBodyMesh(true)
    -- pawn.hideArms(true)


    local inCutscene = IsInCutscene()

    if inCutscene ~= lastInCutsceneState then
        lastInCutsceneState = inCutscene

        if inCutscene then 
            print("Entrando em Cutscene")
            -- Ações ao entrar na cutscene
            -- hands.hideHands(true)
            -- pawn.hideArms(false) 
            vr.set_aim_method(0)
            vr.set_decoupled_pitch_enabled(false) -- Trava a câmera verticalmente ao jogo
            
        else
            print("Saindo de Cutscene")
            -- Ações ao sair da cutscene (reverter mudanças)
            -- hands.hideHands(false)
            -- pawn.hideArms(true)    
            vr.set_aim_method(2)
            vr.set_decoupled_pitch_enabled(true)
        end
    end
end)
    


