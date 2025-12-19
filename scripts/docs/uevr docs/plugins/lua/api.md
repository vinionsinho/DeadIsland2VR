# uevr.api

## Members

### `uevr.api.sdk`

## Functions

### `uevr.api:find_uobject(name: string)`

Searches the [UEVR_FUObjectArray](types/FUObjectArray.md) for an object with the specified name. Returns the object as a [UEVR_UObject*](types/UObject.md) object, or nil if not found.

Should not be constantly used, unless it is for class objects, or objects that are only created once. Otherwise, use [UClass:get_objects_matching](types/UClass.md#get_objects_matching) instead or the equivalent [UEVR_UObjectHook](types/UObjectHook.md) functions.

### `uevr.api:get_engine()`

Returns the global `UGameEngine` object.

### `uevr.api:get_player_controller(index: number)`

Returns the player controller at the specified index, which is a [UEVR_UObject*](types/UObject.md) object.

### `uevr.api:get_local_pawn(index: number)`

Returns the local pawn at the specified index, which is a [UEVR_UObject*](types/UObject.md) object.

### `uevr.api:spawn_object(class: UClass*, outer: UObject*)`

Attempts to spawn an object of the specified class with the specified outer object. Returns the spawned object as a [UEVR_UObject*](types/UObject.md) object.

### `uevr.api:add_component_by_class(actor: UObject*, class: UClass*, deferred: bool = false)`

Unified, simplified function that adds a component to an actor, on UE4 and UE5 with default transforms setup. Automatically calls FinishAddComponent if `deferred` is false.

### `uevr.api:execute_command(command: string)`

Executes the specified console command. Does not operate 1:1 with the native UE console, as it does not pass the command onto the player controller, but should work with most commands.

### `uevr.api:get_uobject_array()`

Returns the [UEVR_FUObjectArray](types/FUObjectArray.md) instance.

### `uevr.api:get_console_manager()`

Returns the [FConsoleManager](types/FConsoleManager.md) instance.

### `uevr.api:dispatch_custom_event(event_name: string, event_data: string)`

Dispatches an event that can be listened to on the C/C++ plugin side via `on_custom_event`.
