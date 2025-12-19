# Attachments (Weapons)

## Setup

Rename the file "example_attachments.luax" as "example_attachments.lua" if required and rename all other examples to ".luax". Go to a point in the game where the character is actually holding a weapon or attachment in its hand.

Every game handles attachments (weapons) differently and so you as a modder will have to determine how to access the weapon meshes for your particular game.

The example_attachments.lua file contains examples of obtaining the meshes for various games such as Atomic Heart, Robocop and Outer Worlds.

## Configuration UI Setup
The Attachments Config Dev tab in the UEVR UI explains that you will have to create this function in order to use the attachments wizard.

<img width="696" height="698" alt="Screenshot 2025-11-16 125411" src="https://github.com/user-attachments/assets/ca8cf5e7-ef75-4210-bcab-7d183186059a" />
<br><br>

Once you have the callback function set up, any time you switch to a new attachment or weapon in the game, a new entry for that weapon will automatically show up in the Attachment Config Dev tab.

Now you can interactively update the Location, Rotation and Scale of the attachment. Checkboxes allow you to specify that a weapon is a Melee weapon, a Scoped Weapon and/or a Two Handed weapon.

<img width="694" height="699" alt="Screenshot 2025-11-16 125516" src="https://github.com/user-attachments/assets/bb6b4edf-4113-4670-9404-57eb561ed3d5" />
<br><br>

## Accessing Attachments Boolean States
You can query the attachments module programmatically for that information at runtime using the following functions:

```lua
attachments.isActiveAttachmentMelee(hand) - checks if the attachment gripped by the specified hand is marked as melee
    example:
        local isMelee = attachments.isActiveAttachmentMelee(Handed.Right)

attachments.isActiveAttachmentScoped(hand) - checks if the attachment gripped by the specified hand is marked as scoped
    example:
        local isScoped = attachments.isActiveAttachmentScoped(Handed.Right)

attachments.isActiveAttachmentTwoHanded(hand) - checks if the attachment gripped by the specified hand is marked as two-handed
    example:
        local isTwoHanded = attachments.isActiveAttachmentTwoHanded(Handed.Right)
```

## Hands Integration

If you created Hands for your game using the Hands Creation Wizard, and you added different animation grips for different weapons, you will be able to select from the various grips you created there using the Grip Animation dropdown.

Switch to other weapons within the game to see more entries appear in the Config UI

<img width="699" height="703" alt="Screenshot 2025-11-16 125758" src="https://github.com/user-attachments/assets/049663b9-20f2-42fe-923c-dc9052197a0b" />
<br><br>

## Using the registerOnGripUpdateCallback Function
Use of the registerOnGripUpdateCallback function that is used in the example files is documented in attachments.lua but here is the definition from that file
```lua
--[[
    attachments.registerOnGripUpdateCallback(callback) - registers a callback function that handles automatic grip updates.
		Your callback will be called periodically to request the item that is being gripped in the right or left hand as
		well as the mesh or component being used for the right and left hands. If no item is currently being gripped then return nil.
        If rightMesh or leftMesh are nil then the attachments will be directly attached to the raw controller instead of a component.
		Return parameters are rightAttachment, rightMesh, rightSocketName, leftAttachment, leftMesh, leftSocketName, detachFromParent, allowReattach
		rightAttachment - the object being held in the right hand (or nil if nothing is held)
		rightMesh (optional) - the mesh or component to attach the right attachment to (or nil to attach to raw controller)
		rightSocketName (optional) - the socket name on the right mesh to attach to (or nil for no socket)
		leftAttachment (optional) - the object being held in the left hand (or nil if nothing is held)
		leftMesh (optional) - the mesh or component to attach the left attachment to (or nil to attach to raw controller)
		leftSocketName (optional) - the socket name on the left mesh to attach to (or nil for no socket)
		detachFromParent (optional) - boolean value indicating whether to detach the attachment from its current parent before attaching. Defaults to true
		allowReattach (optional) - boolean value indicating whether to allow reattaching the attachment to its previous parent when detaching from the current mesh/controller. Defaults to false
			Note that when attaching to raw controller, allowReattach is passed to set_permanent() function of UEVR_UObjectHook so
			if you dont want permananent attachment to controller (eg the object will be thrown), allowReattach should be false.
		example:
			attachments.registerOnGripUpdateCallback(function()
				if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
					local currentWeapon = pawn:GetCurrentWeapon()
					if currentWeapon ~= nil and currentWeapon.RootComponent ~= nil then
						return currentWeapon.RootComponent, hands.getHandComponent(Handed.Right), nil, nil, nil, nil, true
					end
				end
			end)
]]--
```

In the example file we are attaching directly to the raw controller with:

```lua
attachments.registerOnGripUpdateCallback(function()
    return getWeaponMesh()
end)
```

This means the mesh attaches using UEVR_UObjectHook.get_or_add_motion_controller_state(attachment)

You can also attach to a MotionControllerComponent by doing:

```lua
attachments.registerOnGripUpdateCallback(function()
    return getWeaponMesh(), controllers.getController(Handed.Right)
end)
```

<br>

If you have created hands you can also attach a weapon directly to the hands mesh by doing:

```lua
attachments.registerOnGripUpdateCallback(function()
    return getWeaponMesh(), hands.getHandComponent(Handed.Right)
end)
```

and you can attach to a socket on the hands as well using the socket parameters of the callback. See the documentation above for more information.

## Game-Specific Considerations

Which type of attachment you use depends on the game. Most games are fine with attaching to a MotionControllerComponent or hands mesh but some may require a raw controller attachment to be stable.

Also note that in the example file we called for Outer Worlds:

```lua
attachments.init(nil, nil, {0,0,0}, {0,-90,0}) --all attachments in OW have a 90 degree yaw offset so compensate here rather than manually for every individual weapon in the config ui
```

When attaching to the raw controller the yaw is offset by 90 degrees for all weapons. However, if you try attaching to the MotionControllerComponent, there is no 90 degree offset and you could use:

```lua
attachments.init()
```

Setting default locations, rotations and scales in init is just a convenience. You can also just adjust the transforms in the Attachments Wizards manually each time a new one is added.

## Production Deployment

When you configure your weapons, settings are persisted in the profile's data folder. You can therefore remove the:

```lua
uevrUtils.setDeveloperMode(true)
attachments.setLogLevel(LogLevel.Debug)
uevrUtils.setLogLevel(LogLevel.Debug)
```

lines where you are completely finished configuring your game.

