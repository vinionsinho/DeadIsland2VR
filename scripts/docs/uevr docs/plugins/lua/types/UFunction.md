# UEVR_UFunction

## What is UFunction?

UFunction is a type that represents a function in Unreal Engine. Functions are usually associated with a UClass and can be called on instances of that class.

UFunction inherits all the functions from [UEVR_UStruct](UStruct.md).

## Functions

### `UEVR_UFunction.static_class()`

Returns the [UEVR_UClass*](UClass.md) descriptor for UFunction.

### `function:call(obj, args_ptr)`

Not implemented correctly. Do not use. Use `obj:FuncName(args...)` instead.

### `function:get_native_function()`

Returns the native function pointer of the UFunction as a `void*`.

### `function:hook_ptr(pre, post)`

Hooks the UFunction with the specified pre and post function pointers. Functions can be `nil` if you only want to use one but not the other.

Pre Signature: `bool pre(fn: UFunction*, obj: UObject*, locals: StructObject*, result: void*)`

Return `false` to skip the original function. Not returning at all is equivalent to returning `true`.

Post Signature: `void post(fn: UFunction*, obj: UObject*, locals: StructObject*, result: void*)`
