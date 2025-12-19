# Gestures

The gestures modules allows you to query and set up callbacks for user hand gestures in 3D space.

## Overview

This module supports the following gestures:

- **PUNCH**: Detects punching gestures
- **HOLSTER**: Detects weapon holstering gestures
- **RELOAD**: Detects weapon reloading gestures
- **EARGRAB**: Detects ear grabbing gestures
- **EAT**: Detects eating gestures
- **GLASSESGRAB**: Detects glasses grabbing gestures
- **HATGRAB**: Detects hat grabbing gestures
- **EARSCRATCH**: Detects ear scratching gestures
- **HEADSCRATCH**: Detects head scratching gestures
- **LIPSCRATCH**: Detects lip scratching gestures
- **EYESCRATCH**: Detects eye scratching gestures
- **SWIPE_LEFT**: Detects leftward swipe gestures
- **SWIPE_RIGHT**: Detects rightward swipe gestures
- **SWIPE_UP**: Detects upward swipe gestures
- **SWIPE_DOWN**: Detects downward swipe gestures
- **SNATCH**: Detects snatching gestures


## Quick Start

### Basic Setup

```lua
local uevrUtils = require('libs/uevr_utils')
local interaction = require("libs/gestures")

```

### Register Hit Callbacks

```lua
gestures.registerSwipeRightCallback(function()
	print("Swipe Right detected")
    --do some game action
end)

gestures.registerSwipeLeftCallback(function()
	print("Swipe Left detected")
    --do some game action
end)
```

### Using detectGestureWithState

The detectGestureWithState function is used with gamepad input state for button-based gestures:

```lua
-- In XINPUT callback or game loop
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    -- Check for holster gesture (pointing hand down while gripping)
    if gestures.detectGestureWithState(gestures.Gesture.HOLSTER, state, Handed.Right) then
        print("Holster gesture detected - putting weapon away")
        -- Holster weapon logic here
    end

    -- Check for reload gesture (bringing hands close together)
    if gestures.detectGestureWithState(gestures.Gesture.RELOAD, state, Handed.Left) then
        print("Left grab pulled with left hand near right hand")
        -- Reload weapon logic here
    end

    -- Check for eating gesture (hand near mouth)
    if gestures.detectGestureWithState(gestures.Gesture.EAT, state, Handed.Left) then
        print("Left grab pulled with left hand near mouth")
        -- Eating/consuming logic here
    end

    -- Check for face interactions
    if gestures.detectGestureWithState(gestures.Gesture.GLASSESGRAB, state, Handed.Left) then
        print("Left grab pulled with left hand near eyes")
        -- Adjust glasses logic here
    end

    if gestures.detectGestureWithState(gestures.Gesture.HATGRAB, state, Handed.Left) then
        print("Left grab pulled with left hand near top of head")
        -- Remove/adjust hat logic here
    end

    -- Check for scratching gestures
    if gestures.detectGestureWithState(gestures.Gesture.EARSCRATCH, state, Handed.Left) then
        print("Left trigger pulled with left hand near ear")
        -- Ear scratch animation/logic here
    end

    if gestures.detectGestureWithState(gestures.Gesture.HEADSCRATCH, state, Handed.Left) then
        print("Left trigger pulled with left hand on top of head")
        -- Head scratch animation/logic here
    end
end)
```

### Mutiple Gesture Usage

```lua

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    local handedness = Handed.Right
    -- Get all gestures in one call (more efficient for multiple gesture detection)
	local isEating, isGrabbingGlasses, gripHead, isGrabbingEar, triggerMouth, isScratchingEyes, triggerHead, isScratchingEar = gestures.getHeadGestures(state, 1-handedness, true)

    if isEating then
        uevrUtils.pressButton(state, XINPUT_GAMEPAD_B)
    end

end)
```

```


