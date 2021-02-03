--[[ Starting a new file, what an idiot
Persistence for FSE
Objective:
    - Record switch states on exit, reload on loade
    - Record position and reload
    - Isolate to specific airframe variations (rego?)
    ]]



if PLANE_ICAO == "C550" then

-- Modules
local LIP = require("LIP")
require "graphics"

-- Variables
local C550fsePersistenceSettings = {}
local C550FSEP_Loaded = false
local C550FSEPtimer = 3
local C550FSEPStartTime = 0
local C550FSEPready = false

-- Datarefs
dataref("SIM_TIME", "sim/time/total_running_time_sec")
dataref("PRK_BRK", "sim/flightmodel/controls/parkbrake")
dataref("ENG1_RUN", "sim/flightmodel/engine/ENGN_running", 0)
dataref("ENG2_RUN", "sim/flightmodel/engine/ENGN_running", 1)


function WritePersistenceData(C550fsePersistenceSettings)
    LIP.save(AIRCRAFT_PATH .. "/fsePersistence.ini", C550fsePersistenceSettings)
end

function SavePersistenceData()
    local LYOKE = get("thranda/cockpit/actuators/HideYokeL")
    local RYOKE = get("thranda/cockpit/actuators/HideYokeR") -- Right Yoke
    local LARM = get("thranda/cockpit/animations/ArmRestLR") -- Left Arm Rests
    local RARM = get("thranda/cockpit/animations/ArmRestRL") -- Right Arm Rest
    local GPU = get("sim/cockpit/electrical/gpu_on")
    local WREFL = get("thranda/views/WindowRefl") -- Window Reflections
    local IREFL = get("thranda/views/InstRefl") -- Instrument Reflections
    local COVERS = get("thranda/views/staticelements") -- Pitot Covers
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

    local VOLT_SEL = get("thranda/actuators/VoltSelAct") -- Volt Selector
    local TEST_SEL = get("thranda/annunciators/AnnunTestKnob") -- Test Selector
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

    local FUEL_SEL = get("thranda/fuel/CrossFeedLRSw")

    local RECOG = get("thranda/lights/RecogLights")
    local COLL = get("sim/cockpit/electrical/strobe_lights_on")
    local Nav_LT = get("sim/cockpit2/switches/navigation_lights_on")

    local SPD_BG = get("sim/cockpit/autopilot/airspeed") -- Speed Bug
    local RMI_L = get("sim/cockpit/switches/RMI_l_vor_adf_selector") -- Left RMI
    local RMI_R = get("sim/cockpit/switches/RMI_r_vor_adf_selector") -- Right RMI
    local DME_CH = get("sim/cockpit2/radios/actuators/DME_mode")
    local DME_SEL = get("sim/cockpit/switches/DME_distance_or_time")
    local DME_PWR = get("sim/cockpit2/radios/actuators/dme_power")
    local DH = get("sim/cockpit/misc/radio_altimeter_minimum")

    local BARO_UNIT = get("thranda/instruments/BaroUnits")
    local FUEL_TTL = get("sim/cockpit2/fuel/fuel_totalizer_sum_kg")

    local N1_Dial = get("thranda/knobs/N1_Dial")
    -- local INSTR_LTS = get("sim/cockpit2/switches/instrument_brightness_ratio")
    local FLOOD_LT = get("sim/cockpit2/switches/instrument_brightness_ratio", 1)
    local PNL_LT = get("sim/cockpit2/switches/generic_lights_switch", 30)
    local PNL_LFT = get("sim/cockpit2/switches/instrument_brightness_ratio", 2)
    local PNL_CTR = get("sim/cockpit2/switches/instrument_brightness_ratio", 3)
    local PNL_RT = get("sim/cockpit2/switches/instrument_brightness_ratio", 4)
    local PNL_EL = get("sim/cockpit2/switches/instrument_brightness_ratio", 5)
    local ST_BLT = get("sim/cockpit/switches/fasten_seat_belts")
    local BCN = get("sim/cockpit2/switches/beacon_on")
    local L_LND = get("thranda/lights/LandingLightLeft")
    local R_LND = get("thranda/lights/LandingLightRight")
    local ASKID = get("thranda/gear/AntiSkid")

    local PRESS_VVI = get("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm")
    local CAB_ALT = get("sim/cockpit/pressure/cabin_altitude_set_m_msl")
    local TEMP_MAN = get("thranda/BT", 23)
    local TEMP_CTRL = get("thranda/pneumatic/CabinTempAct")
    local PRES_SRC = get("thranda/pneumatic/PressureSource")
    local FLOW_DIST = get("thranda/pneumatic/AirFlowDistribution")

    local TRIM = get("sim/cockpit2/controls/elevator_trim")
    local SPD_BRK = get("sim/cockpit2/controls/speedbrake_ratio")
    local FLP_HNDL = get("sim/cockpit2/controls/flap_ratio")
    local FAN_SYNC = get("sim/cockpit2/switches/jet_sync_mode")

    local CRS1 = get("sim/cockpit/radios/nav1_obs_degm")
    local HDG = get("sim/cockpit/autopilot/heading_mag")
    local VS = get("sim/cockpit2/autopilot/vvi_dial_fpm")
    local APA = get("sim/cockpit2/autopilot/altitude_dial_ft")

    local L_WS = get("thranda/ice/WindshieldIceL")
    local R_WS = get("thranda/ice/WindshieldIceR")
    local CAB_FAN1 = get("thranda/BT", 23)
    local CAB_FOG = get("thranda/BT", 24)
    local AC = get("thranda/pneumatic/AC")
    local BLWR = get("thranda/pneumatic/BlowerIntensity")
    local CAB_VNT = get("thranda/pneumatic/CabinVent")
    local CAB_FAN2 = get("thranda/pneumatic/CabinFan")

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

    C550fsePersistenceSettings = {
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
    WritePersistenceData(C550fsePersistenceSettings)
    print("FSE Persistence: Panel data saved to " .. AIRCRAFT_PATH .. "fsePersistence.ini")
end

function ParsePersistenceData()
    C550fsePersistenceSettings = LIP.load(AIRCRAFT_PATH .. "/fsePersistence.ini")

    set("thranda/cockpit/actuators/HideYokeL", C550fsePersistenceSettings.PersistenceData.LYOKE)
    set("thranda/cockpit/actuators/HideYokeR", C550fsePersistenceSettings.PersistenceData.RYOKE) -- Right Yoke
    set("thranda/cockpit/animations/ArmRestLR", C550fsePersistenceSettings.PersistenceData.LARM) -- Left Arm Rests
    set("thranda/cockpit/animations/ArmRestRL", C550fsePersistenceSettings.PersistenceData.RARM) -- Right Arm Rest
    set("sim/cockpit/electrical/gpu_on", C550fsePersistenceSettings.PersistenceData.GPU)
    set("thranda/views/WindowRefl", C550fsePersistenceSettings.PersistenceData.WREFL) -- Window Reflections
    set("thranda/views/InstRefl", C550fsePersistenceSettings.PersistenceData.IREFL) -- Instrument Reflections
    set("thranda/views/staticelements", C550fsePersistenceSettings.PersistenceData.COVERS) -- Pitot Covers
    set_array("sim/cockpit2/switches/door_open", 0, C550fsePersistenceSettings.PersistenceData.DOOR0) -- 0 Main, 1 Left Bag, 2 Right Bag
    set_array("sim/cockpit2/switches/door_open", 1, C550fsePersistenceSettings.PersistenceData.DOOR1) -- 0 Main, 1 Left Bag, 2 Right Bag
    set_array("sim/cockpit2/switches/door_open", 2, C550fsePersistenceSettings.PersistenceData.DOOR2) -- 0 Main, 1 Left Bag, 2 Right Bag
    set("sim/cockpit2/clock_timer/timer_mode", C550fsePersistenceSettings.PersistenceData.CLK_MODE)
    set("sim/cockpit2/radios/actuators/audio_com_selection_man", C550fsePersistenceSettings.PersistenceData.XMT) -- Transmit Selector
    set("sim/cockpit2/radios/actuators/audio_selection_com1", C550fsePersistenceSettings.PersistenceData.C1_RCV) -- Com 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_com2", C550fsePersistenceSettings.PersistenceData.C2_RCV) -- Com 2 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_adf1", C550fsePersistenceSettings.PersistenceData.ADF1_RCV) -- ADF 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_adf1", C550fsePersistenceSettings.PersistenceData.ADF2_RCV) -- ADF 2 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_nav1", C550fsePersistenceSettings.PersistenceData.NAV1_RCV) -- NAV 1 Receives
    set("sim/cockpit2/radios/actuators/audio_selection_nav2", C550fsePersistenceSettings.PersistenceData.NAV2_RCV) -- NAV 2 Receives
    set("sim/cockpit2/radios/actuators/audio_dme_enabled", C550fsePersistenceSettings.PersistenceData.DME1_RCV) -- DME Recieve
    set("sim/cockpit2/radios/actuators/audio_marker_enabled", C550fsePersistenceSettings.PersistenceData.MRKR_RCV) -- Marker Recieve

    set("thranda/actuators/VoltSelAct", C550fsePersistenceSettings.PersistenceData.VOLT_SEL) -- Volt Selector
    set("thranda/annunciators/AnnunTestKnob", C550fsePersistenceSettings.PersistenceData.TEST_SEL) -- Test Selector
    set_array("sim/cockpit/electrical/generator_on", 0, C550fsePersistenceSettings.PersistenceData.GENL) -- Gen Switches 0 Left, 1 Right
    set_array("sim/cockpit/electrical/generator_on", 1, C550fsePersistenceSettings.PersistenceData.GENR)
    set("sim/cockpit/electrical/battery_on", C550fsePersistenceSettings.PersistenceData.BAT) -- Batt Switch
    set("thranda/electrical/AC_InverterSwitch", C550fsePersistenceSettings.PersistenceData.INV) -- Inverter Switch
    set("sim/cockpit/electrical/avionics_on", C550fsePersistenceSettings.PersistenceData.AVN) -- Avionics Switch
    set_array("sim/cockpit/engine/fuel_pump_on", 0, C550fsePersistenceSettings.PersistenceData.BOOST_PMP1) -- Fuel Pumps, 0 Left, 1 Right
    set_array("sim/cockpit/engine/fuel_pump_on", 1, C550fsePersistenceSettings.PersistenceData.BOOST_PMP2)
    set_array("sim/cockpit/engine/igniters_on", 0, C550fsePersistenceSettings.PersistenceData.IGN1) -- Ignition 0 Left 1 Right
    set_array("sim/cockpit/engine/igniters_on", 1, C550fsePersistenceSettings.PersistenceData.IGN2)
    set("sim/cockpit2/ice/ice_pitot_heat_on_pilot", C550fsePersistenceSettings.PersistenceData.PIT_HT) -- Pitot Heat
    set("sim/cockpit2/ice/ice_window_heat_on", C550fsePersistenceSettings.PersistenceData.WS_BLD) -- Window Bleed
    set_array("sim/cockpit/switches/anti_ice_engine_air", 0, C550fsePersistenceSettings.PersistenceData.ENG_AI1) -- 0 Left 1 Right
    set_array("sim/cockpit/switches/anti_ice_engine_air", 1, C550fsePersistenceSettings.PersistenceData.ENG_AI2)
    set("sim/cockpit2/ice/ice_surface_boot_on", C550fsePersistenceSettings.PersistenceData.SURF_AI) 
    set_array("sim/cockpit/gyros/gyr_free_slaved", 0, C550fsePersistenceSettings.PersistenceData.GYROSL) -- 0 LH Main, 1 LH Source
    set_array("sim/cockpit/gyros/gyr_free_slaved", 1, C550fsePersistenceSettings.PersistenceData.GYROSR)

    
    set("thranda/fuel/CrossFeedLRSw", C550fsePersistenceSettings.PersistenceData.FUEL_SEL)
    set("thranda/lights/RecogLights", C550fsePersistenceSettings.PersistenceData.RECOG)
    set("sim/cockpit/electrical/strobe_lights_on", C550fsePersistenceSettings.PersistenceData.COLL)
    set("sim/cockpit2/switches/navigation_lights_on", C550fsePersistenceSettings.PersistenceData.Nav_LT)

    set("sim/cockpit/autopilot/airspeed", C550fsePersistenceSettings.PersistenceData.SPD_BG) -- Speed Bug
    set("sim/cockpit/switches/RMI_l_vor_adf_selector", C550fsePersistenceSettings.PersistenceData.RMI_L) -- Left RMI
    set("sim/cockpit/switches/RMI_r_vor_adf_selector", C550fsePersistenceSettings.PersistenceData.RMI_R) -- Right RMI

    set("sim/cockpit2/radios/actuators/DME_mode", C550fsePersistenceSettings.PersistenceData.DME_CH)
    set("sim/cockpit/switches/DME_distance_or_time", C550fsePersistenceSettings.PersistenceData.DME_SEL)
    set("sim/cockpit2/radios/actuators/dme_power", C550fsePersistenceSettings.PersistenceData.DME_PWR)

    set("sim/cockpit/misc/radio_altimeter_minimum", C550fsePersistenceSettings.PersistenceData.DH)
    set("thranda/instruments/BaroUnits", C550fsePersistenceSettings.PersistenceData.BARO_UNIT)
    set("sim/cockpit2/fuel/fuel_totalizer_sum_kg", C550fsePersistenceSettings.PersistenceData.FUEL_TTL)

    set("thranda/knobs/N1_Dial", C550fsePersistenceSettings.PersistenceData.N1_Dial)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 1, C550fsePersistenceSettings.PersistenceData.FLOOD_LT)
    set_array("sim/cockpit2/switches/generic_lights_switch", 30 ,C550fsePersistenceSettings.PersistenceData.PNL_LT)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 2, C550fsePersistenceSettings.PersistenceData.PNL_LFT , 3)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 3, C550fsePersistenceSettings.PersistenceData.PNL_CTR , 4)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 4, C550fsePersistenceSettings.PersistenceData.PNL_RT , 5)
    set_array("sim/cockpit2/switches/instrument_brightness_ratio", 5, C550fsePersistenceSettings.PersistenceData.PNL_EL , 6)
    set("sim/cockpit/switches/fasten_seat_belts", C550fsePersistenceSettings.PersistenceData.ST_BLT)
    set("sim/cockpit2/switches/beacon_on", C550fsePersistenceSettings.PersistenceData.BCN)
    set("thranda/lights/LandingLightLeft", C550fsePersistenceSettings.PersistenceData.L_LND)
    set("thranda/lights/LandingLightRight", C550fsePersistenceSettings.PersistenceData.R_LND)
    set("thranda/gear/AntiSkid", C550fsePersistenceSettings.PersistenceData.ASKID)

    set("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm", C550fsePersistenceSettings.PersistenceData.PRESS_VVI)
    set("sim/cockpit/pressure/cabin_altitude_set_m_msl", C550fsePersistenceSettings.PersistenceData.CAB_ALT)
    set_array("thranda/BT", 22, C550fsePersistenceSettings.PersistenceData.TEMP_MAN)
    set("thranda/pneumatic/CabinTempAct", C550fsePersistenceSettings.PersistenceData.TEMP_CTRL)
    set("thranda/pneumatic/PressureSource", C550fsePersistenceSettings.PersistenceData.PRES_SRC)
    set("thranda/pneumatic/AirFlowDistribution", C550fsePersistenceSettings.PersistenceData.FLOW_DIST)

    set("sim/cockpit2/controls/elevator_trim", C550fsePersistenceSettings.PersistenceData.TRIM)
    set("sim/cockpit2/controls/speedbrake_ratio", C550fsePersistenceSettings.PersistenceData.SPD_BRK)
    set("sim/cockpit2/controls/flap_ratio", C550fsePersistenceSettings.PersistenceData.FLP_HNDL)
    set("sim/cockpit2/switches/jet_sync_mode", C550fsePersistenceSettings.PersistenceData.FAN_SYNC)

    set("sim/cockpit/radios/nav1_obs_degm", C550fsePersistenceSettings.PersistenceData.CRS1)
    set("sim/cockpit/autopilot/heading_mag", C550fsePersistenceSettings.PersistenceData.HDG)
    set("sim/cockpit2/autopilot/vvi_dial_fpm", C550fsePersistenceSettings.PersistenceData.VS)
    set("sim/cockpit2/autopilot/altitude_dial_ft", C550fsePersistenceSettings.PersistenceData.APA)

    set("thranda/ice/WindshieldIceL", C550fsePersistenceSettings.PersistenceData.L_WS)
    set("thranda/ice/WindshieldIceR", C550fsePersistenceSettings.PersistenceData.R_WS)
    set_array("thranda/BT", 23, C550fsePersistenceSettings.PersistenceData.CAB_FAN1)
    set_array("thranda/BT", 24, C550fsePersistenceSettings.PersistenceData.CAB_FOG)
    set("thranda/pneumatic/AC", C550fsePersistenceSettings.PersistenceData.AC)
    set("thranda/pneumatic/BlowerIntensity", C550fsePersistenceSettings.PersistenceData.BLWR)
    set("thranda/pneumatic/CabinVent", C550fsePersistenceSettings.PersistenceData.CAB_VNT)
    set("thranda/pneumatic/CabinFan", C550fsePersistenceSettings.PersistenceData.CAB_FAN2)

    set("sim/cockpit/radios/com1_freq_hz", C550fsePersistenceSettings.PersistenceData.COM1_ACT)
    set("sim/cockpit/radios/com1_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.COM1_STB)
    set("sim/cockpit/radios/com2_freq_hz", C550fsePersistenceSettings.PersistenceData.COM2_ACT)
    set("sim/cockpit/radios/com2_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.COM2_STB)
    set("sim/cockpit/radios/nav1_freq_hz", C550fsePersistenceSettings.PersistenceData.NAV1_ACT)
    set("sim/cockpit/radios/nav1_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.NAV1_STB)
    set("sim/cockpit/radios/nav1_freq_hz", C550fsePersistenceSettings.PersistenceData.NAV2_ACT)
    set("sim/cockpit/radios/nav1_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.NAV2_STB)
    set("sim/cockpit/radios/adf1_freq_hz", C550fsePersistenceSettings.PersistenceData.ADF1_ACT)
    set("sim/cockpit/radios/adf1_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.ADF1_STB)
    set("sim/cockpit/radios/adf2_freq_hz", C550fsePersistenceSettings.PersistenceData.ADF2_ACT)
    set("sim/cockpit/radios/adf2_stdby_freq_hz", C550fsePersistenceSettings.PersistenceData.ADF2_STB)  
    set("sim/cockpit/radios/transponder_code", C550fsePersistenceSettings.PersistenceData.XPDR_COD)

    set("sim/cockpit2/radios/actuators/com1_power", C550fsePersistenceSettings.PersistenceData.COM1_PWR)
    set("sim/cockpit2/radios/actuators/com2_power", C550fsePersistenceSettings.PersistenceData.COM2_PWR)
    set("sim/cockpit2/radios/actuators/nav1_power", C550fsePersistenceSettings.PersistenceData.NAV1_PWR)
    set("sim/cockpit2/radios/actuators/nav2_power", C550fsePersistenceSettings.PersistenceData.NAV2_PWR)
    set("sim/cockpit2/radios/actuators/adf1_power", C550fsePersistenceSettings.PersistenceData.ADF1_PWR)
    set("sim/cockpit2/radios/actuators/adf2_power", C550fsePersistenceSettings.PersistenceData.ADF2_PWR)
    set("sim/cockpit2/radios/actuators/transponder_mode", C550fsePersistenceSettings.PersistenceData.XPDR_MODE)

    if ENG1_RUN == 1 and C550fsePersistenceSettings.PersistenceData.ENG1_RUN == 0 then
        set("thranda/cockpit/ThrottleLatchAnim_0", 0.5)
        print("Command Shut 1")
    end
    if ENG2_RUN == 1 and C550fsePersistenceSettings.PersistenceData.ENG1_RUN == 0 then
        set("thranda/cockpit/ThrottleLatchAnim_1", 0.5)
        print("Command Shut 2")
    end
    print("FSE Persistence: Position data loaded from " .. AIRCRAFT_PATH .. "fsePersistence.ini")
end

function C550AutoPersistenceData()
    if C550FSEPtimer < 3 then
       C550FSEPtimer = C550FSEPtimer + 1
    end
    if C550FSEP_Loaded and C550FSEPtimer == 3 and PRK_BRK == 1 and ENG1_RUN == 0 then
        SavePersistenceData()
        C550FSEPtimer = 0
    end
    if C550FSEPready and not C550FSEP_Loaded then
        ParsePersistenceData() 
        C550FSEP_Loaded = true
    end
end

function C550SideSync()
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

function C550FSEP_StartDelay()
    if C550FSEPStartTime == 0 then
        C550FSEPStartTime = (SIM_TIME + 10)
    end
    if (SIM_TIME < C550FSEPStartTime) then
        return
    end
    C550FSEPready = true    
end

do_often("C550FSEP_StartDelay()")
do_sometimes("C550SideSync()")
do_sometimes("C550AutoPersistenceData()")

add_macro("FSE Persistence Save", "SavePersistenceData()")
add_macro("FSE Persistence Load", "ParsePersistenceData()")


end -- master end