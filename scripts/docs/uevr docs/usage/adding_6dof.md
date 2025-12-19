# UEVR: UObjectHook

## What is UObjectHook?

UObjectHook is an extra part of UEVR that can be used to do many things, such as:

* Attach the camera to any object or component in the game
* Add 6DoF motion controls by attaching any components to the motion controllers
    * This is usually contingent on the 3DoF motion controls working in the first place
* Modify and view any property of any active UObject in the game
  * This can be saved by right clicking the property
* Toggle the visibility of any component in the game
* Save the state of all of the above for persistence across sessions

## Important information

UObjectHook is not enabled by default. When giving out profiles, ensure you have "Enabled at Startup" enabled under UObjectHook's config tab.

If a profile received does not work, it is likely because of the above. UObjectHook is not enabled by default, so you need to manually open the UObjectHook menu to enable it if this is the case.

## Examples

In the following examples, we'll be using the "First Person Template" from the Unreal Engine.

These are just the simplest examples possible. There are games that will have differently named components. Sometimes you'll need to go through multiple component lists, children, or properties. You'll usually want to be on the lookout for SkeletalMeshComponent components for attachments.

## Attaching the camera to an object

<video width="640" height="480" controls>
<source src="videos/camera_attach.mp4" type="video/mp4">
</video>

In this example, we'll attach the camera to the local player/pawn.

1. Open the in-game menu and enable advanced options if not already enabled
2. Navigate to UObjectHook on the left side
3. Go to "Common Objects"
4. Go to "Acknowledged Pawn"
5. Click "Attach Camera to" (click "Attach Camera to (Relative)" if the game is already first-person)
6. Click "Save State"

Doing this allows you to turn third person games into first person games. If done in a first person game, this removes unwanted camera movement that should not be there in VR.

## Attaching components to motion controllers

<video width="640" height="480" controls>
<source src="videos/component_attach.mp4" type="video/mp4">
</video>

In this example, we'll attach a component(s) to the motion controllers.

1. Open the in-game menu and enable advanced options if not already enabled
2. Navigate to UObjectHook on the left side
3. Go to "Common Objects"
4. Go to "Acknowledged Pawn"
5. Go to "Components"
5. Click "SkeletalMeshComponent Mesh2P" and uncheck "Visible"
6. Click "SkeletalMeshComponent FP_Gun"
7. Click "Attach right" or "Attach left" depending on which controller you want to attach to
8. Click "Adjust"
9. The menu will close, move your controller so that it lines up with the gun in-game
10. Open the menu again, and the weapon should be attached to the controller with the correct offset
11. Now click "Permanent Change", this will allow the projectiles to fire from the correct location
11. Click "Save State"
12. Navigate to "Input" on the left side
13. Change the "Aim Method" to "Left Controller" or "Right Controller" depending on which controller you attached the weapon to
14. You should now have full 6DoF motion controls for the weapon

## Glossary

### Permanent Change

This means that UEVR will no longer reset the object back to its original position and rotation after rendering is over. This can make projectiles come out of the correct spot with weapons, and make things like colliders work with melee weapons (if they have them).

It is not enabled by default because the user can inadvertently set this option on something that dictates their player position, launching them out of the map.
