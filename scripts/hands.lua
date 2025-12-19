local uevrUtils = require('libs/uevr_utils')
local hands = require('libs/hands')
local controllers = require('libs/controllers')

function on_level_change(level)
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()

	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = '' -- the name you gave your animation
	hands.createFromConfig(paramsFile, configName, animationName)
end