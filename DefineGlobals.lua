-- This is a temporary file to help separate the code into 
-- organized, semantically meaning chunks with their own .lua file. 
-- Must be loaded first in .toc file.  

local addonName, addonTable = ...
-- Ideally we want to eventually be creating NO global variables, 
-- and only use the table passed by the client to each addon. 


-- ---------------------
-- Declare addon globals
-- ---------------------

NEEDTOKNOW = {}
NeedToKnow = {}

-- For NeedToKnow.lua: 
NeedToKnowLoader = {}
NeedToKnow_Visible = {}

-- For NeedToKnow_Options.lua: 
NeedToKnowOptions = {}
NeedToKnowRMB = {}  -- Right-click bar config menu

NeedToKnowIE = {}  -- Used by ImportExport.lua and NeedToKnow_Options.lua


-- --------------------
-- Define global values
-- --------------------

NEEDTOKNOW.VERSION = GetAddOnMetadata(addonName, "Version")
-- to update version, just change the .toc 

NEEDTOKNOW.ITEM_NAMES = {
    -- Seems like this should already exist somewhere
    -- Strings come from the chart on http://www.wowwiki.com/WoW_constants
    HEADSLOT,
    NECKSLOT,
    SHOULDERSLOT,
    SHIRTSLOT,
    CHESTSLOT,
    WAISTSLOT,
    LEGSSLOT,
    FEETSLOT,
    WRISTSLOT,
    HANDSSLOT,
    FINGER0SLOT_UNIQUE,
    FINGER1SLOT_UNIQUE,
    TRINKET0SLOT_UNIQUE,
    TRINKET1SLOT_UNIQUE,
    BACKSLOT,
    MAINHANDSLOT,
    SECONDARYHANDSLOT,
    RANGEDSLOT.."/"..RELICSLOT,
    TABARDSLOT
};

-- ----------------
-- Default settings
-- ----------------

NEEDTOKNOW.BAR_DEFAULTS = {
    Enabled         = true,
    AuraName        = "",
    Unit            = "player",
    BuffOrDebuff    = "HELPFUL",
    OnlyMine        = true,
    BarColor        = { r=0.6, g=0.6, b=0.6, a=1.0 },
    MissingBlink    = { r=0.9, g=0.1, b=0.1, a=0.5 },
    TimeFormat      = "Fmt_SingleUnit",
    vct_enabled     = false,
    vct_color       = { r=0.6, g=0.6, b=0.0, a=0.3 },
    vct_spell       = "",
    vct_extra       = 0,
    bDetectExtends  = false,
    show_text       = true,
    show_count      = true,
    show_time       = true,
    show_spark      = true,
    show_icon       = false,
    show_mypip      = false,
    show_all_stacks = false,
    show_charges    = true,
    show_ttn1       = false,
    show_ttn2       = false,
    show_ttn3       = false,
    show_text_user  = "",
    blink_enabled   = false,
    blink_ooc       = true,
    blink_boss      = false,
    blink_label     = "",
    buffcd_duration = 0,
    buffcd_reset_spells = "",
    usable_duration = 0,
    append_cd       = true,
    append_usable   = false,
}
NEEDTOKNOW.GROUP_DEFAULTS = {
    Enabled          = true,
    NumberBars       = 3,
    Scale            = 1.0,
    Width            = 270,
    Bars             = { NEEDTOKNOW.BAR_DEFAULTS, NEEDTOKNOW.BAR_DEFAULTS, NEEDTOKNOW.BAR_DEFAULTS },
    Position         = { "TOPLEFT", "TOPLEFT", 100, -100 },
    FixedDuration    = 0, 
}
NEEDTOKNOW.DEFAULTS = {
    Version     = NEEDTOKNOW.VERSION,
    OldVersion  = NEEDTOKNOW.VERSION,
    Profiles    = {},
    Chars       = {},
}
NEEDTOKNOW.CHARACTER_DEFAULTS = {
    Specs       = {},
    Locked      = false,
    Profiles    = {},
}
NEEDTOKNOW.PROFILE_DEFAULTS = {
    name        = "Default",
    nGroups     = 1,
    Groups      = { NEEDTOKNOW.GROUP_DEFAULTS },
    BarTexture  = "BantoBar",
    BarFont     = "Fritz Quadrata TT",
    BkgdColor   = { 0, 0, 0, 0.8 },
    BarSpacing  = 3,
    BarPadding  = 3,
    FontSize    = 12,
    FontOutline = 0,
}


