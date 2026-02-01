# Dead Island 2 UEVR Plugin

This is a hybrid Lua mod designed to bring full 6DOF VR support to Dead Island 2 using UEVR. It implements physical melee combat, motion controls, and various quality-of-life fixes to make the game playable in VR.

## VR Mod Features

* **Full 6DOF Motion Controls:** Decoupled head and hand movement.
* **Physical Melee:** Swing your controllers to hit zombies.
* **Floating Hands:** Includes trigger animations (using jbusfield's hand assets).
* **VR Charged Attacks:** Implemented via gesture mechanics (inspired by Markmon Avowed script).
* **Dynamic Rendering:** Automatically changes the rendering method when needed (implementation by Letmein50).
* **Smart Cutscene Handling:** Automatically reverts to standard game input during cutscenes. This prevents VR controller inputs from accidentally moving the character off the intended path or clipping through geometry.
* **Head-Mounted Flashlight:** The flashlight follows your gaze (HMD) rather than the right controller for better visibility.

## ⚠️ Important Gameplay Notes

Please read this section before playing to understand current limitations and mechanics:

* **Interacting with NPCs:** To talk to characters, especially ones far away, you must **physically point your hand** at them.
* **Unsupported Weapons:** Thrusting weapons (Knives, Spears, Forks, etc.) do not work well with the current physics system. I do not plan to fix this, so please stick to bludgeoning or slashing weapons.
* **DLC Weapons:** Attachments for DLC weapons have not been configured yet.

### ⚠️ CRITICAL REQUIREMENT: **Disable HDR in game settings**. Failing to do so will cause a black screen artifact on your right hand/view.

## Controls & Mechanics

### 💥 How to use Charged Attacks
Charged attacks use a custom gesture system:
1.  Hold your **Right Hand** next to your HMD (Headset)—either side works.
2.  Wait for the controller to **vibrate**.
3.  Once the vibration ends, **swing quickly** to unleash a charged attack.
    *(Note: You have to be quick!)*

### 🎮 D-Pad Access
Since the buttons are remapped for VR interaction, the D-Pad is accessed via a combo:
* **Hold Left Thumbrest + Move Right Stick** = D-Pad Input.

### 🎒 Character Menu & Inventory
To access the main menu or inventory, a specific timing is required:
1.  Press and **Hold** the **Left Menu Button** (the small button with three lines `≡`).
2.  Wait for about **1 second**.
3.  **Release** the button to open the menu.


## 🛠️ Weapon Positioning Guide

If you pick up a weapon that looks misaligned, you can fix it in-game using the UEVR menu.

1.  Open the UEVR Menu.
2.  Go to **LuaLoader** > **Attachments Config**.
3.  Look for the currently equipped weapon (the text will be highlighted in **Blue**).
4.  Select the **Grip Animation** that is most adequate for the weapon (usually "Melee").
5.  Adjust the **Position** and **Rotation** sliders until it fits your hand naturally.
6.  **Important:** Check the box **"Use for all children"**. This ensures the setting applies to other weapons of the same class/type.

## Installation

1.  Install the latest nightly build of UEVR.
2.  Download the Mod `.zip` file located in the Releases section of this page.
3.  Import the Config into UEVR (Import Config).
4.  Inject the game with UEVR.

### ⚠️ Injection Troubleshooting (Read Me!)

Please note that injecting UEVR into Dead Island 2 can be **inconsistent**.

* **It might not work on the first try:** If the injection fails or nothing happens, don't panic. This is a known quirk.
* **Give it time:** After clicking "Inject", wait a few seconds (10–15s) to see if the VR mode initializes. It's not always instant.
* **Try again:** If it fails, close the game completely and try again. It often takes a couple of attempts to get a successful hook.

## Credits

* **Praydog:** For the incredible UEVR tool, without which this mod wouldn't exist.
* **Letmein50:** For the dynamic rendering method fix.
* **Jbusfield:** For the attachment system, hand assets, and general helper library.
* **Markmon:** For the charged attack logic.

## Support

This mod is free and open to everyone. If you enjoy the work I put into making **Dead Island 2** playable in VR and would like to support me, you can buy me a coffee! It helps keep me motivated to fix bugs and create more mods.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/vinion)

*Note: This mod utilizes community libraries. Donations are purely for my time spent scripting, testing, and configuring the specific implementation for this game.*
