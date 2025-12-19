# lua

Can be accessed with `uevr.lua`.

Not accessible via `LuaVR.dll` (e.g. from UE4SS Lua). UEVR only.

## Methods

### `uevr.lua.add_script_panel(name, fn)`

Adds a script panel/sidebar that can be used to run [imgui](additional-bindings/imgui.md) code.

### Example

```lua
uevr.lua.add_script_panel("TEST!!!", function()
    imgui.text("test")
end)
```