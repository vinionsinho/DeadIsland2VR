# StructObject

StructObject is a custom UEVR Lua type that represents a struct in Unreal Engine. It's for non-UObject based structs which support reflection.

## Functions

### `StructObject.new(struct: UEVR_UStruct*)`

Constructs a new StructObject from a UEVR_UStruct pointer.

### `StructObject.new(object: UEVR_UObject*)`

Constructs a new StructObject from a UEVR_UObject pointer, if the object inherits from UStruct.