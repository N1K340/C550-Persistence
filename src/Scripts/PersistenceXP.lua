-- Modules
local LIP = require("LIP")
local Defaults = require("PXP_Configs/PXP_Defaults")
local Defaults2 = require("PXP_Configs/PXP_Defaults2")
local DefaultRadio = require("PXP_Configs/PXP_DefaultRadio")
local Car12550 = require("PXP_Configs/PXP_CarPC12_CarC550")
local Car208 = require("PXP_Configs/PXP_CarC208")
local Car340 = require("PXP_Configs/PXP_Car340")
local FF757 = require("PXP_Configs/PXP_FF757")
require "graphics"

-- Main Script Variables
local pxpSwitchData = {}
local pxpSettings = {}
local pxpScriptLoaded = false
local pxpSettingsLoaded = false
local pxpAutoState = false
local pxpScriptLoadTimer = 3
local pxpScriptStartedTime = 0
local pxpScriptReady = false
local pxpUseScript = false
local pxpUseBaroSync = false
local pxpDelayInt = 10
local pxploadedAircraft = nil
local pxplabel = 'disabled'


-- Script Datarefs
dataref("pxp_SIM_TIME", "sim/time/total_running_time_sec")
dataref("pxp_PRK_BRK", "sim/flightmodel/controls/parkbrake")
dataref("pxp_ENG1_RUN", "sim/flightmodel/engine/ENGN_running", "readonly", 0)

-- Save and Load Settings only
function pxpWriteSettings(pxpSettings)
   LIP.save(AIRCRAFT_PATH .. "/pxpSettings.ini", pxpSettings)
   print("Persistence XP Settings Saved")
end

function pxpCompileSettings()
   pxpSettings = {
      settings = {
         pxpUseScript = pxpUseScript,
         pxpDelayInt = pxpDelayInt,
         pxpUseBaroSync = pxpUseBaroSync,
         pxpAutoState = pxpAutoState,
      }
   }
   pxpWriteSettings(pxpSettings)
end

function pxpParseSettings()
   local f = io.open(AIRCRAFT_PATH .. "/pxpSettings.ini", "r")
   if f ~= nil then
      io.close(f)
      pxpSettings = LIP.load(AIRCRAFT_PATH .. "/pxpSettings.ini")
      pxpUseScript = pxpSettings.settings.pxpUseScript
      pxpDelayInt = pxpSettings.settings.pxpDelayInt
      pxpUseBaroSync = pxpSettings.settings.pxpUseBaroSync
      pxpAutoState = pxpSettings.settings.pxpAutoState
      print("PersistenceXP Settings Loaded")
   else
      print("PersistenceXP Settings file for aircraft not found")
   end
end

-- Bubble for messages

local pxpBubbleTimer = 3
local pxpMsgStr = nil

function pxpDisplayMessage()
   bubble(20, get("sim/graphics/view/window_height") - 130, pxpMsgStr)
end

function pxpmsg()
   if pxpBubbleTimer < 3 then
      pxpDisplayMessage()
   else
      pxpMsgStr = nil
   end
end

function pxpBubbleTiming()
   if pxpBubbleTimer < 3 then
      pxpBubbleTimer = pxpBubbleTimer + 1
   end
end

do_every_draw("pxpmsg()")
do_often("pxpBubbleTiming()")

-- Initialise Script

function pxpStartDelay()
   if not pxpSettingsLoaded then
      pxpParseSettings()
      pxpSettingsLoaded = true
   elseif pxpSettingsLoaded and not pxpScriptReady then
      if pxpScriptStartedTime == 0 then
         pxpScriptStartedTime = (pxp_SIM_TIME + pxpDelayInt)
      end
      if (pxp_SIM_TIME < pxpScriptStartedTime) then
         print("PXP Waiting or Paused")
         pxpMsgStr = "Persistence XP Loading or Sim Paused"
         pxpBubbleTimer = 0
         return
      end
      if pxpUseScript == true then
         pxplabel = 'enabled'
      end
      pxploadedAircraft = AIRCRAFT_FILENAME
      print("PXP " ..  pxplabel .. " for " .. AIRCRAFT_FILENAME)
      pxpMsgStr = ("Persistence XP Loaded: "..  pxplabel .. " for " .. AIRCRAFT_FILENAME)
      pxpBubbleTimer = 0
      pxpScriptReady = true
   end
end

do_often("pxpStartDelay()")

-- Settings UI
-- Create and Destroy Settings Window
function pxpOpenSettings_wnd()
   pxpParseSettings()
   pxpSettings_wnd = float_wnd_create(450,200,1, true)
   float_wnd_set_title(pxpSettings_wnd, "PersistenceXP Settings")
   float_wnd_set_imgui_builder(pxpSettings_wnd, "pxpSettings_content")
   float_wnd_set_onclose(pxpSettings_wnd, "pxpCloseSettings_wnd")
end

function pxpCloseSettings_wnd()
   if pxpSettings_wnd then
      float_wnd_destroy(pxpSettings_wnd)
   end
end

-- Contents of Settings Window
function pxpSettings_content(pxpSettings_wnd, x, y)
   local winWidth = imgui.GetWindowWidth()
   local winHeight = imgui.GetWindowHeight()
   local titleText = "PersistenceXP Settings"
   local titleTextWidth, titleTextHeight = imgui.CalcTextSize(titleText)

   imgui.SetCursorPos(winWidth / 2 - titleTextWidth / 2, imgui.GetCursorPosY())
   imgui.TextUnformatted(titleText)

   imgui.Separator()
   imgui.TextUnformatted("")
   imgui.SetCursorPos(20, imgui.GetCursorPosY())
   local changed, newVal = imgui.Checkbox("Use PersistenceXP with this aircraft?", pxpUseScript)
   if changed then
      pxpUseScript = newVal
      pxpCompileSettings()
      print("PersistenceXP: Plugin enabled changed to " .. tostring(pxpUseScript))
   end
   imgui.SetCursorPos(20, imgui.GetCursorPosY())
   local changed, newVal = imgui.Checkbox("Automatically Load and Save Panel States?", pxpAutoState)
   if changed then
      pxpAutoState = newVal
      pxpCompileSettings()
      print("PersistenceXP: Auto Panel changed to " .. tostring(pxpUseScript))
   end
   imgui.SetCursorPos(20, imgui.GetCursorPosY())
   local changed, newVal = imgui.Checkbox("Use Left and Right Baro Sync with this aircraft?", pxpUseBaroSync)
   if changed then
      pxpUseBaroSync = newVal
      pxpCompileSettings()
      print("PersistenceXP: Baro Sync changed to " .. tostring(pxpUseScript))
   end
   imgui.SetCursorPos(50, imgui.GetCursorPosY())
   if imgui.Button("SAVE PANEL STATE") then
      pxpCompilePersistenceData()
   end
   imgui.SameLine()
   imgui.SetCursorPos(250, imgui.GetCursorPosY())
   if imgui.Button("LOAD PANEL STATE") then
      pxpParsePersistenceData()
   end
   imgui.Separator()
   imgui.TextUnformatted("")
   imgui.SetCursorPos(200, imgui.GetCursorPosY())
   if imgui.Button("CLOSE") then
      pxpCloseSettings_wnd()
   end
end

add_macro("PersistenceXP View Settings", "pxpOpenSettings_wnd()", "pxpCloseSettings_wnd()", "deactivate")
add_macro("PersistenceXP Save Panel State", "pxpCompilePersistenceData()")
add_macro("PersistenceXP Load Panel State", "pxpParsePersistenceData()")

-- Auto Function

function pxpAutoPersistenceData()
   if pxpScriptLoadTimer < 3 then
      pxpScriptLoadTimer = pxpScriptLoadTimer + 1
   end
   if pxpAutoState and pxpScriptLoaded and pxpScriptLoadTimer == 3 and pxp_PRK_BRK == 1 and pxp_ENG1_RUN == 0 then
      pxpCompilePersistenceData()
      pxpScriptLoadTimer = 0
   end
   if pxpAutoState and pxpScriptReady and pxpUseScript and not pxpScriptLoaded then
      if pxp_PRK_BRK == 1 and pxp_ENG1_RUN == 0 then
         pxpParsePersistenceData()
      else
         print("PersistenceXP Skipping State Load, Park Brake not set or Engine is running.")
         pxpMsgStr = "PersistenceXP Skipping State Load, Park Brake not set or Engine is running"
         pxpBubbleTimer = -2
      end
      pxpScriptLoaded = true
   end
end

do_sometimes("pxpAutoPersistenceData()")

-- Main Calls

function pxpCompilePersistenceData()
   Defaults.pxpCompile()
   Defaults2.pxpCompile()
   DefaultRadio.pxpCompile()
   if pxploadedAircraft == '757-200_xp11.acf' then
      FF757.pxpCompile()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP 757 Panel State Saved'
   elseif pxploadedAircraft == 'Car_PC12.acf' or pxploadedAircraft == 'S550_Citation_II.acf' then
      Car12550.pxpCompile()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado PC12 / C550 Panel State Saved'
   elseif pxploadedAircraft == 'SF34.acf' then
      Car340.pxpCompile()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado 340 Panel State Saved'
   elseif  pxploadedAircraft == 'C208B_EX_XP11.acf' or pxploadedAircraft == 'Car_C208B.acf' then
      Car208.pxpCompile()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado C208 Panel State Saved'
   else
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Saved Defaults, Plane Unknown'
   end
end

function pxpParsePersistenceData()
   Defaults.pxpRead()
   Defaults2.pxpRead()
   DefaultRadio.pxpRead()
   if pxploadedAircraft == '757-200_xp11.acf' then
      FF757.pxpRead()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP 757 Panel State Loaded'
   elseif pxploadedAircraft == 'Car_PC12.acf' or pxploadedAircraft == 'S550_Citation_II.acf' then
      Car12550.pxpRead()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado PC12 / C550 Panel State Loaded'
   elseif pxploadedAircraft == 'SF34.acf' then
      Car340.pxpRead()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado 340 Panel State Loaded'
   elseif pxploadedAircraft == 'C208B_EX_XP11.acf' or pxploadedAircraft == 'Car_C208B.acf' then
      Car208.pxpRead()
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Carenado C208 Panel State Loaded'
   else
      pxpBubbleTimer = 1
      pxpMsgStr = 'PersistenceXP Loaded Defaults, Plane Unknown'
   end
end