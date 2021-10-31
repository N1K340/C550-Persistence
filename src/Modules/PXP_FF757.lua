--[[
    Data file for Flight Factor 757
]]

module(..., package.seeall)

--Modules
local LIP = require("LIP")

local LARM = nil
local RARM = nil
local pxpSwitchData = {}


function pxpCompile()
    if (XPLMFindDataRef("anim/armCapt/1") ~= nil) then
        LARM = get("anim/armCapt/1")
    end
    if (XPLMFindDataRef("anim/armFO/1") ~= nil) then
        RARM = get("anim/armFO/1")
    end

    pxp757Data = {
        PersistenceData{
            LARM = LARM;
            RARM = RARM;
        }
    }
    
        return pxp757Data
end    