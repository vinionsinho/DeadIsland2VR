# Controller Remapping
## Quick Start

### Basic Setup

```lua
local uevrUtils = require('libs/uevr_utils')
local remap = require("libs/remap")

-- remove the next three line for production mode
uevrUtils.setDeveloperMode(true)
uevrUtils.setLogLevel(LogLevel.Debug)
remap.setLogLevel(LogLevel.Debug)

remap.init()
```

## Examples
Rename the file "example_remap.luax" as "example_remap.lua" or "example_remap_ui.luax" as "example_remap_ui.lua" if required and rename all other examples to ".luax"

## Configuration Interface
With interaction developer mode on, a "Remap Config Dev" tab will appear in the UEVR UI. You can have multiple remap profiles and each can be edited separately by selecting the Remap Profile from the combo. At the bottom of the UI you can Create a New Profile, duplicate the currently selected profile, or delete the currently selected profile.

Under Remap Input Configuration is a list of all of the buttons that can be remapped for the controllers. Button colored blue signify that the button has a remapping. When opening the tree for any button you will see a list of all the new actions that the button can perform. You can also indicate that the button will not perform its original action (usually what you will want) by checking "Unpress Original Input". When a button has actions actually configured, the Actions label will turn blue.
<br>
<br><img width="748" height="1381" alt="Screenshot 2025-11-26 122905" src="https://github.com/user-attachments/assets/11ed40d2-3b3b-4180-b549-f133845fece5" />

### Using Copy Value with Sticks
When remapping the Left or Right Stick X or Y, you will have the option to "Copy Value" so that the Left Stick X can behave as if the Right Stick X is being moved, etc.
<br>
<br><img width="378" height="691" alt="remap1" src="https://github.com/user-attachments/assets/46d18a9d-7ebd-459d-ae04-3c7ec03836db" />

### Pressing vs Toggling
When you use the "While Pressed" or "While Active" behaviors, the action will fire the entire time the original button state is being updated. In contrast, using the "When Toggled On" or "When Toggled Active" behavior will only fire once, when the button state changes from on to off, or off to on. Which type you use will depend on the game and what you are trying to accomplish.
<br>
<br><img width="761" height="1373" alt="Screenshot 2025-11-26 125729" src="https://github.com/user-attachments/assets/fbb08420-11b6-4aae-9408-c5efed24e254" />
