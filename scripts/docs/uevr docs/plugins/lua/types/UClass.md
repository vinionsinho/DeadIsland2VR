# UEVR_UClass

## What is UClass?

UClass acts as a descriptor for a class in Unreal Engine. It contains reflected information about the class, such as its name, properties, and functions.

UClass inherits all the functions from [UEVR_UStruct](UStruct.md).

## Functions

### `UEVR_UClass.static_class()`

Returns the [UEVR_UClass*](UClass.md) descriptor for UClass.

### `class:get_class_default_object()`

Returns the default [UEVR_UObject*](UObject.md) object for the class.

### `class:get_objects_matching(allow_default: bool)`

Returns an array of [UEVR_UObject*](UObject.md) objects that are instances of the class. If `allow_default` is true, default objects are included in the array.

### `class:get_first_object_matching(allow_default: bool)`

Returns the first [UEVR_UObject*](UObject.md) object that is an instance of the class. If `allow_default` is true, default objects are included in the search.

