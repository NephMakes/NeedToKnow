-- Bar tracking behavior

local addonName, addonTable = ...

-- Namespaces
local Bar = NeedToKnow.Bar
local BarEvent = NeedToKnow.BarEvent
local Cooldown = NeedToKnow.Cooldown
local FindAura = NeedToKnow.FindAura

local UPDATE_INTERVAL = 0.025  -- 40 fps

-- Local versions of frequently-used global functions
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local IsUsableSpell = IsUsableSpell
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitRangedDamage = UnitRangedDamage
-- local SecondsToTimeAbbrev = SecondsToTimeAbbrev


-- Deprecated: 
local g_UnitIsFriend = UnitIsFriend
local g_UnitAffectingCombat = UnitAffectingCombat

local m_last_guid       = addonTable.m_last_guid
local m_bCombatWithBoss = addonTable.m_bCombatWithBoss

local mfn_GetAutoShotCooldown = Cooldown.GetAutoShotCooldown



-- ---------
-- Bar Setup
-- ---------

function Bar:Update()
	-- Update bar behavior and appearance
	-- Called by BarGroup:Update() and various BarMenu:Methods()
	-- when addon loaded, locked/unlocked, or bar configuration changed

	local groupID = self:GetParent():GetID()
	local barID = self:GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	self.settings = groupSettings.Bars[barID]
	local settings = self.settings

	local barType = settings.BuffOrDebuff

	self.auraName = settings.AuraName

	if
    	barType == "BUFFCD" or
		barType == "TOTEM" or
		barType == "USABLE" or
		barType == "EQUIPSLOT" or
		barType == "CASTCD"
	then
        settings.Unit = "player"
    end
	self.unit = settings.Unit

	self.fixedDuration = tonumber(groupSettings.FixedDuration)
	if not self.fixedDuration or 0 >= self.fixedDuration then
		self.fixedDuration = nil
	end

	self.max_value = 1
	self:SetValue(self.bar1, 1)

	self.nextUpdate = GetTime() + UPDATE_INTERVAL

	self:SetAppearance()

	if NeedToKnow.CharSettings["Locked"] then
		local enabled = groupSettings.Enabled and settings.Enabled
		if enabled then
			-- Set up bar to be functional

			self:EnableMouse(false)  -- Click through

			-- Split list of spell names    
			self.spells = {}
			self.cd_functions = {}
			local iSpell = 0
			for barSpell in self.auraName:gmatch("([^,]+)") do
				iSpell = iSpell+1
				barSpell = strtrim(barSpell)
				local _, nDigits = barSpell:find("^-?%d+")
				if ( nDigits == barSpell:len() ) then
					table.insert(self.spells, { idxName=iSpell, id=tonumber(barSpell) } )
				else
					table.insert(self.spells, { idxName=iSpell, name=barSpell } )
				end
			end

            -- Split the user name overrides
			self.spell_names = {}
			for un in settings.show_text_user:gmatch("([^,]+)") do
				un = strtrim(un)
				table.insert(self.spell_names, un)
			end

            -- Split the "reset" spells (for internal cooldowns which reset when the player gains an aura)
			if settings.buffcd_reset_spells and settings.buffcd_reset_spells ~= "" then
				self.reset_spells = {}
				self.reset_start = {}
				iSpell = 0
				for resetSpell in settings.buffcd_reset_spells:gmatch("([^,]+)") do
					iSpell = iSpell+1
					resetSpell = strtrim(resetSpell)
					local _, nDigits = resetSpell:find("^%d+")
					if ( nDigits == resetSpell:len() ) then
						table.insert(self.reset_spells, { idxName = iSpell, id=tonumber(resetSpell) } )
					else
						table.insert(self.reset_spells, { idxName = iSpell, name=resetSpell} )
					end
					table.insert(self.reset_start, 0)
				end
			else
				self.reset_spells = nil
				self.reset_start = nil
			end

			self.ticker = self.OnUpdate
			-- self.is_counter = nil
			settings.bAutoShot = nil

			-- Bar:SetType(barType)
            -- Determine which helper functions to use
			if "BUFFCD" == settings.BuffOrDebuff then
				-- self.fnCheck = NeedToKnow.mfn_AuraCheck_BUFFCD
				self.fnCheck = FindAura.FindBuffCooldown
				self.FindSingle = FindAura.FindSingle
			elseif "TOTEM" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_TOTEM
			elseif barType == "USABLE" then
				self.fnCheck = FindAura.FindSpellUsable
			elseif "EQUIPSLOT" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_EQUIPSLOT
			elseif barType == "CASTCD" then
				self.fnCheck = FindAura.FindCooldown
				for idx, entry in ipairs(self.spells) do
					table.insert(self.cd_functions, Cooldown.GetSpellCooldown)
					Cooldown.SetUpSpell(self, entry)
				end
			-- elseif "POWER" == barSettings.BuffOrDebuff then
				-- bar.fnCheck = NeedToKnow.mfn_AuraCheck_POWER
				-- bar.is_counter = true
				-- bar.ticker = nil
				-- bar.ticking = false
			elseif settings.show_all_stacks then
				self.fnCheck = FindAura.FindAllStacks
			else
				self.fnCheck = FindAura.FindSingle
			end

			if barType == "BUFFCD" then
				local duration = tonumber(settings.buffcd_duration)
				if (not duration or duration < 1) then
					print("NeedToKnow: Please set internal cooldown duration for:", settings.AuraName)
					enabled = false
				end
			end

			self:Activate()

			-- Events were cleared while unlocked, so need to check the bar again now
			self:CheckAura()
		else
            self:Inactivate()
			self:Hide()
		end
	else
		self:Inactivate()
		self:Unlock()
	end
end

function Bar:SetType(barType)
	-- Called by Bar:Update()
end

function Bar:Activate()
	-- Called by Bar:Update() if NeedToKnow is locked

	self:SetScript("OnEvent", self.OnEvent)
	if ( self.ticker ) then
		-- This check is a legacy of power tracking i think
		self:SetScript("OnUpdate", self.ticker)
	end

	local settings = self.settings

	local barType = settings.BuffOrDebuff
	if barType == "TOTEM" then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE")
		self.PLAYER_TOTEM_UPDATE = BarEvent.PLAYER_TOTEM_UPDATE
	elseif barType == "CASTCD" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		self.ACTIONBAR_UPDATE_COOLDOWN = BarEvent.ACTIONBAR_UPDATE_COOLDOWN
		self.SPELL_UPDATE_COOLDOWN = BarEvent.SPELL_UPDATE_COOLDOWN
		if settings.bAutoShot then
			self:RegisterEvent("START_AUTOREPEAT_SPELL")
			self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
			self.START_AUTOREPEAT_SPELL = BarEvent.START_AUTOREPEAT_SPELL
			self.STOP_AUTOREPEAT_SPELL = BarEvent.STOP_AUTOREPEAT_SPELL
		end
	elseif barType == "EQUIPSLOT" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self.ACTIONBAR_UPDATE_COOLDOWN = BarEvent.ACTIONBAR_UPDATE_COOLDOWN
	elseif barType == "USABLE" then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
		self.SPELL_UPDATE_USABLE = BarEvent.SPELL_UPDATE_USABLE
	elseif self.unit == "targettarget" then
		-- We don't get UNIT_AURA for target of target
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		self:RegisterCombatLog() 
		self.PLAYER_TARGET_CHANGED = BarEvent.PLAYER_TARGET_CHANGED
		self.UNIT_TARGET = BarEvent.UNIT_TARGET
		self.COMBAT_LOG_EVENT_UNFILTERED = BarEvent.COMBAT_LOG_EVENT_UNFILTERED
	else
		self:RegisterEvent("UNIT_AURA")
		self.UNIT_AURA = BarEvent.UNIT_AURA
	end

	if ( self.unit == "focus" ) then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self.PLAYER_FOCUS_CHANGED = BarEvent.PLAYER_FOCUS_CHANGED
	elseif ( self.unit == "target" ) then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self.PLAYER_TARGET_CHANGED = BarEvent.PLAYER_TARGET_CHANGED
	elseif ( self.unit == "pet" ) then
		self:RegisterEvent("UNIT_PET")
		self.UNIT_PET = BarEvent.UNIT_PET
	elseif ( "lastraid" == settings.Unit ) then
		if ( not NeedToKnow.BarsForPSS ) then
			NeedToKnow.BarsForPSS = {}
		end
		NeedToKnow.BarsForPSS[self] = true
		NeedToKnow.RegisterSpellcastSent()
		self.PLAYER_SPELLCAST_SUCCEEDED = BarEvent.PLAYER_SPELLCAST_SUCCEEDED
	end

	if ( settings.bDetectExtends ) then
		local idx, entry
		for idx, entry in ipairs(self.spells) do
			local spellName
			if ( entry.id ) then
				spellName = GetSpellInfo(entry.id)
			else
				spellName = entry.name
			end
			if ( spellName ) then
				local r = m_last_guid[spellName]
				if ( not r ) then
					m_last_guid[spellName] = { time=0, dur=0, expiry=0 }
				end
			else
				print("Warning! NeedToKnow could not get name for ", entry.id)
			end
		end
		NeedToKnow.RegisterSpellcastSent()
	end

	if ( settings.blink_enabled and settings.blink_boss ) then
		if ( not NeedToKnow.BossStateBars ) then
			NeedToKnow.BossStateBars = {}
		end
		NeedToKnow.BossStateBars[self] = 1;
	end
end

function Bar:RegisterCombatLog()
	-- Used to track auras on target of target
    if UnitExists(self.unit) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function Bar:Inactivate()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)

	local eventList = {
		"ACTIONBAR_UPDATE_COOLDOWN", 
		"COMBAT_LOG_EVENT_UNFILTERED", 
		"PLAYER_FOCUS_CHANGED", 
		"PLAYER_TARGET_CHANGED", 
		"PLAYER_TOTEM_UPDATE", 
		"SPELL_UPDATE_COOLDOWN", 
		"SPELL_UPDATE_USABLE", 
		"START_AUTOREPEAT_SPELL", 
		"STOP_AUTOREPEAT_SPELL", 
		"UNIT_AURA", 
		"UNIT_PET", 
		"UNIT_SPELLCAST_SUCCEEDED", 
		"UNIT_TARGET"
	}
	for k, event in pairs(eventList) do
		self:UnregisterEvent(event)
		self[event] = nil
	end
	self["PLAYER_SPELLCAST_SUCCEEDED"] = nil  -- Fake event called by ExecutiveFrame

	if NeedToKnow.BossStateBars then
		NeedToKnow.BossStateBars[self] = nil
	end
	if self.settings.bDetectExtends then
		NeedToKnow.UnregisterSpellcastSent()
	end
	if NeedToKnow.BarsForPSS and NeedToKnow.BarsForPSS[self] then
		NeedToKnow.BarsForPSS[self] = nil
		if not next(NeedToKnow.BarsForPSS) then
			NeedToKnow.BarsForPSS = nil
			NeedToKnow.UnregisterSpellcastSent()
		end
	end
end


-- -------------
-- Event handler
-- -------------

function Bar:OnEvent(event, unit, ...)
	local fn = self[event]  -- Assigned by Bar:Activate()
	if fn then
		fn(self, unit, ...)
	end
end

-- BarEvent:EVENT(unit, ...) 
--   assigned by Bar:Activate()
--   self = bar

function BarEvent:ACTIONBAR_UPDATE_COOLDOWN()
	self:CheckAura()
end

local auraEvents = {
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true
}
function BarEvent:COMBAT_LOG_EVENT_UNFILTERED(unit, ...)
	-- To monitor target of target
	local _, event, _, _, _, _, _, targetGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	if auraEvents[event] then
		if targetGUID == UnitGUID(self.unit) then
			if self.auraName:find(spellID) or self.auraName:find(spellName) then 
				self:CheckAura()
			end
		end
	elseif event == "UNIT_DIED" then
		if targetGUID == UnitGUID(self.unit) then
			self:CheckAura()
		end
	end 
end

function BarEvent:PLAYER_FOCUS_CHANGED(unit, ...)
	self:CheckAura()
end

function BarEvent:PLAYER_SPELLCAST_SUCCEEDED(unit, ...)
	-- To monitor last raid recipient
	-- Fake event called by ExecutiveFrame 
	local spellName, spellID, target = select(1,...)
	local i, entry
	for i, entry in ipairs(self.spells) do
		if entry.id == spellID or entry.name == spellName then
			self.unit = target or "unknown"
			-- print("Updating", self:GetName(), "since it was recast on", self.unit)
			self:CheckAura()
			break
		end
	end
end

function BarEvent:PLAYER_TARGET_CHANGED(unit, ...)
	if self.unit == "targettarget" then
		self:RegisterCombatLog()
	end
	self:CheckAura()
end

function BarEvent:PLAYER_TOTEM_UPDATE()
	self:CheckAura()
end

function BarEvent:SPELL_UPDATE_COOLDOWN()
	self:CheckAura()
end

function BarEvent:SPELL_UPDATE_USABLE()
	self:CheckAura()
end

function BarEvent:START_AUTOREPEAT_SPELL()
	-- To track Auto Shot
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function BarEvent:STOP_AUTOREPEAT_SPELL()
	-- To track Auto Shot
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function BarEvent:UNIT_AURA(unit, ...)
	if unit == self.unit then
		self:CheckAura()
	end
end

function BarEvent:UNIT_PET()
	if unit == "player" then
		self:CheckAura()
	end
end

local autoShotName = GetSpellInfo(75)  -- Localized name
function BarEvent:UNIT_SPELLCAST_SUCCEEDED(unit, ...)
	-- To track Auto Shot
	--[[
	local spellID  = select(2, ...)
	local spellName = select(1, GetSpellInfo(spellId))
	if self.settings.bAutoShot and unit == "player" and spellName == autoShotName then
		local interval = UnitRangedDamage("player")
		self.tAutoShotCD = interval
		self.tAutoShotStart = GetTime()
		self:CheckAura()
	end
	]]--
	if unit == "player" then 
		-- UNIT_SPELLCAST_SUCCEEDED only registered if self.settings.bAutoShot
		local spellID  = select(2, ...)
		local spellName = select(1, GetSpellInfo(spellId))
		if spellName == autoShotName then
			local interval = UnitRangedDamage("player")
			self.tAutoShotCD = interval
			self.tAutoShotStart = GetTime()
			self:CheckAura()
		end
	end
end

function BarEvent:UNIT_TARGET(unit, ...)
	if self.unit == "targettarget" and unit == "target" then
		self:RegisterCombatLog()
	end
	self:CheckAura()
end


-- ----------
-- Check aura
-- ----------

-- Kitjan made m_scratch as a reusable table to track multiple instances of an aura with one bar
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

function Bar:CheckAura()
	-- Called by many functions
    -- Called very frequently for cooldowns (OnUpdate). Make sure it's efficient. 

    local settings = self.settings
    local unitExists

    if settings.Unit == "player" then
        unitExists = true
    elseif settings.Unit == "lastraid" then
        unitExists = self.unit and UnitExists(self.unit)
    else
        unitExists = UnitExists(settings.Unit)
    end
    
    -- Determine if the bar should be showing anything
    local all_stacks       
    local idxName, duration, buffName, count, expirationTime, iconPath, caster

    if unitExists then
        all_stacks = m_scratch.all_stacks
        NeedToKnow.mfn_ResetScratchStacks(all_stacks);

        -- Call helper function for each spell in list
        for idx, entry in ipairs(self.spells) do
            self.fnCheck(self, entry, all_stacks)  -- fnCheck assigned by Bar:Update()
            if all_stacks.total > 0 and not settings.show_all_stacks then
                idxName = idx
                break
            end
        end
    end
    
    if all_stacks and all_stacks.total > 0 then
        idxName = all_stacks.min.idxName
        buffName = all_stacks.min.buffName
        caster = all_stacks.min.caster
        duration = all_stacks.max.duration
        expirationTime = all_stacks.min.expirationTime
        iconPath = all_stacks.min.iconPath
        count = all_stacks.total
    end

    -- Cancel work done above if reset spell is encountered
    -- reset_spells will only be set for BUFFCD
    if self.reset_spells then
        local maxStart = 0
        local tNow = GetTime()
        local buff_stacks = m_scratch.buff_stacks
        NeedToKnow.mfn_ResetScratchStacks(buff_stacks);
        -- Keep track of when the reset auras were last applied to the player
        for idx, resetSpell in ipairs(self.reset_spells) do
            -- Note this relies on BUFFCD setting the target to player, and that the onlyMine will work either way
            local resetDuration, _, _, resetExpiration
              = NeedToKnow.mfn_AuraCheck_Single(self, resetSpell, buff_stacks)
            local tStart
            if buff_stacks.total > 0 then
               if 0 == buff_stacks.max.duration then 
                   tStart = self.reset_start[idx]
                   if 0 == tStart then
                       tStart = tNow
                   end
               else
                   tStart = buff_stacks.max.expirationTime - buff_stacks.max.duration
               end
               self.reset_start[idx] = tStart
               
               if tStart > maxStart then maxStart = tStart end
            else
               self.reset_start[idx] = 0
            end
        end
        if duration and maxStart > expirationTime - duration then
            duration = nil
        end
    end
    
    -- There is an aura this bar is watching. Set it up
    if duration then
        duration = tonumber(duration)

        -- Handle duration increases
        local extended
        if (settings.bDetectExtends) then
            local curStart = expirationTime - duration
            local guidTarget = UnitGUID(self.unit)
            local r = m_last_guid[buffName] 
            
            if ( not r[guidTarget] ) then 
            	-- Should only happen from /reload or /ntk while the aura is active
                -- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
                --trace("WARNING! allocating guid slot for ", buffName, "on", guidTarget, "due to UNIT_AURA");
                r[guidTarget] = { time=curStart, dur=duration, expiry=expirationTime }
            else
                r = r[guidTarget]
                local oldExpiry = r.expiry
                -- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
                --if ( oldExpiry > 0 and oldExpiry < curStart ) then
                    --trace("WARNING! stale entry for ",buffName,"on",guidTarget,curStart-r.time,curStart-oldExpiry)
                --end

                if ( oldExpiry < curStart ) then
                    r.time = curStart
                    r.dur = duration 
                    r.expiry= expirationTime
                else
                    r.expiry= expirationTime
                    extended = expirationTime - (r.time + r.dur)
                    if extended > 1 then
                        duration = r.dur 
                    else
                        extended = nil
                    end
                end
            end
        end

        --bar.duration = tonumber(bar.fixedDuration) or duration
        self.duration = duration

        self.expirationTime = expirationTime
        self.idxName = idxName
        self.buffName = buffName
        self.iconPath = iconPath
        if ( all_stacks and all_stacks.max.expirationTime ~= expirationTime ) then
            self.max_expirationTime = all_stacks.max.expirationTime
        else
            self.max_expirationTime = nil
        end

        -- Mark the bar as not blinking before calling ConfigureVisible, 
        -- since it calls OnUpdate which checks bar.blink
        self.blink = false
        self:UpdateAppearance()
        self:ConfigureVisible(count, extended, all_stacks)
        self:Show()
    else
        if (settings.bDetectExtends and self.buffName) then
            local r = m_last_guid[self.buffName]
            if ( r ) then
                local guidTarget = UnitGUID(self.unit)
                if guidTarget then
                    r[guidTarget] = nil
                end
            end
        end
        self.buffName = nil
        self.duration = nil
        self.expirationTime = nil
        
        local bBlink = false
        if settings.blink_enabled and settings.MissingBlink.a > 0 then
            bBlink = unitExists and not UnitIsDead(self.unit)
        end
        if ( bBlink and not settings.blink_ooc ) then
            if not g_UnitAffectingCombat("player") then
                bBlink = false
            end
        end
        if ( bBlink and settings.blink_boss ) then
            if g_UnitIsFriend(self.unit, "player") then
                bBlink = m_bCombatWithBoss
            else
                bBlink = (UnitLevel(self.unit) == -1)
            end
        end
        if ( bBlink ) then
            self:StartBlink()
            self:Show()
        else    
            self.blink = false
            self:Hide()
        end
    end
end

local function UnitAuraWrapper(unit, index, filter)
	local name, icon, count, _, duration, expirationTime, sourceUnit, _, _, spellID, _, _, _, _, _, value1, value2, value3 = UnitAura(unit, index, filter)
	if name then
		return name, icon, count, duration, expirationTime, sourceUnit, spellID, value1, value2, value3
	end
end

-- FindAura:Methods() 
--   * assigned by Bar:Update(), called by Bar:CheckAura()
--   * self = bar
--   * spellEntry is element of bar.spells assigned by Bar:Update()
--     {idxName = , id = } or {idxName = , name = }

function FindAura:FindSingle(spellEntry, allStacks)
	-- Find first aura instance then update allStacks
	local filter = self.settings.BuffOrDebuff
	if self.settings.OnlyMine then
		filter = filter .. "|PLAYER"
	end
	if spellEntry.id then
		-- Can't search by spellID, so walk through them
		local j = 1
		while true do
			local name, icon, count, _, duration, expirationTime, sourceUnit, _, _, spellID, _, _, _, _, _, value1, value2, value3 = UnitAura(self.unit, j, filter)
			if not name then
				break
			end
			if spellID == spellEntry.id then 
				NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, sourceUnit, value1, value2, value3)
				return
			end
			j = j + 1
		end
	else
		-- AuraUtil.FindAuraByName() added in patch 8.0, available in Classic
		local name, icon, count, _, duration, expirationTime, sourceUnit, _, _, spellID, _, _, _, _, _, value1, value2, value3 = AuraUtil.FindAuraByName(spellEntry.name, self.unit, filter)
		if name and name == spellEntry.name then 
			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, sourceUnit, value1, value2, value3)
			return
		end
	end
end

function FindAura:FindAllStacks(spellEntry, allStacks)
	-- Find all aura instances then update allStacks
	local j = 1
	local filter = self.settings.BuffOrDebuff
	while true do
		local name, icon, count, _, duration, expirationTime, sourceUnit, _, _, spellID, _, _, _, _, _, value1, value2, value3 = UnitAura(self.unit, j, filter)
		if not name then
			break
		end
		if name == spellEntry.name or spellID == spellEntry.id then
			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, sourceUnit, value1, value2, value3)
		end
		j = j + 1
	end
end

function FindAura:FindSpellUsable(spellEntry, allStacks)
	-- For watching reactive spells and abilities
	local spell = spellEntry.name or spellEntry.id
	if not spell then 
		return 
	end
	local spellName, _, icon = GetSpellInfo(spell)
	if spellName then
		local isUsable, notEnoughMana = IsUsableSpell(spellName)
		if isUsable or notEnoughMana then
			local duration, expirationTime
			local now = GetTime()
			if 
				not self.expirationTime or 
				(self.expirationTime > 0 and self.expirationTime < now - 0.01) 
			then
				duration = self.settings.usable_duration  -- Has to be set by user
				expirationTime = now + duration
			else
				duration = self.duration
				expirationTime = self.expirationTime
			end

			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, spellName, 1, expirationTime, icon, "player")
		end
	end
end

function FindAura:FindCooldown(spellEntry, allStacks)
	-- Find spell or item cooldown then update allStacks
	-- Bar:Update() sets up bar.cd_functions

	local GetCooldown = self.cd_functions[spellEntry.idxName]
	if not GetCooldown then
		print("NeedToKnow FindAura:FindCooldown ERROR setting up index", spellEntry.idxName, "on bar", self:GetName(), self.settings.AuraName)
		return
	end
	local start, duration, _, name, icon, count, start2 = GetCooldown(self, spellEntry)

	-- Filter out global cooldown
	if start and duration <= 1.5 and GetCooldown ~= Cooldown.GetAutoShotCooldown then
		if self.expirationTime and self.expirationTime <= start + duration then
			start = self.expirationTime - self.duration
			duration = self.duration
		else
			start = nil
		end
	end

	if start and duration then
		local now = GetTime()
		local expirationTime = start + duration
		if expirationTime > now + 0.1 then
			if start2 then
				-- start2 returned by Cooldown.GetSpellChargesCooldown
				NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, 1, start2 + duration, icon, "player")
				count = count - 1
			else
				if not count then count = 1 end
			end
			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, "player")
		end
	end
end

--[[
function FindAura:FindEquipSlotCooldown(spellEntry, allStacks)
end

function FindAura:FindTotem(spellEntry, allStacks)
end
]]--

function FindAura:FindBuffCooldown(spellEntry, allStacks)
	-- For internal cooldowns on procs

	local buffStacks = m_scratch.buff_stacks
	NeedToKnow.mfn_ResetScratchStacks(buffStacks);
	self:FindSingle(spellEntry, buffStacks)

	local now = GetTime()
	if buffStacks.total > 0 then
		local duration = tonumber(self.settings.buffcd_duration)
		if buffStacks.max.expirationTime == 0 then
			-- TODO: This really doesn't work very well as a substitute for telling when the aura was applied
			if not self.expirationTime then
				NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration,  buffStacks.min.buffName, 1, duration + now, buffStacks.min.iconPath,  buffStacks.min.caster)
			else
				NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, self.duration,  self.buffName, 1, self.expirationTime, self.iconPath, "player")
			end
			return
		end

		local start = buffStacks.max.expirationTime - buffStacks.max.duration
		local expirationTime = start + duration
		if expirationTime > now then
			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, buffStacks.min.buffName, 1, expirationTime, buffStacks.min.iconPath, buffStacks.min.caster)                   
		end
	elseif self.expirationTime and self.expirationTime > now + 0.1 then
		NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, "player")
	end
end


-- --------
-- OnUpdate
-- --------

function Bar:OnUpdate(elapsed)
	-- Called very frequently. Make sure it's efficient. 
	local now = GetTime()
	if now > self.nextUpdate then
		self.nextUpdate = now + UPDATE_INTERVAL

		if self.blink then
			self.blink_phase = self.blink_phase + UPDATE_INTERVAL
			if self.blink_phase >= 2 then
				self.blink_phase = 0
			end
			local a = self.blink_phase
			if a > 1 then
				a = 2 - a
			end

			self.bar1:SetVertexColor(self.settings.MissingBlink.r, self.settings.MissingBlink.g, self.settings.MissingBlink.b)
			self.bar1:SetAlpha(self.settings.MissingBlink.a * a)
			return
		end
        
		if self.duration and self.duration > 0 then
			local duration = self.fixedDuration or self.duration
			local bar1_timeLeft = self.expirationTime - now
			if bar1_timeLeft < 0 then
				if ( self.settings.BuffOrDebuff == "CASTCD" or
					self.settings.BuffOrDebuff == "BUFFCD" or
					self.settings.BuffOrDebuff == "EQUIPSLOT" )
				then
					-- Item cooldowns don't fire an event when they expire.
					-- Other cooldowns fire the event too soon. So we have to keep checking.
					self:CheckAura()
					return
				end
				bar1_timeLeft = 0
			end
			self:SetValue(self.bar1, bar1_timeLeft);

			if self.settings.show_time then
				local fn = NeedToKnow[self.settings.TimeFormat]
				local oldText = self.time:GetText()
				-- Is this really an optimization?
				local newText
				if fn then
					newText = fn(bar1_timeLeft)
				else 
					newText = string.format(SecondsToTimeAbbrev(bar1_timeLeft))
				end
				if newText ~= oldText then
					self.time:SetText(newText)
				end
			else
				self.time:SetText("")
			end
            
			if self.settings.show_spark and bar1_timeLeft <= duration then
				self.spark:SetPoint("CENTER", self, "LEFT", self:GetWidth()*bar1_timeLeft/duration, 0)
				self.spark:Show()
			else
				self.spark:Hide()
			end
            
			if self.settings.vct_enabled and self.vct_refresh then
				self:UpdateCastTime()
			end

			if self.max_expirationTime then
				local bar2_timeLeft = self.max_expirationTime - GetTime()
				self:SetValue(self.bar2, bar2_timeLeft, bar1_timeLeft)
            end
		end
	end
end


