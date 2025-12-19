# UEVR_UObject

## What is UObject?

UObject are objects that are part of the Unreal Engine's object system. They are backed by a UClass and can be used to represent anything in the game, such as actors, components, and more.

## Meta Functions

### `object:__index(key: string)`

Wrapper for `object:get_property(key)`. Can be used to call functions on the UObject.

ex:
```lua
obj:SomeFunction()
local asdf = obj.SomeProperty
```

StructProperty arguments can be passed via table:
```lua
local color = {R = 0.0, G = 0.0, B = 1.0, A = 1.0}
obj:SomeColorFn(color)
```

Or via `StructObject.new(class)`.

Out arguments can be retrieved by passing an empty table:
```lua
local out = {}
obj:SomeOutFunction(out)

local result = out.result
```

### `object:__newindex(key: string, value: any)`

Wrapper for `object:set_property(key, value)`

ex:
```lua
obj.SomeProperty = 123
```

## Functions

### `UEVR_UObject.static_class()`

Returns the [UEVR_UClass*](UClass.md) descriptor for UObject.

### `obj:get_address()`

Returns the base address of the UObject.


### `obj:get_fname()`

Returns a [UEVR_FName](FName.md) object.

### `obj:get_full_name()`

Returns the full name of the UObject as a Lua string.

### `obj:is_a(class: UClass*)`

Returns true if the UObject is an instance of the specified class.

### `obj:as_class()`

Returns the UObject as an instance of [UEVR_UClass](UClass.md), or nil if it is not a class.

### `obj:as_struct()`

Returns the UObject as an instance of [UEVR_UStruct](UStruct.md), or nil if it is not a struct.

### `obj:as_function()`

Returns the UObject as an instance of [UEVR_UFunction](UFunction.md), or nil if it is not a function.

### `obj:get_class()`

Returns the [UEVR_UClass*](UClass.md) object of the UObject.

### `obj:get_outer()`

Returns the outer [UEVR_UObject*](UObject.md) of the UObject.

### `obj:get_property(name: string)`

Returns the value of the specified property of the UObject.

### `obj:set_property(name: string, value: any)`

Sets the value of the specified property of the UObject. Not all properties are supported.

### `obj:call(name: string, args...)`

Calls the specified function of the UObject with the specified arguments.

### `obj:DANGEROUS_call_member_virtual(index: int, rdx, r8, r9)`

Calls a virtual function at the specified index with the MSVC x64 calling convention.
