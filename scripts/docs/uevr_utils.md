# UEVR Utils Library Documentation

A comprehensive utility library for VR modding with UEVR (Unreal Engine VR). This library provides a wide range of functions for timing, vector math, object management, component creation, callbacks, and VR-specific operations.

## Table of Contents

- [Timing & Animation](#timing--animation)
- [Vector & Math Operations](#vector--math-operations)
- [Object Management](#object-management)
- [Component Creation & Management](#component-creation--management)
- [VR & Camera Controls](#vr--camera-controls)
- [Input & Controller Functions](#input--controller-functions)
- [Callback System](#callback-system)
- [Utility Functions](#utility-functions)
- [Advanced Features](#advanced-features)
- [Lifecycle Callbacks](#lifecycle-callbacks)

## Timing & Animation

### setTimeout(msec, func) / uevrUtils.setTimeout(msec, func) / uevrUtils.delay(msec, func)
Delays for specified number of milliseconds before executing func. `delay()` is deprecated but still works internally.

```lua
setTimeout(1000, function()
    print("after one second delay")
end)
```

### setInterval(msec, func) / uevrUtils.setInterval(msec, func)
Delays for specified number of milliseconds before executing func then repeats.

```lua
setInterval(1000, function()
    print("repeats every second")
end)
```

### uevrUtils.createDeferral(name, timeoutMs, callback)
Creates a named deferral that will execute a callback function after a specified timeout. The deferral starts inactive and must be activated with updateDeferral().

```lua
uevrUtils.createDeferral("reload_cooldown", 2000, function()
    print("Reload cooldown finished - can reload again")
end)
```

### uevrUtils.updateDeferral(name)
Activates a deferral, starting its countdown timer. If the deferral is already active, this resets the countdown to the full timeout duration.

```lua
uevrUtils.updateDeferral("reload_cooldown")  -- starts or restarts the 2-second countdown
```

### uevrUtils.destroyDeferral(name)
Removes a deferral entirely, preventing it from executing its callback.

```lua
uevrUtils.destroyDeferral("reload_cooldown")  -- cancels the deferral
```

### uevrUtils.lerp(lerpID, startAlpha, endAlpha, duration, userdata, callback)
Smoothly interpolates from startAlpha to endAlpha over duration seconds. lerpID is a unique identifier to track this lerp operation. userdata is optional data passed to the callback function.

```lua
uevrUtils.lerp("fade", 0, 1, 2.0, nil, function(alpha, data)
    print("Current fade alpha:", alpha)  
end)
```

### uevrUtils.cancelLerp(lerpID)
Cancels an active lerp operation.

```lua
uevrUtils.cancelLerp("fade")
```

### doOnce(func, scopeType) / uevrUtils.doOnce(func, scopeType)
Executes the function once, no matter how many times it is called. scopeType can be `Once.EVER` or `Once.PER_LEVEL`.

```lua
local initGlobal = doOnce(function()
    print("Global init")
    return "Hello"
end, Once.EVER)

local retValue = initGlobal()  -- prints Global init, returns "Hello"
retValue = initGlobal()        -- does nothing, returns nil
```

## Vector & Math Operations

### uevrUtils.vector_2(x, y, reuseable)
Returns a CoreUObject.Vector2D structure with the given params.

```lua
print("X value is", uevrUtils.vector_2(3, 4).X)
```

### uevrUtils.vector_3(x, y, z)
Returns a UEVR Vector3d structure with the given params. Replacement for using temp_vec3 directly.

```lua
print("Z value is", uevrUtils.vector_3(3, 4, 5).Z)
```

### uevrUtils.vector_3f(x, y, z)
Returns a UEVR Vector3f structure with the given params. Replacement for using temp_vec3f directly.

```lua
print("Z value is", uevrUtils.vector_3f(3, 4, 5).Z)
```

### uevrUtils.quatf(x, y, z, w)
Returns a UEVR Quaternion structure with the given params.

```lua
print("Z value is", uevrUtils.quatf(3, 4, 5, 1).Z)
```

### uevrUtils.quat(x, y, z, w, reuseable)
Returns a CoreUObject.Quat structure with the given params. If reuseable is true a cached struct is returned.

```lua
print("Z value is", uevrUtils.quat(3, 4, 5, 1).Z)
```

### uevrUtils.vector(x, y, z, reuseable) / uevrUtils.vector(table, reuseable)
Returns a CoreUObject.Vector with the given params. Accepts either individual coordinates or a table.

```lua
print("X value is", uevrUtils.vector(30, 40, 50).X)
print("X value is", uevrUtils.vector({30,40,50}).X)
print("X value is", uevrUtils.vector({X=30,Y=40,Z=50}).X)
```

### uevrUtils.vector2D(...)
Returns a CoreUObject.Vector2D with the given parameters. Can accept various input formats.

```lua
local vec2d = uevrUtils.vector2D(100, 200)
```

### uevrUtils.rotator(pitch, yaw, roll, reuseable)
Returns a CoreUObject.Rotator with the given params. If reuseable is true a cached struct is returned.

```lua
print("Pitch value is", uevrUtils.rotator(30, 0, 0).Pitch)
print("Yaw value is", uevrUtils.rotator(30, 40, 50).Yaw)
```

### uevrUtils.rotatorFromQuat(x, y, z, w)
Returns CoreUObject.Rotator given the x,y,z and w values from a quaternion.

```lua
print("Yaw value is", uevrUtils.rotatorFromQuat(0, 0, 0, 1).Yaw)
```

### uevrUtils.quatFromRotator(pitch, yaw, roll)
Converts a rotator to a quaternion.

```lua
local quat = uevrUtils.quatFromRotator(90, 45, 0)
```

### uevrUtils.rotateVector(vector, rotator)
Rotates a vector by the specified rotator.

```lua
local rotatedVec = uevrUtils.rotateVector(uevrUtils.vector(1, 0, 0), uevrUtils.rotator(0, 90, 0))
```

### uevrUtils.vectorDistance(vector1, vector2)
Calculates the distance between two vectors.

```lua
local distance = uevrUtils.vectorDistance(pos1, pos2)
```

### uevrUtils.sumRotators(...)
Adds multiple rotators together, handling both uppercase and lowercase field names.

```lua
local totalRot = uevrUtils.sumRotators({Pitch=10, Yaw=20, Roll=0}, {pitch=5, yaw=10, roll=15})
```

### uevrUtils.distanceBetween(vector1, vector2)
Calculates the distance between two vectors.

```lua
local dist = uevrUtils.distanceBetween(player:K2_GetActorLocation(), target:K2_GetActorLocation())
```

### uevrUtils.getForwardVector(rotator)
Gets the forward vector from a rotator.

```lua
local fwd = uevrUtils.getForwardVector(camera:K2_GetActorRotation())
```

### uevrUtils.clampAngle180(angle)
Clamps an angle to the range -180 to 180 degrees.

```lua
local normalizedAngle = uevrUtils.clampAngle180(370)  -- returns 10
```

### uevrUtils.get_transform(position, rotation, scale, reuseable)
Returns a CoreUObject.Transform struct with the given params. Replacement for temp_transform.

```lua
local transform = uevrUtils.get_transform() -- position and rotation are set to 0s, scale is set to 1
local transform = uevrUtils.get_transform({X=10, Y=15, Z=20})
local transform = uevrUtils.get_transform({X=10, Y=15, Z=20}, nil, {X=.5, Y=.5, Z=.5})
```

## Object Management

### uevrUtils.get_world() / uevrUtils.getWorld()
Gets the current world.

```lua
local world = uevrUtils.get_world()
```

### uevrUtils.spawn_actor(transform, collisionMethod, owner, tag)
Spawns an actor with the given params.

```lua
local pos = pawn:K2_GetActorLocation()
local actor = uevrUtils.spawn_actor(uevrUtils.get_transform({X=pos.X, Y=pos.Y, Z=pos.Z}), 1, nil)
```

### uevrUtils.spawn_object(objClassName, outer)
Spawns an object of the specified class.

```lua
local obj = uevrUtils.spawn_object("Class /Script/Engine.StaticMeshComponent", nil)
```

### uevrUtils.destroy_actor(actor)
Destroys a spawned actor.

```lua
uevrUtils.destroy_actor(actor)
```

### uevrUtils.getAllActorsWithTag(tag)
Gets all actors with the specified tag.

```lua
local taggedActors = uevrUtils.getAllActorsWithTag("CustomTag")
```

### uevrUtils.getAllActorsOfClassWithTag(className, tag)
Gets all actors of the specified class that also have the specified tag.

```lua
local actors = uevrUtils.getAllActorsOfClassWithTag("Class /Script/Engine.StaticMeshActor", "MyTag")
```

### uevrUtils.getAllActorsOfClass(className)
Gets all actors of the specified class.

```lua
local meshActors = uevrUtils.getAllActorsOfClass("Class /Script/Engine.StaticMeshActor")
```

### uevrUtils.getValid(object, properties)
Returns a valid object or property of an object or nil if none is found. Properties are passed as an array of hierarchical property names.

```lua
local mesh = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
local validPawn = uevrUtils.getValid(pawn) -- gets a valid pawn or nil
```

### uevrUtils.validate_object(object)
If the object is returned from this function then it is not nil and it exists.

```lua
if uevrUtils.validate_object(object) ~= nil then 
    print("Good object")
end
```

### uevrUtils.find_required_object(name)
Wrapper for uevr.api:find_uobject(name).

```lua
local obj = uevrUtils.find_required_object("ObjectName")
```

### uevrUtils.get_class(name, clearCache)
Cached wrapper for uevr.api:find_uobject(name). Can be called repeatedly for the same name with no performance hit unless clearCache is true.

```lua
local componentClass = uevrUtils.get_class("Class /Script/Engine.StaticMeshComponent")
local poseableComponent = baseActor:AddComponentByClass(componentClass, true, uevrUtils.get_transform(), false)
```

### uevrUtils.find_instance_of(className, objectName)
Find the named object instance of the given className. Can use short names for objects.

```lua
local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "Sphere")
```

### uevrUtils.find_first_of(className, includeDefault)
Find the first object instance of the given className.

```lua
local widget = uevrUtils.find_first_of("Class /Script/Indiana.HUDWidget", false)
```

### uevrUtils.find_all_of(className, includeDefault)
Find all object instances of the given className. Returns an empty array if none found.

```lua
local motionControllers = uevrUtils.find_all_of("Class /Script/HeadMountedDisplay.MotionControllerComponent", false)
```

### uevrUtils.find_default_instance(className)
Returns get_class_default_object() for the given className.

```lua
kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
```

### uevrUtils.find_first_instance(className, includeDefault)
Find the first class instance of a given className.

```lua
local instance = uevrUtils.find_first_instance("Class /Script/Engine.PlayerController", false)
```

### uevrUtils.find_all_instances(className, includeDefault)
Find all class instances of a given className.

```lua
local instances = uevrUtils.find_all_instances("Class /Script/Engine.PlayerController", false)
```

### uevrUtils.GetInstanceMatching(class_to_search, match_string)
Finds first instance of class that contains match_string in its full name.

```lua
local instance = uevrUtils.GetInstanceMatching("Class /Script/Engine.StaticMesh", "Sphere")
```

### uevrUtils.getShortName(object)
Gets the short name of a UObject.

```lua
local name = uevrUtils.getShortName(actor)  -- returns just the object name without path
```

### uevrUtils.getFullName(object)
Gets the full path name of a UObject.

```lua
local fullName = uevrUtils.getFullName(actor)  -- returns complete object path
```

## Component Creation & Management

### uevrUtils.create_component_of_class(className, manualAttachment, relativeTransform, deferredFinish, parent, tag)
Creates and initializes a component based object of the desired class.

```lua
local component = uevrUtils.create_component_of_class("Class /Script/Engine.StaticMeshComponent")
```

### uevrUtils.createStaticMeshComponent(mesh, options)
Creates a static mesh component and assigns a mesh to it. The mesh param can be a StaticMesh object or class name.

Options:
- `manualAttachment` (bool)
- `relativeTransform` (transform)
- `deferredFinish` (bool)
- `parent` (object)
- `tag` (string)

```lua
local rightComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
local rightComponent = uevrUtils.createStaticMeshComponent("Sphere") --beware of duplicate short names
local rightComponent = uevrUtils.createStaticMeshComponent(mesh)
```

### uevrUtils.createSkeletalMeshComponent(meshName, options)
Creates a skeletal mesh component and assigns a mesh to it with the given name.

Options:
- `manualAttachment` (bool)
- `relativeTransform` (transform)
- `deferredFinish` (bool)
- `parent` (object)
- `tag` (string)

```lua
local component = uevrUtils.createSkeletalMeshComponent(wand.SK_Wand.SkeletalMesh:get_full_name(), {parent=wand})
```

### uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, options)
Creates a skeletal mesh component (PoseableMeshComponent) that can be manually manipulated and is a copy of the passed in skeletalMeshComponent.

Options:
- `manualAttachment` (bool)
- `relativeTransform` (transform)
- `deferredFinish` (bool)
- `parent` (object)
- `tag` (string)
- `showDebug` (bool)
- `useDefaultPose` (bool)

```lua
poseableComponent = uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, {showDebug=false})
```

### uevrUtils.createWidgetComponent(widget, options)
Creates a widget component and assigns a widget to it. The widget param can be a widget class name or an actual widget object.

Options:
- `manualAttachment` (bool)
- `relativeTransform` (transform)
- `deferredFinish` (bool)
- `parent` (object)
- `tag` (string)
- `removeFromViewport` (bool)
- `twoSided` (bool)
- `drawSize` (Vector2D)

```lua
local hudComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=true, twoSided=true, drawSize=vector_2(620, 75)})
local hudComponent = uevrUtils.createWidgetComponent("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C", {removeFromViewport=true, twoSided=true, drawSize=vector_2(100, 100)})
```

### uevrUtils.createRenderTarget2D(options)
Creates a render target 2D texture for custom rendering.

```lua
local renderTarget = uevrUtils.createRenderTarget2D({width=1024, height=1024})
```

### uevrUtils.createSceneCaptureComponent(options)
Creates a scene capture component for capturing the scene to a render target.

```lua
local sceneCapture = uevrUtils.createSceneCaptureComponent({renderTarget=myRenderTarget})
```

### uevrUtils.cloneComponent(component, options)
Creates a copy of an existing component.

```lua
local clonedComponent = uevrUtils.cloneComponent(originalComponent, {parent=newParent})
```

### uevrUtils.destroyComponent(component, destroyOwner, destroyChildren)
Destroys a component and optionally its owner and children.

```lua
uevrUtils.destroyComponent(component, false, true)  -- destroy component and children but not owner
```

### uevrUtils.detachAndDestroyComponent(component, destroyOwner, destroyChildren)
Detaches and then destroys a component.

```lua
uevrUtils.detachAndDestroyComponent(component, false, false)
```

### uevrUtils.set_component_relative_location(component, position)
Sets the relative location of a component.

```lua
uevrUtils.set_component_relative_location(component, {X=10, Y=20, Z=30})
```

### uevrUtils.set_component_relative_rotation(component, rotation)
Sets the relative rotation of a component.

```lua
uevrUtils.set_component_relative_rotation(component, {Pitch=0, Yaw=90, Roll=0})
```

### uevrUtils.set_component_relative_scale(component, scale)
Sets the relative scale of a component.

```lua
uevrUtils.set_component_relative_scale(component, {X=1.5, Y=1.5, Z=1.5})
```

### uevrUtils.set_component_relative_transform(component, position, rotation, scale)
Sets the relative position, rotation and scale of a component class derived object.

```lua
uevrUtils.set_component_relative_transform(meshComponent) -- position and rotation are set to 0s, scale is set to 1
uevrUtils.set_component_relative_transform(meshComponent, {X=10, Y=10, Z=10}, {Pitch=0, Yaw=90, Roll=0})
```

### uevrUtils.getChildComponent(parent, name)
Gets a child component of a given parent component using partial name.

```lua
local referenceGlove = uevrUtils.getChildComponent(pawn.Mesh, "Gloves")
```

### uevrUtils.getPropertiesOfClass(object, className, excludeInherited)
Gets the properties of a class for the given object.

```lua
local properties = uevrUtils.getPropertiesOfClass(myActor, "Actor", false)
```

### uevrUtils.getPropertyPathDescriptorsOfClass(object, objectName, className, includeChildren)
Gets property path descriptors for a class.

```lua
local descriptors = uevrUtils.getPropertyPathDescriptorsOfClass(myObject, "MyObject", "MyClass", true)
```

### uevrUtils.getRootBoneOfBone(skeletalMeshComponent, boneName)
Gets the root bone of a specific bone in a skeletal mesh.

```lua
local rootBone = uevrUtils.getRootBoneOfBone(skelMesh, "hand_r")
```

### uevrUtils.getBoneNames(skeletalMeshComponent)
Gets all bone names from a skeletal mesh component.

```lua
local boneNames = uevrUtils.getBoneNames(skelMesh)
```

### uevrUtils.getActiveWidgetByClass(className)
Gets the currently active widget of the specified class.

```lua
local hudWidget = uevrUtils.getActiveWidgetByClass("Class /Script/MyGame.HUDWidget")
```

## VR & Camera Controls

### uevrUtils.fadeCamera(rate, hardLock, softLock, overrideHardLock, overrideSoftLock)
Fades the players camera to black.

```lua
uevrUtils.fadeCamera(1.0) -- fades the camera to black over one second at which time the fade will disappear
uevrUtils.fadeCamera(1.0, true) -- fades the camera to black over one second and then keeps it black
uevrUtils.fadeCamera(0.1, false, false, true) -- unfades a camera that was previously locked to black
```

### uevrUtils.stopFadeCamera()
Stops any active camera fade effect and removes fade locks.

```lua
uevrUtils.stopFadeCamera()  -- immediately removes any camera fade
```

### uevrUtils.isFadeHardLocked()
Returns whether the camera fade is currently hard locked.

```lua
if uevrUtils.isFadeHardLocked() then
    uevrUtils.stopFadeCamera()
end
```

### uevrUtils.set_2D_mode(state, delay_msec)
Make UEVR switch in or out of 2D mode.

```lua
uevrUtils.set_2D_mode(true)
```

### uevrUtils.get_2D_mode()
Gets the current 2D mode state.

```lua
local is2D = uevrUtils.get_2D_mode()
```

### uevrUtils.set_decoupled_pitch(state)
Sets decoupled pitch mode.

```lua
uevrUtils.set_decoupled_pitch(true)
```

### uevrUtils.get_decoupled_pitch()
Gets the current decoupled pitch state.

```lua
local isDecoupled = uevrUtils.get_decoupled_pitch()
```

### uevrUtils.set_decoupled_pitch_adjust_ui(state)
Sets whether UI adjusts with decoupled pitch.

```lua
uevrUtils.set_decoupled_pitch_adjust_ui(false)
```

### uevrUtils.get_decoupled_pitch_adjust_ui()
Gets the current decoupled pitch UI adjustment state.

```lua
local adjustsUI = uevrUtils.get_decoupled_pitch_adjust_ui()
```

### uevrUtils.enableCameraLerp(state, pitch, yaw, roll)
Enables/disables camera lerping for specified axes.

```lua
uevrUtils.enableCameraLerp(true, true, true, false)  -- enable lerp for pitch and yaw only
```

### uevrUtils.enableUIFollowsView(state)
Enables/disables UI following the view direction.

```lua
uevrUtils.enableUIFollowsView(true)  -- UI will follow player's view
```

### uevrUtils.enableSnapTurn(state)
Enables/disables snap turning.

```lua
uevrUtils.enableSnapTurn(true)
```

### uevrUtils.setUIFollowsViewOffset(offset)
Sets the offset position for UI following view.

```lua
uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=100})  -- offset UI 100 units forward
```

### uevrUtils.setUIFollowsViewSize(size)
Sets the scale of UI when following view.

```lua
uevrUtils.setUIFollowsViewSize(1.5)  -- make UI 1.5x normal size
```

## Input & Controller Functions

### uevrUtils.isButtonPressed(state, button)
Returns true if the given XINPUT button is pressed. The state param comes from on_xinput_get_state().

```lua
if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_X) then
    print("X button pressed")
end
```

### uevrUtils.isButtonNotPressed(state, button)
Returns true if the given XINPUT button is not pressed.

```lua
if uevrUtils.isButtonNotPressed(state, XINPUT_GAMEPAD_A) then
    print("A button not pressed")
end
```

### uevrUtils.pressButton(state, button)
Triggers a button press for the specified button.

```lua
uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
```

### uevrUtils.unpressButton(state, button)
Stops a button press for the specified button.

```lua
uevrUtils.unpressButton(state, XINPUT_GAMEPAD_X)
```

### uevrUtils.isThumbpadTouched(state, hand)
Checks if the thumbpad is being touched for specified hand.

```lua
if uevrUtils.isThumbpadTouched(state, Handed.Right) then
    print("Right thumbpad touched")
end
```

### uevrUtils.triggerHapticVibration(hand, secondsFromNow, duration, frequency, amplitude)
Triggers controller haptic feedback.

```lua
uevrUtils.triggerHapticVibration(Handed.Left, 0, 0.1, 1000, 1.0)  -- immediate short vibration
```

### uevrUtils.getControllerIndex(controllerID)
Gets VR controller index (0=left, 1=right, 2=HMD).

```lua
local leftIndex = uevrUtils.getControllerIndex(0)
```

### uevrUtils.get_local_pawn()
Returns the local player pawn.

```lua
local pawn = uevrUtils.get_local_pawn()
```

### uevrUtils.get_player_controller()
Returns the local player controller.

```lua
local controller = uevrUtils.get_player_controller()
```

## Callback System

### uevrUtils.initUEVR(UEVR, callbackFunc)
Initializes the UEVR library with the provided UEVR instance and optional callback function.

```lua
uevrUtils.initUEVR(uevr, function()
    print("UEVR initialized")
end)
```

### uevrUtils.registerUEVRCallback(callbackName, callbackFunc, priority)
Registers a callback function for the specified UEVR event with optional priority.

```lua
uevrUtils.registerUEVRCallback("levelChange", function(levelName)
    print("Level changed to:", levelName)
end, 10)
```

### uevrUtils.executeUEVRCallbacks(callbackName, ...)
Executes all registered callbacks for the specified event.

```lua
uevrUtils.executeUEVRCallbacks("levelChange", "NewLevel")
```

### uevrUtils.executeUEVRCallbacksWithBooleanResult(callbackName, ...)
Executes callbacks and returns a boolean result based on callback responses.

```lua
local result = uevrUtils.executeUEVRCallbacksWithBooleanResult("inputCheck", inputData)
```

### uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult(callbackName, ...)
Executes callbacks in priority order and returns boolean result.

```lua
local result = uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("priorityEvent", eventData)
```

### uevrUtils.hasUEVRCallbacks(callbackName)
Checks if there are any registered callbacks for the specified event.

```lua
if uevrUtils.hasUEVRCallbacks("levelChange") then
    print("Level change callbacks are registered")
end
```

### uevrUtils.registerOnInputGetStateCallback(func, priority)
Registers a callback for input state changes.

```lua
uevrUtils.registerOnInputGetStateCallback(function(retval, user_index, state)
    print("Input state changed for user", user_index)
end)
```

### uevrUtils.registerOnPreInputGetStateCallback(func, priority)
Registers a callback before input state processing.

```lua
uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
    -- Pre-process input
end)
```

### uevrUtils.registerOnPostInputGetStateCallback(func, priority)
Registers a callback after input state processing.

```lua
uevrUtils.registerOnPostInputGetStateCallback(function(retval, user_index, state)
    -- Post-process input
end)
```

### uevrUtils.registerPreEngineTickCallback(func, priority)
Registers a callback before each engine tick.

```lua
uevrUtils.registerPreEngineTickCallback(function(engine, delta)
    print("Pre-tick with delta:", delta)
end)
```

### uevrUtils.registerPostEngineTickCallback(func, priority)
Registers a callback after each engine tick.

```lua
uevrUtils.registerPostEngineTickCallback(function(engine, delta)
    print("Post-tick with delta:", delta) 
end)
```

### uevrUtils.registerPreCalculateStereoViewCallback(func, priority)
Registers a callback before stereo view calculations.

```lua
uevrUtils.registerPreCalculateStereoViewCallback(function(device, view_index, ...)
    print("Pre-calculate stereo view for device", device)
end)
```

### uevrUtils.registerPostCalculateStereoViewCallback(func, priority)
Registers a callback after stereo view calculations.

```lua
uevrUtils.registerPostCalculateStereoViewCallback(function(device, view_index, ...)
    print("Post-calculate stereo view for device", device)
end)
```

### uevrUtils.registerLevelChangeCallback(func, priority)
Registers a callback for when the game level changes.

```lua
uevrUtils.registerLevelChangeCallback(function(levelName)
    print("Level changed to:", levelName)
end)
```

### uevrUtils.registerPreLevelChangeCallback(func, priority)
Registers a callback before the game level changes.

```lua
uevrUtils.registerPreLevelChangeCallback(function(levelName)
    print("Level about to change to:", levelName)
end)
```

### uevrUtils.registerGamePausedCallback(func, priority)
Registers a callback for when the game is paused/unpaused.

```lua
uevrUtils.registerGamePausedCallback(function(isPaused)
    print("Game paused:", isPaused)
end)
```

### uevrUtils.registerCharacterHiddenCallback(func, priority)
Registers a callback for when the character is hidden/shown.

```lua
uevrUtils.registerCharacterHiddenCallback(function(isHidden)
    print("Character hidden:", isHidden)
end)
```

### uevrUtils.registerCutsceneChangeCallback(func, priority)
Registers a callback for cutscene state changes.

```lua
uevrUtils.registerCutsceneChangeCallback(function(inCutscene)
    print("In cutscene:", inCutscene)
end)
```

### uevrUtils.registerMontageChangeCallback(func, priority)
Registers a callback for animation montage changes.

```lua
uevrUtils.registerMontageChangeCallback(function(montageData)
    print("Montage changed:", montageData)
end)
```

### uevrUtils.registerHandednessChangeCallback(func, priority)
Registers a callback for handedness preference changes.

```lua
uevrUtils.registerHandednessChangeCallback(function(handedness)
    print("Handedness changed to:", handedness)
end)
```

### uevrUtils.registerUEVRUIChangeCallback(func, priority)
Registers a callback for when the UEVR UI visibility state changes.

```lua
uevrUtils.registerUEVRUIChangeCallback(function(isUIVisible)
    print("UEVR UI visible:", isUIVisible)
end)
```

## Utility Functions

### uevrUtils.enableDebug(val)
Enables/disables debug logging (true = LogLevel.Debug, false = LogLevel.Off).

```lua
uevrUtils.enableDebug(true)  -- Enable debug logging
```

### uevrUtils.setLogLevel(val)
Sets the log level filtering (LogLevel.Off, LogLevel.Debug, LogLevel.Info, etc).

```lua
uevrUtils.setLogLevel(LogLevel.Info)  -- Only show Info level and above
```

### uevrUtils.setLogToFile(val)
Enables/disables logging to file in addition to console.

```lua
uevrUtils.setLogToFile(true)  -- Also write logs to file
```

### uevrUtils.print(str, logLevel)
Prints a message with the specified log level (defaults to Debug).

```lua
uevrUtils.print("Starting initialization", LogLevel.Info)
```

### uevrUtils.log_info(message)
Logs message to log.txt file.

```lua
uevrUtils.log_info("Custom log message")
```

### uevrUtils.setDeveloperMode(val)
Enables/disables developer mode features.

```lua
uevrUtils.setDeveloperMode(true)
```

### uevrUtils.getDeveloperMode()
Returns current developer mode state.

```lua
if uevrUtils.getDeveloperMode() then
    -- Do developer-only things
end
```

### uevrUtils.setHandedness(val)
Sets the handedness preference (left or right handed).

```lua
uevrUtils.setHandedness(Handed.Left)   -- set to left-handed
uevrUtils.setHandedness(Handed.Right)  -- set to right-handed
```

### uevrUtils.getHandedness()
Gets the current handedness preference.

```lua
local currentHandedness = uevrUtils.getHandedness()
if currentHandedness == Handed.Left then
    print("User is left-handed")
end
```

### uevrUtils.guid()
Generates a unique identifier.

```lua
local uniqueId = uevrUtils.guid()
```

### uevrUtils.getEngineVersion()
Returns the current Unreal Engine version number as a string.

```lua
local version = uevrUtils.getEngineVersion()
print("Running on UE version:", version)
```

### uevrUtils.isGamePaused()
Returns whether the game is currently paused.

```lua
if uevrUtils.isGamePaused() then
    print("Game is paused")
end
```

### uevrUtils.isInCutscene()
Returns whether the game is currently in a cutscene.

```lua
if uevrUtils.isInCutscene() then
    print("Currently in cutscene")
end
```

### uevrUtils.get_struct_object(structClassName, reuseable)
Get a structure object that can optionally be reuseable.

```lua
local vector = uevrUtils.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D")
```

### uevrUtils.get_reuseable_struct_object(structClassName)
Gets a structure that can be reused in the way temp_transform was used but for any structure class.

```lua
local reuseableColor = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")
reuseableColor.R = 1.0
```

### uevrUtils.fname_from_string(str)
Returns the FName of a given string.

```lua
local fname = uevrUtils.fname_from_string("Mesh")
```

### uevrUtils.color_from_rgba(r,g,b,a,reuseable)
Returns a CoreUObject.LinearColor struct with the given params in the range of 0.0 to 1.0.

```lua
local color = uevrUtils.color_from_rgba(1.0, 0.0, 0.0, 1.0)
```

### uevrUtils.color_from_rgba_int(r,g,b,a,reuseable)
Returns a CoreUObject.Color struct with the given params in the range of 0 to 255.

```lua
local color = uevrUtils.color_from_rgba_int(255, 0, 0, 255)
```

### uevrUtils.hexToColor(hex)
Converts a hexadecimal color string to a color object.

```lua
local color = uevrUtils.hexToColor("#FF0000FF")
```

### uevrUtils.intToColor(num)
Converts an integer to a color object.

```lua
local color = uevrUtils.intToColor(0xFF0000FF)
```

### uevrUtils.intToHexString(num)
Converts an integer to "#RRGGBBAA" color format.

```lua
local hex = uevrUtils.intToHexString(0xFF0000FF)  -- returns "#FF0000FF"
```

### uevrUtils.splitStr(inputstr, sep)
Splits a string by a separator into a table.

```lua
local parts = uevrUtils.splitStr("a,b,c", ",")  -- returns {"a", "b", "c"}
```

### uevrUtils.splitOnLastPeriod(input)
Splits a string on the last period character.

```lua
local prefix, suffix = uevrUtils.splitOnLastPeriod("path.to.object")
```

### uevrUtils.PositiveIntegerMask(text)
Filters text to only allow positive integers and minus sign.

```lua
local number = uevrUtils.PositiveIntegerMask("abc123def-456")  -- returns "123-456"
```

### uevrUtils.getArrayFromVector2(vec)
Converts a Vector2D to an array.

```lua
local array = uevrUtils.getArrayFromVector2(vector2D)
```

### uevrUtils.getArrayFromVector3(vec)
Converts a Vector3 to an array.

```lua
local array = uevrUtils.getArrayFromVector3(vector3D)
```

### uevrUtils.getArrayFromVector4(vec)
Converts a Vector4 to an array.

```lua
local array = uevrUtils.getArrayFromVector4(vector4D)
```

### uevrUtils.getNativeValue(val, useTable)
Gets the native value from a UE object, optionally as a table.

```lua
local nativeValue = uevrUtils.getNativeValue(ueObject, true)
```

### uevrUtils.tableToString(tbl, indent)
Converts a Lua table to a formatted string representation.

```lua
local tableStr = uevrUtils.tableToString({a=1, b=2, c={d=3}}, 2)
```

### uevrUtils.dumpJson(filename, jsonData)
Converts any lua table to a json structure and dumps it to a file.

```lua
local configDefinition = {name = "Hello", data = {1,2,3}}
uevrUtils.dumpJson("test", configDefinition)
```

### uevrUtils.PrintInstanceNames(class_to_search)
Print all instance names of a class to debug console.

```lua
uevrUtils.PrintInstanceNames("Class /Script/Engine.StaticMesh")
```

## Advanced Features

### uevrUtils.getAssetDataFromPath(pathStr)
Converts a path string into an AssetData structure.

```lua
local fAssetData = uevrUtils.getAssetDataFromPath("StaticMesh /Game/Environment/Meshes/SM_Sword.SM_Sword")
```

### uevrUtils.getLoadedAsset(pathStr)
Get an object even if it's not already loaded into the system.

```lua
local staticMesh = uevrUtils.getLoadedAsset("StaticMesh /Game/Environment/Meshes/SM_Sword.SM_Sword")
```

### uevrUtils.copyMaterials(fromComponent, toComponent, showDebug)
Copy Materials from one component to another.

```lua
uevrUtils.copyMaterials(wand.SK_Wand, component)
```

### uevrUtils.fixMeshFOV(mesh, propertyName, value, includeChildren, includeNiagara, showDebug)
Removes the FOV distortions that many flat FPS games apply to player and weapon meshes using ScalarParameterValues.

```lua
uevrUtils.fixMeshFOV(hands.getHandComponent(0), "UsePanini", 0.0, true, true, true)
```

### uevrUtils.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance, maxTraceDistance)
Performs a line trace from origin in direction and returns hit location.

```lua
local hitLocation = uevrUtils.getTargetLocation(startPos, forwardVec, 0, {}, false, 10)
```

### uevrUtils.getLineTraceHitResult(originPosition, originDirection, collisionChannel, traceComplex, ignoreActors, minHitDistance, maxTraceDistance, includeFullDetails)
Performs a line trace from origin in direction and returns detailed hit result information.

```lua
local hitResult = uevrUtils.getLineTraceHitResult(startPos, forwardVec, 0, false, {}, 10, 1000, true)
```

### uevrUtils.getCleanHitResult(hitResult)
Cleans and processes a hit result from a line trace.

```lua
local cleanResult = uevrUtils.getCleanHitResult(rawHitResult)
```

### uevrUtils.getArrayRange(arr, startIndex, endIndex)
Returns a subset of an array from startIndex to endIndex (1-based indexing).

```lua
local subset = uevrUtils.getArrayRange(myArray, 2, 5)  -- gets elements 2-5
```

### uevrUtils.wrapTextOnWordBoundary(text, maxCharsPerLine)
Wraps text to specified line length while preserving word boundaries.

```lua
local wrapped = uevrUtils.wrapTextOnWordBoundary("This is a long line", 10)
```

### uevrUtils.parseHierarchyString(str)
Parses a hierarchy string like "Pawn.Mesh(Arm).Glove" into traversable node structure.

```lua
local node = uevrUtils.parseHierarchyString("Pawn.Mesh(Arm).Glove")
```

### uevrUtils.getObjectFromHierarchy(node, object, showDebug)
Traverses object hierarchy using parsed node structure.

```lua
local result = uevrUtils.getObjectFromHierarchy(node, pawn, true)
```

### uevrUtils.getObjectFromDescriptor(descriptor, showDebug)
Gets object using hierarchy descriptor string.

```lua
local glove = uevrUtils.getObjectFromDescriptor("Pawn.Mesh(Arm).Glove", false)
```

### uevrUtils.getUEVRParam_bool(paramName)
Gets a boolean UEVR parameter value.

```lua
local isEnabled = uevrUtils.getUEVRParam_bool("VR_EnableFeature")
```

### uevrUtils.getUEVRParam_int(paramName, default)
Gets an integer UEVR parameter value with optional default.

```lua
local value = uevrUtils.getUEVRParam_int("VR_Quality", 2)
```

### uevrUtils.get_cvar_int(cvar)
Gets an integer console variable value.

```lua
local fogValue = uevrUtils.get_cvar_int("r.VolumetricFog")
```

### uevrUtils.set_cvar_int(cvar, value)
Sets an int cvar value.

```lua
uevrUtils.set_cvar_int("r.VolumetricFog", 0)
```

### uevrUtils.set_cvar_float(cvar, value)
Sets a float console variable value.

```lua
uevrUtils.set_cvar_float("r.ScreenPercentage", 100.0)
```

## Key Binding System

### register_key_bind(keyName, callbackFunc)
Registers a callback function that will be triggered when a key is pressed.

```lua
register_key_bind("F1", function()
    print("F1 pressed\n")
end)
register_key_bind("LeftMouseButton", function()
    print("Left mouse button pressed\n")
end)
```

### Supported Key Names

#### Keyboard
- **Letters**: "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
- **Arrow keys**: "Left", "Up", "Right", "Down"
- **Numbers**: "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"
- **NumPad**: "NumPadZero", "NumPadOne", "NumPadTwo", "NumPadThree", "NumPadFour", "NumPadFive", "NumPadSix", "NumPadSeven", "NumPadEight", "NumPadNine"
- **NumPad operators**: "Multiply", "Add", "Subtract", "Decimal", "Divide"
- **Control keys**: "BackSpace", "Tab", "Enter", "Pause", "NumLock", "ScrollLock", "CapsLock", "Escape", "SpaceBar", "PageUp", "PageDown", "End", "Home", "Insert", "Delete"
- **Function keys**: "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
- **Modifier keys**: "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt", "LeftCommand", "RightCommand"
- **Symbols**: "Semicolon", "Equals", "Comma", "Underscore", "Period", "Slash", "Tilde", "LeftBracket", "Backslash", "RightBracket", "Quote"

#### Mouse
- **Axes**: "MouseX", "MouseY", "MouseScrollUp", "MouseScrollDown", "MouseWheelSpin"
- **Buttons**: "LeftMouseButton", "RightMouseButton", "MiddleMouseButton", "ThumbMouseButton", "ThumbMouseButton2"

#### Gamepads
- **Analog sticks**: "Gamepad_LeftX", "Gamepad_LeftY", "Gamepad_RightX", "Gamepad_RightY"
- **Triggers**: "Gamepad_LeftTriggerAxis", "Gamepad_RightTriggerAxis"
- **Stick buttons**: "Gamepad_LeftThumbstick", "Gamepad_RightThumbstick"
- **Special buttons**: "Gamepad_Special_Left", "Gamepad_Special_Right"
- **Face buttons**: "Gamepad_FaceButton_Bottom", "Gamepad_FaceButton_Right", "Gamepad_FaceButton_Left", "Gamepad_FaceButton_Top"
- **Shoulder buttons**: "Gamepad_LeftShoulder", "Gamepad_RightShoulder", "Gamepad_LeftTrigger", "Gamepad_RightTrigger"
- **D-Pad**: "Gamepad_DPad_Up", "Gamepad_DPad_Down", "Gamepad_DPad_Right", "Gamepad_DPad_Left"
- **Virtual stick directions**: "Gamepad_LeftStick_Up", "Gamepad_LeftStick_Down", "Gamepad_LeftStick_Right", "Gamepad_LeftStick_Left", "Gamepad_RightStick_Up", "Gamepad_RightStick_Down", "Gamepad_RightStick_Right", "Gamepad_RightStick_Left"

#### Touch Devices
- **Motion**: "Tilt", "RotationRate", "Gravity", "Acceleration"
- **Gestures**: "Gesture_SwipeLeftRight", "Gesture_SwipeUpDown", "Gesture_TwoFingerSwipeLeftRight", "Gesture_TwoFingerSwipeUpDown", "Gesture_Pinch", "Gesture_Flick"

## Hook System

### hook_function(class_name, function_name, native, prefn, postfn, dbgout)
A method of getting a function callback from the game engine.

```lua
hook_function("BlueprintGeneratedClass /Game/Blueprints/Player/PlayerCharacter_BP.PlayerCharacter_BP_C", "PlayerCinematicChange", false, 
    function(fn, obj, locals, result)
        print("PlayerCharacter PlayerCinematicChange")
        isInCinematic = locals.bCinematicMode
        return true
    end
, nil, true)
```

## Lifecycle Callbacks

The following functions can be added to your main script. They are optional and will only be called if you add them:

### on_xinput_get_state(retval, user_index, state)
Callback for uevr.sdk.callbacks.on_xinput_get_state

### on_pre_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
Callback for on_pre_calculate_stereo_view_offset

### on_post_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
Callback for on_post_calculate_stereo_view_offset

### on_pre_engine_tick(engine, delta)
Callback for uevr.sdk.callbacks.on_pre_engine_tick

### on_post_engine_tick(engine, delta)
Callback for uevr.sdk.callbacks.on_post_engine_tick

### on_lazy_poll()
Function that gets called once per second for things you want to do at a slower interval than every tick

### on_level_change(level, levelName)
Function that gets called when the level changes

### UEVRReady(instance)
Function that gets called when this library has finished initializing

## UEVR Lifecycle

The UEVR rendering lifecycle follows this order:
1. Pre engine
2. Early Stereo (one eye)
3. Pre Stereo (one eye)
4. Post Stereo (one eye)
5. Early Stereo (other eye)
6. Pre Stereo (other eye)
7. Post Stereo (other eye)
8. Post engine

## Utility Arrays

### spliceableInlineArray & expandArray
A utility that enables declarative construction of Lua arrays by allowing inline expansion of multiple return values at arbitrary positions within a table.

```lua
local function getWidgets()
    return { {type="button"}, {type="slider"}, {type="checkbox"} }
end

local ui = spliceableInlineArray {
    {type="label"},
    expandArray(getWidgets),
    {type="footer"}
}
```

---

This documentation covers all externally exposed functions in the UEVR Utils library. For implementation details and source code, refer to the actual `uevr_utils.lua` file.
