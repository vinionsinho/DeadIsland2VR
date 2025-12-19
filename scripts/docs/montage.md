# Montages 

The montage module allows you to monitor the playback of montages in realtime and allows you to perform actions based on the starting and stopping of individual monatges.

## Overview

The playback of montages can affect:

- **Hands Visibility**: Custom hands can be hidden or shown based on the state of a montage
- **Left and Right Arm animations**: The bones of custom hands can be made to animate with the animation of the montage
- **Pawn Body Visibility**: The pawn body can be hidden or shown
- **Pawn Arms Visibility**: The pawn arms can bbe hidden or shown (if they are a separate mesh from the body)
- **Pawn Arms Bones Visibility**: The arm bones can be hidden or shown if you are normally hiding bones rather than the mesh itself
- **Motion Sickness Compensation**: Motion sickness compensation can be turned on for specified montages

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
