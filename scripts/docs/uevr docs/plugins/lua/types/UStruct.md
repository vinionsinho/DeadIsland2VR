# UEVR_UStruct

## What is UStruct?

UStruct is a type that represents a descriptor for a struct in Unreal Engine. Objects that can be described by a UStruct (but not a UClass) are usually POD types or simple data structures like FVector.

UStruct inherits all the functions from [UEVR_UObject](UObject.md).

## Functions

### `UEVR_UStruct.static_class()`

Returns the [UEVR_UClass*](UClass.md) descriptor for UStruct.

### `struct:get_super_struct()`

Returns the [UEVR_UStruct*](UStruct.md) object of the super struct.

### `struct:get_super()`

Same as `struct:get_super_struct()`.

### `struct:find_function(name: string)`

Returns the [UEVR_UFunction*](UFunction.md) object of the function with the specified name.

### `struct:find_property(name: string)`

Returns the [UEVR_FProperty](FProperty.md) object of the property with the specified name.

### `struct:get_child_properties()`

Returns the first [UEVR_FProperty*](FProperty.md) object of the struct. Use `property:get_next()` to iterate through the properties.

### `struct:get_properties_size()`

Returns the total byte size of the properties of the struct.
