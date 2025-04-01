-- UI Module
-- This module handles menu creation and rendering functionality

local ui = {}

-- Required modules
local control_panel_helper = require("common/utility/control_panel_helper")
local key_helper = require("common/utility/key_helper")
local plugin_helper = require("common/utility/plugin_helper")

-- Define menu elements
ui.menu_elements = {
    main_tree = core.menu.tree_node(),
    keybinds_tree_node = core.menu.tree_node(),
    enable_script_check = core.menu.checkbox(true, "enable_script_check"),
    
    -- General settings
    settings_tree_node = core.menu.tree_node(),
    heal_threshold = core.menu.slider_int(60, 90, 75, "heal_threshold"),
    shield_threshold = core.menu.slider_int(80, 100, 90, "shield_threshold"),
    
    -- Damage spells toggle
    damage_spells_tree_node = core.menu.tree_node(),
    enable_purge_the_wicked = core.menu.checkbox(true, "enable_purge_the_wicked"),
    enable_mind_blast = core.menu.checkbox(true, "enable_mind_blast"),
    enable_penance_damage = core.menu.checkbox(true, "enable_penance_damage"),
    enable_smite = core.menu.checkbox(true, "enable_smite"),
    enable_mind_games = core.menu.checkbox(true, "enable_mind_games"),
    enable_shadow_word_death = core.menu.checkbox(true, "enable_shadow_word_death"),
    
    -- Heal spells toggle
    heal_spells_tree_node = core.menu.tree_node(),
    enable_shield = core.menu.checkbox(true, "enable_shield"),
    enable_shadowmend = core.menu.checkbox(true, "enable_shadowmend"),
    enable_penance_heal = core.menu.checkbox(true, "enable_penance_heal"),
    enable_pain_suppression = core.menu.checkbox(true, "enable_pain_suppression"),
    enable_rapture = core.menu.checkbox(true, "enable_rapture"),
    enable_power_word_radiance = core.menu.checkbox(true, "enable_power_word_radiance"),
    enable_evangelism = core.menu.checkbox(true, "enable_evangelism"),
    
    -- Cooldown settings
    cooldowns_tree_node = core.menu.tree_node(),
    enable_power_infusion = core.menu.checkbox(true, "enable_power_infusion"),
    power_infusion_key = core.menu.keybind(999, false, "power_infusion_key"),
    power_infusion_self = core.menu.checkbox(true, "power_infusion_self"),
    enable_spirit_shell = core.menu.checkbox(true, "enable_spirit_shell"),
    spirit_shell_key = core.menu.keybind(999, false, "spirit_shell_key"),
    
    -- Ramping settings
    ramping_tree_node = core.menu.tree_node(),
    enable_ramping = core.menu.checkbox(true, "enable_ramping"),
    ramp_automatically = core.menu.checkbox(false, "ramp_automatically"),
    ramp_time_before_event = core.menu.slider_int(5, 20, 10, "ramp_time_before_event"),
    manual_ramp_key = core.menu.keybind(999, false, "manual_ramp_key"),
    
    -- Keybinds
    enable_toggle = core.menu.keybind(999, false, "toggle_script_check"),
    pain_suppression_key = core.menu.keybind(999, false, "pain_suppression_key"),

    -- Interface settings
    draw_plugin_state = core.menu.checkbox(true, "draw_plugin_state"),
    ts_custom_logic_override = core.menu.checkbox(true, "override_ts_logic"),
    draw_atonement_count = core.menu.checkbox(true, "draw_atonement_count"),
    draw_ramp_timer = core.menu.checkbox(true, "draw_ramp_timer")
}

-- Render the menu
function ui.render_menu()
    ui.menu_elements.main_tree:render("Discipline Priest Rotation", function()
        ui.menu_elements.enable_script_check:render("Enable Script")

        if not ui.menu_elements.enable_script_check:get_state() then
            return false
        end

        ui.menu_elements.settings_tree_node:render("Settings", function()
            ui.menu_elements.heal_threshold:render("Heal Threshold %")
            ui.menu_elements.shield_threshold:render("Shield Threshold %")
            ui.menu_elements.ts_custom_logic_override:render("Enable TS Custom Settings Override")
            ui.menu_elements.draw_plugin_state:render("Draw Plugin State")
            ui.menu_elements.draw_atonement_count:render("Display Atonement Count")
            ui.menu_elements.draw_ramp_timer:render("Display Ramp Timer")
        end)

        ui.menu_elements.damage_spells_tree_node:render("Damage Spells", function()
            ui.menu_elements.enable_purge_the_wicked:render("Enable Purge The Wicked")
            ui.menu_elements.enable_mind_blast:render("Enable Mind Blast")
            ui.menu_elements.enable_penance_damage:render("Enable Penance (Damage)")
            ui.menu_elements.enable_smite:render("Enable Smite")
            ui.menu_elements.enable_shadow_word_death:render("Enable Shadow Word: Death")
            ui.menu_elements.enable_mind_games:render("Enable Mind Games")
        end)

        ui.menu_elements.heal_spells_tree_node:render("Healing Spells", function()
            ui.menu_elements.enable_shield:render("Enable Power Word: Shield")
            ui.menu_elements.enable_shadowmend:render("Enable Shadow Mend")
            ui.menu_elements.enable_penance_heal:render("Enable Penance (Healing)")
            ui.menu_elements.enable_pain_suppression:render("Enable Pain Suppression")
            ui.menu_elements.enable_power_word_radiance:render("Enable Power Word: Radiance")
        end)

        ui.menu_elements.cooldowns_tree_node:render("Cooldowns", function()
            ui.menu_elements.enable_power_infusion:render("Enable Power Infusion")
            ui.menu_elements.power_infusion_key:render("Power Infusion Key")
            ui.menu_elements.power_infusion_self:render("Use Power Infusion on Self")
            ui.menu_elements.enable_rapture:render("Enable Rapture")
            ui.menu_elements.enable_evangelism:render("Enable Evangelism")
            ui.menu_elements.enable_spirit_shell:render("Enable Spirit Shell")
            ui.menu_elements.spirit_shell_key:render("Spirit Shell Key")
        end)

        ui.menu_elements.ramping_tree_node:render("Damage Ramping", function()
            ui.menu_elements.enable_ramping:render("Enable Ramping System")
            ui.menu_elements.ramp_automatically:render("Auto-Ramp Based on BigWigs Timers")
            ui.menu_elements.ramp_time_before_event:render("Seconds Before Event to Start Ramping")
            ui.menu_elements.manual_ramp_key:render("Manual Ramp Key")
        end)

        ui.menu_elements.keybinds_tree_node:render("Keybinds", function()
            ui.menu_elements.enable_toggle:render("Enable Script Toggle")
            ui.menu_elements.pain_suppression_key:render("Pain Suppression Key")
        end)
    end)
end

-- Render on-screen UI elements
function ui.render_screen(is_ramping, ramp_phase, ramp_start_time, next_big_damage_time, get_atonement_count)
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end

    if not ui.menu_elements.enable_script_check:get_state() then
        return
    end

    if not plugin_helper:is_toggle_enabled(ui.menu_elements.enable_toggle) then
        if ui.menu_elements.draw_plugin_state:get_state() then
            plugin_helper:draw_text_character_center("DISABLED")
        end
        return
    end
    
    -- Load color properly
    local color_module = require("common/color")
    local color = color_module
    
    -- Display Atonement count if enabled
    if ui.menu_elements.draw_atonement_count:get_state() then
        local atonement_count = get_atonement_count()
        
        local display_color = color.white()
        
        -- Color based on count (green for good coverage, yellow for moderate, red for low)
        if atonement_count >= 3 then
            display_color = color.green()
        elseif atonement_count >= 1 then
            display_color = color.yellow()
        else
            display_color = color.red()
        end
        
        plugin_helper:draw_text_character_center("Atonement: " .. atonement_count, display_color, 20)
    end
    
    -- Display ramping status if enabled
    if ui.menu_elements.draw_ramp_timer:get_state() and is_ramping then
        local current_time = core.time()
        local elapsed_time = current_time - ramp_start_time
        local time_to_damage = next_big_damage_time - current_time
        
        local phase_text = ""
        local phase_color = color.white()
        
        if ramp_phase == 1 then
            phase_text = "Shielding"
            phase_color = color.blue_pale()
        elseif ramp_phase == 2 then
            phase_text = "Radiance"
            phase_color = color.purple()
        elseif ramp_phase == 3 then
            phase_text = "Evangelism"
            phase_color = color.yellow()
        elseif ramp_phase == 4 then
            phase_text = "Damage Phase"
            phase_color = color.red()
        end
        
        -- Format time nicely
        local damage_timer = string.format("%.1f", time_to_damage)
        
        -- Draw ramping status
        plugin_helper:draw_text_character_center("RAMPING: " .. phase_text, phase_color, -20)
        plugin_helper:draw_text_character_center("Damage in: " .. damage_timer .. "s", time_to_damage < 3 and color.red() or color.yellow(), -40)
    end
end

-- Render the control panel elements
function ui.render_control_panel()
    local control_panel_elements = {}
    
    -- Enable Toggle on Control Panel
    if ui.menu_elements.enable_toggle then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Enable (" .. key_helper:get_key_name(ui.menu_elements.enable_toggle:get_key_code()) .. ") ",
            keybind = ui.menu_elements.enable_toggle
        })
    end
    
    -- Pain Suppression Toggle
    if ui.menu_elements.pain_suppression_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Pain Suppression (" .. key_helper:get_key_name(ui.menu_elements.pain_suppression_key:get_key_code()) .. ") ",
            keybind = ui.menu_elements.pain_suppression_key
        })
    end
    
    -- Power Infusion Toggle
    if ui.menu_elements.power_infusion_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Power Infusion (" .. key_helper:get_key_name(ui.menu_elements.power_infusion_key:get_key_code()) .. ") ",
            keybind = ui.menu_elements.power_infusion_key
        })
    end
    
    -- Manual Ramp Toggle
    if ui.menu_elements.manual_ramp_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Manual Ramp (" .. key_helper:get_key_name(ui.menu_elements.manual_ramp_key:get_key_code()) .. ") ",
            keybind = ui.menu_elements.manual_ramp_key
        })
    end
    
    -- Spirit Shell Toggle
    if ui.menu_elements.spirit_shell_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Spirit Shell (" .. key_helper:get_key_name(ui.menu_elements.spirit_shell_key:get_key_code()) .. ") ",
            keybind = ui.menu_elements.spirit_shell_key
        })
    end

    return control_panel_elements
end

return ui
