-- Rotation Module
-- This module handles the main combat rotation logic for Discipline Priest

local rotation = {}

-- Required modules
local enums = require("common/enums")
local unit_helper = require("common/utility/unit_helper")
local plugin_helper = require("common/utility/plugin_helper")
local buff_manager = require("common/modules/buff_manager")
local target_selector = require("common/modules/target_selector")
local spell_helper = require("common/utility/spell_helper")
local spell_queue = require("common/modules/spell_queue")

-- Local modules
local constants = require("modules/constants")
local utility = require("modules/utility")
local ramp = require("modules/ramp")

-- Target selector override
local is_ts_overriden = false

-- Setup target selector override for Discipline Priest
function rotation.override_ts_settings(menu_elements)
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

-- Check keybinds and handle specific key presses
---@param local_player game_object
---@param heal_targets_list table
---@param menu_elements table
---@return boolean
function rotation.handle_keybinds(local_player, heal_targets_list, menu_elements)
    -- Check for ramp key
    if menu_elements.enable_ramping:get_state() then
        -- Check for manual ramp key press
        if ramp.check_manual_ramp(menu_elements.manual_ramp_key) then
            return true
        end
        
        -- Check for auto-ramp from BigWigs
        if ramp.check_auto_ramp(
            menu_elements.ramp_automatically:get_state(), 
            menu_elements.ramp_time_before_event:get()
        ) then
            return true
        end
    end

    -- Check for Pain Suppression key press
    local is_defensive_allowed = plugin_helper:is_defensive_allowed()
    if is_defensive_allowed and plugin_helper:is_keybind_enabled(menu_elements.pain_suppression_key) then
        for _, heal_target in ipairs(heal_targets_list) do
            if utility.cast_pain_suppression(local_player, heal_target, menu_elements.enable_pain_suppression:get_state()) then
                plugin_helper:set_defensive_block_time(3.0)
                return true
            end
            break  -- Only try the first target
        end
    end
    
    -- Check for Power Infusion key press
    if plugin_helper:is_keybind_enabled(menu_elements.power_infusion_key) then
        if menu_elements.power_infusion_self:get_state() then
            if utility.cast_power_infusion(local_player, local_player, menu_elements.enable_power_infusion:get_state()) then
                return true
            end
        else
            -- Find a DPS player to buff
            for _, target in ipairs(heal_targets_list) do
                if unit_helper:get_role_id(target) == enums.group_role.DAMAGER and target:is_player() then
                    if utility.cast_power_infusion(local_player, target, menu_elements.enable_power_infusion:get_state()) then
                        return true
                    end
                    break
                end
            end
        end
    end
    
    -- Check for Spirit Shell key press
    if plugin_helper:is_keybind_enabled(menu_elements.spirit_shell_key) then
        if utility.cast_spirit_shell(local_player, menu_elements.enable_spirit_shell:get_state()) then
            return true
        end
    end
    
    return false
end

-- Handle emergency defensives and critical situations
---@param local_player game_object
---@param heal_targets_list table
---@param menu_elements table
---@return boolean
function rotation.handle_defensives(local_player, heal_targets_list, menu_elements)
    local is_defensive_allowed = plugin_helper:is_defensive_allowed()
    if not is_defensive_allowed then
        return false
    end

    for _, heal_target in ipairs(heal_targets_list) do
        if not heal_target or not heal_target:is_valid() then
            goto continue
        end

        -- Critical situation for tank
        if unit_helper:get_role_id(heal_target) == enums.group_role.TANK then
            local health_percentage = unit_helper:get_health_percentage(heal_target)
            if health_percentage < 0.4 then  -- 40% health or lower
                if utility.cast_pain_suppression(local_player, heal_target, menu_elements.enable_pain_suppression:get_state()) then
                    plugin_helper:set_defensive_block_time(3.0)
                    return true
                end
            end
        end

        -- Critical situation for any player
        if heal_target:is_player() then
            local health_percentage = unit_helper:get_health_percentage(heal_target)
            if health_percentage < 0.3 then  -- 30% health or lower
                if utility.cast_pain_suppression(local_player, heal_target, menu_elements.enable_pain_suppression:get_state()) then
                    plugin_helper:set_defensive_block_time(3.0)
                    return true
                end
            end
        end

        ::continue::
    end

    return false
end

-- Complete rotation logic 
---@param local_player game_object
---@param targets_list table
---@param heal_targets_list table
---@param menu_elements table
---@return boolean
function rotation.execute_rotation(local_player, targets_list, heal_targets_list, menu_elements)
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
    if ramp.is_ramping and ramp.execute_ramp(local_player, heal_targets_list, menu_elements) then
        return true
    end
    
    -- During ramping phase 4 (damage phase), we prioritize damage without stopping ramping
    local in_damage_phase = ramp.is_in_damage_phase()
    
    -- First priority: Emergency healing when someone is critically low
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            local health_percentage = unit_helper:get_health_percentage(target)
            if health_percentage < 0.4 then -- Critical health - under 40%
                -- Use emergency cooldowns for tanks or very low health
                if health_percentage < 0.25 or unit_helper:is_tank(target) then
                    if menu_elements.enable_pain_suppression:get_state() and 
                       utility.cast_pain_suppression(local_player, target, menu_elements.enable_pain_suppression:get_state()) then
                        return true
                    end
                    
                    if unit_helper:is_tank(target) and 
                       utility.cast_power_word_shield(local_player, target, menu_elements.enable_shield:get_state()) then
                        return true
                    end
                end
                
                -- Use direct healing
                if utility.cast_shadow_mend(local_player, target, menu_elements.enable_shadowmend:get_state()) then
                    return true
                end
                
                if utility.cast_penance(local_player, target, false, 
                                        menu_elements.enable_penance_damage:get_state(),
                                        menu_elements.enable_penance_heal:get_state()) then
                    return true
                end
            end
        end
    end
    
    -- Second priority: Atonement maintenance through shields
    -- Count how many targets have atonement
    local atonement_count = utility.count_atonements(heal_targets_list)
    
    -- Apply shields to maintain atonement (unless in damage phase)
    if not in_damage_phase and atonement_count < 3 then
        for _, target in ipairs(heal_targets_list) do
            if not utility.has_atonement(target) then
                if utility.cast_power_word_shield(local_player, target, menu_elements.enable_shield:get_state()) then
                    return true
                end
            end
        end
    end
    
    -- Third priority: Shield tanks or targets taking damage
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            if unit_helper:get_role_id(target) == enums.group_role.TANK or 
               utility.needs_shield(target, menu_elements.shield_threshold:get()) then
                if not utility.has_atonement(target) then
                    if utility.cast_power_word_shield(local_player, target, menu_elements.enable_shield:get_state()) then
                        return true
                    end
                end
            end
        end
    end
    
    -- Fourth priority: Maintain critical buffs for self
    local dark_side_buff = buff_manager:get_buff_data(local_player, constants.buff_ids.POWER_OF_THE_DARK_SIDE)
    
    -- Fifth priority: DoT maintenance
    for _, target in ipairs(targets_list) do
        if target:is_in_combat() and utility.cast_purge_the_wicked(
            local_player, target, menu_elements.enable_purge_the_wicked:get_state()) then
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
        if health_percentage < 0.2 and utility.cast_shadow_word_death(
            local_player, target, menu_elements.enable_shadow_word_death:get_state()) then
            return true
        end
        
        -- Use Mind Games if available
        if utility.cast_mind_games(local_player, target, menu_elements.enable_mind_games:get_state()) then
            return true
        end
        
        -- If Power of the Dark Side is active, prioritize Penance
        if dark_side_buff.is_active and utility.cast_penance(
            local_player, target, true, 
            menu_elements.enable_penance_damage:get_state(),
            menu_elements.enable_penance_heal:get_state()) then
            return true
        end
        
        -- Mind Blast as it's more mana efficient
        if utility.cast_mind_blast(local_player, target, menu_elements.enable_mind_blast:get_state()) then
            return true
        end
        
        -- Regular Penance
        if utility.cast_penance(
            local_player, target, true, 
            menu_elements.enable_penance_damage:get_state(),
            menu_elements.enable_penance_heal:get_state()) then
            return true
        end
        
        -- Lastly, Smite as filler
        if utility.cast_smite(local_player, target, menu_elements.enable_smite:get_state()) then
            return true
        end
        
        ::continue::
    end
    
    -- If nothing else to do, shield people preemptively
    if not in_damage_phase then
        for _, target in ipairs(heal_targets_list) do
            if target and target:is_valid() and not utility.has_atonement(target) then
                if utility.cast_power_word_shield(local_player, target, menu_elements.enable_shield:get_state()) then
                    return true
                end
            end
        end
    end
    
    return false
end

return rotation
