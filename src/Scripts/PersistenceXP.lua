--[[ Starting a new file, what an idiot
Persistence for X-Plane 11 Aircraft, with compatability with custom datarefs as coded
Objective:
    - Record switch states on exit, reload on loade
    - Record position and reload
    - Isolate to specific airframe variations (rego?)
    ]]



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
local loadedAircraft = nil
-- globalLUA PLANE_TAILNUMBER

-- Script Datarefs
dataref("SIM_TIME", "sim/time/total_running_time_sec")
dataref("PRK_BRK", "sim/flightmodel/controls/parkbrake")
dataref("ENG1_RUN", "sim/flightmodel/engine/ENGN_running", 0)
dataref("ENG2_RUN", "sim/flightmodel/engine/ENGN_running", 1)

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
            print("PXP Waiting or Paused")
            return
        end
        loadedAircraft = AIRCRAFT_FILENAME
        print("PXP Ready for " .. AIRCRAFT_FILENAME)
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
        pxpCompilePersistenceData()
        pxpScriptLoadTimer = 0
    end
    if pxpScriptReady and not pxpScriptLoaded then
        pxpParsePersistenceData() 
        pxpScriptLoaded = true
    end
end

do_sometimes("pxpAutoPersistenceData()")

add_macro("PersistenceXP Save Panel State", "pxpCompilePersistenceData()")
add_macro("PersistenceXP Load Panel State", "pxpParsePersistenceData()")

-- Save and Load Panel Data Functions

function pxpWritePersistenceData(pxpSwitchData)
    LIP.save(AIRCRAFT_PATH .. "/pxpPersistence.ini", pxpSwitchData)
    print("PersistenceXP Panel State Saved")
end

function pxpCompilePersistenceData()
    -- Deafult Electrical
    local BAT = nil
    local AVN = nil
    local GENL = nil
    local GENR = nil
    local GENAPU = nil
    local GPU = nil

    if (XPLMFindDataRef("sim/cockpit/electrical/battery_on") ~= nil) then
        BAT = get("sim/cockpit/electrical/battery_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/avionics_power_on") ~= nil) then
        AVN = get("sim/cockpit2/switches/avionics_power_on")
    end
    if (XPLMFindDataRef("sim/cockpit/electrical/generator_on", 0) ~= nil) then
        GENL = get("sim/cockpit/electrical/generator_on", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/electrical/generator_on", 1) ~= nil) then
        GENR = get("sim/cockpit/electrical/generator_on", 1)
    end
    if (XPLMFindDataRef("sim/cockpit/electrical/generator_apu_on") ~= nil) then
        GENAPU = get("sim/cockpit/electrical/generator_apu_on")
    end
    if (XPLMFindDataRef("sim/cockpit/electrical/gpu_on") ~= nil) then
        GPU = get("sim/cockpit/electrical/gpu_on")
    end

    -- Deafult Lighting
    local Nav_LT = nil
    local BCN = nil
    local STROBE = nil
    local LNDLIGHT = nil
    local TAXILIGHT = nil

    if (XPLMFindDataRef("sim/cockpit2/switches/navigation_lights_on") ~= nil) then
        Nav_LT = get("sim/cockpit2/switches/navigation_lights_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/beacon_on") ~= nil) then
        BCN = get("sim/cockpit2/switches/beacon_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/strobe_lights_on") ~= nil) then
        STROBE = get("sim/cockpit2/switches/strobe_lights_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on") ~= nil) then
        LNDLIGHT = get("sim/cockpit2/switches/landing_lights_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/taxi_light_on") ~= nil) then
        TAXILIGHT = get("sim/cockpit2/switches/taxi_light_on")
    end


    -- Doors
    local DOOR0 = nil -- 0 Main, 1 Left Bag, 2 Right Bag
    local DOOR1 = nil
    local DOOR2 = nil

    if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 0) ~= nil) then
        DOOR0 = get("sim/cockpit2/switches/door_open", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 1) ~= nil) then
        DOOR1 = get("sim/cockpit2/switches/door_open", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 2) ~= nil) then
        DOOR2 = get("sim/cockpit2/switches/door_open", 2)
    end

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

    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav1_power") ~= nil) then
        NAV1_PWR = get("sim/cockpit2/radios/actuators/nav1_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav2_power") ~= nil) then
        NAV2_PWR = get("sim/cockpit2/radios/actuators/nav2_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com1_power") ~= nil) then
        COM1_PWR = get("sim/cockpit2/radios/actuators/com1_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com2_power") ~= nil) then
        COM2_PWR = get("sim/cockpit2/radios/actuators/com2_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf1_power") ~= nil) then
        ADF1_PWR = get("sim/cockpit2/radios/actuators/adf1_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf2_power") ~= nil) then
        ADF2_PWR = get("sim/cockpit2/radios/actuators/adf2_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps_power") ~= nil) then
        GPS1_PWR = get("sim/cockpit2/radios/actuators/gps_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps2_power") ~= nil) then
        GPS2_PWR = get("sim/cockpit2/radios/actuators/gps2_power")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/dme_power") ~= nil) then
        DME_PWR = get("sim/cockpit2/radios/actuators/dme_power")
    end

    local XMT = nil
    local C1_RCV = nil
    local C2_RCV = nil
    local ADF1_RCV = nil
    local ADF2_RCV = nil
    local NAV1_RCV = nil
    local NAV2_RCV = nil
    local DME1_RCV = nil
    local MRKR_RCV = nil

    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_com_selection_man") ~= nil) then
        XMT = get("sim/cockpit2/radios/actuators/audio_com_selection_man")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com1") ~= nil) then
        C1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_com1")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com2") ~= nil) then
        C2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_com2")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf1") ~= nil) then
        ADF1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_adf1")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf2") ~= nil) then
        ADF2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_adf2")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav1") ~= nil) then
        NAV1_RCV = get("sim/cockpit2/radios/actuators/audio_selection_nav1")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav2") ~= nil) then
        NAV2_RCV = get("sim/cockpit2/radios/actuators/audio_selection_nav2")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_dme_enabled") ~= nil) then
        DME1_RCV = get("sim/cockpit2/radios/actuators/audio_dme_enabled")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_marker_enabled") ~= nil) then
        MRKR_RCV = get("sim/cockpit2/radios/actuators/audio_marker_enabled")
    end
    

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
    local CLK_MODE = get("sim/cockpit2/clock_timer/timer_mode")

    if (XPLMFindDataRef("sim/cockpit/radios/nav1_freq_hz") ~= nil) then
        NAV1_ACT = get("sim/cockpit/radios/nav1_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/nav1_stdby_freq_hz") ~= nil) then
        NAV1_STB = get("sim/cockpit/radios/nav1_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/nav2_freq_hz") ~= nil) then
        NAV2_ACT = get("sim/cockpit/radios/nav2_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/nav2_stdby_freq_hz") ~= nil) then
        NAV2_STB = get("sim/cockpit/radios/nav2_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/com1_freq_hz") ~= nil) then
        COM1_ACT = get("sim/cockpit/radios/com1_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/com1_stdby_freq_hz") ~= nil) then
        COM1_STB = get("sim/cockpit/radios/com1_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/com2_freq_hz") ~= nil) then
        COM2_ACT = get("sim/cockpit/radios/com2_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/com2_stdby_freq_hz") ~= nil) then
        COM2_STB = get("sim/cockpit/radios/com2_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/adf1_freq_hz") ~= nil) then
        ADF1_ACT = get("sim/cockpit/radios/adf1_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/adf1_stdby_freq_hz") ~= nil) then
        ADF1_STB = get("sim/cockpit/radios/adf1_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/adf2_freq_hz") ~= nil) then
        ADF2_ACT = get("sim/cockpit/radios/adf2_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/adf2_stdby_freq_hz") ~= nil) then
        ADF2_STB = get("sim/cockpit/radios/adf2_stdby_freq_hz")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/transponder_code") ~= nil) then
        XPDR_COD = get("sim/cockpit/radios/transponder_code")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/transponder_mode") ~= nil) then
        XPDR_MODE = get("sim/cockpit2/radios/actuators/transponder_mode")
    end
    if (XPLMFindDataRef("sim/cockpit2/clock_timer/timer_mode") ~= nil) then
        CLK_MODE = get("sim/cockpit2/clock_timer/timer_mode")
    end



    -- Bugs
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

    if (XPLMFindDataRef("sim/cockpit/autopilot/heading_mag") ~= nil) then
        HDG = get("sim/cockpit/autopilot/heading_mag")
    end
    if (XPLMFindDataRef("sim/cockpit2/autopilot/vvi_dial_fpm") ~= nil) then
        VS = get("sim/cockpit2/autopilot/vvi_dial_fpm")
    end
    if (XPLMFindDataRef("sim/cockpit2/autopilot/altitude_dial_ft") ~= nil) then
        APA = get("sim/cockpit2/autopilot/altitude_dial_ft")
    end
    if (XPLMFindDataRef("sim/cockpit/autopilot/airspeed") ~= nil) then
        SPD_BG = get("sim/cockpit/autopilot/airspeed")
    end
    if (XPLMFindDataRef("sim/cockpit/switches/RMI_l_vor_adf_selector") ~= nil) then
        RMI_L = get("sim/cockpit/switches/RMI_l_vor_adf_selector")
    end
    if (XPLMFindDataRef("sim/cockpit/switches/RMI_r_vor_adf_selector") ~= nil) then
        RMI_R = get("sim/cockpit/switches/RMI_r_vor_adf_selector")
    end
    if (XPLMFindDataRef("sim/cockpit2/radios/actuators/DME_mode") ~= nil) then
        DME_CH = get("sim/cockpit2/radios/actuators/DME_mode")
    end
    if (XPLMFindDataRef("sim/cockpit/switches/DME_distance_or_time") ~= nil) then
        DME_SEL = get("sim/cockpit/switches/DME_distance_or_time")
    end
    if (XPLMFindDataRef("sim/cockpit/misc/radio_altimeter_minimum") ~= nil) then
        DH = get("sim/cockpit/misc/radio_altimeter_minimum")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/nav1_obs_degm") ~= nil) then
        CRS1 = get("sim/cockpit/radios/nav1_obs_degm")
    end
    if (XPLMFindDataRef("sim/cockpit/radios/nav2_obs_degm") ~= nil) then
        CRS2 = get("sim/cockpit/radios/nav2_obs_degm")
    end

    -- Engine
    local IGN1 = nil
    local IGN2 = nil
    local MAG1 = nil
    local MAG2 = nil

    if (XPLMFindDataRef("sim/cockpit/engine/igniters_on", 0) ~= nil) then
        IGN1 = get("sim/cockpit/engine/igniters_on", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/engine/igniters_on", 1) ~= nil) then
        IGN2 = get("sim/cockpit/engine/igniters_on", 1)
    end
    if (XPLMFindDataRef("sim/cockpit/engine/ignition_on", 0) ~= nil) then
        MAG1 = get("sim/cockpit/engine/ignition_on", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/engine/ignition_on", 1) ~= nil) then
        MAG2 = get("sim/cockpit/engine/ignition_on", 1)
    end

    -- Fuel
    local BOOST_PMP1 = nil
    local BOOST_PMP2 = nil
    local FUEL0 = nil
    local FUEL1 = nil
    local FUEL2 = nil
    local FUEL3 = nil
    local FUEL_TTL = nil

    if (XPLMFindDataRef("sim/cockpit/engine/fuel_pump_on", 0) ~= nil) then
        BOOST_PMP1 = get("sim/cockpit/engine/fuel_pump_on", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/engine/fuel_pump_on", 1) ~= nil) then
        BOOST_PMP2 = get("sim/cockpit/engine/fuel_pump_on", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 0) ~= nil) then
        FUEL0 = get("sim/cockpit2/fuel/fuel_quantity", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 1) ~= nil) then
        FUEL1 = get("sim/cockpit2/fuel/fuel_quantity", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 2) ~= nil) then
        FUEL2 = get("sim/cockpit2/fuel/fuel_quantity", 2)
    end
    if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_quantity", 3) ~= nil) then
        FUEL3 = get("sim/cockpit2/fuel/fuel_quantity", 3)
    end
    if (XPLMFindDataRef("sim/cockpit2/fuel/fuel_totalizer_sum_kg") ~= nil) then
        FUEL_TTL = get("sim/cockpit2/fuel/fuel_totalizer_sum_kg")
    end

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

    if (XPLMFindDataRef("sim/cockpit2/ice/ice_pitot_heat_on_pilot") ~= nil) then
        PIT1_HT = get("sim/cockpit2/ice/ice_pitot_heat_on_pilot")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_static_heat_on_pilot") ~= nil) then
        STAT1_HT = get("sim/cockpit2/ice/ice_static_heat_on_pilot")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_AOA_heat_on") ~= nil) then
        AOA1_HT = get("sim/cockpit2/ice/ice_AOA_heat_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_pitot_heat_on_copilot") ~= nil) then
        PIT2_HT = get("sim/cockpit2/ice/ice_pitot_heat_on_copilot")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_static_heat_on_copilot") ~= nil) then
        STAT2_HT = get("sim/cockpit2/ice/ice_static_heat_on_copilot")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_AOA_heat_on_copilot") ~= nil) then
        AOA2_HT = get("sim/cockpit2/ice/ice_AOA_heat_on_copilot")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_window_heat_on") ~= nil) then
        WS_BLD = get("sim/cockpit2/ice/ice_window_heat_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 0) ~= nil) then
        INLET1_AI = get("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 1) ~= nil) then
        INLET2_AI = get("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 1)
    end
    if (XPLMFindDataRef("sim/cockpit/switches/anti_ice_engine_air", 0) ~= nil) then
        ENG_AI1 = get("sim/cockpit/switches/anti_ice_engine_air", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/switches/anti_ice_engine_air", 1) ~= nil) then
        ENG_AI2 = get("sim/cockpit/switches/anti_ice_engine_air", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_surface_boot_on") ~= nil) then
        WING_BOOT = get("sim/cockpit2/ice/ice_surface_boot_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_surfce_heat_on") ~= nil) then
        WING_HEAT = get("sim/cockpit2/ice/ice_surfce_heat_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/ice/ice_prop_heat_on") ~= nil) then
        PROP_HEAT = get("sim/cockpit2/ice/ice_prop_heat_on")
    end


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

    if (XPLMFindDataRef("sim/cockpit2/controls/elevator_trim") ~= nil) then
        TRIM = get("sim/cockpit2/controls/elevator_trim")
    end
    if (XPLMFindDataRef("sim/cockpit2/controls/speedbrake_ratio") ~= nil) then
        SPD_BRK = get("sim/cockpit2/controls/speedbrake_ratio")
    end
    if (XPLMFindDataRef("sim/cockpit2/controls/flap_ratio") ~= nil) then
        FLP_HNDL = get("sim/cockpit2/controls/flap_ratio")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/jet_sync_mode") ~= nil) then
        FAN_SYNC = get("sim/cockpit2/switches/jet_sync_mode")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/prop_sync_on") ~= nil) then
        PROP_SYNC = get("sim/cockpit2/switches/prop_sync_on")
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/throttle_ratio_all") ~= nil) then
        THRTL = get("sim/cockpit2/engine/actuators/throttle_ratio_all")
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/prop_ratio_all") ~= nil) then
        PROP = get("sim/cockpit2/engine/actuators/prop_ratio_all")
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/mixture_ratio_all") ~= nil) then
        MIX = get("sim/cockpit2/engine/actuators/mixture_ratio_all")
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/carb_heat_ratio", 0) ~= nil) then
        CARB1 = get("sim/cockpit2/engine/actuators/carb_heat_ratio", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/carb_heat_ratio", 1) ~= nil) then
        CARB2 = get("sim/cockpit2/engine/actuators/carb_heat_ratio", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/cowl_flap_ratio", 0) ~= nil) then
        COWL1 = get("sim/cockpit2/engine/actuators/cowl_flap_ratio", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/engine/actuators/cowl_flap_ratio", 1) ~= nil) then
        COWL2 = get("sim/cockpit2/engine/actuators/cowl_flap_ratio", 1)
    end

    -- Carenado Citation II
    local LYOKE = nil
    local LARM = nil
    local RARM = nil
    if loadedAircraft == 'S550_Citation_II.acf' then
        if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
            LYOKE = get("thranda/cockpit/actuators/HideYokeL")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
            LARM = get("thranda/cockpit/animations/ArmRestLR")
        end
        if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
            RARM = get("thranda/cockpit/animations/ArmRestRL")
        end
    else
        print("PXP Skipping Carenado Citation II Ref's")
    end
--[[ Deafulat Datarefs
 
 

    


    
    local GYROSL = get("sim/cockpit/gyros/gyr_free_slaved", 0) -- 0 LH Main, 1 LH Source
    local GYROSR = get("sim/cockpit/gyros/gyr_free_slaved", 1)
    

 
    -- local INSTR_LTS = get("sim/cockpit2/switches/instrument_brightness_ratio")
    local FLOOD_LT = get("sim/cockpit2/switches/instrument_brightness_ratio", 1)
    local PNL_LT = get("sim/cockpit2/switches/generic_lights_switch", 30)
    local PNL_LFT = get("sim/cockpit2/switches/instrument_brightness_ratio", 2)
    local PNL_CTR = get("sim/cockpit2/switches/instrument_brightness_ratio", 3)
    local PNL_RT = get("sim/cockpit2/switches/instrument_brightness_ratio", 4)
    local PNL_EL = get("sim/cockpit2/switches/instrument_brightness_ratio", 5)
    local ST_BLT = get("sim/cockpit/switches/fasten_seat_belts")
    local PRESS_VVI = get("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm")
    local CAB_ALT = get("sim/cockpit/pressure/cabin_altitude_set_m_msl")
    

 


    
    




    local INV = get("thranda/electrical/AC_InverterSwitch") -- Inverter Switch

    local RYOKE = get("thranda/cockpit/actuators/HideYokeR") -- Right Yoke

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
]]

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

            --Bugs
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

            -- Engines
            IGN1 = IGN1,
            IGN2 = IGN2,
            MAG1 = MAG1,
            MAG2 = MAG2,

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

            -- Carenado C550
            LYOKE = LYOKE,


            --[[
                
            RYOKE = RYOKE,
            LARM = LARM,
            RARM = RARM,
            INV = INV,
            WREFL = WREFL,
            IREFL = IREFL,
            COVERS = COVERS,

            
            VOLT_SEL = VOLT_SEL,
            TEST_SEL = TEST_SEL,
            
            
            
            GYROSL = GYROSL,
            GYROSR = GYROSR,
            FUEL_SEL = FUEL_SEL,
            RECOG = RECOG,
            
            BARO_UNIT = BARO_UNIT,
            N1_Dial = N1_Dial,
            FLOOD_LT = FLOOD_LT,
            PNL_LT = PNL_LT,
            PNL_LFT = PNL_LFT,
            PNL_CTR = PNL_CTR,
            PNL_RT = PNL_RT,
            PNL_EL = PNL_EL,
            ST_BLT = ST_BLT,
            L_LND = L_LND,
            R_LND = R_LND,
            ASKID = ASKID,
            PRESS_VVI = PRESS_VVI,
            CAB_ALT = CAB_ALT,
            TEMP_MAN = TEMP_MAN,
            TEMP_CTRL = TEMP_CTRL,
            PRES_SRC = PRES_SRC,
            FLOW_DIST = FLOW_DIST,
            
            
            L_WS = L_WS,
            R_WS = R_WS,
            CAB_FAN1 = CAB_FAN1,
            CAB_FOG = CAB_FOG,
            AC = AC,
            BLWR = BLWR,
            CAB_VNT = CAB_VNT,
            CAB_FAN2 = CAB_FAN2,
            
            ENG1_RUN = ENG1_RUN,
            ENG2_RUN = ENG2_RUN,]]

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
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/switches/avionics_power_on", pxpSwitchData.PersistenceData.AVN) -- Avionics Switch
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit/electrical/generator_on", 0, pxpSwitchData.PersistenceData.GENL) -- Gen Switches 0 Left, 1 Right
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit/electrical/generator_on", 1, pxpSwitchData.PersistenceData.GENR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/generator_apu_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/electrical/generator_apu_on", pxpSwitchData.PersistenceData.GENAPU)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/electrical/gpu_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/electrical/gpu_on", pxpSwitchData.PersistenceData.GPU)
            end
        end

        --Default Lighting
        if (XPLMFindDataRef("sim/cockpit2/switches/navigation_lights_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/switches/navigation_lights_on", pxpSwitchData.PersistenceData.Nav_LT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/beacon_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/switches/beacon_on", pxpSwitchData.PersistenceData.BCN)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/strobe_lights_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/switches/strobe_lights_on", pxpSwitchData.PersistenceData.STROBE)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 0, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 1, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 2, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/landing_lights_on", 3) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/landing_lights_on", 3, pxpSwitchData.PersistenceData.LNDLIGHT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/taxi_light_on") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/switches/taxi_light_on", pxpSwitchData.PersistenceData.TAXILIGHT)
            end
        end

        --Doors
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 0) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/door_open", 0, pxpSwitchData.PersistenceData.DOOR0) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 1) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/door_open", 1, pxpSwitchData.PersistenceData.DOOR1) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/switches/door_open", 2) ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set_array("sim/cockpit2/switches/door_open", 2, pxpSwitchData.PersistenceData.DOOR2) -- 0 Main, 1 Left Bag, 2 Right Bag
            end
        end

        --Com Select
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/nav1_power", pxpSwitchData.PersistenceData.NAV1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/nav2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/nav2_power", pxpSwitchData.PersistenceData.NAV2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/com1_power", pxpSwitchData.PersistenceData.COM1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/com2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/com2_power", pxpSwitchData.PersistenceData.COM2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf1_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/adf1_power", pxpSwitchData.PersistenceData.ADF1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/adf2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/adf2_power", pxpSwitchData.PersistenceData.ADF2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/gps_power", pxpSwitchData.PersistenceData.GPS1_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/gps2_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/gps2_power", pxpSwitchData.PersistenceData.GPS2_PWR)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/dme_power") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/dme_power", pxpSwitchData.PersistenceData.DME_PWR)
            end
        end


        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_com_selection_man") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_com_selection_man", pxpSwitchData.PersistenceData.XMT) -- Transmit Selector
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com1") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_com1", pxpSwitchData.PersistenceData.C1_RCV) -- Com 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_com2") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_com2", pxpSwitchData.PersistenceData.C2_RCV) -- Com 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf1") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_adf1", pxpSwitchData.PersistenceData.ADF1_RCV) -- ADF 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_adf1") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_adf1", pxpSwitchData.PersistenceData.ADF2_RCV) -- ADF 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav1") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_nav1", pxpSwitchData.PersistenceData.NAV1_RCV) -- NAV 1 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_selection_nav2") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_selection_nav2", pxpSwitchData.PersistenceData.NAV2_RCV) -- NAV 2 Receives
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_dme_enabled") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_dme_enabled", pxpSwitchData.PersistenceData.DME1_RCV) -- DME Recieve
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/audio_marker_enabled") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/audio_marker_enabled", pxpSwitchData.PersistenceData.MRKR_RCV) -- Marker Recieve
            end
        end


        if (XPLMFindDataRef("sim/cockpit/radios/com1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/com1_freq_hz", pxpSwitchData.PersistenceData.COM1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/com1_stdby_freq_hz", pxpSwitchData.PersistenceData.COM1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/com2_freq_hz", pxpSwitchData.PersistenceData.COM2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/com2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/com2_stdby_freq_hz", pxpSwitchData.PersistenceData.COM2_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/nav1_freq_hz", pxpSwitchData.PersistenceData.NAV1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/nav2_freq_hz", pxpSwitchData.PersistenceData.NAV2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/nav2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/nav1_stdby_freq_hz", pxpSwitchData.PersistenceData.NAV2_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf1_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/adf1_freq_hz", pxpSwitchData.PersistenceData.ADF1_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf1_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/adf1_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF1_STB)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf2_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/adf2_freq_hz", pxpSwitchData.PersistenceData.ADF2_ACT)
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/adf2_stdby_freq_hz") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/adf2_stdby_freq_hz", pxpSwitchData.PersistenceData.ADF2_STB)  
            end
        end
        if (XPLMFindDataRef("sim/cockpit/radios/transponder_code") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit/radios/transponder_code", pxpSwitchData.PersistenceData.XPDR_COD)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/radios/actuators/transponder_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/radios/actuators/transponder_mode", pxpSwitchData.PersistenceData.XPDR_MODE)
            end
        end
        if (XPLMFindDataRef("sim/cockpit2/clock_timer/timer_mode") ~= nil) then
            if pxpSwitchData.PersistenceData.BAT ~= nil then
                set("sim/cockpit2/clock_timer/timer_mode", pxpSwitchData.PersistenceData.CLK_MODE)
            end
        end

        --Bugs
        set("sim/cockpit/autopilot/heading_mag", pxpSwitchData.PersistenceData.HDG)
        set("sim/cockpit2/autopilot/vvi_dial_fpm", pxpSwitchData.PersistenceData.VS)
        set("sim/cockpit2/autopilot/altitude_dial_ft", pxpSwitchData.PersistenceData.APA)
        set("sim/cockpit/autopilot/airspeed", pxpSwitchData.PersistenceData.SPD_BG) -- Speed Bug
        set("sim/cockpit/switches/RMI_l_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_L) -- Left RMI
        set("sim/cockpit/switches/RMI_r_vor_adf_selector", pxpSwitchData.PersistenceData.RMI_R) -- Right RMI
        set("sim/cockpit2/radios/actuators/DME_mode", pxpSwitchData.PersistenceData.DME_CH)
        set("sim/cockpit/switches/DME_distance_or_time", pxpSwitchData.PersistenceData.DME_SEL)
        set("sim/cockpit/misc/radio_altimeter_minimum", pxpSwitchData.PersistenceData.DH)
        set("sim/cockpit/radios/nav1_obs_degm", pxpSwitchData.PersistenceData.CRS1)
        set("sim/cockpit/radios/nav2_obs_degm", pxpSwitchData.PersistenceData.CRS2)

        -- Engines
        set_array("sim/cockpit/engine/igniters_on", 0, pxpSwitchData.PersistenceData.IGN1) -- Ignition 0 Left 1 Right
        set_array("sim/cockpit/engine/igniters_on", 1, pxpSwitchData.PersistenceData.IGN2)
        set_array("sim/cockpit/engine/ignition_on", 0, pxpSwitchData.PersistenceData.MAG1) -- Ignition 0 Left 1 Right
        set_array("sim/cockpit/engine/ignition_on", 1, pxpSwitchData.PersistenceData.MAG2)

        -- Fuel
        set_array("sim/cockpit/engine/fuel_pump_on", 0, pxpSwitchData.PersistenceData.BOOST_PMP1) -- Fuel Pumps, 0 Left, 1 Right
        set_array("sim/cockpit/engine/fuel_pump_on", 1, pxpSwitchData.PersistenceData.BOOST_PMP2)
        set_array("sim/cockpit2/fuel/fuel_quantity", 0, pxpSwitchData.PersistenceData.FUEL0)
        set_array("sim/cockpit2/fuel/fuel_quantity", 1, pxpSwitchData.PersistenceData.FUEL1)
        set_array("sim/cockpit2/fuel/fuel_quantity", 2, pxpSwitchData.PersistenceData.FUEL2)
        set_array("sim/cockpit2/fuel/fuel_quantity", 3, pxpSwitchData.PersistenceData.FUEL3)
        set("sim/cockpit2/fuel/fuel_totalizer_sum_kg", pxpSwitchData.PersistenceData.FUEL_TTL)

        -- Ice Protection
        set("sim/cockpit2/ice/ice_pitot_heat_on_pilot", pxpSwitchData.PersistenceData.PIT1_HT) -- Pitot Heat
        set("sim/cockpit2/ice/ice_static_heat_on_pilot", pxpSwitchData.PersistenceData.STAT1_HT) -- Static Heat
        set("sim/cockpit2/ice/ice_AOA_heat_on", pxpSwitchData.PersistenceData.AOA1_HT) -- AOA Heat
        set("sim/cockpit2/ice/ice_pitot_heat_on_copilot", pxpSwitchData.PersistenceData.PIT2_HT) -- Pitot Heat
        set("sim/cockpit2/ice/ice_static_heat_on_copilot", pxpSwitchData.PersistenceData.STAT2_HT) -- Static Heat
        set("sim/cockpit2/ice/ice_AOA_heat_on_copilot", pxpSwitchData.PersistenceData.AOA2_HT) -- AOA Heat
        set("sim/cockpit2/ice/ice_window_heat_on", pxpSwitchData.PersistenceData.WS_BLD) -- Window Bleed
        set_array("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 0, pxpSwitchData.PersistenceData.INLET1_AI) -- 0 Left 1 Right
        set_array("sim/cockpit2/ice/ice_inlet_heat_on_per_engine", 1, pxpSwitchData.PersistenceData.INLET2_AI)
        set_array("sim/cockpit/switches/anti_ice_engine_air", 0, pxpSwitchData.PersistenceData.ENG_AI1) -- 0 Left 1 Right
        set_array("sim/cockpit/switches/anti_ice_engine_air", 1, pxpSwitchData.PersistenceData.ENG_AI2)
        set("sim/cockpit2/ice/ice_surface_boot_on", pxpSwitchData.PersistenceData.WING_BOOT) 
        set("sim/cockpit2/ice/ice_surfce_heat_on", pxpSwitchData.PersistenceData.WING_HEAT)
        set("sim/cockpit2/ice/ice_prop_heat_on", pxpSwitchData.PersistenceData.PROP_HEAT)


        -- Controls
        set("sim/cockpit2/controls/elevator_trim", pxpSwitchData.PersistenceData.TRIM)
        set("sim/cockpit2/controls/speedbrake_ratio", pxpSwitchData.PersistenceData.SPD_BRK)
        set("sim/cockpit2/controls/flap_ratio", pxpSwitchData.PersistenceData.FLP_HNDL)
        set("sim/cockpit2/switches/jet_sync_mode", pxpSwitchData.PersistenceData.FAN_SYNC)
        set("sim/cockpit2/switches/prop_sync_on", pxpSwitchData.PersistenceData.PROP_SYNC)
        set("sim/cockpit2/engine/actuators/throttle_ratio_all", pxpSwitchData.PersistenceData.THRTL)
        set("sim/cockpit2/engine/actuators/prop_ratio_all", pxpSwitchData.PersistenceData.PROP)
        set("sim/cockpit2/engine/actuators/mixture_ratio_all", pxpSwitchData.PersistenceData.MIX)
        set_array("sim/cockpit2/engine/actuators/carb_heat_ratio", 0, pxpSwitchData.PersistenceData.CARB1)
        set_array("sim/cockpit2/engine/actuators/carb_heat_ratio", 1, pxpSwitchData.PersistenceData.CARB2)
        set_array("sim/cockpit2/engine/actuators/cowl_flap_ratio", 0, pxpSwitchData.PersistenceData.COWL1)
        set_array("sim/cockpit2/engine/actuators/cowl_flap_ratio", 1, pxpSwitchData.PersistenceData.COWL2)

        if loadedAircraft == 'S550_Citation_II.acf' then
            if (XPLMFindDataRef("thranda/cockpit/actuators/HideYokeL") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("thranda/cockpit/actuators/HideYokeL", pxpSwitchData.PersistenceData.LYOKE)
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestLR") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("thranda/cockpit/animations/ArmRestLR", pxpSwitchData.PersistenceData.LARM) -- Left Arm Rests
                end
            end
            if (XPLMFindDataRef("thranda/cockpit/animations/ArmRestRL") ~= nil) then
                if pxpSwitchData.PersistenceData.LYOKE ~= nil then
                    set("thranda/cockpit/animations/ArmRestRL", pxpSwitchData.PersistenceData.RARM) -- Right Arm Rest
                end
            end
        else
            print("PXP Skipping Carenado Citation II Ref's")
        end
--[[
        set("thranda/electrical/AC_InverterSwitch", pxpSwitchData.PersistenceData.INV) -- Inverter Switch

        set("thranda/cockpit/actuators/HideYokeR", pxpSwitchData.PersistenceData.RYOKE) -- Right Yoke
        
        
        set("thranda/views/WindowRefl", pxpSwitchData.PersistenceData.WREFL) -- Window Reflections
        set("thranda/views/InstRefl", pxpSwitchData.PersistenceData.IREFL) -- Instrument Reflections
        set("thranda/views/staticelements", pxpSwitchData.PersistenceData.COVERS) -- Pitot Covers
        
        

        set("thranda/actuators/VoltSelAct", pxpSwitchData.PersistenceData.VOLT_SEL) -- Volt Selector
        set("thranda/annunciators/AnnunTestKnob", pxpSwitchData.PersistenceData.TEST_SEL) -- Test Selector


       
        set_array("sim/cockpit/gyros/gyr_free_slaved", 0, pxpSwitchData.PersistenceData.GYROSL) -- 0 LH Main, 1 LH Source
        set_array("sim/cockpit/gyros/gyr_free_slaved", 1, pxpSwitchData.PersistenceData.GYROSR)

        
        set("thranda/fuel/CrossFeedLRSw", pxpSwitchData.PersistenceData.FUEL_SEL)
        set("thranda/lights/RecogLights", pxpSwitchData.PersistenceData.RECOG)

        

        set("thranda/instruments/BaroUnits", pxpSwitchData.PersistenceData.BARO_UNIT)

        set("thranda/knobs/N1_Dial", pxpSwitchData.PersistenceData.N1_Dial)
        set_array("sim/cockpit2/switches/instrument_brightness_ratio", 1, pxpSwitchData.PersistenceData.FLOOD_LT)
        set_array("sim/cockpit2/switches/generic_lights_switch", 30 ,pxpSwitchData.PersistenceData.PNL_LT)
        set_array("sim/cockpit2/switches/instrument_brightness_ratio", 2, pxpSwitchData.PersistenceData.PNL_LFT , 3)
        set_array("sim/cockpit2/switches/instrument_brightness_ratio", 3, pxpSwitchData.PersistenceData.PNL_CTR , 4)
        set_array("sim/cockpit2/switches/instrument_brightness_ratio", 4, pxpSwitchData.PersistenceData.PNL_RT , 5)
        set_array("sim/cockpit2/switches/instrument_brightness_ratio", 5, pxpSwitchData.PersistenceData.PNL_EL , 6)
        set("sim/cockpit/switches/fasten_seat_belts", pxpSwitchData.PersistenceData.ST_BLT)
        set("thranda/lights/LandingLightLeft", pxpSwitchData.PersistenceData.L_LND)
        set("thranda/lights/LandingLightRight", pxpSwitchData.PersistenceData.R_LND)
        set("thranda/gear/AntiSkid", pxpSwitchData.PersistenceData.ASKID)

        set("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm", pxpSwitchData.PersistenceData.PRESS_VVI)
        set("sim/cockpit/pressure/cabin_altitude_set_m_msl", pxpSwitchData.PersistenceData.CAB_ALT)
        set_array("thranda/BT", 22, pxpSwitchData.PersistenceData.TEMP_MAN)
        set("thranda/pneumatic/CabinTempAct", pxpSwitchData.PersistenceData.TEMP_CTRL)
        set("thranda/pneumatic/PressureSource", pxpSwitchData.PersistenceData.PRES_SRC)
        set("thranda/pneumatic/AirFlowDistribution", pxpSwitchData.PersistenceData.FLOW_DIST)

        


        set("thranda/ice/WindshieldIceL", pxpSwitchData.PersistenceData.L_WS)
        set("thranda/ice/WindshieldIceR", pxpSwitchData.PersistenceData.R_WS)
        set_array("thranda/BT", 23, pxpSwitchData.PersistenceData.CAB_FAN1)
        set_array("thranda/BT", 24, pxpSwitchData.PersistenceData.CAB_FOG)
        set("thranda/pneumatic/AC", pxpSwitchData.PersistenceData.AC)
        set("thranda/pneumatic/BlowerIntensity", pxpSwitchData.PersistenceData.BLWR)
        set("thranda/pneumatic/CabinVent", pxpSwitchData.PersistenceData.CAB_VNT)
        set("thranda/pneumatic/CabinFan", pxpSwitchData.PersistenceData.CAB_FAN2)

        

        if ENG1_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
            set("thranda/cockpit/ThrottleLatchAnim_0", 0.5)
            print("Command Shut 1")
        end
        if ENG2_RUN == 1 and pxpSwitchData.PersistenceData.ENG1_RUN == 0 then
            set("thranda/cockpit/ThrottleLatchAnim_1", 0.5)
            print("Command Shut 2")
        end]]
        print("PersistenceXP Panel State Loaded")
    end
end

 --[[   function PXPSideSync()
        local Baro = nil
        local SpdBug = nil

        if get("sim/cockpit/autopilot/airspeed") ~= SpdBug then
            SpdBug = get("sim/cockpit/autopilot/airspeed")
            set("thranda/cockpit/actuators/ASI_adjustCo", SpdBug)
        end
        if get("sim/cockpit/misc/barometer_setting") ~= Baro then
            Baro = get("sim/cockpit/misc/barometer_setting")
            set("sim/cockpit/misc/barometer_setting2", Baro)
        end
    else
    print("PersistenceXP panel state for aircraft not found")   
end]]




-- do_sometimes("PXPSideSync()")



-- end -- master end