# UEVR_MotionControllerState

## Functions

{{func_doc
name: state:set_rotation_offset
args: offset: variant
description: Sets the rotation offset of the motion controller state.<br>`offset` can be a `UEVR_Quaternionf`, a `Vector4f`, or a `Vector3d`.
}}

{{func_doc
name: state:set_location_offset
args: offset: variant
description: Sets the location offset of the motion controller state.<br>`offset` can be a `UEVR_Vector3f`, a `Vector3f`, or a `Vector3d`.
}}

{{func_doc
name: state:set_hand
args: hand: int
description: Sets the hand of the motion controller state.<br>`hand` can be `0` for left hand or `1` for right hand, or `2` for the HMD.
}}

{{func_doc
name: state:set_permanant
args: permanent: bool
description: Sets the permanant flag of the motion controller state. Permanent meaning UObjectHook will not reset the rotation or location at the end of the tick.
}}