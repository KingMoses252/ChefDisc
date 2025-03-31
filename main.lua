-- Discipline Priest Rotation
-- This script implements a complete rotation for Discipline Priests focusing on
-- Atonement healing through damage, direct healing, and ramping for upcoming damage events

-- Let's include all required modules:
---@type enums
local enums = require("common/enums")

---@type spell_queue
local spell_queue = require("common/modules/spell_queue")

---@type unit_helper
local unit_helper = require("common/utility/unit_helper")

---@type spell_helper
local spell_helper = require("common/utility/spell_helper")

---@type buff_manager
local buff_manager = require("common/modules/buff_manager")

---@type plugin_helper
local plugin_helper = require("common/utility/plugin_helper")

---@type spell_prediction
local spell_prediction = require("common/modules/spell_prediction")

---@type control_panel_helper
local control_panel_helper = require("common/utility/control_panel_helper")

---@type target_selector
local target_selector = require("common/modules/target_selector")

---@type key_helper
local key_helper = require("common/utility/key_helper")

-- Define menu elements:
local menu_elements = {
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

-- Render the menu:
local function my_menu_render()
    menu_elements.main_tree:render("Discipline Priest Rotation", function()
        menu_elements.enable_script_check:render("Enable Script")

        if not menu_elements.enable_script_check:get_state() then
            return false
        end

        menu_elements.settings_tree_node:render("Settings", function()
            menu_elements.heal_threshold:render("Heal Threshold %")
            menu_elements.shield_threshold:render("Shield Threshold %")
            menu_elements.ts_custom_logic_override:render("Enable TS Custom Settings Override")
            menu_elements.draw_plugin_state:render("Draw Plugin State")
            menu_elements.draw_atonement_count:render("Display Atonement Count")
            menu_elements.draw_ramp_timer:render("Display Ramp Timer")
        end)

        menu_elements.damage_spells_tree_node:render("Damage Spells", function()
            menu_elements.enable_purge_the_wicked:render("Enable Purge The Wicked")
            menu_elements.enable_mind_blast:render("Enable Mind Blast")
            menu_elements.enable_penance_damage:render("Enable Penance (Damage)")
            menu_elements.enable_smite:render("Enable Smite")
            menu_elements.enable_shadow_word_death:render("Enable Shadow Word: Death")
            menu_elements.enable_mind_games:render("Enable Mind Games")
        end)

        menu_elements.heal_spells_tree_node:render("Healing Spells", function()
            menu_elements.enable_shield:render("Enable Power Word: Shield")
            menu_elements.enable_shadowmend:render("Enable Shadow Mend")
            menu_elements.enable_penance_heal:render("Enable Penance (Healing)")
            menu_elements.enable_pain_suppression:render("Enable Pain Suppression")
            menu_elements.enable_power_word_radiance:render("Enable Power Word: Radiance")
        end)

        menu_elements.cooldowns_tree_node:render("Cooldowns", function()
            menu_elements.enable_power_infusion:render("Enable Power Infusion")
            menu_elements.power_infusion_key:render("Power Infusion Key")
            menu_elements.power_infusion_self:render("Use Power Infusion on Self")
            menu_elements.enable_rapture:render("Enable Rapture")
            menu_elements.enable_evangelism:render("Enable Evangelism")
            menu_elements.enable_spirit_shell:render("Enable Spirit Shell")
            menu_elements.spirit_shell_key:render("Spirit Shell Key")
        end)

        menu_elements.ramping_tree_node:render("Damage Ramping", function()
            menu_elements.enable_ramping:render("Enable Ramping System")
            menu_elements.ramp_automatically:render("Auto-Ramp Based on BigWigs Timers")
            menu_elements.ramp_time_before_event:render("Seconds Before Event to Start Ramping")
            menu_elements.manual_ramp_key:render("Manual Ramp Key")
        end)

        menu_elements.keybinds_tree_node:render("Keybinds", function()
            menu_elements.enable_toggle:render("Enable Script Toggle")
            menu_elements.pain_suppression_key:render("Pain Suppression Key")
        end)
    end)
end

-- Define buff IDs for checking
local buff_ids = {
    ATONEMENT = enums.buff_db.ATONEMENT,
    WEAKENED_SOUL = {6788}, -- Not in buff_db, use direct ID
    PURGE_THE_WICKED = enums.buff_db.PURGE_THE_WICKED,
    POWER_OF_THE_DARK_SIDE = enums.buff_db.POWER_OF_THE_DARK_SIDE,
    POWER_WORD_SHIELD = enums.buff_db.POWER_WORD_SHIELD,
    RAPTURE = {47536}, -- Not in buff_db, use direct ID
    POWER_INFUSION = {10060}, -- Direct ID
    SPIRIT_SHELL = {109964} -- Direct ID
}

-- Define spell data for all relevant spells:
local spell_data = {
    -- Damage spells
    purge_the_wicked = {
        id = 204197,
        name = "Purge the Wicked",
        range = 40
    },
    penance = {
        id = 47540,
        name = "Penance",
        range = 40
    },
    mind_blast = {
        id = 8092,
        name = "Mind Blast",
        range = 40
    },
    smite = {
        id = 585,
        name = "Smite",
        range = 40
    },
    shadow_word_death = {
        id = 32379,
        name = "Shadow Word: Death",
        range = 40
    },
    mind_games = {
        id = 375901,
        name = "Mind Games",
        range = 40
    },
    
    -- Healing spells
    power_word_shield = {
        id = 17,
        name = "Power Word: Shield",
        range = 40
    },
    shadow_mend = {
        id = 186263,
        name = "Shadow Mend",
        range = 40
    },
    pain_suppression = {
        id = 33206,
        name = "Pain Suppression",
        range = 40
    },
    power_word_radiance = {
        id = 194509,
        name = "Power Word: Radiance",
        range = 40
    },
    
    -- Cooldowns
    power_infusion = {
        id = 10060,
        name = "Power Infusion",
        range = 40
    },
    rapture = {
        id = 47536,
        name = "Rapture",
        range = 0
    },
    evangelism = {
        id = 246287,
        name = "Evangelism",
        range = 0
    },
    spirit_shell = {
        id = 109964,
        name = "Spirit Shell",
        range = 0
    }
}

-- Timer variables to avoid multiple calls
local last_cast_times = {
    purge_the_wicked = 0.0,
    penance = 0.0,
    mind_blast = 0.0,
    smite = 0.0,
    shadow_word_death = 0.0,
    mind_games = 0.0,
    power_word_shield = 0.0,
    shadow_mend = 0.0,
    pain_suppression = 0.0,
    power_word_radiance = 0.0,
    power_infusion = 0.0,
    rapture = 0.0,
    evangelism = 0.0,
    spirit_shell = 0.0
}

-- Ramping variables
local is_ramping = false
local ramp_start_time = 0
local ramp_phase = 0  -- 0: not ramping, 1: applying shields, 2: applying radiance, 3: evangelism
local next_big_damage_time = 0
local ramping_target_count = 0

---@param target game_object
---@return boolean
local function has_atonement(target)
    if not target or not target:is_valid() then return false end
    local atonement_data = buff_manager:get_buff_data(target, buff_ids.ATONEMENT)
    return atonement_data.is_active
end

---@param target game_object
---@return number
local function get_atonement_remaining(target)
    if not target or not target:is_valid() then return 0 end
    local atonement_data = buff_manager:get_buff_data(target, buff_ids.ATONEMENT)
    if atonement_data.is_active then
        return atonement_data.remaining
    end
    return 0
end

---@param target game_object
---@return boolean
local function needs_shield(target)
    if not target or not target:is_valid() then return false end
    
    -- Check health percentage threshold
    local health_percentage = unit_helper:get_health_percentage(target)
    return health_percentage <= (menu_elements.shield_threshold:get() / 100)
end

---@param target game_object
---@return boolean
local function needs_emergency_healing(target)
    if not target or not target:is_valid() then return false end
    
    -- Check health percentage threshold
    local health_percentage = unit_helper:get_health_percentage(target)
    return health_percentage <= (menu_elements.heal_threshold:get() / 100)
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_purge_the_wicked(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_purge_the_wicked:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.purge_the_wicked < 0.20 then
        return false
    end
    
    -- Check if the target already has the debuff
    local dot_data = buff_manager:get_debuff_data(target, buff_ids.PURGE_THE_WICKED)
    if dot_data.is_active and dot_data.remaining > 2000 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.purge_the_wicked.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.purge_the_wicked.id, target, 1, "Casting Purge the Wicked on " .. target:get_name())
    last_cast_times.purge_the_wicked = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param is_damage boolean
---@return boolean
local function cast_penance(local_player, target, is_damage)
    if not local_player or not target or not target:is_valid() then return false end
    
    if is_damage and not menu_elements.enable_penance_damage:get_state() then
        return false
    end
    
    if not is_damage and not menu_elements.enable_penance_heal:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.penance < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.penance.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Check for Power of the Dark Side buff for damage penance
    if is_damage then
        local dark_side_buff = buff_manager:get_buff_data(local_player, buff_ids.POWER_OF_THE_DARK_SIDE)
        if dark_side_buff.is_active then
            -- Prioritize using penance with Power of the Dark Side
        end
    end
    
    spell_queue:queue_spell_target(spell_data.penance.id, target, 1, 
        is_damage and "Casting Penance on " .. target:get_name() or "Healing with Penance on " .. target:get_name())
    last_cast_times.penance = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_mind_blast(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_mind_blast:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.mind_blast < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.mind_blast.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.mind_blast.id, target, 1, "Casting Mind Blast on " .. target:get_name())
    last_cast_times.mind_blast = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_smite(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_smite:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.smite < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.smite.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.smite.id, target, 1, "Casting Smite on " .. target:get_name())
    last_cast_times.smite = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_shadow_word_death(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_shadow_word_death:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.shadow_word_death < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.shadow_word_death.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Shadow Word: Death is best used as an execute
    local health_percentage = unit_helper:get_health_percentage(target)
    if health_percentage > 0.2 then  -- Only use on targets below 20% health
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.shadow_word_death.id, target, 1, "Casting Shadow Word: Death on " .. target:get_name())
    last_cast_times.shadow_word_death = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_mind_games(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_mind_games:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.mind_games < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.mind_games.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.mind_games.id, target, 1, "Casting Mind Games on " .. target:get_name())
    last_cast_times.mind_games = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_power_word_shield(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_shield:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.power_word_shield < 0.20 then
        return false
    end
    
    -- Check if target already has Weakened Soul (unless Rapture is active)
    local rapture_active = buff_manager:get_buff_data(local_player, buff_ids.RAPTURE).is_active
    if not rapture_active then
        local weakened_soul_data = buff_manager:get_debuff_data(target, buff_ids.WEAKENED_SOUL)
        if weakened_soul_data.is_active then
            return false
        end
    end
    
    -- Check if target already has shield (refresh if in Rapture)
    local shield_data = buff_manager:get_buff_data(target, buff_ids.POWER_WORD_SHIELD)
    if shield_data.is_active and not rapture_active then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.power_word_shield.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.power_word_shield.id, target, 1, "Casting Power Word: Shield on " .. target:get_name())
    last_cast_times.power_word_shield = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_shadow_mend(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_shadowmend:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.shadow_mend < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.shadow_mend.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.shadow_mend.id, target, 1, "Casting Shadow Mend on " .. target:get_name())
    last_cast_times.shadow_mend = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_pain_suppression(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_pain_suppression:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.pain_suppression < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.pain_suppression.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.pain_suppression.id, target, 1, "Casting Pain Suppression on " .. target:get_name())
    last_cast_times.pain_suppression = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_power_word_radiance(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_power_word_radiance:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.power_word_radiance < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.power_word_radiance.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    -- Radiance is an AoE heal, best used on grouped targets
    local heal_targets = target_selector:get_targets_heal()
    local targets_nearby = 0
    
    for _, nearby_target in ipairs(heal_targets) do
        if nearby_target and nearby_target:is_valid() and 
           nearby_target:get_position():dist_to(target:get_position()) <= 10 and 
           not has_atonement(nearby_target) then
            targets_nearby = targets_nearby + 1
        end
    end
    
    -- Only cast if it will hit at least 3 targets without Atonement
    if targets_nearby < 3 and not is_ramping then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.power_word_radiance.id, target, 1, "Casting Power Word: Radiance on " .. target:get_name())
    last_cast_times.power_word_radiance = time
    return true
end

---@param local_player game_object
---@param target game_object
---@return boolean
local function cast_power_infusion(local_player, target)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not menu_elements.enable_power_infusion:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.power_infusion < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.power_infusion.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.power_infusion.id, target, 1, "Casting Power Infusion on " .. target:get_name())
    last_cast_times.power_infusion = time
    return true
end

---@param local_player game_object
---@return boolean
local function cast_rapture(local_player)
    if not local_player or not local_player:is_valid() then return false end
    
    if not menu_elements.enable_rapture:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.rapture < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.rapture.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.rapture.id, local_player, 1, "Casting Rapture")
    last_cast_times.rapture = time
    return true
end

---@param local_player game_object
---@return boolean
local function cast_evangelism(local_player)
    if not local_player or not local_player:is_valid() then return false end
    
    if not menu_elements.enable_evangelism:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.evangelism < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.evangelism.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Count atonements before using
    local heal_targets = target_selector:get_targets_heal(10) -- Check up to 10 targets
    local atonement_count = 0
    
    for _, heal_target in ipairs(heal_targets) do
        if heal_target and heal_target:is_valid() and has_atonement(heal_target) then
            atonement_count = atonement_count + 1
        end
    end
    
    -- Only use if we have at least 5 atonements active (unless ramping)
    if atonement_count < 5 and not is_ramping then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.evangelism.id, local_player, 1, "Casting Evangelism")
    last_cast_times.evangelism = time
    return true
end

---@param local_player game_object
---@return boolean
local function cast_spirit_shell(local_player)
    if not local_player or not local_player:is_valid() then return false end
    
    if not menu_elements.enable_spirit_shell:get_state() then
        return false
    end
    
    local time = core.time()
    if time - last_cast_times.spirit_shell < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(spell_data.spirit_shell.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(spell_data.spirit_shell.id, local_player, 1, "Casting Spirit Shell")
    last_cast_times.spirit_shell = time
    return true
end

-- Ramping functions
local function start_ramping()
    if is_ramping then return end
    
    core.log("Starting damage ramping sequence")
    is_ramping = true
    ramp_start_time = core.time()
    ramp_phase = 1
    ramping_target_count = 0
end

local function stop_ramping()
    if not is_ramping then return end
    
    core.log("Stopping damage ramping sequence")
    is_ramping = false
    ramp_phase = 0
    ramping_target_count = 0
end

-- Check BigWigs timers for incoming damage events
local function check_bigwigs_timers()
    -- Check if BigWigs is loaded and we can access its timers
    local BigWigs = _G.BigWigs
    if not BigWigs then 
        return false 
    end
    
    local bars = nil
    
    -- Try different approaches to access BigWigs bars
    if BigWigs.bars and BigWigs.bars.GetBars then
        -- Modern BigWigs API
        bars = BigWigs.bars:GetBars()
    elseif BigWigs.db and BigWigs.db.profile and BigWigs.db.profile.bars then
        if BigWigs.db.profile.bars.messages then
            -- Alternative structure used in some versions
            bars = BigWigs.db.profile.bars.messages
        elseif type(BigWigs.db.profile.bars) == "table" then
            -- Direct access attempt
            bars = BigWigs.db.profile.bars
        end
    end
    
    -- If we couldn't find valid bars
    if not bars or type(bars) ~= "table" then
        return false
    end
    
    local ramp_threshold = menu_elements.ramp_time_before_event:get()
    
    -- Check if there's any important timer coming up
    for id, bar in pairs(bars) do
        if bar and bar.text then
            -- Look for important mechanics typically requiring a ramp
            if bar.text:find("Damage") or 
               bar.text:find("Explosion") or 
               bar.text:find("Storm") or 
               bar.text:find("Breath") or
               bar.text:find("Blast") or
               bar.text:find("Nova") or
               bar.text:find("Wave") then
                
                -- Get the remaining time - different versions store it differently
                local remaining = 0
                if bar.remaining then
                    remaining = bar.remaining
                elseif bar.expirationTime then
                    remaining = bar.expirationTime - GetTime()
                end
                
                -- If the timer is within our threshold and we're not already ramping
                if remaining > 0 and remaining <= ramp_threshold and not is_ramping then
                    next_big_damage_time = core.time() + remaining
                    start_ramping()
                    return true
                end
            end
        end
    end
    
    return false
end

-- Execute ramping logic
local function execute_ramp(local_player, heal_targets_list)
    if not is_ramping then
        return false
    end
    
    local current_time = core.time()
    local elapsed_time = current_time - ramp_start_time
    
    -- Phase 1: Apply shields to as many targets as possible
    if ramp_phase == 1 then
        -- Check if we should cast Rapture first
        if menu_elements.enable_rapture:get_state() then
            local rapture_buff = buff_manager:get_buff_data(local_player, buff_ids.RAPTURE)
            if not rapture_buff.is_active then
                if cast_rapture(local_player) then
                    return true
                end
            end
        end
        
        -- Shield as many targets as possible
        for _, target in ipairs(heal_targets_list) do
            if cast_power_word_shield(local_player, target) then
                ramping_target_count = ramping_target_count + 1
                return true
            end
        end
        
        -- If we've shielded enough targets or spent enough time, move to phase 2
        if ramping_target_count >= 5 or elapsed_time > 3.0 then
            ramp_phase = 2
            ramping_target_count = 0
            return false
        end
    -- Phase 2: Apply Radiance for group atonement spread
    elseif ramp_phase == 2 then
        -- Find best target for Radiance (most grouped allies)
        local best_target = nil
        local max_nearby = 0
        
        for _, center_target in ipairs(heal_targets_list) do
            local nearby_count = 0
            for _, nearby_target in ipairs(heal_targets_list) do
                if center_target:get_position():dist_to(nearby_target:get_position()) <= 10 then
                    nearby_count = nearby_count + 1
                end
            end
            
            if nearby_count > max_nearby then
                max_nearby = nearby_count
                best_target = center_target
            end
        end
        
        if best_target and cast_power_word_radiance(local_player, best_target) then
            ramping_target_count = ramping_target_count + 1
            
            -- If we've used 2 Radiance or spent enough time, move to phase 3
            if ramping_target_count >= 2 or elapsed_time > 6.0 then
                ramp_phase = 3
                return true
            end
            return true
        end
        
        -- If we couldn't cast Radiance but spent enough time, move to phase 3
        if elapsed_time > 6.0 then
            ramp_phase = 3
            return false
        end
    -- Phase 3: Cast Evangelism to extend Atonement
    elseif ramp_phase == 3 then
        if cast_evangelism(local_player) then
            -- Apply Spirit Shell if enabled
            if menu_elements.enable_spirit_shell:get_state() then
                cast_spirit_shell(local_player)
            end
            
            -- Use Power Infusion if enabled
            if menu_elements.enable_power_infusion:get_state() and menu_elements.power_infusion_self:get_state() then
                cast_power_infusion(local_player, local_player)
            end
            
            -- Move to damage phase
            ramp_phase = 4
            return true
        end
        
        -- If we spent too much time without casting Evangelism, move on anyway
        if elapsed_time > 8.0 then
            ramp_phase = 4
            return false
        end
    -- Phase 4: Damage phase - deal damage for atonement healing
    elseif ramp_phase == 4 then
        -- Continue damage rotation until damage event or time runs out
        if current_time >= next_big_damage_time or elapsed_time > 15.0 then
            stop_ramping()
            return false
        end
        
        -- No direct return here - will fall through to normal rotation
        -- with is_ramping still true to prioritize damage
    end
    
    return false
end

-- Complete rotation logic
local function complete_cast_logic(local_player, targets_list, heal_targets_list)
    -- Safety check for valid parameters
    if not local_player or not local_player:is_valid() then
        return false
    end
    
    if not targets_list or #targets_list == 0 then
        targets_list = {}
    end
    
    if not heal_targets_list or #heal_targets_list == 0 then
        heal_targets_list = {}
    end
    
    -- Check if we're in ramping mode - if so, execute ramp logic
    if is_ramping and execute_ramp(local_player, heal_targets_list) then
        return true
    end
    
    -- During ramping phase 4 (damage phase), we prioritize damage without stopping ramping
    local in_damage_phase = is_ramping and ramp_phase == 4
    
    -- First priority: Emergency healing when someone is critically low
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            local health_percentage = unit_helper:get_health_percentage(target)
            if health_percentage < 0.4 then -- Critical health - under 40%
                -- Use emergency cooldowns for tanks or very low health
                if health_percentage < 0.25 or unit_helper:is_tank(target) then
                    if menu_elements.enable_pain_suppression:get_state() and cast_pain_suppression(local_player, target) then
                        return true
                    end
                    
                    if unit_helper:is_tank(target) and cast_power_word_shield(local_player, target) then
                        return true
                    end
                end
                
                -- Use direct healing
                if cast_shadow_mend(local_player, target) then
                    return true
                end
                
                if cast_penance(local_player, target, false) then
                    return true
                end
            end
        end
    end
    
    -- Second priority: Atonement maintenance through shields
    -- Count how many targets have atonement
    local atonement_count = 0
    for _, target in ipairs(heal_targets_list) do
        if has_atonement(target) then
            atonement_count = atonement_count + 1
        end
    end
    
    -- Apply shields to maintain atonement (unless in damage phase)
    if not in_damage_phase and atonement_count < 3 then
        for _, target in ipairs(heal_targets_list) do
            if not has_atonement(target) then
                if cast_power_word_shield(local_player, target) then
                    return true
                end
            end
        end
    end
    
    -- Third priority: Shield tanks or targets taking damage
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            if unit_helper:get_role_id(target) == enums.group_role.TANK or needs_shield(target) then
                if not has_atonement(target) then
                    if cast_power_word_shield(local_player, target) then
                        return true
                    end
                end
            end
        end
    end
    
    -- Fourth priority: Maintain critical buffs for self
    local dark_side_buff = buff_manager:get_buff_data(local_player, buff_ids.POWER_OF_THE_DARK_SIDE)
    local power_infusion_active = buff_manager:get_buff_data(local_player, buff_ids.POWER_INFUSION)
    
    -- Use Power Infusion on keybind press
    if plugin_helper:is_keybind_enabled(menu_elements.power_infusion_key) then
        if menu_elements.power_infusion_self:get_state() then
            if cast_power_infusion(local_player, local_player) then
                return true
            end
        else
            -- Find a DPS player to buff
            for _, target in ipairs(heal_targets_list) do
                if unit_helper:get_role_id(target) == enums.group_role.DAMAGER and target:is_player() then
                    if cast_power_infusion(local_player, target) then
                        return true
                    end
                    break
                end
            end
        end
    end
    
    -- Use Spirit Shell on keybind press
    if plugin_helper:is_keybind_enabled(menu_elements.spirit_shell_key) then
        if cast_spirit_shell(local_player) then
            return true
        end
    end
    
    -- Fifth priority: DoT maintenance
    for _, target in ipairs(targets_list) do
        if target:is_in_combat() and cast_purge_the_wicked(local_player, target) then
            return true
        end
    end
    
    -- Sixth priority: Damage rotation for Atonement healing
    for _, target in ipairs(targets_list) do
        if not target:is_in_combat() then
            goto continue
        end
        
        -- Check for execute range
        local health_percentage = unit_helper:get_health_percentage(target)
        if health_percentage < 0.2 and cast_shadow_word_death(local_player, target) then
            return true
        end
        
        -- Use Mind Games if available
        if cast_mind_games(local_player, target) then
            return true
        end
        
        -- If Power of the Dark Side is active, prioritize Penance
        if dark_side_buff.is_active and cast_penance(local_player, target, true) then
            return true
        end
        
        -- Mind Blast as it's more mana efficient
        if cast_mind_blast(local_player, target) then
            return true
        end
        
        -- Regular Penance
        if cast_penance(local_player, target, true) then
            return true
        end
        
        -- Lastly, Smite as filler
        if cast_smite(local_player, target) then
            return true
        end
        
        ::continue::
    end
    
    -- If nothing else to do, shield people preemptively
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            if target and target:is_valid() and not has_atonement(target) then
                if cast_power_word_shield(local_player, target) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Target selector override
-- Set up target selector override for Discipline Priest
local is_ts_overriden = false
local function override_ts_settings()
    if is_ts_overriden then
        return
    end

    local is_override_allowed = menu_elements.ts_custom_logic_override:get_state()
    if not is_override_allowed then
        return
    end

    -- If the menu elements don't exist yet, wait until they do
    if not target_selector.menu_elements or 
       not target_selector.menu_elements.settings or 
       not target_selector.menu_elements.damage or 
       not target_selector.menu_elements.healing then
        return
    end

    -- Set safe values for range
    if target_selector.menu_elements.settings.max_range_damage then
        target_selector.menu_elements.settings.max_range_damage:set(40)
    end
    
    if target_selector.menu_elements.settings.max_range_heal then
        target_selector.menu_elements.settings.max_range_heal:set(40)
    end
    
    -- Emphasize nearby targets for damage
    if target_selector.menu_elements.damage.weight_distance then
        target_selector.menu_elements.damage.weight_distance:set(true)
    end
    
    if target_selector.menu_elements.damage.slider_weight_distance then
        target_selector.menu_elements.damage.slider_weight_distance:set(3)
    end
    
    -- Prioritize low health for healing
    if target_selector.menu_elements.healing.weight_health then
        target_selector.menu_elements.healing.weight_health:set(true)
    end
    
    if target_selector.menu_elements.healing.slider_weight_health then
        target_selector.menu_elements.healing.slider_weight_health:set(4)
    end
    
    is_ts_overriden = true
end

local function my_on_update()
    -- Control Panel Drag & Drop
    control_panel_helper:on_update(menu_elements)

    -- No local player check
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end

    -- Check if the user disabled the script
    if not menu_elements.enable_script_check:get_state() then
        return
    end

    if not plugin_helper:is_toggle_enabled(menu_elements.enable_toggle) then
        return
    end

    -- Check if currently casting or channeling
    local cast_end_time = local_player:get_active_spell_cast_end_time()
    if cast_end_time > 0.0 then
        return false
    end

    local channel_end_time = local_player:get_active_channel_cast_end_time()
    if channel_end_time > 0.0 then
        return false
    end

    -- Do not run the rotation code while mounted
    if local_player:is_mounted() then
        return
    end

    -- Override TS settings
    override_ts_settings()

    -- Get all targets from the target selector
    local targets_list = target_selector:get_targets(5) -- Get up to 5 targets
    local heal_targets_list = target_selector:get_targets_heal(5) -- Get up to 5 healing targets
    
    -- Check for ramping conditions
    if menu_elements.enable_ramping:get_state() then
        -- Check for manual ramp key press
        if plugin_helper:is_keybind_enabled(menu_elements.manual_ramp_key) and not is_ramping then
            next_big_damage_time = core.time() + 10.0  -- Assume damage in 10 seconds for manual ramp
            start_ramping()
        end
        
        -- Check for auto-ramp from BigWigs
        if menu_elements.ramp_automatically:get_state() and not is_ramping then
            check_bigwigs_timers()
        end
    end

    -- Check for Pain Suppression key press
    local is_defensive_allowed = plugin_helper:is_defensive_allowed()
    if is_defensive_allowed and plugin_helper:is_keybind_enabled(menu_elements.pain_suppression_key) then
        for _, heal_target in ipairs(heal_targets_list) do
            if cast_pain_suppression(local_player, heal_target) then
                plugin_helper:set_defensive_block_time(3.0)
                return true
            end
            break  -- Only try the first target
        end
    end

    -- Defensive logic for the player and allies
    for _, heal_target in ipairs(heal_targets_list) do
        if not heal_target or not heal_target:is_valid() then
            goto continue
        end

        -- Critical situation for tank
        if is_defensive_allowed and unit_helper:get_role_id(heal_target) == enums.group_role.TANK then
            local health_percentage = unit_helper:get_health_percentage(heal_target)
            if health_percentage < 0.4 then  -- 40% health or lower
                if cast_pain_suppression(local_player, heal_target) then
                    plugin_helper:set_defensive_block_time(3.0)
                    return true
                end
            end
        end

        -- Critical situation for any player
        if is_defensive_allowed and heal_target:is_player() then
            local health_percentage = unit_helper:get_health_percentage(heal_target)
            if health_percentage < 0.3 then  -- 30% health or lower
                if cast_pain_suppression(local_player, heal_target) then
                    plugin_helper:set_defensive_block_time(3.0)
                    return true
                end
            end
        end

        ::continue::
    end

    -- Execute the main rotation logic
    return complete_cast_logic(local_player, targets_list, heal_targets_list)
end

-- Render the "Disabled" rectangle box when script is toggled off
local function my_on_render()
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end

    if not menu_elements.enable_script_check:get_state() then
        return
    end

    if not plugin_helper:is_toggle_enabled(menu_elements.enable_toggle) then
        if menu_elements.draw_plugin_state:get_state() then
            plugin_helper:draw_text_character_center("DISABLED")
        end
        return
    end
    
    -- Load color properly
    local color_module = require("common/color")
    local color = color_module
    
    -- Display Atonement count if enabled
    if menu_elements.draw_atonement_count:get_state() then
        local heal_targets = target_selector:get_targets_heal()
        local atonement_count = 0
        for _, target in ipairs(heal_targets) do
            if has_atonement(target) then
                atonement_count = atonement_count + 1
            end
        end
        
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
    if menu_elements.draw_ramp_timer:get_state() and is_ramping then
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

local function on_control_panel_render()
    local control_panel_elements = {}
    
    -- Enable Toggle on Control Panel
    if menu_elements.enable_toggle then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Enable (" .. key_helper:get_key_name(menu_elements.enable_toggle:get_key_code()) .. ") ",
            keybind = menu_elements.enable_toggle
        })
    end
    
    -- Pain Suppression Toggle
    if menu_elements.pain_suppression_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Pain Suppression (" .. key_helper:get_key_name(menu_elements.pain_suppression_key:get_key_code()) .. ") ",
            keybind = menu_elements.pain_suppression_key
        })
    end
    
    -- Power Infusion Toggle
    if menu_elements.power_infusion_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Power Infusion (" .. key_helper:get_key_name(menu_elements.power_infusion_key:get_key_code()) .. ") ",
            keybind = menu_elements.power_infusion_key
        })
    end
    
    -- Manual Ramp Toggle
    if menu_elements.manual_ramp_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Manual Ramp (" .. key_helper:get_key_name(menu_elements.manual_ramp_key:get_key_code()) .. ") ",
            keybind = menu_elements.manual_ramp_key
        })
    end
    
    -- Spirit Shell Toggle
    if menu_elements.spirit_shell_key then
        control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = "[DiscPriest] Spirit Shell (" .. key_helper:get_key_name(menu_elements.spirit_shell_key:get_key_code()) .. ") ",
            keybind = menu_elements.spirit_shell_key
        })
    end

    return control_panel_elements
end

-- Register Callbacks
core.register_on_update_callback(my_on_update)
core.register_on_render_callback(my_on_render)
core.register_on_render_menu_callback(my_menu_render)
core.register_on_render_control_panel_callback(on_control_panel_render)

-- Return success to indicate the script loaded correctly
return true