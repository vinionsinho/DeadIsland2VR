# UEVR_VRData

Accessed with `uevr.params.vr`

Static functions. Use `.` operator. Exception is `vr:get_mod_value`

## Functions

### `vr.is_runtime_ready()`

Returns true if the VR runtime is ready.

### `vr.is_openvr()`

Returns true if the VR runtime is OpenVR.

### `vr.is_openxr()`

Returns true if the VR runtime is OpenXR.

### `vr.is_hmd_active()`

Returns true if the HMD is active. Usually meaning the headset is on and tracking.

### `vr.get_standing_origin(out standing_origin: UEVR_Vector3f)`

Returns the standing origin of the HMD.

### `vr.get_rotation_offset(out rotation_offset: UEVR_Quaternionf)`

Returns the rotation offset of the HMD.

### `vr.set_standing_origin(standing_origin: UEVR_Vector3f)`

Sets the standing origin of the HMD.

### `vr.set_rotation_offset(rotation_offset: UEVR_Quaternionf)`

Sets the rotation offset of the HMD.

### `vr.get_hmd_index()`

Returns the index of the HMD.

### `vr.get_left_controller_index()`

Returns the index of the left controller.

### `vr.get_right_controller_index()`

Returns the index of the right controller.

### `vr.get_pose(index: number, out position: UEVR_Vector3f, out rotation: UEVR_Quaternionf)`

Returns the pose of the specified device.

### `vr.get_transform(index: number, out transform: UEVR_Transform)`

Returns the transform of the specified device.

### `vr.get_eye_offset(index: number, out eye_offset: UEVR_Vector3f)`

Returns the eye offset of the specified eye.

### `vr.get_ue_projection_matrix(index: number, out projection_matrix: UEVR_Matrix4f)`

Returns the projection matrix of the specified eye.

### `vr.get_left_joystick_source()`

Returns the source handle of the left joystick.

### `vr.get_right_joystick_source()`

Returns the source handle of the right joystick.

### `vr.get_action_handle(action_name: string)`

Returns the handle of the specified action.

### `vr.is_action_active(action_handle: UEVR_ActionHandle, source: UEVR_InputSourceHandle)`

Returns true if the specified action is active.

### `vr.is_action_active_any_joystick(action_handle: UEVR_ActionHandle)`

Returns true if the specified action is active.

### `vr.get_joystick_axis(index: number, out axis: UEVR_Vector2f)`

Returns the axis of the specified joystick.

### `vr.trigger_haptic_vibration(seconds_from_now: number, duration: number, frequency: number, amplitude: number, source_handle: number)`

Triggers haptic vibration on the specified device.

### `vr.is_using_controllers()`

Returns true if the VR system is using controllers within the past 30 seconds.

### `vr.get_lowest_xinput_index()`

### `vr.recenter_view()`

Recenters the view.

### `vr.recenter_horizon()`

Recenters the horizon.

### `vr.get_aim_method()`

Returns the aim method as an integer.

### `vr.set_aim_method(aim_method: number)`

Sets the aim method.

### `vr.is_aim_allowed()`

Returns true if aiming is allowed.

### `vr.set_aim_allowed(aim_allowed: bool)`

Sets whether aiming is allowed.

### `vr.get_hmd_width()`

Returns the render width of the HMD.

### `vr.get_hmd_height()`

Returns the render height of the HMD.

### `vr.get_ui_width()`

Returns the render width of the UI.

### `vr.get_ui_height()`

Returns the render height of the UI.

### `vr.is_snap_turn_enabled()`

Returns true if snap turning is enabled.

### `vr.set_snap_turn_enabled(snap_turn_enabled: bool)`

Sets whether snap turning is enabled.

### `vr.set_decoupled_pitch_enabled(decoupled_pitch_enabled: bool)`

Sets whether decoupled pitch is enabled.

### `vr.set_mod_value(name: string, value: string)`

Sets the value of the specified mod.

### `vr:get_mod_value(name: string)`

Returns the value of the specified mod as a Lua string.

This is a special function that requires use of `:` instead of `.` because it uses a custom function, not the original function.

### `vr.save_config()`

Saves the configuration.

### `vr.reload_config()`

Reloads the configuration.

