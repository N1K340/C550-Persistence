--[[ Starting a new file, what an idiot
Persistence for X-Plane 11 Aircraft, with compatability with custom datarefs as coded
Objective:
    - Record switch states on exit, reload on loade
    - Record position and reload
    - Isolate to specific airframe variations (rego?)
    ]]



-- if PLANE_ICAO == "C550" then



-- Modules
local LIP = require("LIP")
require "graphics"

-- Main Script Variables
local pxpSwitchData = {}
local pxpSettings = {}
local pxpScriptLoaded = false
local pxpSettingsLoaded = false
local pxpScriptLoadTimer = 3
local pxpScriptStartedTime = 0
local pxpScriptReady = false
local pxpUseScript = false
local pxpDelayInt = 10
local pxpSettingsWindow = false

-- Script Datarefs
dataref("SIM_TIME", "sim/time/total_running_time_sec")
dataref("PRK_BRK", "sim/flightmodel/controls/parkbrake")
dataref("ENG1_RUN", "sim/flightmodel/engine/ENGN_running", 0)
dataref("ENG2_RUN", "sim/flightmodel/engine/ENGN_running", 1)

-- Save and Load Settings only
function pxpWriteSettings(pxpSettings)
    LIP.save(AIRCRAFT_PATH .. "/xpxSettings.ini", pxpSettings)
    print("Persistence XP Settings Saved")
end

function pxpCompileSettings()
    pxpSettings = {
        settings = {
            pxpUseScript = pxpUseScript,
            pxpDelayInt = pxpDelayInt,
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
        print("PersistenceXP Settings Loaded")
        print("PersistenceXP enabled for aircraft: " .. tostring(pxpUseScript))
    else
        print("PersistenceXP Settings file for aircraft not found")
    end    
end

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
            print("Not Ready")
            return
        end
        print("Ready")
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
end

add_macro("PersistenceXP View Settings", "pxpOpenSettings_wnd()", "pxpCloseSettings_wnd()", "deactivate")


-- Main Function Call

function pxpAutoPersistenceData()
    if pxpScriptLoadTimer < 3 then
       pxpScriptLoadTimer = pxpScriptLoadTimer + 1
    end
    if pxpScriptLoaded and pxpScriptLoadTimer == 3 and PRK_BRK == 1 and ENG1_RUN == 0 then
        pxpSavePersistenceData()
        pxpScriptLoadTimer = 0
    end
    if pxpScriptReady and not pxpScriptLoaded then
        pxpParsePersistenceData() 
        pxpScriptLoaded = true
    end
end

do_sometimes("pxpAutoPersistenceData()")

add_macro("PersistenceXP Save Panel State", "SavePersistenceData()")
add_macro("PersistenceXP Load Panel State", "ParsePersistenceData()")

-- Save and Load Panel Data Functions

function pxpWritePersistenceData(pxpSwitchData)
    LIP.save(AIRCRAFT_PATH .. "/pxpPersistence.ini", pxpSwitchData)
    print("PersistenceXP Panel State Saved")
end

function pxpCompilePersistenceData()

-- Deafulat Datarefs
    local GPU = get("sim/cockpit/electrical/gpu_on")
    local DOOR0 = get("sim/cockpit2/switches/door_open", 0) -- 0 Main, 1 Left Bag, 2 Right Bag
    local DOOR1 = get("sim/cockpit2/switches/door_open", 1) -- 0 Main, 1 Left Bag, 2 Right Bag
    local DOOR2 = get("sim/cockpit2/switches/door_open", 2) -- 0 Main, 1 Left Bag, 2 Right Bag
    local CLK_MODE = get("sim/cockpit2/clock_timer/timer_mode")
    local XMT = get("sim/cockpit2/radios/actuators/audio_com_selection_man") -- Transmit Selector
    local C1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_com1") -- Com 1 Receives
    local C2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_com2") -- Com 2 Receives
    local ADF1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_adf1") -- ADF 1 Receives
    local ADF2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_adf1") -- ADF 2 Receives
    local NAV1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_nav1") -- NAV 1 Receives
    local NAV2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_nav2") -- NAV 2 Receives
    local DME1_RCV = get("sim/cockpit2/radios/actuators/audio_dme_enabled") -- DME Recieve
    local MRKR_RCV = get("sim/cockpit2/radios/actuators/audio_marker_enabled") -- Marker Recieve

    local GENL = get("sim/cockpit/electrical/generator_on", 0) -- Gen Switches 0 Left, 1 Right
    local GENR = get("sim/cockpit/electrical/generator_on", 1)
    local BAT = get("sim/cockpit/electrical/battery_on") -- Batt Switch
    local INV = get("thranda/electrical/AC_InverterSwitch") -- Inverter Switch
    local AVN = get("sim/cockpit/electrical/avionics_on") -- Avionics Switch
    local BOOST_PMP1 = get("sim/cockpit/engine/fuel_pump_on", 0) -- Fuel Pumps, 0 Left, 1 Right
    local BOOST_PMP2 = get("sim/cockpit/engine/fuel_pump_on", 1)
    local IGN1 = get("sim/cockpit/engine/igniters_on", 0) -- Ignition 0 Left 1 Right
    local IGN2 = get("sim/cockpit/engine/igniters_on", 1)
    local PIT_HT = get("sim/cockpit2/ice/ice_pitot_heat_on_pilot") -- Pitot Heat
    local WS_BLD = get("sim/cockpit2/ice/ice_window_heat_on") -- Window Bleed
    local ENG_AI1 = get("sim/cockpit/switches/anti_ice_engine_air", 0) -- 0 Left 1 Right
    local ENG_AI2 = get("sim/cockpit/switches/anti_ice_engine_air", 1)
    local SURF_AI = get("sim/cockpit2/ice/ice_surface_boot_on") 
    local GYROSL = get("sim/cockpit/gyros/gyr_free_slaved", 0) -- 0 LH Main, 1 LH Source
    local GYROSR = get("sim/cockpit/gyros/gyr_free_slaved", 1)
    
    local COLL = get("sim/cockpit/electrical/strobe_lights_on")
    local Nav_LT = get("sim/cockpit2/switches/navigation_lights_on")

    local SPD_BG = get("sim/cockpit/autopilot/airspeed") -- Speed Bug
    local RMI_L = get("sim/cockpit/switches/RMI_l_vor_adf_selector") -- Left RMI
    local RMI_R = get("sim/cockpit/switches/RMI_r_vor_adf_selector") -- Right RMI
    local DME_CH = get("sim/cockpit2/radios/actuators/DME_mode")
    local DME_SEL = get("sim/cockpit/switches/DME_distance_or_time")
    local DME_PWR = get("sim/cockpit2/radios/actuators/dme_power")
    local DH = get("sim/cockpit/misc/radio_altimeter_minimum")
    local FUEL_TTL = get("sim/cockpit2/fuel/fuel_totalizer_sum_kg")
    -- local INSTR_LTS = get("sim/cockpit2/switches/instrument_brightness_ratio")
    local FLOOD_LT = get("sim/cockpit2/switches/instrument_brightness_ratio", 1)
    local PNL_LT = get("sim/cockpit2/switches/generic_lights_switch", 30)
    local PNL_LFT = get("sim/cockpit2/switches/instrument_brightness_ratio", 2)
    local PNL_CTR = get("sim/cockpit2/switches/instrument_brightness_ratio", 3)
    local PNL_RT = get("sim/cockpit2/switches/instrument_brightness_ratio", 4)
    local PNL_EL = get("sim/cockpit2/switches/instrument_brightness_ratio", 5)
    local ST_BLT = get("sim/cockpit/switches/fasten_seat_belts")
    local BCN = get("sim/cockpit2/switches/beacon_on")
    local PRESS_VVI = get("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm")
    local CAB_ALT = get("sim/cockpit/pressure/cabin_altitude_set_m_msl")
    local TRIM = get("sim/cockpit2/controls/elevator_trim")
    local SPD_BRK = get("sim/cockpit2/controls/speedbrake_ratio")
    local FLP_HNDL = get("sim/cockpit2/controls/flap_ratio")
    local FAN_SYNC = get("sim/cockpit2/switches/jet_sync_mode")

    local CRS1 = get("sim/cockpit/radios/nav1_obs_degm")
    local HDG = get("sim/cockpit/autopilot/heading_mag")
    local VS = get("sim/cockpit2/autopilot/vvi_dial_fpm")
    local APA = get("sim/cockpit2/autopilot/altitude_dial_ft")

    local COM1_ACT = get("sim/cockpit/radios/com1_freq_hz")
    local COM1_STB = get("sim/cockpit/radios/com1_stdby_freq_hz")
    local COM2_ACT = get("sim/cockpit/radios/com2_freq_hz")
    local COM2_STB = get("sim/cockpit/radios/com2_stdby_freq_hz")
    local NAV1_ACT = get("sim/cockpit/radios/nav1_freq_hz")
    local NAV1_STB = get("sim/cockpit/radios/nav1_stdby_freq_hz")
    local NAV2_ACT = get("sim/cockpit/radios/nav1_freq_hz")
    local NAV2_STB = get("sim/cockpit/radios/nav1_stdby_freq_hz")
    local ADF1_ACT = get("sim/cockpit/radios/adf1_freq_hz")
    local ADF1_STB = get("sim/cockpit/radios/adf1_stdby_freq_hz")
    local ADF2_ACT = get("sim/cockpit/radios/adf2_freq_hz")
    local ADF2_STB = get("sim/cockpit/radios/adf2_stdby_freq_hz")  
    local XPDR_COD = get("sim/cockpit/radios/transponder_code")

    local COM1_PWR = get("sim/cockpit2/radios/actuators/com1_power")
    local COM2_PWR = get("sim/cockpit2/radios/actuators/com2_power")
    local NAV1_PWR = get("sim/cockpit2/radios/actuators/nav1_power")
    local NAV2_PWR = get("sim/cockpit2/radios/actuators/nav2_power")
    local ADF1_PWR = get("sim/cockpit2/radios/actuators/adf1_power")
    local ADF2_PWR = get("sim/cockpit2/radios/actuators/adf2_power")
    local XPDR_MODE = get("sim/cockpit2/radios/actuators/transponder_mode")
    local ENG1_RUN = get("sim/flightmodel/engine/ENGN_running", 0)
    local ENG2_RUN = get("sim/flightmodel/engine/ENGN_running", 1)

    
    local LYOKE = get("thranda/cockpit/actuators/HideYokeL")
    local RYOKE = get("thranda/cockpit/actuators/HideYokeR") -- Right Yoke
    local LARM = get("thranda/cockpit/animations/ArmRestLR") -- Left Arm Rests
    local RARM = get("thranda/cockpit/animations/ArmRestRL") -- Right Arm Rest
    local WREFL = get("thranda/views/WindowRefl") -- Window Reflections
    local IREFL = get("thranda/views/InstRefl") -- Instrument Reflections
    local COVERS = get("thranda/views/staticelements") -- Pitot Covers
    local VOLT_SEL = get("thranda/actuators/VoltSelAct") -- Volt Selector
    local TEST_SEL = get("thranda/annunciators/AnnunTestKnob") -- Test Selector
    local FUEL_SEL = get("thranda/fuel/CrossFeedLRSw")
    local RECOG = get("thranda/lights/RecogLights")
    local BARO_UNIT = get("thranda/instruments/BaroUnits")
    local N1_Dial = get("thranda/knobs/N1_Dial")
    local L_LND = get("thranda/lights/LandingLightLeft")
    local R_LND = get("thranda/lights/LandingLightRight")
    local ASKID = get("thranda/gear/AntiSkid")
    local TEMP_MAN = get("thranda/BT", 23)
    local TEMP_CTRL = get("thranda/pneumatic/CabinTempAct")
    local PRES_SRC = get("thranda/pneumatic/PressureSource")
    local FLOW_DIST = get("thranda/pneumatic/AirFlowDistribution")
    local L_WS = get("thranda/ice/WindshieldIceL")
    local R_WS = get("thranda/ice/WindshieldIceR")
    local CAB_FAN1 = get("thranda/BT", 23)
    local CAB_FOG = get("thranda/BT", 24)
    local AC = get("thranda/pneumatic/AC")
    local BLWR = get("thranda/pneumatic/BlowerIntensity")
    local CAB_VNT = get("thranda/pneumatic/CabinVent")
    local CAB_FAN2 = get("thranda/pneumatic/CabinFan")


    pxpSwitchData = {
        PersistenceData = {
            LYOKE = LYOKE,
            RYOKE = RYOKE,
            LARM = LARM,
            RARM = RARM,
            GPU = GPU,
            WREFL = WREFL,
            IREFL = IREFL,
            COVERS = COVERS,
            DOOR0 = DOOR0,
            DOOR1 = DOOR1,
            DOOR2 = DOOR2,
            CLK_MODE = CLK_MODE,
            XMT = XMT,
            C1_RCV = C1_RCV,
            C2_RCV = C2_RCV,
            ADF1_RCV = ADF1_RCV,
            ADF2_RCV = ADF2_RCV,
            NAV1_RCV = NAV1_RCV,
            NAV2_RCV = NAV2_RCV,
            DME1_RCV = DME1_RCV,
            MRKR_RCV = MRKR_RCV,
            VOLT_SEL = VOLT_SEL,
            TEST_SEL = TEST_SEL,
            GENL = GENL,
            GENR = GENR,
            BAT = BAT,
            INV = INV,
            AVN = AVN,
            BOOST_PMP1 = BOOST_PMP1,
            BOOST_PMP2 = BOOST_PMP2,
            IGN1 = IGN1,
            IGN2 = IGN2,
            PIT_HT = PIT_HT,
            WS_BLD = WS_BLD,
            ENG_AI1 = ENG_AI1,
            ENG_AI2 = ENG_AI2,
            SURF_AI = SURF_AI,
            GYROSL = GYROSL,
            GYROSR = GYROSR,
            FUEL_SEL = FUEL_SEL,
            RECOG = RECOG,
            COLL = COLL,
            Nav_LT = Nav_LT,
            SPD_BG = SPD_BG,
            RMI_L = RMI_L,
            RMI_R = RMI_R,
            DME_CH = DME_CH,
            DME_SEL = DME_SEL,
            DME_PWR = DME_PWR,
            BARO_UNIT = BARO_UNIT,
            FUEL_TTL = FUEL_TTL,
            N1_Dial = N1_Dial,
            FLOOD_LT = FLOOD_LT,
            PNL_LT = PNL_LT,
            PNL_LFT = PNL_LFT,
            PNL_CTR = PNL_CTR,
            PNL_RT = PNL_RT,
            PNL_EL = PNL_EL,
            ST_BLT = ST_BLT,
            BCN = BCN,
            L_LND = L_LND,
            R_LND = R_LND,
            ASKID = ASKID,
            PRESS_VVI = PRESS_VVI,
            CAB_ALT = CAB_ALT,
            TEMP_MAN = TEMP_MAN,
            TEMP_CTRL = TEMP_CTRL,
            PRES_SRC = PRES_SRC,
            FLOW_DIST = FLOW_DIST,
            TRIM = TRIM,
            SPD_BRK = SPD_BRK,
            FLP_HNDL = FLP_HNDL,
            FAN_SYNC = FAN_SYNC,
            CRS1 = CRS1,
            HDG = HDG,
            VS = VS,
            APA = APA,
            L_WS = L_WS,
            R_WS = R_WS,
            CAB_FAN1 = CAB_FAN1,
            CAB_FOG = CAB_FOG,
            AC = AC,
            BLWR = BLWR,
            CAB_VNT = CAB_VNT,
            CAB_FAN2 = CAB_FAN2,
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
            COM1_PWR = COM1_PWR,
            COM2_PWR = COM2_PWR,
            NAV1_PWR = NAV1_PWR,
            NAV2_PWR = NAV2_PWR,
            ADF1_PWR = ADF1_PWR,
            ADF2_PWR = ADF2_PWR,
            XPDR_MODE = XPDR_MODE,
            DH = DH,
            ENG1_RUN = ENG1_RUN,
            ENG2_RUN = ENG2_RUN,

        }
    }
    pxpWritePersistenceData(pxpSwitchData)
    print("C550 Persistence: Panel data saved to " .. AIRCRAFT_PATH .. "pxpPersistence.ini")
end

function pxpParsePersistenceData()
    pxpSwitchData = LIP.load(AIRCRAFT_PATH .. "/pxpPersistence.ini")

    set("thranda/cockpit/actuators/HideYokeL", pxpSwitchData.PersistenceData.LYOKE)
    set("thranda/cockpit/actuators/HideYokeR", pxpSwitchData.PersistenceData.RYOKE) -- Right Yoke
    set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
    set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
    set("sim/cockpit/electrical/gpu_on", pxpSwitchData.PersistenceData.GPU)
    set("thranda/views/WindowRefl", pxpSwitchData.PersistenceData.WREFL) -- Window Reflections
    set("thranda/views/InstRefl", pxpSwitchData.PersistenceData.IREFL) -- Instrument Reflections
    set("thranda/views/staticelements", pxpSwitchData.PersistenceData.COVERS) -- Pitot Covers
    set_array("sim/cockpit2/switches/door_open", 0, pxpSwitchData.PersistenceData.DOOR0) -- 0 Main, 1 Left Bag, 2 Right Bag
    set_array("sim/cockpit2/switches/door_open", 1, pxpSwitchData.PersistenceData.DOOR1) -- 0 Main, 1 Left Bag, 2 Right Bag
    set_array("sim/cockpit2/switches/door_open", 2, pxpSwitchData.PersistenceData.DOOR2) -- 0 Main, 1 Left Bag, 2 Right Bag
    set("sim/cockpit2/clock_timer/timer_mode", pxpSwitchData.PersistenceData.CLK_MODE)
    set("sim/cockpit2/radios/actuators/audio_com_selection_man", pxpSwitchData.PersistenceData.XMT) -- Transmit Selector
    set("sim/cockpit2/radios/actuators/audio_selection_com1", pxpSwitchData.PersistenceData.C1_RCV) -- Com 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_com2", pxpSwitchData.PersistenceData.C2_RCV) -- Com 2 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_adf1", pxpSwitchData.PersistenceData.ADF1_RCV) -- ADF 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_adf1", pxpSwitchData.PersistenceData.ADF2_RCV) -- ADF 2 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_nav1", pxpSwitchData.PersistenceData.NAV1_RCV) -- NAV 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_nav2", pxpSwitchData.PersistenceData.NAV2_RCV) -- NAV 2 Receives
    set("sim/cockpit2/radios/actuators/audio_dme_enabled", pxpSwitchData.PersistenceData.DME1_RCV) -- DME Recieve
    set("sim/cockpit2/radios/actuators/audio_marker_enabled", pxpSwitchData.PersistenceData.MRKR_RCV) -- Marker Recieve

    set("thranda/actuators/VoltSelAct", pxpSwitchData.PersistenceData.VOLT_SEL) -- Volt Selector
    set("thranda/annunciators/AnnunTestKnob", pxpSwitchData.PersistenceData.TEST_SEL) -- Test Selector
    set_array("sim/cockpit/electrical/generator_on", 0, pxpSwitchData.PersistenceData.GENL) -- Gen Switches 0 Left, 1 Right
    set_array("sim/cockpit/electrical/generator_on", 1, pxpSwitchData.PersistenceData.GENR)
    set("sim/cockpit/electrical/battery_on", pxpSwitchData.PersistenceData.BAT) -- Batt Switch
    set("thranda/electrical/AC_InverterSwitch", pxpSwitchData.PersistenceData.INV) -- Inverter Switch
    set("sim/cockpit/electrical/avionics_on", pxpSwitchData.PersistenceData.AVN) -- Avionics Switch
    set_array("sim/cockpit/engine/fuel_pump_on", 0, pxpSwitchData.PersistenceData.BOOST_PMP1) -- Fuel Pumps, 0 Left, 1 Right
    set_array("sim/cockpit/engine/fuel_pump_on", 1, pxpSwitchData.PersistenceData.BOOST_PMP2)
    set_array("sim/cockpit/engine/igniters_on", 0, pxpSwitchData.PersistenceData.IGN1) -- Ignition 0 Left 1 Right
    set_array("sim/cockpit/engine/igniters_on", 1, pxpSwitchData.PersistenceData.IGN2)
    set("sim/cockpit2/ice/ice_pitot_heat_on_pilot", pxpSwitchData.PersistenceData.PIT_HT) -- Pitot Heat
    set("sim/cockpit2/ice/ice_window_heat_on", pxpSwitchData.PersistenceData.WS_BLD) -- Window Bleed
    set_array("sim/cockpit/switches/anti_ice_engine_air", 0, pxpSwitchData.PersistenceData.ENG_AI1) -- 0 Left 1 Right
    set_array("sim/cockpit/switches/anti_ice_engine_air", 1, pxpSwitchData.PersistenceData.ENG_AI2)
    set("sim/cockpit2/ice/ice_surface_boot_on", pxpSwitchData.PersistenceData.SURF_AI) 
    set_array("sim/cockpit/gyros/gyr_free_slaved", 0, pxpSwitchData.PersistenceData.GYROSL) -- 0 LH Main, 1 LH Source
    set_array("sim/cockpit/gyros/gyr_free_slaved", 1, pxpSwitchData.PersistenceData.GYROSR)

    
    set("thranda/fuel/CrossFeedLRSw", pxpSwitchData.PersistenceData.FUEL_SEL)
    set("thranda/lights/RecogLights", pxpSwitchData.PersistenceData.RECOG)
    set("sim/cockpit/electrical/strobe_lights_on", pxpSwitchData.PersistenceData.COLL)
    set("sim/cockpit2/switches/navigation_lights_on", pxpSwitchData.PersistenceData.Nav_LT)

    set("sim/cockpit/autopilot/airspeed", pxpSwitchData.PersistenceData.SPD_BG) -- Speed Bug
    set("sim/cockpit/switches/RMI_l_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_L) -- Left RMI
    set("sim/cockpit/switches/RMI_r_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_R) -- Right RMI

    set("sim/cockpit2/radios/actuators/DME_mode", pxpSwitchData.PersistenceData.DME_CH)
    set("sim/cockpit/switches/DME_distance_or_time", pxpSwitchData.PersistenceData.DME_SEL)
    set("sim/cockpit2/radios/actuators/dme_power", pxpSwitchData.PersistenceData.DME_PWR)

    set("sim/cockpit/misc/radio_altimeter_minimum", pxpSwitchData.PersistenceData.DH)
    set("thranda/instruments/BaroUnits", pxpSwitchData.PersistenceData.BARO_UNIT)
    set("sim/cockpit2/fuel/fuel_totalizer_sum_kg", pxpSwitchData.PersistenceData.FUEL_TTL)

    set("thranda/knobs/N1_Dial", pxpSwitchData.PersistenceData.N1_Dial)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 1, pxpSwitchData.PersistenceData.FLOOD_LT)
    set_array("sim/cockpit2/switches/generic_lights_switch", 30 ,pxpSwitchData.PersistenceData.PNL_LT)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 2, pxpSwitchData.PersistenceData.PNL_LFT , 3)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 3, pxpSwitchData.PersistenceData.PNL_CTR , 4)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 4, pxpSwitchData.PersistenceData.PNL_RT , 5)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 5, pxpSwitchData.PersistenceData.PNL_EL , 6)
    set("sim/cockpit/switches/fasten_seat_belts", pxpSwitchData.PersistenceData.ST_BLT)
    set("sim/cockpit2/switches/beacon_on", pxpSwitchData.PersistenceData.BCN)
    set("thranda/lights/LandingLightLeft", pxpSwitchData.PersistenceData.L_LND)
    set("thranda/lights/LandingLightRight", pxpSwitchData.PersistenceData.R_LND)
    set("thranda/gear/AntiSkid", pxpSwitchData.PersistenceData.ASKID)

    set("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm", pxpSwitchData.PersistenceData.PRESS_VVI)
    set("sim/cockpit/pressure/cabin_altitude_set_m_msl", pxpSwitchData.PersistenceData.CAB_ALT)
    set_array("thranda/BT", 22, pxpSwitchData.PersistenceData.TEMP_MAN)
    set("thranda/pneumatic/CabinTempAct", pxpSwitchData.PersistenceData.TEMP_CTRL)
    set("thranda/pneumatic/PressureSource", pxpSwitchData.PersistenceData.PRES_SRC)
    set("thranda/pneumatic/AirFlowDistribution", pxpSwitchData.PersistenceData.FLOW_DIST)

    set("sim/cockpit2/controls/elevator_trim", pxpSwitchData.PersistenceData.TRIM)
    set("sim/cockpit2/controls/speedbrake_ratio", pxpSwitchData.PersistenceData.SPD_BRK)
    set("sim/cockpit2/controls/flap_ratio", pxpSwitchData.PersistenceData.FLP_HNDL)
    set("sim/cockpit2/switches/jet_sync_mode", pxpSwitchData.PersistenceData.FAN_SYNC)

    set("sim/cockpit/radios/nav1_obs_degm", pxpSwitchData.PersistenceData.CRS1)
    set("sim/cockpit/autopilot/heading_mag", pxpSwitchData.PersistenceData.HDG)
    set("sim/cockpit2/autopilot/vvi_dial_fpm", pxpSwitchData.PersistenceData.VS)
    set("sim/cockpit2/autopilot/altitude_dial_ft", pxpSwitchData.PersistenceData.APA)

    set("thranda/ice/WindshieldIceL", pxpSwitchData.PersistenceData.L_WS)
    set("thranda/ice/WindshieldIceR", pxpSwitchData.PersistenceData.R_WS)
    set_array("thranda/BT", 23, pxpSwitchData.PersistenceData.CAB_FAN1)
    set_array("thranda/BT", 24, pxpSwitchData.PersistenceData.CAB_FOG)
    set("thranda/pneumatic/AC", pxpSwitchData.PersistenceData.AC)
    set("thranda/pneumatic/BlowerIntensity", pxpSwitchData.PersistenceData.BLWR)
    set("thranda/pneumatic/CabinVent", pxpSwitchData.PersistenceData.CAB_VNT)
    set("thranda/pneumatic/CabinFan", pxpSwitchData.PersistenceData.CAB_FAN2)

    set("sim/cockpit/radios/com1_freq_hz", pxpSwitchData.PersistenceData.COM1_ACT)
    set("sim/cockpit/radios/com1_stdby_freq_hz", pxpSwitchData.PersistenceData.COM1_STB)
    set("sim/cockpit/radios/com2_freq_hz", pxpSwitchData.PersistenceData.COM2_ACT)
    set("sim/cockpit/radios/com2_stdby_freq_hz", pxpSwitchData.PersistenceData.COM2_STB)
    set("sim/cockpit/radios/nav1_freq_hz", pxpSwitchData.PersistenceData.NAV1_ACT)
    set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV1_STB)
    set("sim/cockpit/radios/nav1_freq_hz", pxpSwitchData.PersistenceData.NAV2_ACT)
    set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV2_STB)
    set("sim/cockpit/radios/adf1_freq_hz", pxpSwitchData.PersistenceData.ADF1_ACT)
    set("sim/cockpit/radios/adf1_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF1_STB)
    set("sim/cockpit/radios/adf2_freq_hz", pxpSwitchData.PersistenceData.ADF2_ACT)
    set("sim/cockpit/radios/adf2_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF2_STB)  
    set("sim/cockpit/radios/transponder_code", pxpSwitchData.PersistenceData.XPDR_COD)

    set("sim/cockpit2/radios/actuators/com1_power", pxpSwitchData.PersistenceData.COM1_PWR)
    set("sim/cockpit2/radios/actuators/com2_power", pxpSwitchData.PersistenceData.COM2_PWR)
    set("sim/cockpit2/radios/actuators/nav1_power", pxpSwitchData.PersistenceData.NAV1_PWR)
    set("sim/cockpit2/radios/actuators/nav2_power", pxpSwitchData.PersistenceData.NAV2_PWR)
    set("sim/cockpit2/radios/actuators/adf1_power", pxpSwitchData.PersistenceData.ADF1_PWR)
    set("sim/cockpit2/radios/actuators/adf2_power", pxpSwitchData.PersistenceData.ADF2_PWR)
    set("sim/cockpit2/radios/actuators/transponder_mode", pxpSwitchData.PersistenceData.XPDR_MODE)

    if ENG1_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
        set("thranda/cockpit/ThrottleLatchAnim_0", 0.5)
        print("Command Shut 1")
    end
    if ENG2_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
        set("thranda/cockpit/ThrottleLatchAnim_1", 0.5)
        print("Command Shut 2")
    end
    print("PersistenceXP Panel State Loaded")
end

function PXPSideSync()
    local Baro = 0
    local SpdBug = 0

    if get("sim/cockpit/autopilot/airspeed") ~= SpdBug then
        SpdBug = get("sim/cockpit/autopilot/airspeed")
        set("thranda/cockpit/actuators/ASI_adjustCo", SpdBug)
    end
    if get("sim/cockpit/misc/barometer_setting") ~= Baro then
        Baro = get("sim/cockpit/misc/barometer_setting")
        set("sim/cockpit/misc/barometer_setting2", Baro)
    end
end




-- do_sometimes("PXPSideSync()")



-- end -- master end