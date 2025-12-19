# UEVR

Welcome to [UEVR](https://github.com/praydog/UEVR)! This powerful tool will transform your favorite Unreal Engine games into 6DOF VR experiences with minimal effort.

UEVR can be downloaded from [here](https://github.com/praydog/UEVR/releases).

## Supported Engine Versions

- Unreal Engine 4.8 - 5.4

## Supported Graphics APIs

- Direct3D 11
- Direct3D 12

## Features

- Full 6DOF support out of the box (HMD movement)
- Full stereoscopic 3D out of the box
- Frontend GUI for easy process injection
- Supports OpenVR and OpenXR runtimes
- Native UE4/UE5 stereo rendering system for a truly immersive VR experience
- 3 rendering modes: Native Stereo, Synchronized Sequential, and Alternating/AFR
- Optional 3DOF motion controls in many games, essentially emulating a semi-native VR experience
- Optional roomscale movement in many games, moving the player character itself in 3D space along with the headset
- User-authored UI-based system for adding motion controls and first person to games that don't support them
- Automatic handling of most in-game UI so it is projected into 3D space
- In-game menu with shortcuts for adjusting settings
- Access to various CVars for fixing broken shaders/effects
- Optional depth buffer integration for improved latency on some headsets
- Per-game configurations
- [C++ Plugin system](https://praydog.github.io/uevr-docs/plugins/getting_started.html) and [Blueprint support](https://praydog.github.io/uevr-docs/plugins/blueprint.html) for modders to add additional features like motion controls

## Reporting a bug

Click "Open Global Dir" in the frontend. Browse to the corresponding game folder that is having an issue and zip up the folder and upload it for us. Clicking "Export Config" is an alternative here to do this automatically.

You can then describe the issue and upload the file for us on the [Issues](https://github.com/praydog/UEVR/issues).

You can read the full instructions when making an issue, choose the [bug report template](https://github.com/praydog/UEVR/blob/master/.github/ISSUE_TEMPLATE/bug_report.md).

## Getting Started

Before launching, ensure you have installed .NET 6.0. It should tell you where to install it upon first open, but if not, you can [download it from here](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)

Anti-viruses may delete files required to run from UEVR at this time. You may need to whitelist the UEVR directory and un-quarantine any files the anti-virus may have deleted.

1. Launch UEVRInjector.exe
2. Launch the target game
3. Locate the game in the process dropdown list
4. Select your desired runtime (OpenVR/OpenXR)
5. Configure pre-injection settings
6. Inject

## To-dos before injection

### Double check that the game you are injecting into has no Anti-Cheat mechanisms. If you are not sure, assume that all multiplayer games have Anti-Cheat, and do not attempt to inject into them. The exception here is if it can be disabled in some way to play offline.

1. Disable HDR (it will still work without it, but the game will be darker than usual if it is)
2. Start as administrator if the game is not visible in the list
3. Pass `-nohmd` to the game's command line and/or delete VR plugins from the game directory if the game contains any existing VR plugins
4. Disable any overlays that may conflict and cause crashes (Rivatuner, ASUS software, Razer software, Overwolf, etc...)
6. Disable graphical options in-game that may cause crashes or severe issues like DLSS Frame Generation
7. Consider disabling `Hardware Accelerated GPU Scheduling` in your Windows `Graphics settings`

## Quick troubleshooting

There are some games that work pretty much perfectly out of the box, and others will need tinkering.

* If there are major graphical bugs or crashing, change the rendering method to Synced Sequential and check if the issue goes away
* If there is still crashing, there are various Compatibility options that can be enabled (Advanced View shows them, or can be seen in the frontend)
  * Do not enable Extreme Compatibility Mode, only as a last resort
* If there are still graphical bugs present, enable Advanced View and tweak the CVars
  * INI tweaks can work here as well
* If the game is locked to 60 FPS (even in flat), disable ASW/motion smoothing so the game doesn't slow down due to the runtime halving the framerate
* If the game is running poorly, lower the in-game settings, lower the resolution in the UEVR interface or SteamVR
* If there is rapid flickering or extreme lag, this likely indicates that DLSS Frame Generation is enabled, turn it off or disable `Hardware Accelerated GPU Scheduling` in your Windows `Graphics settings`.
* OpenXR Toolkit may also need to be disabled if there is even more crashing or lag

If all fails, someone may have came up with a config for the game or can help you on the [Flat2VR Discord](http://flat2vr.com).

## If there is rotational judder/lag

There's a few reasons for this and fixes for it:

* If using Virtual Desktop, you must use OpenXR to prevent lag when rotating your head, OpenVR simply does not work correctly right now with Virtual Desktop
    * The `Virtual Desktop fix` must be enabled if it isn't getting enabled (under Runtime)
* You can also disable `r.OneFrameThreadLag` under `Console/CVars` (advanced view must be enabled)
* You can also modify the `Frame Delay Compensation` under Debug (advanced view must be enabled) 

## In-Game Menu

Press the **Insert** key or **L3+R3** on a controller to access the in-game menu, which opens by default at startup. With the menu open, hold **RT** for various shortcuts:

- RT + Left Stick: Move the camera left/right/forward/back
- RT + Right Stick: Move the camera up/down
- RT + B: Reset camera offset
- RT + Y: Recenter view
- RT + X: Reset standing origin

## Help! What games are Unreal Engine?

Use tools like [Rai Pal](https://github.com/Raicuparta/rai-pal/). 

Rai Pal is a tool by [Raicuparta](https://github.com/Raicuparta) that can go through your entire library of games and attempt to tell you what engine, and what version of that engine they are using. 

It also has some level of support for UEVR for automatic launching, as well as displaying user scores given to the VR compatibility of a given game.

Alex also has made a [spreadsheet of supported games](https://docs.google.com/spreadsheets/d/1ZcjCQwzPOltaRZnpYU5_HPihEDareZq_0Ww1DZQ4USw/edit#gid=0) and how well they function, and various other metrics.

## Quick overview of rendering methods

### Native Stereo

When it works, it looks the best, performs the best (usually). Can cause crashes or graphical bugs if the game does not play well with it.

Temporal effects like TAA are fully intact. DLSS/FSR2 usually work completely fine with no ghosting in this mode.

Fully synchronized eye rendering. Works with the majority of games. Uses the actual stereo rendering pipeline in the Unreal Engine to achieve a stereoscopic image.

### Synchronized Sequential

This is the first alternative option that should be used if Native Stereo is not working as expected or you are encountering graphical bugs. It should be noted that this mode gives worse performance than Native Stereo.

A form of AFR. Can fix many rendering bugs that are introduced with Native Stereo. Renders two frames **sequentially** in a **synchronized** fashion on the same engine tick.

Fully synchronized eye rendering. Game world does not advance time between frames.

Looks normal but temporal effects like TAA will have ghosting/doubling effect. Motion blur will need to be turned off.

**Skip Draw** skips the viewport draw on the next engine tick. Usually works the best but sometimes particle effects may not play at the correct speed.

**Skip Tick** skips the next engine tick entirely. Usually buggy but does fix particle effects and sometimes brings higher performance.

### AFR

Alternated Frame Rendering. Renders each eye on separate frames in an alternating fashion, with the game world advancing time in between frames. Causes eye desyncs and usually nausea along with it.

Not synchronized. Generally should not be used unless the other two are unusable in some way.

## Overview of UEVR usage by Alex

[![video](https://i.ytimg.com/vi/G8HHjTjbQFE/hqdefault.jpg)](https://www.youtube.com/watch?v=CW60zLLo2fw&list=PLyE0aREJRIBLMQREfAFXKSQydoI-h4Vfh)

[Getting started spreadsheet by Alex](https://docs.google.com/spreadsheets/d/1ZcjCQwzPOltaRZnpYU5_HPihEDareZq_0Ww1DZQ4USw/edit#gid=0)

## Additional information

Read the [Detailed overview](usage/overview.md) for a comprehensive guide on how to fine-tune your VR experience.

Head over to the [Flat2VR Discord](http://flat2vr.com).

## Special thanks

* [TheNewJavaman](https://github.com/TheNewJavaman) - Developer of the previous Unreal VR project.

To all the testers. These include:

* [Brian Tate](https://twitter.com/Flat2VR) - Founder of the Flat2VR community. He is the catalyst that kicked off this project. He was digging around and found out that most of the stereo pipeline is left in the engine.

* [Alex G/Virtual Insider](https://www.youtube.com/c/VirtualInsider) - A tester from the start. Has helped find many bugs and issues. Has also provided many helpful suggestions and ideas.

* [Alex/Waifu Enjoyer](https://www.youtube.com/@waifu_enjoyer) - One of the most prolific testers. Has tested hundreds of games and has helped find many bugs and issues. Has also provided many helpful suggestions and ideas. Has provided helpful statistics on game compatibility.

* [Alchemist](https://github.com/NicolasAubinet/) - DRG VR developer.

* Ashok - Has helped find many bugs and issues. Has also provided many helpful suggestions and ideas. Has poked around various specific games making mods to fix issues with them and add things like Oculus controller prompts. Experimented a lot with UObjectHook to fix games and find issues/pain points with this feature.

* Igoreso

* [Jay Fullerton](https://www.youtube.com/@jayfullerton6981) - Has tested many games, and stands out as one of the testers with a lower end system. This has helped get an idea of how the tool performs on lower end hardware.

* Kitt - Mechwarrior 5 VR developer.

* Lance McCary - Has helped find many bugs and issues. Has also provided many helpful suggestions and ideas. Helped coordinate with Matthieu Bucchianeri to get eye tracked foveated rendering working in OpenXR Toolkit.

* Kalth Streil - Has helped find many bugs and issues.

* [Matthieu Bucchianeri](https://github.com/mbucchia) - Creator of OpenXR Toolkit. Has helped figure out what needed to be changed to get eye tracked foveated rendering working. Has also provided many helpful technical insights into the OpenXR API and VR development in general.

* [Narknon](https://github.com/narknon) - UE4SS developer. Provided a lot of helpful information about the Unreal Engine in general.

* [PanterA](https://www.youtube.com/@PanterACFH) - Joined late into development, but tested a good amount of games and provided good feedback. Located games that were causing crashes after code changes. Helped find issues with AMD GPUs.

* [PinkMilkProductions](https://github.com/PinkMilkProductions) - DRG VR developer.

* pvncher

* [webhead](https://www.reddit.com/user/webheadVR)

## Disclaimer

UEVR is not affiliated with, endorsed by, or connected to Epic Games, Unreal Engine, or any of their affiliates. All trademarks are the property of their respective owners.
