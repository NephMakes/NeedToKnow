-- Bar tracking behavior

local _, NeedToKnow = ...

local Bar = NeedToKnow.Bar
local Cooldown = NeedToKnow.Cooldown
local ExecutiveFrame = NeedToKnow.ExecutiveFrame
local String = NeedToKnow.String

local INVSLOT_MAINHAND = INVSLOT_MAINHAND
local INVSLOT_OFFHAND = INVSLOT_OFFHAND
local INVSLOT_RANGED = INVSLOT_RANGED

-- Local versions of frequently-used global functions
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetAuraDataBySpellName = C_UnitAuras.GetAuraDataBySpellName
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local GetInventoryItemID = GetInventoryItemID
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo
local IsUsableSpell = C_Spell.IsSpellUsable or IsUsableSpell
local UnitExists = UnitExists
local UnitGUID = UnitGUID

-- Functions different between Retail and Classic as of 11.0.0
local GetSpellInfo = GetSpellInfo
local function GetRetailSpellInfo(spell)
	local info = C_Spell.GetSpellInfo(spell)  -- Only in Retail
	if info then
		return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
	end
end
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	GetSpellInfo = GetRetailSpellInfo
end


--[[ Bar setup ]]--

function Bar:Update()
	-- Update bar behavior and appearance
	-- Called by BarGroup:Update() and various BarMenu:Methods()
	-- when addon loaded, locked/unlocked, or bar configuration changed

	local groupID = self:GetParent():GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	self.settings = groupSettings.Bars[self:GetID()]

	self:SetBarType()
	self:SetSpells()
	self:SetAppearance()

	self.groupDuration = tonumber(groupSettings.FixedDuration)
	if not self.groupDuration or self.groupDuration <= 0 then
		self.groupDuration = nil
	end
	self.condenseGroup = groupSettings.condenseGroup

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

function Bar:SetBarType()
	-- Called by Bar:Update()

	local settings = self.settings
	self.barType = settings.BuffOrDebuff
	local barType = self.barType

	-- BarType mixins provide Bar:SetBarTypeInfo, ...
	local barTypeMixin = {
		HELPFUL = NeedToKnow.AuraBarMixin, 
		HARMFUL = NeedToKnow.AuraBarMixin, 
		-- EQUIPBUFF = NeedToKnow.EquipBuffBarMixin, 
		USABLE = NeedToKnow.SpellUsableBarMixin, 
		TOTEM = NeedToKnow.TotemBarMixin, 
		CASTCD = NeedToKnow.SpellCooldownBarMixin, 
		EQUIPSLOT = NeedToKnow.EquipCooldownBarMixin, 
		BUFFCD = NeedToKnow.BuffCooldownBarMixin, 
	}
	Mixin(self, barTypeMixin[barType])

	self:SetBarTypeInfo()

	-- Set unit
	if barType == "BUFFCD" or 
		barType == "TOTEM" or 
		barType == "USABLE" or 
		barType == "EQUIPSLOT" or 
		barType == "EQUIPBUFF" or 
		barType == "CASTCD" 
	then
		settings.Unit = "player"
	end
	self.unit = settings.Unit

	-- Set UnitExists function
	if settings.Unit == "player" then
		self.UnitExists = Bar.UnitExistsPlayer
	elseif settings.Unit == "lastraid" then
		self.UnitExists = Bar.UnitExistsLastRaid
	else
		self.UnitExists = Bar.UnitExists
	end

	-- Set tracking functions
	if barType == "BUFFCD" then
		self.GetTrackedInfo = self.GetBuffCooldownInfo
		local duration = tonumber(settings.buffcd_duration)
		if not duration or duration < 1 then
			print("NeedToKnow: Please set internal cooldown time for ", settings.AuraName)
		end
	elseif barType == "TOTEM" then
		self.GetTrackedInfo = self.GetTotemInfo
	elseif barType == "USABLE" then
		self.GetTrackedInfo = self.GetSpellUsableInfo
	elseif barType == "EQUIPSLOT" then
		self.GetTrackedInfo = self.GetEquipCooldownInfo
	elseif barType == "CASTCD" then
		self.GetTrackedInfo = self.GetCooldownInfo
	elseif barType == "EQUIPBUFF" then
		self.GetTrackedInfo = self.GetEquipBuffInfo
	elseif settings.show_all_stacks then
		self.GetTrackedInfo = self.GetAuraInfoAllStacks
	else
		self.GetTrackedInfo = self.GetAuraInfo
	end

	-- Should Bar:OnUpdate check tracked spell when time runs out
	self.checkOnNoTimeLeft = nil
	if barType == "CASTCD" or 
		self.barType == "BUFFCD" or 
		self.barType == "EQUIPSLOT" 
	then
		-- Item cooldowns don't fire event on expire. Others fire too soon. 
		self.checkOnNoTimeLeft = true
	end
end

function Bar:UnitExists()
	return UnitExists(self.unit)
end

function Bar:UnitExistsPlayer()
	return true
end

function Bar:UnitExistsLastRaid()
	-- self.unit set by Bar:PLAYER_SPELLCAST_SUCCEEDED
	return self.unit and UnitExists(self.unit)
end

function Bar:SetSpells()
	-- Set spells/items/abilities tracked by bar
	-- Stored as bar.spells = {{name, id, shownName, ...}, }
	-- Called by Bar:Update

	local settings = self.settings

	local spellNames = {}
	-- for spellName in settings.AuraName:gmatch("([^;]+)") do  -- Not yet
	for spellName in settings.AuraName:gmatch("([^,]+)") do
		table.insert(spellNames, strtrim(spellName))
	end

	local shownNames = {}
	-- for shownName in settings.show_text_user:gmatch("([^;]+)") do  -- Not yet
	for shownName in settings.show_text_user:gmatch("([^,]+)") do
		table.insert(shownNames, strtrim(shownName))
	end

	self.spells = {}
	for i, spellName in ipairs(spellNames) do
		local spellEntry = {}
		local _, numDigits = string.find(spellName, "^-?%d+")
		if numDigits == string.len(spellName) then
			spellEntry.id = tonumber(spellName)  -- Track by ID
		else
			spellEntry.name = spellName  -- Track by name
		end

		if shownNames[i] then
			spellEntry.shownName = shownNames[i]
		elseif shownNames[1] then
			spellEntry.shownName = shownNames[math.min(#shownNames, #spellNames)]
		elseif self.barType == "EQUIPSLOT" or self.barType == "EQUIPBUFF" then
			spellEntry.shownName = String.GetInventorySlotName(spellName)
		end

		table.insert(self.spells, spellEntry)
	end

	if self.barType == "CASTCD" then
		self:SetCooldownSpells()
	elseif self.barType == "BUFFCD" then
		self:SetBuffCooldownResetSpells()
	end
end

function Bar:SetBuffCooldownResetSpells()
	-- Set spells that reset buff cooldown
	-- For example: a Classic Druid's Eclipse resets cooldown on Nature's Grace
	local settings = self.settings
	if settings.buffcd_reset_spells and settings.buffcd_reset_spells ~= "" then
		self.reset_spells = {}
		self.reset_start = {}
		local spellIndex = 0
		-- for resetSpell in settings.buffcd_reset_spells:gmatch("([^;]+)") do  -- Not yet
		for resetSpell in settings.buffcd_reset_spells:gmatch("([^,]+)") do
			spellIndex = spellIndex + 1
			resetSpell = strtrim(resetSpell)
			local _, numDigits = resetSpell:find("^%d+")
			if numDigits == resetSpell:len() then
				table.insert(self.reset_spells, {id = tonumber(resetSpell)})
			else
				table.insert(self.reset_spells, {name = resetSpell})
			end
			table.insert(self.reset_start, 0)
		end
	else
		self.reset_spells = nil
		self.reset_start = nil
	end
end

function Bar:Activate()
	-- Called by Bar:Update if NeedToKnow is locked

	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self.nextUpdate = GetTime()

	local settings = self.settings
	local barType = self.barType

	-- Tracking events
	if barType == "TOTEM" then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	elseif barType == "CASTCD" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	elseif barType == "EQUIPSLOT" then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	elseif barType == "EQUIPBUFF" then
		-- self:RegisterEvent("WEAPON_ENCHANT_CHANGED")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	elseif barType == "USABLE" then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	elseif self.unit == "targettarget" then
		-- We don't get UNIT_AURA for target of target
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		self:RegisterCombatLog() 
	else
		self:RegisterEvent("UNIT_AURA")
	end

	-- Unit events
	if self.unit == "target" then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif self.unit == "focus" then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif self.unit == "pet" then
		self:RegisterEvent("UNIT_PET")
		-- self:RegisterUnitEvent("UNIT_PET", "pet")  -- TODO
	elseif settings.Unit == "lastraid" then
		self:RegisterLastRaid()
	end

	if settings.bDetectExtends then
		self:RegisterExtendedTime()
	end

	-- Blink events
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
		"PLAYER_REGEN_DISABLED", 
		"PLAYER_REGEN_ENABLED", 
		"PLAYER_TARGET_CHANGED", 
		"PLAYER_TOTEM_UPDATE", 
		"SPELL_UPDATE_COOLDOWN", 
		"SPELL_UPDATE_USABLE", 
		"UNIT_AURA", 
		"UNIT_PET", 
		"UNIT_TARGET", 
--		"WEAPON_ENCHANT_CHANGED", 
--		"UNIT_INVENTORY_CHANGED", 
	}
	for _, event in pairs(eventList) do
		self:UnregisterEvent(event)
	end

	self.isBlinking = nil
	self:UnregisterBossFight()
	self:UnregisterExtendedTime()
	self:UnregisterLastRaid()
end


--[[ Events ]]--

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
	-- For Bar:COMBAT_LOG_EVENT_UNFILTERED
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

--[[
function Bar:WEAPON_ENCHANT_CHANGED(...)
	-- Event only in Retail
	-- print("NeedToKnow: WEAPON_ENCHANT_CHANGED")
end

function Bar:UNIT_INVENTORY_CHANGED(unit, ...)
--	if unit == "player" then
--		print("NeedToKnow: UNIT_INVENTORY_CHANGED", unit)
--	end
	self:CheckAura()
end
]]--


--[[ Tracking behavior ]]--

-- Kitjan made m_scratch a reusable table to track multiple instances of an aura with one bar
local m_scratch = {}
m_scratch.all_stacks = {
	-- Stores tracked info
	min = {
		buffName = "", 
		duration = 0, 
		expirationTime = 0, 
		icon = "",
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
		icon = "",
	},
	max = {
		duration = 0, 
		expirationTime = 0, 
	},
	total = 0,
}

function Bar:CheckAura()
	-- Get info for tracked spell/item/ability and act on it
	-- Primary update call for active bars, called by many functions

	local settings = self.settings
	local allStacks, name, icon, count, duration, expirationTime, shownName

	-- Get info
	local unitExists = self:UnitExists()
	if unitExists then
		allStacks = m_scratch.all_stacks
		self:ResetScratchStacks(allStacks)
		for _, spellEntry in pairs(self.spells) do
			self:GetTrackedInfo(spellEntry, allStacks)
			if allStacks.total > 0 and not settings.show_all_stacks then
				break
			end
		end
		if allStacks.total > 0 then
			name = allStacks.min.name
			icon = allStacks.min.icon
			count = allStacks.total
			if settings.show_all_stacks then
				duration = allStacks.max.duration
				expirationTime = allStacks.max.expirationTime
			else
				duration = allStacks.min.duration
				expirationTime = allStacks.min.expirationTime
			end
			shownName = allStacks.min.shownName
		end
	end
	if self.barType == "BUFFCD" and self.reset_spells and duration then
		duration = self:GetBuffCooldownReset(duration, expirationTime)
	end

	-- Act on info
	if duration then
		self:OnDurationFound(name, icon, count, duration, expirationTime, shownName)
	else
		self:OnDurationAbsent(unitExists)
	end
	if self.condenseGroup then
		self:CondenseBarGroup()
	end
end

function Bar:GetBuffCooldownReset(duration, expirationTime)
	-- For example Classic Druid Eclipse resets internal cooldown on Nature's Grace
	local maxStart = 0
	local tNow = GetTime()
	local buff_stacks = m_scratch.buff_stacks
	self:ResetScratchStacks(buff_stacks)
	-- Track when reset auras last applied to player
	for i, resetSpell in ipairs(self.reset_spells) do
		local resetDuration, _, _, resetExpiration = self:GetAuraInfo(resetSpell, buff_stacks)
		local tStart
		if buff_stacks.total > 0 then
			if 0 == buff_stacks.max.duration then 
				tStart = self.reset_start[i]
				if 0 == tStart then
					tStart = tNow
				end
			else
				tStart = buff_stacks.max.expirationTime - buff_stacks.max.duration
			end
			self.reset_start[i] = tStart
			if tStart > maxStart then 
				maxStart = tStart 
			end
		else
			self.reset_start[i] = 0
		end
	end
	if maxStart > expirationTime - duration then
		duration = nil
	end
	return duration
end

function Bar:GetTrackedInfo()
	-- Default null function that gets replaced in Bar:SetBarType
end

function Bar:GetAuraInfo(spellEntry, allStacks)
	-- Get tracking info for first instance of buff/debuff
	-- Called by Bar:CheckAura, Bar:GetBuffCooldownInfo, Bar:GetBuffCooldownReset

	local filter = self.barType  -- "HELPFUL" or "HARMFUL"
	if self.barType == "BUFFCD" then
		filter = "HELPFUL"
	end
	if self.settings.OnlyMine then
		filter = filter.."|PLAYER"
	end

	local aura
	local entryName = spellEntry.name
	local entryID = spellEntry.id
	if entryName then
		aura = GetAuraDataBySpellName(self.unit, entryName, filter)
	elseif entryID and (self.unit == "player") then
		aura = GetPlayerAuraBySpellID(entryID)
	elseif entryId then
		local i = 1
		while true do
			local thisAura = GetAuraDataByIndex(self.unit, i, filter)
			if not thisAura then break end
			if thisAura.spellId == entryID then
				aura = thisAura
				break
			end
			i = i + 1
		end
	end
	if aura then
		self:AddTrackedInfo(allStacks, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, spellEntry.shownName, unpack(aura.points))
	end
end

function Bar:GetAuraInfoAllStacks(spellEntry, allStacks)
	-- Get tracking info for all instances of buff/debuff
	local filter = self.barType  -- "HELPFUL" or "HARMFUL"
	if self.settings.OnlyMine then
		filter = filter.."|PLAYER"
	end
	local aura
	local i = 1
	while true do
		aura = GetAuraDataByIndex(self.unit, i, filter)
		if not aura then break end
		if aura.name == spellEntry.name or aura.spellId == spellEntry.id then 
			self:AddTrackedInfo(allStacks, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, spellEntry.shownName, unpack(aura.points))
		end
		i = i + 1
	end
end

function Bar:GetSpellUsableInfo(spellEntry, allStacks)
	-- Get tracking info for reactive spell/ability
	local spell = spellEntry.name or spellEntry.id
	if not spell then return end
	local spellName, _, icon = GetSpellInfo(spell)
	if spellName then
		local isUsable, notEnoughMana = IsUsableSpell(spellName)
		if isUsable or notEnoughMana then
			local duration, expirationTime
			local now = GetTime()
			if not self.expirationTime or 
				(self.expirationTime > 0 and self.expirationTime < now - 0.01) 
			then
				duration = self.settings.usable_duration  -- Has to be set by user :(
				expirationTime = now + duration
			else
				duration = self.duration
				expirationTime = self.expirationTime
			end
			self:AddTrackedInfo(allStacks, duration, spellName, 1, expirationTime, icon, spellEntry.shownName)
		end
	end
end

function Bar:GetCooldownInfo(spellEntry, allStacks)
	-- Get tracking info for spell or item cooldown

	local GetCooldown = spellEntry.cooldownFunction
	if not GetCooldown then return end
	local start, duration, _, name, icon, count, start2 = GetCooldown(self, spellEntry)

	-- Filter out global cooldown
	if start and (duration <= 1.5) then
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
				self:AddTrackedInfo(allStacks, duration, name, 1, start2 + duration, icon, spellEntry.shownName)
				count = count - 1
			else
				if not count then count = 1 end
			end
			self:AddTrackedInfo(allStacks, duration, name, count, expirationTime, icon, spellEntry.shownName)
		end
	end
end

function Bar:GetEquipCooldownInfo(spellEntry, allStacks)
	-- Get tracking info for cooldown of equipped item 
	-- by inventorySlotID (stored as spellEntry.id)
	if not spellEntry.id then return end
	local start, duration, enable = GetInventoryItemCooldown("player", spellEntry.id)
	if start and start > 0 then
		local icon = GetInventoryItemTexture("player", spellEntry.id)
		self:AddTrackedInfo(allStacks, duration, name, 1, start + duration, icon, spellEntry.shownName)
	end
end

function Bar:GetEquipBuffInfo(spellEntry, allStacks)
	-- NOT YET IMPLEMENTED
	-- Get tracking info for temporary weapon enhancement (poison, sharpening 
	-- stone, etc) by inventorySlotID

	local count, timeLeft, enchantID, expirationTime

	local _, mainHandTimeLeft, mainHandCharges, mainHandEnchantID, _, offHandTimeLeft, offHandCharges, offHandEnchantID, _, rangedTimeLeft, rangedCharges, rangedEnchantID = GetWeaponEnchantInfo()

	local slotID = spellEntry.id
	if slotID == INVSLOT_MAINHAND then
		count = mainHandCharges
		timeLeft = mainHandTimeLeft
		enchantID = mainHandEnchantID
	elseif slotID == INVSLOT_OFFHAND then
		count = offHandCharges
		timeLeft = offHandTimeLeft
		enchantID = offHandEnchantID
	elseif slotID == INVSLOT_RANGED then
		count = rangedCharges
		timeLeft = rangedTimeLeft
		enchantID = rangedEnchantID
	end

	-- local duration  -- How to get? 

	if count then
		count = math.max(count, 1)
	end

	if timeLeft then
		local now = GetTime()
		timeLeft = timeLeft / 1000
		expirationTime = now + timeLeft
	end

	local icon = GetInventoryItemTexture("player", slotID)
	-- TO DO: Can we show name/icon of enchant instead of weapon slot?

	-- print("FindEquipSlotBuff()", spellEntry.shownName, timeLeft)
	-- self:AddTrackedInfo(allStacks, duration, spellEntry.id, count, expirationTime, icon, spellEntry.shownName)
end

-- Old tooltip-scanning code: 
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

function Bar:GetTotemInfo(spellEntry, allStacks)
	-- Get tracking info for shaman totem
	local spellName = spellEntry.name or GetSpellInfo(spellEntry.id)
	for index = 1, 4 do
		local _, name, startTime, duration, icon = GetTotemInfo(index)  
		if name and name:find(spellName) then
			self:AddTrackedInfo(allStacks, duration, name, 1, startTime + duration, icon, spellEntry.shownName)
			return
		end
	end
end

function Bar:GetBuffCooldownInfo(spellEntry, allStacks)
	-- Get tracking info for buff cooldown (internal cooldown on proc)

	local buffStacks = m_scratch.buff_stacks
	self:ResetScratchStacks(buffStacks)
	self:GetAuraInfo(spellEntry, buffStacks)

	local now = GetTime()
	if buffStacks.total > 0 then
		local duration = tonumber(self.settings.buffcd_duration)
		if buffStacks.max.expirationTime == 0 then
			-- TODO: This doesn't work well as a substitute for telling when the aura was applied
			if not self.expirationTime then
				self:AddTrackedInfo(allStacks, duration, buffStacks.min.name, 1, duration + now, buffStacks.min.icon, spellEntry.shownName)
			else
				self:AddTrackedInfo(allStacks, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, spellEntry.shownName)
			end
			return
		end

		local start = buffStacks.max.expirationTime - buffStacks.max.duration
		local expirationTime = start + duration
		if expirationTime > now then
			self:AddTrackedInfo(allStacks, duration, buffStacks.min.name, 1, expirationTime, buffStacks.min.icon, spellEntry.shownName)                   
		end
	elseif self.expirationTime and self.expirationTime > now + 0.1 then
		self:AddTrackedInfo(allStacks, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, spellEntry.shownName)
	end
end

function Bar:ResetScratchStacks(stacks)
	stacks.total = 0
end

function Bar:AddTrackedInfo(allStacks, duration, name, count, expirationTime, icon, shownName, value1, value2, value3)
	if not duration then return end
	if not count or count < 1 then 
		count = 1 
	end
	if allStacks.total == 0 or expirationTime < allStacks.min.expirationTime then
		allStacks.min.name = name
		allStacks.min.icon = icon
		allStacks.min.duration = duration
		allStacks.min.expirationTime = expirationTime
		allStacks.min.shownName = shownName
	end
	if allStacks.total == 0 or expirationTime > allStacks.max.expirationTime then
		allStacks.max.duration = duration
		allStacks.max.expirationTime = expirationTime
	end 
	allStacks.total = allStacks.total + count
end

function Bar:OnDurationFound(name, icon, count, duration, expirationTime, shownName)
	-- Update bar to show status of tracked spell/item/ability
	-- Called by Bar:CheckAura

	local settings = self.settings

	local extended
	if settings.bDetectExtends then
		extended, duration = self:GetExtendedTime(name, duration, expirationTime, self.unit)
	end

	self.buffName = name
	self.iconPath = icon
	self.count = count
	self.duration = duration
	self.expirationTime = expirationTime
	self.shownName = shownName
	self.extendedTime = extended

	if duration > 0 then
		self.maxTimeLeft = self.groupDuration or duration
	else
		-- Indefinite aura (duration == 0)
		self.maxTimeLeft = self.groupDuration or 1
	end
	self.isBlinking = false

	self:UpdateAppearance()
	self:SetLockedText()
	self:Show()
	self:OnUpdate(0)
end

function Bar:OnDurationAbsent(unitExists)
	-- Update bar to show tracked buff/debuff/cooldown is absent
	-- Called by Bar:CheckAura

	local settings = self.settings

	if settings.bDetectExtends and self.buffName then
		self:ClearExtendedTime()
	end

	self.buffName = nil
	self.iconPath = nil
	self.count = nil
	self.duration = nil
	self.expirationTime = nil
	self.shownName = nil
	self.extendedTime = nil

	self.maxTimeLeft = 1

	if self:ShouldBlink(settings, unitExists) then
		self:Blink(settings)
		self:Show()
		self:OnUpdate(0)
	else    
		self.isBlinking = false
		self:Hide()
	end
end

function Bar:OnUpdate(elapsed)
	-- Called very frequently. Be efficient. 

	local now = GetTime()
	if now < self.nextUpdate then return end
	self.nextUpdate = now + 0.025  -- 40/sec

	if self.isBlinking then
		self:UpdateBlink(elapsed)
		return
	end

	if not self.duration or self.duration <= 0 then return end
		-- Indefinite auras have duration == 0

	local timeLeft = self.expirationTime - now
	if timeLeft < 0 then
		if self.checkOnNoTimeLeft then
			self:CheckAura()
			return
		end
		timeLeft = 0
	end

	self:SetValue(timeLeft)
	if self.settings.show_spark and timeLeft <= self.maxTimeLeft then
		self.Spark:Show()
	else
		self.Spark:Hide()
	end
	if self.settings.show_time then
		self.Time:SetText(self:FormatTime(timeLeft))
	end
	if self.settings.vct_enabled and self.refreshCastTime then
		self:UpdateCastTime()
	end
end


