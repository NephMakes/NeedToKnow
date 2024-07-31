-- Bar tracking behavior

local _, NeedToKnow = ...

local Bar = NeedToKnow.Bar
local FindAura = NeedToKnow.FindAura
local Cooldown = NeedToKnow.Cooldown
local ExecutiveFrame = NeedToKnow.ExecutiveFrame

local UPDATE_INTERVAL = 0.025  -- 40 /sec

-- Local versions of frequently-used global functions
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetInventoryItemID = GetInventoryItemID
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo
local IsUsableSpell = C_Spell.IsSpellUsable or IsUsableSpell
local UnitExists = UnitExists
local UnitGUID = UnitGUID

-- Functions different between Retail and Classic as of 11.0.0
local function GetMySpellInfo(spell)
	local info = C_Spell.GetSpellInfo(spell)  -- Only in Retail
	return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
end
local GetSpellInfo = GetSpellInfo or GetMySpellInfo

-- Deprecated: 
local m_last_guid = NeedToKnow.m_last_guid  -- For detect extends


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

	self:UpdateSpells()
	self:UpdateBarType()
	self:SetAppearance()

	self.max_value = 1
	self:SetValue(self.bar1, 1)
	self.fixedDuration = tonumber(groupSettings.FixedDuration)
	if not self.fixedDuration or 0 >= self.fixedDuration then
		self.fixedDuration = nil
	end

	if NeedToKnow.isLocked then
		if self.settings.Enabled and groupSettings.Enabled then
			self:EnableMouse(false)  -- Click through
			self:Activate()
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

function Bar:UpdateSpells()
	-- Update tracked spells/abilities
	-- Called by Bar:Update()

	local settings = self.settings
	self.auraName = settings.AuraName  -- User entry

	-- Process list of spell names or IDs
	self.spells = {}
	local spellIndex = 0
	for spell in self.auraName:gmatch("([^,]+)") do
		spellIndex = spellIndex + 1
		spell = strtrim(spell)
		local _, numDigits = spell:find("^-?%d+")
		if numDigits == spell:len() then
			table.insert(self.spells, {idxName = spellIndex, id = tonumber(spell)})
		else
			table.insert(self.spells, {idxName = spellIndex, name = spell})
		end
	end

	-- Process list of user-set name overrides
	self.spell_names = {}
	for shownName in settings.show_text_user:gmatch("([^,]+)") do
		shownName = strtrim(shownName)
		table.insert(self.spell_names, shownName)
	end
	-- self:UpdateReplacementText()  -- TO DO

	-- Process list of reset spells for internal cooldowns
	-- TO DO: add check for settings.BuffOrDebuff == "BUFFCD"
	if settings.buffcd_reset_spells and settings.buffcd_reset_spells ~= "" then
		self.reset_spells = {}
		self.reset_start = {}
		spellIndex = 0
		for resetSpell in settings.buffcd_reset_spells:gmatch("([^,]+)") do
			spellIndex = spellIndex + 1
			resetSpell = strtrim(resetSpell)
			local _, numDigits = resetSpell:find("^%d+")
			if numDigits == resetSpell:len() then
				table.insert(self.reset_spells, {idxName = spellIndex, id = tonumber(resetSpell)})
			else
				table.insert(self.reset_spells, {idxName = spellIndex, name = resetSpell})
			end
			table.insert(self.reset_start, 0)
		end
	else
		self.reset_spells = nil
		self.reset_start = nil
	end
end

function Bar:UpdateBarType()
	-- Set up tracking functions
	-- Called by Bar:Update()

	local settings = self.settings
	local barType = settings.BuffOrDebuff

	if barType == "BUFFCD" or
		barType == "TOTEM" or
		barType == "USABLE" or
		barType == "EQUIPSLOT" or
		barType == "CASTCD"
	then
        settings.Unit = "player"
    end
	self.unit = settings.Unit

	if barType == "BUFFCD" then
		local duration = tonumber(settings.buffcd_duration)
		if not duration or duration < 1 then
			print("NeedToKnow: Please set internal cooldown time for:", settings.AuraName)
		end
		self.fnCheck = FindAura.FindBuffCooldown
		self.FindSingle = FindAura.FindSingle
	elseif barType == "TOTEM" then
		-- self.dropTime = {}  -- array 1-4 of precise times totems appeared
		self.fnCheck = FindAura.FindTotem
	elseif barType == "USABLE" then
		self.fnCheck = FindAura.FindSpellUsable
	elseif barType == "EQUIPSLOT" then
		self.fnCheck = FindAura.FindEquipSlotCooldown
	elseif barType == "CASTCD" then
		for index, spellInfo in ipairs(self.spells) do
			Cooldown.SetUpSpell(self, spellInfo)
		end
		self.fnCheck = FindAura.FindCooldown
	elseif settings.show_all_stacks then
		self.fnCheck = FindAura.FindAllStacks
	else
		self.fnCheck = FindAura.FindSingle
	end
end

function Bar:Activate()
	-- Called by Bar:Update() if NeedToKnow is locked

	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self.nextUpdate = GetTime() + UPDATE_INTERVAL

	local settings = self.settings

	local barType = settings.BuffOrDebuff
	if barType == "TOTEM" then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	elseif barType == "CASTCD" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	elseif barType == "EQUIPSLOT" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	elseif barType == "USABLE" then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	elseif self.unit == "targettarget" then
		-- We don't get UNIT_AURA for target of target
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		self:RegisterCombatLog() 
	-- elseif self.unit ~== "lastraid" then
		-- self:RegisterUnitEvent("UNIT_AURA", self.unit)
	else
		self:RegisterEvent("UNIT_AURA")
	end

	if self.unit == "focus" then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif self.unit == "target" then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif self.unit == "pet" then
		self:RegisterEvent("UNIT_PET")
		-- self:RegisterUnitEvent("UNIT_PET", "pet")  -- To do
	elseif settings.Unit == "lastraid" then
		if not NeedToKnow.BarsForPSS then
			NeedToKnow.BarsForPSS = {}
		end
		NeedToKnow.BarsForPSS[self] = true
		NeedToKnow.RegisterSpellcastSent()
	end

	if settings.bDetectExtends then
		self:RegisterExtendedTime()
	end

	if settings.blink_enabled then
		if not settings.blink_ooc then
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		if settings.blink_boss then
			self:RegisterBossFight()
		end
	end
end

function Bar:RegisterExtendedTime()
	for idx, entry in ipairs(self.spells) do
		local spellName
		if entry.id then
			spellName = GetSpellInfo(entry.id)
		else
			spellName = entry.name
		end
		if spellName then
			local r = m_last_guid[spellName]
			if not r then
				m_last_guid[spellName] = {time = 0, dur = 0, expiry = 0}
			end
		else
			print("Warning! NeedToKnow could not get name for ", entry.id)
		end
	end
	NeedToKnow.RegisterSpellcastSent()
end

function Bar:RegisterCombatLog()
	-- For monitoring target of target
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
		"UNIT_AURA", 
		"UNIT_PET", 
		"UNIT_TARGET", 
		"PLAYER_REGEN_DISABLED", 
		"PLAYER_REGEN_ENABLED", 
	}
	for i, event in pairs(eventList) do
		self:UnregisterEvent(event)
	end
	self["PLAYER_SPELLCAST_SUCCEEDED"] = nil  -- Fake event called by ExecutiveFrame

	self.isBlinking = nil
	self:UnregisterBossFight()

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
	local f = self[event]  -- Assigned by Bar:Activate()
	if f then
		f(self, unit, ...)
	end
end

function Bar:ACTIONBAR_UPDATE_COOLDOWN()
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
function Bar:COMBAT_LOG_EVENT_UNFILTERED(unit, ...)
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

function Bar:PLAYER_FOCUS_CHANGED(unit, ...)
	self:CheckAura()
end

function Bar:PLAYER_REGEN_DISABLED()
	self:CheckAura()
end

function Bar:PLAYER_REGEN_ENABLED()
	self:CheckAura()
end

function Bar:PLAYER_SPELLCAST_SUCCEEDED(unit, ...)
	-- Fake event called by ExecutiveFrame to monitor last raid recipient
	-- local spellName, spellID, target = select(1,...)
	local spellName, spellID = select(1, ...)
	-- local i, entry
	for i, entry in ipairs(self.spells) do
		if entry.id == spellID or entry.name == spellName then
			-- self.unit = target or "unknown"
			-- print("Updating", self:GetName(), "since it was recast on", self.unit)
			self:CheckAura()
			break
		end
	end
end

function Bar:PLAYER_TARGET_CHANGED(unit, ...)
	if self.unit == "targettarget" then
		self:RegisterCombatLog()
	end
	self:CheckAura()
end

function Bar:PLAYER_TOTEM_UPDATE()
	self:CheckAura()
end

function Bar:SPELL_UPDATE_COOLDOWN()
	self:CheckAura()
end

function Bar:SPELL_UPDATE_USABLE()
	self:CheckAura()
end

function Bar:UNIT_AURA(unit, ...)
	if unit == self.unit then
		self:CheckAura()
	end
end

function Bar:UNIT_PET(unit, ...)
	if unit == "player" then
		self:CheckAura()
	end
end

function Bar:UNIT_TARGET(unit, ...)
	if self.unit == "targettarget" and unit == "target" then
		self:RegisterCombatLog()
	end
	self:CheckAura()
end


-- ----------
-- Check aura
-- ----------

-- Kitjan made m_scratch a reusable table to track multiple instances of an aura with one bar
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
}
m_scratch.buff_stacks = {
	-- Used to track proc internal cooldowns (barType "BUFFCD")
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
}
m_scratch.bar_entry = {
	idxName = 0,
	barSpell = "",
	isSpellID = false,
}

function Bar:CheckAura()
	-- Called by many functions
	local settings = self.settings

	local unitExists
	if settings.Unit == "player" then
		unitExists = true
	elseif settings.Unit == "lastraid" then
		unitExists = self.unit and UnitExists(self.unit)
	else
		unitExists = UnitExists(settings.Unit)
	end

	-- Determine if bar should show anything
	local all_stacks       
	local idxName, duration, buffName, count, expirationTime, iconPath, caster
	if unitExists then
		all_stacks = m_scratch.all_stacks
		self:ResetScratchStacks(all_stacks)

		-- Call helper function for each spell in list until first found
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
		duration = all_stacks.max.duration
		expirationTime = all_stacks.min.expirationTime
		count = all_stacks.total
		iconPath = all_stacks.min.iconPath
		caster = all_stacks.min.caster
	end

	-- Cancel work done above if reset spell encountered.  reset_spells only set for BUFFCD. 
	if self.reset_spells then
		local maxStart = 0
		local tNow = GetTime()
		local buff_stacks = m_scratch.buff_stacks
		self:ResetScratchStacks(buff_stacks)
		-- Keep track of when the reset auras were last applied to the player
		for idx, resetSpell in ipairs(self.reset_spells) do
			-- Relies on BUFFCD setting target to player. onlyMine will work either way. 
			local resetDuration, _, _, resetExpiration = FindAura.FindSingle(self, resetSpell, buff_stacks)
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
	-- TO DO: 
    -- if settings.BuffOrDebuff == "BUFFCD" and self.reset_spells and duration then
		-- duration = self:GetProcReset(duration, expirationTime)
	-- end

    if duration then
	    -- There's an aura or cooldown this bar is watching. Set it up
        duration = tonumber(duration)

		local extended
		if settings.bDetectExtends then
			extended, duration = self:GetExtendedTime(buffName, duration, expirationTime, self.unit)
		end

		-- bar.duration = tonumber(bar.fixedDuration) or duration
		self.duration = duration
		self.expirationTime = expirationTime
		self.idxName = idxName
		self.buffName = buffName
		self.iconPath = iconPath

		if all_stacks and all_stacks.max.expirationTime ~= expirationTime then
			self.max_expirationTime = all_stacks.max.expirationTime
		else
			self.max_expirationTime = nil
		end

		self.isBlinking = false  -- Because UpdateAppearance() calls OnUpdate which checks bar.isBlinking
		self:UpdateAppearance()
		-- self:UpdateBarText(self.settings, count, extended, all_stacks)
		self:UpdateBarText(self.settings, count, extended)
		self:Show()
	else
		if settings.bDetectExtends and self.buffName then
			self:ClearExtendedTime()
		end
		self.buffName = nil
		self.duration = nil
		self.expirationTime = nil

		if self:ShouldBlink(settings, unitExists) then
			self:Blink(settings)
			self:Show()
		else    
			self.isBlinking = false
			self:Hide()
		end
	end

	-- Condense group
	local barGroup = self:GetParent()
	if barGroup.settings.condenseGroup and (self.isVisible ~= self:IsVisible()) then
		barGroup:UpdateBarPosition()
		self.isVisible = self:IsVisible()
	end
end

function Bar:GetProcReset(duration, expirationTime)
	local maxStart = 0
	local tNow = GetTime()
	local buff_stacks = m_scratch.buff_stacks
	self:ResetScratchStacks(buff_stacks)

	-- Keep track of when the reset auras were last applied to the player
	for idx, resetSpell in ipairs(self.reset_spells) do
		-- Relies on BUFFCD setting target to player. onlyMine will work either way. 
		local resetDuration, _, _, resetExpiration = FindAura.FindSingle(self, resetSpell, buff_stacks)
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
	return duration
end

function Bar:GetExtendedTime(auraName, duration, expirationTime, unit)
	local extended
	local curStart = expirationTime - duration
	local guidTarget = UnitGUID(unit)
	local r = m_last_guid[auraName]
            
	if not r[guidTarget] then 
		-- Should only happen from /reload or /ntk while the aura is active
		-- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
		--trace("WARNING! allocating guid slot for ", buffName, "on", guidTarget, "due to UNIT_AURA");
		r[guidTarget] = {time = curStart, dur = duration, expiry = expirationTime}
	else
		r = r[guidTarget]
		local oldExpiry = r.expiry
		-- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
		--if ( oldExpiry > 0 and oldExpiry < curStart ) then
			--trace("WARNING! stale entry for ",buffName,"on",guidTarget,curStart-r.time,curStart-oldExpiry)
		--end

		if oldExpiry < curStart then
			r.time = curStart
			r.dur = duration
			r.expiry = expirationTime
		else
			r.expiry = expirationTime
			extended = expirationTime - (r.time + r.dur)
			if extended > 1 then
				duration = r.dur 
			else
				extended = nil
			end
		end
	end
	return extended, duration
end

function Bar:ClearExtendedTime()
	local r = m_last_guid[self.buffName]
	if r then
		local guidTarget = UnitGUID(self.unit)
		if guidTarget then
			r[guidTarget] = nil
		end
	end
end

-- FindAura:Methods() 
--   assigned by Bar:Update(), called by Bar:CheckAura()
--   self = bar
--   spellEntry is element of bar.spells, {idxName, id} or {idxName, name}

function FindAura:FindSingle(spellEntry, allStacks)
	-- Find first aura instance then update allStacks
	local filter = self.settings.BuffOrDebuff
	if self.settings.OnlyMine then
		filter = filter .. "|PLAYER"
	end
	if spellEntry.id then
		local j = 1
		while true do
			local aura = GetAuraDataByIndex(self.unit, j, filter)
			if not aura then
				break
			end
			if aura.spellId == spellEntry.id then 
				self:AddInstanceToStacks(allStacks, spellEntry, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, aura.sourceUnit, nil, nil, nil)
				return
			end
			j = j + 1
		end
	else
		local name, icon, count, _, duration, expirationTime, sourceUnit, _, _, spellID, _, _, _, _, _, value1, value2, value3 = AuraUtil.FindAuraByName(spellEntry.name, self.unit, filter)
		if name then 
			self:AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, sourceUnit, value1, value2, value3)
			return
		end
	end
end

function FindAura:FindAllStacks(spellEntry, allStacks)
	-- Find all aura instances then update allStacks
	local j = 1
	local filter = self.settings.BuffOrDebuff
	while true do
		local aura = GetAuraDataByIndex(self.unit, j, filter)
		if not aura then
			break
		end
		if aura.name == spellEntry.name or aura.spellId == spellEntry.id then 
			self:AddInstanceToStacks(allStacks, spellEntry, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, aura.sourceUnit, nil, nil, nil)
			return
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
			if not self.expirationTime or 
				(self.expirationTime > 0 and self.expirationTime < now - 0.01) 
			then
				duration = self.settings.usable_duration  -- Has to be set by user
				expirationTime = now + duration
			else
				duration = self.duration
				expirationTime = self.expirationTime
			end
			self:AddInstanceToStacks(allStacks, spellEntry, duration, spellName, 1, expirationTime, icon, "player")
		end
	end
end

function FindAura:FindCooldown(spellInfo, allStacks)
	-- Find spell or item cooldown then update allStacks

	local GetCooldown = spellInfo.cooldownFunction
	local start, duration, _, name, icon, count, start2 = GetCooldown(self, spellInfo)

	-- Filter out global cooldown
	if start and duration <= 1.5 then
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
			if start2 then  -- returned by Cooldown.GetSpellChargesCooldown
				self:AddInstanceToStacks(allStacks, spellInfo, duration, name, 1, start2 + duration, icon, "player")
				count = count - 1
			else
				if not count then count = 1 end
			end
			self:AddInstanceToStacks(allStacks, spellInfo, duration, name, count, expirationTime, icon, "player")
		end
	end
end

function FindAura:FindEquipSlotCooldown(spellEntry, allStacks)
	-- Find item cooldown then update allStacks
	if spellEntry.id then
		local itemID = GetInventoryItemID("player", spellEntry.id)
		if itemID then
			local itemEntry = m_scratch.bar_entry
			itemEntry.id = itemID
			local start, duration, _, name, icon = Cooldown.GetItemCooldown(bar, itemEntry)
			if start and start > 0 then
				self:AddInstanceToStacks(allStacks, spellEntry, duration, name, 1, start + duration, icon, "player")
			end
		end
	end
end

-- Needs testing
function FindAura:FindTotem(spellEntry, allStacks)
	local spellName = spellEntry.name or GetSpellInfo(spellEntry.id)
	for index = 1, 4 do
		local _, name, startTime, duration, icon = GetTotemInfo(index)  
			-- Kitjan: startTime cast to integer and off by latency, so can be low
			-- NephMakes: True for GetTotemTimeLeft() but not GetTotemInfo()
		if name and name:find(spellName) then
		--[[
			-- Cache time totem actually appeared if GetTime() close to startTime
			local dropTime = self.dropTime
			if not dropTime[index] or dropTime[index] < startTime then
				local preciseTime = GetTime()
				if preciseTime - startTime > 1 then
					preciseTime = startTime + 1
				end
				dropTime[index] = preciseTime
			end
			NeedToKnow.mfn_AddInstanceToStacks(allStacks, spellEntry, duration, name, 1, dropTime[index] + duration, icon, "player")
		]]--
			self:AddInstanceToStacks(allStacks, spellEntry, duration, name, 1, startTime + duration, icon, "player")
		end
	end
end
--[[
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
]]--

function FindAura:FindBuffCooldown(spellEntry, allStacks)
	-- For internal cooldowns on procs

	local buffStacks = m_scratch.buff_stacks
	self:ResetScratchStacks(buffStacks)
	self:FindSingle(spellEntry, buffStacks)

	local now = GetTime()
	if buffStacks.total > 0 then
		local duration = tonumber(self.settings.buffcd_duration)
		if buffStacks.max.expirationTime == 0 then
			-- TODO: This doesn't work well as a substitute for telling when the aura was applied
			if not self.expirationTime then
				self:AddInstanceToStacks(allStacks, spellEntry, duration,  buffStacks.min.buffName, 1, duration + now, buffStacks.min.iconPath,  buffStacks.min.caster)
			else
				self:AddInstanceToStacks(allStacks, spellEntry, self.duration,  self.buffName, 1, self.expirationTime, self.iconPath, "player")
			end
			return
		end

		local start = buffStacks.max.expirationTime - buffStacks.max.duration
		local expirationTime = start + duration
		if expirationTime > now then
			self:AddInstanceToStacks(allStacks, spellEntry, duration, buffStacks.min.buffName, 1, expirationTime, buffStacks.min.iconPath, buffStacks.min.caster)                   
		end
	elseif self.expirationTime and self.expirationTime > now + 0.1 then
		self:AddInstanceToStacks(allStacks, spellEntry, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, "player")
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

function Bar:AddInstanceToStacks(allStacks, spellEntry, duration, name, count, expirationTime, icon, sourceUnit, value1, value2, value3)
	if duration then
		if not count or count < 1 then 
			count = 1 
		end
		if allStacks.total == 0 or allStacks.min.expirationTime > expirationTime then
			allStacks.min.idxName = spellEntry.idxName
			allStacks.min.buffName = name
			allStacks.min.caster = sourceUnit
			allStacks.min.duration = duration
			allStacks.min.expirationTime = expirationTime
			allStacks.min.iconPath = icon
		end
		if allStacks.total == 0 or allStacks.max.expirationTime < expirationTime then
			allStacks.max.duration = duration
			allStacks.max.expirationTime = expirationTime
		end 
		allStacks.total = allStacks.total + count
	end
end

function Bar:ResetScratchStacks(auraStacks)
	auraStacks.total = 0
end


-- --------
-- OnUpdate
-- --------

function Bar:OnUpdate(elapsed)
	-- Called very frequently. Make sure it's efficient. 
	local now = GetTime()
	if now > self.nextUpdate then
		self.nextUpdate = now + 0.025  -- now + UPDATE_INTERVAL, 40 /sec

		if self.isBlinking then
			self:UpdateBlink(elapsed)
			return
		end
        
		if self.duration and self.duration > 0 then
			local duration = self.fixedDuration or self.duration
			local bar1_timeLeft = self.expirationTime - now
			if bar1_timeLeft < 0 then
				if self.settings.BuffOrDebuff == "CASTCD" or
					self.settings.BuffOrDebuff == "BUFFCD" or
					self.settings.BuffOrDebuff == "EQUIPSLOT"
				then
					-- Item cooldowns don't fire event when they expire.
					-- Other cooldowns fire event too soon. So keep checking.
					self:CheckAura()
					return
				end
				bar1_timeLeft = 0
			end
			self:SetValue(self.bar1, bar1_timeLeft)

			if self.settings.show_time then
				self.time:SetText(self:FormatTime(bar1_timeLeft))
			end
            
			if self.settings.show_spark and bar1_timeLeft <= duration then
				self.spark:SetPoint("CENTER", self, "LEFT", self:GetWidth() * bar1_timeLeft/duration, 0)
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


