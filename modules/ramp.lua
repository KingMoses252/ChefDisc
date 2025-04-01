-- Ramp Module
-- This module handles damage ramping functionality for Discipline Priest rotation

local ramp = {}

-- Required modules
local utility = require("modules/utility")
local target_selector = require("common/modules/target_selector")
local plugin_helper = require("common/utility/plugin_helper")

-- Ramping variables
ramp.is_ramping = false
ramp.ramp_start_time = 0
ramp.ramp_phase = 0  -- 0: not ramping, 1: applying shields, 2: applying radiance, 3: evangelism, 4: damage
ramp.next_big_damage_time = 0
ramp.ramping_target_count = 0

-- Start ramping sequence
function ramp.start_ramping()
    if ramp.is_ramping then return end
    
    core.log("Starting damage ramping sequence")
    ramp.is_ramping = true
    ramp.ramp_start_time = core.time()
    ramp.ramp_phase = 1
    ramp.ramping_target_count = 0
end

-- Stop ramping sequence
function ramp.stop_ramping()
    if not ramp.is_ramping then return end
    
    core.log("Stopping damage ramping sequence")
    ramp.is_ramping = false
    ramp.ramp_phase = 0
    ramp.ramping_target_count = 0
end

-- Check for automatic ramping based on BigWigs timers
---@param ramp_automatically boolean
---@param ramp_threshold number
---@return boolean
function ramp.check_auto_ramp(ramp_automatically, ramp_threshold)
    if not ramp_automatically or ramp.is_ramping then
        return false
    end
    
    local should_ramp, next_damage_time = utility.check_bigwigs_timers(ramp_threshold)
    if should_ramp and next_damage_time then
        ramp.next_big_damage_time = next_damage_time
        ramp.start_ramping()
        return true
    end
    
    return false
end

-- Check for manual ramp key press
---@param manual_ramp_key table
---@return boolean
function ramp.check_manual_ramp(manual_ramp_key)
    if ramp.is_ramping then
        return false
    end
    
    if plugin_helper:is_keybind_enabled(manual_ramp_key) then
        ramp.next_big_damage_time = core.time() + 10.0  -- Assume damage in 10 seconds for manual ramp
        ramp.start_ramping()
        return true
    end
    
    return false
end

-- Execute ramping logic based on current phase
---@param local_player game_object
---@param heal_targets_list table
---@param menu_elements table
---@return boolean
function ramp.execute_ramp(local_player, heal_targets_list, menu_elements)
    if not ramp.is_ramping then
        return false
    end
    
    local current_time = core.time()
    local elapsed_time = current_time - ramp.ramp_start_time
    
    -- Phase 1: Apply shields to as many targets as possible
    if ramp.ramp_phase == 1 then
        -- Check if we should cast Rapture first
        if menu_elements.enable_rapture:get_state() then
            local rapture_active = utility.cast_rapture(local_player, menu_elements.enable_rapture:get_state())
            if rapture_active then
                return true
            end
        end
        
        -- Shield as many targets as possible
        for _, target in ipairs(heal_targets_list) do
            if utility.cast_power_word_shield(local_player, target, menu_elements.enable_shield:get_state()) then
                ramp.ramping_target_count = ramp.ramping_target_count + 1
                return true
            end
        end
        
        -- If we've shielded enough targets or spent enough time, move to phase 2
        if ramp.ramping_target_count >= 5 or elapsed_time > 3.0 then
            ramp.ramp_phase = 2
            ramp.ramping_target_count = 0
            return false
        end
    
    -- Phase 2: Apply Radiance for group atonement spread
    elseif ramp.ramp_phase == 2 then
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
        
        if best_target and utility.cast_power_word_radiance(
            local_player, 
            best_target, 
            menu_elements.enable_power_word_radiance:get_state(),
            heal_targets_list,
            true) then
            ramp.ramping_target_count = ramp.ramping_target_count + 1
            
            -- If we've used 2 Radiance or spent enough time, move to phase 3
            if ramp.ramping_target_count >= 2 or elapsed_time > 6.0 then
                ramp.ramp_phase = 3
                return true
            end
            return true
        end
        
        -- If we couldn't cast Radiance but spent enough time, move to phase 3
        if elapsed_time > 6.0 then
            ramp.ramp_phase = 3
            return false
        end
    
    -- Phase 3: Cast Evangelism to extend Atonement
    elseif ramp.ramp_phase == 3 then
        if utility.cast_evangelism(local_player, 
                                  menu_elements.enable_evangelism:get_state(),
                                  heal_targets_list,
                                  true) then
            -- Apply Spirit Shell if enabled
            if menu_elements.enable_spirit_shell:get_state() then
                utility.cast_spirit_shell(local_player, menu_elements.enable_spirit_shell:get_state())
            end
            
            -- Use Power Infusion if enabled
            if menu_elements.enable_power_infusion:get_state() and menu_elements.power_infusion_self:get_state() then
                utility.cast_power_infusion(local_player, local_player, menu_elements.enable_power_infusion:get_state())
            end
            
            -- Move to damage phase
            ramp.ramp_phase = 4
            return true
        end
        
        -- If we spent too much time without casting Evangelism, move on anyway
        if elapsed_time > 8.0 then
            ramp.ramp_phase = 4
            return false
        end
    
    -- Phase 4: Damage phase - deal damage for atonement healing
    elseif ramp.ramp_phase == 4 then
        -- Continue damage rotation until damage event or time runs out
        if current_time >= ramp.next_big_damage_time or elapsed_time > 15.0 then
            ramp.stop_ramping()
            return false
        end
        
        -- No direct return here - will fall through to normal rotation
        -- with is_ramping still true to prioritize damage
    end
    
    return false
end

-- Check if we're in the damage phase of ramping
function ramp.is_in_damage_phase()
    return ramp.is_ramping and ramp.ramp_phase == 4
end

return ramp
