# UEVR: Blueprint API

UEVR implements some functions within the Unreal Engine's existing VR Blueprint API. These functions would usually do nothing because the VR plugins are not present. UEVR implements these functions so modders can easily access HMD and controller data without having to write a C++ plugin.

This should be more familiar to modders, and easier to use than the C++ API. Normal game developers should feel right at home as well.

It should be noted that generating the uproject for interacting with these games is out of UEVR's scope. There are other tools to assist in this, and others may have already generated one somewhere. 

UE4SS can assist in generating projects for blueprints.

Official modding tools by the game developers can work here too, if they provide a working uproject.

[Unreal Engine Modding Discord](https://discord.com/invite/eP72x2Hm)

[UE4SS Discord](https://discord.gg/MFvUysppTS)

## Automatically handled components

### Motion Controller components
### When UObjectHook is activated
All `UMotionControllerComponent` ("`Motion Controller`") components will have their location and rotation set correctly to the world transform of the user's motion controllers.

This means you can make `Motion Controller` components in Blueprint and UEVR will handle it for you, as long as you enable UObjectHook. You can then do any logic you wish with the Motion Controller transforms, like parenting a weapon mesh to one of them.

You must correctly set the `Motion Source` name to either `Left` or `Right`. Case sensitive. Or modify the `Hand` property on older UE versions.

`Motion Source` can be set to `Head` or `HMD` to track the HMD transform.

## Implemented functions

Tested and confirmed working on 4.27 and 5.0.3

`Load Blueprint Code` in the UEVR menu must be turned on or one of the head/controller aiming options must be enabled for these to work.

Some functions explicitly require `Load Blueprint Code` to be enabled, not just the aiming options.

For more information on these functions, visit the [Unreal Engine documentation](https://docs.unrealengine.com/4.27/en-US/BlueprintAPI/Input/HeadMountedDisplay/)

### Head Mounted Display: Is Head Mounted Display Enabled

Always works on < 4.18. >= 4.18, `Load Blueprint Code` must be explicitly enabled for this to work.

### Head Mounted Display: Get Device Pose

This one only works for the HMD for now. Bit of a hacky implementation, but it works.

### Head Mounted Display: Get Orientation And Position

Gets data about the HMD transform. `Load Blueprint Code` must be explicitly enabled for this to work on >= 4.18.

### Head Mounted Display: Get Motion Controller Data

Only works for left and right controller. 

`Valid`, `Aim Position`, `Aim Rotation`, `Grip Position`, `Grip Rotation` are implemented.

### Head Mounted Display: Get XRSystem Flags

Metadata used to inform blueprint about certain things.

```cpp
enum ECustomSystemFlags : int32_t {
    SYSTEMFLAG_NONE = 0,
    SYSTEMFLAG_HMD_ACTIVE = 1 << 0,
    SYSTEMFLAG_DECOUPLED_PITCH = 1 << 1,
    SYSTEMFLAG_OPENXR = 1 << 2,
    SYSTEMFLAG_OPENVR = 1 << 3,
    SYSTEMFLAG_MOTION_CONTROLLERS_ACTIVE = 1 << 4,
    SYSTEMFLAG_LEFT_THUMBREST_ACTIVE = 1 << 5,
    SYSTEMFLAG_RIGHT_THUMBREST_ACTIVE = 1 << 6,
    SYSTEMFLAG_GAME_AIMING_MODE = 1 << 7,
    SYSTEMFLAG_HEAD_AIMING_MODE = 1 << 8,
    SYSTEMFLAG_LEFT_CONTROLLER_AIMING_MODE = 1 << 9,
    SYSTEMFLAG_RIGHT_CONTROLLER_AIMING_MODE = 1 << 10,
    SYSTEMFLAG_TWO_HANDED_LEFT_AIMING_MODE = 1 << 11,
    SYSTEMFLAG_TWO_HANDED_RIGHT_AIMING_MODE = 1 << 12,
};
```

### Head Mounted Display: Get HMDData

Untested.

### Head Mounted Display: Reset Orientation

### Head Mounted Display: Reset Position

### Head Mounted Display: Reset Orientation and Position

