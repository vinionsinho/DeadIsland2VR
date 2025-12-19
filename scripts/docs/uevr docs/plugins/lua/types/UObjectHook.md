
# UEVR_UObjectHook

## What is UObjectHook?

UObjectHook is a UEVR defined class that hooks into the UObject creation and destruction process. It is used to track UObject instances with minimal performance overhead.

It is also used to add motion controls.

UObjectHook uses all static functions.

## Functions

{{func_doc
name: UEVR_UObjectHook.activate
description: Activates the UObjectHook. Some of the below functions automatically activate the UObjectHook if it is not already active.
}}

{{func_doc
name: UEVR_UObjectHook.exists
args: obj: UObject*
description: Returns true if the specified UObject currently exists.
}}

{{func_doc
name: UEVR_UObjectHook.is_disabled
description: Returns true if the UObjectHook is disabled.
}}

{{func_doc
name: UEVR_UObjectHook.set_disabled
args: disabled: bool
description: Sets the disabled state of the UObjectHook.
}}

{{func_doc
name: UEVR_UObjectHook.get_first_object_by_class
args: class: UClass*, allow_default: bool
description: Returns the first UObject instance of the specified class. If `allow_default` is true, default objects are included in the search.
}}

{{func_doc
name: UEVR_UObjectHook.get_objects_by_class
args: class: UClass*, allow_default: bool
description: Returns an array of UObject instances of the specified class. If `allow_default` is true, default objects are included in the array.
}}

{{func_doc
name: UEVR_UObjectHook.get_or_add_motion_controller_state
args: obj: UObject*
description: Returns the motion controller state for the specified UObject. If the state does not exist, it is created.
}}

{{func_doc
name: UEVR_UObjectHook.get_motion_controller_state
args: obj: UObject*
description: Returns the motion controller state for the specified UObject. If the state does not exist, returns nil.
}}
