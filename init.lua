-- teleportation: /rtp (random teleport) and /tpr (teleport requests, with
-- accept / deny, a timeout and blocking).

teleportation = {}

local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath .. "/blocks.lua")
dofile(modpath .. "/rtp.lua")
dofile(modpath .. "/skyblock_zero.lua")
dofile(modpath .. "/tpr.lua")
