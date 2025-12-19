# UEVR: Lua API

UEVR provides a Lua API that can be used to create plugins.

Scripts can be loaded under LuaLoader, and are automatically loaded from `<game config folder>/scripts/*.lua`.

The Lua API can also be loaded in different environments, like UE4SS. UEVR comes with a LuaVR.dll for this purpose.

## Example

```lua
print("Initializing hello_world.lua")

UEVR_UObjectHook.activate()

local api = uevr.api;
local uobjects = uevr.types.FUObjectArray.get()

print("Printing first 5 UObjects")
for i=0, 5 do
    local uobject = uobjects:get_object(i)

    if uobject ~= nil then
        print(uobject:get_full_name())
    end
end

local once = true
local last_world = nil
local last_level = nil

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)

end)

local spawn_once = true

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    --[[if spawn_once then
        local cheat_manager_c = api:find_uobject("Class /Script/Engine.CheatManager")
        local cheat_manager = UEVR_UObjectHook.get_first_object_by_class(cheat_manager_c)

        print(tostring(cheat_manager_c))

        cheat_manager:Summon("Something_C")

        spawn_once = false
    end]]

    local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("Viewport is nil")
        return
    end
    local world = viewport.World

    if world == nil then
        print("World is nil")
        return
    end

    if world ~= last_world then
        print("World changed")
    end

    last_world = world

    local level = world.PersistentLevel

    if level == nil then
        print("Level is nil")
        return
    end

    if level ~= last_level then
        print("Level changed")
        print("Level name: " .. level:get_full_name())

        local game_instance = game_engine.GameInstance

        if game_instance == nil then
            print("GameInstance is nil")
            return
        end

        local local_players = game_instance.LocalPlayers

        for i in ipairs(local_players) do
            local player = local_players[i]
            local player_controller = player.PlayerController
            local pawn = player_controller.Pawn
    
            if pawn ~= nil then
                print("Pawn: " .. pawn:get_full_name())
                --pawn.BaseEyeHeight = 0.0
                --pawn.bActorEnableCollision = not pawn.bActorEnableCollision

                local actor_component_c = api:find_uobject("Class /Script/Engine.ActorComponent");
                print("actor_component_c class: " .. tostring(actor_component_c))
                local test_component = pawn:GetComponentByClass(actor_component_c)

                print("TestComponent: " .. tostring(test_component))

                local controller = pawn.Controller

                if controller ~= nil then
                    print("Controller: " .. controller:get_full_name())

                    local velocity = controller:GetVelocity()
                    print("Velocity: " .. tostring(velocity.x) .. ", " .. tostring(velocity.y) .. ", " .. tostring(velocity.z))

                    local test = Vector3d.new(1.337, 1.0, 1.0)
                    print("Test: " .. tostring(test.x) .. ", " .. tostring(test.y) .. ", " .. tostring(test.z))

                    controller:SetActorScale3D(Vector3d.new(1.337, 1.0, 1.0))

                    local actor_scale_3d = controller:GetActorScale3D()
                    print("ActorScale3D: " .. tostring(actor_scale_3d.x) .. ", " .. tostring(actor_scale_3d.y) .. ", " .. tostring(actor_scale_3d.z))

                    
                    local control_rotation = controller:GetControlRotation()

                    print("ControlRotation: " .. tostring(control_rotation.Pitch) .. ", " .. tostring(control_rotation.Yaw) .. ", " .. tostring(control_rotation.Roll))
                    control_rotation.Pitch = 1.337

                    controller:SetControlRotation(control_rotation)
                    control_rotation = controller:GetControlRotation()

                    print("New ControlRotation: " .. tostring(control_rotation.Pitch) .. ", " .. tostring(control_rotation.Yaw) .. ", " .. tostring(control_rotation.Roll))
                end

                local primary_actor_tick = pawn.PrimaryActorTick

                if primary_actor_tick ~= nil then
                    print("PrimaryActorTick: " .. tostring(primary_actor_tick))

                    -- Print various properties, this is testing of StructProperty as PrimaryActorTick is a struct
                    local tick_interval = primary_actor_tick.TickInterval
                    print("TickInterval: " .. tostring(tick_interval))

                    print("bAllowTickOnDedicatedServer: " .. tostring(primary_actor_tick.bAllowTickOnDedicatedServer))
                    print("bCanEverTick: " .. tostring(primary_actor_tick.bCanEverTick))
                    print("bStartWithTickEnabled: " .. tostring(primary_actor_tick.bStartWithTickEnabled))
                    print("bTickEvenWhenPaused: " .. tostring(primary_actor_tick.bTickEvenWhenPaused))
                else
                    print("PrimaryActorTick is nil")
                end

                local control_input_vector = pawn.ControlInputVector
                pawn.ControlInputVector.x = 1.337

                print("ControlInputVector: " .. tostring(control_input_vector.x) .. ", " .. tostring(control_input_vector.y) .. ", " .. tostring(control_input_vector.z))

                local is_actor_tick_enabled = pawn:IsActorTickEnabled()
                print("IsActorTickEnabled: " .. tostring(is_actor_tick_enabled))

                pawn:SetActorTickEnabled(not is_actor_tick_enabled)
                is_actor_tick_enabled = pawn:IsActorTickEnabled()
                print("New IsActorTickEnabled: " .. tostring(is_actor_tick_enabled))

                pawn:SetActorTickEnabled(not is_actor_tick_enabled) -- resets it back to default

                local life_span = pawn:GetLifeSpan()
                local og_life_span = life_span
                print("LifeSpan: " .. tostring(life_span))

                pawn:SetLifeSpan(10.0)
                life_span = pawn:GetLifeSpan()

                print("New LifeSpan: " .. tostring(life_span))
                pawn:SetLifeSpan(og_life_span) -- resets it back to default

                local net_driver_name = pawn.NetDriverName:to_string()

                print("NetDriverName: " .. net_driver_name)
            end
    
            if player_controller ~= nil then
                print("PlayerController: " .. player_controller:get_full_name())
            end
        end

        print("Local players: " .. tostring(local_players))
    end

    last_level = level

    if once then
        print("executing stat fps")
        uevr.api:execute_command("stat fps")
        once = false

        print("executing stat unit")
        uevr.api:execute_command("stat unit")

        print("GameEngine class: " .. game_engine_class:get_full_name())
        print("GameEngine object: " .. game_engine:get_full_name())
    end
end)

uevr.sdk.callbacks.on_script_reset(function()
    print("Resetting hello_world.lua")
end)
```

## Example (when integrated into an environment like UE4SS)

```lua
local LuaVR = require("LuaVR")

local function vr_print(text)
    print("[LuaVR Script] " .. text .. "\n")
end

local params = LuaVR.params
local callbacks = params.sdk.callbacks

local total_t = 0.0

-- Example usage of callbacks
callbacks.on_pre_engine_tick(function(engine, delta)
    total_t = total_t + delta
end)

-- Modifies the camera position
callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    position.z = position.z + 100.0
    position.y = position.y - 100.0
end)



-- UEVR_PluginInitializeParam

-- UEVR_PluginVersion
vr_print("Major: " .. tostring(params.version.major))
vr_print("Minor: " .. tostring(params.version.minor))
vr_print("Patch: " .. tostring(params.version.patch))

-- UEVR_PluginFunctions
vr_print("Is drawing ui: " .. tostring(params.functions.is_drawing_ui()))
params.functions.log_info("Hello from LuaVR!")
params.functions.log_warn("Hello from LuaVR!")
params.functions.log_error("Hello from LuaVR!")

-- UEVR_VRData
vr_print("Runtime ready state: " .. tostring(params.vr.is_runtime_ready()))
vr_print("Is OpenVR: " .. tostring(params.vr.is_openvr()))
vr_print("Is OpenXR: " .. tostring(params.vr.is_openxr()))
vr_print("Is HMD Active: " .. tostring(params.vr.is_hmd_active()))

local standing_origin = UEVR_Vector3f.new()
params.vr.get_standing_origin(standing_origin)
vr_print("Standing Origin: " .. tostring(standing_origin.x) .. ", " .. tostring(standing_origin.y) .. ", " .. tostring(standing_origin.z))

local rotation_offset = UEVR_Vector3f.new()
params.vr.get_rotation_offset(rotation_offset)
vr_print("Rotation Offset: " .. tostring(rotation_offset.x) .. ", " .. tostring(rotation_offset.y) .. ", " .. tostring(rotation_offset.z))

local hmd_index = params.vr.get_hmd_index()
vr_print("HMD Index: " .. tostring(hmd_index))

local left_controller_index = params.vr.get_left_controller_index()
vr_print("Left Controller Index: " .. tostring(left_controller_index))

local right_controller_index = params.vr.get_right_controller_index()
vr_print("Right Controller Index: " .. tostring(right_controller_index))

local hmd_position = UEVR_Vector3f.new()
local hmd_rotation = UEVR_Quaternionf.new()
params.vr.get_pose(hmd_index, hmd_position, hmd_rotation)

vr_print("HMD Position: " .. tostring(hmd_position.x) .. ", " .. tostring(hmd_position.y) .. ", " .. tostring(hmd_position.z))
vr_print("HMD Rotation: " .. tostring(hmd_rotation.x) .. ", " .. tostring(hmd_rotation.y) .. ", " .. tostring(hmd_rotation.z) .. ", " .. tostring(hmd_rotation.w))

if left_controller_index ~= -1 then
    local left_controller_position = UEVR_Vector3f.new()
    local left_controller_rotation = UEVR_Quaternionf.new()
    params.vr.get_pose(left_controller_index, left_controller_position, left_controller_rotation)

    vr_print("Left Controller Position: " .. tostring(left_controller_position.x) .. ", " .. tostring(left_controller_position.y) .. ", " .. tostring(left_controller_position.z))
    vr_print("Left Controller Rotation: " .. tostring(left_controller_rotation.x) .. ", " .. tostring(left_controller_rotation.y) .. ", " .. tostring(left_controller_rotation.z) .. ", " .. tostring(left_controller_rotation.w))        
end

if right_controller_index ~= -1 then
    local right_controller_position = UEVR_Vector3f.new()
    local right_controller_rotation = UEVR_Quaternionf.new()
    params.vr.get_pose(right_controller_index, right_controller_position, right_controller_rotation)

    vr_print("Right Controller Position: " .. tostring(right_controller_position.x) .. ", " .. tostring(right_controller_position.y) .. ", " .. tostring(right_controller_position.z))
    vr_print("Right Controller Rotation: " .. tostring(right_controller_rotation.x) .. ", " .. tostring(right_controller_rotation.y) .. ", " .. tostring(right_controller_rotation.z) .. ", " .. tostring(right_controller_rotation.w))        
end

local left_eye_offset = UEVR_Vector3f.new()
local right_eye_offset = UEVR_Vector3f.new()

params.vr.get_eye_offset(0, left_eye_offset)
params.vr.get_eye_offset(1, right_eye_offset)

vr_print("Left Eye Offset: " .. tostring(left_eye_offset.x) .. ", " .. tostring(left_eye_offset.y) .. ", " .. tostring(left_eye_offset.z))
vr_print("Right Eye Offset: " .. tostring(right_eye_offset.x) .. ", " .. tostring(right_eye_offset.y) .. ", " .. tostring(right_eye_offset.z))

local is_using_controllers = params.vr.is_using_controllers()
vr_print("Is Using Controllers: " .. tostring(is_using_controllers))
```
