# UEVR_PluginInitializeParam

Accessed with `uevr.params`.

## Members

### `params.uevr_module`

The HMODULE of UEVR.

### `params.version`

The version of UEVR's plugin API.

Returns:
```c
typedef struct {
    int major;
    int minor;
    int patch;
} UEVR_PluginVersion;
```

### `params.functions`

Returns [UEVR_PluginFunctions](UEVR_PluginFunctions.md).

### `params.callbacks`

Returns [UEVR_PluginCallbacks](UEVR_PluginCallbacks.md).

### `params.renderer`

Returns [UEVR_RendererData](UEVR_RendererData.md).

### `params.vr`

Returns [UEVR_VRData](UEVR_VRData.md).

### `params.openvr`

Returns [UEVR_OpenVRData](UEVR_OpenVRData.md).

### `params.openxr`

Returns [UEVR_OpenXRData](UEVR_OpenXRData.md).

### `params.sdk`

Returns [UEVR_SDKData](UEVR_SDKData.md).
