# Dead Island 2 UEVR Plugin

> [!IMPORTANT]
> ### 🛑 Please Read: Recommended Profile Update
> **[jbusfield](https://github.com/jbusfield)** (who originally authored many of the underlying VR libraries used here) has released a significantly more advanced and complete profile for Dead Island 2:  
> 👉 **[https://github.com/jbusfield/DI2_UEVR](https://github.com/jbusfield/DI2_UEVR)**
>
> His profile solves virtually all the major limitations present in this early release, including:
> * **Fully functional knives, thrusting weapons, and brass knuckles**;
> * **Native melee sweep integration** (consistent hit registration with stamina/flesh dismemberment);
> * **Dual-wielding and Fury Mode support**;
> * **Weapon physics collisions with zombie ragdolls and severed limbs**.
>
> **I strongly recommend using jbusfield's profile for the definitive Dead Island 2 VR playthrough.**  
> This repository will remain available for historical reference and to host standalone add-on scripts/plugins (such as custom wheel interactions or extra experimental features) that can be used alongside or on top of jbusfield's build. I will no longer be accepting donations related to Dead Island 2 VR.

---

## About This Project (Legacy Overview)

This was an early hybrid Lua mod designed to bring full 6DOF VR support to Dead Island 2 using UEVR. It implemented physical melee combat, motion controls, and various quality-of-life fixes.

### VR Mod Features

* **Full 6DOF Motion Controls:** Decoupled head and hand movement.
* **Physical Melee:** Swing your controllers to hit zombies.
* **Floating Hands:** Includes trigger animations (using jbusfield's hand assets).
* **VR Charged Attacks:** Implemented via gesture mechanics (inspired by Markmon Avowed script).
* **Dynamic Rendering:** Automatically changes the rendering method when needed (implementation by Letmein50).
* **Smart Cutscene Handling:** Automatically reverts to standard game input during cutscenes to prevent clipping and unintended displacement.
* **Head-Mounted Flashlight:** The flashlight follows your gaze (HMD) rather than the right controller for better visibility.

---

## ⚠️ Important Gameplay Notes

* **Interacting with NPCs:** To talk to characters, especially ones far away, you must **physically point your hand** at them.
* **Unsupported Weapons (in this legacy build):** Thrusting weapons (Knives, Spears, Forks, etc.) do not work well with this physics system (use [jbusfield's mod](https://github.com/jbusfield/DI2_UEVR) for full knife support).
* **DLC Weapons:** Attachments for DLC weapons have not been configured in this version.

### ⚠️ CRITICAL REQUIREMENT: **Disable HDR in game settings**. Failing to do so will cause a black screen artifact on your right hand/view.

---

## Controls & Mechanics

### 💥 How to use Charged Attacks
Charged attacks use a custom gesture system:
1. Hold your **Right Hand** next to your HMD (Headset)—either side works.
2. Wait for the controller to **vibrate**.
3. Once the vibration ends, **swing quickly** to unleash a charged attack.  
   *(Note: You have to be quick!)*

### 🎮 D-Pad Access
Since the buttons are remapped for VR interaction, the D-Pad is accessed via a combo:
* **Hold Left Thumbrest + Move Right Stick** = D-Pad Input.

### 🎒 Character Menu & Inventory
To access the main menu or inventory:
1. Press and **Hold** the **Left Menu Button** (the small button with three lines `≡`).
2. Wait for about **1 second**.
3. **Release** the button to open the menu.

---

## 🛠️ Weapon Positioning Guide

If you pick up a weapon that looks misaligned:
1. Open the UEVR Menu.
2. Go to **LuaLoader** > **Attachments Config**.
3. Look for the currently equipped weapon (text highlighted in **Blue**).
4. Select the **Grip Animation** that is most adequate for the weapon (usually "Melee").
5. Adjust the **Position** and **Rotation** sliders until it fits your hand naturally.
6. **Important:** Check the box **"Use for all children"** so it applies across all weapons of that type.

---

## Installation

1. Install the latest nightly build of UEVR.
2. Download the Mod `.zip` file located in the Releases section.
3. Import the Config into UEVR (`Import Config`).
4. Inject the game with UEVR.

### ⚠️ Injection Troubleshooting

Injecting UEVR into Dead Island 2 can occasionally be inconsistent:
* **Wait a few seconds:** After clicking "Inject", give it 10–15 seconds to hook properly.
* **Retry if needed:** If it fails to hook on the first try, close the game completely and launch again.

---

## Credits

* **Praydog:** For the incredible UEVR tool.
* **Jbusfield:** For the attachment system, hand assets, helper libraries, and the new definitive profile.
* **Letmein50:** For the dynamic rendering method fix.
* **Markmon:** For the charged attack logic.

