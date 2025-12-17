local uevrUtils = require("libs/uevr_utils")
local uevrDev = require("libs/uevr_dev")

function on_level_change()
	uevrDev.onLevelChange()
end

uevrUtils.initUEVR(uevr, function()
	print("UEVR is now ready\n")
	uevrDev.init()
end)
