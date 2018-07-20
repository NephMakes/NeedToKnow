-- ----------------------
-- NeedToKnow
-- by Kitjan, lieandswell
-- ----------------------

local trace = print
--function maybe_trace(...)
  --local so_far = ""
  --local p = _G
  --for idx = 1,40,1 do
      --local v = select(idx,...)
      --if not v then 
        --break 
      --end
      --p = p[v]
      --if not p then
        --if so_far == "" then
          --trace("global variable",v,"does not exist")
        --else
          --trace(so_far,"does not have member",v)
        --end
        --return;
      --end
      --so_far = so_far .. "." .. v
  --end
  --trace(so_far,"=",p)
--end
--
-- -------------
-- ADDON GLOBALS
-- -------------

NeedToKnow = {}
NeedToKnowLoader = {}

-- -------------
-- ADDON MEMBERS
-- -------------
local g_GetActiveTalentGroup = _G.GetSpecialization
local g_UnitAffectingCombat = UnitAffectingCombat
local g_UnitIsFriend = UnitIsFriend
local g_UnitGUID = UnitGUID
local g_GetTime = GetTime
local g_GetSpellBookItemInfo = GetSpellBookItemInfo
local g_GetSpellTabInfo = GetSpellTabInfo
local g_GetNumSpellTabs = GetNumSpellTabs
local g_GetNumSpecializations = GetNumSpecializations
local g_GetSpecializationSpells = GetSpecializationSpells
local g_GetSpellInfo = GetSpellInfo
local g_GetSpellPowerCost = GetSpellPowerCost

local m_last_guid, m_last_cast, m_last_sent, m_last_cast_head, m_last_cast_tail
local m_bInCombat, m_bCombatWithBoss

local mfn_Bar_AuraCheck
local mfn_EnergyBar_OnUpdate
local mfn_AuraCheck_Single
local mfn_AuraCheck_TOTEM
local mfn_AuraCheck_BUFFCD
local mfn_AuraCheck_USABLE
local mfn_AuraCheck_EQUIPSLOT
local mfn_AuraCheck_POWER
local mfn_AuraCheck_CASTCD
local mfn_AuraCheck_AllStacks
local mfn_GetUnresolvedCooldown
local mfn_GetAutoShotCooldown
local mfn_GetSpellChargesCooldown
local mfn_GetSpellCooldown
local mfn_AddInstanceToStacks
local mfn_SetStatusBarValue
local mfn_ResetScratchStacks
local mfn_UpdateVCT

local m_scratch = {}
m_scratch.all_stacks = 
    {
        min = 
        {
            buffName = "", 
            duration = 0, 
            expirationTime = 0, 
            iconPath = "",
            caster = ""
        },
        max = 
        {
            duration = 0, 
            expirationTime = 0, 
        },
        total = 0,
        total_ttn = { 0, 0, 0 }
    }
m_scratch.buff_stacks = 
    {
        min = 
        {
            buffName = "", 
            duration = 0, 
            expirationTime = 0, 
            iconPath = "",
            caster = ""
        },
        max = 
        {
            duration = 0, 
            expirationTime = 0, 
        },
        total = 0,
        total_ttn = { 0, 0, 0 }
    }
m_scratch.bar_entry = 
    {
        idxName = 0,
        barSpell = "",
        isSpellID = false,
    }
-- NEEDTOKNOW = {} is defined in the localization file, which must be loaded before this file

NEEDTOKNOW.VERSION = "4.0.28"

local c_UPDATE_INTERVAL = 0.05
local c_MAXBARS = 20

-- Get the localized name of spell 75, which is "Auto Shot" in US English
local c_AUTO_SHOT_NAME = g_GetSpellInfo(75)


-- COMBAT_LOG_EVENT_UNFILTERED events where select(6,...) is the caster, 9 is the spellid, and 10 is the spell name
-- (used for Target-of-target monitoring)
local c_AURAEVENTS = {
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true
}
    
    
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
    Version       = NEEDTOKNOW.VERSION,
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

NEEDTOKNOW.SHORTENINGS= {
    Enabled         = "On",
    AuraName        = "Aura",
    --Unit            = "Unit",
    BuffOrDebuff    = "Typ",
    OnlyMine        = "Min",
    BarColor        = "Clr",
    MissingBlink    = "BCl",
    TimeFormat      = "TF",
    vct_enabled     = "VOn",
    vct_color       = "VCl",
    vct_spell       = "VSp",
    vct_extra       = "VEx",
    bDetectExtends  = "Ext",
    show_text       = "sTx",
    show_count      = "sCt",
    show_time       = "sTm",
    show_spark      = "sSp",
    show_icon       = "sIc",
    show_mypip      = "sPp",
    show_all_stacks = "All",
    show_charges    = "Chg",
    show_text_user  = "sUr",
    show_ttn1       = "sN1",
    show_ttn2       = "sN2",
    show_ttn3       = "sN3",
    blink_enabled   = "BOn",
    blink_ooc       = "BOC",
    blink_boss      = "BBs",
    blink_label     = "BTx",
    buffcd_duration = "cdd",
    buffcd_reset_spells = "cdr",
    usable_duration = "udr",
    append_cd       = "acd",
    append_usable   = "aus",
    --NumberBars       = "NmB",
    --Scale            = "Scl",
    --Width            = "Cx",
    --Bars             = "Brs",
    --Position         = "Pos",
    --FixedDuration    = "FxD", 
    --Version       = "Ver",
    --OldVersion  = "OVr",
    --Profiles    = "Pfl",
    --Chars       = "Chr",
    --Specs       = "Spc",
    --Locked      = "Lck",
    --name        = "nam",
    --nGroups     = "nGr",
    --Groups      = "Grp",
    --BarTexture  = "Tex",
    --BarFont     = "Fnt",
    --BkgdColor   = "BgC",
    --BarSpacing  = "BSp",
    --BarPadding  = "BPd",
    --FontSize    = "FSz",
    --FontOutline = "FOl",
}

NEEDTOKNOW.LENGTHENINGS= {
   On = "Enabled",
   Aura = "AuraName",
--   Unit = "Unit",
   Typ = "BuffOrDebuff",
   Min = "OnlyMine",
   Clr = "BarColor",
   BCl = "MissingBlink",
   TF  = "TimeFormat",
   VOn = "vct_enabled",
   VCl = "vct_color",
   VSp = "vct_spell",
   VEx = "vct_extra",
   Ext = "bDetectExtends",
   sTx = "show_text",
   sCt = "show_count",
   sN1 = "show_ttn1",
   sN2 = "show_ttn2",
   sN3 = "show_ttn3",
   sTm = "show_time",
   sSp = "show_spark",
   sIc = "show_icon",
   sPp = "show_mypip",
   All = "show_all_stacks",
   Chg = "show_charges",
   sUr = "show_text_user",
   BOn = "blink_enabled",
   BOC = "blink_ooc",
   BBs = "blink_boss",
   BTx = "blink_label",
   cdd = "buffcd_duration",
   cdr = "buffcd_reset_spells",
   udr = "usable_duration",
   acd = "append_cd",
   aus = "append_usable",
    --NumberBars       = "NmB",
    --Scale            = "Scl",
    --Width            = "Cx",
    --Bars             = "Brs",
    --Position         = "Pos",
    --FixedDuration    = "FxD", 
    --Version       = "Ver",
    --OldVersion  = "OVr",
    --Profiles    = "Pfl",
    --Chars       = "Chr",
    --Specs       = "Spc",
    --Locked      = "Lck",
    --name can't be compressed since it's used even when not the active profile
    --nGroups     = "nGr",
    --Groups      = "Grp",
    --BarTexture  = "Tex",
    --BarFont     = "Fnt",
    --BkgdColor   = "BgC",
    --BarSpacing  = "BSp",
    --BarPadding  = "BPd",
    --FontSize    = "FSz",
    --FontOutline = "FOl";
}

-- -------------------
-- SharedMedia Support
-- -------------------

    NeedToKnow.LSM = LibStub("LibSharedMedia-3.0", true)
    
    if not NeedToKnow.LSM:Fetch("statusbar", "Aluminum", true) then NeedToKnow.LSM:Register("statusbar", "Aluminum",           [[Interface\Addons\NeedToKnow\Textures\Aluminum.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Armory", true) then NeedToKnow.LSM:Register("statusbar", "Armory",             [[Interface\Addons\NeedToKnow\Textures\Armory.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "BantoBar", true) then NeedToKnow.LSM:Register("statusbar", "BantoBar",           [[Interface\Addons\NeedToKnow\Textures\BantoBar.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "DarkBottom", true) then NeedToKnow.LSM:Register("statusbar", "DarkBottom",         [[Interface\Addons\NeedToKnow\Textures\Darkbottom.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Default", true) then NeedToKnow.LSM:Register("statusbar", "Default",            [[Interface\Addons\NeedToKnow\Textures\Default.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Flat", true) then NeedToKnow.LSM:Register("statusbar", "Flat",               [[Interface\Addons\NeedToKnow\Textures\Flat.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Glaze", true) then NeedToKnow.LSM:Register("statusbar", "Glaze",              [[Interface\Addons\NeedToKnow\Textures\Glaze.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Gloss", true) then NeedToKnow.LSM:Register("statusbar", "Gloss",              [[Interface\Addons\NeedToKnow\Textures\Gloss.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Graphite", true) then NeedToKnow.LSM:Register("statusbar", "Graphite",           [[Interface\Addons\NeedToKnow\Textures\Graphite.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Minimalist", true) then NeedToKnow.LSM:Register("statusbar", "Minimalist",         [[Interface\Addons\NeedToKnow\Textures\Minimalist.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Otravi", true) then NeedToKnow.LSM:Register("statusbar", "Otravi",             [[Interface\Addons\NeedToKnow\Textures\Otravi.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Smooth", true) then NeedToKnow.LSM:Register("statusbar", "Smooth",             [[Interface\Addons\NeedToKnow\Textures\Smooth.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Smooth v2", true) then NeedToKnow.LSM:Register("statusbar", "Smooth v2",          [[Interface\Addons\NeedToKnow\Textures\Smoothv2.tga]]) end
    if not NeedToKnow.LSM:Fetch("statusbar", "Striped", true) then NeedToKnow.LSM:Register("statusbar", "Striped",            [[Interface\Addons\NeedToKnow\Textures\Striped.tga]]) end

-- ---------------
-- EXECUTIVE FRAME
-- ---------------

function NeedToKnow.ExecutiveFrame_OnEvent(self, event, ...)
    local fnName = "ExecutiveFrame_"..event
    local fn = NeedToKnow[fnName]
    if ( fn ) then
        fn(...)
    end
end

-- function NeedToKnow.ExecutiveFrame_UNIT_SPELLCAST_SENT(unit, spell, rank_str, tgt, serialno)
function NeedToKnow.ExecutiveFrame_UNIT_SPELLCAST_SENT(unit, tgt, lineID, spellID)
    if unit == "player" then
        -- TODO: I hate to pay this memory cost for every "spell" ever cast.
        --       Would be nice to at least garbage collect this data at some point, but that
        --       may add more overhead than just keeping track of 100 spells.
        if not m_last_sent then
            m_last_sent = {}
        end
        m_last_sent[spellID] = g_GetTime()

        -- How expensive a second check do we need?
        if ( m_last_guid[spellID] or NeedToKnow.BarsForPSS ) then
            local r = m_last_cast[m_last_cast_tail]
            if not r then
                r = { spellID=spellID, target=tgt, lineID=lineID }
                m_last_cast[m_last_cast_tail] = r
            else
                r.spellID = spellID
                r.target = tgt
                r.lineID = lineID
            end
            m_last_cast_tail = m_last_cast_tail + 1
            if ( m_last_cast_tail == 2 ) then
                m_last_cast_head = 1
                if ( m_last_guid[spellID] ) then
                    NeedToKnow_ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                    NeedToKnow_ExecutiveFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                else
                    NeedToKnow_ExecutiveFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                end
            end
        end
    end
end


-- function NeedToKnow.ExecutiveFrame_UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank_str, serialno, spellid)
function NeedToKnow.ExecutiveFrame_UNIT_SPELLCAST_SUCCEEDED(unit, target, lineID, spellID)
	-- Patch 8.0 UNIT_SPELLCAST_SUCCEEDED no longers provides spell name and rank 
    if unit == "player" then
        local found
        local t = m_last_cast
        local last = m_last_cast_tail-1
        local i
        for i = last,m_last_cast_head,-1  do
            if t[i].spellID == spellID and t[i].serial == serialno then
                found = i
                break
            end
        end

        if found then
            if ( NeedToKnow.BarsForPSS ) then
                local bar,one, spellName
                for bar,one in pairs(NeedToKnow.BarsForPSS) do
                    local unitTarget = NeedToKnow.raid_members[t[found].target or ""]
                    NeedToKnow.Bar_OnEvent(bar, "PLAYER_SPELLCAST_SUCCEEDED", "player", spellName, spellID, unitTarget);
                end
            end

            if ( found == last ) then
                m_last_cast_tail = 1
                m_last_cast_head = 1
                NeedToKnow_ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            else
                m_last_cast_head = found+1
            end
        end
    end
end

-- function NeedToKnow.ExecutiveFrame_COMBAT_LOG_EVENT_UNFILTERED(tod, event, hideCaster, guidCaster, ...)
function NeedToKnow.ExecutiveFrame_COMBAT_LOG_EVENT_UNFILTERED()

    local tod, event, hideCaster, guidCaster, sourceName, sourceFlags, sourceRaidFlags, guidTarget, nameTarget, _, _, spellid, spell = CombatLogGetCurrentEventInfo()

    -- the time that's passed in appears to be time of day, not game time like everything else.
    local time = g_GetTime() 
    -- TODO: Is checking r.state sufficient or must event be checked instead?
    if ( guidCaster == NeedToKnow.guidPlayer and event=="SPELL_CAST_SUCCESS") then
        -- local guidTarget, nameTarget, _, _, spellid, spell = select(4, ...) -- source_name, source_flags, source_flags2, 

        local found
        local t = m_last_cast
        local last = m_last_cast_tail-1
        local i
        for i = last,m_last_cast_head,-1  do
            if t[i].spell == spell then
                found = i
                break
            end
        end
        if found then
            if ( NeedToKnow.BarsForPSS ) then
                local bar,one
                for bar,one in pairs(NeedToKnow.BarsForPSS) do
                    local unitTarget = NeedToKnow.raid_members[t[found].target or ""]
                    NeedToKnow.Bar_OnEvent(bar, "PLAYER_SPELLCAST_SUCCEEDED", "player", spell, spellid, unitTarget);
                end
            end

            local rBySpell = m_last_guid[spell]
            if ( rBySpell ) then
                local rByGuid = rBySpell[guidTarget]
                if not rByGuid then
                    rByGuid = { time=time, dur=0, expiry=0 }
                    rBySpell[guidTarget] = rByGuid
                else
                    rByGuid.time= time
                    rByGuid.dur = 0
                    rByGuid.expiry = 0
                end
            end

            if ( found == last ) then
                m_last_cast_tail = 1
                m_last_cast_head = 1
                NeedToKnow_ExecutiveFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            else
                m_last_cast_head = found+1
            end
        end
    end
end


function NeedToKnow.ExecutiveFrame_ADDON_LOADED(addon)
    if ( addon == "NeedToKnow") then
        if ( not NeedToKnow_Visible ) then
            NeedToKnow_Visible = true
        end
        
        m_last_cast = {} -- [n] = { spell, target, serial }
        m_last_cast_head = 1
        m_last_cast_tail = 1
        m_last_guid = {} -- [spell][guidTarget] = { time, dur, expiry }
        NeedToKnow.totem_drops = {} -- array 1-4 of precise times the totems appeared
        
        SlashCmdList["NEEDTOKNOW"] = NeedToKnow.SlashCommand
        SLASH_NEEDTOKNOW1 = "/needtoknow"
        SLASH_NEEDTOKNOW2 = "/ntk"
    end
end


function NeedToKnow.ExecutiveFrame_PLAYER_LOGIN()
    NeedToKnowLoader.SafeUpgrade()
    NeedToKnow.ExecutiveFrame_PLAYER_TALENT_UPDATE()
    NeedToKnow.guidPlayer = UnitGUID("player")

    local _, player_CLASS = UnitClass("player")
    if player_CLASS == "DEATHKNIGHT" then
        NeedToKnow.is_DK = 1
    elseif player_CLASS == "DRUID" then
        NeedToKnow.is_Druid = 1
    end

    -- NeedToKnowLoader.SetPowerTypeList(player_CLASS)

    NeedToKnow_ExecutiveFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    NeedToKnow_ExecutiveFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    NeedToKnow_ExecutiveFrame:RegisterEvent("UNIT_TARGET")
    NeedToKnow_ExecutiveFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    NeedToKnow_ExecutiveFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    NeedToKnow_ExecutiveFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    if ( NeedToKnow.is_DK ) then
        NeedToKnow.RegisterSpellcastSent();
    end
    NeedToKnow.Update()
    
    NeedToKnow_ExecutiveFrame:UnregisterEvent("PLAYER_LOGIN")
    NeedToKnow_ExecutiveFrame:UnregisterEvent("ADDON_LOADED")
    NeedToKnow.ExecutiveFrame_ADDON_LOADED = nil
    NeedToKnow.ExecutiveFrame_PLAYER_LOGIN = nil
    NeedToKnowLoader = nil

    NeedToKnow.RefreshRaidMemberNames()
end

function NeedToKnow.RegisterSpellcastSent()
    if ( NeedToKnow.nRegisteredSent ) then
        NeedToKnow.nRegisteredSent = NeedToKnow.nRegisteredSent + 1
    else
        NeedToKnow.nRegisteredSent = 1
        NeedToKnow_ExecutiveFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    end
end

function NeedToKnow.UnregisterSpellcastSent()
    if ( NeedToKnow.nRegisteredSent ) then
        NeedToKnow.nRegisteredSent = NeedToKnow.nRegisteredSent - 1
        if ( 0 == NeedToKnow.nRegisteredSent ) then
            NeedToKnow.nRegisteredSent = nil
            NeedToKnow_ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
            NeedToKnow_ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            NeedToKnow_ExecutiveFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end
end

function NeedToKnow.ExecutiveFrame_ACTIVE_TALENT_GROUP_CHANGED()
    -- This is the only event we're guaranteed to get on a talent switch,
    -- so we have to listen for it.  However, the client may not yet have
    -- the spellbook updates, so trying to evaluate the cooldows may fail.
    -- This is one of the reasons the cooldown logic has to fail silently
    -- and try again later
    NeedToKnow.ExecutiveFrame_PLAYER_TALENT_UPDATE()
end


function NeedToKnow.ExecutiveFrame_PLAYER_TALENT_UPDATE()
    if NeedToKnow.CharSettings then
        local spec = g_GetActiveTalentGroup()

        local profile_key = NeedToKnow.CharSettings.Specs[spec]
        if not profile_key then
            print("NeedToKnow: Switching to spec",spec,"for the first time")
            profile_key = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS), spec)
        end
    
        NeedToKnow.ChangeProfile(profile_key);
    end
end


function NeedToKnow.ExecutiveFrame_UNIT_TARGET(unitTargeting)
    if m_bInCombat and not m_bCombatWithBoss then
        if UnitLevel(unitTargeting .. 'target') == -1 then
            m_bCombatWithBoss = true
            if NeedToKnow.BossStateBars then
                for bar, unused in pairs(NeedToKnow.BossStateBars) do
                    mfn_Bar_AuraCheck(bar)
                end
            end
        end
    end
end

function NeedToKnow.GetNameAndServer(unit)
  local name, server = UnitName(unit)
  if name and server then 
    return name .. '-' .. server
  end
  return name
end

function NeedToKnow.RefreshRaidMemberNames()
    NeedToKnow.raid_members = {}

    -- Note, if I did want to handle raid pets as well, they do not get the 
    -- server name decoration in the combat log as of 5.0.4
    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid"..i
            local name = NeedToKnow.GetNameAndServer(unit)
            if ( name ) then NeedToKnow.raid_members[name] = unit end
        end
    elseif IsInGroup() then
        for i = 1, 5 do
            local unit = "party"..i
            local name = NeedToKnow.GetNameAndServer(unit)
            if ( name ) then NeedToKnow.raid_members[name] = unit end
        end
    end

    -- Also get the player and their pet in directly
    -- (don't need NameAndServer since the player will always have a nil server.)
    local unit = "player"
    local name = UnitName(unit)
    NeedToKnow.raid_members[name] = unit

    unit = "pet"
    name = UnitName(unit)
    if ( name ) then
        NeedToKnow.raid_members[name] = unit
    end
end


function NeedToKnow.ExecutiveFrame_GROUP_ROSTER_UPDATE()
    NeedToKnow.RefreshRaidMemberNames();
end


function NeedToKnow.ExecutiveFrame_PLAYER_REGEN_DISABLED(unitTargeting)
    m_bInCombat = true
    m_bCombatWithBoss = false
    if IsInRaid() then
        for i = 1, 40 do
            if UnitLevel("raid"..i.."target") == -1 then
                m_bCombatWithBoss = true;
                break;
            end
        end
    elseif IsInGroup() then
        for i = 1, 5 do
            if UnitLevel("party"..i.."target") == -1 then
                m_bCombatWithBoss = true;
                break;
            end
        end
    elseif UnitLevel("target") == -1 then
        m_bCombatWithBoss = true
    end
    if NeedToKnow.BossStateBars then
        for bar, unused in pairs(NeedToKnow.BossStateBars) do
            mfn_Bar_AuraCheck(bar)
        end
    end
end


function NeedToKnow.ExecutiveFrame_PLAYER_REGEN_ENABLED(unitTargeting)
    m_bInCombat = false
    m_bCombatWithBoss = false
    if NeedToKnow.BossStateBars then
        for bar, unused in pairs(NeedToKnow.BossStateBars) do
            mfn_Bar_AuraCheck(bar)
        end
    end
end


function NeedToKnow.RemoveDefaultValues(t, def, k)
  if not k then k = "" end
  if def == nil then
    -- Some obsolete setting, or perhaps bUncompressed
    return true
  end
  -- Never want to compress name since it's read from inactive profiles
  -- Note: k was just for debugging, so it's got a leading space as part
  -- of how the debugging string was built.  This mechanism should probably
  -- be revisited.
  if type(t) ~= "table" then
    return ((k~=" name") and (t == def))
  end
  
  if #t > 0 then
    -- An array, like Groups or Bars. Compare each element against def[1]
    for i,v in ipairs(t)do
      local rhs = def[i]
      if rhs == nil then rhs = def[1] end
      if NeedToKnow.RemoveDefaultValues(v, rhs, k .. " " .. i) then
        t[i] = nil
      end
    end
  else
    for kT, vT in pairs(t) do
      if NeedToKnow.RemoveDefaultValues(t[kT], def[kT], k .. " " .. kT) then
        t[kT] = nil
      end
    end
  end
  local fn = pairs(t)
  return fn(t) == nil
end

function NeedToKnow.CompressProfile(profileSettings)
    -- Remove unused bars/groups
    for iG,vG in ipairs(profileSettings["Groups"]) do
        if iG > profileSettings.nGroups then
            profileSettings["Groups"][iG] = nil
        elseif vG.NumberBars then
            for iB, vB in ipairs(vG["Bars"]) do
                if iB > vG.NumberBars then
                    vG["Bars"][iB] = nil
                end
            end
        end
    end
    NeedToKnow.RemoveDefaultValues(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS);
end

-- DEBUG: remove k, it's just for debugging
function NeedToKnow.AddDefaultsToTable(t, def, k)
    if type(t) ~= "table" then return end
        if def == nil then
            return
        end
    if not k then k = "" end
    local n = table.maxn(t)
    if n > 0 then
        for i=1,n do
            local rhs = def[i]
            if rhs == nil then rhs = def[1] end
            if t[i] == nil then
                t[i] = NeedToKnow.DeepCopy(rhs)
            else
                NeedToKnow.AddDefaultsToTable(t[i], rhs, k .. " " .. i)
            end
        end
        else
        for kD,vD in pairs(def) do
            if t[kD] == nil then
                if type(vD) == "table" then
                    t[kD] = NeedToKnow.DeepCopy(vD)
                else
                    t[kD] = vD
                end
            else
                NeedToKnow.AddDefaultsToTable(t[kD], vD, k .. " " .. kD)
            end
        end
    end
end

function NeedToKnow.UncompressProfile(profileSettings)
    -- Make sure the arrays have the right number of elements so that
    -- AddDefaultsToTable will find them and fill them in
    if profileSettings.nGroups then
        if not profileSettings.Groups then
            profileSettings.Groups = {}
        end
        if not profileSettings.Groups[profileSettings.nGroups] then
            profileSettings.Groups[profileSettings.nGroups] = {}
        end
    end
    if profileSettings.Groups then
        for i,g in ipairs(profileSettings.Groups) do
            if g.NumberBars then
                if not g.Bars then
                    g.Bars = {}
                end
                if not g.Bars[g.NumberBars] then
                    g.Bars[g.NumberBars] = {}
                end
            end
        end
    end
        
    NeedToKnow.AddDefaultsToTable(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
    
    profileSettings.bUncompressed = true
end


function NeedToKnow.ChangeProfile(profile_key)
    if NeedToKnow_Profiles[profile_key] and
       NeedToKnow.ProfileSettings ~= NeedToKnow_Profiles[profile_key] then
        -- Compress the old profile by removing defaults
        if NeedToKnow.ProfileSettings and NeedToKnow.ProfileSettings.bUncompressed then
            NeedToKnow.CompressProfile(NeedToKnow.ProfileSettings)
        end

        -- Switch to the new profile
        NeedToKnow.ProfileSettings = NeedToKnow_Profiles[profile_key]
        local spec = g_GetActiveTalentGroup()
        NeedToKnow.CharSettings.Specs[spec] = profile_key

        -- fill in any missing defaults
        NeedToKnow.UncompressProfile(NeedToKnow.ProfileSettings)
        -- FIXME: We currently display 4 groups in the options UI, not nGroups
        -- FIXME: We don't handle nGroups changing (showing/hiding groups based on nGroups changing)
        -- Forcing 4 groups for now
        NeedToKnow.ProfileSettings.nGroups = 4
        for groupID = 1,4 do
            if ( nil == NeedToKnow.ProfileSettings.Groups[groupID] ) then
                NeedToKnow.ProfileSettings.Groups[groupID] = CopyTable( NEEDTOKNOW.GROUP_DEFAULTS )
                local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
                groupSettings.Enabled = false;
                groupSettings.Position[4] = -100 - (groupID-1) * 100
            end
        end

        -- Hide any groups not in use
        local iGroup = NeedToKnow.ProfileSettings.nGroups + 1
        while true do
            local group = _G["NeedToKnow_Group"..iGroup]
            if not group then
                break
            end
            group:Hide()
            iGroup = iGroup + 1
        end
        
        -- Update the bars and options panel (if it's open)
        NeedToKnow.Update()
        NeedToKnowOptions.UIPanel_Update()
    elseif not NeedToKnow_Profiles[profile_key] then
        print("NeedToKnow profile",profile_key,"does not exist!") -- LOCME!
    end
end


mfn_SetStatusBarValue = function (bar,texture,value,value0)
  local pct0 = 0
  if value0 then
    pct0 = value0 / bar.max_value
    if pct0 > 1 then pct0 = 1 end
  end
  
  -- This happened to me when there was lag right around the time
  -- a bar was ending
  if value < 0 then
    value = 0
  end

  local pct = value / bar.max_value
  texture.cur_value = value
  if pct > 1 then pct = 1 end
  local w = (pct-pct0) * bar:GetWidth()
  if w < 1 then 
      texture:Hide()
  else
      texture:SetWidth(w)
      texture:SetTexCoord(pct0,0, pct0,1, pct,0, pct,1)
      texture:Show()
  end
end


function NeedToKnowLoader.Reset(bResetCharacter)
    NeedToKnow_Globals = CopyTable( NEEDTOKNOW.DEFAULTS )
    
    if bResetCharacter == nil or bResetCharacter then
        NeedToKnow.ResetCharacter()
    end
end


function NeedToKnow.ResetCharacter(bCreateSpecProfile)
    local charKey = UnitName("player") .. ' - ' .. GetRealmName(); 
    NeedToKnow_CharSettings = CopyTable(NEEDTOKNOW.CHARACTER_DEFAULTS)
    NeedToKnow.CharSettings = NeedToKnow_CharSettings
    if bCreateSpecProfile == nil or bCreateSpecProfile then
        NeedToKnow.ExecutiveFrame_PLAYER_TALENT_UPDATE()    
    end
end


function NeedToKnow.AllocateProfileKey()
    local n=NeedToKnow_Globals.NextProfile or 1
    while NeedToKnow_Profiles["G"..n] do
        n = n+1
    end
    if ( NeedToKnow_Globals.NextProfile==null or n >= NeedToKnow_Globals.NextProfile ) then
        NeedToKnow_Globals.NextProfile = n+1
    end
    return "G"..n;
end

function NeedToKnow.FindUnusedNumericSuffix(prefix, defPrefix)
    local suffix = defPrefix
    if not suffix then suffix = 1 end

    local candidate = prefix .. suffix
    while ( NeedToKnow.FindProfileByName(candidate) ) do 
        suffix = suffix + 1
        candidate = prefix .. suffix
    end
    return candidate;
end

function NeedToKnow.CreateProfile(settings, idxSpec, nameProfile)
    if not nameProfile then
        local prefix = UnitName("player") .. "-"..GetRealmName() .. "." 
        nameProfile = NeedToKnow.FindUnusedNumericSuffix(prefix, idxSpec)
    end
    settings.name = nameProfile

    local keyProfile
    for k,t in pairs(NeedToKnow_Globals.Profiles) do
        if t.name == nameProfile then
            keyProfile = k
            break;
        end
    end

    if not keyProfile then
        keyProfile = NeedToKnow.AllocateProfileKey()
    end

    if NeedToKnow_CharSettings.Profiles[keyProfile] then
        print("NeedToKnow: Clearing profile ",nameProfile); -- FIXME - Localization
    else
        print("NeedToKnow: Adding profile",nameProfile) -- FIXME - Localization
    end

    if idxSpec then
        NeedToKnow.CharSettings.Specs[idxSpec] = keyProfile
    end
    NeedToKnow_CharSettings.Profiles[keyProfile] = settings
    NeedToKnow_Profiles[keyProfile] = settings
    return keyProfile
end


function NeedToKnowLoader.RoundSettings(t)
  for k,v in pairs(t) do
    local typ = type(v)
    if typ == "number" then
      t[k] = tonumber(string.format("%0.4f",v))
    elseif typ == "table" then
      NeedToKnowLoader.RoundSettings(v)
    end
  end    
end


function NeedToKnowLoader.MigrateSpec(specSettings, idxSpec)
    if not specSettings or not specSettings.Groups or not specSettings.Groups[1] or not 
       specSettings.Groups[2] or not specSettings.Groups[3] or not specSettings.Groups[4] then
        return false
    end
    
    -- Round floats to 0.00001, since old versions left really stange values of
    -- BarSpacing and BarPadding around
    NeedToKnowLoader.RoundSettings(specSettings)
    specSettings.Spec = nil
    specSettings.Locked = nil
    specSettings.nGroups = 4
    specSettings.BarFont = NeedToKnowLoader.FindFontName(specSettings.BarFont)
    NeedToKnow.CreateProfile(specSettings, idxSpec)
    return true
end


function NeedToKnowLoader.MigrateCharacterSettings()
    print("NeedToKnow: Migrating settings from", NeedToKnow_Settings["Version"]);
    local oldSettings = NeedToKnow_Settings
    NeedToKnow.ResetCharacter(false)
    if ( not oldSettings["Spec"] ) then 
        NeedToKnow_Settings = nil 
        return 
    end

    -- Blink was controlled purely by the alpha of MissingBlink for awhile,
    -- But then I introduced an explicit blink_enabled variable.  Fill that in
    -- if it's missing
    for kS,vS in pairs(oldSettings["Spec"]) do
      for kG,vG in pairs(vS["Groups"]) do
        for kB,vB in pairs(vG["Bars"]) do
            if nil == vB.blink_enabled and vB.MissingBlink then
                vB.blink_enabled = vB.MissingBlink.a > 0
            end
        end
      end
    end

    NeedToKnow.CharSettings["Locked"] = oldSettings["Locked"]

    local bOK
    if ( oldSettings["Spec"] ) then -- The Spec member existed from versions 2.4 to 3.1.7
        for idxSpec = 1,2 do
            local newprofile = oldSettings.Spec[idxSpec]
            for kD,_ in pairs(NEEDTOKNOW.PROFILE_DEFAULTS) do
              if oldSettings[kD] then
                newprofile[kD] = oldSettings[kD]
              end
            end
            bOK = NeedToKnowLoader.MigrateSpec(newprofile, idxSpec)
        end
    -- if before dual spec support, copy old settings to both specs    
    elseif oldSettings["Version"] >= "2.0" and oldSettings["Groups"] then    
        bOK = NeedToKnowLoader.MigrateSpec(oldSettings, 1) and 
              NeedToKnowLoader.MigrateSpec(CopyTable(oldSettings), 2)

        -- save group positions if upgrading from version that used layout-local.txt
        if ( bOK and NeedToKnow_Settings.Version < "2.1" ) then    
            for groupID = 1, 4 do -- Prior to 3.2, there were always 4 groups
                NeedToKnow.SavePosition(_G["NeedToKnow_Group"..groupID], groupID)
            end
        end        
    end
        
    if not bOK then
        print("Old NeedToKnow character settings corrupted or not compatible with current version... starting from scratch")
        NeedToKnow.ResetCharacter()
    end
    NeedToKnow_Settings = nil
end


function NeedToKnowLoader.FindFontName(fontPath)
    local fontList = NeedToKnow.LSM:List("font")
    for i=1,#fontList do
        local fontName = fontList[i]
        local iPath = NeedToKnow.LSM:Fetch("font", fontName)
        if iPath == fontPath then
            return fontName
        end
    end
    return NEEDTOKNOW.PROFILE_DEFAULTS.BarFont
end

function NeedToKnowLoader.SafeUpgrade()
    local defPath = GameFontHighlight:GetFont()
    NEEDTOKNOW.PROFILE_DEFAULTS.BarFont = NeedToKnowLoader.FindFontName(defPath)
    NeedToKnow_Profiles = {}

    -- If there had been an error during the previous upgrade, NeedToKnow_Settings 
    -- may be in an inconsistent, halfway state.  
    if not NeedToKnow_Globals then
        NeedToKnowLoader.Reset(false)
    end

    if NeedToKnow_Settings then -- prior to 4.0
        NeedToKnowLoader.MigrateCharacterSettings()
    end
    if not NeedToKnow_CharSettings then
        -- we'll call talent update right after this, so we pass false now
        NeedToKnow.ResetCharacter(false)
    end
    NeedToKnow.CharSettings = NeedToKnow_CharSettings

    -- 4.0 settings sanity check 
    if not NeedToKnow_Globals or
       not NeedToKnow_Globals["Version"] or
       not NeedToKnow_Globals.Profiles
    then
        print("NeedToKnow settings corrupted, resetting")
        NeedToKnowLoader.Reset()
    end

    local maxKey = 0
    local aByName = {}
    for iS,vS in pairs(NeedToKnow_Globals.Profiles) do
        if vS.bUncompressed then
            NeedToKnow.CompressProfile(vS)
        end
        -- Although name should never be compressed, it could have been prior to 4.0.16
        if not vS.name then vS.name = "Default" end
        local cur = tonumber(iS:sub(2))
        if ( cur > maxKey ) then maxKey = cur end
        NeedToKnow_Profiles[iS] = vS
        if aByName[ vS.name ] then
            local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
            print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
            vS.name = renamed;
        end
        aByName[vS.name] = vS
    end

    local aFixups = {}
    if NeedToKnow_CharSettings.Profiles then
        for iS,vS in pairs(NeedToKnow_CharSettings.Profiles) do
            -- Check for collisions by name
            if aByName[ vS.name ] then
                local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
                print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
                vS.name = renamed;
            end
            aByName[vS.name] = vS

            -- Check for collisions by key
            if ( NeedToKnow_Profiles[iS] ) then
                print("NeedToKnow error encountered, both", vS.name, "and", NeedToKnow_Profiles[iS].name, "collided as " .. iS .. ".  Some specs may be mapped to one that should have been mapped to the other.");
                local oS = iS;
                iS = NeedToKnow.AllocateProfileKey();
                aFixups[oS] = iS
            end

            -- Although name should never be compressed, it could have been prior to 4.0.16
            if not vS.name then vS.name = "Default" end
            local cur = tonumber(iS:sub(2))
            if ( cur > maxKey ) then maxKey = cur end
            NeedToKnow_Profiles[iS] = vS
            local k = NeedToKnow.FindProfileByName(vS.name);
        end
    end

    -- fixup character profile collisions by key
    for oS,iS in pairs(aFixups) do
      NeedToKnow_CharSettings.Profiles[iS] = NeedToKnow_CharSettings.Profiles[oS]; 
      NeedToKnow_CharSettings.Profiles[oS] = nil; 
    end

    if ( not NeedToKnow_Globals.NextProfile or maxKey > NeedToKnow_Globals.NextProfile ) then
        print("Warning, NeedToKnow forgot how many profiles it had allocated.  New account profiles may hiccup when switching characters.")
        NeedToKnow_Globals.NextProfile = maxKey + 1
    end

    local spec = g_GetActiveTalentGroup()
    local curKey = NeedToKnow.CharSettings.Specs[spec]
    if ( curKey and not NeedToKnow_Profiles[curKey] ) then
        print("Current profile (" .. curKey .. ") has been deleted!");
        curKey = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS), spec)
        local curProf = NeedToKnow_Profiles[curKey]
        NeedToKnow.CharSettings.Specs[spec] = curKey
    end
    

     -- TODO: check the required members for existence and delete any corrupted profiles
end

--[[
function NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed)
    local costInfo = g_GetSpellPowerCost(sid)
	local iCost
	for iCost =1,table.getn(costInfo) do
	    local pt = costInfo[iCost].type
		-- -2 is used as HEALTH for certain self-harming spells
		if ( pt >= 0 ) then
		    local n = g_GetSpellInfo(sid)
			-- print(sid, n, pt)
			powerTypesUsed[pt] = costInfo[iCost].name;
		end
	end
end

function NeedToKnowLoader.SetPowerTypeList(player_CLASS)
    if player_CLASS == "DRUID" or 
        player_CLASS == "MONK" 
    then
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(NEEDTOKNOW.SPELL_POWER_PRIMARY), MenuText = NeedToKnow.GetPowerName(NEEDTOKNOW.SPELL_POWER_PRIMARY) } ) 
    end
    if player_CLASS == "MONK" 
    then
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(NEEDTOKNOW.SPELL_POWER_STAGGER), MenuText = NeedToKnow.GetPowerName(NEEDTOKNOW.SPELL_POWER_STAGGER) } ) 
    end

	local powerTypesUsed = {}
	
    local numTabs = g_GetNumSpellTabs() 
	for iTab=1,numTabs do 
	    local _,_,offset,numSpells = g_GetSpellTabInfo(iTab) 
	    for iSpell=1,numSpells do 
		    local stype,sid = g_GetSpellBookItemInfo(iSpell+offset, "book") 
			-- print(iTab, iSpell, stype, sid)
			if (stype=="SPELL" or stype=="FUTURESPELL") then
			    NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed);
			end
		end 
	end
	
	local nSpecs = g_GetNumSpecializations()
	for iSpec=1,nSpecs do
	    local spells = {g_GetSpecializationSpells(iSpec)}
		local numSpells = table.getn(spells)
		for iSpell=1,numSpells,2 do
		    local sid = spells[iSpell]
			NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed);
		end
	end
	
	for pt,ptn in pairs(powerTypesUsed) do
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(pt), MenuText = NeedToKnow.GetPowerName(pt) } ) 
	end
end	
]]--



function NeedToKnow.DeepCopy(object)
    if type(object) ~= "table" then
        return object
    else
        local new_table = {}
        for k,v in pairs(object) do
            new_table[k] = NeedToKnow.DeepCopy(v)
        end
        return new_table
    end
end


---- Copies anything (int, table, whatever).  Unlike DeepCopy (and CopyTable), CopyRefGraph can 
---- recreate a recursive reference structure (CopyTable will stack overflow.)
---- Copied from http://lua-users.org/wiki/CopyTable
--function NeedToKnow.CopyRefGraph(object)
    --local lookup_table = {}
    --local function _copy(object)
        --if type(object) ~= "table" then
            --return object
        --elseif lookup_table[object] then
            --return lookup_table[object]
        --end
        --local new_table = {}
        --lookup_table[object] = new_table
        --for index, value in pairs(object) do
            --new_table[_copy(index)] = _copy(value)
        --end
        --return setmetatable(new_table, getmetatable(object))
    --end
    --return _copy(object)
--end

function NeedToKnow.RestoreTableFromCopy(dest, source)
    for key,value in pairs(source) do
        if type(value) == "table" then
           if dest[key] then
               NeedToKnow.RestoreTableFromCopy(dest[key], value)
           else
               dest[key] = value
           end
        else
            dest[key] = value
        end
    end
    for key,value in pairs(dest) do
        if source[key] == nil then
            dest[key] = nil
        end
    end
end

function NeedToKnow.Update()
    if UnitExists("player") and NeedToKnow.ProfileSettings then
        for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
            NeedToKnow.Group_Update(groupID)
        end
    end
end


function NeedToKnow.Show(bShow)
    NeedToKnow_Visible = bShow
    for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
        local groupName = "NeedToKnow_Group"..groupID
        local group = _G[groupName]
        local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
        
        if (NeedToKnow_Visible and groupSettings.Enabled) then
            group:Show()
        else
            group:Hide()
        end
    end
end

do
    local executiveFrame = CreateFrame("Frame", "NeedToKnow_ExecutiveFrame")
    executiveFrame:SetScript("OnEvent", NeedToKnow.ExecutiveFrame_OnEvent)
    executiveFrame:RegisterEvent("ADDON_LOADED")
    executiveFrame:RegisterEvent("PLAYER_LOGIN")
end



-- ------
-- GROUPS
-- ------

function NeedToKnow.Group_Update(groupID)
    local groupName = "NeedToKnow_Group"..groupID
    local group = _G[groupName]
    local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

    local bar
    for barID = 1, groupSettings.NumberBars do
        local barName = groupName.."Bar"..barID
        bar = _G[barName] or CreateFrame("Frame", barName, group, "NeedToKnow_BarTemplate")
        bar:SetID(barID)

        if ( barID > 1 ) then
            bar:SetPoint("TOP", _G[groupName.."Bar"..(barID-1)], "BOTTOM", 0, -NeedToKnow.ProfileSettings.BarSpacing)
        else
            bar:SetPoint("TOPLEFT", group, "TOPLEFT")
        end

        NeedToKnow.Bar_Update(groupID, barID)

        if ( not groupSettings.Enabled ) then
            NeedToKnow.ClearScripts(bar)
        end
    end

    local resizeButton = _G[groupName.."ResizeButton"]
    resizeButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -8)

    local barID = groupSettings.NumberBars+1
    while true do
        bar = _G[groupName.."Bar"..barID]
        if bar then
            bar:Hide()
            NeedToKnow.ClearScripts(bar)
            barID = barID + 1
        else
            break
        end
    end

    if ( NeedToKnow.CharSettings["Locked"] ) then
        resizeButton:Hide()
    else
        resizeButton:Show()
    end

    -- Early enough in the loading process (before PLAYER_LOGIN), we might not
    -- know the position yet
    if groupSettings.Position then
        group:ClearAllPoints()
        local point, relativePoint, xOfs, yOfs = unpack(groupSettings.Position)
        group:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        group:SetScale(groupSettings.Scale)
    end
    
    if ( NeedToKnow_Visible and groupSettings.Enabled ) then
        group:Show()
    else
        group:Hide()
    end
end



-- ----
-- BARS
-- ----

-- Attempt to figure out if a name is an item or a spell, and if a spell
-- try to choose a spell with that name that has a cooldown
-- This may fail for valid names if the client doesn't have the data for
-- that spell yet (just logged in or changed talent specs), in which case 
-- we mark that spell to try again later
function NeedToKnow.SetupSpellCooldown(bar, entry)
    local id = entry.id
    local name = entry.name
    local idx = entry.idxName
    if not id then
        if ( name == "Auto Shot" or
             name == c_AUTO_SHOT_NAME ) 
        then
            bar.settings.bAutoShot = true
            bar.cd_functions[idx] = mfn_GetAutoShotCooldown
        else
            local item_id = NeedToKnow.GetItemIDString(name)
            if item_id then
                entry.id = item_id
                entry.name = nil
                bar.cd_functions[idx] = NeedToKnow.GetItemCooldown
            else
                local betterSpellID
                betterSpellID = NeedToKnow.TryToFindSpellWithCD(name)
                if nil ~= betterSpell then
                    entry.id = betterSpell
                    entry.name = nil
                    bar.cd_functions[idx] = mfn_GetSpellCooldown
                elseif not GetSpellCooldown(name) then
                    bar.cd_functions[idx] = mfn_GetUnresolvedCooldown
                else
                    bar.cd_functions[idx] = mfn_GetSpellCooldown
                end

                if ( bar.cd_functions[idx] == mfn_GetSpellCooldown ) then
                    local key = entry.id or entry.name
                    if ( bar.settings.show_charges and GetSpellCharges(key) ) then
                        bar.cd_functions[idx] = mfn_GetSpellChargesCooldown
                    end
                end
            end
        end
    end
end

-- Called when the configuration of the bar has changed, when the addon
-- is loaded or when ntk is locked and unlocked
function NeedToKnow.Bar_Update(groupID, barID)
    local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

    local barName = "NeedToKnow_Group"..groupID.."Bar"..barID
    local bar = _G[barName]
    if not bar then
        -- New bar added in the UI; need to create it!
        local group = _G["NeedToKnow_Group"..groupID]
        bar = CreateFrame("Button", barName, group, "NeedToKnow_BarTemplate")
        if barID > 1 then
            bar:SetPoint("TOPLEFT", "NeedToKnow_Group"..groupID.."Bar"..(barID-1), "BOTTOMLEFT", 0, 0)
        else
            bar:SetPoint("TOPLEFT", "NeedToKnow_Group"..groupID, "TOPLEFT")
        end
        bar:SetPoint("RIGHT", group, "RIGHT", 0, 0)
        --trace("Creating bar for", groupID, barID)
    end

    local background = _G[barName.."Background"]
    bar.spark = _G[barName.."Spark"]
    bar.text = _G[barName.."Text"]
    bar.time = _G[barName.."Time"]
    bar.bar1 = _G[barName.."Texture"]

    local barSettings = groupSettings["Bars"][barID]
    if not barSettings then
        --trace("Adding bar settings for", groupID, barID)
        barSettings = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
        groupSettings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
    end
    bar.auraName = barSettings.AuraName
    
    if ( barSettings.BuffOrDebuff == "BUFFCD" or
         barSettings.BuffOrDebuff == "TOTEM" or
         barSettings.BuffOrDebuff == "USABLE" or
         barSettings.BuffOrDebuff == "EQUIPSLOT" or
         barSettings.BuffOrDebuff == "CASTCD") 
    then
        barSettings.Unit = "player"
    end

    bar.settings = barSettings
    bar.unit = barSettings.Unit
    bar.nextUpdate = g_GetTime() + c_UPDATE_INTERVAL

    bar.fixedDuration = tonumber(groupSettings.FixedDuration)
    if ( not bar.fixedDuration or 0 >= bar.fixedDuration ) then
        bar.fixedDuration = nil
    end

    bar.max_value = 1
    mfn_SetStatusBarValue(bar,bar.bar1,1)
    bar.bar1:SetTexture(NeedToKnow.LSM:Fetch("statusbar", NeedToKnow.ProfileSettings["BarTexture"]))
    if ( bar.bar2 ) then
        bar.bar2:SetTexture(NeedToKnow.LSM:Fetch("statusbar", NeedToKnow.ProfileSettings["BarTexture"]))
    end
    local fontPath = NeedToKnow.LSM:Fetch("font", NeedToKnow.ProfileSettings["BarFont"])
    if ( fontPath ) then
        local ol = NeedToKnow.ProfileSettings["FontOutline"]
        if ( ol == 0 ) then
          ol = nil
        elseif (ol == 1) then
          ol = "OUTLINE"
        else
          ol = "THICKOUTLINE"
        end

        bar.text:SetFont(fontPath, NeedToKnow.ProfileSettings["FontSize"],ol)
        bar.time:SetFont(fontPath, NeedToKnow.ProfileSettings["FontSize"],ol)
    end
    
    bar:SetWidth(groupSettings.Width)
    bar.text:SetWidth(groupSettings.Width-60)
    NeedToKnow.SizeBackground(bar, barSettings.show_icon)

    background:SetHeight(bar:GetHeight() + 2*NeedToKnow.ProfileSettings["BarPadding"])
    background:SetVertexColor(unpack(NeedToKnow.ProfileSettings["BkgdColor"]))

    -- Set up the Visual Cast Time overlay.  It isn't a part of the template 
    -- because most bars won't use it and thus don't need to pay the cost of
    -- a hidden frame
    if ( barSettings.vct_enabled ) then
        if ( nil == bar.vct ) then
            bar.vct = bar:CreateTexture(barName.."VisualCast", "ARTWORK")
            bar.vct:SetPoint("TOPLEFT", bar, "TOPLEFT")
        end
        local argb = barSettings.vct_color
        bar.vct:SetColorTexture(argb.r, argb.g, argb.b, argb.a )
        bar.vct:SetBlendMode("ADD")
        bar.vct:SetHeight(bar:GetHeight())
    elseif (nil ~= bar.vct) then
        bar.vct:Hide()
    end
    
    if ( barSettings.show_icon ) then
        if ( not bar.icon ) then
            bar.icon = bar:CreateTexture(bar:GetName().."Icon", "ARTWORK")
        end
        local size = bar:GetHeight()
        bar.icon:SetWidth(size)
        bar.icon:SetHeight(size)
        bar.icon:ClearAllPoints()
        bar.icon:SetPoint("TOPRIGHT", bar, "TOPLEFT", -NeedToKnow.ProfileSettings["BarPadding"], 0)
        bar.icon:Show()
    elseif (bar.icon) then
        bar.icon:Hide()
    end

    if ( NeedToKnow.CharSettings["Locked"] ) then
        local enabled = groupSettings.Enabled and barSettings.Enabled
        if enabled then
            -- Set up the bar to be functional
            -- click through
            bar:EnableMouse(false)

            -- Split the spell names    
            bar.spells = {}
            bar.cd_functions = {}
            local iSpell = 0
            for barSpell in bar.auraName:gmatch("([^,]+)") do
                iSpell = iSpell+1
                barSpell = strtrim(barSpell)
                local _, nDigits = barSpell:find("^-?%d+")
                if ( nDigits == barSpell:len() ) then
                    table.insert(bar.spells, { idxName=iSpell, id=tonumber(barSpell) } )
                else
                    table.insert(bar.spells, { idxName=iSpell, name=barSpell } )
                end
            end

            -- split the user name overrides
            bar.spell_names = {}
            for un in barSettings.show_text_user:gmatch("([^,]+)") do
                un = strtrim(un)
                table.insert(bar.spell_names, un)
            end

            -- split the "reset" spells (for internal cooldowns which reset when the player gains an aura)
            if barSettings.buffcd_reset_spells and barSettings.buffcd_reset_spells ~= "" then
                bar.reset_spells = {}
                bar.reset_start = {}
                iSpell = 0
                for resetSpell in barSettings.buffcd_reset_spells:gmatch("([^,]+)") do
                    iSpell = iSpell+1
                    resetSpell = strtrim(resetSpell)
                    local _, nDigits = resetSpell:find("^%d+")
                    if ( nDigits == resetSpell:len() ) then
                        table.insert(bar.reset_spells, { idxName = iSpell, id=tonumber(resetSpell) } )
                    else
                        table.insert(bar.reset_spells, { idxName = iSpell, name=resetSpell} )
                    end
                    table.insert(bar.reset_start, 0)
                end
            else
                bar.reset_spells = nil
                bar.reset_start = nil
            end

            barSettings.bAutoShot = nil
            bar.is_counter = nil
            bar.ticker = NeedToKnow.Bar_OnUpdate
            
            -- Determine which helper functions to use
            if     "BUFFCD" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_BUFFCD
            elseif "TOTEM" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_TOTEM
            elseif "USABLE" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_USABLE
            elseif "EQUIPSLOT" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_EQUIPSLOT
            elseif "POWER" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_POWER
                bar.is_counter = true
                bar.ticker = nil
                bar.ticking = false
            elseif "CASTCD" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_CASTCD
                for idx, entry in ipairs(bar.spells) do
                    table.insert(bar.cd_functions, mfn_GetSpellCooldown)
                    NeedToKnow.SetupSpellCooldown(bar, entry)
                end
            elseif barSettings.show_all_stacks then
                bar.fnCheck = mfn_AuraCheck_AllStacks
            else
                bar.fnCheck = mfn_AuraCheck_Single
            end
        
            if ( barSettings.BuffOrDebuff == "BUFFCD" ) then
                local dur = tonumber(barSettings.buffcd_duration)
                if (not dur or dur < 1) then
                    print("Internal cooldown bar watching",barSettings.AuraName,"did not set a cooldown duration.  Disabling the bar")
                    enabled = false
                end
            end
        
            NeedToKnow.SetScripts(bar)
            -- Events were cleared while unlocked, so need to check the bar again now
            mfn_Bar_AuraCheck(bar)
        else
            NeedToKnow.ClearScripts(bar)
            bar:Hide()
        end
    else
        NeedToKnow.ClearScripts(bar)
        -- Set up the bar to be configured
        bar:EnableMouse(true)

        bar.bar1:SetVertexColor(barSettings.BarColor.r, barSettings.BarColor.g, barSettings.BarColor.b)
        bar.bar1:SetAlpha(barSettings.BarColor.a)
        bar:Show()
        bar.spark:Hide()
        bar.time:Hide()
        if ( bar.icon ) then
            bar.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        if ( bar.vct ) then
            bar.vct:SetWidth( bar:GetWidth() / 16)
            bar.vct:Show()
        end
        if ( bar.bar2 ) then
            bar.bar2:Hide()
        end
        
        local txt=""
        if ( barSettings.show_mypip ) then
            txt = txt.."* "
        end

        if ( barSettings.show_text ) then
            if "" ~= barSettings.show_text_user then
                txt = barSettings.show_text_user
            else
                txt = txt .. NeedToKnow.PrettyName(barSettings)
            end

            if ( barSettings.append_cd
                 and (barSettings.BuffOrDebuff == "CASTCD"
                   or barSettings.BuffOrDebuff == "BUFFCD"
                   or barSettings.BuffOrDebuff == "EQUIPSLOT" ) )
            then
                txt = txt .. " CD"
            elseif ( barSettings.append_usable
                 and barSettings.BuffOrDebuff == "USABLE" )
            then
                txt = txt .. " Usable"
            end
            if ( barSettings.bDetectExtends == true ) then
                txt = txt .. " + 3s"
            end
        end
        bar.text:SetText(txt)

        if ( barSettings.Enabled ) then
            bar:SetAlpha(1)
        else
            bar:SetAlpha(0.4)
        end
    end
end


function NeedToKnow.CheckCombatLogRegistration(bar, force)
    if UnitExists(bar.unit) then
        bar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        bar:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end


function NeedToKnow.SetScripts(bar)
    bar:SetScript("OnEvent", NeedToKnow.Bar_OnEvent)
 
    if ( bar.ticker ) then
        bar:SetScript("OnUpdate", bar.ticker)
    end
    if ( "TOTEM" == bar.settings.BuffOrDebuff ) then
        bar:RegisterEvent("PLAYER_TOTEM_UPDATE")
    elseif ( "CASTCD" == bar.settings.BuffOrDebuff ) then
        if ( bar.settings.bAutoShot ) then
            bar:RegisterEvent("START_AUTOREPEAT_SPELL")
            bar:RegisterEvent("STOP_AUTOREPEAT_SPELL")
        end
        bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    elseif ( "EQUIPSLOT" == bar.settings.BuffOrDebuff ) then
        bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
--[[
    elseif ( "POWER" == bar.settings.BuffOrDebuff ) then
        if bar.settings.AuraName == tostring(NEEDTOKNOW.SPELL_POWER_STAGGER) then
          bar:RegisterEvent("UNIT_HEALTH")
        else
          bar:RegisterEvent("UNIT_POWER")
          bar:RegisterEvent("UNIT_DISPLAYPOWER")
        end
]]--
    elseif ( "USABLE" == bar.settings.BuffOrDebuff ) then
        bar:RegisterEvent("SPELL_UPDATE_USABLE")
    elseif ( bar.settings.Unit == "targettarget" ) then
        -- WORKAROUND: PLAYER_TARGET_CHANGED happens immediately, UNIT_TARGET every couple seconds
        bar:RegisterEvent("PLAYER_TARGET_CHANGED")
        bar:RegisterEvent("UNIT_TARGET")
        -- WORKAROUND: Don't get UNIT_AURA for targettarget
        NeedToKnow.CheckCombatLogRegistration(bar)
    else
        bar:RegisterEvent("UNIT_AURA")
    end

    if ( bar.unit == "focus" ) then
        bar:RegisterEvent("PLAYER_FOCUS_CHANGED")
    elseif ( bar.unit == "target" ) then
        bar:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif ( bar.unit == "pet" ) then
        bar:RegisterEvent("UNIT_PET")
    elseif ( "lastraid" == bar.settings.Unit ) then
        if ( not NeedToKnow.BarsForPSS ) then
            NeedToKnow.BarsForPSS = {}
        end
        NeedToKnow.BarsForPSS[bar] = true
        NeedToKnow.RegisterSpellcastSent()
    end
    
    if bar.settings.bDetectExtends then
        local idx,entry
        for idx, entry in ipairs(bar.spells) do
            local spellName
            if ( entry.id ) then
                spellName = g_GetSpellInfo(entry.id)
            else
                spellName = entry.name
            end
            if spellName then
                local r = m_last_guid[spellName]
                if not r then
                    m_last_guid[spellName] = { time=0, dur=0, expiry=0 }
                end
            else
                print("Warning! NTK could not get name for ", entry.id)
            end
        end
        NeedToKnow.RegisterSpellcastSent()
    end
    if bar.settings.blink_enabled and bar.settings.blink_boss then
        if not NeedToKnow.BossStateBars then
            NeedToKnow.BossStateBars = {}
        end
        NeedToKnow.BossStateBars[bar] = 1;
    end
end

function NeedToKnow.ClearScripts(bar)
    bar:SetScript("OnEvent", nil)
    bar:SetScript("OnUpdate", nil)
    bar:UnregisterEvent("PLAYER_TARGET_CHANGED")
    bar:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    bar:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    bar:UnregisterEvent("PLAYER_TOTEM_UPDATE")
    bar:UnregisterEvent("UNIT_AURA")
    -- bar:UnregisterEvent("UNIT_POWER")
    -- bar:UnregisterEvent("UNIT_DISPLAYPOWER")
    bar:UnregisterEvent("UNIT_TARGET")
    bar:UnregisterEvent("START_AUTOREPEAT_SPELL")
    bar:UnregisterEvent("STOP_AUTOREPEAT_SPELL")
    bar:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if NeedToKnow.BossStateBars then
        NeedToKnow.BossStateBars[bar] = nil;
    end

    if bar.settings.bDetectExtends then
        NeedToKnow.UnregisterSpellcastSent()
    end
    if NeedToKnow.BarsForPSS and NeedToKnow.BarsForPSS[bar] then
        NeedToKnow.BarsForPSS[bar] = nil
        if nil == next(NeedToKnow.BarsForPSS) then
            NeedToKnow.BarsForPSS = nil
            NeedToKnow.UnregisterSpellcastSent();
        end
    end
end

function NeedToKnow.Bar_OnMouseUp(self, button)
    if ( button == "RightButton" ) then
        -- PlaySound("UChatScrollButton");
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
        NeedToKnowRMB.ShowMenu(self);
     end
end

function NeedToKnow.Bar_OnSizeChanged(self)
    if (self.bar1.cur_value) then mfn_SetStatusBarValue(self, self.bar1, self.bar1.cur_value) end
    if (self.bar2 and self.bar2.cur_value) then mfn_SetStatusBarValue(self, self.bar2, self.bar2.cur_value, self.bar1.cur_value) end
end




-- AuraCheck calls on this to compute the "text" of the bar
-- It is separated out like this in part to be hooked by other addons
function NeedToKnow.ComputeBarText(buffName, count, extended, buff_stacks, bar)
    local text
    if ( count > 1 ) then
        text = buffName.."  ["..count.."]"
    else
        text = buffName
    end

    if ( bar.settings.show_ttn1 and buff_stacks.total_ttn[1] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[1]..")"
    end
    if ( bar.settings.show_ttn2 and buff_stacks.total_ttn[2] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[2]..")"
    end
    if ( bar.settings.show_ttn3 and buff_stacks.total_ttn[3] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[3]..")"
    end
    if ( extended and extended > 1 ) then
        text = text .. string.format(" + %.0fs", extended)
    end
    return text
end

-- Called by mfn_UpdateVCT, which is called from AuraCheck and possibly 
-- by Bar_Update depending on vct_refresh. In addition to refactoring out some 
-- code from the long AuraCheck, this also provides a convenient hook for other addons
function NeedToKnow.ComputeVCTDuration(bar)
    local vct_duration = 0
    
    local spellToTime = bar.settings.vct_spell
    if ( nil == spellToTime or "" == spellToTime ) then
        spellToTime = bar.buffName
    end
     
    local _, _, _, castTime = g_GetSpellInfo(spellToTime)

    if ( castTime ) then
        vct_duration = castTime / 1000
        bar.vct_refresh = true
    else
        bar.vct_refresh = false
    end
    
    if ( bar.settings.vct_extra ) then
        vct_duration =  vct_duration + bar.settings.vct_extra
    end
    return vct_duration
end

mfn_UpdateVCT = function (bar)
    local vct_duration = NeedToKnow.ComputeVCTDuration(bar)

    local dur = bar.fixedDuration or bar.duration
    if ( dur ) then
        vct_width =  (vct_duration * bar:GetWidth()) / dur
        if (vct_width > bar:GetWidth()) then
            vct_width = bar:GetWidth() 
        end
    else
        vct_width = 0
    end

    if ( vct_width > 1 ) then
        bar.vct:SetWidth(vct_width)
        bar.vct:Show()
    else
        bar.vct:Hide()
    end
end

function NeedToKnow.SizeBackground(bar, i_show_icon)
    local background = _G[bar:GetName() .. "Background"]
    local bgWidth = bar:GetWidth() + 2*NeedToKnow.ProfileSettings["BarPadding"]
    local y = NeedToKnow.ProfileSettings["BarPadding"]
    local x = -y
    background:ClearAllPoints()

    if ( i_show_icon ) then
        local iconExtra = bar:GetHeight() + NeedToKnow.ProfileSettings["BarPadding"]
        bgWidth = bgWidth + iconExtra
        x = x - iconExtra
    end
    background:SetWidth(bgWidth)
    background:SetPoint("TOPLEFT", bar, "TOPLEFT", x, y)
end

function NeedToKnow.CreateBar2(bar)
    if ( not bar.bar2 ) then
        local n = bar:GetName() .. "Bar2"
        bar.bar2 = bar:CreateTexture(n, "BORDER")
        bar.bar2:SetPoint("TOPLEFT", bar.bar1, "TOPRIGHT")
        bar.bar2:SetPoint("BOTTOM", bar, "BOTTOM")
        bar.bar2:SetWidth(bar:GetWidth())
    end
end

function NeedToKnow.PrettyName(barSettings)
    if ( barSettings.BuffOrDebuff == "EQUIPSLOT" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NEEDTOKNOW.ITEM_NAMES[idx] end
        return ""
    elseif ( barSettings.BuffOrDebuff == "POWER" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NeedToKnow.GetPowerName(idx) end
        return ""
    else
        return barSettings.AuraName
    end
end

function NeedToKnow.ConfigureVisibleBar(bar, count, extended, buff_stacks)
    local text = ""
    if ( bar.settings.show_icon and bar.iconPath and bar.icon ) then
        bar.icon:SetTexture(bar.iconPath)
        bar.icon:Show()
        NeedToKnow.SizeBackground(bar, true)
    elseif bar.icon then
        bar.icon:Hide()
        NeedToKnow.SizeBackground(bar, false)
    end

    bar.bar1:SetVertexColor(bar.settings.BarColor.r, bar.settings.BarColor.g, bar.settings.BarColor.b)
    bar.bar1:SetAlpha(bar.settings.BarColor.a)
    if ( bar.max_expirationTime and bar.max_expirationTime ~= bar.expirationTime ) then 
        NeedToKnow.CreateBar2(bar)
        bar.bar2:SetTexture(bar.bar1:GetTexture())
        bar.bar2:SetVertexColor(bar.settings.BarColor.r, bar.settings.BarColor.g, bar.settings.BarColor.b)
        bar.bar2:SetAlpha(bar.settings.BarColor.a * 0.5)
        bar.bar2:Show()
    elseif (bar.bar2) then
        bar.bar2:Hide()
    end
    
    local txt = ""
    if ( bar.settings.show_mypip ) then
        txt = txt .. "* "
    end

    local n = ""
    if ( bar.settings.show_text ) then
        n = bar.buffName
        if "" ~= bar.settings.show_text_user then
            local idx=bar.idxName
            if idx > #bar.spell_names then idx = #bar.spell_names end
            n = bar.spell_names[idx]
        end
    end

    local c = count
    if not bar.settings.show_count then
        c = 1
    end
    local to_append = NeedToKnow.ComputeBarText(n, c, extended, buff_stacks, bar)
    if to_append and to_append ~= "" then
        txt = txt .. to_append
    end

    if ( bar.settings.append_cd 
         and (bar.settings.BuffOrDebuff == "CASTCD" 
           or bar.settings.BuffOrDebuff == "BUFFCD"
           or bar.settings.BuffOrDebuff == "EQUIPSLOT" ) ) 
    then
        txt = txt .. " CD"
    elseif (bar.settings.append_usable and bar.settings.BuffOrDebuff == "USABLE" ) then
        txt = txt .. " Usable"
    end
    bar.text:SetText(txt)
        
    -- Is this an aura with a finite duration?
    local vct_width = 0
    if ( not bar.is_counter and bar.duration > 0 ) then
        -- Configure the main status bar
        local duration = bar.fixedDuration or bar.duration
        bar.max_value = duration

        -- Determine the size of the visual cast bar
        if ( bar.settings.vct_enabled ) then
            mfn_UpdateVCT(bar)
        end
        
        -- Force an update to get all the bars to the current position (sharing code)
        -- This will call UpdateVCT again, but that seems ok
        bar.nextUpdate = -c_UPDATE_INTERVAL
        if bar.expirationTime > g_GetTime() then
            NeedToKnow.Bar_OnUpdate(bar, 0)
        end

        bar.time:Show()
    elseif bar.is_counter then
        bar.max_value = 1
        local pct = buff_stacks.total_ttn[1] / buff_stacks.total_ttn[2]
        mfn_SetStatusBarValue(bar,bar.bar1,pct)
        if bar.bar2 then mfn_SetStatusBarValue(bar,bar.bar2,pct) end

        bar.time:Hide()
        bar.spark:Hide()

        if ( bar.vct ) then
            bar.vct:Hide()
        end
    else
        -- Hide the time text and spark for auras with "infinite" duration
        bar.max_value = 1

        mfn_SetStatusBarValue(bar,bar.bar1,1)
        if bar.bar2 then mfn_SetStatusBarValue(bar,bar.bar2,1) end

        bar.time:Hide()
        bar.spark:Hide()

        if ( bar.vct ) then
            bar.vct:Hide()
        end
    end
end

function NeedToKnow.ConfigureBlinkingBar(bar)
    local settings = bar.settings
    if ( not bar.blink ) then
        bar.blink=true
        bar.blink_phase=1
        bar.bar1:SetVertexColor(settings.MissingBlink.r, settings.MissingBlink.g, settings.MissingBlink.b)
        bar.bar1:SetAlpha(settings.MissingBlink.a)
    end
    bar.text:SetText(settings.blink_label)
    bar.time:Hide()
    bar.spark:Hide()
    bar.max_value = 1
    mfn_SetStatusBarValue(bar,bar.bar1,1)
    
    if ( bar.icon ) then
        bar.icon:Hide()
        NeedToKnow.SizeBackground(bar, false)
    end
    if ( bar.bar2 ) then
        bar.bar2:Hide()
    end
end

function NeedToKnow.GetUtilityTooltips()
    if ( not NeedToKnow_Tooltip1 ) then
        for idxTip = 1,2 do
            local ttname = "NeedToKnow_Tooltip"..idxTip
            local tt = CreateFrame("GameTooltip", ttname)
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt.left = {}
            tt.right = {}
            -- Most of the tooltip lines share the same text widget,
            -- But we need to query the third one for cooldown info
            for i = 1, 30 do
                tt.left[i] = tt:CreateFontString()
                tt.left[i]:SetFontObject(GameFontNormal)
                if i < 5 then
                    tt.right[i] = tt:CreateFontString()
                    tt.right[i]:SetFontObject(GameFontNormal)
                    tt:AddFontStrings(tt.left[i], tt.right[i])
                else
                    tt:AddFontStrings(tt.left[i], tt.right[4])
                end
            end 
         end
    end
    local tt1,tt2 = NeedToKnow_Tooltip1, NeedToKnow_Tooltip2
    
    tt1:ClearLines()
    tt2:ClearLines()
    return tt1,tt2
end

function NeedToKnow.DetermineTempEnchantFromTooltip(i_invID)
    local tt1,tt2 = NeedToKnow.GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end



-- Looks at the tooltip for the given spell to see if a cooldown 
-- is listed with a duration in seconds.  Longer cooldowns don't
-- need this logic, so we don't need to do unit conversion
function NeedToKnow.DetermineShortCooldownFromTooltip(spell)
    if not NeedToKnow.short_cds then
        NeedToKnow.short_cds = {}
    end
    if not NeedToKnow.short_cds[spell] then
        -- Figure out what a cooldown in seconds should look like
        local ref = SecondsToTime(10):lower()
        local unit_ref = ref:match("10 (.+)")

        -- Get the number and unit of the cooldown from the tooltip
        local tt1 = NeedToKnow.GetUtilityTooltips()
        local lnk = GetSpellLink(spell)
        local cd, n_cd, unit_cd
        if lnk and lnk ~= "" then
            tt1:SetHyperlink( lnk )
            
            for iTT=3,2,-1 do
                cd = tt1.right[iTT]:GetText()
                if cd then 
                    cd = cd:lower()
                    n_cd, unit_cd = cd:match("(%d+) (.+) ")
                end
                if n_cd then break end
            end
        end

        -- unit_ref will be "|4sec:sec;" in english, so do a find rather than a ==
        if not n_cd then 
            -- If we couldn't parse the tooltip, assume there's no cd
            NeedToKnow.short_cds[spell] = 0
        elseif unit_ref:find(unit_cd) then
            NeedToKnow.short_cds[spell] = tonumber(n_cd)
        else
            -- Not a short cooldown.  Record it as a minute
            NeedToKnow.short_cds[spell] = 60
        end
    end

    return NeedToKnow.short_cds[spell]
end


-- Search the player's spellbook for a spell that matches 
-- todo: cache this result?
function NeedToKnow.TryToFindSpellWithCD(barSpell)
    if NeedToKnow.DetermineShortCooldownFromTooltip(barSpell) > 0 then return barSpell end
    
    for iBook = 1, g_GetNumSpellTabs() do
        local sBook,_,iFirst,nSpells = g_GetSpellTabInfo(iBook)
        for iSpell=iFirst+1, iFirst+nSpells do
            local sName = g_GetSpellInfo(iSpell, sBook)
            if sName == barSpell then
                local sLink = GetSpellLink(iSpell, sBook)
                local sID = sLink:match("spell:(%d+)")
                local start = GetSpellCooldown(sID)
                if start then
                    local ttcd = NeedToKnow.DetermineShortCooldownFromTooltip(sID)
                    if ttcd and ttcd>0 then
                        return sID
                    end
                end
            end
        end
    end
end


function NeedToKnow.GetItemIDString(id_or_name)
    local _, link = GetItemInfo(id_or_name)
    if link then
        local idstring = link:match("item:(%d+):")
        if idstring then
            return idstring
        end
    end
end


-- Helper for mfn_AuraCheck_CASTCD which gets the autoshot cooldown
mfn_GetAutoShotCooldown = function(bar)
    local tNow = g_GetTime()
    if ( bar.tAutoShotStart and bar.tAutoShotStart + bar.tAutoShotCD > tNow ) then
        local n, _, icon = g_GetSpellInfo(75)
        return bar.tAutoShotStart, bar.tAutoShotCD, 1, c_AUTO_SHOT_NAME, icon
    else
        bar.tAutoShotStart = nil
    end
end


-- Helper for mfn_AuraCheck_CASTCD for names we haven't figured out yet
mfn_GetUnresolvedCooldown = function(bar, entry)
    NeedToKnow.SetupSpellCooldown(bar, entry)
    local fn = bar.cd_functions[entry.idxName]
    if mfn_GetUnresolvedCooldown ~= fn then
        return fn(bar, entry)
    end
end


-- Wrapper around GetSpellCooldown with extra sauce
-- Expected to return start, cd_len, enable, buffName, iconpath
mfn_GetSpellCooldown = function(bar, entry)
    local barSpell = entry.id or entry.name
    local start, cd_len, enable = GetSpellCooldown(barSpell)
    if start and start > 0 then
        local spellName, _, spellIconPath, _, _, _, spellId = g_GetSpellInfo(barSpell)
        if not spellName then 
            if not NeedToKnow.GSIBroken then 
                NeedToKnow.GSIBroken = {} 
            end
            if  not NeedToKnow.GSIBroken[barSpell] then
                print("NeedToKnow: Warning! Unable to get spell info for",barSpell,".  Try using Spell ID instead.")
                NeedToKnow.GSIBroken[barSpell] = true;
            end
            spellName = tostring(barSpell)
        end

        if 0 == enable then 
            -- Filter out conditions like Stealth while stealthed
            start = nil
        elseif NeedToKnow.is_DK == 1 then
		    local usesRunes=nil
		    local costInfo = g_GetSpellPowerCost(spellId)
			local nCosts = table.getn(costInfo)
			for iCost=1,nCosts do
			    if costInfo[iCost].type == SPELL_POWER_RUNES then  
				    usesRunes=true
				end
			end

			if ( usesRunes ) then
				-- Filter out rune cooldown artificially extending the cd
				if cd_len <= 10 then
					local tNow = g_GetTime()
					if bar.expirationTime and tNow < bar.expirationTime then
						-- We've already seen the correct CD for this; keep using it
						start = bar.expirationTime - bar.duration
						cd_len = bar.duration
					elseif m_last_sent and m_last_sent[spellName] and m_last_sent[spellName] > (tNow - 1.5) then
						-- We think the spell was just cast, and a CD just started but it's short.
						-- Look at the tooltip to tell what the correct CD should be. If it's supposed
						-- to be short (Ghoul Frenzy, Howling Blast), then start a CD bar
						cd_len = NeedToKnow.DetermineShortCooldownFromTooltip(barSpell)
						if cd_len == 0 or cd_len > 10 then
							start = nil
						end
					else
						start = nil
					end
				end
			end
        end
        
        if start then
            return start, cd_len, enable, spellName, spellIconPath
        end
    end
end



mfn_GetSpellChargesCooldown = function(bar, entry)
    local barSpell = entry.id or entry.name
    local cur, max, charge_start, recharge = GetSpellCharges(barSpell)
    if ( cur ~= max ) then
        local start, cd_len, enable, spellName, spellIconPath 
        if ( cur == 0 ) then
            start, cd_len, enable, spellName, spellIconPath = mfn_GetSpellCooldown(bar, entry)
            return start, cd_len, enable, spellName, spellIconPath, max, charge_start
        else
            local spellName, _, spellIconPath = g_GetSpellInfo(barSpell)
            if not spellName then spellName = barSpell end
            return charge_start, recharge, 1, spellName, spellIconPath, max-cur
        end
    end
end



-- Wrapper around GetItemCooldown
-- Expected to return start, cd_len, enable, buffName, iconpath
function NeedToKnow.GetItemCooldown(bar, entry)
    local start, cd_len, enable = GetItemCooldown(entry.id)
    if start then
        local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(entry.id)
        return start, cd_len, enable, name, icon
    end
end


mfn_AddInstanceToStacks = function (all_stacks, bar_entry, duration, name, count, expirationTime, iconPath, caster, tt1, tt2, tt3)
    if duration then
        if (not count or count < 1) then count = 1 end
        if ( 0 == all_stacks.total or all_stacks.min.expirationTime > expirationTime ) then
            all_stacks.min.idxName = bar_entry.idxName
            all_stacks.min.buffName = name
            all_stacks.min.caster = caster
            all_stacks.min.duration = duration
            all_stacks.min.expirationTime = expirationTime
            all_stacks.min.iconPath = iconPath
        end
        if ( 0 == all_stacks.total or all_stacks.max.expirationTime < expirationTime ) then
            all_stacks.max.duration = duration
            all_stacks.max.expirationTime = expirationTime
        end 
        all_stacks.total = all_stacks.total + count
        if ( tt1 ) then
            all_stacks.total_ttn[1] = all_stacks.total_ttn[1] + tt1
            if ( tt2 ) then
                all_stacks.total_ttn[2] = all_stacks.total_ttn[2] + tt2
            end
            if ( tt3 ) then
                all_stacks.total_ttn[3] = all_stacks.total_ttn[3] + tt3
            end
        end
    end
end


-- Bar_AuraCheck helper for Totem bars, this returns data if
-- a totem matching bar_entry is currently out. 
mfn_AuraCheck_TOTEM = function(bar, bar_entry, all_stacks)
    local idxName = bar_entry.idxName
    local sComp = bar_entry.name or g_GetSpellInfo(bar_entry.id)
    for iSlot=1, 4 do
        local haveTotem, totemName, startTime, totemDuration, totemIcon = GetTotemInfo(iSlot)
        if ( totemName and totemName:find(sComp) ) then
            -- WORKAROUND: The startTime reported here is both cast to an int and off by 
            -- a latency meaning it can be significantly low.  So we cache the g_GetTime 
            -- that the totem actually appeared, so long as g_GetTime is reasonably close to 
            -- startTime (since the totems may have been out for awhile before this runs.)
            if ( not NeedToKnow.totem_drops[iSlot] or 
                 NeedToKnow.totem_drops[iSlot] < startTime ) 
            then
                local precise = g_GetTime()
                if ( precise - startTime > 1 ) then
                    precise = startTime + 1
                end
                NeedToKnow.totem_drops[iSlot] = precise
            end

            mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                   totemDuration,                              -- duration
                   totemName,                                  -- name
                   1,                                          -- count
                   NeedToKnow.totem_drops[iSlot] + totemDuration, -- expiration time
                   totemIcon,                                  -- icon path
                   "player" )                                  -- caster
        end
    end
end




-- Bar_AuraCheck helper for tracking usable gear based on the slot its in
-- rather than the equipment name
mfn_AuraCheck_EQUIPSLOT = function (bar, bar_entry, all_stacks)
    local spellName, _, spellIconPath
    if ( bar_entry.id ) then
        local id = GetInventoryItemID("player",bar_entry.id)
        if id then
            local item_entry = m_scratch.bar_entry
            item_entry.id = id
            local start, cd_len, enable, name, icon = NeedToKnow.GetItemCooldown(bar, item_entry)

            if ( start and start > 0 ) then
                mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                       cd_len,                                     -- duration
                       name,                                       -- name
                       1,                                          -- count
                       start + cd_len,                             -- expiration time
                       icon,                                       -- icon path
                       "player" )                                  -- caster
            end
        end
    end
end



-- Bar_AuraCheck helper for power and combo points.  The current
-- amount is reported as the first tooltip number rather than 
-- stacks since 1 stack doesn't get displayed normally
mfn_AuraCheck_POWER = function (bar, bar_entry, all_stacks)
    local spellName, _, spellIconPath
    local cpt = UnitPowerType(bar.unit)
    local pt = bar_entry.id

    if ( pt ) then
        if pt == NEEDTOKNOW.SPELL_POWER_PRIMARY then pt = cpt end
        if (pt == NEEDTOKNOW.SPELL_POWER_LEGACY_CP) then pt = SPELL_POWER_COMBO_POINTS end

        local curPower, maxPower;
        if (pt == NEEDTOKNOW.SPELL_POWER_STAGGER ) then
		    curPower = UnitStagger(bar.unit)
			maxPower = UnitHealthMax(bar.unit)
        else
            curPower = UnitPower(bar.unit, pt)
            maxPower = UnitPowerMax(bar.unit, pt)
        end

        if ( maxPower and maxPower > 0 and
             (not bar.settings.power_sole or pt == cpt) ) 
        then
            local bTick = false
            if pt == 3 then -- SPELL_POWER_ENERGY
                if (pt == cpt) then
                    bar.power_regen = GetPowerRegen()
                end
                if (bar.power_regen and bar.power_regen > 0) then
                    bTick = true
                end
            end
            if bTick then
                if not bar.ticking then
                    bar.ticker = mfn_EnergyBar_OnUpdate
                    bar:SetScript("OnUpdate", bar.ticker)
                    bar.ticking = true
                end
            elseif bar.ticking then
                bar:SetScript("OnUpdate", nil)
                bar.ticking = false
            end

            if bar.ticking then                
                local now = g_GetTime()
                if not bar.tPower or now - bar.tPower > 2 or bar.last_power ~= curPower then
                    bar.tPower = now
                    bar.last_power = curPower
                    bar.last_power_max = maxPower

                end
            end

            mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                   0,                                          -- duration
                   NeedToKnow.GetPowerName(pt),                -- name
                   1,                                          -- count
                   0,                                          -- expiration time
                   nil,                                        -- icon path
                   bar.unit,                                   -- caster
                   curPower,                                   -- tooltip #1
                   maxPower,                                   -- tooltip #2
                   floor(curPower*1000/maxPower)/10 )          -- tooltip #3
        end
    end
end




-- Bar_AuraCheck helper that checks for spell/item use cooldowns
-- Relies on mfn_GetAutoShotCooldown, mfn_GetSpellCooldown 
-- and NeedToKnow.GetItemCooldown. Bar_Update will have already pre-processed 
-- this list so that bar.cd_functions[idxName] can do something with bar_entry
mfn_AuraCheck_CASTCD = function(bar, bar_entry, all_stacks)
    local idxName = bar_entry.idxName
    local func = bar.cd_functions[idxName]
    if ( not func ) then
        print("NTK ERROR setting up index",idxName,"on bar",bar:GetName(),bar.settings.AuraName);
        return;
    end
    local start, cd_len, should_cooldown, buffName, iconPath, stacks, start_2 = func(bar, bar_entry)

    -- filter out the GCD, we only care about actual spell CDs
    if start and cd_len <= 1.5 and func ~= mfn_GetAutoShotCooldown then
        if bar.expirationTime and bar.expirationTime <= (start + cd_len) then
            start = bar.expirationTime - bar.duration
            cd_len = bar.duration
        else
            start = nil
        end
    end

    if start and cd_len then
        local tNow = g_GetTime()
        local tEnd = start + cd_len
        if ( tEnd > tNow + 0.1 ) then
            if start_2 then
                mfn_AddInstanceToStacks( all_stacks, bar_entry,
                    cd_len,                                   -- duration
                    buffName,                                   -- name
                    1,                                          -- count
                    start_2+cd_len,                             -- expiration time
                    iconPath,                                   -- icon path
                    "player" )                                  -- caster
                stacks = stacks - 1
            else
                if not stacks then stacks = 1 end
            end
            mfn_AddInstanceToStacks( all_stacks, bar_entry,
                    cd_len,                                     -- duration
                    buffName,                                   -- name
                    stacks,                                     -- count
                    tEnd,                                       -- expiration time
                    iconPath,                                   -- icon path
                    "player" )                                  -- caster
        end
    end
end


-- Bar_AuraCheck helper for watching "Is Usable", which means that the action
-- bar button for the spell lights up.  This is mostly useful for Victory Rush
mfn_AuraCheck_USABLE = function (bar, bar_entry, all_stacks)
    local key = bar_entry.id or bar_entry.name
    local settings = bar.settings
    if ( not key ) then key = "" end
    local spellName, _, iconPath = g_GetSpellInfo(key)
    if ( spellName ) then
        local isUsable, notEnoughMana = IsUsableSpell(spellName)
        if (isUsable or notEnoughMana) then
            local duration = settings.usable_duration
            local expirationTime
            local tNow = g_GetTime()
            if ( not bar.expirationTime or 
                 (bar.expirationTime > 0 and bar.expirationTime < tNow - 0.01) ) 
            then
                duration = settings.usable_duration
                expirationTime = tNow + duration
            else
                duration = bar.duration
                expirationTime = bar.expirationTime
            end

            mfn_AddInstanceToStacks( all_stacks, bar_entry,
                   duration,                                   -- duration
                   spellName,                                  -- name
                   1,                                          -- count
                   expirationTime,                             -- expiration time
                   iconPath,                                   -- icon path
                   "player" )                                  -- caster
        end
    end
end


mfn_ResetScratchStacks = function (buff_stacks)
    buff_stacks.total = 0;
    buff_stacks.total_ttn[1] = 0;
    buff_stacks.total_ttn[2] = 0;
    buff_stacks.total_ttn[3] = 0;
end

-- Bar_AuraCheck helper for watching "internal cooldowns", which is like a spell
-- cooldown for spells cast automatically (procs).  The "reset on buff" logic
-- is still handled by 
mfn_AuraCheck_BUFFCD = function (bar, bar_entry, all_stacks)
    local buff_stacks = m_scratch.buff_stacks
    mfn_ResetScratchStacks(buff_stacks);
    mfn_AuraCheck_Single(bar, bar_entry, buff_stacks)
    local tNow = g_GetTime()
    if ( buff_stacks.total > 0 ) then
        if buff_stacks.max.expirationTime == 0 then
            -- TODO: This really doesn't work very well as a substitute for telling when the aura was applied
            if not bar.expirationTime then
                local nDur = tonumber(bar.settings.buffcd_duration)
                mfn_AddInstanceToStacks( all_stacks, bar_entry,
                    nDur, buff_stacks.min.buffName, 1, nDur+tNow, buff_stacks.min.iconPath, buff_stacks.min.caster )
            else
                mfn_AddInstanceToStacks( all_stacks, bar_entry,
                       bar.duration,                               -- duration
                       bar.buffName,                               -- name
                       1,                                          -- count
                       bar.expirationTime,                         -- expiration time
                       bar.iconPath,                               -- icon path
                       "player" )                                  -- caster
            end
            return
        end
        local tStart = buff_stacks.max.expirationTime - buff_stacks.max.duration
        local duration = tonumber(bar.settings.buffcd_duration)
        local expiration = tStart + duration
        if ( expiration > tNow ) then
            mfn_AddInstanceToStacks( all_stacks, bar_entry,
                   duration,                                   -- duration
                   buff_stacks.min.buffName,                                   -- name
                   -- Seeing the charges on the CD bar violated least surprise for me
                   1,                                          -- count
                   expiration,                                 -- expiration time
                   buff_stacks.min.iconPath,                   -- icon path
                   buff_stacks.min.caster )                    -- caster
        end
    elseif ( bar.expirationTime and bar.expirationTime > tNow + 0.1 ) then
        mfn_AddInstanceToStacks( all_stacks, bar_entry,
               bar.duration,                               -- duration
               bar.buffName,                               -- name
               1,                                          -- count
               bar.expirationTime,                         -- expiration time
               bar.iconPath,                               -- icon path
               "player" )                                  -- caster
    end
end

local function UnitAuraWrapper(a,b,c,d)
     local
        name,  
        -- _, -- rank,  
        icon,
        count,  
        _, -- type,
        dur,
        expiry,
        caster,
        _, -- uao.steal,
        _, -- uao.cons -- Should consolidate
        id,
        _, -- uao.canCast -- The player's class/spec can cast this spell
        _, -- A boss applied this
        _, -- cast by any player
		_, -- nameplate show all
		_, -- time mod
        v1,
        v2,
        v3
    = UnitAura(a,b,c,d)

    if name then
        return name, icon, count, dur, expiry, caster, id, v1, v2, v3
    end
end

-- Bar_AuraCheck helper that looks for the first instance of a buff
-- Uses the UnitAura filters exclusively if it can
mfn_AuraCheck_Single = function(bar, bar_entry, all_stacks)
    local settings = bar.settings
    local filter = settings.BuffOrDebuff
    if settings.OnlyMine then
        filter = filter .. "|PLAYER"
    end

    if bar_entry.id then
        -- WORKAROUND: The second parameter to UnitAura can't be a spellid, so I have 
        --             to walk them all
        local barID = bar_entry.id
        local j = 1
        while true do
            local buffName, iconPath, count, duration, expirationTime, caster, spellID, tt1, tt2, tt3
              = UnitAuraWrapper(bar.unit, j, filter)
            if (not buffName) then
                break
            end

            if (spellID == barID) then 
                mfn_AddInstanceToStacks( all_stacks, bar_entry,
                       duration,                               -- duration
                       buffName,                               -- name
                       count,                                  -- count
                       expirationTime,                         -- expiration time
                       iconPath,                               -- icon path
                       caster,                                 -- caster
                       tt1, tt2, tt3 )                         -- extra status values, like vengeance armor or healing bo
                return;
            end
            j=j+1
        end
    else
        --[[
        -- UnitAura() no longer supports querying by spell name 
        local buffName, iconPath, count, duration, expirationTime, caster, _, tt1, tt2, tt3 
          = UnitAuraWrapper(bar.unit, bar_entry.name, nil, filter)
          mfn_AddInstanceToStacks( all_stacks, bar_entry,
               duration,                               -- duration
               buffName,                               -- name
               count,                                  -- count
               expirationTime,                         -- expiration time
               iconPath,                               -- icon path
               caster,                                 -- caster
               tt1, tt2, tt3 )                         -- extra status values, like vengeance armor or healing bo
        ]]--
        -- TODO: Use AuraUtil.FindAuraByName in FrameXML/AuraUtil.lua (added in 8.0)
        local j = 1
        while true do
            local buffName, iconPath, count, duration, expirationTime, caster, spellID, tt1, tt2, tt3
              = UnitAuraWrapper(bar.unit, j, filter)
            if (not buffName) then
                break
            end

            if (buffName == bar_entry.name) then 
                mfn_AddInstanceToStacks( all_stacks, bar_entry,
                       duration,                               -- duration
                       buffName,                               -- name
                       count,                                  -- count
                       expirationTime,                         -- expiration time
                       iconPath,                               -- icon path
                       caster,                                 -- caster
                       tt1, tt2, tt3 )                         -- extra status values, like vengeance armor or healing bo
                return;
            end
            j=j+1
        end
    end
end


-- Bar_AuraCheck helper that updates bar.all_stacks (but returns nil)
-- by scanning all the auras on the unit
mfn_AuraCheck_AllStacks = function (bar, bar_entry, all_stacks)
    local j = 1
    local settings = bar.settings
    local filter = settings.BuffOrDebuff
    
    while true do
        local buffName, iconPath, count, duration, expirationTime, caster, spellID, tt1, tt2, tt3
          = UnitAuraWrapper(bar.unit, j, filter)
        if (not buffName) then
            break
        end
        
        if (spellID == bar_entry.id) or (bar_entry.name == buffName) 
        then
            mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                duration,
                buffName,
                count,
                expirationTime,
                iconPath,
                caster,
                tt1, tt2, tt3 )
        end

        j = j+1
    end
end


-- Called whenever the state of auras on the bar's unit may have changed
local g_UnitExists = UnitExists
mfn_Bar_AuraCheck = function (bar)
    local settings = bar.settings
    local bUnitExists
    if "player" == settings.Unit then
        bUnitExists = true
    elseif "lastraid" == settings.Unit then
        bUnitExists = bar.unit and UnitExists(bar.unit)
    else
        bUnitExists = g_UnitExists(settings.Unit)
    end
    
    -- Determine if the bar should be showing anything
    local all_stacks       
    local idxName, duration, buffName, count, expirationTime, iconPath, caster
    if ( bUnitExists ) then
        all_stacks = m_scratch.all_stacks
        mfn_ResetScratchStacks(all_stacks);

        -- Call the helper function for each of the spells in the list
        for idx, entry in ipairs(bar.spells) do
            bar.fnCheck(bar, entry, all_stacks);
            
            if all_stacks.total > 0 and not settings.show_all_stacks then
                idxName = idx
                break 
            end
        end
    end
    
    if ( all_stacks and all_stacks.total > 0 ) then
        idxName = all_stacks.min.idxName
        buffName = all_stacks.min.buffName
        caster = all_stacks.min.caster
        duration = all_stacks.max.duration
        expirationTime = all_stacks.min.expirationTime
        iconPath = all_stacks.min.iconPath
        count = all_stacks.total
    end

    -- Cancel the work done above if a reset spell is encountered
    -- (reset_spells will only be set for BUFFCD)
    if ( bar.reset_spells ) then
        local maxStart = 0
        local tNow = g_GetTime()
        local buff_stacks = m_scratch.buff_stacks
        mfn_ResetScratchStacks(buff_stacks);
        -- Keep track of when the reset auras were last applied to the player
        for idx, resetSpell in ipairs(bar.reset_spells) do
            -- Note this relies on BUFFCD setting the target to player, and that the onlyMine will work either way
            local resetDuration, _, _, resetExpiration
              = mfn_AuraCheck_Single(bar, resetSpell, buff_stacks)
            local tStart
            if buff_stacks.total > 0 then
               if 0 == buff_stacks.max.duration then 
                   tStart = bar.reset_start[idx]
                   if 0 == tStart then
                       tStart = tNow
                   end
               else
                   tStart = buff_stacks.max.expirationTime - buff_stacks.max.duration
               end
               bar.reset_start[idx] = tStart
               
               if tStart > maxStart then maxStart = tStart end
            else
               bar.reset_start[idx] = 0
            end
        end
        if duration and maxStart > expirationTime-duration then
            duration = nil
        end
    end
    
    -- There is an aura this bar is watching! Set it up
    if ( duration ) then
        duration = tonumber(duration)
        -- Handle duration increases
        local extended
        if (settings.bDetectExtends) then
            local curStart = expirationTime - duration
            local guidTarget = UnitGUID(bar.unit)
            local r = m_last_guid[buffName] 
            
            if ( not r[guidTarget] ) then -- Should only happen from /reload or /ntk while the aura is active
                -- This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
                --trace("WARNING! allocating guid slot for ", buffName, "on", guidTarget, "due to UNIT_AURA");
                r[guidTarget] = { time=curStart, dur=duration, expiry=expirationTime }
            else
                r = r[guidTarget]
                local oldExpiry = r.expiry
                -- This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
                --if ( oldExpiry > 0 and oldExpiry < curStart ) then
                    --trace("WARNING! stale entry for ",buffName,"on",guidTarget,curStart-r.time,curStart-oldExpiry)
                --end

                if ( oldExpiry < curStart ) then
                    r.time = curStart
                    r.dur = duration 
                    r.expiry= expirationTime
                else
                    r.expiry= expirationTime
                    extended =  expirationTime - (r.time + r.dur)
                    if ( extended > 1 ) then
                        duration = r.dur 
                    else
                        extended = nil
                    end
                end
            end
        end

        --bar.duration = tonumber(bar.fixedDuration) or duration
        bar.duration = duration

        bar.expirationTime = expirationTime
        bar.idxName = idxName
        bar.buffName = buffName
        bar.iconPath = iconPath
        if ( all_stacks and all_stacks.max.expirationTime ~= expirationTime ) then
            bar.max_expirationTime = all_stacks.max.expirationTime
        else
            bar.max_expirationTime = nil
        end

        -- Mark the bar as not blinking before calling ConfigureVisibleBar, 
        -- since it calls OnUpdate which checks bar.blink
        bar.blink=false
        NeedToKnow.ConfigureVisibleBar(bar, count, extended, all_stacks)
        bar:Show()
    else
        if (settings.bDetectExtends and bar.buffName) then
            local r = m_last_guid[bar.buffName]
            if ( r ) then
                local guidTarget = UnitGUID(bar.unit)
                if guidTarget then
                    r[guidTarget] = nil
                end
            end
        end
        bar.buffName = nil
        bar.duration = nil
        bar.expirationTime = nil
        
        local bBlink = false
        if settings.blink_enabled and settings.MissingBlink.a > 0 then
            bBlink = bUnitExists and not UnitIsDead(bar.unit)
        end
        if ( bBlink and not settings.blink_ooc ) then
            if not g_UnitAffectingCombat("player") then
                bBlink = false
            end
        end
        if ( bBlink and settings.blink_boss ) then
            if g_UnitIsFriend(bar.unit, "player") then
                bBlink = m_bCombatWithBoss
            else
                bBlink = (UnitLevel(bar.unit) == -1)
            end
        end
        if ( bBlink ) then
            NeedToKnow.ConfigureBlinkingBar(bar)
            bar:Show()
        else    
            bar.blink=false
            bar:Hide()
        end
    end
end


function NeedToKnow.Fmt_SingleUnit(i_fSeconds)
    return string.format(SecondsToTimeAbbrev(i_fSeconds))
end


function NeedToKnow.Fmt_TwoUnits(i_fSeconds)
  if ( i_fSeconds < 6040 ) then
      local nMinutes, nSeconds
      nMinutes = floor(i_fSeconds / 60)
      nSeconds = floor(i_fSeconds - nMinutes*60)
      return string.format("%02d:%02d", nMinutes, nSeconds)
  else
      string.format(SecondsToTimeAbbrev(i_fSeconds))
  end
end

function NeedToKnow.Fmt_Float(i_fSeconds)
  return string.format("%0.1f", i_fSeconds)
end

function NeedToKnow.Bar_OnUpdate(self, elapsed)
    local now = g_GetTime()
    if ( now > self.nextUpdate ) then
        self.nextUpdate = now + c_UPDATE_INTERVAL

        if ( self.blink ) then
            self.blink_phase = self.blink_phase + c_UPDATE_INTERVAL
            if ( self.blink_phase >= 2 ) then
                self.blink_phase = 0
            end
            local a = self.blink_phase
            if ( a > 1 ) then
                a = 2 - a
            end

            self.bar1:SetVertexColor(self.settings.MissingBlink.r, self.settings.MissingBlink.g, self.settings.MissingBlink.b)
            self.bar1:SetAlpha(self.settings.MissingBlink.a * a)
            return
        end
        
        -- WORKAROUND: Some of these (like item cooldowns) don't fire an event when the CD expires.
        --   others fire the event too soon.  So we have to keep checking.
        if ( self.duration and self.duration > 0 ) then
            local duration = self.fixedDuration or self.duration
            local bar1_timeLeft = self.expirationTime - g_GetTime()
            if ( bar1_timeLeft < 0 ) then
                if ( self.settings.BuffOrDebuff == "CASTCD" or
                     self.settings.BuffOrDebuff == "BUFFCD" or
                     self.settings.BuffOrDebuff == "EQUIPSLOT" )
                then
                    mfn_Bar_AuraCheck(self)
                    return
                end
                bar1_timeLeft = 0
            end
            mfn_SetStatusBarValue(self, self.bar1, bar1_timeLeft);
            if ( self.settings.show_time ) then
                local fn = NeedToKnow[self.settings.TimeFormat]
                local oldText = self.time:GetText()
                local newText
                if ( fn ) then
                    newText = fn(bar1_timeLeft)
                else 
                    newText = string.format(SecondsToTimeAbbrev(bar1_timeLeft))
                end
                
                if ( newText ~= oldText ) then
                    self.time:SetText(newText)
                end
            else
                self.time:SetText("")
            end
            
            if ( self.settings.show_spark and bar1_timeLeft <= duration ) then
                self.spark:SetPoint("CENTER", self, "LEFT", self:GetWidth()*bar1_timeLeft/duration, 0)
                self.spark:Show()
            else
                self.spark:Hide()
            end
            
            if ( self.max_expirationTime ) then
                local bar2_timeLeft = self.max_expirationTime - g_GetTime()
                mfn_SetStatusBarValue(self, self.bar2, bar2_timeLeft, bar1_timeLeft)
            end
            
            if ( self.vct_refresh ) then
                mfn_UpdateVCT(self)
            end
        end
    end
end 


mfn_EnergyBar_OnUpdate = function(bar, elapsed)
    local now = g_GetTime()
    if ( now > bar.nextUpdate ) then
        bar.nextUpdate = now + c_UPDATE_INTERVAL
        local delta = now - bar.tPower
        local predicted = bar.last_power + bar.power_regen * delta
        local bCapped = false
        if predicted >= bar.last_power_max then
            predicted = bar.last_power_max
            bCapped = true
        elseif predicted <= 0 then
            predicted = 0
            bCapped = true
        end

        bar.max_value = bar.last_power_max
        mfn_SetStatusBarValue(bar, bar.bar1, predicted);

        if bCapped then
            bar.ticking = false
            bar:SetScript("OnUpdate", nil)
        end
    end
end




-- Define the event dispatching table.  Note, this comes last as the referenced 
-- functions must already be declared.  Avoiding the re-evaluation of all that
-- is one of the reasons this is an optimization!
local fnAuraCheckIfUnitMatches = function(self, unit)
    if ( unit == self.unit )  then
        mfn_Bar_AuraCheck(self)
    end
end

local fnAuraCheckIfUnitPlayer = function(self, unit)
    if ( unit == "player" ) then
        mfn_Bar_AuraCheck(self)
    end
end

local EDT = {}
EDT["COMBAT_LOG_EVENT_UNFILTERED"] = function(self, unit, ...)
    -- local combatEvent = select(1, ...)
    local tod, event, hideCaster, guidCaster, sourceName, sourceFlags, sourceRaidFlags, guidTarget, nameTarget, _, _, spellid, spell = CombatLogGetCurrentEventInfo()

    if ( c_AURAEVENTS[combatEvent] ) then
        -- local guidTarget = select(7, ...)
        if ( guidTarget == g_UnitGUID(self.unit) ) then
            -- local idSpell, nameSpell = select(11, ...)
            if (self.auraName:find(idSpell) or
                    self.auraName:find(nameSpell)) 
            then 
                mfn_Bar_AuraCheck(self)
            end
        end
    elseif ( combatEvent == "UNIT_DIED" ) then
        -- local guidDeceased = select(7, ...) 
        -- if ( guidDeceased == UnitGUID(self.unit) ) then
        if ( guidTarget == UnitGUID(self.unit) ) then
            mfn_Bar_AuraCheck(self)
        end
    end 
end
EDT["PLAYER_TOTEM_UPDATE"] = mfn_Bar_AuraCheck
EDT["ACTIONBAR_UPDATE_COOLDOWN"] = mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_COOLDOWN"] = mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_USABLE"] = mfn_Bar_AuraCheck
EDT["UNIT_AURA"] = fnAuraCheckIfUnitMatches
-- EDT["UNIT_POWER"] = fnAuraCheckIfUnitMatches
-- EDT["UNIT_DISPLAYPOWER"] = fnAuraCheckIfUnitMatches
EDT["UNIT_HEALTH"] = mfn_Bar_AuraCheck
EDT["PLAYER_TARGET_CHANGED"] = function(self, unit)
    if self.unit == "targettarget" then
        NeedToKnow.CheckCombatLogRegistration(self)
    end
    mfn_Bar_AuraCheck(self)
end  
EDT["PLAYER_FOCUS_CHANGED"] = EDT["PLAYER_TARGET_CHANGED"]
EDT["UNIT_TARGET"] = function(self, unit)
    if unit == "target" and self.unit == "targettarget" then
        NeedToKnow.CheckCombatLogRegistration(self)
    end
    mfn_Bar_AuraCheck(self)
end  
EDT["UNIT_PET"] = fnAuraCheckIfUnitPlayer
EDT["PLAYER_SPELLCAST_SUCCEEDED"] = function(self, unit, ...)
    local spellName, spellID, tgt = select(1,...)
    local i,entry
    for i,entry in ipairs(self.spells) do
        if entry.id == spellID or entry.name == spellName then
            self.unit = tgt or "unknown"
            --trace("Updating",self:GetName(),"since it was recast on",self.unit)
            mfn_Bar_AuraCheck(self)
            break;
        end
    end
end
EDT["START_AUTOREPEAT_SPELL"] = function(self, unit, ...)
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
EDT["STOP_AUTOREPEAT_SPELL"] = function(self, unit, ...)
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
EDT["UNIT_SPELLCAST_SUCCEEDED"] = function(self, unit, ...)
    -- local spell = select(1,...)
    local spellID  = select(2, ...)
    local spellName = select(1, GetSpellInfo(spellId))
    if ( self.settings.bAutoShot and unit == "player" and spellName == c_AUTO_SHOT_NAME ) then
        local interval = UnitRangedDamage("player")
        self.tAutoShotCD = interval
        self.tAutoShotStart = g_GetTime()
        mfn_Bar_AuraCheck(self)
    end
end

function NeedToKnow.Bar_OnEvent(self, event, unit, ...)
    local fn = EDT[event]
    if fn then 
        fn(self, unit, ...)
    end
end

function NeedToKnow.GetPowerName(pt)
    local name = NEEDTOKNOW.POWER_TYPES[pt]
	if not name then 
	    print("NeedToKnow: Could not find power", pt)
	    return tostring(pt)
	end
	return name
end