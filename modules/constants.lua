-- Constants Module
-- This module contains spell data, buff IDs, and other constants

local enums = require("common/enums")

local constants = {}

-- Define buff IDs for checking
constants.buff_ids = {
    ATONEMENT = enums.buff_db.ATONEMENT,
    WEAKENED_SOUL = {6788}, -- Not in buff_db, use direct ID
    PURGE_THE_WICKED = enums.buff_db.PURGE_THE_WICKED,
    POWER_OF_THE_DARK_SIDE = enums.buff_db.POWER_OF_THE_DARK_SIDE,
    POWER_WORD_SHIELD = enums.buff_db.POWER_WORD_SHIELD,
    RAPTURE = {47536}, -- Not in buff_db, use direct ID
    POWER_INFUSION = {10060}, -- Direct ID
    SPIRIT_SHELL = {109964} -- Direct ID
}

-- Define spell data for all relevant spells
constants.spell_data = {
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

return constants
