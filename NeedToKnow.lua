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

-- Local versions of global functions
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

local m_last_guid       = addonTable.m_last_guid
local m_bCombatWithBoss = addonTable.m_bCombatWithBoss

local mfn_GetSpellCooldown        = Cooldown.GetSpellCooldown
local mfn_GetSpellChargesCooldown = Cooldown.GetSpellChargesCooldown
local mfn_GetAutoShotCooldown     = Cooldown.GetAutoShotCooldown
local mfn_GetUnresolvedCooldown   = Cooldown.GetUnresolvedCooldown

-- Kitjan used m_scratch to track multiple instances of an aura with one bar
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
    

-- ------------------
-- Kitjan's functions
-- ------------------

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
            local idx = bar.idxName
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
    -- local vct_width = 0
    if ( not bar.is_counter and bar.duration > 0 ) then
        -- Configure the main status bar
        local duration = bar.fixedDuration or bar.duration
        bar.max_value = duration

        -- Set CastTime size
        if ( bar.settings.vct_enabled ) then
            bar:UpdateCastTime()
        end
        
        -- Force an update to get all the bars to the current position (sharing code)
        -- This will call UpdateCastTime again, but that seems ok
        bar.nextUpdate = -c_UPDATE_INTERVAL
        if bar.expirationTime > g_GetTime() then
            NeedToKnow.Bar_OnUpdate(bar, 0)
        end

        bar.Time:Show()
--    elseif bar.is_counter then
--    	-- Bar is tracking player power?
--
--        bar.max_value = 1
--        local pct = buff_stacks.total_ttn[1] / buff_stacks.total_ttn[2]
--        mfn_SetStatusBarValue(bar,bar.bar1,pct)
--        if bar.bar2 then mfn_SetStatusBarValue(bar,bar.bar2,pct) end
--
--        bar.time:Hide()
--        bar.spark:Hide()
--
--        if ( bar.vct ) then
--            bar.vct:Hide()
--        end
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

function NeedToKnow.mfn_AddInstanceToStacks(all_stacks, bar_entry, duration, name, count, expirationTime, iconPath, caster, tt1, tt2, tt3)
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

function NeedToKnow.mfn_AuraCheck_TOTEM(bar, bar_entry, all_stacks)
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
            NeedToKnow.mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                   totemDuration,                              -- duration
                   totemName,                                  -- name
                   1,                                          -- count
                   NeedToKnow.totem_drops[iSlot] + totemDuration, -- expiration time
                   totemIcon,                                  -- icon path
                   "player" )                                  -- caster
        end
    end
end

function NeedToKnow.mfn_AuraCheck_EQUIPSLOT(bar, bar_entry, all_stacks)
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
                NeedToKnow.mfn_AddInstanceToStacks(all_stacks, bar_entry, 
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

function NeedToKnow.mfn_AuraCheck_CASTCD(bar, bar_entry, all_stacks)
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
                NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
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
            NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
                    cd_len,                                     -- duration
                    buffName,                                   -- name
                    stacks,                                     -- count
                    tEnd,                                       -- expiration time
                    iconPath,                                   -- icon path
                    "player" )                                  -- caster
        end
    end
end

function NeedToKnow.mfn_AuraCheck_USABLE(bar, bar_entry, all_stacks)
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

            NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
                   duration,                                   -- duration
                   spellName,                                  -- name
                   1,                                          -- count
                   expirationTime,                             -- expiration time
                   iconPath,                                   -- icon path
                   "player" )                                  -- caster
        end
    end
end

function NeedToKnow.mfn_ResetScratchStacks(buff_stacks)
    buff_stacks.total = 0;
    buff_stacks.total_ttn[1] = 0;
    buff_stacks.total_ttn[2] = 0;
    buff_stacks.total_ttn[3] = 0;
end

-- Bar_AuraCheck helper for watching "internal cooldowns", which is like a spell
-- cooldown for spells cast automatically (procs).  The "reset on buff" logic
-- is still handled by 
function NeedToKnow.mfn_AuraCheck_BUFFCD(bar, bar_entry, all_stacks)
    local buff_stacks = m_scratch.buff_stacks
    NeedToKnow.mfn_ResetScratchStacks(buff_stacks);
    NeedToKnow.mfn_AuraCheck_Single(bar, bar_entry, buff_stacks)
    local tNow = g_GetTime()
    if ( buff_stacks.total > 0 ) then
        if buff_stacks.max.expirationTime == 0 then
            -- TODO: This really doesn't work very well as a substitute for telling when the aura was applied
            if not bar.expirationTime then
                local nDur = tonumber(bar.settings.buffcd_duration)
                NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
                    nDur, buff_stacks.min.buffName, 1, nDur+tNow, buff_stacks.min.iconPath, buff_stacks.min.caster )
            else
                NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
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
            NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
                   duration,                                   -- duration
                   buff_stacks.min.buffName,                                   -- name
                   -- Seeing the charges on the CD bar violated least surprise for me
                   1,                                          -- count
                   expiration,                                 -- expiration time
                   buff_stacks.min.iconPath,                   -- icon path
                   buff_stacks.min.caster )                    -- caster
        end
    elseif ( bar.expirationTime and bar.expirationTime > tNow + 0.1 ) then
        NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
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

function NeedToKnow.mfn_AuraCheck_Single(bar, bar_entry, all_stacks)
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
                NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
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
                NeedToKnow.mfn_AddInstanceToStacks( all_stacks, bar_entry,
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

function NeedToKnow.mfn_AuraCheck_AllStacks(bar, bar_entry, all_stacks)
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
            NeedToKnow.mfn_AddInstanceToStacks(all_stacks, bar_entry, 
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

function NeedToKnow.mfn_Bar_AuraCheck(bar)
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
        NeedToKnow.mfn_ResetScratchStacks(all_stacks);

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
        NeedToKnow.mfn_ResetScratchStacks(buff_stacks);
        -- Keep track of when the reset auras were last applied to the player
        for idx, resetSpell in ipairs(bar.reset_spells) do
            -- Note this relies on BUFFCD setting the target to player, and that the onlyMine will work either way
            local resetDuration, _, _, resetExpiration
              = NeedToKnow.mfn_AuraCheck_Single(bar, resetSpell, buff_stacks)
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
                    -- mfn_Bar_AuraCheck(self)
                    NeedToKnow.mfn_Bar_AuraCheck(self)
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
                self:UpdateCastTime()
            end
        end
    end
end 

function NeedToKnow.fnAuraCheckIfUnitMatches(bar, unit)
    if ( unit == bar.unit )  then
        -- mfn_Bar_AuraCheck(bar)
        NeedToKnow.mfn_Bar_AuraCheck(bar)
    end
end

function NeedToKnow.fnAuraCheckIfUnitPlayer(bar, unit)
    if ( unit == "player" ) then
        -- mfn_Bar_AuraCheck(self)
        NeedToKnow.mfn_Bar_AuraCheck(bar)
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
                -- mfn_Bar_AuraCheck(self)
                NeedToKnow.mfn_Bar_AuraCheck(self)
            end
        end
    elseif ( combatEvent == "UNIT_DIED" ) then
        -- local guidDeceased = select(7, ...) 
        -- if ( guidDeceased == UnitGUID(self.unit) ) then
        if ( guidTarget == UnitGUID(self.unit) ) then
            -- mfn_Bar_AuraCheck(self)
            NeedToKnow.mfn_Bar_AuraCheck(self)
        end
    end 
end

EDT["PLAYER_TOTEM_UPDATE"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["ACTIONBAR_UPDATE_COOLDOWN"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_COOLDOWN"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_USABLE"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["UNIT_AURA"] = NeedToKnow.fnAuraCheckIfUnitMatches
-- EDT["UNIT_POWER"] = fnAuraCheckIfUnitMatches
-- EDT["UNIT_DISPLAYPOWER"] = fnAuraCheckIfUnitMatches
EDT["UNIT_HEALTH"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["PLAYER_TARGET_CHANGED"] = function(self, unit)
    if self.unit == "targettarget" then
        -- NeedToKnow.CheckCombatLogRegistration(self)
        self:CheckCombatLogRegistration()
    end
    -- mfn_Bar_AuraCheck(self)
    NeedToKnow.mfn_Bar_AuraCheck(self)
end  
EDT["PLAYER_FOCUS_CHANGED"] = EDT["PLAYER_TARGET_CHANGED"]
EDT["UNIT_TARGET"] = function(self, unit)
    if unit == "target" and self.unit == "targettarget" then
        -- NeedToKnow.CheckCombatLogRegistration(self)
        self:CheckCombatLogRegistration()
    end
    -- mfn_Bar_AuraCheck(self)
    NeedToKnow.mfn_Bar_AuraCheck(self)
end  
EDT["UNIT_PET"] = NeedToKnow.fnAuraCheckIfUnitPlayer
EDT["PLAYER_SPELLCAST_SUCCEEDED"] = function(self, unit, ...)
    local spellName, spellID, tgt = select(1,...)
    local i,entry
    for i,entry in ipairs(self.spells) do
        if entry.id == spellID or entry.name == spellName then
            self.unit = tgt or "unknown"
            --trace("Updating",self:GetName(),"since it was recast on",self.unit)
            -- mfn_Bar_AuraCheck(self)
            NeedToKnow.mfn_Bar_AuraCheck(self)
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
        -- mfn_Bar_AuraCheck(self)
        NeedToKnow.mfn_Bar_AuraCheck(self)
    end
end

function NeedToKnow.Bar_OnEvent(self, event, unit, ...)
    local fn = EDT[event]
    if fn then 
        fn(self, unit, ...)
    end
end

--[[
function Bar:OnEvent(event, unit, ...)
	local fn = EDT[event]
	if fn then 
		fn(self, unit, ...)
	end
end
]]--
