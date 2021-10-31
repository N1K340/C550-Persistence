--[[ Starting a new file, what an idiot
Persistence for X-Plane 11 Aircraft, with compatability with custom datarefs as coded
Objective:
    - Save and Load Panel State 
    - Isolate to specific airframe variations (rego?)

Aircraft With Custom Datarefs
    - Carenado Citation II
    - Carenado C208 HD
    - Carenado C208 EX
    - Flight Factor 757

    ]]



-- Modules
local LIP = require("LIP")
local FF757 = require("PXP_FF757")
-- local Defaults = require("PXP_Defaults")
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
local loadedAircraft = nil
local label = 'disabled'
local useDefaults = false


-- Script Datarefs
dataref("SIM_TIME", "sim/time/total_running_time_sec")
dataref("PRK_BRK", "sim/flightmodel/controls/parkbrake")
-- dataref("ENG1_RUN", "sim/flightmodel/engine/ENGN_running", 0)
-- dataref("ENG2_RUN", "sim/flightmodel/engine/ENGN_running", 1)
-- dataref("dataSavePath", "sim/aircraft/view/acf_livery_path", 0)

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

    local bubbleTimer = 3
    local msgStr = nil

    function pxpDisplayMessage()
        bubble(20, get("sim/graphics/view/window_height") - 130, msgStr)
    end

    function pxpmsg()
        if bubbleTimer < 3 then
            pxpDisplayMessage()
        else
            msgStr = nil
        end 
    end

    function pxpBubbleTiming()
        if bubbleTimer < 3 then
            bubbleTimer = bubbleTimer + 1
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
            pxpScriptStartedTime = (SIM_TIME + pxpDelayInt)
        end
        if (SIM_TIME < pxpScriptStartedTime) then
            print("PXP Waiting or Paused")
            msgStr = "Persistence XP Loading or Sim Paused"
            bubbleTimer = 0
            return
        end
        if pxpUseScript == true then
            label = 'enabled'
        end
        loadedAircraft = AIRCRAFT_FILENAME
        print("PXP " ..  label .. " for " .. AIRCRAFT_FILENAME)
        msgStr = ("Persistence XP Loaded: "..  label .. " for " .. AIRCRAFT_FILENAME)
        bubbleTimer = 0
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


-- Main Function Call




--[[

function pxpAutoPersistenceData()
        if pxpScriptLoadTimer < 3 then
        pxpScriptLoadTimer = pxpScriptLoadTimer + 1
        end
        if pxpAutoState and pxpScriptLoaded and pxpScriptLoadTimer == 3 and PRK_BRK == 1 and ENG1_RUN == 0 then
            pxpCompilePersistenceData()
            pxpScriptLoadTimer = 0
        end
        if pxpAutoState and pxpScriptReady and pxpUseScript and not pxpScriptLoaded then
            if PRK_BRK == 1 and ENG1_RUN == 0 then        
                pxpParsePersistenceData()
                print("Persistence XP Panel State Loaded")
                msgStr = "Persistence XP Panel State Loaded"
                bubbleTimer = -2
            else
                print("PersistenceXP Skipping State Load, Park Brake not set or Engine is running.")
                msgStr = "PersistenceXP Skipping State Load, Park Brake not set or Engine is running"
                bubbleTimer = -2     
            end
            pxpScriptLoaded = true
        end
end

do_sometimes("pxpAutoPersistenceData()")
]]

add_macro("PersistenceXP Save Panel State", "pxpCompilePersistenceData()")
add_macro("PersistenceXP Load Panel State", "pxpParsePersistenceData()")

-- Save and Load Panel Data Functions

function pxpWritePersistenceData(pxpSwitchData)
    LIP.save(AIRCRAFT_PATH .. "/pxpPersistence.ini", pxpSwitchData)
    print("PersistenceXP Panel State Saved")
    msgStr = "PersistenceXP Panel State Saved"
    bubbleTimer = 1
end

function pxpCompilePersistenceData()
    if loadedAircraft == '757-200_xp11.acf' then
        FF757.pxpCompile()
        pxpSwitchData = FF757.pxp757Data
    end
    pxpWritePersistenceData(pxpSwitchData)
    print("PersistenceXP Panel data saved to " .. AIRCRAFT_PATH .. "pxpPersistence.ini")
end
--[[

    -- Deafult Electrical
    local BAT = nil
    local AVN = nil
    local GENL = nil
    local GENR = nil
    local GENAPU = nil
    local GPU = nil
    -- Internal Lighting
    local ST_BLT = nil
    local NO_SMK = nil
    local PNL_LT0 = nil
    local PNL_LT1 = nil
    local PNL_LT2 = nil
    local PNL_LT3 = nil
    local PNL_LT4 = nil
    local PNL_LT5 = nil
    local PNL_LT6 = nil
    local PNL_LT7 = nil
    local PNL_LT8 = nil
    local PNL_LT9 = nil    
    -- Deafult Lighting
    local Nav_LT = nil
    local BCN = nil
    local STROBE = nil
    local LNDLIGHT = nil
    local TAXILIGHT = nil
    -- Doors
    local DOOR0 = nil -- 0 Main, 1 Left Bag, 2 Right Bag
    local DOOR1 = nil
    local DOOR2 = nil
    --Com Select
    local NAV1_PWR = nil
    local NAV2_PWR = nil
    local COM1_PWR = nil
    local COM2_PWR = nil
    local ADF1_PWR = nil
    local ADF2_PWR = nil
    local GPS1_PWR = nil
    local GPS2_PWR = nil
    local DME_PWR = nil
    local XMT = nil
    local C1_RCV = nil
    local C2_RCV = nil
    local ADF1_RCV = nil
    local ADF2_RCV = nil
    local NAV1_RCV = nil
    local NAV2_RCV = nil
    local DME1_RCV = nil
    local MRKR_RCV = nil
    local NAV1_ACT = nil
    local NAV1_STB = nil
    local NAV2_ACT = nil
    local NAV2_STB = nil
    local COM1_ACT = nil
    local COM1_STB = nil
    local COM2_ACT = nil
    local COM2_STB = nil
    local ADF1_ACT = nil
    local ADF1_STB = nil
    local ADF2_ACT = nil
    local ADF2_STB = nil
    local XPDR_COD = nil
    local XPDR_MODE = nil
    local CLK_MODE = nil
    -- Nav Related
    local HDG = nil
    local VS = nil
    local APA = nil
    local SPD_BG = nil
    local RMI_L = nil
    local RMI_R = nil
    local DME_CH = nil
    local DME_SEL = nil
    local DH = nil
    local CRS1 = nil
    local CRS2 = nil
    local GYROSL = nil
    local GYROSR = nil
    -- Engine
    local IGN1 = nil
    local IGN2 = nil
    local MAG1 = nil
    local MAG2 = nil
    -- Fuel
    local BOOST_PMP1 = nil
    local BOOST_PMP2 = nil
    local FUEL0 = nil
    local FUEL1 = nil
    local FUEL2 = nil
    local FUEL3 = nil
    local FUEL_TTL = nil
    -- Ice Protection
    local PIT1_HT = nil
    local STAT1_HT = nil
    local AOA1_HT = nil
    local PIT2_HT = nil
    local STAT2_HT = nil
    local AOA2_HT = nil
    local WS_BLD = nil
    local INLET1_AI = nil
    local INLET2_AI = nil
    local ENG_AI1 = nil
    local ENG_AI2 = nil
    local WING_BOOT = nil
    local WING_HEAT = nil
    local PROP_HEAT = nil
    -- Controls
    local TRIM = nil
    local SPD_BRK = nil
    local FLP_HNDL = nil
    local FAN_SYNC = nil
    local PROP_SYNC = nil
    local THRTL = nil
    local PROP = nil
    local MIX = nil
    local CARB1 = nil
    local CARB2 = nil
    local COWL1 = nil
    local COWL2 = nil
    local CAB_ALT = nil
    local CAB_RATE = nil    

    -- Custom Aircraft
    -- Carenado Citation II / Carenado PC12
    local LYOKE = nil
    local RYOKE = nil
    local LARM = nil
    local RARM = nil
    local PNL_LT = nil
    local PNL_LFT = nil
    local PNL_CTR = nil
    local PNL_RT = nil
    local PNL_EL = nil

    -- Carenado PC12
    local LVISARM = nil
    local LVIS = nil
    local RVISARM = nil
    local RVIS = nil

    -- Carenado C208 HD
    local CARGOPOD = nil
    local STB_PWR = nil
    local STRT1 = nil
    local WING_LT = nil
    local PNL_LWR = nil
    local ANNUN_DIM = nil
    local CAB_UTIL = nil
    local CAB_LT = nil
    local STALL_HT = nil
    local FLOOD_LFT = nil
    local FLOOD_RT = nil
    local BLEED_AIR = nil
    local FUEL_SEL_L = nil
    local FUEL_SEL_R = nil

    -- Carenado SF34
    local IGNL_CVR = nil
    local IGNR_CVR = nil
    local DCAMP = nil
    local EMG_CVR = nil
    local EMG = nil
    local CAB_PRESS_CTL = nil
    local INV = nil
    local WREFL = nil
    local IREFL = nil
    local COVERS = nil
    local VOLT_SEL = nil
    local TEST_SEL = nil
    local FUEL_SEL = nil
    local RECOG = nil
    local BARO_UNIT = nil
    local N1_DIAL = nil
    local L_LND = nil
    local R_LND = nil
    local ASKID = nil
    local TEMP_MAN = nil
    local TEMP_CTRL = nil
    local PRES_SRC = nil
    local FLOW_DIST = nil
    local L_WS = nil
    local R_WS = nil
    local CAB_FAN1 = nil
    local CAB_FAN2 = nil
    local CAB_FAN3 = nil
    local CAB_FOG = nil
    local AC = nil
    local BLWR = nil
    local CAB_VNT = nil
    local NAV_IDENT = nil
    local MIC_SEL = nil
    
    -- Carenado Citation II
    if loadedAircraft == 'S550_Citation_II.acf' then
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
            LYOKE = get("thranda/cockpit/actuators/HideYokeL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeR") ~= nil) then
            RYOKE = get("thranda/cockpit/actuators/HideYokeR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            LARM = get("thranda/cockpit/animations/ArmRestLR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            RARM = get("thranda/cockpit/animations/ArmRestRL")
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/generic_lights_switch", 30) ~= nil) then
            PNL_LT = get("sim/cockpit2/switches/generic_lights_switch", 30)
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 1) ~= nil) then
            FLOOD_LT = get("sim/cockpit2/switches/instrument_brightness_ratio", 1)
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 2) ~= nil) then
            PNL_LFT = get("sim/cockpit2/switches/instrument_brightness_ratio", 2)
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 3) ~= nil) then
            PNL_CTR = get("sim/cockpit2/switches/instrument_brightness_ratio", 3)
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 4) ~= nil) then
            PNL_RT = get("sim/cockpit2/switches/instrument_brightness_ratio", 4)
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 5) ~= nil) then
            PNL_EL = get("sim/cockpit2/switches/instrument_brightness_ratio", 5)
        end
        if (XPLMFindDataRef("thranda/electrical/AC_InverterSwitch") ~= nil) then -- Inverter
            INV = get("thranda/electrical/AC_InverterSwitch")
        end
        if (XPLMFindDataRef("thranda/views/WindowRefl") ~= nil) then -- Window Reflections
            WREFL = get("thranda/views/WindowRefl") 
        end
        if (XPLMFindDataRef("thranda/views/InstRefl") ~= nil) then -- Instrument Reflections
            IREFL = get("thranda/views/InstRefl") 
        end
        if (XPLMFindDataRef("thranda/views/staticelements") ~= nil) then -- Pitot Covers etc.
            COVERS = get("thranda/views/staticelements") 
        end
        if (XPLMFindDataRef("thranda/actuators/VoltSelAct") ~= nil) then -- Volt Meter
            VOLT_SEL = get("thranda/actuators/VoltSelAct") 
        end
        if (XPLMFindDataRef("thranda/annunciators/AnnunTestKnob") ~= nil) then -- Annun Test
            TEST_SEL = get("thranda/annunciators/AnnunTestKnob") 
        end
        if (XPLMFindDataRef("thranda/fuel/CrossFeedLRSw") ~= nil) then
            FUEL_SEL = get("thranda/fuel/CrossFeedLRSw") 
        end
        if (XPLMFindDataRef("thranda/lights/RecogLights") ~= nil) then
            RECOG = get("thranda/lights/RecogLights") 
        end
        if (XPLMFindDataRef("thranda/instruments/BaroUnits") ~= nil) then
            BARO_UNIT = get("thranda/instruments/BaroUnits") 
        end
        if (XPLMFindDataRef("thranda/knobs/N1_Dial") ~= nil) then
            N1_DIAL = get("thranda/knobs/N1_Dial") 
        end
        if (XPLMFindDataRef("thranda/lights/LandingLightLeft") ~= nil) then
            L_LND = get("thranda/lights/LandingLightLeft") 
        end
        if (XPLMFindDataRef("thranda/lights/LandingLightRight") ~= nil) then
            R_LND = get("thranda/lights/LandingLightRight") 
        end
        if (XPLMFindDataRef("thranda/gear/AntiSkid") ~= nil) then
            ASKID = get("thranda/gear/AntiSkid") 
        end
        if (XPLMFindDataRef("thranda/BT", 22) ~= nil) then
            TEMP_MAN = get("thranda/BT", 22) 
        end
        if (XPLMFindDataRef("thranda/pneumatic/CabinTempAct") ~= nil) then
            TEMP_CTRL = get("thranda/pneumatic/CabinTempAct") 
        end
        if (XPLMFindDataRef("thranda/pneumatic/PressureSource") ~= nil) then
            PRES_SRC = get("thranda/pneumatic/PressureSource") 
        end
        if (XPLMFindDataRef("thranda/pneumatic/AirFlowDistribution") ~= nil) then
            FLOW_DIST = get("thranda/pneumatic/AirFlowDistribution") 
        end
        if (XPLMFindDataRef("thranda/ice/WindshieldIceL") ~= nil) then
            L_WS = get("thranda/ice/WindshieldIceL") 
        end
        if (XPLMFindDataRef("thranda/ice/WindshieldIceR") ~= nil) then
            R_WS = get("thranda/ice/WindshieldIceR") 
        end
        if (XPLMFindDataRef("thranda/BT", 23) ~= nil) then
            CAB_FAN1 = get("thranda/BT", 23) 
        end
        if (XPLMFindDataRef("thranda/pneumatic/CabinFan") ~= nil) then
            CAB_FAN2 = get("thranda/pneumatic/CabinFan") 
        end
        if (XPLMFindDataRef("thranda/BT", 24) ~= nil) then
            CAB_FOG = get("thranda/BT", 24) 
        end
        if (XPLMFindDataRef("thranda/pneumatic/AC") ~= nil) then
            AC = get("thranda/pneumatic/AC") 
        end
        if (XPLMFindDataRef("thranda/pneumatic/BlowerIntensity") ~= nil) then
            BLWR = get("thranda/pneumatic/BlowerIntensity") 
        end
        if (XPLMFindDataRef("thranda/pneumatic/CabinVent") ~= nil) then
            CAB_VNT = get("thranda/pneumatic/CabinVent") 
        end
        if (XPLMFindDataRef("thranda/BT", 2) ~= nil) then
            NAV_IDENT = get("thranda/BT", 2) 
        end
        if (XPLMFindDataRef("thranda/BT", 32) ~= nil) then
            MIC_SEL = get("thranda/BT", 32) 
        end
    else
        print("PXP Skipping Carenado Citation II Ref's")
    end

    -- Carenado PC12
    if loadedAircraft == 'Car_PC12.acf' then
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
            LYOKE = get("thranda/cockpit/actuators/HideYokeL")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            LARM = get("thranda/cockpit/animations/ArmRestLR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            RARM = get("thranda/cockpit/animations/ArmRestRL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/VisorSwingL") ~= nil) then
            LVISARM = get("thranda/cockpit/actuators/VisorSwingL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/VisorL") ~= nil) then
            LVIS = get("thranda/cockpit/actuators/VisorL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/VisorSwingR") ~= nil) then
            RVISARM = get("thranda/cockpit/actuators/VisorSwingR")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/VisorR") ~= nil) then
            RVIS = get("thranda/cockpit/actuators/VisorR")
        end
    else
        print("PXP Skipping Carenado PC12 Ref's")
    end

    -- Carenado C208 HD / EX

    if loadedAircraft == 'C208B_EX_XP11.acf' or 'Car_C208B.acf' then
        if (XPLMFindDataRef("com/dkmp/cargopod") ~= nil) then
            CARGOPOD = get("com/dkmp/cargopod")
        end
        if (XPLMFindDataRef("Carenado/Switch/Dummy/Dummy1") ~= nil) then
            LYOKE = get("Carenado/Switch/Dummy/Dummy1")
        end
        if (XPLMFindDataRef("Carenado/Switch/Dummy/Dummy2") ~= nil) then
            RYOKE = get("Carenado/Switch/Dummy/Dummy2")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            LARM = get("thranda/cockpit/animations/ArmRestLR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            RARM = get("thranda/cockpit/animations/ArmRestRL")
        end
        if (XPLMFindDataRef("com/dkmp/FuelBoost") ~= nil) then
            BOOST_PMP1 = get("com/dkmp/FuelBoost")
        end
        if (XPLMFindDataRef("com/dkmp/StbyPwr") ~= nil) then
            STB_PWR = get("com/dkmp/StbyPwr")
        end
        if (XPLMFindDataRef("com/dkmp/Ignition") ~= nil) then
            IGN1 = get("com/dkmp/Ignition")
        end
        if (XPLMFindDataRef("com/dkmp/Starter") ~= nil) then
            STRT1 = get("com/dkmp/Starter")
        end
        if (XPLMFindDataRef("com/dkmp/AmpsVoltsSwitch") ~= nil) then
            DCAMP = get("com/dkmp/AmpsVoltsSwitch")
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/generic_lights_switch", 30) ~= nil) then
            WING_LT = get("sim/cockpit2/switches/generic_lights_switch", 30)
        end
        if (XPLMFindDataRef("com/dkmp/Ventilate") ~= nil) then
            AC = get("com/dkmp/Ventilate")
        end
        if (XPLMFindDataRef("com/dkmp/ACFansLeft") ~= nil) then
            CAB_FAN1 = get("com/dkmp/ACFansLeft")
        end
        if (XPLMFindDataRef("com/dkmp/ACFansRight") ~= nil) then
            CAB_FAN2 = get("com/dkmp/ACFansRight")
        end
        if (XPLMFindDataRef("com/dkmp/ACFansAft") ~= nil) then
            CAB_FAN3 = get("com/dkmp/ACFansAft")
        end
        if (XPLMFindDataRef("com/dkmp/TempHot") ~= nil) then
            TEMP_CTRL = get("com/dkmp/TempHot")
        end
        if (XPLMFindDataRef("com/dkmp/PanelLit") ~= nil) then
            PNL_LT = get("com/dkmp/PanelLit")
        end
        if (XPLMFindDataRef("Carenado/lights/CortesyLight") ~= nil) then
            CAB_LT = get("Carenado/lights/CortesyLight")
        end
        if (XPLMFindDataRef("com/dkmp/AnnunLITsw") ~= nil) then
            ANNUN_DIM = get("com/dkmp/AnnunLITsw")
        end
        if (XPLMFindDataRef("com/dkmp/Throttle") ~= nil) then
            THRTL = get("com/dkmp/Throttle")
        end
        if (XPLMFindDataRef("sim/flightmodel/engine/ENGN_prop", 0) ~= nil) then
            PROP = get("sim/flightmodel/engine/ENGN_prop", 0)
        end
        if (XPLMFindDataRef("com/dkmp/FuelSwL") ~= nil) then
            FUEL_SEL_L = get("com/dkmp/FuelSwL")
        end
        if (XPLMFindDataRef("com/dkmp/FuelSwR") ~= nil) then
            FUEL_SEL_R = get("com/dkmp/FuelSwR")
        end
        
        -- C208 EX
        if (XPLMFindDataRef("Carenado/visibilities/CargoPod") ~= nil) then
            CARGOPOD = get("Carenado/visibilities/CargoPod")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/PropHeat") ~= nil) then
            PROP_HEAT = get("Carenado/Switch/dummy/PropHeat")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/PowerOutlet") ~= nil) then
            CAB_UTIL = get("Carenado/Switch/dummy/PowerOutlet")
        end
        if (XPLMFindDataRef("Carenado/Heat/StallHeat") ~= nil) then
            STALL_HT = get("Carenado/Heat/StallHeat")
        end
        if (XPLMFindDataRef("Carenado/lights/WingLight") ~= nil) then
            WING_LT = get("Carenado/lights/WingLight")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/FuelBoost") ~= nil) then
            BOOST_PMP1 = get("Carenado/Switch/dummy/FuelBoost")
        end
        if (XPLMFindDataRef("Carenado/battery/StbyBatt") ~= nil) then
            STB_PWR = get("Carenado/battery/StbyBatt")
        end
        if (XPLMFindDataRef("Carenado/Switch/Ignition") ~= nil) then
            IGN1 = get("Carenado/Switch/Ignition")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/Starter") ~= nil) then
            STRT1 = get("Carenado/Switch/dummy/Starter")
        end
        if (XPLMFindDataRef("Carenado/lights/leftFloodLight") ~= nil) then
            FLOOD_LFT = get("Carenado/lights/leftFloodLight")
        end
        if (XPLMFindDataRef("Carenado/lights/rightFloodLight") ~= nil) then
            FLOOD_RT = get("Carenado/lights/rightFloodLight")
        end

        if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioning") ~= nil) then
            AC = get("Carenado/Switch/dummy/AirConditioning")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningLeft") ~= nil) then
            CAB_FAN1 = get("Carenado/Switch/dummy/AirConditioningLeft")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningRigth") ~= nil) then
            CAB_FAN2 = get("Carenado/Switch/dummy/AirConditioningRigth")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningAft") ~= nil) then
            CAB_FAN3 = get("Carenado/Switch/dummy/AirConditioningAft")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/TempBleedAir") ~= nil) then
            TEMP_CTRL = get("Carenado/Switch/dummy/TempBleedAir")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/BleedAir") ~= nil) then
            BLEED_AIR = get("Carenado/Switch/dummy/BleedAir")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/FuelSelectorL") ~= nil) then
            FUEL_SEL_L = get("Carenado/Switch/dummy/FuelSelectorL")
        end
        if (XPLMFindDataRef("Carenado/Switch/dummy/FuelSelectorR") ~= nil) then
            FUEL_SEL_R = get("Carenado/Switch/dummy/FuelSelectorR")
        end
        if (XPLMFindDataRef("Carenado/Cockpit/RestArmL") ~= nil) then
            LARM = get("Carenado/Cockpit/RestArmL")
        end
        if (XPLMFindDataRef("Carenado/Cockpit/RestArmR") ~= nil) then
            RARM = get("Carenado/Cockpit/RestArmR")
        end
    else
        print("PXP Skipping Carenado C208 HD Ref's")
    end

    -- Carenado SF34

    if loadedAircraft == 'SF34.acf' then
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            LARM = get("thranda/cockpit/animations/ArmRestLR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            RARM = get("thranda/cockpit/animations/ArmRestRL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
            LYOKE = get("thranda/cockpit/actuators/HideYokeL")
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeR") ~= nil) then
            RYOKE = get("thranda/cockpit/actuators/HideYokeR")
        end
        if (XPLMFindDataRef("thranda/BT", 9) ~= nil) then
            IGNL_CVR = get("thranda/BT", 9)
        end
        if (XPLMFindDataRef("thranda/BT", 10) ~= nil) then
            IGNR_CVR = get("thranda/BT", 10)
        end
        if (XPLMFindDataRef("thranda/BT", 107) ~= nil) then
            IGN1 = get("thranda/BT", 107)
        end
        if (XPLMFindDataRef("thranda/BT", 108) ~= nil) then
            IGN2 = get("thranda/BT", 108)
        end
        if (XPLMFindDataRef("thranda/actuators/VoltSelAct") ~= nil) then
            DCAMP = get("thranda/actuators/VoltSelAct")
        end
        if (XPLMFindDataRef("thranda/BT", 27) ~= nil) then
            EMG_CVR = get("thranda/BT", 27)
        end
        if (XPLMFindDataRef("thranda/BT", 93) ~= nil) then
            EMG = get("thranda/BT", 93)
        end
        if (XPLMFindDataRef("thranda/cockpit/ManualOverride") ~= nil) then
            CAB_PRESS_CTL = get("thranda/cockpit/ManualOverride")
        end
        if (XPLMFindDataRef("thranda/engine/TorqueLimit") ~= nil) then
            CTOT_PWR = get("thranda/engine/TorqueLimit")
        end
        if (XPLMFindDataRef("thranda/engine/CTOT") ~= nil) then
            CTOT = get("thranda/engine/CTOT")
        end
    else
        print("PXP Skipping Carenado Saab 340 Ref's")
    end

    -- FF 757

    if loadedAircraft == '757-200_xp11.acf' then
        FF757.pxpCompile()
    end

    pxpSwitchData = {
        PersistenceData = {
            --Deafault Electrical
            BAT = BAT,
            AVN = AVN,
            GENL = GENL,
            GENR = GENR,
            GENAPU = GENAPU,
            GPU = GPU,

            -- Default Lighting
            Nav_LT = Nav_LT,
            BCN = BCN,
            STROBE = STROBE,
            LNDLIGHT = LNDLIGHT,
            TAXILIGHT = TAXILIGHT,

            --Doors
            DOOR0 = DOOR0,
            DOOR1 = DOOR1,
            DOOR2 = DOOR2,

            --Coms
            NAV1_PWR = NAV1_PWR,
            NAV2_PWR = NAV2_PWR,
            COM1_PWR = COM1_PWR,
            COM2_PWR = COM2_PWR,
            ADF1_PWR = ADF1_PWR,
            ADF2_PWR = ADF2_PWR,
            GPS1_PWR = GPS1_PWR,
            GPS2_PWR = GPS2_PWR,
            DME_PWR = DME_PWR,

            XMT = XMT,
            C1_RCV = C1_RCV,
            C2_RCV = C2_RCV,
            ADF1_RCV = ADF1_RCV,
            ADF2_RCV = ADF2_RCV,
            NAV1_RCV = NAV1_RCV,
            NAV2_RCV = NAV2_RCV,
            DME1_RCV = DME1_RCV,
            MRKR_RCV = MRKR_RCV,

            COM1_ACT = COM1_ACT,
            COM1_STB = COM1_STB,
            COM2_ACT = COM2_ACT,
            COM2_STB = COM2_STB,
            NAV1_ACT = NAV1_ACT,
            NAV1_STB = NAV1_STB,
            NAV2_ACT = NAV2_ACT,
            NAV2_STB = NAV2_STB,
            ADF1_ACT = ADF1_ACT,
            ADF1_STB = ADF1_STB,
            ADF2_ACT = ADF2_ACT,
            ADF2_STB = ADF2_STB,
            XPDR_COD = XPDR_COD,
            XPDR_MODE = XPDR_MODE,

            CLK_MODE = CLK_MODE,

            -- Nav Related
            HDG = HDG,
            VS = VS,
            APA = APA,
            SPD_BG = SPD_BG,
            RMI_L = RMI_L,
            RMI_R = RMI_R,
            DME_CH = DME_CH,
            DME_SEL = DME_SEL,
            DH = DH,
            CRS1 = CRS1,
            CRS2 = CRS2,
            GYROSL = GYROSL,
            GYROSR = GYROSR,

            -- Engines
            IGN1 = IGN1,
            IGN2 = IGN2,
            MAG1 = MAG1,
            MAG2 = MAG2,
            ENG1_RUN = ENG1_RUN,
            ENG2_RUN = ENG2_RUN,

            -- Fuel
            BOOST_PMP1 = BOOST_PMP1,
            BOOST_PMP2 = BOOST_PMP2,
            FUEL0 = FUEL0,
            FUEL1 = FUEL1,
            FUEL2 = FUEL2,
            FUEL3 = FUEL3,
            FUEL_TTL = FUEL_TTL,

            -- Ice Protection
            PIT1_HT = PIT1_HT,
            STAT1_HT = STAT1_HT,
            AOA1_HT = AOA1_HT,
            PIT2_HT = PIT2_HT,
            STAT2_HT = STAT2_HT,
            AOA2_HT = AOA2_HT,
            WS_BLD = WS_BLD,
            INLET1_AI = INLET1_AI,
            INLET2_AI = INLET2_AI,
            ENG_AI1 = ENG_AI1,
            ENG_AI2 = ENG_AI2,
            WING_BOOT = WING_BOOT,
            WING_HEAT = WING_HEAT,
            PROP_HEAT = PROP_HEAT,

            -- Controls
            TRIM = TRIM,
            SPD_BRK = SPD_BRK,
            FLP_HNDL = FLP_HNDL,
            FAN_SYNC = FAN_SYNC,
            PROP_SYNC = PROP_SYNC,
            THRTL = THRTL,
            PROP = PROP,
            MIX = MIX,
            CARB1 = CARB1,
            CARB2 = CARB2,
            COWL1 = COWL1,
            COWL2 = COWL2,
            CAB_ALT = CAB_ALT,
            CAB_RATE = CAB_RATE,

            -- Internal Lights
            ST_BLT = ST_BLT,
            NO_SMK = NO_SMK,
            PNL_LT0 = PNL_LT0,
            PNL_LT1 = PNL_LT1,
            PNL_LT2 = PNL_LT2,
            PNL_LT3 = PNL_LT3,
            PNL_LT4 = PNL_LT4,
            PNL_LT5 = PNL_LT5,
            PNL_LT6 = PNL_LT6,
            PNL_LT7 = PNL_LT7,
            PNL_LT8 = PNL_LT8,
            PNL_LT9 = PNL_LT9,
            

            -- Carenado C550
            LYOKE = LYOKE,
            RYOKE = RYOKE,
            LARM = LARM,
            RARM = RARM,
            FLOOD_LT = FLOOD_LT,
            PNL_LT = PNL_LT,
            PNL_LFT = PNL_LFT,
            PNL_CTR = PNL_CTR,
            PNL_RT = PNL_RT,
            PNL_EL = PNL_EL,
            INV = INV,
            WREFL = WREFL,
            IREFL = IREFL,
            COVERS = COVERS,
            VOLT_SEL = VOLT_SEL,
            TEST_SEL = TEST_SEL,
            FUEL_SEL = FUEL_SEL,
            RECOG = RECOG,
            BARO_UNIT = BARO_UNIT,
            N1_DIAL = N1_DIAL,
            L_LND = L_LND,
            R_LND = R_LND,
            ASKID = ASKID,
            TEMP_MAN = TEMP_MAN,
            TEMP_CTRL = TEMP_CTRL,
            PRES_SRC = PRES_SRC,
            FLOW_DIST = FLOW_DIST,
            L_WS = L_WS,
            R_WS = R_WS,
            CAB_FAN1 = CAB_FAN1,
            CAB_FAN2 = CAB_FAN2,
            CAB_FAN3 = CAB_FAN3,
            CAB_FOG = CAB_FOG,
            AC = AC,
            BLWR = BLWR,
            CAB_VNT = CAB_VNT,
            NAV_IDENT = NAV_IDENT,
            MIC_SEL = MIC_SEL,

            

            -- Carenado PC12
            LVIS = LVIS,
            LVISARM = LVISARM,
            RVIS = RVIS,
            RVISARM = RVISARM,

            -- Carenado C208
            CARGOPOD = CARGOPOD,
            STRT1 = STRT1,
            STB_PWR = STB_PWR,
            WING_LT = WING_LT,
            PNL_LWR = PNL_LWR,
            ANNUN_DIM = ANNUN_DIM,
            CAB_UTIL = CAB_UTIL,
            CAB_LT = CAB_LT,
            STALL_HT = STALL_HT,
            FLOOD_LFT = FLOOD_LFT,
            FLOOD_RT = FLOOD_RT,
            BLEED_AIR = BLEED_AIR,
            FUEL_SEL_L = FUEL_SEL_L,
            FUEL_SEL_R = FUEL_SEL_R,

            -- Careando Saab 340
            IGNL_CVR = IGNL_CVR,
            IGNR_CVR = IGNR_CVR,
            DCAMP = DCAMP,
            EMG_CVR = EMG_CVR,
            EMG = EMG,
            CAB_PRESS_CTL = CAB_PRESS_CTL,
            CTOT_PWR = CTOT_PWR,
            CTOT = CTOT,

        }
    }
    pxpWritePersistenceData(pxpSwitchData)
    print("PersistenceXP Panel data saved to " .. AIRCRAFT_PATH .. "pxpPersistence.ini")
end

function pxpParsePersistenceData()
    local f = io.open(AIRCRAFT_PATH .. "/pxpPersistence.ini","r")
	if f ~= nil then 
		io.close(f) 
        pxpSwitchData = LIP.load(AIRCRAFT_PATH .. "/pxpPersistence.ini")
        
        --Default Electrical
        if (XPLMFindDataRef("sim/cockpit/electrical/battery_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
            set("sim/cockpit/electrical/battery_on", pxpSwitchData.PersistenceData.BAT) -- Batt Switch
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/avionics_power_on") ~= nil) then
            if pxpSwitchData.PersistenceData.AVN ~= nil then
                set("sim/cockpit2/switches/avionics_power_on", pxpSwitchData.PersistenceData.AVN) -- Avionics Switch
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_on") ~= nil) then
            if pxpSwitchData.PersistenceData.GENL ~= nil then
                set_array("sim/cockpit/electrical/generator_on", 0, pxpSwitchData.PersistenceData.GENL) -- Gen Switches 0 Left, 1 Right
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_on") ~= nil) then
            if pxpSwitchData.PersistenceData.GENR ~= nil then
                set_array("sim/cockpit/electrical/generator_on", 1, pxpSwitchData.PersistenceData.GENR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_apu_on") ~= nil) then
            if pxpSwitchData.PersistenceData.GENAPU ~= nil then
                set("sim/cockpit/electrical/generator_apu_on", pxpSwitchData.PersistenceData.GENAPU)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/gpu_on") ~= nil) then
            if pxpSwitchData.PersistenceData.GPU ~= nil then
                set("sim/cockpit/electrical/gpu_on", pxpSwitchData.PersistenceData.GPU)
            end
        end

        --Default Lighting
        if (XPLMFindDataRef("sim/cockpit2/switches/navigation_lights_on") ~= nil) then
            if pxpSwitchData.PersistenceData.Nav_LT ~= nil then
                set("sim/cockpit2/switches/navigation_lights_on", pxpSwitchData.PersistenceData.Nav_LT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/beacon_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BCN ~= nil then
                set("sim/cockpit2/switches/beacon_on", pxpSwitchData.PersistenceData.BCN)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/strobe_lights_on") ~= nil) then
            if pxpSwitchData.PersistenceData.STROBE ~= nil then
                set("sim/cockpit2/switches/strobe_lights_on", pxpSwitchData.PersistenceData.STROBE)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 0, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 1, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 2, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 3) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 3, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_switch", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_switch", 0, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_switch", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_switch", 1, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_switch", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.LNDLIGHT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_switch", 2, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/taxi_light_on") ~= nil) then
            if pxpSwitchData.PersistenceData.TAXILIGHT ~= nil then
                set("sim/cockpit2/switches/taxi_light_on", pxpSwitchData.PersistenceData.TAXILIGHT)
            end
        end

        --Doors
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.DOOR0 ~= nil then
                set_array("sim/cockpit2/switches/door_open", 0, pxpSwitchData.PersistenceData.DOOR0) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.DOOR1 ~= nil then
                set_array("sim/cockpit2/switches/door_open", 1, pxpSwitchData.PersistenceData.DOOR1) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.DOOR2 ~= nil then
                set_array("sim/cockpit2/switches/door_open", 2, pxpSwitchData.PersistenceData.DOOR2) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end

        --Com Select
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV1_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/nav1_power", pxpSwitchData.PersistenceData.NAV1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV2_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/nav2_power", pxpSwitchData.PersistenceData.NAV2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.COM1_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/com1_power", pxpSwitchData.PersistenceData.COM1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.COM2_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/com2_power", pxpSwitchData.PersistenceData.COM2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF1_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/adf1_power", pxpSwitchData.PersistenceData.ADF1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF2_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/adf2_power", pxpSwitchData.PersistenceData.ADF2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps_power") ~= nil) then
            if pxpSwitchData.PersistenceData.GPS1_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/gps_power", pxpSwitchData.PersistenceData.GPS1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.GPS2_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/gps2_power", pxpSwitchData.PersistenceData.GPS2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/dme_power") ~= nil) then
            if pxpSwitchData.PersistenceData.DME_PWR ~= nil then
                set("sim/cockpit2/radios/actuators/dme_power", pxpSwitchData.PersistenceData.DME_PWR)
            end
        end


        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_com_selection_man") ~= nil) then
            if pxpSwitchData.PersistenceData.XMT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_com_selection_man", pxpSwitchData.PersistenceData.XMT) -- Transmit Selector
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com1") ~= nil) then
            if pxpSwitchData.PersistenceData.C1_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_com1", pxpSwitchData.PersistenceData.C1_RCV) -- Com 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com2") ~= nil) then
            if pxpSwitchData.PersistenceData.C2_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_com2", pxpSwitchData.PersistenceData.C2_RCV) -- Com 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf1") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF1_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_adf1", pxpSwitchData.PersistenceData.ADF1_RCV) -- ADF 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf2") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF2_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_adf2", pxpSwitchData.PersistenceData.ADF2_RCV) -- ADF 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav1") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV1_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_nav1", pxpSwitchData.PersistenceData.NAV1_RCV) -- NAV 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav2") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV2_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_nav2", pxpSwitchData.PersistenceData.NAV2_RCV) -- NAV 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_dme_enabled") ~= nil) then
            if pxpSwitchData.PersistenceData.DME1_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_dme_enabled", pxpSwitchData.PersistenceData.DME1_RCV) -- DME Recieve
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_marker_enabled") ~= nil) then
            if pxpSwitchData.PersistenceData.MRKR_RCV ~= nil then
                set("sim/cockpit2/radios/actuators/audio_marker_enabled", pxpSwitchData.PersistenceData.MRKR_RCV) -- Marker Recieve
            end
        end


        if (XPLMFindDataRef("sim/cockpit/radios/com1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.COM1_ACT ~= nil then
                set("sim/cockpit/radios/com1_freq_hz", pxpSwitchData.PersistenceData.COM1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.COM1_STB ~= nil then
                set("sim/cockpit/radios/com1_stdby_freq_hz", pxpSwitchData.PersistenceData.COM1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.COM2_ACT ~= nil then
                set("sim/cockpit/radios/com2_freq_hz", pxpSwitchData.PersistenceData.COM2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.COM2_STB ~= nil then
                set("sim/cockpit/radios/com2_stdby_freq_hz", pxpSwitchData.PersistenceData.COM2_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV1_ACT ~= nil then
                set("sim/cockpit/radios/nav1_freq_hz", pxpSwitchData.PersistenceData.NAV1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV1_STB ~= nil then
                set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV2_ACT ~= nil then
                set("sim/cockpit/radios/nav2_freq_hz", pxpSwitchData.PersistenceData.NAV2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.NAV2_STB ~= nil then
                set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV2_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF1_ACT ~= nil then
                set("sim/cockpit/radios/adf1_freq_hz", pxpSwitchData.PersistenceData.ADF1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF1_STB ~= nil then
                set("sim/cockpit/radios/adf1_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF2_ACT ~= nil then
                set("sim/cockpit/radios/adf2_freq_hz", pxpSwitchData.PersistenceData.ADF2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.ADF2_STB ~= nil then
                set("sim/cockpit/radios/adf2_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF2_STB)  
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/transponder_code") ~= nil) then
            if pxpSwitchData.PersistenceData.XPDR_COD ~= nil then
                set("sim/cockpit/radios/transponder_code", pxpSwitchData.PersistenceData.XPDR_COD)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/transponder_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.XPDR_MODE ~= nil then
                set("sim/cockpit2/radios/actuators/transponder_mode", pxpSwitchData.PersistenceData.XPDR_MODE)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/clock_timer/timer_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.CLK_MODE ~= nil then
                set("sim/cockpit2/clock_timer/timer_mode", pxpSwitchData.PersistenceData.CLK_MODE)
            end
        end

        -- Nav Related
        if (XPLMFindDataRef("sim/cockpit/gyros/gyr_free_slaved", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.GYROSL ~= nil then
                set_array("sim/cockpit/gyros/gyr_free_slaved", 0, pxpSwitchData.PersistenceData.GYROSL)
            end
        end        
        if (XPLMFindDataRef("sim/cockpit/gyros/gyr_free_slaved", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.GYROSR ~= nil then
                set_array("sim/cockpit/gyros/gyr_free_slaved", 1, pxpSwitchData.PersistenceData.GYROSR)
            end
        end      

        if (XPLMFindDataRef("sim/cockpit/autopilot/heading_mag") ~= nil) then
            if pxpSwitchData.PersistenceData.HDG ~= nil then
                set("sim/cockpit/autopilot/heading_mag", pxpSwitchData.PersistenceData.HDG)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/autopilot/vvi_dial_fpm") ~= nil) then
            if pxpSwitchData.PersistenceData.VS ~= nil then
                set("sim/cockpit2/autopilot/vvi_dial_fpm", pxpSwitchData.PersistenceData.VS)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/autopilot/altitude_dial_ft") ~= nil) then
            if pxpSwitchData.PersistenceData.APA ~= nil then
                set("sim/cockpit2/autopilot/altitude_dial_ft", pxpSwitchData.PersistenceData.APA)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/autopilot/airspeed") ~= nil) then
            if pxpSwitchData.PersistenceData.SPD_BG ~= nil then
                set("sim/cockpit/autopilot/airspeed", pxpSwitchData.PersistenceData.SPD_BG) -- Speed Bug
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/RMI_l_vor_adf_selector") ~= nil) then
            if pxpSwitchData.PersistenceData.RMI_L ~= nil then
                set("sim/cockpit/switches/RMI_l_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_L) -- Left RMI
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/RMI_r_vor_adf_selector") ~= nil) then
            if pxpSwitchData.PersistenceData.RMI_R ~= nil then
                set("sim/cockpit/switches/RMI_r_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_R) -- Right RMI
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/DME_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.DME_CH ~= nil then
                set("sim/cockpit2/radios/actuators/DME_mode", pxpSwitchData.PersistenceData.DME_CH)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/DME_distance_or_time") ~= nil) then
            if pxpSwitchData.PersistenceData.DME_SEL ~= nil then
                set("sim/cockpit/switches/DME_distance_or_time", pxpSwitchData.PersistenceData.DME_SEL)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/misc/radio_altimeter_minimum") ~= nil) then
            if pxpSwitchData.PersistenceData.DH ~= nil then
                set("sim/cockpit/misc/radio_altimeter_minimum", pxpSwitchData.PersistenceData.DH)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav1_obs_degm") ~= nil) then
            if pxpSwitchData.PersistenceData.CRS1 ~= nil then
                set("sim/cockpit/radios/nav1_obs_degm", pxpSwitchData.PersistenceData.CRS1)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav2_obs_degm") ~= nil) then
            if pxpSwitchData.PersistenceData.CRS2 ~= nil then
                set("sim/cockpit/radios/nav2_obs_degm", pxpSwitchData.PersistenceData.CRS2)
            end
        end

        -- Engines
        if (XPLMFindDataRef("sim/cockpit/engine/igniters_on", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.IGN1 ~= nil then
                set_array("sim/cockpit/engine/igniters_on", 0, pxpSwitchData.PersistenceData.IGN1) -- Ignition 0 Left 1 Right
            end
        end        
        if (XPLMFindDataRef("sim/cockpit/engine/igniters_on", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.IGN2 ~= nil then
                set_array("sim/cockpit/engine/igniters_on", 1, pxpSwitchData.PersistenceData.IGN2)
            end
        end        
        if (XPLMFindDataRef("sim/cockpit/engine/ignition_on", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.MAG1 ~= nil then
                set_array("sim/cockpit/engine/ignition_on", 0, pxpSwitchData.PersistenceData.MAG1) -- Ignition 0 Left 1 Right
            end
        end        
        if (XPLMFindDataRef("sim/cockpit/engine/ignition_on", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.MAG2 ~= nil then
                set_array("sim/cockpit/engine/ignition_on", 1, pxpSwitchData.PersistenceData.MAG2)
            end
        end

        -- Fuel
        if (XPLMFindDataRef("sim/cockpit/engine/fuel_pump_on", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.BOOST_PMP1 ~= nil then
                set_array("sim/cockpit/engine/fuel_pump_on", 0, pxpSwitchData.PersistenceData.BOOST_PMP1) -- Fuel Pumps, 0 Left, 1 Right
            end
        end
        if (XPLMFindDataRef("sim/cockpit/engine/fuel_pump_on", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.BOOST_PMP2 ~= nil then
                set_array("sim/cockpit/engine/fuel_pump_on", 1, pxpSwitchData.PersistenceData.BOOST_PMP2)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.FUEL0 ~= nil then
                set_array("sim/cockpit2/fuel/fuel_quantity", 0, pxpSwitchData.PersistenceData.FUEL0)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.FUEL1 ~= nil then
                set_array("sim/cockpit2/fuel/fuel_quantity", 1, pxpSwitchData.PersistenceData.FUEL1)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.FUEL2 ~= nil then
                set_array("sim/cockpit2/fuel/fuel_quantity", 2, pxpSwitchData.PersistenceData.FUEL2)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 3) ~= nil) then
            if pxpSwitchData.PersistenceData.FUEL3 ~= nil then
                set_array("sim/cockpit2/fuel/fuel_quantity", 3, pxpSwitchData.PersistenceData.FUEL3)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_totalizer_sum_kg") ~= nil) then
            if pxpSwitchData.PersistenceData.FUEL_TTL ~= nil then
                set("sim/cockpit2/fuel/fuel_totalizer_sum_kg", pxpSwitchData.PersistenceData.FUEL_TTL)
            end
        end

        -- Ice Protection
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_pitot_heat_on_pilot") ~= nil) then
            if pxpSwitchData.PersistenceData.PIT1_HT ~= nil then
                set("sim/cockpit2/ice/ice_pitot_heat_on_pilot", pxpSwitchData.PersistenceData.PIT1_HT) -- Pitot Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_static_heat_on_pilot") ~= nil) then
            if pxpSwitchData.PersistenceData.STAT1_HT ~= nil then
                set("sim/cockpit2/ice/ice_static_heat_on_pilot", pxpSwitchData.PersistenceData.STAT1_HT) -- Static Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_AOA_heat_on") ~= nil) then
            if pxpSwitchData.PersistenceData.AOA1_HT ~= nil then
                set("sim/cockpit2/ice/ice_AOA_heat_on", pxpSwitchData.PersistenceData.AOA1_HT) -- AOA Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_pitot_heat_on_copilot") ~= nil) then
            if pxpSwitchData.PersistenceData.PIT2_HT ~= nil then
                set("sim/cockpit2/ice/ice_pitot_heat_on_copilot", pxpSwitchData.PersistenceData.PIT2_HT) -- Pitot Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_static_heat_on_copilot") ~= nil) then
            if pxpSwitchData.PersistenceData.STAT2_HT ~= nil then
                set("sim/cockpit2/ice/ice_static_heat_on_copilot", pxpSwitchData.PersistenceData.STAT2_HT) -- Static Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_AOA_heat_on_copilot") ~= nil) then
            if pxpSwitchData.PersistenceData.AOA2_HT ~= nil then
                set("sim/cockpit2/ice/ice_AOA_heat_on_copilot", pxpSwitchData.PersistenceData.AOA2_HT) -- AOA Heat
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_window_heat_on") ~= nil) then
            if pxpSwitchData.PersistenceData.WS_BLD ~= nil then
                set("sim/cockpit2/ice/ice_window_heat_on", pxpSwitchData.PersistenceData.WS_BLD) -- Window Bleed
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.INLET1_AI ~= nil then
                set_array("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 0, pxpSwitchData.PersistenceData.INLET1_AI) -- 0 Left 1 Right
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.INLET2_AI ~= nil then
                set_array("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 1, pxpSwitchData.PersistenceData.INLET2_AI)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/anti_ice_engine_air", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.ENG_AI1 ~= nil then
                set_array("sim/cockpit/switches/anti_ice_engine_air", 0, pxpSwitchData.PersistenceData.ENG_AI1) -- 0 Left 1 Right
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/anti_ice_engine_air", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.ENG_AI2 ~= nil then
                set_array("sim/cockpit/switches/anti_ice_engine_air", 1, pxpSwitchData.PersistenceData.ENG_AI2)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_surface_boot_on") ~= nil) then
            if pxpSwitchData.PersistenceData.WING_BOOT ~= nil then
                set("sim/cockpit2/ice/ice_surface_boot_on", pxpSwitchData.PersistenceData.WING_BOOT) 
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_surfce_heat_on") ~= nil) then
            if pxpSwitchData.PersistenceData.WING_HEAT ~= nil then
                set("sim/cockpit2/ice/ice_surfce_heat_on", pxpSwitchData.PersistenceData.WING_HEAT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/ice/ice_prop_heat_on") ~= nil) then
            if pxpSwitchData.PersistenceData.PROP_HEAT ~= nil then
                set("sim/cockpit2/ice/ice_prop_heat_on", pxpSwitchData.PersistenceData.PROP_HEAT)
            end
        end

        -- Controls
        if (XPLMFindDataRef("sim/cockpit2/controls/elevator_trim") ~= nil) then
            if pxpSwitchData.PersistenceData.TRIM ~= nil then
                set("sim/cockpit2/controls/elevator_trim", pxpSwitchData.PersistenceData.TRIM)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/controls/speedbrake_ratio") ~= nil) then
            if pxpSwitchData.PersistenceData.SPD_BRK ~= nil then
                set("sim/cockpit2/controls/speedbrake_ratio", pxpSwitchData.PersistenceData.SPD_BRK)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/controls/flap_ratio") ~= nil) then
            if pxpSwitchData.PersistenceData.FLP_HNDL ~= nil then
                set("sim/cockpit2/controls/flap_ratio", pxpSwitchData.PersistenceData.FLP_HNDL)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/jet_sync_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.FAN_SYNC ~= nil then
                set("sim/cockpit2/switches/jet_sync_mode", pxpSwitchData.PersistenceData.FAN_SYNC)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/prop_sync_on") ~= nil) then
            if pxpSwitchData.PersistenceData.PROP_SYNC ~= nil then
                set("sim/cockpit2/switches/prop_sync_on", pxpSwitchData.PersistenceData.PROP_SYNC)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/throttle_ratio_all") ~= nil) then
            if pxpSwitchData.PersistenceData.THRTL ~= nil then
                set("sim/cockpit2/engine/actuators/throttle_ratio_all", pxpSwitchData.PersistenceData.THRTL)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/prop_ratio_all") ~= nil) then
            if pxpSwitchData.PersistenceData.PROP ~= nil then
                set("sim/cockpit2/engine/actuators/prop_ratio_all", pxpSwitchData.PersistenceData.PROP)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/mixture_ratio_all") ~= nil) then
            if pxpSwitchData.PersistenceData.MIX ~= nil then
                set("sim/cockpit2/engine/actuators/mixture_ratio_all", pxpSwitchData.PersistenceData.MIX)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/carb_heat_ratio", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.CARB1 ~= nil then
                set_array("sim/cockpit2/engine/actuators/carb_heat_ratio", 0, pxpSwitchData.PersistenceData.CARB1)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/carb_heat_ratio", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.CARB2 ~= nil then
                set_array("sim/cockpit2/engine/actuators/carb_heat_ratio", 1, pxpSwitchData.PersistenceData.CARB2)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/cowl_flap_ratio", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.COWL1 ~= nil then
                set_array("sim/cockpit2/engine/actuators/cowl_flap_ratio", 0, pxpSwitchData.PersistenceData.COWL1)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/engine/actuators/cowl_flap_ratio", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.COWL2 ~= nil then
                set_array("sim/cockpit2/engine/actuators/cowl_flap_ratio", 1, pxpSwitchData.PersistenceData.COWL2)
            end
        end

        if (XPLMFindDataRef("sim/cockpit2/pressurization/actuators/cabin_altitude_ft") ~= nil) then
            if pxpSwitchData.PersistenceData.CAB_ALT ~= nil then
                set("sim/cockpit2/pressurization/actuators/cabin_altitude_ft", pxpSwitchData.PersistenceData.CAB_ALT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm") ~= nil) then
            if pxpSwitchData.PersistenceData.CAB_RATE ~= nil then
                set("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm", pxpSwitchData.PersistenceData.CAB_RATE)
            end
        end

        -- Internal Lights

        if (XPLMFindDataRef("sim/cockpit/switches/fasten_seat_belts") ~= nil) then
            if pxpSwitchData.PersistenceData.ST_BLT ~= nil then
                set("sim/cockpit/switches/fasten_seat_belts", pxpSwitchData.PersistenceData.ST_BLT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/switches/no_smoking") ~= nil) then
            if pxpSwitchData.PersistenceData.NO_SMK ~= nil then
                set("sim/cockpit/switches/no_smoking", pxpSwitchData.PersistenceData.NO_SMK)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT0 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 0, pxpSwitchData.PersistenceData.PNL_LT0)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT1 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 1, pxpSwitchData.PersistenceData.PNL_LT1)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT2 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 2, pxpSwitchData.PersistenceData.PNL_LT2)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 3) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT3 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 3, pxpSwitchData.PersistenceData.PNL_LT3)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 4) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT4 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 4, pxpSwitchData.PersistenceData.PNL_LT4)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 5) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT5 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 5, pxpSwitchData.PersistenceData.PNL_LT5)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 6) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT6 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 6, pxpSwitchData.PersistenceData.PNL_LT6)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 7) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT7 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 7, pxpSwitchData.PersistenceData.PNL_LT7)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 8) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT8 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 8, pxpSwitchData.PersistenceData.PNL_LT8)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 9) ~= nil) then
            if pxpSwitchData.PersistenceData.PNL_LT9 ~= nil then
                set_array("sim/cockpit2/switches/panel_brightness_ratio", 9, pxpSwitchData.PersistenceData.PNL_LT9)
            end
        end
        -- Carenado Citaion II

        if loadedAircraft == 'S550_Citation_II.acf' then
            if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("thranda/cockpit/actuators/HideYokeL", pxpSwitchData.PersistenceData.LYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeR") ~= nil) then
                if pxpSwitchData.PersistenceData.RYOKE ~= nil then
                    set("thranda/cockpit/actuators/HideYokeR", pxpSwitchData.PersistenceData.RYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
                if pxpSwitchData.PersistenceData.LARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
                if pxpSwitchData.PersistenceData.RARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/generic_lights_switch", 30) ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_LT ~= nil then
                    set_array("sim/cockpit2/switches/generic_lights_switch", 30, pxpSwitchData.PersistenceData.PNL_LT)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 1) ~= nil) then
                if pxpSwitchData.PersistenceData.FLOOD_LT ~= nil then
                    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 1, pxpSwitchData.PersistenceData.FLOOD_LT)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 2) ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_LFT ~= nil then
                    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 2, pxpSwitchData.PersistenceData.PNL_LFT)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 3) ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_CTR ~= nil then
                    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 3, pxpSwitchData.PersistenceData.PNL_CTR)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 4) ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_RT ~= nil then
                    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 4, pxpSwitchData.PersistenceData.PNL_RT)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/instrument_brightness_ratio", 5) ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_EL ~= nil then
                    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 5, pxpSwitchData.PersistenceData.PNL_EL)
                end
            end
            if (XPLMFindDataRef("thranda/electrical/AC_InverterSwitch") ~= nil) then
                if pxpSwitchData.PersistenceData.INV ~= nil then
                    set("thranda/electrical/AC_InverterSwitch", pxpSwitchData.PersistenceData.INV)
                end
            end
            if (XPLMFindDataRef("thranda/views/WindowRefl") ~= nil) then
                if pxpSwitchData.PersistenceData.WREFL ~= nil then
                    set("thranda/views/WindowRefl", pxpSwitchData.PersistenceData.WREFL)
                end
            end
            if (XPLMFindDataRef("thranda/views/InstRefl") ~= nil) then
                if pxpSwitchData.PersistenceData.IREFL ~= nil then
                    set("thranda/views/InstRefl", pxpSwitchData.PersistenceData.IREFL)
                end
            end
            if (XPLMFindDataRef("thranda/views/staticelements") ~= nil) then
                if pxpSwitchData.PersistenceData.COVERS ~= nil then
                    set("thranda/views/staticelements", pxpSwitchData.PersistenceData.COVERS)
                end
            end
            if (XPLMFindDataRef("thranda/actuators/VoltSelAct") ~= nil) then
                if pxpSwitchData.PersistenceData.VOLT_SEL ~= nil then
                    set("thranda/actuators/VoltSelAct", pxpSwitchData.PersistenceData.VOLT_SEL)
                end
            end
            if (XPLMFindDataRef("thranda/annunciators/AnnunTestKnob") ~= nil) then
                if pxpSwitchData.PersistenceData.TEST_SEL ~= nil then
                    set("thranda/annunciators/AnnunTestKnob", pxpSwitchData.PersistenceData.TEST_SEL)
                end
            end
            if (XPLMFindDataRef("thranda/fuel/CrossFeedLRSw") ~= nil) then
                if pxpSwitchData.PersistenceData.FUEL_SEL ~= nil then
                    set("thranda/fuel/CrossFeedLRSw", pxpSwitchData.PersistenceData.FUEL_SEL)
                end
            end
            if (XPLMFindDataRef("thranda/lights/RecogLights") ~= nil) then
                if pxpSwitchData.PersistenceData.RECOG ~= nil then
                    set("thranda/lights/RecogLights", pxpSwitchData.PersistenceData.RECOG)
                end
            end
            if (XPLMFindDataRef("thranda/instruments/BaroUnits") ~= nil) then
                if pxpSwitchData.PersistenceData.BARO_UNIT ~= nil then
                    set("thranda/instruments/BaroUnits", pxpSwitchData.PersistenceData.BARO_UNIT)
                end
            end
            if (XPLMFindDataRef("thranda/knobs/N1_Dial") ~= nil) then
                if pxpSwitchData.PersistenceData.N1_DIAL ~= nil then
                    set("thranda/knobs/N1_Dial", pxpSwitchData.PersistenceData.N1_DIAL)
                end
            end
            if (XPLMFindDataRef("thranda/lights/LandingLightLeft") ~= nil) then
                if pxpSwitchData.PersistenceData.L_LND ~= nil then
                    set("thranda/lights/LandingLightLeft", pxpSwitchData.PersistenceData.L_LND)
                end
            end
            if (XPLMFindDataRef("thranda/lights/LandingLightRight") ~= nil) then
                if pxpSwitchData.PersistenceData.R_LND ~= nil then
                    set("thranda/lights/LandingLightRight", pxpSwitchData.PersistenceData.R_LND)
                end
            end
            if (XPLMFindDataRef("thranda/gear/AntiSkid") ~= nil) then
                if pxpSwitchData.PersistenceData.ASKID ~= nil then
                    set("thranda/gear/AntiSkid", pxpSwitchData.PersistenceData.ASKID)
                end
            end
            if (XPLMFindDataRef( "thranda/BT", 22) ~= nil) then
                if pxpSwitchData.PersistenceData.TEMP_MAN ~= nil then
                    set_array( "thranda/BT", 22, pxpSwitchData.PersistenceData.TEMP_MAN)
                end
            end
            if (XPLMFindDataRef( "thranda/BT", 2) ~= nil) then
                if pxpSwitchData.PersistenceData.NAV_IDENT ~= nil then
                    set_array( "thranda/BT", 2, pxpSwitchData.PersistenceData.NAV_IDENT)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/CabinTempAct") ~= nil) then
                if pxpSwitchData.PersistenceData.TEMP_CTRL ~= nil then
                    set("thranda/pneumatic/CabinTempAct", pxpSwitchData.PersistenceData.TEMP_CTRL)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/PressureSource") ~= nil) then
                if pxpSwitchData.PersistenceData.PRES_SRC ~= nil then
                    set("thranda/pneumatic/PressureSource", pxpSwitchData.PersistenceData.PRES_SRC)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/AirFlowDistribution") ~= nil) then
                if pxpSwitchData.PersistenceData.FLOW_DIST ~= nil then
                    set("thranda/pneumatic/AirFlowDistribution", pxpSwitchData.PersistenceData.FLOW_DIST)
                end
            end
            if (XPLMFindDataRef("thranda/ice/WindshieldIceL") ~= nil) then
                if pxpSwitchData.PersistenceData.L_WS ~= nil then
                    set("thranda/ice/WindshieldIceL", pxpSwitchData.PersistenceData.L_WS)
                end
            end
            if (XPLMFindDataRef("thranda/ice/WindshieldIceR") ~= nil) then
                if pxpSwitchData.PersistenceData.R_WS ~= nil then
                    set("thranda/ice/WindshieldIceR", pxpSwitchData.PersistenceData.R_WS)
                end
            end
            if (XPLMFindDataRef( "thranda/BT", 23) ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN1 ~= nil then
                    set_array( "thranda/BT", 23, pxpSwitchData.PersistenceData.CAB_FAN1)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/CabinFan") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN2 ~= nil then
                    set("thranda/pneumatic/CabinFan", pxpSwitchData.PersistenceData.CAB_FAN2)
                end
            end
            if (XPLMFindDataRef( "thranda/BT", 24) ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FOG ~= nil then
                    set_array( "thranda/BT", 24, pxpSwitchData.PersistenceData.CAB_FOG)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/AC") ~= nil) then
                if pxpSwitchData.PersistenceData.AC ~= nil then
                    set("thranda/pneumatic/AC", pxpSwitchData.PersistenceData.AC)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/BlowerIntensity") ~= nil) then
                if pxpSwitchData.PersistenceData.BLWR ~= nil then
                    set("thranda/pneumatic/BlowerIntensity", pxpSwitchData.PersistenceData.BLWR)
                end
            end
            if (XPLMFindDataRef("thranda/pneumatic/CabinVent") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_VNT ~= nil then
                    set("thranda/pneumatic/CabinVent", pxpSwitchData.PersistenceData.CAB_VNT)
                end
            end
            if (XPLMFindDataRef( "thranda/BT", 32) ~= nil) then
                if pxpSwitchData.PersistenceData.MIC_SEL ~= nil then
                    set_array( "thranda/BT", 32, pxpSwitchData.PersistenceData.MIC_SEL)
                end
            end
            if ENG1_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
                if (XPLMFindDataRef("thranda/cockpit/ThrottleLatchAnim_0") ~= nil) then
                    set("thranda/cockpit/ThrottleLatchAnim_0", 0.5)
                    print("Command Shut 1")
                end
            end
            if ENG2_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
                if (XPLMFindDataRef("thranda/cockpit/ThrottleLatchAnim_1") ~= nil) then
                    set("thranda/cockpit/ThrottleLatchAnim_1", 0.5)
                    print("Command Shut 2")
                end
            end
        else
            print("PXP Skipping Carenado Citation II Ref's")
        end

        -- Carenado PC12

        if loadedAircraft == 'Car_PC12.acf' then
            if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("thranda/cockpit/actuators/HideYokeL", pxpSwitchData.PersistenceData.LYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeR") ~= nil) then
                if pxpSwitchData.PersistenceData.RYOKE ~= nil then
                    set("thranda/cockpit/actuators/HideYokeR", pxpSwitchData.PersistenceData.RYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
                if pxpSwitchData.PersistenceData.LARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
                if pxpSwitchData.PersistenceData.RARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/VisorSwingL") ~= nil) then
                if pxpSwitchData.PersistenceData.LVISARM ~= nil then
                    set("thranda/cockpit/actuators/VisorSwingL", pxpSwitchData.PersistenceData.LVISARM)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/VisorL") ~= nil) then
                if pxpSwitchData.PersistenceData.LVIS ~= nil then
                    set("thranda/cockpit/actuators/VisorL", pxpSwitchData.PersistenceData.LVIS)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/VisorSwingL") ~= nil) then
                if pxpSwitchData.PersistenceData.RVISARM ~= nil then
                    set("thranda/cockpit/actuators/VisorSwingR", pxpSwitchData.PersistenceData.RVISARM)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/actuators/VisorL") ~= nil) then
                if pxpSwitchData.PersistenceData.RVIS ~= nil then
                    set("thranda/cockpit/actuators/VisorR", pxpSwitchData.PersistenceData.RVIS)
                end
            end
        else
            print("PXP Skipping Carenado PC12 Ref's")
        end

        -- Carenado C208 HD

        if loadedAircraft == 'C208B_EX_XP11.acf' or 'Car_C208B.acf' then
            if (XPLMFindDataRef("Carenado/Switch/Dummy/Dummy1") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("Carenado/Switch/Dummy/Dummy1", pxpSwitchData.PersistenceData.LYOKE)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/Dummy/Dummy2") ~= nil) then
                if pxpSwitchData.PersistenceData.RYOKE ~= nil then
                    set("Carenado/Switch/Dummy/Dummy2", pxpSwitchData.PersistenceData.RYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
                if pxpSwitchData.PersistenceData.LARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
                if pxpSwitchData.PersistenceData.RARM ~= nil then
                    set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
                end
            end
            if (XPLMFindDataRef("com/dkmp/cargopod") ~= nil) then
                if pxpSwitchData.PersistenceData.CARGOPOD ~= nil then
                    set("com/dkmp/cargopod", pxpSwitchData.PersistenceData.CARGOPOD)
                end
            end
            if (XPLMFindDataRef("com/dkmp/FuelBoost") ~= nil) then
                if pxpSwitchData.PersistenceData.BOOST_PMP1 ~= nil then
                    set("com/dkmp/FuelBoost", pxpSwitchData.PersistenceData.BOOST_PMP1)
                end
            end
            if (XPLMFindDataRef("com/dkmp/StbyPwr") ~= nil) then
                if pxpSwitchData.PersistenceData.STB_PWR ~= nil then
                    set("com/dkmp/StbyPwr", pxpSwitchData.PersistenceData.STB_PWR)
                end
            end
            if (XPLMFindDataRef("com/dkmp/Ignition") ~= nil) then
                if pxpSwitchData.PersistenceData.IGN1 ~= nil then
                    set("com/dkmp/Ignition", pxpSwitchData.PersistenceData.IGN1)
                end
            end
            if (XPLMFindDataRef("com/dkmp/Starter") ~= nil) then
                if pxpSwitchData.PersistenceData.STRT1 ~= nil then
                    set("com/dkmp/Starter", pxpSwitchData.PersistenceData.STRT1)
                end
            end
            if (XPLMFindDataRef("com/dkmp/AmpsVoltsSwitch") ~= nil) then
                if pxpSwitchData.PersistenceData.DCAMP ~= nil then
                    set("com/dkmp/AmpsVoltsSwitch", pxpSwitchData.PersistenceData.DCAMP)
                end
            end
            if (XPLMFindDataRef("sim/cockpit2/switches/generic_lights_switch", 30) ~= nil) then
                if pxpSwitchData.PersistenceData.WING_LT ~= nil then
                    set_array("sim/cockpit2/switches/generic_lights_switch", 30, pxpSwitchData.PersistenceData.WING_LT)
                end
            end
            if (XPLMFindDataRef("com/dkmp/Ventilate") ~= nil) then
                if pxpSwitchData.PersistenceData.AC ~= nil then
                    set("com/dkmp/Ventilate", pxpSwitchData.PersistenceData.AC)
                end
            end
            if (XPLMFindDataRef("com/dkmp/ACFansLeft") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN1 ~= nil then
                    set("com/dkmp/ACFansLeft", pxpSwitchData.PersistenceData.CAB_FAN1)
                end
            end
            if (XPLMFindDataRef("com/dkmp/ACFansRight") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN2 ~= nil then
                    set("com/dkmp/ACFansRight", pxpSwitchData.PersistenceData.CAB_FAN2)
                end
            end
            if (XPLMFindDataRef("com/dkmp/ACFansAft") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN3 ~= nil then
                    set("com/dkmp/ACFansAft", pxpSwitchData.PersistenceData.CAB_FAN3)
                end
            end
            if (XPLMFindDataRef("com/dkmp/TempHot") ~= nil) then
                if pxpSwitchData.PersistenceData.TEMP_CTRL ~= nil then
                    set("com/dkmp/TempHot", pxpSwitchData.PersistenceData.TEMP_CTRL)
                end
            end
            if (XPLMFindDataRef("com/dkmp/PanelLit") ~= nil) then
                if pxpSwitchData.PersistenceData.PNL_LT ~= nil then
                    set("com/dkmp/PanelLit", pxpSwitchData.PersistenceData.PNL_LT)
                end
            end
            if (XPLMFindDataRef("com/dkmp/AnnunLITsw") ~= nil) then
                if pxpSwitchData.PersistenceData.ANNUN_DIM ~= nil then
                    set("com/dkmp/AnnunLITsw", pxpSwitchData.PersistenceData.ANNUN_DIM)
                end
            end
            if (XPLMFindDataRef("com/dkmp/Throttle") ~= nil) then
                if pxpSwitchData.PersistenceData.THRTL ~= nil then
                    set("com/dkmp/Throttle", pxpSwitchData.PersistenceData.THRTL)
                end
            end
            if (XPLMFindDataRef("sim/flightmodel/engine/ENGN_prop") ~= nil) then
                if pxpSwitchData.PersistenceData.PROP ~= nil then
                    set_array("sim/flightmodel/engine/ENGN_prop", 0, pxpSwitchData.PersistenceData.PROP)
                end
            end
            if (XPLMFindDataRef("com/dkmp/FuelSwL") ~= nil) then
                if pxpSwitchData.PersistenceData.FUEL_SEL_L ~= nil then
                    set("com/dkmp/FuelSwL", pxpSwitchData.PersistenceData.FUEL_SEL_L)
                end
            end
            if (XPLMFindDataRef("com/dkmp/FuelSwR") ~= nil) then
                if pxpSwitchData.PersistenceData.FUEL_SEL_R ~= nil then
                    set("com/dkmp/FuelSwR", pxpSwitchData.PersistenceData.FUEL_SEL_R)
                end
            end

            

            -- C208 EX
            if (XPLMFindDataRef("Carenado/visibilities/CargoPod") ~= nil) then
                if pxpSwitchData.PersistenceData.CARGOPOD ~= nil then
                    set("Carenado/visibilities/CargoPod", pxpSwitchData.PersistenceData.CARGOPOD)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/PropHeat") ~= nil) then
                if pxpSwitchData.PersistenceData.PROP_HEAT ~= nil then
                    set("Carenado/Switch/dummy/PropHeat", pxpSwitchData.PersistenceData.PROP_HEAT)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/PowerOutlet") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_UTIL ~= nil then
                    set("Carenado/Switch/dummy/PowerOutlet", pxpSwitchData.PersistenceData.CAB_UTIL)
                end
            end
            if (XPLMFindDataRef("Carenado/lights/CortesyLight") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_LT ~= nil then
                    set("Carenado/lights/CortesyLight", pxpSwitchData.PersistenceData.CAB_LT)
                end
            end
            if (XPLMFindDataRef("Carenado/Heat/StallHeat") ~= nil) then
                if pxpSwitchData.PersistenceData.STALL_HT ~= nil then
                    set("Carenado/Heat/StallHeat", pxpSwitchData.PersistenceData.STALL_HT)
                end
            end
            if (XPLMFindDataRef("Carenado/lights/WingLight") ~= nil) then
                if pxpSwitchData.PersistenceData.WING_LT ~= nil then
                    set("Carenado/lights/WingLight", pxpSwitchData.PersistenceData.WING_LT)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/FuelBoost") ~= nil) then
                if pxpSwitchData.PersistenceData.BOOST_PMP1 ~= nil then
                    set("Carenado/Switch/dummy/FuelBoost", pxpSwitchData.PersistenceData.BOOST_PMP1)
                end
            end
            if (XPLMFindDataRef("Carenado/battery/StbyBatt") ~= nil) then
                if pxpSwitchData.PersistenceData.STB_PWR ~= nil then
                    set("Carenado/battery/StbyBatt", pxpSwitchData.PersistenceData.STB_PWR)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/Ignition") ~= nil) then
                if pxpSwitchData.PersistenceData.IGN1 ~= nil then
                    set("Carenado/Switch/Ignition", pxpSwitchData.PersistenceData.IGN1)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/Starter") ~= nil) then
                if pxpSwitchData.PersistenceData.STRT1 ~= nil then
                    set("Carenado/Switch/dummy/Starter", pxpSwitchData.PersistenceData.STRT1)
                end
            end
            if (XPLMFindDataRef("Carenado/lights/leftFloodLight") ~= nil) then
                if pxpSwitchData.PersistenceData.FLOOD_LFT ~= nil then
                    set("Carenado/lights/leftFloodLight", pxpSwitchData.PersistenceData.FLOOD_LFT)
                end
            end
            if (XPLMFindDataRef("Carenado/lights/rightFloodLight") ~= nil) then
                if pxpSwitchData.PersistenceData.FLOOD_RT ~= nil then
                    set("Carenado/lights/rightFloodLight", pxpSwitchData.PersistenceData.FLOOD_RT)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioning") ~= nil) then
                if pxpSwitchData.PersistenceData.AC ~= nil then
                    set("Carenado/Switch/dummy/AirConditioning", pxpSwitchData.PersistenceData.AC)
                end
            end

            if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningLeft") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN1 ~= nil then
                    set("Carenado/Switch/dummy/AirConditioningLeft", pxpSwitchData.PersistenceData.CAB_FAN1)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningRigth") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN2 ~= nil then
                    set("Carenado/Switch/dummy/AirConditioningRigth", pxpSwitchData.PersistenceData.CAB_FAN2)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/AirConditioningAft") ~= nil) then
                if pxpSwitchData.PersistenceData.CAB_FAN3 ~= nil then
                    set("Carenado/Switch/dummy/AirConditioningAft", pxpSwitchData.PersistenceData.CAB_FAN3)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/TempBleedAir") ~= nil) then
                if pxpSwitchData.PersistenceData.TEMP_CTRL ~= nil then
                    set("Carenado/Switch/dummy/TempBleedAir", pxpSwitchData.PersistenceData.TEMP_CTRL)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/BleedAir") ~= nil) then
                if pxpSwitchData.PersistenceData.BLEED_AIR ~= nil then
                    set("Carenado/Switch/dummy/BleedAir", pxpSwitchData.PersistenceData.BLEED_AIR)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/FuelSelectorL") ~= nil) then
                if pxpSwitchData.PersistenceData.FUEL_SEL_L ~= nil then
                    set("Carenado/Switch/dummy/FuelSelectorL", pxpSwitchData.PersistenceData.FUEL_SEL_L)
                end
            end
            if (XPLMFindDataRef("Carenado/Switch/dummy/FuelSelectorR") ~= nil) then
                if pxpSwitchData.PersistenceData.FUEL_SEL_R ~= nil then
                    set("Carenado/Switch/dummy/FuelSelectorR", pxpSwitchData.PersistenceData.FUEL_SEL_R)
                end
            end
            if (XPLMFindDataRef("Carenado/Cockpit/RestArmL") ~= nil) then
                if pxpSwitchData.PersistenceData.LARM ~= nil then
                    set("Carenado/Cockpit/RestArmL", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
                end
            end
            if (XPLMFindDataRef("Carenado/Cockpit/RestArmR") ~= nil) then
                if pxpSwitchData.PersistenceData.RARM ~= nil then
                    set("Carenado/Cockpit/RestArmR", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
                end
            end
        else
            print("PXP Skipping Carenado C208 Ref's")
        end 

        -- Carenado SF34

    if loadedAircraft == 'SF34.acf' then
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
            if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                set("thranda/cockpit/actuators/HideYokeL", pxpSwitchData.PersistenceData.LYOKE)
            end
        end
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeR") ~= nil) then
            if pxpSwitchData.PersistenceData.RYOKE ~= nil then
                set("thranda/cockpit/actuators/HideYokeR", pxpSwitchData.PersistenceData.RYOKE)
            end
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            if pxpSwitchData.PersistenceData.LARM ~= nil then
                set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
            end
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            if pxpSwitchData.PersistenceData.RARM ~= nil then
                set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
            end
        end
        if (XPLMFindDataRef("thranda/BT", 9) ~= nil) then
            if pxpSwitchData.PersistenceData.IGNL_CVR ~= nil then
                set_array("thranda/BT", 9, pxpSwitchData.PersistenceData.IGNL_CVR)
            end
        end
        if (XPLMFindDataRef("thranda/BT", 10) ~= nil) then
            if pxpSwitchData.PersistenceData.IGNR_CVR ~= nil then
                set_array("thranda/BT", 10, pxpSwitchData.PersistenceData.IGNR_CVR)
            end
        end
        if (XPLMFindDataRef("thranda/BT", 107) ~= nil) then
            if pxpSwitchData.PersistenceData.IGN1 ~= nil then
                set_array("thranda/BT", 107, pxpSwitchData.PersistenceData.IGN1)
            end
        end
        if (XPLMFindDataRef("thranda/BT", 108) ~= nil) then
            if pxpSwitchData.PersistenceData.IGN2 ~= nil then
                set_array("thranda/BT", 108, pxpSwitchData.PersistenceData.IGN2)
            end
        end
        if (XPLMFindDataRef("thranda/actuators/VoltSelAct") ~= nil) then
            if pxpSwitchData.PersistenceData.DCAMP ~= nil then
                set("thranda/actuators/VoltSelAct", pxpSwitchData.PersistenceData.DCAMP)
            end
        end
        if (XPLMFindDataRef("thranda/BT", 27) ~= nil) then
            if pxpSwitchData.PersistenceData.EMG_CVR ~= nil then
                set_array("thranda/BT", 27, pxpSwitchData.PersistenceData.EMG_CVR)
            end
        end
        if (XPLMFindDataRef("thranda/BT", 93) ~= nil) then
            if pxpSwitchData.PersistenceData.EMG ~= nil then
                set_array("thranda/BT", 93, pxpSwitchData.PersistenceData.EMG)
            end
        end
        if (XPLMFindDataRef("thranda/cockpit/ManualOverride") ~= nil) then
            if pxpSwitchData.PersistenceData.CAB_PRESS_CTL ~= nil then
                set("thranda/cockpit/ManualOverride", pxpSwitchData.PersistenceData.CAB_PRESS_CTL)
            end
        end
        if (XPLMFindDataRef("thranda/engine/TorqueLimit") ~= nil) then
            if pxpSwitchData.PersistenceData.CTOT_PWR ~= nil then
                set("thranda/engine/TorqueLimit", pxpSwitchData.PersistenceData.CTOT_PWR)
            end
        end
        if (XPLMFindDataRef("thranda/engine/CTOT") ~= nil) then
            if pxpSwitchData.PersistenceData.CTOT ~= nil then
                set("thranda/engine/CTOT", pxpSwitchData.PersistenceData.CTOT)
            end
        end
        else
            print("PXP Skipping Carenado Saab 340 Ref's")
        end 

        -- FF 757
    if loadedAircraft == '757-200_xp11.acf' then
        FF757.pxpParse()
        else
            print("PXP Skipping Flight Factor 757 Ref's")
        end 

        print("PersistenceXP Panel State Loaded")
    end
end ]]


-- Baro Sync Side Program

function PXPSideSync()
    if pxpUseBaroSync == true then

        if (XPLMFindDataRef("sim/cockpit/autopilot/airspeed") ~= nil) then
            if (XPLMFindDataRef("thranda/cockpit/actuators/ASI_adjustCo") ~= nil) then
                set("thranda/cockpit/actuators/ASI_adjustCo", get("sim/cockpit/autopilot/airspeed"))
            end
        end

        if (XPLMFindDataRef("sim/cockpit/misc/barometer_setting") ~= nil) then
            if (XPLMFindDataRef("sim/cockpit/misc/barometer_setting2") ~= nil) then
                set("sim/cockpit/misc/barometer_setting2", get("sim/cockpit/misc/barometer_setting"))
            end
        end

    end
end

do_sometimes("PXPSideSync()")