-- Load after libs and before everything else

local addonName, addonTable = ...


-- ------------------------
-- Declare global variables
-- ------------------------

NeedToKnow = {}
NEEDTOKNOW = {}

-- We want to eventually be creating fewer global variables and get rid of these: 
NeedToKnowLoader = {}    -- Used by NeedToKnow.lua
NeedToKnowOptions = {}   -- Used by NeedToKnow_Options.lua
-- NeedToKnowRMB = {}    -- Used by NeedToKnow.lua, NeedToKnow_Options.lua, NeedToKnow_Options.xml
                         -- (Right-click bar config menu)

-- ----------
-- Namespaces
-- ----------

NeedToKnow.ExecutiveFrame = CreateFrame("Frame", "NeedToKnow_ExecutiveFrame")

NeedToKnow.Bar = {}
NeedToKnow.Cooldown = {}
NeedToKnow.BarGroup = {}
NeedToKnow.BarMenu = {}
NeedToKnow.ResizeButton = {}



-- ---------------------
-- Addon-wide parameters
-- ---------------------

NEEDTOKNOW.VERSION = GetAddOnMetadata(addonName, "Version")
-- to update version, change the .toc 

NEEDTOKNOW.ITEM_NAMES = {
    -- Used by NeedToKnow.lua, NeedToKnow_Options.lua
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

-- Default settings
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
    append_cd       = false,
    append_usable   = false,
}
NEEDTOKNOW.GROUP_DEFAULTS = {
    Enabled       = true,
    NumberBars    = 3,
    Scale         = 1.0,
    Width         = 270,
    Bars          = { NEEDTOKNOW.BAR_DEFAULTS, NEEDTOKNOW.BAR_DEFAULTS, NEEDTOKNOW.BAR_DEFAULTS },
    Position      = { "TOPLEFT", "TOPLEFT", 100, -100 },
    FixedDuration = 0, 
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
NEEDTOKNOW.CHARACTER_DEFAULTS = {
    Specs       = {},
    Locked      = false,
    Profiles    = {},
}
NEEDTOKNOW.DEFAULTS = {
    Version     = NEEDTOKNOW.VERSION,
    OldVersion  = NEEDTOKNOW.VERSION,
    Profiles    = {},
    Chars       = {},
}


-- -------------------
-- SharedMedia support
-- -------------------

-- LibSharedMedia library
NeedToKnow.LSM = LibStub("LibSharedMedia-3.0", true)
local barTextures = {
	["Aluminum"]   = [[Interface\Addons\NeedToKnow\Textures\Aluminum.tga]],
	["Armory"]     = [[Interface\Addons\NeedToKnow\Textures\Armory.tga]],
	["BantoBar"]   = [[Interface\Addons\NeedToKnow\Textures\BantoBar.tga]],
	["DarkBottom"] = [[Interface\Addons\NeedToKnow\Textures\Darkbottom.tga]],
	["Default"]    = [[Interface\Addons\NeedToKnow\Textures\Default.tga]],
	["Flat"]       = [[Interface\Addons\NeedToKnow\Textures\Flat.tga]],
	["Glaze"]      = [[Interface\Addons\NeedToKnow\Textures\Glaze.tga]],
	["Gloss"]      = [[Interface\Addons\NeedToKnow\Textures\Gloss.tga]],
	["Graphite"]   = [[Interface\Addons\NeedToKnow\Textures\Graphite.tga]],
	["Minimalist"] = [[Interface\Addons\NeedToKnow\Textures\Minimalist.tga]],
	["Otravi"]     = [[Interface\Addons\NeedToKnow\Textures\Otravi.tga]],
	["Smooth"]     = [[Interface\Addons\NeedToKnow\Textures\Smooth.tga]],
	["Smooth v2"]  = [[Interface\Addons\NeedToKnow\Textures\Smoothv2.tga]],
	["Striped"]    = [[Interface\Addons\NeedToKnow\Textures\Striped.tga]]
}
for k, v in pairs(barTextures) do
	NeedToKnow.LSM:Register("statusbar", k, v) 
end


-- -----------------
-- Utility functions
-- -----------------

--[[
function maybe_trace(...)
	local so_far = ""
	local p = _G
	for idx = 1, 40, 1 do
		local v = select(idx,...)
		if not v then 
			break 
		end
		p = p[v]
		if not p then
			if so_far == "" then
				trace("global variable", v, "does not exist")
			else
				trace(so_far, "does not have member", v)
			end
			return;
		end
		so_far = so_far.."."..v
	end
	trace(so_far, "=", p)
end
]]--

-- ---------------------
-- Kitjan's addon locals
-- ---------------------

-- Used by Executive Frame:
addonTable.m_last_cast = {}
addonTable.m_last_cast_head = {}
addonTable.m_last_cast_tail = {}
addonTable.m_last_guid = {}
addonTable.m_bInCombat = {}
addonTable.m_bCombatWithBoss = {}


