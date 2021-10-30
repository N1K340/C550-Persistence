--[[
    Data file for Flight Factor 757
]]

--Modules
local LIP = require("LIP")

local FF757 = {};

local LARM = nil

function FF757.pxpCompile()
    if (XPLMFindDataRef("anim/armCapt/1") ~= nil) then
        LARM = get("anim/armCapt/1")
    end
    if (XPLMFindDataRef("anim/armFO/1") ~= nil) then
        RARM = get("anim/armFO/1")
    end
end    

return FF757;
