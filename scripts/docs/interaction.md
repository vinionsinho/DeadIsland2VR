# Interaction (Laser Pointer)

The interaction module provides VR interaction capabilities for UEVR mods, enabling laser pointer-based interaction with both UI widgets and 3D meshes in the game world.

## Overview

This module supports:

- **Widget Interaction**: Creates a `WidgetInteractionComponent` that can interact with Unreal Engine UI elements
- **Mesh Interaction**: Raycast against 3D geometry
- **Laser Pointer**: Visual feedback showing interaction direction
- **Mouse Control**: Optional mouse cursor synchronization

## Quick Start

### Basic Setup

```lua
local uevrUtils = require('libs/uevr_utils')
local interaction = require("libs/interaction")

-- remove the next three line for production mode
uevrUtils.setDeveloperMode(true)
uevrUtils.setLogLevel(LogLevel.Debug)
interaction.setLogLevel(LogLevel.Debug)

interaction.init()
```

### Register Hit Callbacks

```lua
interaction.registerOnHitCallback(function(hitResult)
    print("Hit at location:", hitResult.Location.X, hitResult.Location.Y, hitResult.Location.Z)
    print("Hit actor:", hitResult.Actor:get_full_name())
end)
```
<br>

## Configuration Interface
With interaction developer mode on, an "Interaction Config Dev" tab will appear in the UEVR UI. In the UI you can select from four types of interaction, "None", "Mesh", "Widget" or "Mesh and Widget".
<br>
### Laser
Each of the three Interaction Type choices "Mesh", "Widget" or "Mesh and Widget" can operate with no visible UI, but they will also allow you to enable a visible "laser" to see where the interaction element is pointing. To make the laser visible check the Show Laser checkbox. The color of the laser can also be changed to any color you wish.

### Mesh Interaction
Choosing Mesh interaction creates a vector whose source is either the left controller, right controller or head, depending on your selection in the 
"Attach To" combo. You can additionally adjust the position and rotation of the origin of the vector with respect to the controllers or head using the Location and Rotation sliders.
<br>
#### Interaction Distanc
Interaction Distance is the maximum length of the vector. When viewing the laser, the laser will never be longer than this length and if using hit testing, no hits will register further than this length.
<br>
#### Enable Hit Testing
Enable Hit Testing, when checked, will use LineTraceSingle to determine which objects in the world are being hit by the vector depending on the trace channel.
<br>
#### Trace Channel
Trace Channel determines what is hit by LineTraceSingle. Only objects configured to respond to the trace channel you have set will respond with a hit result when intersected by the vector
<br>
#### Callback function
With Enable Hit Testing checked, if you set up a <A href="https://github.com/jbusfield/uevrlib/edit/main/docs/interaction.md#register-hit-callbacks">callback function</A> as described above, that callback function will be called with the hit result when an object in the world is hit by the interaction vector.

<br><img width="691" height="696" alt="Screenshot 2025-11-26 105744" src="https://github.com/user-attachments/assets/8dfe62b9-9001-4853-a3e2-39dd6b77037f" />
<br><br>
### Widget Interaction
Choosing Widget interaction creates a UMG.WidgetInteractionComponent connected to the end of a vector whose source is either the left controller, right controller or head, depending on your selection in the "Attach To" combo. You can additionally adjust the position and rotation of the origin of the vector with respect to the controllers or head using the Location and Rotation sliders. The "Attach To", "Location" and "Rotation" setting is shared between Widget and Mesh interaction, so changing it for one type will change it for the other.
The Interaction Source, Pointer Index, Interaction Distance and Enable Hit Testing settings are all properties of, and documented by the <A href="https://dev.epicgames.com/documentation/en-us/unreal-engine/umg-widget-interaction-components-in-unreal-engine">Widget Interaction Component</A>
<br>
#### Trace Channel
The Trace Channel is probobably the most important setting for getting Widget Interaction to work. Widgets rarely respond to the default trace channel 0 but every game is different so it is likely you will have to step through every channel individually from 1-? until you find the channel where the widget actually responds. In Atomic Heart, for example, the channel is 23.
<br>
#### Interaction Depth Offset
In some games, noteably Atomic Heart, when pointing the interaction component at a Widget at a non-perpendicular angle, the interaction appears to happen "behind" the UI element of the widget. The Interaction Depth Offset setting corrects this by projecting a new plane between you and the interaction location that the vector can intersect, making the interaction feel more accurate with respect to the UI.

<br><img width="698" height="698" alt="Screenshot 2025-11-26 105652" src="https://github.com/user-attachments/assets/8358ef03-6b3e-4d91-835a-bceb5eb276ab" />

### Mesh and Widget Interaction
Choosing Mesh and Widget allows you to use both interaction methods at the same time and the properties described for both types individually still apply.

<br><img width="690" height="697" alt="Screenshot 2025-11-26 105802" src="https://github.com/user-attachments/assets/e4bb6317-49af-4f3b-8f10-3d77c59c9e29" />


