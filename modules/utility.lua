-- Utility Module
-- This module contains utility functions for the Discipline Priest rotation

local utility = {}

-- Required modules
local unit_helper = require("common/utility/unit_helper")
local buff_manager = require("common/modules/buff_manager")
local constants = require("modules/constants")
local spell_helper = require("common/utility/spell_helper")
local spell_queue = require("common/modules/spell_queue")

-- Timer variables to avoid multiple calls
utility.last_cast_times = {
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

---@param target game_object
---@return boolean
function utility.has_atonement(target)
    if not target or not target:is_valid() then return false end
    local atonement_data = buff_manager:get_buff_data(target, constants.buff_ids.ATONEMENT)
    return atonement_data.is_active
end

---@param target game_object
---@return number
function utility.get_atonement_remaining(target)
    if not target or not target:is_valid() then return 0 end
    local atonement_data = buff_manager:get_buff_data(target, constants.buff_ids.ATONEMENT)
    if atonement_data.is_active then
        return atonement_data.remaining
    end
    return 0
end

---@param target game_object
---@param shield_threshold number
---@return boolean
function utility.needs_shield(target, shield_threshold)
    if not target or not target:is_valid() then return false end
    
    -- Check health percentage threshold
    local health_percentage = unit_helper:get_health_percentage(target)
    return health_percentage <= (shield_threshold / 100)
end

---@param target game_object
---@param heal_threshold number
---@return boolean
function utility.needs_emergency_healing(target, heal_threshold)
    if not target or not target:is_valid() then return false end
    
    -- Check health percentage threshold
    local health_percentage = unit_helper:get_health_percentage(target)
    return health_percentage <= (heal_threshold / 100)
end

---@param heal_targets_list table
---@return number
function utility.count_atonements(heal_targets_list)
    local count = 0
    for _, target in ipairs(heal_targets_list) do
        if utility.has_atonement(target) then
            count = count + 1
        end
    end
    return count
end

-- Check BigWigs timers for incoming damage events
function utility.check_bigwigs_timers(ramp_threshold)
    -- Check if BigWigs is loaded and we can access its timers
    local BigWigs = _G.BigWigs
    if not BigWigs then 
        return false, nil
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
        return false, nil
    end
    
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
                
                -- If the timer is within our threshold
                if remaining > 0 and remaining <= ramp_threshold then
                    local next_damage_time = core.time() + remaining
                    return true, next_damage_time
                end
            end
        end
    end
    
    return false, nil
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_purge_the_wicked(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.purge_the_wicked < 0.20 then
        return false
    end
    
    -- Check if the target already has the debuff
    local dot_data = buff_manager:get_debuff_data(target, constants.buff_ids.PURGE_THE_WICKED)
    if dot_data.is_active and dot_data.remaining > 2000 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.purge_the_wicked.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.purge_the_wicked.id, target, 1, "Casting Purge the Wicked on " .. target:get_name())
    utility.last_cast_times.purge_the_wicked = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param is_damage boolean
---@param enable_damage boolean
---@param enable_heal boolean
---@return boolean
function utility.cast_penance(local_player, target, is_damage, enable_damage, enable_heal)
    if not local_player or not target or not target:is_valid() then return false end
    
    if is_damage and not enable_damage then
        return false
    end
    
    if not is_damage and not enable_heal then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.penance < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.penance.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Check for Power of the Dark Side buff for damage penance
    if is_damage then
        local dark_side_buff = buff_manager:get_buff_data(local_player, constants.buff_ids.POWER_OF_THE_DARK_SIDE)
        if dark_side_buff.is_active then
            -- Prioritize using penance with Power of the Dark Side
        end
    end
    
    spell_queue:queue_spell_target(constants.spell_data.penance.id, target, 1, 
        is_damage and "Casting Penance on " .. target:get_name() or "Healing with Penance on " .. target:get_name())
    utility.last_cast_times.penance = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_mind_blast(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.mind_blast < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.mind_blast.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.mind_blast.id, target, 1, "Casting Mind Blast on " .. target:get_name())
    utility.last_cast_times.mind_blast = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_smite(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.smite < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.smite.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.smite.id, target, 1, "Casting Smite on " .. target:get_name())
    utility.last_cast_times.smite = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_shadow_word_death(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.shadow_word_death < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.shadow_word_death.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Shadow Word: Death is best used as an execute
    local health_percentage = unit_helper:get_health_percentage(target)
    if health_percentage > 0.2 then  -- Only use on targets below 20% health
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.shadow_word_death.id, target, 1, "Casting Shadow Word: Death on " .. target:get_name())
    utility.last_cast_times.shadow_word_death = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_mind_games(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.mind_games < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.mind_games.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.mind_games.id, target, 1, "Casting Mind Games on " .. target:get_name())
    utility.last_cast_times.mind_games = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_power_word_shield(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.power_word_shield < 0.20 then
        return false
    end
    
    -- Check if target already has Weakened Soul (unless Rapture is active)
    local rapture_active = buff_manager:get_buff_data(local_player, constants.buff_ids.RAPTURE).is_active
    if not rapture_active then
        local weakened_soul_data = buff_manager:get_debuff_data(target, constants.buff_ids.WEAKENED_SOUL)
        if weakened_soul_data.is_active then
            return false
        end
    end
    
    -- Check if target already has shield (refresh if in Rapture)
    local shield_data = buff_manager:get_buff_data(target, constants.buff_ids.POWER_WORD_SHIELD)
    if shield_data.is_active and not rapture_active then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.power_word_shield.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.power_word_shield.id, target, 1, "Casting Power Word: Shield on " .. target:get_name())
    utility.last_cast_times.power_word_shield = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_shadow_mend(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.shadow_mend < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.shadow_mend.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.shadow_mend.id, target, 1, "Casting Shadow Mend on " .. target:get_name())
    utility.last_cast_times.shadow_mend = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_pain_suppression(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.pain_suppression < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.pain_suppression.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.pain_suppression.id, target, 1, "Casting Pain Suppression on " .. target:get_name())
    utility.last_cast_times.pain_suppression = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@param heal_targets table
---@param is_ramping boolean
---@return boolean
function utility.cast_power_word_radiance(local_player, target, enable_spell, heal_targets, is_ramping)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.power_word_radiance < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.power_word_radiance.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Don't cast if we are moving
    if local_player:is_moving() then
        return false
    end
    
    -- Radiance is an AoE heal, best used on grouped targets
    local targets_nearby = 0
    
    for _, nearby_target in ipairs(heal_targets) do
        if nearby_target and nearby_target:is_valid() and 
           nearby_target:get_position():dist_to(target:get_position()) <= 10 and 
           not utility.has_atonement(nearby_target) then
            targets_nearby = targets_nearby + 1
        end
    end
    
    -- Only cast if it will hit at least 3 targets without Atonement
    if targets_nearby < 3 and not is_ramping then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.power_word_radiance.id, target, 1, "Casting Power Word: Radiance on " .. target:get_name())
    utility.last_cast_times.power_word_radiance = time
    return true
end

---@param local_player game_object
---@param target game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_power_infusion(local_player, target, enable_spell)
    if not local_player or not target or not target:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.power_infusion < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.power_infusion.id, local_player, target, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.power_infusion.id, target, 1, "Casting Power Infusion on " .. target:get_name())
    utility.last_cast_times.power_infusion = time
    return true
end

---@param local_player game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_rapture(local_player, enable_spell)
    if not local_player or not local_player:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.rapture < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.rapture.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.rapture.id, local_player, 1, "Casting Rapture")
    utility.last_cast_times.rapture = time
    return true
end

---@param local_player game_object
---@param enable_spell boolean
---@param heal_targets table
---@param is_ramping boolean
---@return boolean
function utility.cast_evangelism(local_player, enable_spell, heal_targets, is_ramping)
    if not local_player or not local_player:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.evangelism < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.evangelism.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    -- Count atonements before using
    local atonement_count = 0
    
    for _, heal_target in ipairs(heal_targets) do
        if heal_target and heal_target:is_valid() and utility.has_atonement(heal_target) then
            atonement_count = atonement_count + 1
        end
    end
    
    -- Only use if we have at least 5 atonements active (unless ramping)
    if atonement_count < 5 and not is_ramping then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.evangelism.id, local_player, 1, "Casting Evangelism")
    utility.last_cast_times.evangelism = time
    return true
end

---@param local_player game_object
---@param enable_spell boolean
---@return boolean
function utility.cast_spirit_shell(local_player, enable_spell)
    if not local_player or not local_player:is_valid() then return false end
    
    if not enable_spell then
        return false
    end
    
    local time = core.time()
    if time - utility.last_cast_times.spirit_shell < 0.20 then
        return false
    end
    
    -- Check if spell is castable
    local is_spell_ready = spell_helper:is_spell_castable(constants.spell_data.spirit_shell.id, local_player, local_player, false, false)
    if not is_spell_ready then
        return false
    end
    
    spell_queue:queue_spell_target(constants.spell_data.spirit_shell.id, local_player, 1, "Casting Spirit Shell")
    utility.last_cast_times.spirit_shell = time
    return true
end

return utility
