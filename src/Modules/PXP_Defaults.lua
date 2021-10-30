--[[
    Data file for default aircraft
]]

local PXP_Defaults = {};




function pxpCompile_Defaults()
    -- Deafult Electrical
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



    -- Nav Related

    if (XPLMFindDataRef("sim/cockpit/gyros/gyr_free_slaved", 0) ~= nil) then
        GYRSL = get("sim/cockpit/gyros/gyr_free_slaved", 0)
    end
    if (XPLMFindDataRef("sim/cockpit/gyros/gyr_free_slaved", 1) ~= nil) then
        GYROSR = get("sim/cockpit/gyros/gyr_free_slaved", 1)
    end

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
    if (XPLMFindDataRef("sim/cockpit2/pressurization/actuators/cabin_altitude_ft") ~= nil) then
        CAB_ALT = get("sim/cockpit2/pressurization/actuators/cabin_altitude_ft")
    end
    if (XPLMFindDataRef("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm") ~= nil) then
        CAB_RATE = get("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm")
    end

    -- Internal Lighting

    if (XPLMFindDataRef("sim/cockpit/switches/fasten_seat_belts") ~= nil) then
        ST_BLT = get("sim/cockpit/switches/fasten_seat_belts")
    end
    if (XPLMFindDataRef("sim/cockpit/switches/no_smoking") ~= nil) then
        NO_SMK = get("sim/cockpit/switches/no_smoking")
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 0) ~= nil) then
        PNL_LT0 = get("sim/cockpit2/switches/panel_brightness_ratio", 0)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 1) ~= nil) then
        PNL_LT1 = get("sim/cockpit2/switches/panel_brightness_ratio", 1)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 2) ~= nil) then
        PNL_LT2 = get("sim/cockpit2/switches/panel_brightness_ratio", 2)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 3) ~= nil) then
        PNL_LT3 = get("sim/cockpit2/switches/panel_brightness_ratio", 3)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 4) ~= nil) then
        PNL_LT4 = get("sim/cockpit2/switches/panel_brightness_ratio", 4)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 5) ~= nil) then
        PNL_LT5 = get("sim/cockpit2/switches/panel_brightness_ratio", 5)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 6) ~= nil) then
        PNL_LT6 = get("sim/cockpit2/switches/panel_brightness_ratio", 6)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 7) ~= nil) then
        PNL_LT7 = get("sim/cockpit2/switches/panel_brightness_ratio", 7)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 8) ~= nil) then
        PNL_LT8 = get("sim/cockpit2/switches/panel_brightness_ratio", 8)
    end
    if (XPLMFindDataRef("sim/cockpit2/switches/panel_brightness_ratio", 9) ~= nil) then
        PNL_LT9 = get("sim/cockpit2/switches/panel_brightness_ratio", 9)
    end

end

return PXP_Defaults;