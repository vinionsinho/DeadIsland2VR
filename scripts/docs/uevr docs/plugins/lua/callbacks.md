# uevr.sdk.callbacks

## Functions

### `uevr.sdk.callbacks.on_xinput_get_state(fn)`
Registers a callback to be called when XInput state is requested.

Prototype: `function(retval: uint32, user_index: uint32, state: XINPUT_STATE*)`

[XINPUT_STATE](thirdparty/XINPUT_STATE.md)

### `uevr.sdk.callbacks.on_xinput_set_state(fn)`

Registers a callback to be called when XInput state is set.

Prototype: `function(retval: uint32, user_index: uint32, state: XINPUT_VIBRATION*)`

[XINPUT_VIBRATION](thirdparty/XINPUT_VIBRATION.md)

### `uevr.sdk.callbacks.on_pre_engine_tick(fn)`

Registers a callback to be called before the engine tick.

Prototype: `function(engine: void*, delta_time: float)`

### `uevr.sdk.callbacks.on_post_engine_tick(fn)`

Registers a callback to be called after the engine tick.

Prototype: `function(engine: void*, delta_time: float)`

### `uevr.sdk.callbacks.on_pre_slate_draw_window_render_thread(fn)`

Registers a callback to be called before the slate window is drawn on the render thread.

Prototype: `function(renderer: UEVR_FSlateRHIRendererHandle, viewport_info: UEVR_FViewportInfoHandle)`

### `uevr.sdk.callbacks.on_post_slate_draw_window_render_thread(fn)`

Registers a callback to be called after the slate window is drawn on the render thread.

Prototype: `function(renderer: UEVR_FSlateRHIRendererHandle, viewport_info: UEVR_FViewportInfoHandle)`

### `uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(fn)`

Registers a callback to be called before VR transformations are applied to the view.

Prototype: `function(device: UEVR_StereoRenderingDeviceHandle, view_index: int, world_to_meters: float, position: Vector3f* or Vector3d*, rotation: Quaternionf* or Quaterniond*, is_double: bool)`

### `uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(fn)`

Registers a callback to be called after VR transformations are applied to the view.

Prototype: `function(device: UEVR_StereoRenderingDeviceHandle, view_index: int, world_to_meters: float, position: Vector3f* or Vector3d*, rotation: Quaternionf* or Quaterniond*, is_double: bool)`

### `uevr.sdk.callbacks.on_pre_viewport_client_draw(fn)`  

Registers a callback to be called before the viewport is drawn on the game thread.

Prototype: `function(viewport: UEVR_FViewportClientHandle, viewport: UEVR_FViewportHandle canvas: UEVR_FCanvasHandle)`

### `uevr.sdk.callbacks.on_post_viewport_client_draw(fn)`

Registers a callback to be called after the viewport is drawn on the game thread.

Prototype: `function(viewport: UEVR_FViewportClientHandle, viewport: UEVR_FViewportHandle canvas: UEVR_FCanvasHandle)`

### `uevr.sdk.callbacks.on_frame(fn)`

Registers a callback to be called every frame. For ImGui functionality.
Prototype: `function()`

### `uevr.sdk.callbacks.on_draw_ui(fn)`

Registers a callback to be called when the UI is drawn. For ImGui functionality that should be constrained to the UEVR window.

### `uevr.sdk.callbacks.on_script_reset(fn)`

Registers a callback to be called when the Lua script is reset. Script cleanup should be performed here.

### `uevr.sdk.callbacks.on_lua_event(fn)`

Registers a callback that can be triggered when a C plugin dispatches an event for Lua.

Prototype: `function(event_name: string, event_data: string)`
