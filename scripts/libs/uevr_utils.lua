
-- The following code includes contributions from markmon, Pande4360, Rusty Gere and lobotomy

--[[ 
Usage
	Drop the lib folder containing this file into your project folder
	At the top of your script file add 
		local uevrUtils = require("libs/uevr_utils")
		uevrUtils.initUEVR(uevr)
		
	In your code call function like this
		local actor = uevrUtils.spawn_actor(transform, collisionMethod, owner)
		
	Some functions such as setTimeout(msec, func) that are globally useful have both
	a global and module referenced implementation. The module reference is just for
	convenience and does nothing but call the global implementation
	
	Available functions:
	
	setTimeout(msec, func) or uevrUtils.setTimeout(msec, func)) or uevrUtils.delay(msec, func) - delays for specified number of milliseconds 
		before executing func. 
		delay(msec, func) is deprecated to prevent global naming conflicts but, if used, will still call setTimeout(msec, func) internally
		example: 
			setTimeout(1000, function()
				print("after one second delay")
			end)
			
	setInterval(msec, func) or uevrUtils.setInterval(msec, func) - delays for specified number of milliseconds before executing func then repeats
		example: 
			setInterval(1000, function()
				print("repeats one second delay")
			end)
			
	doOnce(func, (optional)scopeType) - executes the function once, no matter how many times it is called.
		scopeType can be Once.EVER and the function will only execute once ever, or Once.PER_LEVEL and the
		function will execute only once each time there is a new level. Your function can return values
		example:
			local initGlobal = doOnce(function()
				print("Global init")
				return "Hello"
			end, Once.EVER)

			local initLevel = doOnce(function()
				print("Level init")
			end, Once.PER_LEVEL)

			local retValue = initGlobal()  	-- prints Global init
			print(retVal)					-- prinst Hello
			retValue = initGlobal()  		-- does not print anything
			print(retVal)					-- prints nil
			initLevel()   -- prints Level init
			initLevel()   -- does nothing
			-- game level changes
			initLevel()   -- prints Level init again 
			initGlobal:reset() -- even though this function was set as Once.EVER you can manually reset it
			initGlobal()  -- prints Global init
			
			-- doOnce is also fault tolerant and can re-execute on failure. Just call error() on failure. 
			
			local failCount = 0
			local canFail = doOnce(function()
				if failCount < 3 then
					failCount = failCount + 1
					print("canFail failed.")
					error()
				end
				print("canFail succeeded")
			end, Once.EVER)

			canFail()   -- prints canFail failed.
			canFail()   -- prints canFail failed.
			canFail()   -- prints canFail failed.   
			canFail() 	-- prints canFail succeeded 
			canFail()   -- does nothing
			canFail()   -- does nothing

	createDeferral(name, timeoutMs, callback) or uevrUtils.createDeferral(name, timeoutMs, callback) - creates a named deferral that will execute 
		a callback function after a specified timeout. The deferral starts inactive and must be activated with updateDeferral().
		example:
			uevrUtils.createDeferral("reload_cooldown", 2000, function()
				print("Reload cooldown finished - can reload again")
			end)
			
	updateDeferral(name) or uevrUtils.updateDeferral(name) - activates a deferral, starting its countdown timer. If the deferral is already 
		active, this resets the countdown to the full timeout duration.
		example:
			uevrUtils.updateDeferral("reload_cooldown")  -- starts or restarts the 2-second countdown
			
	destroyDeferral(name) or uevrUtils.destroyDeferral(name) - removes a deferral entirely, preventing it from executing its callback.
		example:
			uevrUtils.destroyDeferral("reload_cooldown")  -- cancels the deferral

	uevrUtils.vector_2(x, y, reuseable) - returns a CoreUObject.Vector2D structure with the given params
		example:
			print("X value is",uevrUtils.vector_2(3, 4).X)
			
	uevrUtils.vector_3(x, y, z) - returns a UEVR Vector3d structure with the given params. Replacement for using temp_vec3 directly
		example:
			print("Z value is",uevrUtils.vector_3(3, 4, 5).Z)
	
	uevrUtils.vector_3f(x, y, z) - returns a UEVR Vector3f structure with the given params. Replacement for using temp_vec3f directly
		example:
			print("Z value is",uevrUtils.vector_3f(3, 4, 5).Z)
	
	uevrUtils.quatf(x, y, z, w) - returns a UEVR Quaternion structure with the given params
		example:
			print("Z value is",uevrUtils.quatf(3, 4, 5, 1).Z)
	
	uevrUtils.quat(x, y, z, w, reuseable) - returns a CoreUObject.Quat structure with the given params.
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("Z value is",uevrUtils.quat(3, 4, 5, 1).Z)
	
	uevrUtils.rotator(pitch, yaw, roll, reuseable) - returns a CoreUObject.Rotator with the given params
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("Pitch value is",uevrUtils.rotator(30, 0, 0).Pitch)
			print("Yaw value is",uevrUtils.rotator(30, 40, 50).Yaw)
			
	uevrUtils.lerp(lerpID, startAlpha, endAlpha, duration, userdata, callback) - smoothly interpolates from startAlpha to endAlpha over duration seconds
		lerpID is a unique identifier to track this lerp operation
		userdata is optional data passed to the callback function
		callback is called each frame during interpolation with current alpha value and userdata
		example:
			uevrUtils.lerp("fade", 0, 1, 2.0, nil, function(alpha, data)
				print("Current fade alpha:", alpha)  
			end)
			
	uevrUtils.cancelLerp(lerpID) - cancels an active lerp operation
		example:
			uevrUtils.cancelLerp("fade")
			
	uevrUtils.enableDebug(val) - enables/disables debug logging (true = LogLevel.Debug, false = LogLevel.Off)
		example:
			uevrUtils.enableDebug(true)  -- Enable debug logging
			
	uevrUtils.getEngineVersion() - returns the current Unreal Engine version number as a string
		example:
			local version = uevrUtils.getEngineVersion()
			print("Running on UE version:", version)
			
	uevrUtils.setLogLevel(val) - sets the log level filtering (LogLevel.Off, LogLevel.Debug, LogLevel.Info, etc)
		example:
			uevrUtils.setLogLevel(LogLevel.Info)  -- Only show Info level and above
			
	uevrUtils.setLogToFile(val) - enables/disables logging to file in addition to console
		example:
			uevrUtils.setLogToFile(true)  -- Also write logs to file
			
	uevrUtils.print(str, logLevel) - prints a message with the specified log level (defaults to Debug)
		example:
			uevrUtils.print("Starting initialization", LogLevel.Info)
			
	uevrUtils.setDeveloperMode(val) - enables/disables developer mode features
		example:
			uevrUtils.setDeveloperMode(true)
			
	uevrUtils.getDeveloperMode() - returns current developer mode state
		example:
			if uevrUtils.getDeveloperMode() then
				-- Do developer-only things
			end

	uevrUtils.setHandedness(val) - sets the handedness preference (left or right handed)
		example:
			uevrUtils.setHandedness(Handed.Left)   -- set to left-handed
			uevrUtils.setHandedness(Handed.Right)  -- set to right-handed
			
	uevrUtils.getHandedness() - gets the current handedness preference 
		example:
			local currentHandedness = uevrUtils.getHandedness()
			if currentHandedness == Handed.Left then
				print("User is left-handed")
			end

	uevrUtils.vector(x, y, z, (optional)reuseable) - returns a CoreUObject.Vector with the given params
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("X value is",uevrUtils.vector(30, 40, 50).X)
	
	uevrUtils.vector(table, (optional)reuseable) - returns a CoreUObject.Vector with the given params
		If reuseable is true a cached struct is returned. 
		example:
			print("X value is",uevrUtils.vector({30,40,50}).X)
			print("X value is",uevrUtils.vector({X=30,Y=40,Z=50}).X)
			print("X value is",uevrUtils.vector({x=30,y=40,z=50}).X)
	
	uevrUtils.rotatorFromQuat(x, y, z, w) - returns CoreUObject.Rotator given the x,y,z and w values from a quaternion
		example:
			print("Yaw value is",uevrUtils.rotatorFromQuat(0, 0, 0, 1).Yaw)
	
	uevrUtils.get_transform((optional)position, (optional)rotation, (optional)scale) -- returns a CoreUObject.Transform struct with the given params. 
		Replacement for temp_transform
		examples:
			local transform = uevrUtils.get_transform() -- position and rotation are set to 0s, scale is set to 1
			local transform = uevrUtils.get_transform({X=10, Y=15, Z=20})
			local transform = uevrUtils.get_transform({X=10, Y=15, Z=20}, nil, {X=.5, Y=.5, Z=.5})
			
	uevrUtils.set_component_relative_transform(component, (optional)position, (optional)rotation, (optional)scale) - sets the relative position, rotation
		and scale of a component class derived object
		examples:
			uevrUtils.set_component_relative_transform(meshComponent) -- position and rotation are set to 0s, scale is set to 1
			uevrUtils.set_component_relative_transform(meshComponent, {X=10, Y=10, Z=10}, {Pitch=0, Yaw=90, Roll=0})
	
	uevrUtils.get_struct_object(structClassName, (optional)reuseable) - get a structure object that can optionally be reuseable
		example:
			local vector = uevrUtils.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D")
			
	uevrUtils.get_reuseable_struct_object(structClassName) - gets a structure that can be reused in the way temp_transform was used but for any structure class
		The structure is cached so repeated calls to this function for the same class incur no penalty
		example:
			local reuseableColor = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")
			reuseableColor.R = 1.0
			
	uevrUtils.get_world() - gets the current world
		example:
			local world = uevrUtils.get_world()
	
	uevrUtils.spawn_actor(transform, collisionMethod, owner) - spawns an actor with the given params
		example:
			local pos = pawn:K2_GetActorLocation()
			local actor = uevrUtils.spawn_actor( uevrUtils.get_transform({X=pos.X, Y=pos.Y, Z=pos.Z}), 1, nil)
		
	uevrUtils.getValid(object, (optional)properties) -- returns a valid object or property of an object or nil if none is found. Use this
		in place of endless nested checks for nil on objects and their properties. Properties are passed in as an array of hierarchical 
		property names. The first example shows how to get the property pawn.Weapon.WeaponMesh
		example:
			local mesh = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
			local validPawn = uevrUtils.getValid(pawn) -- gets a valid pawn or nil
	
	uevrUtils.validate_object(object) - if the object is returned from this function then it is not nil and it exists
		if uevrUtils.validate_object(object) ~- nil then 
			print("Good object")
		end
	
	uevrUtils.destroy_actor(actor) - destroys a spawned actor
		example:
			uevrUtils.destroy_actor(actor)
		
	uevrUtils.create_component_of_class(className, (optional)manualAttachment, (optional)relativeTransform, (optional)deferredFinish, (optional)parent) - creates and 
		initializes a component based object of the desired class. If parent is provided then parent is used as the component's actor rather than create a new actor
		example:
			local component = create_component_of_class("Class /Script/Engine.StaticMeshComponent")
	
	uevrUtils.find_required_object(name) - wrapper for uevr.api:find_uobject(name).
	
	uevrUtils.get_class(name, (optional)clearCache) - cached wrapper for uevr.api:find_uobject(name). Can be called repeatedly for the same name 
		with no performance hit unless clearCache is true
		examples:
			local componentClass = uevrUtils.get_class("Class /Script/Engine.StaticMeshComponent")
			local poseableComponent = baseActor:AddComponentByClass(componentClass, true, uevrUtils.get_transform(), false)

	uevrUtils.find_instance_of(className, objectName) - find the named object instance of the given className. Can use short names for objects
		example:
			local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "Sphere")
	
	uevrUtils.find_first_of(className, (optional)includeDefault) - find the first object instance of the given className
		example:
			local widget = uevrUtils.find_first_of("Class /Script/Indiana.HUDWidget", false)

	uevrUtils.find_all_of(className, (optional)includeDefault) - find all object instances of the given className. Returns an empty array if none found
		example:
			local motionControllers = uevrUtils.find_all_of("Class /Script/HeadMountedDisplay.MotionControllerComponent", false)

	uevrUtils.find_default_instance(className) - returns get_class_default_object() for the given className. Wraps uevr class:get_class_default_object()
		example:
			kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
			
	uevrUtils.find_first_instance(className, (optional)includeDefault) - find the first class instance of a given className. Wraps uevr class:get_first_object_matching(includeDefault)
	
	uevrUtils.find_all_instances(className, (optional)includeDefault) - find the all class instances of a given className. Wraps uevr class:get_objects_matching(includeDefault)
	
	uevrUtils.fname_from_string(str) - returns the FName of a given string
		example:
			local fname = uevrUtils.fname_from_string("Mesh")
			
	uevrUtils.color_from_rgba(r,g,b,a,reuseable) or color_from_rgba(r,g,b,a,reuseable) - returns a CoreUObject.LinearColor struct with the given params in the range of 0.0 to 1.0
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			local color = uevrUtils.color_from_rgba(1.0, 0.0, 0.0, 1.0)
			
	uevrUtils.color_from_rgba_int(r,g,b,a,reuseable) or color_from_rgba_int(r,g,b,a,reuseable) - returns a CoreUObject.Color struct with the given params in the range of 0 to 255
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			uevr.api:get_player_controller(0):ClientSetCameraFade(false, color_from_rgba_int(0,0,0,0), vector_2(0, 1), 1.0, false, false)

	uevrUtils.isButtonPressed(state, button) - returns true if the given XINPUT button is pressed. The state param comes from on_xinput_get_state()
	uevrUtils.isButtonNotPressed(state, button) - returns true if the given XINPUT button is not pressed. The state param comes from on_xinput_get_state()
	uevrUtils.pressButton(state, button) - triggers a button press for the specified button. The state param comes from on_xinput_get_state()
	uevrUtils.unpressButton(state, button) - stops a button press for the specified button. The state param comes from on_xinput_get_state()
		example
			if isButtonPressed(state, XINPUT_GAMEPAD_X) then
				unpressButton(state, XINPUT_GAMEPAD_X)
				pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
			end
			
	uevrUtils.fadeCamera(rate, (optional)hardLock, (optional)softLock, (optional)overrideHardLock, (optional)overrideSoftLock) - fades the players camera to black
		example:
			uevrUtils.fadeCamera(1.0) - fades the camera to black over one second at which time the fade will disappear
			uevrUtils.fadeCamera(1.0, true) - fades the camera to black over one second and then keeps it black
			uevrUtils.fadeCamera(0.1, false, false, true) - unfades a camera that was previously locked to black

	uevrUtils.set_2D_mode(state, (optional)delay_msec) - make UEVR switch in or out of 2D mode
		example:
			uevrUtils.set_2D_mode(true)
			
	uevrUtils.set_cvar_int(cvar, value) or set_cvar_int(cvar, value) - sets an int cvar value
		example:
			uevrUtils.set_cvar_int("r.VolumetricFog", 0)
			
	uevrUtils.PrintInstanceNames(class_to_search) - Print all instance names of a class to debug console
	
	uevrUtils.dumpJson(filename, jsonData) - Converts any lua table to a json structure and dumps it to a file.
		Useful for saving configuration data or for debugging a table structure
		example:
			local configDefinition = {name = "Hello", data = {1,2,3}}
			uevrUtils.dumpJson("test", configDefinition)
	
	uevrUtils.getAssetDataFromPath(pathStr) - converts a path string into an AssetData structure
		example:
			local fAssetData = uevrUtils.getAssetDataFromPath("StaticMesh /Game/Environment/Hogwarts/Meshes/Statues/SM_HW_Armor_Sword.SM_HW_Armor_Sword")
			
	uevrUtils.getLoadedAsset(pathStr) - get an object even if it's not already loaded into the system
		example:
			local staticMesh = uevrUtils.getLoadedAsset("StaticMesh /Game/Environment/Hogwarts/Meshes/Statues/SM_HW_Armor_Sword.SM_HW_Armor_Sword")

	uevrUtils.copyMaterials(fromComponent, toComponent) - Copy Materials from one component to another
		example:
			uevrUtils.copyMaterials(wand.SK_Wand, component)

	uevrUtils.sumRotators(...) - adds multiple rotators together, handling both uppercase and lowercase field names
		example:
			local totalRot = uevrUtils.sumRotators({Pitch=10, Yaw=20, Roll=0}, {pitch=5, yaw=10, roll=15})
			
	uevrUtils.distanceBetween(vector1, vector2) - calculates the distance between two vectors
		example:
			local dist = uevrUtils.distanceBetween(player:K2_GetActorLocation(), target:K2_GetActorLocation())
			
	uevrUtils.getForwardVector(rotator) - gets the forward vector from a rotator
		example:
			local fwd = uevrUtils.getForwardVector(camera:K2_GetActorRotation())
			
	uevrUtils.clampAngle180(angle) - clamps an angle to the range -180 to 180 degrees
		example:
			local normalizedAngle = uevrUtils.clampAngle180(370)  -- returns 10
			
	uevrUtils.getShortName(object) - gets the short name of a UObject
		example:
			local name = uevrUtils.getShortName(actor)  -- returns just the object name without path
			
	uevrUtils.getFullName(object) - gets the full path name of a UObject
		example:
			local fullName = uevrUtils.getFullName(actor)  -- returns complete object path
			
	uevrUtils.isGamePaused() - returns whether the game is currently paused
		example:
			if uevrUtils.isGamePaused() then
				print("Game is paused")
			end
			
	uevrUtils.isFadeHardLocked() - returns whether the camera fade is currently hard locked
		example:
			if uevrUtils.isFadeHardLocked() then
				uevrUtils.stopFadeCamera()
			end
			
	uevrUtils.stopFadeCamera() - stops any active camera fade effect and removes fade locks
		example:
			uevrUtils.stopFadeCamera()  -- immediately removes any camera fade
			
	uevrUtils.enableCameraLerp(state, pitch, yaw, roll) - enables/disables camera lerping for specified axes
		example:
			uevrUtils.enableCameraLerp(true, true, true, false)  -- enable lerp for pitch and yaw only
			
	uevrUtils.enableUIFollowsView(state) - enables/disables UI following the view direction
		example:
			uevrUtils.enableUIFollowsView(true)  -- UI will follow player's view
			
	uevrUtils.setUIFollowsViewOffset(offset) - sets the offset position for UI following view
		example:
			uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=100})  -- offset UI 100 units forward
			
	uevrUtils.setUIFollowsViewSize(size) - sets the scale of UI when following view
		example:
			uevrUtils.setUIFollowsViewSize(1.5)  -- make UI 1.5x normal size
			
	uevrUtils.isThumbpadTouched(state, hand) - checks if the thumbpad is being touched for specified hand
		example:
			if uevrUtils.isThumbpadTouched(state, Handed.Right) then
				print("Right thumbpad touched")
			end
			
	uevrUtils.triggerHapticVibration(hand, secondsFromNow, duration, frequency, amplitude) - triggers controller haptic feedback
		example:
			uevrUtils.triggerHapticVibration(Handed.Left, 0, 0.1, 1000, 1.0)  -- immediate short vibration
			
	uevrUtils.getUEVRParam_bool(paramName) - gets a boolean UEVR parameter value
		example:
			local isEnabled = uevrUtils.getUEVRParam_bool("VR_EnableFeature")
			
	uevrUtils.getUEVRParam_int(paramName, default) - gets an integer UEVR parameter value with optional default
		example:
			local value = uevrUtils.getUEVRParam_int("VR_Quality", 2)
			
	uevrUtils.PositiveIntegerMask(text) - filters text to only allow positive integers and minus sign
		example:
			local number = uevrUtils.PositiveIntegerMask("abc123def-456")  -- returns "123-456"
			
	uevrUtils.splitStr(inputstr, sep) - splits a string by a separator into a table
		example:
			local parts = uevrUtils.splitStr("a,b,c", ",")  -- returns {"a", "b", "c"}
			
	uevrUtils.intToHexString(num) - converts an integer to "#RRGGBBAA" color format
		example:
			local hex = uevrUtils.intToHexString(0xFF0000FF)  -- returns "#FF0000FF"
	
	uevrUtils.getChildComponent(parent, name) - gets a child component of a given parent component (from AttachChildren param) using partial name
		example:
			local referenceGlove = uevrUtils.getChildComponent(pawn.Mesh, "Gloves")
	
	uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, (optional)options) - creates a skeletal mesh component (PoseableMeshComponent) that can be 
		manually manipulated and is a copy of the passed in skeletalMeshComponent. If parent is provided then parent is used as the component's actor rather 
		than create a new actor
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
			showDebug(bool)
			useDefaultPose(bool) - By default the function will take the current bone transforms of the source skeletalmeshcomponent and apply them 
				to the poseablemeshcomponent. For example if your source is gripping a gun then the copy will also be gripping. 
				If you do not want this and just want the default skeleton then set options.useDefaultPose to true

		example:
			poseableComponent = uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, {showDebug=false})
	
	uevrUtils.createSkeletalMeshComponent(meshName, (optional)options) - creates a skeletal mesh component and assigns a mesh to it with the given name. 
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
		Can use short name. If parent is provided then parent is used as the component's actor rather than create a new actor
		example:
			local component = uevrUtils.createSkeletalMeshComponent(wand.SK_Wand.SkeletalMesh:get_full_name(), {parent=wand})	

	uevrUtils.createStaticMeshComponent(mesh, (optional)options) - creates a static mesh component and assigns a mesh to it.
		The mesh param can be a StaticMesh object or the class name of a static mesh. Can use short name
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
		example:
			local rightComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			local rightComponent = uevrUtils.createStaticMeshComponent("Sphere") --beware of duplicate short names
			local rightComponent = uevrUtils.createStaticMeshComponent(mesh)

	uevrUtils.createWidgetComponent(widget, (optional)options) - creates a widget component and assigns a widget to it
		The widget param can be a widget class name or an actual widget object
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
			removeFromViewport(bool)
			twoSided(bool)
			drawSize(Vector2D)
		example:
			local hudComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=true, twoSided=true, drawSize=vector_2(620, 75)})	
			local hudComponent = uevrUtils.createWidgetComponent("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C", {removeFromViewport=true, twoSided=true, drawSize=vector_2(100, 100)})	
	
	uevrUtils.setWidgetLayout(widget, scale, alignment) - sets the layout of a widget, including scale and alignment in the viewport
		scale and alignment are Vector2D structs representing normalized values (0.0 to 1.0) for scale and (-1.0 to 1.0) for alignment
		example:
			uevrUtils.setWidgetLayout(myWidget, uevrUtils.vector2D(0.5, 0.5), uevrUtils.vector2D(0.5, 0.5))
	
	uevrUtils.fixMeshFOV(mesh, propertyName, value, (optional)includeChildren, (optional)includeNiagara, (optional)showDebug) --Removes the FOV distortions that 
		many flat FPS games apply to player and weapon meshes using ScalarParameterValues
		example:
			uevrUtils.fixMeshFOV(hands.getHandComponent(0), "UsePanini", 0.0, true, true, true)

	uevrUtils.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance) - performs a line trace from origin in direction and returns hit location
		example:
			local hitLocation = uevrUtils.getTargetLocation(startPos, forwardVec, 0, {}, false, 10)
			
	uevrUtils.getLineTraceHitResult(originPosition, originDirection, collisionChannel, traceComplex, ignoreActors, minHitDistance, maxTraceDistance, includeFullDetails) - performs a line trace from origin in direction and returns detailed hit result information
		example:
			local hitResult = uevrUtils.getLineTraceHitResult(startPos, forwardVec, 0, false, {}, 10, 1000, true)
			
	uevrUtils.getArrayRange(arr, startIndex, endIndex) - returns a subset of an array from startIndex to endIndex (1-based indexing)
		example:
			local subset = uevrUtils.getArrayRange(myArray, 2, 5)  -- gets elements 2-5
			
	uevrUtils.wrapTextOnWordBoundary(text, maxCharsPerLine) - wraps text to specified line length while preserving word boundaries
		example:
			local wrapped = uevrUtils.wrapTextOnWordBoundary("This is a long line", 10)
			
	uevrUtils.parseHierarchyString(str) - parses a hierarchy string like "Pawn.Mesh(Arm).Glove" into traversable node structure
		example:
			local node = uevrUtils.parseHierarchyString("Pawn.Mesh(Arm).Glove")
			
	uevrUtils.getObjectFromHierarchy(node, object, showDebug) - traverses object hierarchy using parsed node structure
		example:
			local result = uevrUtils.getObjectFromHierarchy(node, pawn, true)
			
	uevrUtils.getObjectFromDescriptor(descriptor, showDebug) - gets object using hierarchy descriptor string
		example:
			local glove = uevrUtils.getObjectFromDescriptor("Pawn.Mesh(Arm).Glove", false)
			
	uevrUtils.getControllerIndex(controllerID) - gets VR controller index (0=left, 1=right, 2=HMD)
		example:
			local leftIndex = uevrUtils.getControllerIndex(0)
			
	uevrUtils.get_local_pawn() - returns the local player pawn
		example:
			local pawn = uevrUtils.get_local_pawn()
			
	uevrUtils.get_player_controller() - returns the local player controller
		example:
			local controller = uevrUtils.get_player_controller()
			
	uevrUtils.log_info(message) - logs message to log.txt file
		example:
			uevrUtils.log_info("Custom log message")
			
	uevrUtils.GetInstanceMatching(class_to_search, match_string) - finds first instance of class that contains match_string in its full name
		example:
			local instance = uevrUtils.GetInstanceMatching("Class /Script/Engine.StaticMesh", "Sphere")


	uevrUtils.registerOnInputGetStateCallback(func) - registers a callback for input state changes
		func receives (retval, user_index, state) parameters
		example:
			uevrUtils.registerOnInputGetStateCallback(function(retval, user_index, state)
				print("Input state changed for user", user_index)
			end)
			
	uevrUtils.registerPreEngineTickCallback(func) - registers a callback before each engine tick
		func receives (engine, delta) parameters
		example:
			uevrUtils.registerPreEngineTickCallback(function(engine, delta)
				print("Pre-tick with delta:", delta)
			end)
			
	uevrUtils.registerPostEngineTickCallback(func) - registers a callback after each engine tick
		func receives (engine, delta) parameters
		example:
			uevrUtils.registerPostEngineTickCallback(function(engine, delta)
				print("Post-tick with delta:", delta) 
			end)
			
	uevrUtils.registerPreCalculateStereoViewCallback(func) - registers a callback before stereo view calculations
		func receives (device, view_index, world_to_meters, position, rotation, is_double) parameters
		example:
			uevrUtils.registerPreCalculateStereoViewCallback(function(device, view_index, ...)
				print("Pre-calculate stereo view for device", device)
			end)
			
	uevrUtils.registerPostCalculateStereoViewCallback(func) - registers a callback after stereo view calculations
		func receives (device, view_index, world_to_meters, position, rotation, is_double) parameters
		example:
			uevrUtils.registerPostCalculateStereoViewCallback(function(device, view_index, ...)
				print("Post-calculate stereo view for device", device)
			end)
			
	uevrUtils.registerLevelChangeCallback(func) - registers a callback for when the game level changes
		func receives the new level name
		example:
			uevrUtils.registerLevelChangeCallback(function(levelName)
				print("Level changed to:", levelName)
			end)
			
	uevrUtils.registerPreLevelChangeCallback(func) - registers a callback before the game level changes
		func receives the new level name
		example:
			uevrUtils.registerPreLevelChangeCallback(function(levelName)
				print("Level about to change to:", levelName)
			end)
			
	uevrUtils.registerGamePausedCallback(func) - registers a callback for when the game is paused/unpaused 
		func receives a boolean indicating pause state
		example:
			uevrUtils.registerGamePausedCallback(function(isPaused)
				print("Game paused:", isPaused)
			end)
			
	uevrUtils.registerUEVRUIChangeCallback(func, priority) - registers a callback for when the UEVR UI visibility state changes
		func receives a boolean indicating whether the UEVR UI is visible
		priority is optional (higher numbers execute first)
		example:
			uevrUtils.registerUEVRUIChangeCallback(function(isUIVisible)
				print("UEVR UI visible:", isUIVisible)
			end)
	

	hook_function(class_name, function_name, native, prefn, postfn, dbgout)	- a method of getting a function callback from the game engine
		example:
			hook_function("BlueprintGeneratedClass /Game/Blueprints/Player/IndianaPlayerCharacter_BP.IndianaPlayerCharacter_BP_C", "PlayerCinematicChange", false, 
				function(fn, obj, locals, result)
					print("IndianaPlayerCharacter PlayerCinematicChange")
					isInCinematic = locals.bCinematicMode
					return true
				end
			, nil, true)

	register_key_bind(keyName, callbackFunc) - registers a callback function that will be triggered when a key is pressed
		example:
			register_key_bind("F1", function()
				print("F1 pressed\n")
			end)
			register_key_bind("LeftMouseButton", function()
				print("Left mouse button pressed\n")
			end)

		keyName list:
			# Keyboard
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


	spliceableInlineArray, expandArray - is a utility that enables declarative construction 
		of Lua arrays by allowing inline expansion of multiple return values such as those from functions 
		or generators at arbitrary positions within a table. This circumvents Lua’s native limitation 
		where multiple return values are only expanded in the final position of a table constructor.
		example:
			local function getWidgets()
				return { {type="button"}, {type="slider"}, {type="checkbox"} }
			end
			local ui = spliceableInlineArray {
				{type="label"},
				expandArray(getWidgets),
				{type="footer"}
			}


	Callbacks:	
		The following functions can be added to you main script. They are optional and will only be called if you add them
		
		--callback for uevr.sdk.callbacks.on_xinput_get_state
		function on_xinput_get_state(retval, user_index, state)
		end

		--callback for on_pre_calculate_stereo_view_offset
		function on_pre_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end

		--callback for on_post_calculate_stereo_view_offset
		function on_post_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end
		
		--callback for uevr.sdk.callbacks.on_pre_engine_tick
		function on_pre_engine_tick(engine, delta)
		end

		--callback for uevr.sdk.callbacks.on_post_engine_tick
		function on_post_engine_tick(engine, delta)
		end

		-- function that gets called once per second for things you want to do at a slower interval than every tick
		function on_lazy_poll()
		end

		-- function that gets called when the level changes
		function on_level_change(level, levelName)
		end

		-- function that gets called when the client restarts or changes pawns
		-- When the playerController changes pawns (e.g. respawn, death, entering a controllable vehicle), this function is called.
		-- In your code just add a callback like this:
		-- function on_client_restart(newPawn)
		-- 		uevrUtils.print("Pawn changed to " .. newPawn:get_full_name())
		-- end
		function on_client_restart(newPawn)
		end

		-- function that gets called when this library has finished initializing
		function UEVRReady(instance)
		end
	

		UEVR lifecycle
			Pre engine
			Early Stereo --one eye
			Pre Stereo --one eye
			Post Stereo --one eye
			Early Stereo --other eye
			Pre Stereo --other eye
			Post Stereo --other eye
			Post engine

]]--

require("libs/enums/unreal")
-------------------------------
-- Globals
--  These exist for backwards compatability with existing scripts 
--  The functions in this library provide better ways than using these globals
---@class temp_vec3
---@field [any] any
temp_vec3 = nil
---@class temp_vec3f
---@field [any] any
temp_vec3f = nil
---@class temp_quatf
---@field [any] any
temp_quatf = nil

---@class reusable_hit_result
---@field [any] any
reusable_hit_result = nil
temp_transform = nil
zero_color = nil

---@class game_engine
---@field [any] any
game_engine = nil

static_mesh_component_c = nil
motion_controller_component_c = nil
scene_component_c = nil
actor_c = nil

-- These are useful as is
---@class pawn
---@field [any] any
pawn = nil -- updated every tick 
---@class Statics
---@field [any] any
Statics = nil
WidgetBlueprintLibrary = nil
WidgetLayoutLibrary = nil
---@class kismet_system_library
---@field [any] any
kismet_system_library = nil
---@class kismet_math_library
---@field [any] any
kismet_math_library = nil
---@class kismet_string_library
---@field [any] any
kismet_string_library = nil
---@class kismet_rendering_library
---@field [any] any
kismet_rendering_library = nil
--uevr = nil
-------------------------------
-- global enums
LogLevel = {
    Off = 0,
    Critical = 1,
    Error = 2,
    Warning = 3,
    Info = 4,
    Debug = 5,
    Trace = 6,
    Ignore = 99,
}

LogLevelString = {[0]="off",[1]="crit",[2]="error",[3]="warn",[4]="info",[5]="debug",[6]="trace",[99]="ignore"}

Handed = {
	Left = 0,
	Right = 1
}

KeyName = {
	-- Mouse buttons
	LeftMouseButton = "LeftMouseButton",
	RightMouseButton = "RightMouseButton",
	MiddleMouseButton = "MiddleMouseButton",
	ThumbMouseButton = "ThumbMouseButton",
	ThumbMouseButton2 = "ThumbMouseButton2",

	-- Mouse axes
	MouseX = "MouseX",
	MouseY = "MouseY",
	MouseScrollUp = "MouseScrollUp",
	MouseScrollDown = "MouseScrollDown",
	MouseWheelSpin = "MouseWheelSpin",

	-- Letters
	A = "A", B = "B", C = "C", D = "D", E = "E", F = "F", G = "G", H = "H", I = "I", J = "J",
	K = "K", L = "L", M = "M", N = "N", O = "O", P = "P", Q = "Q", R = "R", S = "S", T = "T",
	U = "U", V = "V", W = "W", X = "X", Y = "Y", Z = "Z",

	-- Numbers (above alphabet)
	Zero = "Zero", One = "One", Two = "Two", Three = "Three", Four = "Four",
	Five = "Five", Six = "Six", Seven = "Seven", Eight = "Eight", Nine = "Nine",

	-- Arrow keys
	Left = "Left", Up = "Up", Right = "Right", Down = "Down",

	-- NumPad
	NumPadZero = "NumPadZero", NumPadOne = "NumPadOne", NumPadTwo = "NumPadTwo", NumPadThree = "NumPadThree",
	NumPadFour = "NumPadFour", NumPadFive = "NumPadFive", NumPadSix = "NumPadSix", NumPadSeven = "NumPadSeven",
	NumPadEight = "NumPadEight", NumPadNine = "NumPadNine",

	-- NumPad operators
	Multiply = "Multiply", Add = "Add", Subtract = "Subtract", Decimal = "Decimal", Divide = "Divide",

	-- Control keys
	BackSpace = "BackSpace", Tab = "Tab", Enter = "Enter", Pause = "Pause", NumLock = "NumLock",
	ScrollLock = "ScrollLock", CapsLock = "CapsLock", Escape = "Escape", SpaceBar = "SpaceBar",
	PageUp = "PageUp", PageDown = "PageDown", End = "End", Home = "Home", Insert = "Insert", Delete = "Delete",

	-- Function keys
	F1 = "F1", F2 = "F2", F3 = "F3", F4 = "F4", F5 = "F5", F6 = "F6",
	F7 = "F7", F8 = "F8", F9 = "F9", F10 = "F10", F11 = "F11", F12 = "F12",

	-- Modifier keys
	LeftShift = "LeftShift", RightShift = "RightShift", LeftControl = "LeftControl", RightControl = "RightControl",
	LeftAlt = "LeftAlt", RightAlt = "RightAlt", LeftCommand = "LeftCommand", RightCommand = "RightCommand",

	-- Symbols
	Semicolon = "Semicolon", Equals = "Equals", Comma = "Comma", Underscore = "Underscore",
	Period = "Period", Slash = "Slash", Tilde = "Tilde", LeftBracket = "LeftBracket",
	Backslash = "Backslash", RightBracket = "RightBracket", Quote = "Quote",

	-- Gamepad analog sticks
	Gamepad_LeftX = "Gamepad_LeftX", Gamepad_LeftY = "Gamepad_LeftY",
	Gamepad_RightX = "Gamepad_RightX", Gamepad_RightY = "Gamepad_RightY",

	-- Gamepad triggers
	Gamepad_LeftTriggerAxis = "Gamepad_LeftTriggerAxis", Gamepad_RightTriggerAxis = "Gamepad_RightTriggerAxis",

	-- Gamepad stick buttons
	Gamepad_LeftThumbstick = "Gamepad_LeftThumbstick", Gamepad_RightThumbstick = "Gamepad_RightThumbstick",

	-- Gamepad special buttons
	Gamepad_Special_Left = "Gamepad_Special_Left", Gamepad_Special_Right = "Gamepad_Special_Right",

	-- Gamepad face buttons
	Gamepad_FaceButton_Bottom = "Gamepad_FaceButton_Bottom", Gamepad_FaceButton_Right = "Gamepad_FaceButton_Right",
	Gamepad_FaceButton_Left = "Gamepad_FaceButton_Left", Gamepad_FaceButton_Top = "Gamepad_FaceButton_Top",

	-- Gamepad shoulder buttons
	Gamepad_LeftShoulder = "Gamepad_LeftShoulder", Gamepad_RightShoulder = "Gamepad_RightShoulder",
	Gamepad_LeftTrigger = "Gamepad_LeftTrigger", Gamepad_RightTrigger = "Gamepad_RightTrigger",

	-- Gamepad D-Pad
	Gamepad_DPad_Up = "Gamepad_DPad_Up", Gamepad_DPad_Down = "Gamepad_DPad_Down",
	Gamepad_DPad_Right = "Gamepad_DPad_Right", Gamepad_DPad_Left = "Gamepad_DPad_Left",

	-- Gamepad virtual stick directions
	Gamepad_LeftStick_Up = "Gamepad_LeftStick_Up", Gamepad_LeftStick_Down = "Gamepad_LeftStick_Down",
	Gamepad_LeftStick_Right = "Gamepad_LeftStick_Right", Gamepad_LeftStick_Left = "Gamepad_LeftStick_Left",
	Gamepad_RightStick_Up = "Gamepad_RightStick_Up", Gamepad_RightStick_Down = "Gamepad_RightStick_Down",
	Gamepad_RightStick_Right = "Gamepad_RightStick_Right", Gamepad_RightStick_Left = "Gamepad_RightStick_Left",

	-- Touch device motion
	Tilt = "Tilt", RotationRate = "RotationRate", Gravity = "Gravity", Acceleration = "Acceleration",

	-- Touch device gestures
	Gesture_SwipeLeftRight = "Gesture_SwipeLeftRight", Gesture_SwipeUpDown = "Gesture_SwipeUpDown",
	Gesture_TwoFingerSwipeLeftRight = "Gesture_TwoFingerSwipeLeftRight", Gesture_TwoFingerSwipeUpDown = "Gesture_TwoFingerSwipeUpDown",
	Gesture_Pinch = "Gesture_Pinch", Gesture_Flick = "Gesture_Flick",

	-- Special
	PS4_Special = "PS4_Special"
}
-------------------------------
local coreLerp = require("libs/core/lerp")

local M = {}

local classCache = {}
local structCache = {}
local uevrCallbacks = {}
local keyBindList = {}
local usingLuaVR = false
local isPaused = false
local isInCutscene = false
local isCharacterHidden = false
local isDeveloperMode = nil
local handedness = Handed.Right --a way to track handedness in a unified way


function register_key_bind(keyName, callbackFunc)
	keyBindList[keyName] = {}
	keyBindList[keyName].func = callbackFunc
	keyBindList[keyName].isPressed = false
	print("Registered key bind for ", keyName)
end

function unregister_key_bind(keyName)
	keyBindList[keyName] = nil
	print("Unregistered key bind for ", keyName)
end

local function updateKeyPress()
	local pc = nil
	local keyStruct = nil
	for key, elem in pairs(keyBindList) do
		if pc == nil then pc = uevr.api:get_player_controller(0) end -- dont allocate until we know its needed
		if keyStruct == nil then keyStruct = M.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key") end
		keyStruct.KeyName = M.fname_from_string(key)
		if pc:IsInputKeyDown(keyStruct) then
			if elem.isPressed == false then
				elem.func()
				elem.isPressed = true
			end
		else
			elem.isPressed = false
		end
		-- although these return analog states it's always 0.0 or 1.0
		-- print(pc:GetInputAnalogKeyState(keyStruct))
		-- local vector = pc:GetInputVectorKeyState(keyStruct)
		-- print("Vector state:", vector.X, vector.Y, vector.Z)
	end
end

local delayList = {}
function setTimeout(msec, func)
	table.insert(delayList, {countDown = msec/1000, func = func})
end
function M.setTimeout(msec, func)
	setTimeout(msec, func)
end
function delay(msec, func)
	setTimeout(msec, func)
end
function M.delay(msec, func)
	setTimeout(msec, func)
end

local function updateDelay(delta)
	for i = #delayList, 1, -1 do
		delayList[i]["countDown"] = delayList[i]["countDown"] - delta
		if delayList[i]["countDown"] < 0 then
			if delayList[i]["func"] ~= nil then
				delayList[i]["func"]()
			end
			table.remove(delayList, i)
		end
	end
end

local timerList = {}
function setInterval(msec, func)
	local id = M.guid()
	table.insert(timerList, {id = id,period = msec/1000, countDown = msec/1000, func = func})
	return id
end
function M.setInterval(msec, func)
	return setInterval(msec, func)
end
function M.clearInterval(id)
	for i = #timerList, 1, -1 do
		if timerList[i].id == id then
			table.remove(timerList, i)
			break
		end
	end
end

local function updateTimer(delta)
	for i = #timerList, 1, -1 do
		timerList[i]["countDown"] = timerList[i]["countDown"] - delta
		if timerList[i]["countDown"] < 0 then
			if timerList[i]["func"] ~= nil then
				timerList[i]["func"]()
			end
			timerList[i]["countDown"] = timerList[i]["countDown"] + timerList[i]["period"]
		end
	end
end

-- Named deferral system with auto-reset functionality
local namedDeferrals = {}

local function validateDeferralName(name, funcName)
	if not name or type(name) ~= "string" then
		M.print(funcName .. ": invalid deferral name", LogLevel.Error)
		return false
	end
	return true
end

local function getDeferral(name, funcName)
	if not validateDeferralName(name, funcName) then return nil end

	local deferral = namedDeferrals[name]
	if not deferral then
		M.print(funcName .. ": deferral '" .. name .. "' does not exist", LogLevel.Error)
		return nil
	end
	return deferral
end

function M.createDeferral(name, timeoutMs, callback)
	if not validateDeferralName(name, "createDeferral") then return false end
	if not timeoutMs or type(timeoutMs) ~= "number" or timeoutMs <= 0 then
		M.print("createDeferral: invalid timeout value", LogLevel.Error)
		return false
	end

	namedDeferrals[name] = {
		isLocked = false,  -- Deferral starts inactive
		timeout = timeoutMs / 1000,  -- convert to seconds
		countdown = timeoutMs / 1000,
		callback = callback
	}

	M.print("Created deferral '" .. name .. "' with " .. timeoutMs .. "ms timeout", LogLevel.Debug)
	return true
end

function M.updateDeferral(name)
	local deferral = getDeferral(name, "updateDeferral")
	if not deferral then return false end

	-- Activate the deferral
	deferral.isLocked = true
	deferral.countdown = deferral.timeout  -- Reset countdown to full timeout

	--M.print("Deferral '" .. name .. "' activated", LogLevel.Debug)
	return true
end

function M.destroyDeferral(name)
	if not validateDeferralName(name, "destroyDeferral") then return false end

	if namedDeferrals[name] then
		namedDeferrals[name] = nil
		M.print("Deferral '" .. name .. "' destroyed", LogLevel.Debug)
		return true
	end

	return false
end

local function updateDeferrals(delta)
	for name, deferral in pairs(namedDeferrals) do
		if deferral.isLocked then  -- Only update active deferrals
			deferral.countdown = deferral.countdown - delta

			if deferral.countdown <= 0 then
				deferral.isLocked = false
				deferral.countdown = 0

				if deferral.callback then
					local success, err = pcall(deferral.callback)
					if not success then
						M.print("Deferral '" .. name .. "' callback error: " .. tostring(err), LogLevel.Error)
					end
				end

				--M.print("Deferral '" .. name .. "' expired", LogLevel.Debug)
			end
		end
	end
end

local lerpList = {}
function M.lerp(lerpID, startAlpha, endAlpha, duration, userdata, callback)
	if lerpList[lerpID] ~= nil then
		lerpList[lerpID]:update(startAlpha, endAlpha, duration, userdata)
	else
		local lerp = coreLerp.new(startAlpha, endAlpha, duration, userdata, callback)
		lerp:start()
		lerpList[lerpID] = lerp
		--print("Created lerp\n")
	end
end
local function updateLerp(delta)
	local cleanup = {}
	for id, lerp in pairs(lerpList) do
		lerp:tick(delta)
		if lerp:isFinished() then table.insert(cleanup, id) end
	end
	for i = 1, #cleanup do
		lerpList[cleanup[i]] = nil
		--print("Deleted lerp\n")
	end
end
function M.cancelLerp(lerpID)
	lerpList[lerpID] = nil
end

-- Do Once 
Once = {
    EVER = 0,
    PER_LEVEL = 1
}

local perLevelDoOnceRegistry = {}
function doOnce(func, scopeType)
    local hasRun = false
    local succeeded = false

    local obj = {
        scopeType = scopeType or Once.EVER
    }

    -- function obj:run()
        -- if not hasRun then
            -- hasRun = true
            -- func()
        -- end
    -- end

   function obj:run()
        if not hasRun or not succeeded then
            hasRun = true
            local ok, result = pcall(func)

            if not ok then
                -- Failure detected, reset so we can try again later
                hasRun = false
                succeeded = false
            else
                succeeded = true
            end
            return result
        end
    end

    function obj:reset()
        hasRun = false
        succeeded = false
    end

    setmetatable(obj, {
        __call = function(self)
            self:run()
        end
    })


    -- Register with external scope tracker if needed
    if obj.scopeType == Once.PER_LEVEL then
        table.insert(perLevelDoOnceRegistry, obj)
    end

    return obj
end

local function resetPerLevelDoOnce()
    for _, obj in ipairs(perLevelDoOnceRegistry) do
        obj:reset()
    end
end

function M.doOnce(func, scopeType)
	return doOnce(func, scopeType)
end
-- end Do Once

-- function delay(seconds, func)
  -- local co = coroutine.create(function()
    -- local start = os.time()
    -- while os.time() - start < seconds do
      -- coroutine.yield()
    -- end
    -- func()
  -- end)

  -- while coroutine.status(co) ~= "dead" do
    -- coroutine.resume(co)
  -- end
-- end

local lazyElapsedTime = 0.0
local lazyPollTime = 1.0
local function updateLazyPoll(delta)
	if on_lazy_poll ~= nil then --don't bother doing anything if nothing is listening
		lazyElapsedTime = lazyElapsedTime + delta
		if lazyElapsedTime > lazyPollTime then
			on_lazy_poll()
			lazyElapsedTime = 0
		end
	end
end

local function registerUEVRCallback(callbackName, callbackFunc, priority)
	if priority == nil then priority = 0 end
	if uevrCallbacks[callbackName] == nil then uevrCallbacks[callbackName] = {} end

	for i, existingEntry in ipairs(uevrCallbacks[callbackName]) do
		if existingEntry.func == callbackFunc then
			--print("Function already exists")
			return
		end
	end

	table.insert(uevrCallbacks[callbackName], {func = callbackFunc, priority = priority})
	-- Sort by priority (highest priority first)
	table.sort(uevrCallbacks[callbackName], function(a, b)
		return a.priority > b.priority
	end)
end

function M.registerUEVRCallback(callbackName, callbackFunc, priority)
	registerUEVRCallback(callbackName, callbackFunc, priority)
end

--note that only the last result will be returned for functions that return results
--therefore, for function returning results, only one callback should be 
--registered system wide or use executeUEVRCallbacksWithBooleanResult
local function executeUEVRCallbacks(callbackName, ...)
	if uevrCallbacks[callbackName] ~= nil then
		local lastResults = nil
		for i, entry in ipairs(uevrCallbacks[callbackName]) do
			local results = {entry.func(table.unpack({...}))}
			if #results > 0 then
				lastResults = results
			end
		end
		if lastResults then
			return table.unpack(lastResults)
		end
	end
end

local function executeUEVRCallbacksWithBooleanResult(callbackName, ...)
	local result = nil
	if uevrCallbacks[callbackName] ~= nil then
		for i, entry in ipairs(uevrCallbacks[callbackName]) do
			local funcResult = entry.func(table.unpack({...}))
			if funcResult ~= nil then
				result = result or funcResult
			end
		end
	end
	return result
end

local function executeUEVRCallbacksWithPriorityBooleanResult(callbackName, ...)
	local result = nil
	local priority = 0
	if uevrCallbacks[callbackName] ~= nil then
		for i, entry in ipairs(uevrCallbacks[callbackName]) do
			local funcResult, funcPriority = entry.func(table.unpack({...}))
			if funcPriority == nil then funcPriority = 0 end
			if funcResult ~= nil and funcPriority >= priority then
				result = result or funcResult
				priority = funcPriority
			end
		end
	end
	return result, priority
end

-- local function executeUEVRCallbacks(callbackName, ...)
-- 	if uevrCallbacks[callbackName] ~= nil then
-- 		for i, func in ipairs(uevrCallbacks[callbackName]) do
-- 			func(table.unpack({...}))
-- 		end
-- 	end
-- end

function M.executeUEVRCallbacks(callbackName, ...)
	return executeUEVRCallbacks(callbackName, ...)
end

function M.executeUEVRCallbacksWithBooleanResult(callbackName, ...)
	return executeUEVRCallbacksWithBooleanResult(callbackName, ...)
end

function M.executeUEVRCallbacksWithPriorityBooleanResult(callbackName, ...)
	return executeUEVRCallbacksWithPriorityBooleanResult(callbackName, ...)
end

local function hasUEVRCallbacks(callbackName)
	if uevrCallbacks[callbackName] ~= nil then
		return true
	end
	return false
end
function M.hasUEVRCallbacks(callbackName)
	return hasUEVRCallbacks(callbackName)
end

local function getCurrentLevel()
	local world = M.get_world()
	if world ~= nil then
		return world.PersistentLevel
	end
	return nil
end

local lastLevel = nil
local function updateCurrentLevel()
	if on_level_change ~= nil or hasUEVRCallbacks("on_pre_level_change") or hasUEVRCallbacks("on_level_change") then --don't bother doing anything if nothing is listening
		local level = getCurrentLevel()
		if level ~= nil and lastLevel ~= level then
			resetPerLevelDoOnce()

			local levelName = M.getShortName(level:get_outer())
			executeUEVRCallbacks("on_pre_level_change", level, levelName)

			if on_level_change ~= nil then
				on_level_change(level, levelName)
			end

			executeUEVRCallbacks("on_level_change", level, levelName)
		end
		lastLevel = level
	end
end

local function updateGamePaused()
	if on_game_paused ~= nil or hasUEVRCallbacks("on_game_paused") then --don't bother doing anything if nothing is listening
		local m_isPaused = false
		local world = M.get_world()
		if world ~= nil then
			m_isPaused = Statics:IsGamePaused(world)
		end
		if isPaused ~= m_isPaused then
			if on_game_paused ~= nil then
				on_game_paused(m_isPaused)
			end
			executeUEVRCallbacks("on_game_paused", m_isPaused)
		end
		isPaused = m_isPaused
	end
end

local function updateCharacterHidden()
	if on_character_hidden ~= nil or hasUEVRCallbacks("on_character_hidden") then --don't bother doing anything if nothing is listening
		local m_isHidden = M.getValid(pawn, {"Controller", "Character", "bHidden"}) or false
		if isCharacterHidden ~= m_isHidden then
			if on_character_hidden ~= nil then
				on_character_hidden(m_isHidden)
			end
			executeUEVRCallbacks("on_character_hidden", m_isHidden)
		end
---@diagnostic disable-next-line: cast-local-type
		isCharacterHidden = m_isHidden
	end
end

local function updateCutscene()
	if on_cutscene_change ~= nil or hasUEVRCallbacks("on_cutscene_change") then --don't bother doing anything if nothing is listening
		if M.getValid(pawn) ~= nil then
			local playerController = pawn.Controller
			if playerController ~= nil then
				local cameraManager = playerController.PlayerCameraManager
				if cameraManager ~= nil then
					local target = cameraManager.ViewTarget.Target
--print(target:get_class():get_full_name())
					local m_isInCutscene = false
					if target ~= nil then
						if target:is_a(M.get_class("Class /Script/CinematicCamera.CineCameraActor")) then
							m_isInCutscene = true
							--print("In Cinematic")
						elseif target.ActiveCamera ~= nil and target.ActiveCamera.Camera ~= nil and target.ActiveCamera.Camera:is_a(M.get_class("Class /Script/CinematicCamera.CineCameraComponent")) then
							m_isInCutscene = true
							--print("In Cinematic")
						end
					end

					if isInCutscene ~= m_isInCutscene then
						if on_cutscene_change ~= nil then
							on_cutscene_change(m_isInCutscene)
						end
						executeUEVRCallbacks("on_cutscene_change", m_isInCutscene)
					end
					isInCutscene = m_isInCutscene
				end
			end
		end
	end
end

local currentMontage = nil
local function updateMontage()
	if on_montage_change ~= nil or hasUEVRCallbacks("on_montage_change") then --don't bother doing anything if nothing is listening
		if M.getValid(pawn) ~= nil and pawn.GetCurrentMontage ~= nil then
			local montage = pawn:GetCurrentMontage()
			if currentMontage ~= montage then
				local montageName = montage and M.getShortName(montage) or ""
				if on_montage_change ~= nil then
					on_montage_change(montage, montageName)
				end
				executeUEVRCallbacks("on_montage_change", montage, montageName)
			end
			currentMontage = montage
		end
	end
end

--courtesy of Rusty Gere
local currentUEVRDrawn = nil
local function updateUEVRUIState()
	if on_uevr_ui_change ~= nil or hasUEVRCallbacks("on_uevr_ui_change") then --don't bother doing anything if nothing is listening
		local uiDrawn = uevr.params.functions.is_drawing_ui()
		if currentUEVRDrawn ~= uiDrawn then
			if on_uevr_ui_change ~= nil then
				on_uevr_ui_change(uiDrawn)
			end
			executeUEVRCallbacks("on_uevr_ui_change", uiDrawn)
		end
		currentUEVRDrawn = uiDrawn
	end
end


local isInitialized = false
function M.initUEVR(UEVR, callbackFunc)
	if isInitialized == true then
		if callbackFunc ~= nil then
			callbackFunc()
		end
		return
	end
	isInitialized = true

	if UEVR == nil then
		UEVR = require("LuaVR")
		usingLuaVR = true
	end

	uevr = UEVR
	local params = uevr.params
	M.print("UEVR loaded " .. tostring(params.version.major) .. "." .. tostring(params.version.minor) .. "." .. tostring(params.version.patch))

	pawn = uevr.api:get_local_pawn(0)

	temp_vec3 = Vector3d.new(0, 0, 0)
	temp_vec3f = Vector3f.new(0, 0, 0)
	temp_quatf = Quaternionf.new(0, 0, 0, 0)

	kismet_system_library = M.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
	kismet_math_library = M.find_default_instance("Class /Script/Engine.KismetMathLibrary")
	kismet_string_library = M.find_default_instance("Class /Script/Engine.KismetStringLibrary")
	kismet_rendering_library = M.find_default_instance("Class /Script/Engine.KismetRenderingLibrary")
	Statics = M.find_default_instance("Class /Script/Engine.GameplayStatics")
	WidgetBlueprintLibrary = M.find_default_instance("Class /Script/UMG.WidgetBlueprintLibrary")
    WidgetLayoutLibrary = M.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary")
    

	game_engine = M.find_first_of("Class /Script/Engine.GameEngine")

	static_mesh_component_c = M.get_class("Class /Script/Engine.StaticMeshComponent")
	motion_controller_component_c = M.get_class("Class /Script/HeadMountedDisplay.MotionControllerComponent")
	scene_component_c = M.get_class("Class /Script/Engine.SceneComponent")
	actor_c = M.get_class("Class /Script/Engine.Actor")

	zero_color = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")
	reusable_hit_result = M.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
	temp_transform = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.Transform")

	uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
		executeUEVRCallbacks("onPreInputGetState", retval, user_index, state)

		if on_xinput_get_state ~= nil then
			on_xinput_get_state(retval, user_index, state)
		end

		executeUEVRCallbacks("onInputGetState", retval, user_index, state)

		executeUEVRCallbacks("onPostInputGetState", retval, user_index, state)
	end)

	uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
		if on_pre_calculate_stereo_view_offset ~= nil then
			on_pre_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end

		executeUEVRCallbacks("preCalculateStereoView", device, view_index, world_to_meters, position, rotation, is_double)
	end)

	uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
		local success, response = pcall(function()
			if on_post_calculate_stereo_view_offset ~= nil then
				on_post_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
			end

			executeUEVRCallbacks("postCalculateStereoView", device, view_index, world_to_meters, position, rotation, is_double)
		end)
		if success == false then
			M.print("[on_pre_engine_tick] " .. response, LogLevel.Error)
		end
	end)

	uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
		local success, response = pcall(function()
			pawn = uevr.api:get_local_pawn(0)
			updateCurrentLevel()
			updateDelay(delta)
			updateTimer(delta)
			updateDeferrals(delta)
			updateLazyPoll(delta)
			updateKeyPress()
			updateLerp(delta)
			updateGamePaused()
			updateCharacterHidden()
			updateCutscene()
			updateMontage()
			updateUEVRUIState()

			if on_pre_engine_tick ~= nil then
				on_pre_engine_tick(engine, delta)
			end

			executeUEVRCallbacks("preEngineTick", engine, delta)
		end)
		if success == false then
			M.print("[on_pre_engine_tick] " .. response, LogLevel.Error)
		end
	end)

	uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
		if on_post_engine_tick ~= nil then
			on_post_engine_tick(engine, delta)
		end

		executeUEVRCallbacks("postEngineTick", engine, delta)
	end)

	if callbackFunc ~= nil then
		callbackFunc()
	end

	-- if on_uevr_ready ~= nil or hasUEVRCallbacks("on_uevr_ready") then --don't bother doing anything if nothing is listening
	-- 	if on_uevr_ready ~= nil then
	-- 		on_uevr_ready(uevr)
	-- 	end
	-- 	executeUEVRCallbacks("on_uevr_ready", uevr)
	-- end

	if UEVRReady ~= nil then UEVRReady(uevr) end
end

local currentLogLevel = LogLevel.Error
local logToFile = false
function M.enableDebug(val)
	currentLogLevel = val and LogLevel.Debug or LogLevel.Off
end

function M.setLogLevel(val)
	currentLogLevel = val
end

function M.setLogToFile(val)
	logToFile = val
end

function M.print(str, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if type(logLevel) ~= "number" then logLevel = LogLevel.Debug end
	if type(str) == "string" then
		if logLevel <= currentLogLevel then
			print("[" .. LogLevelString[logLevel] .. "] " .. str .. (usingLuaVR and "\n" or ""))
			if logToFile then
				if logLevel == LogLevel.Error or logLevel == LogLevel.Critical then
					uevr.params.functions.log_error("[" .. LogLevelString[logLevel] .. "] " .. str)
				elseif logLevel == LogLevel.Warning then
					uevr.params.functions.log_warn("[" .. LogLevelString[logLevel] .. "] " .. str)
				else
					uevr.params.functions.log_info("[" .. LogLevelString[logLevel] .. "] " .. str)
				end
			end
		end
	else
		print("Failed to print a non-string" .. (usingLuaVR and "\n" or ""))
	end
end

function M.setDeveloperMode(val)
	isDeveloperMode = val
end

function M.getDeveloperMode()
	return isDeveloperMode
end

function M.registerOnInputGetStateCallback(func, priority)
	registerUEVRCallback("onInputGetState", func, priority)
end

function M.registerOnPreInputGetStateCallback(func, priority)
	registerUEVRCallback("onPreInputGetState", func, priority)
end

function M.registerOnPostInputGetStateCallback(func, priority)
	registerUEVRCallback("onPostInputGetState", func, priority)
end

function M.registerPreEngineTickCallback(func, priority)
	registerUEVRCallback("preEngineTick", func, priority)
end

function M.registerPostEngineTickCallback(func, priority)
	registerUEVRCallback("postEngineTick", func, priority)
end

function M.registerPreCalculateStereoViewCallback(func, priority)
	registerUEVRCallback("preCalculateStereoView", func, priority)
end

function M.registerPostCalculateStereoViewCallback(func, priority)
	registerUEVRCallback("postCalculateStereoView", func, priority)
end

function M.registerLevelChangeCallback(func, priority)
	registerUEVRCallback("on_level_change", func, priority)
end

function M.registerPreLevelChangeCallback(func, priority)
	registerUEVRCallback("on_pre_level_change", func, priority)
end

function M.registerGamePausedCallback(func, priority)
	registerUEVRCallback("on_game_paused", func, priority)
end

function M.registerCharacterHiddenCallback(func, priority)
	registerUEVRCallback("on_character_hidden", func, priority)
end

function M.registerCutsceneChangeCallback(func, priority)
	registerUEVRCallback("on_cutscene_change", func, priority)
end

function M.registerMontageChangeCallback(func, priority)
	registerUEVRCallback("on_montage_change", func, priority)
end

function M.registerHandednessChangeCallback(func, priority)
	registerUEVRCallback("handedness_change", func, priority)
end

function M.registerUEVRUIChangeCallback(func, priority)
	registerUEVRCallback("on_uevr_ui_change", func, priority)
end

function M.setHandedness(val)
	handedness = val
	M.executeUEVRCallbacks("handedness_change", val)
end

function M.getHandedness()
	return handedness
end

function M.guid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function vector_2(x, y, reuseable)
	local vector = M.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D", reuseable)
	if vector ~= nil then
		vector.X = x
		vector.Y = y
	end
	return vector
end
function M.vector_2(x, y, reuseable)
	return vector_2(x, y, reuseable)
end

function vector_3(x, y, z)
	temp_vec3:set(x, y, z)
	return temp_vec3
end
function M.vector_3(x, y, z)
	return vector_3(x, y, z)
end

function vector_3f(x, y, z)
	temp_vec3f:set(x, y, z)
	return temp_vec3f
end
function M.vector_3f(x, y, z)
	return vector_3f(x, y, z)
end

function quatf(x, y, z, w)
	temp_quatf:set(x, y, z, w)
	return temp_quatf
end
function M.quatf(x, y, z, w)
	return quatf(x, y, z, w)
end

--function M.vector(x, y, z, reuseable)
function M.vector(...)
    local arg = {...}
	local x=0.0
	local y=0.0
	local z=0.0
	local reuseable = false

	if #arg == 1 or #arg == 2 then
		if type(arg[1]) == "table" or type(arg[1]) == "userdata" then
			x = (arg[1].X ~= nil) and arg[1].X or ((arg[1].x ~= nil) and arg[1].x or ((#arg[1] > 0) and arg[1][1] or 0.0))
			y = (arg[1].Y ~= nil) and arg[1].Y or ((arg[1].y ~= nil) and arg[1].y or ((#arg[1] > 1) and arg[1][2] or 0.0))
			z = (arg[1].Z ~= nil) and arg[1].Z or ((arg[1].z ~= nil) and arg[1].z or ((#arg[1] > 2) and arg[1][3] or 0.0))
		else
			M.print("Invalid argument 1 passed to vector function", LogLevel.Warning)
		end

		if #arg == 2 then
			if type(arg[2]) == "boolean" then
				reuseable = arg[2]
			else
				M.print("Invalid argument 2 passed to vector function", LogLevel.Warning)
			end
		end
	elseif #arg == 3 or #arg == 4 then
		if type(arg[1]) == "number" then x = arg[1] else M.print("Invalid x value passed to vector function", LogLevel.Warning) end
		if type(arg[2]) == "number" then y = arg[2] else M.print("Invalid y value passed to vector function", LogLevel.Warning) end
		if type(arg[3]) == "number" then z = arg[3] else M.print("Invalid z value passed to vector function", LogLevel.Warning) end

		if #arg == 4 then
			if type(arg[4]) == "boolean" then
				reuseable = arg[4]
			else
				M.print("Invalid argument 4 passed to vector function", LogLevel.Warning)
			end
		end
	end

	local vector = M.get_struct_object("ScriptStruct /Script/CoreUObject.Vector", reuseable)
	if vector ~= nil then
		if vector["X"] ~= nil then vector.X = x else vector.x = x end
		if vector["Y"] ~= nil then vector.Y = y else vector.y = y end
		if vector["Z"] ~= nil then vector.Z = z else vector.z = z end
	end
	return vector

	--this should work but doesnt, at least in robocop
	--return kismet_math_library:MakeVector(x, y, z)

end

function M.rotator(...)
    local arg = {...}
	local pitch=0
	local yaw=0
	local roll=0
	local reuseable = false

	if #arg == 1 or #arg == 2 then
		if type(arg[1]) == "userdata" then --maybe a rotator was sent in
			--if arg[1]:is_a(M.get_class("ScriptStruct /Script/CoreUObject.Rotator")) then
			return arg[1]
		elseif type(arg[1]) == "table" then
			pitch = (arg[1].Pitch ~= nil) and arg[1].Pitch or ((arg[1].X ~= nil) and arg[1].X or ((arg[1].x ~= nil) and arg[1].x or ((#arg[1] > 0) and arg[1][1] or 0.0)))
			yaw = (arg[1].Yaw ~= nil) and arg[1].Yaw or ((arg[1].Y ~= nil) and arg[1].Y or ((arg[1].y ~= nil) and arg[1].y or ((#arg[1] > 1) and arg[1][2] or 0.0)))
			roll = (arg[1].Roll ~= nil) and arg[1].Roll or ((arg[1].Z ~= nil) and arg[1].Z or ((arg[1].z ~= nil) and arg[1].z or ((#arg[1] > 2) and arg[1][3] or 0.0)))
		else
			M.print("Invalid argument 1 passed to rotator function", LogLevel.Warning)
		end

		if #arg == 2 then
			if type(arg[2]) == "boolean" then
				reuseable = arg[2]
			else
				M.print("Invalid argument 2 passed to rotator function", LogLevel.Warning)
			end
		end
	elseif #arg == 3 or #arg == 4 then
		if type(arg[1]) == "number" then pitch = arg[1] else M.print("Invalid pitch value passed to rotator function", LogLevel.Warning) end
		if type(arg[2]) == "number" then yaw = arg[2] else M.print("Invalid yaw value passed to rotator function", LogLevel.Warning) end
		if type(arg[3]) == "number" then roll = arg[3] else M.print("Invalid roll value passed to rotator function", LogLevel.Warning) end

		if #arg == 4 then
			if type(arg[4]) == "boolean" then
				reuseable = arg[4]
			else
				M.print("Invalid argument 4 passed to vector function", LogLevel.Warning)
			end
		end
	end

	if kismet_math_library.MakeRotator ~= nil then
		return kismet_math_library:MakeRotator(roll, pitch, yaw)
	end

	local rotator = M.get_struct_object("ScriptStruct /Script/CoreUObject.Rotator", reuseable)
	if rotator ~= nil then
		if rotator["Pitch"] ~= nil then rotator.Pitch = pitch else rotator.pitch = pitch end
		if rotator["Yaw"] ~= nil then rotator.Yaw = yaw else rotator.yaw = yaw end
		if rotator["Roll"] ~= nil then rotator.Roll = roll else rotator.roll = roll end
	else
		rotator = {Pitch = pitch, Yaw = yaw, Roll = roll}
	end
	return rotator
end

function M.vector2D(...)
    local arg = {...}
	local x=0.0
	local y=0.0
	local reuseable = false

	if #arg == 1 or (#arg == 2 and type(arg[2]) == "boolean") then
		if type(arg[1]) == "table" or type(arg[1]) == "userdata" then
			x = (arg[1].X ~= nil) and arg[1].X or ((arg[1].x ~= nil) and arg[1].x or ((#arg[1] > 0) and arg[1][1] or 0.0))
			y = (arg[1].Y ~= nil) and arg[1].Y or ((arg[1].y ~= nil) and arg[1].y or ((#arg[1] > 1) and arg[1][2] or 0.0))
		else
			M.print("Invalid argument 1 passed to vector function", LogLevel.Warning)
		end

		if #arg == 2 then
			if type(arg[2]) == "boolean" then
				reuseable = arg[2]
			else
				M.print("Invalid argument 2 passed to vector function", LogLevel.Warning)
			end
		end
	elseif #arg == 2 or (#arg == 3 and type(arg[3]) == "boolean") then
		if type(arg[1]) == "number" then x = arg[1] else M.print("Invalid x value passed to vector function", LogLevel.Warning) end
		if type(arg[2]) == "number" then y = arg[2] else M.print("Invalid y value passed to vector function", LogLevel.Warning) end

		if #arg == 3 then
			if type(arg[3]) == "boolean" then
				reuseable = arg[3]
			else
				M.print("Invalid argument 3 passed to vector function", LogLevel.Warning)
			end
		end
	end

	local vector = M.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D", reuseable)
	if vector ~= nil then
		if vector["X"] ~= nil then vector.X = x else vector.x = x end
		if vector["Y"] ~= nil then vector.Y = y else vector.y = y end
	end
	return vector
end

-- Converts degrees to radians
local function deg2rad(deg)
    return deg * math.pi / 180
end

-- Converts a rotator (pitch, yaw, roll) to a quaternion
local function rotatorToQuaternion(pitch, yaw, roll)
    -- Convert to radians
    local p = deg2rad(pitch)
    local y = deg2rad(yaw)
    local r = deg2rad(roll)

    -- Half angles
    local cy = math.cos(y * 0.5)
    local sy = math.sin(y * 0.5)
    local cp = math.cos(p * 0.5)
    local sp = math.sin(p * 0.5)
    local cr = math.cos(r * 0.5)
    local sr = math.sin(r * 0.5)

    -- Quaternion components
    local qw = cr * cp * cy + sr * sp * sy
    local qx = sr * cp * cy - cr * sp * sy
    local qy = cr * sp * cy + sr * cp * sy
    local qz = cr * cp * sy - sr * sp * cy

    return {x = qx, y = qy, z = qz, w = qw}
end

function M.rotatorFromQuat(x, y, z, w)
	return kismet_math_library:Quat_Rotator(M.quat(x, y, z, w))
end

function M.quatFromRotator(pitch, yaw, roll)
	local quat = rotatorToQuaternion(pitch, yaw, roll)
	return M.quatf(quat.x, quat.y, quat.z, quat.w)
	--return kismet_math_library:Conv_VectorToQuaternion(M.vector(x, y, z))
end

function M.quat(x, y, z, w, reuseable)
	local quat = M.get_struct_object("ScriptStruct /Script/CoreUObject.Quat", reuseable)
	if quat ~= nil then
		kismet_math_library:Quat_SetComponents(quat, x, y, z, w)
	end
	return quat
end

function M.rotateVector(vector, rotator)
	return kismet_math_library:Quat_RotateVector(kismet_math_library:Quat_MakeFromEuler(M.vector(rotator.Roll, rotator.Pitch, rotator.Yaw)), vector)
end

function M.vectorDistance(vector1, vector2)
	return kismet_math_library:Vector_Distance(vector1, vector2)
end
-- function M.sumRotators(...) --BreakRotator doesnt work in robocop UB
    -- local arg = {...}
	-- local rollTotal,pitchTotal,yawTotal = 0,0,0
	-- for i = 1, #arg do
		-- local roll,pitch,yaw = 0,0,0
		-- kismet_math_library:BreakRotator(arg[i], roll, pitch, yaw) 
		-- print("here", roll, pitch, yaw)
		-- rollTotal = rollTotal + roll
		-- pitchTotal = pitchTotal + pitch
		-- yawTotal = yawTotal + yaw
	-- end
	-- return kismet_math_library:MakeRotator(rollTotal, pitchTotal, yawTotal)
-- end

function M.sumRotators(...)
    local arg = {...}
	local rollTotal,pitchTotal,yawTotal = 0,0,0
	if arg ~= nil then
		for i = 1, #arg do
			if arg[i] ~= nil then
				if arg[i]["Pitch"] ~= nil then pitchTotal = pitchTotal + arg[i]["Pitch"] else pitchTotal = pitchTotal + arg[i]["pitch"] end
				if arg[i]["Yaw"] ~= nil then yawTotal = yawTotal + arg[i]["Yaw"] else yawTotal = yawTotal + arg[i]["yaw"] end
				if arg[i]["Roll"] ~= nil then rollTotal = rollTotal + arg[i]["Roll"] else rollTotal = rollTotal + arg[i]["roll"] end
			end
		end
	end
	return kismet_math_library:MakeRotator(rollTotal, pitchTotal, yawTotal)
end

function M.get_transform(position, rotation, scale, reuseable)
	if position == nil then position = {X=0.0, Y=0.0, Z=0.0} end
	if scale == nil then scale = {X=1.0, Y=1.0, Z=1.0} end
	local transform = M.get_struct_object("ScriptStruct /Script/CoreUObject.Transform", reuseable)
	if transform ~= nil then
		transform.Translation = vector_3f(position.X, position.Y, position.Z)
		if rotation == nil then
			transform.Rotation.X = 0.0
			transform.Rotation.Y = 0.0
			transform.Rotation.Z = 0.0
			transform.Rotation.W = 1.0
		else
			transform.Rotation = rotation
		end
		transform.Scale3D = vector_3f(scale.X, scale.Y, scale.Z)
	end
	return transform
end

function M.set_component_relative_location(component, position)
	if component ~= nil and component.RelativeLocation ~= nil then
		if position == nil then position = {X=0.0, Y=0.0, Z=0.0} else position = M.vector(position) end
		if position ~= nil then
			component.RelativeLocation.X = position.X
			component.RelativeLocation.Y = position.Y
			component.RelativeLocation.Z = position.Z
		end
	end
end

function M.set_component_relative_rotation(component, rotation)
	if component ~= nil and component.RelativeRotation ~= nil then
		if rotation == nil then rotation = {Pitch=0, Yaw=0, Roll=0} else rotation = M.rotator(rotation) end
		component.RelativeRotation.Pitch = rotation.Pitch
		component.RelativeRotation.Yaw = rotation.Yaw
		component.RelativeRotation.Roll = rotation.Roll
	end
end

function M.set_component_relative_scale(component, scale)
	if component ~= nil and component.RelativeScale3D ~= nil then
		if scale == nil then scale = {X=1.0, Y=1.0, Z=1.0} else scale = M.vector(scale) end
		if scale ~= nil then
			component.RelativeScale3D.X = scale.X
			component.RelativeScale3D.Y = scale.Y
			component.RelativeScale3D.Z = scale.Z
		end
	end
end

function M.set_component_relative_transform(component, position, rotation, scale)
	M.set_component_relative_location(component, position)
	M.set_component_relative_rotation(component, rotation)
	M.set_component_relative_scale(component, scale)
end

function M.distanceBetween(vector1, vector2)
	return kismet_math_library:Vector_Distance(M.vector(vector1), M.vector(vector2))
end

function M.getForwardVector(rotator)
	if rotator ~= nil then
		return kismet_math_library:GetForwardVector(rotator)
	else
		return M.vector(0,0,0)
	end
end

function M.clampAngle180(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end
    return angle
end

-- The following two function allow you to create an array that can have a function as an element
--and that function can return more array elements that get spliced in
-- Marks a function call for expansion
function expandArray(f, ...)
	if f ~= nil then
		return {__expand = true, values = {table.unpack(f(...))}}
	end
end

-- Processes a mixed list of values and expansion markers
function spliceableInlineArray(t)
    local result = {}
    for _, v in ipairs(t) do
        if type(v) == "table" and v.__expand then
            for _, val in ipairs(v.values) do
                result[#result + 1] = val
            end
        else
            result[#result + 1] = v
        end
    end
    return result
end


function M.getShortName(object)
	if M.getValid(object) ~= nil then
		local name = object:get_fname():to_string()
		if name ~= nil then return name end
	end
	return ""
end

function M.getFullName(object)
	if M.getValid(object) ~= nil then
		return object:get_full_name()
	end
	return ""
end

function M.getUEVRParam_bool(paramName)
	local param = uevr.params.vr:get_mod_value(paramName)
	if param ~= nil then
		if string.sub(param, 1, 4 ) == "true" then return true else return false end
	else
		M.print("Invalid paramName in getUEVRParam_bool", LogLevel.Error)
	end
	return false
end

function M.getUEVRParam_int(paramName, default)
	local result = nil
	local param = uevr.params.vr:get_mod_value(paramName)
	if param ~= nil then
		--result = math.tointeger(param:gsub("[^%-%d]", ""))
		result = math.tointeger(M.PositiveIntegerMask(param))
	else
		M.print("Invalid paramName in getUEVRParam_int", LogLevel.Error)
	end
	if result == nil then result = default end
	return result
end


function M.PositiveIntegerMask(text)
    return text:gsub("[^%-%d]", "")
end

function M.get_reuseable_struct_object(structClassName)
	if structCache[structClassName] == nil then
		local class = M.get_class(structClassName)
		if class ~= nil then
			structCache[structClassName] = StructObject.new(class)
		end
	end
	return structCache[structClassName]
end

function M.get_struct_object(structClassName, reuseable)
	if reuseable == true then
		return M.get_reuseable_struct_object(structClassName)
	end
	local class = M.get_class(structClassName)
	if class ~= nil then
		return StructObject.new(class)
	end
	return nil
end

function M.isGamePaused()
	return isPaused
end

function M.isInCutscene()
	return isInCutscene
end

function M.get_world()
	if game_engine ~= nil then
		local viewport = game_engine.GameViewport
		if viewport ~= nil then
			local world = viewport.World
			return world
		end
	end
	return nil
end

function M.getWorld()
	return M.get_world()
end


function M.spawn_actor(transform, collisionMethod, owner, tag)
	local viewport = game_engine.GameViewport
	if viewport == nil then
		print("Viewport is nil")
	end

	local worldContext = viewport.World
	if worldContext == nil then
		print("World is nil")
	end

	if transform == nil then
		transform = M.get_transform()
	end

    local actor = Statics:BeginDeferredActorSpawnFromClass(worldContext, actor_c, transform, collisionMethod, owner)

    if actor == nil then
		print("Failed to spawn actor")
        return nil
    end

    Statics:FinishSpawningActor(actor, transform)

	-- print("Tags ",actor.Tags)
	-- if actor.Tags == nil then actor.Tags = {} end
	-- print("Tags before",#actor.Tags)
	-- if tag ~= nil then
		-- actor.Tags[#actor.Tags + 1] = M.fname_from_string(tag)
		-- print("Tag added", actor.Tags[#actor.Tags])
	-- end
	-- print("Tags after",#actor.Tags)

    return actor
end

function M.getAllActorsWithTag(tag)
	local actors = {}
	Statics:GetAllActorsWithTag(M.get_world(), M.fname_from_string(tag), actors)
	--print("getAllActorWithTag",#actors)
	return actors
end

function M.getAllActorsOfClassWithTag(className, tag)
	local actors = {}
	local class = M.get_class(className)
	if class ~= nil then
		Statics:GetAllActorsOfClassWithTag(M.get_world(), class, M.fname_from_string(tag), actors)
	end
	--print("getAllActorsOfClassWithTag",#actors)
	return actors
end

function M.getAllActorsOfClass(className)
	local actors = {}
	local class = M.get_class(className)
	if class ~= nil then
		Statics:GetAllActorsOfClass(M.get_world(), class, actors)
	end
	--print("getAllActorsOfClass",#actors)
	return actors
end

--coutesy of Pande4360
function M.validate_object(object)
    if object == nil or not UEVR_UObjectHook.exists(object) then
        return nil
    else
        return object
    end
end

function M.getValid(object, properties)
	if M.validate_object(object) ~= nil then
		if properties ~= nil and #properties > 0 then
			for i = 1 , #properties do
				object = object[properties[i]]
				if object ~= nil then
					if type(object) == "userdata" then
---@diagnostic disable-next-line: undefined-field
						if object.as_class == nil then
							--this is a property not an object
						else
							if not UEVR_UObjectHook.exists(object) then --check that is hasnt been deallocated
								return nil
							end
						end
					end
				else
					return nil
				end
			end
			return object
		else
			return object
		end
	else
		return nil
	end
end

function M.destroy_actor(actor)
	if actor ~= nil then
		pcall(function()
			if actor.K2_DestroyActor ~= nil then
				actor:K2_DestroyActor()
				print("Actor destroyed\n")
			end
		end)
	end
end

function M.spawn_object(objClassName, outer)
	local objClass = M.find_required_object(objClassName) --Class /Script/Engine.StaticMeshSocket
--	UObject* Statics:SpawnObject(UClass* ObjectClass, class UObject* Outer)
	if objClass ~= nil then
		return Statics:SpawnObject(objClass, outer)
	end
	return nil
end

-- namespace EAttachLocation {
    -- enum Type {
        -- KeepRelativeOffset = 0,
        -- KeepWorldPosition = 1,
        -- SnapToTarget = 2,
        -- SnapToTargetIncludingScale = 3,
        -- EAttachLocation_MAX = 4,
    -- };
-- }
function M.create_component_of_class(class, manualAttachment, relativeTransform, deferredFinish, parent, tag)
	if type(class) == "string" then class = M.get_class(class) end
	if manualAttachment == nil then manualAttachment = true end
	if relativeTransform == nil then relativeTransform = M.get_transform() end
	if deferredFinish == nil then deferredFinish = false end
	local baseActor = parent
	if baseActor == nil then baseActor = M.spawn_actor( nil, 1, nil, tag) end
	local component = nil
	if baseActor.AddComponentByClass == nil then
		component = uevr.api:add_component_by_class(baseActor, class, deferredFinish)
		--print("Used uevr.api:add_component_by_class to create component", baseActor,component, class)
		-- if component == nil then --what is templateName
			-- baseActor:AddComponent(templateName, manualAttachment, relativeTransform, deferredFinish)
		-- end
	else
		component = baseActor:AddComponentByClass(class, manualAttachment, relativeTransform, deferredFinish)
		--print("Used AddComponentByClass to create component",component)
	end
	if component ~= nil then
		component:SetVisibility(true)
		component:SetHiddenInGame(false)
		if component.SetCollisionEnabled ~= nil then
			component:SetCollisionEnabled(0, false)
		end
	else
		M.print("Failed to create_component_of_class because component was nil")
	end
	return component
end

function M.getEngineVersion()
	return kismet_system_library:GetEngineVersion()
end

function M.find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        M.print("Cannot find " .. name)
        return nil
    end

    return obj
end

--uses caching
function M.get_class(name, clearCache)
	if clearCache or classCache[name] == nil then
		classCache[name] = uevr.api:find_uobject(name)
	end
    return classCache[name]
end

function M.find_default_instance(className)
	local class =  M.get_class(className)
	if class ~= nil and class.get_first_object_matching ~= nil then
		return class:get_class_default_object()
	end
	return nil
end

function M.find_first_instance(className, includeDefault)
	local class =  M.get_class(className)
	if class ~= nil and class.get_first_object_matching ~= nil then
		return class:get_first_object_matching(includeDefault)
	end
	return nil
end

function M.find_all_instances(className, includeDefault)
	local class =  M.get_class(className)
	if class ~= nil and class.get_objects_matching ~= nil then
		return class:get_objects_matching(includeDefault)
	end
	return nil
end

function M.find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  M.get_class(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function M.find_all_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  M.get_class(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_objects_by_class(class, includeDefault)
	end
	return {}
end

function M.splitOnLastPeriod(input)
    local lastPeriodIndex = input:match(".*()%.") -- Find the last period's position
    if not lastPeriodIndex then
        return input, nil -- No period found
    end
    local beforePeriod = input:sub(1, lastPeriodIndex - 1)
    local afterPeriod = input:sub(lastPeriodIndex + 1)
    return beforePeriod, afterPeriod
end

function M.find_instance_of(className, objectName)
	--check if the objectName is a short name
	local isShortName = string.find(objectName, '.', 1, true) == nil
	local instances = M.find_all_of(className, true)
	for i, instance in ipairs(instances) do
		if isShortName then
			local before, after = M.splitOnLastPeriod(instance:get_full_name())
			if after ~= nil and after == objectName then
				return instance
			end
		else
			if instance:get_full_name() == objectName then
				return instance
			end
		end
	end
	return nil
end

function M.fname_from_string(str)
	if str == nil then str = "" end
	return kismet_string_library:Conv_StringToName(str)
end

-- float values from 0.0 to 1.0
function color_from_rgba(r,g,b,a, reuseable)
	local color = M.get_struct_object("ScriptStruct /Script/CoreUObject.LinearColor", reuseable) --StructObject.new(M.get_class("ScriptStruct /Script/CoreUObject.LinearColor"))
	--zero_color = StructObject.new(color_c)
	if color ~= nil then
		if color["R"] ~= nil then color.R = r else color.r = r end
		if color["G"] ~= nil then color.G = g else color.g = g end
		if color["B"] ~= nil then color.B = b else color.b = b end
		if color["A"] ~= nil then color.A = a else color.a = a end
	end
	return color
end
function M.color_from_rgba(r,g,b,a, reuseable)
	return color_from_rgba(r,g,b,a, reuseable)
end
-- int values from 0 to 255
function color_from_rgba_int(r,g,b,a, reuseable)
	local color = M.get_struct_object("ScriptStruct /Script/CoreUObject.Color", reuseable) --StructObject.new(M.get_class("ScriptStruct /Script/CoreUObject.Color"))
	if color ~= nil then
		color.R = r
		color.G = g
		if color["B"] == nil then
			color.b = b
		else
			color.B = b
		end
		color.A = a
	end
	return color
end
function M.color_from_rgba_int(r,g,b,a, reuseable)
	return color_from_rgba_int(r,g,b,a, reuseable)
end

function M.hexToColor(hex)
    if type(hex) ~= "string" or #hex < 7 then return M.color_from_rgba_int(0, 0, 0, 255) end
    local r = tonumber(string.sub(hex, 2, 3), 16) or 0
    local g = tonumber(string.sub(hex, 4, 5), 16) or 0
    local b = tonumber(string.sub(hex, 6, 7), 16) or 0
    local a = #hex >= 9 and tonumber(string.sub(hex, 8, 9), 16) or 255
    return M.color_from_rgba_int(r, g, b, a)
end

-- Converts an integer (AARRGGBB or RRGGBBAA) to RGBA components
function M.intToColor(num)
	-- If input is nil or not a number, return opaque black
	if type(num) ~= "number" then return M.color_from_rgba_int(0, 0, 0, 255) end
	-- Try to detect format: if num > 0xFFFFFF, assume AARRGGBB, else RRGGBB (alpha=255)
	local hex = string.format("%08X", num)
	local a, r, g, b
	if #hex == 8 then
		-- Default: treat as RRGGBBAA
		r = tonumber(hex:sub(1,2), 16)
		g = tonumber(hex:sub(3,4), 16)
		b = tonumber(hex:sub(5,6), 16)
		a = tonumber(hex:sub(7,8), 16)
	else
		-- Fallback: treat as RRGGBB
		r = tonumber(hex:sub(1,2), 16)
		g = tonumber(hex:sub(3,4), 16)
		b = tonumber(hex:sub(5,6), 16)
		a = 255
	end
	return M.color_from_rgba_int(r, g, b, a)
end

-- Converts an integer to a hex string in #RRGGBBAA format
function M.intToHexString(num)
	if type(num) ~= "number" then return "#000000FF" end
	local a = (num >> 24) & 0xFF
	local b = (num >> 16) & 0xFF
	local g = (num >> 8) & 0xFF
	local r = num & 0xFF
	return string.format("#%02X%02X%02X%02X", r, g, b, a)
end


function M.splitStr(inputstr, sep)
   	if sep == nil then
      	sep = '%s'
   	end
   	local t={}
   	if inputstr ~= nil then
		for str in string.gmatch(inputstr, '([^'..sep..']+)')
		do
			table.insert(t, str)
		end
   	end
   	return t
end

function M.getArrayFromVector2(vec)
	if vec == nil then
		return {0,0}
	end
	return {vec.x, vec.y}
end

function M.getArrayFromVector3(vec)
	if vec == nil then
		return {0,0,0}
	end
	return {vec.X, vec.Y, vec.Z}
end

function M.getArrayFromVector4(vec)
	if vec == nil then
		return {0, 0, 0, 0}
	end
	return {vec.X, vec.Y, vec.Z, vec.W}
end

--convert userdata types to native lua types for json saving
function M.getNativeValue(val, useTable)
	local returnValue = val
	if type(val) == "userdata" then
---@diagnostic disable-next-line: undefined-field
		if val.x ~= nil and val.y ~= nil and val.z == nil and val.w == nil then
			returnValue = M.getArrayFromVector2(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2]}
			end
---@diagnostic disable-next-line: undefined-field
		elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w == nil then
			returnValue = M.getArrayFromVector3(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2], Z=returnValue[3]}
			end
---@diagnostic disable-next-line: undefined-field
		elseif val.x ~= nil and val.y ~= nil and val.z ~= nil and val.w ~= nil then
			returnValue = M.getArrayFromVector4(val)
			if useTable == true then
				returnValue = {X=returnValue[1], Y=returnValue[2], Z=returnValue[3], W=returnValue[4]}
			end
		end
	end
	return returnValue
end

function M.tableToString(tbl, indent)
	if not indent then indent = 0 end
	local toprint = string.rep(" ", indent) .. "{\n"
	indent = indent + 2 
	for k, v in pairs(tbl) do
		toprint = toprint .. string.rep(" ", indent)
		if type(k) == "number" then
			toprint = toprint .. "[" .. k .. "] = "
		elseif type(k) == "string" then
			toprint = toprint  .. k ..  " = "
		end
		if type(v) == "number" then
			toprint = toprint .. v .. ",\n"
		elseif type(v) == "string" then
			toprint = toprint .. "\"" .. v .. "\",\n"
		elseif type(v) == "table" then
			toprint = toprint .. M.tableToString(v, indent + 2) .. ",\n"
		else
			toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
		end
	end
	toprint = toprint .. string.rep(" ", indent - 2) .. "}"
	return toprint
end

function M.isButtonPressed(state, button)
    return state.Gamepad.wButtons & button ~= 0
end
function M.isButtonNotPressed(state, button)
    return state.Gamepad.wButtons & button == 0
end
function M.pressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function M.unpressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end
function M.isThumbpadTouched(state, hand)
    local thumbpad = hand == Handed.Right and uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchRight") or uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchLeft")
	local controller = hand == Handed.Right and uevr.params.vr.get_right_joystick_source() or uevr.params.vr.get_left_joystick_source()
	return uevr.params.vr.is_action_active(thumbpad, controller)
end
function M.triggerHapticVibration(hand, secondsFromNow, duration, frequency, amplitude)
	if hand == nil then hand = Handed.Right end
	if secondsFromNow == nil then secondsFromNow = 0 end
	if duration == nil then duration = .05 end
	if frequency == nil then frequency = 1000.0 end
	if amplitude == nil then amplitude = 1.0 end
	local controller = hand == Handed.Right and uevr.params.vr.get_right_joystick_source() or uevr.params.vr.get_left_joystick_source()
	uevr.params.vr.trigger_haptic_vibration(secondsFromNow, duration, frequency, amplitude, controller)
end

-- if isButtonPressed(state, XINPUT_GAMEPAD_X) then
    -- unpressButton(state, XINPUT_GAMEPAD_X)
    -- pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
-- end

local fadeHardLock = false
local fadeSoftLock = false
function M.isFadeHardLocked()
	return fadeHardLock
end
function M.fadeCamera(rate, hardLock, softLock, overrideHardLock, overrideSoftLock)
	--print("fadeCamera called", rate, hardLock, softLock, overrideHardLock, overrideSoftLock, fadeHardLock, fadeSoftLock, "\n")

	if hardLock == nil then hardLock = false end
	if softLock == nil then softLock = false end
	--if overrideLocks == nil then overrideLocks = false end
	if overrideHardLock == nil then overrideHardLock = false end
	if overrideSoftLock == nil then overrideSoftLock = false end

	if overrideHardLock then
		fadeHardLock = false
	end
	if overrideSoftLock then
		fadeSoftLock = false
	end

	if fadeSoftLock or fadeHardLock then
		return
	end

	fadeHardLock = hardLock
	fadeSoftLock = softLock
	--print("fadeCamera executed",rate,"\n")

	local camMan = M.find_first_of("Class /Script/Engine.PlayerCameraManager")
	--camMan = uevr.api:get_player_controller(0).PlayerCameraManager
	--print("Camera Manager was",camMan:get_full_name(),"\n")
	if uevr ~= nil and camMan ~= nil and UEVR_UObjectHook.exists(camMan) then
		--(FromAlpha, ToAlpha, Duration, Color, bShouldFadeAudio, bHoldWhenFinished)
		camMan:StartCameraFade(0.999, 1.0, rate, color_from_rgba(0.0, 0.0, 0.0, 1.0), false, fadeHardLock)

		--pc:ClientSetCameraFade(bool bEnableFading, _Script_CoreUObject::Color FadeColor, _Script_CoreUObject::Vector2D FadeAlpha, float FadeTime, bool bFadeAudio, bool bHoldWhenFinished)
		if fadeSoftLock then
			delay(math.floor(rate * 1000), function()
				fadeSoftLock = false
			end)
		end
	end
	-- end
	-- local obj_class = api:find_uobject("Class /Script/Engine.PlayerCameraManager")
    -- if obj_class == nil then 
		-- print("Class /Script/Engine.PlayerCameraManager not found") 
		-- return
	-- end

    -- local obj_instances = obj_class:get_objects_matching(false)
    -- for i, instance in ipairs(obj_instances) do
		-- instance:StartCameraFade(0.999, 1.0, rate, color_from_rgba(0.0, 0.0, 0.0, 1.0), false, fadeHardLock)
		-- print("Camera Manager ",i,instance:get_full_name(),fadeHardLock,"\n")
	-- end

	-- if fadeSoftLock then
		-- delay(math.floor(rate * 1000), function()
			-- fadeSoftLock = false
		-- end)	
	-- end

end

function M.stopFadeCamera()
	local camMan = M.find_first_of("Class /Script/Engine.PlayerCameraManager")
	--print("Camera Manager was",camMan:get_full_name(),"\n")

	if uevr ~= nil and camMan ~= nil and UEVR_UObjectHook.exists(camMan) then
		--(FromAlpha, ToAlpha, Duration, Color, bShouldFadeAudio, bHoldWhenFinished)
		camMan:StopCameraFade()
		--camMan:SetManualCameraFade(1, color_from_rgba(0.0, 0.0, 0.0, 0.0), false)
		print("stopFadeCamera executed\n")
	end
	fadeHardLock = false
	fadeSoftLock = false
end

function M.set_2D_mode(state, delay_msec)
	--print("Setting 2D mode to ", state)
    if uevr ~= nil and uevr.params ~= nil then
		local mode = uevr.params.vr:get_mod_value("VR_2DScreenMode")
		if state and (string.sub(mode, 1, 5 ) == "false") then
			if delay_msec == nil then
				uevr.params.vr.set_mod_value("VR_2DScreenMode", "true")
				M.print("2D mode set immediate")
			else
				delay( delay_msec, function()
					uevr.params.vr.set_mod_value("VR_2DScreenMode", "true")
					M.print("2D mode set")
				end)
			end
		end
		if (not state) and (string.sub(mode, 1, 4 ) == "true") then
			if delay_msec == nil then
				uevr.params.vr.set_mod_value("VR_2DScreenMode", "false")
				M.print("3D mode set immediate")
			else
				delay( delay_msec, function()
					uevr.params.vr.set_mod_value("VR_2DScreenMode", "false") --do not execute in game thread
					M.print("3D mode set")
				end)
			end
		end
	end
end

function M.get_2D_mode()
	if uevr ~= nil and uevr.params ~= nil then
		local mode = uevr.params.vr:get_mod_value("VR_2DScreenMode")
		if string.sub(mode, 1, 4 ) == "true" then
			return true
		else
			return false
		end
	end
	return false
end

function M.set_decoupled_pitch(state)
	--print("Setting decoupled pitch to " ,state)
	uevr.params.vr.set_mod_value("VR_DecoupledPitch", state and "true" or "false")
end

function M.get_decoupled_pitch()
	local mode = uevr.params.vr:get_mod_value("VR_DecoupledPitch")
	if string.sub(mode, 1, 4 ) == "true" then
		return true
	else
		return false
	end
end

function M.set_decoupled_pitch_adjust_ui(state)
	uevr.params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", state and "true" or "false")
end

function M.get_decoupled_pitch_adjust_ui()
	local mode = uevr.params.vr:get_mod_value("VR_DecoupledPitchUIAdjust")
	if string.sub(mode, 1, 4 ) == "true" then
		return true
	else
		return false
	end
end


function M.enableCameraLerp(state, pitch, yaw, roll)
	if pitch == true then
		uevr.params.vr.set_mod_value("VR_LerpCameraPitch", state and "true" or "false")
	end
	if yaw == true then
		uevr.params.vr.set_mod_value("VR_LerpCameraYaw", state and "true" or "false")
	end
	if roll == true then
		uevr.params.vr.set_mod_value("VR_LerpCameraRoll", state and "true" or "false")
	end
end

function M.enableUIFollowsView(state)
	uevr.params.vr.set_mod_value("UI_FollowView", state and "true" or "false")
end

function M.enableSnapTurn(state)
	uevr.params.vr.set_mod_value("VR_SnapTurn", state and "true" or "false")
end

function M.setUIFollowsViewOffset(offset)
	uevr.params.vr.set_mod_value("UI_Distance", offset.Z)
	uevr.params.vr.set_mod_value("UI_X_Offset", offset.X)
	uevr.params.vr.set_mod_value("UI_Y_Offset", offset.Y)
end

function M.setUIFollowsViewSize(size)
	uevr.params.vr.set_mod_value("UI_Size", tostring(size))
end

--there should be a better way to do this with the asset registry
function M.getAssetDataFromPath(pathStr)
	local fAssetData = M.get_struct_object("ScriptStruct /Script/CoreUObject.AssetData")
	if fAssetData ~= nil then
		local arr = M.splitStr(pathStr, " ")
		if fAssetData.ObjectPath ~= nil then
			fAssetData.AssetClass = M.fname_from_string(arr[1])
			fAssetData.ObjectPath = M.fname_from_string(arr[2])
		end
		if fAssetData.AssetClassPath ~= nil then
			fAssetData.AssetClassPath.PackageName = M.fname_from_string("/Script/Engine")
			fAssetData.AssetClassPath.AssetName = M.fname_from_string(arr[1])
		end
		arr = M.splitStr(arr[2], "/")
		local arr2 = M.splitStr(arr[#arr], ".")
		fAssetData.AssetName = M.fname_from_string(arr2[2])
		local packagePath = table.concat(arr, "/", 1, #arr - 1)
		fAssetData.PackagePath = "/" .. packagePath
		if arr2[1] ~= nil then
			fAssetData.PackageName = "/" .. packagePath .. "/" .. arr2[1]
		end
	end
	return fAssetData
end

function M.getLoadedAsset(pathStr)
	local fAssetData = M.getAssetDataFromPath(pathStr)
	local assetRegistryHelper = M.find_first_of("Class /Script/AssetRegistry.AssetRegistryHelpers",  true)
	if assetRegistryHelper ~= nil then
		if not assetRegistryHelper:IsAssetLoaded(fAssetData) then
			local fSoftObjectPath = assetRegistryHelper:ToSoftObjectPath(fAssetData);
			kismet_system_library:LoadAsset_Blocking(fSoftObjectPath)
		end
		return assetRegistryHelper:GetAsset(fAssetData)
	end
	return nil
end

function M.copyMaterials(fromComponent, toComponent, showDebug)
	if fromComponent ~= nil and toComponent ~= nil then
		local materials = fromComponent:GetMaterials()
		if materials ~= nil then
			if showDebug == true then M.print("Copying materials. Found " .. #materials .. " materials on fromComponent") end
			for i = 1 , #materials do
				toComponent:SetMaterial(i - 1, materials[i])
				--print statement can cause crash
				--if showDebug == true then M.print("Material index " .. i .. ": " .. materials[i]:get_full_name()) end
			end
		end
	end
end

function M.getChildComponent(parent, name)
	local childComponent = nil
	if M.validate_object(parent) ~= nil and name ~= nil then
		local children = parent.AttachChildren
		if children ~= nil then
			for i, child in ipairs(children) do
				if  string.find(child:get_full_name(), name) then
					childComponent = child
				end
			end
		end
	end
	return childComponent
end

-- className and excludeInherited are optional
function M.getPropertiesOfClass(object, className, excludeInherited)
	local propertiesList = {}
	if M.getValid(object) ~= nil then
		local propertyClass = nil
		if className ~= nil then
			propertyClass = M.get_class(className)
		end
		local class = object:get_class()
		while M.getValid(class) ~= nil do
			local property = class:get_child_properties()
			while property ~= nil do
				if property:get_class():get_name() == "ObjectProperty" then
					local value = object[property:get_fname():to_string()]
					if value ~= nil and (propertyClass == nil or value:is_a(propertyClass)) then
						table.insert(propertiesList, property:get_fname():to_string())
					end
				end
				property = property:get_next()
			end
			if excludeInherited == true then
				class = nil
			else
				class = class:get_super_struct()
			end
		end
	end
	return propertiesList
end

function M.getPropertyPathDescriptorsOfClass(object, objectName, className, includeChildren)
	local meshList = {}
	if M.getValid(object) ~= nil then
		meshList = M.getPropertiesOfClass(object, className)
		for index, name in ipairs(meshList) do
			meshList[index] = objectName .. "." .. meshList[index]
		end

		if includeChildren == true then
			for _, prop in ipairs(meshList) do
				local parent = M.getObjectFromDescriptor(prop)
				if parent ~= nil then
					local children = parent.AttachChildren
					if children ~= nil then
						for i, child in ipairs(children) do
							if child:is_a(M.get_class(className)) then
								local prefix, shortName = M.splitOnLastPeriod(child:get_full_name())
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
	return meshList
end

function M.destroyComponent(component, destroyOwner, destroyChildren)
	if M.validate_object(component) ~= nil then
		local success, response = pcall(function()
			local name = component:get_full_name()
			M.print("[destroyComponent] destroyComponent called for " .. name)

			if destroyChildren == true then
				local children = component.AttachChildren
				if children ~= nil then
					M.print("[destroyComponent] Found " .. #children .. " children")
					for i = #children, 1, -1 do
						M.destroyComponent(children[i], destroyOwner, destroyChildren)
					end
				else
					M.print("[destroyComponent] No children found")
				end
			end

			M.print("[destroyComponent] Getting component owner for " ..  name)
			if component.GetOwner ~= nil then
				local actor = component:GetOwner()
				if actor ~= nil then
					local actorName = actor:get_full_name()
					M.print("[destroyComponent] Found component owner " .. actorName)
					if actor.K2_DestroyComponent ~= nil then
						actor:K2_DestroyComponent(component)
						M.print("[destroyComponent] Destroyed component " .. name)
					elseif component.K2_DestroyComponent ~= nil then
						component:K2_DestroyComponent(component)
						M.print("[destroyComponent] Destroyed component directly " .. name)
					end
					if destroyOwner == nil then destroyOwner = false end
					if destroyOwner then
						actor:K2_DestroyActor()
						M.print("[destroyComponent] Destroyed component owner " .. actorName .. " for " .. name)
					end
				else
					M.print("[destroyComponent] Component owner not found")
				end
			end
		end)
		if success == false then
			M.print("[destroyComponent] pcall fail " .. response, LogLevel.Error)
		end
	end
end

function M.detachAndDestroyComponent(component, destroyOwner, destroyChildren)
	if M.validate_object(component) ~= nil then
		M.print("[detachAndDestroyComponent] Detaching " .. component:get_full_name())
		if component.DetachFromParent ~= nil then
			component:DetachFromParent(true,false)
		end
		M.print("[detachAndDestroyComponent] Component detached")
		M.destroyComponent(component, destroyOwner, destroyChildren)
	end
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, showDebug, useDefaultPose
function M.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, options)
	if options == nil then options = {} end
	local showDebug = options.showDebug
	if showDebug == true then M.print("Creating PoseableMeshComponent from " .. skeletalMeshComponent:get_full_name()) end
	local poseableComponent = nil
	if skeletalMeshComponent ~= nil then
		if skeletalMeshComponent:is_a(M.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
			poseableComponent = M.create_component_of_class("Class /Script/Engine.PoseableMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			--poseableComponent:SetCollisionEnabled(0, false)
			if poseableComponent ~= nil then
				if showDebug == true then M.print("Created " .. poseableComponent:get_full_name()) end
				poseableComponent.SkeletalMesh = skeletalMeshComponent.SkeletalMesh
				--force initial update
				if poseableComponent.SetMasterPoseComponent ~= nil then
					poseableComponent:SetMasterPoseComponent(skeletalMeshComponent, true)
					poseableComponent:SetMasterPoseComponent(nil, false)
				elseif poseableComponent.SetLeaderPoseComponent ~= nil then
					poseableComponent:SetLeaderPoseComponent(skeletalMeshComponent, true)
					poseableComponent:SetLeaderPoseComponent(nil, false)
				end
				if showDebug == true then M.print("Master pose updated") end

				pcall(function()
					-- CopyPoseFromSkeletalComponent will take the current bone transforms
					-- of the source skeletalmeshcomponent and apply them to the poseablemeshcomponent
					-- For example if your source is gripping a gun then the copy will also be gripping
					-- If you do not want this and just want the default skeleton then set options.useDefaultPose to true
					if options.useDefaultPose ~= true then
						poseableComponent:CopyPoseFromSkeletalComponent(skeletalMeshComponent)
						if showDebug == true then M.print("Pose copied") end
					end
				end)

				M.copyMaterials(skeletalMeshComponent, poseableComponent, showDebug)
			else
				M.print("PoseableMeshComponent could not be created")
			end
		else
			M.print("PoseableMeshComponent could not be created because provided component is not a skeletalMeshComponent")
		end
	else
		M.print("PoseableMeshComponent could not be created because provided component is nil")
	end
	return poseableComponent
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, visible, collisionEnabled
function M.createStaticMeshComponent(mesh, options)
	local component = nil
	if mesh ~= nil and (type(mesh) == "string" or mesh:is_a(M.get_class("Class /Script/Engine.StaticMesh"))) then
		if type(mesh) == "string" then
			mesh = M.find_instance_of("Class /Script/Engine.StaticMesh", mesh)
		end

		if mesh ~= nil then --check mesh again because it changed if it was originally a string
			if options == nil then options = {} end
			component = M.create_component_of_class("Class /Script/Engine.StaticMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				if options.visible ~= nil then
					component:SetVisibility(options.visible)
				end
				if options.collisionEnabled ~= nil and component.SetCollisionEnabled ~= nil then
					component:SetCollisionEnabled(options.collisionEnabled == true and 1 or 0)
				end
				--various ways of finding a StaticMesh
				--local staticMesh = M.find_required_object("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --no caching so performance could suffer
				--local staticMesh = M.get_class("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --has caching but call is ideally meant for classes not other types
				--local staticMesh = M.find_instance_of("Class /Script/Engine.StaticMesh", "Sphere") --easier to specify name unless there is more than one "Sphere"
				--local staticMesh = M.find_instance_of("Class /Script/Engine.StaticMesh", "StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --safest

				component:SetStaticMesh(mesh)
			else
				M.print("StaticMeshComponent creation failed")
			end
		else
			M.print("StaticMeshComponent not created because static mesh could not be created")
		end
	else
		M.print("StaticMeshComponent not created because mesh param is invalid")
	end
	return component
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag
function M.createSkeletalMeshComponent(mesh, options)
	local component = nil
	if mesh ~= nil and (type(mesh) == "string" or mesh:is_a(M.get_class("Class /Script/Engine.SkeletalMesh"))) then
		if type(mesh) == "string" then
			mesh = M.find_instance_of("Class /Script/Engine.SkeletalMesh", mesh)
		end

		if mesh ~= nil then --check mesh again because it changed if it was originally a string
			if options == nil then options = {} end

			component = M.create_component_of_class("Class /Script/Engine.SkeletalMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				--component:SetCollisionEnabled(false,false)
				if component.SetSkeletalMesh ~= nil then
					component:SetSkeletalMesh(mesh)
					--M.print("Using SetSkeletalMesh")
				elseif component.SetSkeletalMeshAsset ~= nil then
					component:SetSkeletalMeshAsset(mesh)
					--M.print("Using SetSkeletalMeshAsset")
				else
					M.print("SkeletalMeshComponent SetSkeletalMesh function does not exist")
				end
				--component.SkeletalMesh = skeletalMesh				
			else
				M.print("SkeletalMeshComponent creation failed")
			end
		else
			M.print("SkeletalMeshComponent not created because skeletal mesh could not be created")
		end
	else
		M.print("SkeletalMeshComponent not created because mesh param is invalid")
	end
	return component
end

function M.getRootBoneOfBone(skeletalMeshComponent, boneName)
	local fName = M.fname_from_string(boneName)
	local boneName = fName
	while fName:to_string() ~= "None" do
		boneName = fName
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	return boneName
end

function M.getBoneNames(skeletalMeshComponent)
	local boneNames = {}
	if skeletalMeshComponent ~= nil then
		local count = skeletalMeshComponent:GetNumBones()
		for index = 0 , count - 1 do
			table.insert(boneNames, skeletalMeshComponent:GetBoneName(index):to_string())
		end
	else
		M.print("Can't get bone names because skeletalMeshComponent was nil", LogLevel.Warning)
	end
	return boneNames
end



--options are width, height, format
function M.createRenderTarget2D(options)
     return kismet_rendering_library:CreateRenderTarget2D( M.get_world(), options.width, options.height, options.format, zero_color, false)
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, visible, collisionEnabled
function M.createSceneCaptureComponent(options)
	local component = M.create_component_of_class("Class /Script/Engine.SceneCaptureComponent2D", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
	if component ~= nil then
		if options.visible ~= nil then
			component:SetVisibility(options.visible)
		end
		if options.collisionEnabled ~= nil and component.SetCollisionEnabled ~= nil then
			component:SetCollisionEnabled(options.collisionEnabled == true and 1 or 0)
		end
		-- if component["bCacheVolumetricCloudsShadowMaps"] ~= nil then component.bCacheVolumetricCloudsShadowMaps = true end
		-- -- component.bCachedDistanceFields = 1;
		-- component.bUseRayTracingIfEnabled = false;
		-- -- component.PrimitiveRenderMode = 2; -- 0 - legacy, 1 - other
		-- -- component.CaptureSource = 1;
		-- component.bAlwaysPersistRenderingState = true;
		-- if component["bEnableVolumetricCloudsCapture"] ~= nil then component.bEnableVolumetricCloudsCapture = false end
		-- component.bCaptureEveryFrame = 1;

		-- -- post processing
		-- component.PostProcessSettings.bOverride_MotionBlurAmount = true
		-- component.PostProcessSettings.MotionBlurAmount = 0.0 -- Disable motion blur
		-- component.PostProcessSettings.bOverride_ScreenSpaceReflectionIntensity = true
		-- component.PostProcessSettings.ScreenSpaceReflectionIntensity = 0.0 -- Disable screen space reflections
		-- component.PostProcessSettings.bOverride_AmbientOcclusionIntensity = true
		-- component.PostProcessSettings.AmbientOcclusionIntensity = 0.0 -- Disable ambient occlusion
		-- component.PostProcessSettings.bOverride_BloomIntensity = true
		-- component.PostProcessSettings.BloomIntensity = 0.0
		-- component.PostProcessSettings.bOverride_LensFlareIntensity = true
		-- component.PostProcessSettings.LensFlareIntensity = 0.0 -- Disable lens flares
		-- component.PostProcessSettings.bOverride_VignetteIntensity = true
		-- component.PostProcessSettings.VignetteIntensity = 0.0 -- Disable vignette
	else
		print("SceneCaptureComponent not created\n")
	end
	return component
end

function M.getActiveWidgetByClass(className)
	local widgets = M.find_all_instances(className, false)
	if widgets ~= nil and M.getValid(pawn) ~= nil then
		for _, widget in ipairs(widgets) do
			if widget:GetOwningPlayerPawn() == pawn then
				return widget
			end
		end
	end
end

-- local widget = WidgetBlueprintLibrary:Create(uevrUtils.get_world(), uevrUtils.get_class("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C"), playerController)

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, removeFromViewport, twoSided, drawSize
function M.createWidgetComponent(widget, options)
	local component = nil
	local widgetAlignment = nil
	local className = nil
	if widget ~= nil and (type(widget) == "string" or widget:is_a(M.get_class("Class /Script/UMG.Widget"))) then
		if type(widget) == "string" then
			className = widget
			widget = M.getActiveWidgetByClass(widget)
		end
		if M.getValid(widget) ~= nil then
			widgetAlignment = widget:GetAlignmentInViewport()
			component = M.create_component_of_class("Class /Script/UMG.WidgetComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				if options.removeFromViewport == true and widget.RemoveFromViewport ~= nil then
					widget:RemoveFromViewport()
				end
				component:SetWidget(widget)
				if options.twoSided ~= nil and component.SetTwoSided ~= nil then
					component:SetTwoSided(options.twoSided)
				end
				if options.drawSize ~= nil and component.SetDrawSize ~= nil then
					component:SetDrawSize(options.drawSize)
				end
				-- component:SetRenderCustomDepth(true)
				-- component:SetCustomDepthStencilValue(100)
				-- component:SetCustomDepthStencilWriteMask(1)
			else
				M.print("WidgetComponent creation failed")
			end
		else
			--Temporary hack for Unreal Engine 5.5+ returning invalid classes for a few seconds after level change
			if className ~= nil then classCache[className] = nil end
			M.print("WidgetComponent not created because widget could not be created")
		end
	else
		M.print("WidgetComponent not created because widget param was invalid")
	end
	return component, widgetAlignment
end

function M.setWidgetLayout(widget, scale, alignment)
    if widget ~= nil and WidgetLayoutLibrary ~= nil then
        if scale ~= nil then
            scale = M.vector2D(scale)
            if scale ~= nil then
                local viewportSize = WidgetLayoutLibrary:GetViewportSize(M.get_world())
                local viewportScale = WidgetLayoutLibrary:GetViewportScale(M.get_world())
                local newSizeX = viewportSize.X * scale.X / viewportScale
                local newSizeY = viewportSize.Y * scale.Y / viewportScale
                widget:SetDesiredSizeInViewport(M.vector2D(newSizeX, newSizeY))
            end
        end
        if alignment ~= nil then
            alignment = M.vector2D(alignment)
            if alignment ~= nil then
                widget:SetAlignmentInViewport(M.vector2D(-alignment.X, -alignment.Y))
            end
        end
    end
end


function M.fixMeshFOV(mesh, propertyName, value, includeChildren, includeNiagara, showDebug)
	local logLevel = showDebug == true and LogLevel.Debug or LogLevel.Ignore
	if M.validate_object(mesh) == nil then
		M.print("Unable to fix mesh FOV, invalid Mesh", LogLevel.Warning)
	elseif propertyName == nil or propertyName == "" then
		M.print("Unable to fix mesh FOV, invalid property name", LogLevel.Warning)
	else
		local propertyFName = M.fname_from_string(propertyName)
		if value == nil then value = 0.0 end

		local oldValue = nil
		local newValue = nil
		if mesh ~= nil and mesh.GetMaterials ~= nil then
			local materials = mesh:GetMaterials()
			if materials ~= nil then
				if showDebug == true then M.print("Found " .. #materials .. " materials in fixMeshFOV", logLevel) end
				for i, material in ipairs(materials) do
					if material:is_a(M.get_class("Class /Script/Engine.MaterialInstanceConstant")) then
						material = mesh:CreateAndSetMaterialInstanceDynamicFromMaterial(i-1, material)
					end

					if material.SetScalarParameterValue ~= nil then
						if showDebug == true then oldValue = material:K2_GetScalarParameterValue(propertyFName) end
						material:SetScalarParameterValue(propertyFName, value)
						if showDebug == true then
							newValue = material:K2_GetScalarParameterValue(propertyFName)
							M.print("Material: " .. i .. " " .. material:get_full_name() .. " before:" .. oldValue .. " after:" .. newValue, logLevel)
						end
					end
				end
			else
				M.print("No materials found on mesh", logLevel)
			end
			if includeChildren == true then
				local children = mesh.AttachChildren
				if children ~= nil then
					for i, child in ipairs(children) do
						if child:is_a(M.get_class("Class /Script/Engine.MeshComponent")) and child.GetMaterials ~= nil then
							local materials = child:GetMaterials()
							if materials ~= nil then
								for i, material in ipairs(materials) do
									if material:is_a(M.get_class("Class /Script/Engine.MaterialInstanceConstant")) then
										material = child:CreateAndSetMaterialInstanceDynamicFromMaterial(i-1, material)
									end
									if material.SetScalarParameterValue ~= nil then
										if showDebug == true then oldValue = material:K2_GetScalarParameterValue(propertyFName) end
										material:SetScalarParameterValue(propertyFName, value)
										if showDebug == true then
											newValue = material:K2_GetScalarParameterValue(propertyFName)
											M.print("Child Material: " .. i .. " " .. material:get_full_name() .. " before:" .. oldValue .. " after:" .. newValue, logLevel)
										end
									end
								end
							end
						end

						if includeNiagara == true and child:is_a(M.get_class("Class /Script/Niagara.NiagaraComponent")) then
							child:SetNiagaraVariableFloat(propertyName, value)
							if showDebug == true then M.print("Child Niagara Material: " .. child:get_full_name(),logLevel) end
						end
					end
				end
			end
		end
	end
end


function M.cloneComponent(component, options)
	if options == nil then options = {} end
	local clone = M.create_component_of_class(component:get_class(), options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
	if clone ~= nil and component.SetStaticMesh ~= nil then
		clone:SetStaticMesh(component.StaticMesh)
	elseif component:is_a(M.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
		clone = M.createPoseableMeshFromSkeletalMesh(component, nil)
	end
	-- if component.SetSkeletalMesh ~= nil then
		-- clone:SetSkeletalMesh(component.SkeletalMesh)
		-- M.copyMaterials(component, clone, showDebug)
	-- end
	-- if component.SetSkeletalMeshAsset ~= nil then
		-- clone:SetSkeletalMeshAsset(component.SkeletalMeshAsset)
		-- M.copyMaterials(component, clone, showDebug)
	-- end
	return clone
end

--courtesy of lobotomy
function M.getCleanHitResult(hitResult)
	if hitResult ~= nil then
		local bBlockingHit = {}
		local bInitialOverlap = {}
		local Time = {}
		local Distance = {}
		local Location = {}
		local ImpactPoint = {}
		local Normal = {}
		local ImpactNormal = {}
		local PhysMat = {}
		local HitActor = {}
		local HitComponent = {}
		local HitBoneName = {}
		local HitItem = {}
		local ElementIndex = {}
		local FaceIndex = {}
		local TraceStart = {}
		local TraceEnd = {}
		Statics:BreakHitResult(hitResult, bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd )

		local details = {}
		details.FaceIndex = hitResult.FaceIndex
		details.Time = hitResult.Time
		details.Distance = hitResult.Distance
		details.Location = M.vector(hitResult.Location)
		details.ImpactPoint = M.vector(hitResult.ImpactPoint)
		details.Normal = M.vector(hitResult.Normal)
		details.ImpactNormal = M.vector(hitResult.ImpactNormal)
		details.TraceStart = M.vector(hitResult.TraceStart)
		details.TraceEnd = M.vector(hitResult.TraceEnd)
		details.PenetrationDepth = hitResult.PenetrationDepth
		details.Item = hitResult.Item
		details.ElementIndex = hitResult.ElementIndex
		details.bBlockingHit = hitResult.bBlockingHit
		details.bStartPenetrating = hitResult.bStartPenetrating
		details.PhysMaterial = PhysMat.result
		details.Actor = HitActor.result
		details.Component = HitComponent.result
		details.BoneName = HitBoneName.result and HitBoneName.result:to_string() or nil
		details.MyBoneName = hitResult.MyBoneName and hitResult.MyBoneName:to_string() or nil
		return details
	end
	return nil
end

function M.getLineTraceHitResult(originPosition, originDirection, collisionChannel, traceComplex, ignoreActors, minHitDistance, maxTraceDistance, includeFullDetails)
	if originPosition ~= nil and originDirection ~= nil then
		if maxTraceDistance == nil then maxTraceDistance = 8192.0 end
		local endLocation = originPosition + (originDirection * maxTraceDistance)
		local ignore_actors = ignoreActors or {}
		if traceComplex == nil then traceComplex = false end
		--if minHitDistance == nil then minHitDistance = 10 end
		if collisionChannel == nil then collisionChannel = 0 end
		local world = M.get_world()
		if world ~= nil then
			local hit = kismet_system_library:LineTraceSingle(world, originPosition, endLocation, collisionChannel, traceComplex, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			local exceedsMinDistance = true
			if minHitDistance ~= nil then
				local distance = M.vectorDistance(originPosition, M.vector(reusable_hit_result.Location))
				exceedsMinDistance = distance >= minHitDistance
			end
			--print(collisionChannel, traceComplex, maxTraceDistance, hit, reusable_hit_result.Distance, minHitDistance,reusable_hit_result.Location.X, reusable_hit_result.Location.Y, reusable_hit_result.Location.Z)
			if hit and exceedsMinDistance then --reusable_hit_result.Distance > minHitDistance then
				if includeFullDetails == true then
					return M.getCleanHitResult(reusable_hit_result)
				end
				return reusable_hit_result
			end
		end
	end
	return nil
end


function M.getTargetLocation(originPosition, originDirection, collisionChannel, ignoreActors, traceComplex, minHitDistance, maxTraceDistance)
	local hitResult = M.getLineTraceHitResult(originPosition, originDirection, collisionChannel, traceComplex, ignoreActors, minHitDistance, maxTraceDistance)
	if hitResult ~= nil then
		--M.executeUEVRCallbacks("on_interaction_hit", M.getCleanHitResult(hitResult))
		return M.vector(hitResult.Location)
	end
	

	-- if originPosition ~= nil and originDirection ~= nil then
	-- 	local endLocation = originPosition + (originDirection * 8192.0)
	-- 	local ignore_actors = ignoreActors or {}
	-- 	if traceComplex == nil then traceComplex = false end
	-- 	if minHitDistance == nil then minHitDistance = 10 end
	-- 	if collisionChannel == nil then collisionChannel = 0 end
	-- 	local world = M.get_world()
	-- 	if world ~= nil then
	-- 		local hit = kismet_system_library:LineTraceSingle(world, originPosition, endLocation, collisionChannel, traceComplex, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
	-- 		if hit and reusable_hit_result.Distance > minHitDistance then
	-- 			endLocation = M.vector(reusable_hit_result.Location) --{X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
	-- 		end
	-- 	end

	-- 	return endLocation
	-- end
	return nil
end


function M.getArrayRange(arr, startIndex, endIndex)
    local result = {}
    -- Ensure startIndex and endIndex are within valid bounds
    startIndex = math.max(1, startIndex)
    endIndex = math.min(#arr, endIndex)

    for i = startIndex, endIndex do
        table.insert(result, arr[i])
    end
    return result
end

function M.wrapTextOnWordBoundary(text, maxCharsPerLine)
	if text == nil then text = "" end
 	if maxCharsPerLine == nil then maxCharsPerLine = 80 end
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

function M.parseHierarchyString(str)
	if str == nil then str = "" end
    local tokens = {}
    for token in str:gmatch("[^%.]+") do
        table.insert(tokens, token)
    end

    local root = nil
    local current = nil

    for _, token in ipairs(tokens) do
        local parent, child = token:match("^(%w+)%((%w+)%)$")
        local node

        if parent and child then
            node = { name = parent, child = { name = child } }
        else
            node = { name = token }
        end

        if not root then
            root = node
            current = root
        else
			if current ~= nil then
				if current.child then
					current = current.child
				elseif current.property then
					current = current.property
				end

				if parent and child then
					current.property = node
					current = node.child
				else
					current.property = node
					current = node
				end
			end
        end
    end

    return root
end

function M.getObjectFromHierarchy(node, object, showDebug)
	if node ~= nil then
		if node.name then
			if object == nil then
				if node.name == "Pawn" then
					if showDebug == true then M.print("[getObjectFromHierarchy] Node name " .. node.name) end
					object = pawn
				end
			end
			if object == nil then
				if showDebug == true then M.print("[getObjectFromHierarchy] Object not found " .. node.name) end
				return object
			end
			if showDebug == true then M.print("[getObjectFromHierarchy] " .. object:get_full_name()) end
		end
		if node.child then
			if showDebug == true then M.print("[getObjectFromHierarchy] Attached child " .. node.child.name) end
			object = M.getChildComponent(object, node.child.name)
			object = M.getObjectFromHierarchy(node.child, object, showDebug)
		end
		if M.getValid(object) ~= nil and node.property and node.property.name ~= nil then
			if showDebug == true then M.print("[getObjectFromHierarchy] Property " .. node.property.name) end
			object = object[node.property.name]
			object = M.getObjectFromHierarchy(node.property, object, showDebug)
		end
	end
	return object
end

-- "Pawn.Mesh(Arm).Glove"
function M.getObjectFromDescriptor(descriptor, showDebug)
	return M.getObjectFromHierarchy(M.parseHierarchyString(descriptor), nil, showDebug)
end

function M.getControllerIndex(controllerID)
	if controllerID == 0 then
		return uevr.params.vr.get_left_controller_index()
	elseif controllerID == 1 then
		return uevr.params.vr.get_right_controller_index()
	elseif controllerID == 2 then
		return uevr.params.vr.get_hmd_index()
	end
	return nil
end

function M.dumpJson(filename, jsonData)
	json.dump_file(filename .. ".json", jsonData, 4)
end
-- Following code is coutesy of markmon 
------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------
function get_cvar_int(cvar)
    local console_manager = uevr.api:get_console_manager()

    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        return var:get_int()
    end
end
function M.get_cvar_int(cvar)
	get_cvar_int(cvar)
end
function set_cvar_int(cvar, value)
    local console_manager = uevr.api:get_console_manager()

    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_int(value)
    end
end
function M.set_cvar_int(cvar, value)
	set_cvar_int(cvar, value)
end

function set_cvar_float(cvar, value)
    local console_manager = uevr.api:get_console_manager()

    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_float(value)
    end
end
function M.set_cvar_float(cvar, value)
	set_cvar_float(cvar, value)
end

-------------------------------------------------------------------------------
-- hook_function
--
-- Hooks a UEVR function. 
--
-- class_name = the class to find, such as "Class /Script.GunfireRuntime.RangedWeapon"
-- function_name = the function to Hook
-- native = true or false whether or not to set the native function flag.
-- prefn = the function to run if you hook pre. Pass nil to not use
-- postfn = the function to run if you hook post. Pass nil to not use.
-- dbgout = true to print the debug outputs, false to not
--
-- Example:
--    hook_function("Class /Script/GunfireRuntime.RangedWeapon", "OnFireBegin", true, nil, gun_firingbegin_hook, true)
--
-- Returns: true on success, false on failure.
-------------------------------------------------------------------------------
function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
	if(dbgout) then M.print("[hook_function] " .. class_name .. "   " .. function_name) end
    local result = false
    local class_obj = uevr.api:find_uobject(class_name)
    if(class_obj ~= nil) then
        if dbgout then M.print("[hook_function] Found class obj for " .. class_name) end
        local class_fn = class_obj:find_function(function_name)
        if(class_fn ~= nil) then
            if dbgout then M.print("[hook_function] Found function " .. function_name .. " for " .. class_name) end
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then M.print("[hook_function] Set native flag") end
            end

            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then M.print("[hook_function] Set function hook for " .. (prefn == nil and "nil" or "pre-function") .. " and " .. (postfn == nil and "nil" or "post-function")) end
        end
    end
    if dbgout then M.print("---") end
    return result
end

-------------------------------------------------------------------------------
-- returns local pawn
-------------------------------------------------------------------------------
function M.get_local_pawn()
	return uevr.api:get_local_pawn(0)
end

-------------------------------------------------------------------------------
-- returns local player controller
-------------------------------------------------------------------------------
function M.get_player_controller()
	return uevr.api:get_player_controller(0)
end

-------------------------------------------------------------------------------
-- Logs to the log.txt
-------------------------------------------------------------------------------
function M.log_info(message)
	uevr.params.functions.log_info(message)
end

-------------------------------------------------------------------------------
-- Print all instance names of a class to debug console
-------------------------------------------------------------------------------
function M.PrintInstanceNames(class_to_search)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then
		print(class_to_search, "was not found")
		return
	end

    local obj_instances = obj_class:get_objects_matching(false)

    for i, instance in ipairs(obj_instances) do
		print(i, instance:get_fname():to_string(), instance:get_full_name())
	end
end

-------------------------------------------------------------------------------
-- Get first instance of a given class object
-------------------------------------------------------------------------------
local function GetFirstInstance(class_to_search)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then
		print(class_to_search, "was not found")
		return nil
	end

    return obj_class:get_first_object_matching(false)
end


-------------------------------------------------------------------------------
-- Get class object instance matching string
-------------------------------------------------------------------------------
function M.GetInstanceMatching(class_to_search, match_string)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then
		print(class_to_search, "was not found")
		return nil
	end

    local obj_instances = obj_class:get_objects_matching(false)

    for i, instance in ipairs(obj_instances) do
        if string.find(instance:get_full_name(), match_string) then
			return instance
		end
	end
end


-------------------------------------------------------------------------------
-- Example hook pre function. Post is same but no return.
-------------------------------------------------------------------------------

-- Note if post, do not return a value. 
-- If hooking as native, must return false.
-- local function HookedFunctionPre(fn, obj, locals, result)
    -- print("Shift beginning : ")

    -- return true
-- end

--hook_function("BlueprintGeneratedClass /Game/Reality/BP_ShiftManager.BP_ShiftManager_C", "OnShiftBegin", false, HookedFunctionPre, nil, true)


M.initUEVR(uevr)

-- When the playerController changes pawns (e.g. respawn, death, entering a controllable vehicle), this function is called.
-- We hook it here to notify any listeners providing an easy way for developers to react to pawn changes.
-- In your code just add a callback like this:
-- function on_client_restart(newPawn)
-- 	uevrUtils.print("Pawn changed to " .. newPawn:get_full_name())
-- end
hook_function("Class /Script/Engine.PlayerController", "ClientRestart", true, nil,
	function(fn, obj, locals, result)
		if on_client_restart ~= nil or hasUEVRCallbacks("on_client_restart") then --don't bother doing anything if nothing is listening
			if on_client_restart ~= nil then
				on_client_restart(locals.NewPawn)
			end
			executeUEVRCallbacks("on_client_restart", locals.NewPawn)
		end

	-- print("ClientRestart called", locals, result, locals.NewPawn:get_class():get_full_name(), obj:get_class():get_full_name() )
	-- if locals.NewPawn ~= nil and locals.NewPawn:get_class():get_full_name() == "BlueprintGeneratedClass /Game/Core/Player/BP_PlayerCharacter.BP_PlayerCharacter_C" then
	-- 	pawn = locals.NewPawn
	-- end
	-- if locals.NewPawn ~= nil and locals.NewPawn:get_class():get_full_name() == "BlueprintGeneratedClass /Game/Development/Vehicles/BP_MoskvichDrivable.BP_MoskvichDrivable_C" then
	-- 	print("Player in vehicle")
	-- 	--isInCar = true
	-- end
	end
, true)


return M