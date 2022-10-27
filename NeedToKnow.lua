-- --------------------------------
-- NeedToKnow
-- by Kitjan, NephMakes/lieandswell
-- --------------------------------

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar
local Cooldown = NeedToKnow.Cooldown

local trace = print

-- -------------
-- ADDON MEMBERS
-- -------------

-- Define local versions of global functions
local g_UnitExists = UnitExists
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

local m_last_cast       = addonTable.m_last_cast
local m_last_cast_head  = addonTable.m_last_cast_head
local m_last_cast_tail  = addonTable.m_last_cast_tail
local m_last_guid       = addonTable.m_last_guid
local m_bInCombat       = addonTable.m_bInCombat
local m_bCombatWithBoss = addonTable.m_bCombatWithBoss
-- local m_last_guid, m_last_cast, m_last_sent, m_last_cast_head, m_last_cast_tail
-- local m_bInCombat, m_bCombatWithBoss

local mfn_GetSpellCooldown        = Cooldown.GetSpellCooldown
local mfn_GetSpellChargesCooldown = Cooldown.GetSpellChargesCooldown
local mfn_GetAutoShotCooldown     = Cooldown.GetAutoShotCooldown
local mfn_GetUnresolvedCooldown   = Cooldown.GetUnresolvedCooldown

-- local mfn_SetStatusBarValue
local mfn_Bar_AuraCheck = addonTable.mfn_Bar_AuraCheck
-- local mfn_Bar_AuraCheck
local mfn_AuraCheck_Single
local mfn_AuraCheck_TOTEM
local mfn_AuraCheck_BUFFCD
local mfn_AuraCheck_USABLE
local mfn_AuraCheck_EQUIPSLOT
local mfn_AuraCheck_CASTCD
local mfn_AuraCheck_AllStacks
local mfn_AddInstanceToStacks
local mfn_ResetScratchStacks
local mfn_UpdateVCT

local m_scratch = {}
m_scratch.all_stacks = {
	min = {
		buffName = "", 
		duration = 0, 
		expirationTime = 0, 
		iconPath = "",
		caster = ""
	},
	max = {
		duration = 0, 
		expirationTime = 0, 
	},
	total = 0,
	total_ttn = { 0, 0, 0 }
}
m_scratch.buff_stacks = {
	min = {
		buffName = "", 
		duration = 0, 
		expirationTime = 0, 
		iconPath = "",
		caster = ""
	},
	max = {
		duration = 0, 
		expirationTime = 0, 
	},
	total = 0,
	total_ttn = { 0, 0, 0 }
}
m_scratch.bar_entry = {
	idxName = 0,
	barSpell = "",
	isSpellID = false,
}

local c_UPDATE_INTERVAL = 0.03  -- equivalent to ~33 frames per second
local c_MAXBARS = 20
local c_AUTO_SHOT_NAME = g_GetSpellInfo(75) -- Localized name for Auto Shot

-- COMBAT_LOG_EVENT_UNFILTERED events where select(6,...) is the caster, 
-- 9 is the spellid, and 10 is the spell name. 
-- Used for Target-of-target monitoring. 
local c_AURAEVENTS = {
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true
}
    

-- ----
-- BARS
-- ----

function NeedToKnow.Bar_Update(groupID, barID)
    -- Called when the configuration of the bar has changed, when the addon
    -- is loaded, and when locked and unlocked
	-- Called by BarGroup:Update() and various BarMenu:Methods()

    local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

    local barName = "NeedToKnow_Group"..groupID.."Bar"..barID
    local bar = _G[barName]
    if not bar then
        -- Kitjan: New bar added in the UI; need to create it!
        -- NephMakes: Wouldn't this be covered by BarGroup:Update()? 

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

    local barSettings = groupSettings["Bars"][barID]
    if ( not barSettings ) then
        --trace("Adding bar settings for", groupID, barID)
        barSettings = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
        groupSettings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
    end
    bar.settings = barSettings

	bar.icon  = bar.Icon
	bar.spark = bar.Spark
    bar.text  = bar.Text
    bar.time  = bar.Time
    bar.bar1  = bar.Texture
    bar.bar2  = bar.Texture2
	bar.vct   = bar.CastTime
	-- want to not need these eventually

    bar.auraName = barSettings.AuraName
    
    if ( barSettings.BuffOrDebuff == "BUFFCD" or
         barSettings.BuffOrDebuff == "TOTEM" or
         barSettings.BuffOrDebuff == "USABLE" or
         barSettings.BuffOrDebuff == "EQUIPSLOT" or
         barSettings.BuffOrDebuff == "CASTCD" ) 
    then
        barSettings.Unit = "player"
    end

    bar.unit = barSettings.Unit
    bar.nextUpdate = g_GetTime() + c_UPDATE_INTERVAL

    bar.fixedDuration = tonumber(groupSettings.FixedDuration)
    if ( not bar.fixedDuration or 0 >= bar.fixedDuration ) then
        bar.fixedDuration = nil
    end

    bar.max_value = 1
    bar:SetValue(bar.bar1, 1)

	bar:SetAppearance()

    if ( NeedToKnow.CharSettings["Locked"] ) then
        local enabled = groupSettings.Enabled and barSettings.Enabled
        if ( enabled ) then
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
            --[[
            elseif "POWER" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_POWER
                bar.is_counter = true
                bar.ticker = nil
                bar.ticking = false
            ]]--
            elseif "CASTCD" == barSettings.BuffOrDebuff then
                bar.fnCheck = mfn_AuraCheck_CASTCD
                for idx, entry in ipairs(bar.spells) do
                    table.insert(bar.cd_functions, mfn_GetSpellCooldown)
                    Cooldown.SetUpSpell(bar, entry)
                end
            elseif barSettings.show_all_stacks then
                bar.fnCheck = mfn_AuraCheck_AllStacks
            else
                bar.fnCheck = mfn_AuraCheck_Single
            end
        
            if ( barSettings.BuffOrDebuff == "BUFFCD" ) then
                local dur = tonumber(barSettings.buffcd_duration)
                if (not dur or dur < 1) then
                    -- print("NeedToKnow: Internal cooldown bar watching", barSettings.AuraName, "did not set a cooldown duration. Disabling the bar.")
                    print("NeedToKnow: Please set internal cooldown duration for:", barSettings.AuraName)
                    enabled = false
                end
            end
        
            bar:SetScripts()
            -- Events were cleared while unlocked, so need to check the bar again now
            mfn_Bar_AuraCheck(bar)
        else
            bar:ClearScripts()
            bar:Hide()
        end
    else
        bar:ClearScripts()
		bar:Unlock()
    end
end

function NeedToKnow.ComputeBarText(buffName, count, extended, buff_stacks, bar)
    -- AuraCheck calls on this to compute the "text" of the bar
    -- It is separated out like this in part to be hooked by other addons
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

function NeedToKnow.ComputeVCTDuration(bar)
    -- Called by mfn_UpdateVCT, which is called from AuraCheck and possibly 
    -- by Bar_OnUpdate depending on vct_refresh. In addition to refactoring out some 
    -- code from the long AuraCheck, this also provides a convenient hook for other addons

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

function NeedToKnow.PrettyName(barSettings)
    if ( barSettings.BuffOrDebuff == "EQUIPSLOT" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NEEDTOKNOW.ITEM_NAMES[idx] end
        return ""
    --[[  
    -- Player power no longer supported
    elseif ( barSettings.BuffOrDebuff == "POWER" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NeedToKnow.GetPowerName(idx) end
        return ""
    ]]--
    else
        return barSettings.AuraName
    end
end

function NeedToKnow.ConfigureVisibleBar(bar, count, extended, buff_stacks)
	-- Called by mfn_Bar_AuraCheck(bar) if bar.duration found

    local text = ""
    
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

        bar.Time:Show()
    --[[
    elseif bar.is_counter then
    	-- Bar is tracking player power?

        bar.max_value = 1
        local pct = buff_stacks.total_ttn[1] / buff_stacks.total_ttn[2]
        mfn_SetStatusBarValue(bar,bar.bar1,pct)
        if bar.bar2 then mfn_SetStatusBarValue(bar,bar.bar2,pct) end

        bar.time:Hide()
        bar.spark:Hide()

        if ( bar.vct ) then
            bar.vct:Hide()
        end
    ]]--
    else
        -- Hide time, text, and spark for auras with infinite duration
        bar.max_value = 1
		bar:SetValue(bar.Texture, 1)
		bar:SetValue(bar.Texture2, 1)
        bar.Time:Hide()
        bar.Spark:Hide()
        bar.CastTime:Hide()
    end
end

-- NephMakes: I don't think temporary enchants aren't a thing anymore, 
-- but keep this for potential use in WoW Classic
--[[
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
]]--

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

mfn_AuraCheck_TOTEM = function(bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper for Totem bars, this returns data if
    -- a totem matching bar_entry is currently out. 
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

mfn_AuraCheck_EQUIPSLOT = function (bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper for tracking usable gear based on the slot its in
    -- rather than the equipment name
    local spellName, _, spellIconPath
    if ( bar_entry.id ) then
        local id = GetInventoryItemID("player",bar_entry.id)
        if id then
            local item_entry = m_scratch.bar_entry
            item_entry.id = id
            -- local start, cd_len, enable, name, icon = NeedToKnow.GetItemCooldown(bar, item_entry)
            local start, cd_len, enable, name, icon = Cooldown.GetItemCooldown(bar, item_entry)
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

mfn_AuraCheck_CASTCD = function(bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper that checks for spell/item use cooldowns
    -- Relies on mfn_GetAutoShotCooldown, mfn_GetSpellCooldown 
    -- and NeedToKnow.GetItemCooldown. Bar_Update will have already pre-processed 
    -- this list so that bar.cd_functions[idxName] can do something with bar_entry

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

mfn_AuraCheck_USABLE = function (bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper for watching "Is Usable", which means that the action
    -- bar button for the spell lights up.  This is mostly useful for Victory Rush
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

mfn_AuraCheck_Single = function(bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper that looks for the first instance of a buff
    -- Uses the UnitAura filters exclusively if it can

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

mfn_AuraCheck_AllStacks = function (bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper that updates bar.all_stacks (but returns nil)
    -- by scanning all the auras on the unit

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

mfn_Bar_AuraCheck = function (bar)
    -- Called whenever the state of auras on the bar's unit may have changed

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
        bar.blink = false
        bar:UpdateAppearance()
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
            bar:StartBlink()
            bar:Show()
        else    
            bar.blink = false
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
            -- mfn_SetStatusBarValue(self, self.bar1, bar1_timeLeft);
            self:SetValue(self.bar1, bar1_timeLeft);
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
                -- mfn_SetStatusBarValue(self, self.bar2, bar2_timeLeft, bar1_timeLeft)
                self:SetValue(self.bar2, bar2_timeLeft, bar1_timeLeft)
            end
            
            if ( self.vct_refresh ) then
                mfn_UpdateVCT(self)
            end
        end
    end
end 

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

-- Define the event dispatching table.  Note, this comes last as the referenced 
-- functions must already be declared.  Avoiding the re-evaluation of all that
-- is one of the reasons this is an optimization!
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
        -- NeedToKnow.CheckCombatLogRegistration(self)
        self:CheckCombatLogRegistration()
    end
    mfn_Bar_AuraCheck(self)
end  
EDT["PLAYER_FOCUS_CHANGED"] = EDT["PLAYER_TARGET_CHANGED"]
EDT["UNIT_TARGET"] = function(self, unit)
    if unit == "target" and self.unit == "targettarget" then
        -- NeedToKnow.CheckCombatLogRegistration(self)
        self:CheckCombatLogRegistration()
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

