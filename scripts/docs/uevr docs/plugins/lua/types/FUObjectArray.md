# UEVR_FUObjectArray

## What is FUObjectArray?

FUObjectArray is a struct that contains a list of all UObject instances in Unreal Engine.

## Functions

### `UEVR_FUObjectArray.get()`

Returns the instance of the FUObjectArray.

### `arr:is_chunked()`

Returns true if the array is chunked.

### `arr:is_inlined()`

Returns true if the array is inlined.

### `arr:get_objects_offset()`

Returns the offset of the objects in the array.

### `arr:get_item_distance()`

Returns the distance between items in the array.

### `arr:get_object_count()`

Returns the number of objects in the array.

### `arr:get_objects_ptr()`

### `arr:get_object(index: number)`

Returns the [UEVR_UObject*](UObject.md) object at the specified index.

### `arr:get_item(index: number)`

Returns the [UEVR_FUObjectItem*](FUObjectItem.md) object at the specified index.