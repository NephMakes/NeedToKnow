-- Bar tracking behavior

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

local GetTime = GetTime
local UnitExists = UnitExists


--[[ Bar setup ]]--

function Bar:Update()
	-- Update bar behavior and appearance
	-- Called by BarGroup:Update() and various BarMenu:Methods()
	-- when addon loaded, locked/unlocked, or bar configuration changed

	local groupSettings = self:GetParent().settings
	self.settings = groupSettings.Bars[self:GetID()]

	self:SetBarType()
	self:SetTrackingOptions()
	self:SetAppearanceOptions()
	self:SetSpells()
	self:SetAppearance()

	if NeedToKnow.isLocked then
		if self.isEnabled and groupSettings.Enabled then
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
	self.barType = self.settings.BuffOrDebuff
	local barTypeMixin = {
		-- BarType mixins provide
		--   Bar:SetBarTypeInfo,
		--   Bar:SetBarTypeSpells,
		--   Bar:RegisterBarTypeEvents, 
		--   Bar:UnregisterBarTypeEvents, 
		--   Most Bar:EVENTS, 
		--   Bar:GetTrackedInfo, 
		--   ...
		HELPFUL = NeedToKnow.AuraBarMixin, 
		HARMFUL = NeedToKnow.AuraBarMixin, 
		EQUIPBUFF = NeedToKnow.EquipBuffBarMixin, 
		USABLE = NeedToKnow.SpellUsableBarMixin, 
		TOTEM = NeedToKnow.TotemBarMixin, 
		CASTCD = NeedToKnow.SpellCooldownBarMixin, 
		EQUIPSLOT = NeedToKnow.EquipCooldownBarMixin, 
		BUFFCD = NeedToKnow.BuffCooldownBarMixin, 
	}
	Mixin(self, barTypeMixin[self.barType])
	self:SetBarTypeInfo()
end

function Bar:SetTrackingOptions()
	-- Setting names can be nonintuitive so let's corral them
	local settings = self.settings

	local unit = settings.Unit
	self.unit = unit
	if unit == "player" then
		self.UnitExists = Bar.UnitExistsPlayer
	elseif unit == "lastraid" then
		self.UnitExists = Bar.UnitExistsLastRaid
	else
		self.UnitExists = Bar.UnitExistsGeneric
	end

	self.isEnabled = settings.Enabled
	self.showAllStacks = settings.show_all_stacks
	self.showExtendedTime = settings.bDetectExtends
	self:SetBlinkOptions()
	self:SetCastTimeOptions()

	local groupSettings = self:GetParent().settings
	local groupDuration = tonumber(groupSettings.FixedDuration)
	if groupDuration and groupDuration > 0 then
		self.groupDuration = groupDuration
	else
		self.groupDuration = nil
	end
end

function Bar:UnitExistsPlayer()
	-- Called as bar:UnitExists()
	return true
end

function Bar:UnitExistsLastRaid()
	-- Called as bar:UnitExists()
	-- Bar:PLAYER_SPELLCAST_SUCCEEDED sets self.unit
	return self.unit and UnitExists(self.unit)
end

function Bar:UnitExistsGeneric()
	-- Called as bar:UnitExists()
	return UnitExists(self.unit)
end

local function GetSpellNames(settingString)
	-- Extract spell names from string entered by user
	local names = {}
	for name in settingString:gmatch("([^,]+)") do
		table.insert(names, strtrim(name))
	end
	return names
end

function Bar:SetSpells()
	-- Set spells/items/abilities tracked by bar
	-- Store as bar.spells = {{name, id, shownName, ...}, }
	self.spells = {}
	local spellNames = GetSpellNames(self.settings.AuraName)
	local shownNames = GetSpellNames(self.settings.show_text_user)
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
		end
		table.insert(self.spells, spellEntry)
	end
	self:SetBarTypeSpells()
end

function Bar:Activate()
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self.nextUpdate = GetTime()
	self:RegisterBarTypeEvents()
	if self.showBlink then
		self:RegisterBlinkEvents()
	end
	if self.showExtendedTime then
		self:RegisterExtendedTime()
	end
end

function Bar:Inactivate()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:UnregisterBarTypeEvents()
	self.isBlinking = nil
	self:UnregisterBlinkEvents()
	self:UnregisterExtendedTime()
end


--[[ Bar tracking behavior ]]--

function Bar:OnEvent(event, unit, ...)
	local f = self[event]
	if f then
		f(self, unit, ...)
	end
end

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

function Bar:CheckAura()
	-- Get info for tracked spell/item/ability and act on it
	-- Primary update call for active bars, called by many functions
	-- Called by Bar:EVENT functions

	local allStacks, name, icon, count, duration, expirationTime, shownName

	-- Get info
	local unitExists = self:UnitExists()
	if unitExists then
		allStacks = m_scratch.all_stacks
		allStacks.total = 0
		for _, spellEntry in pairs(self.spells) do
			self:GetTrackedInfo(spellEntry, allStacks)
			if allStacks.total > 0 and not self.showAllStacks then
				break
			end
		end
		if allStacks.total > 0 then
			name = allStacks.min.name
			icon = allStacks.min.icon
			count = allStacks.total
			if self.showAllStacks then
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

do
	Bar.UpdateTracking = Bar.CheckAura  -- Temporary alias
end
-- function Bar:UpdateTracking() end  -- TODO (will replace CheckAura)

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

	local extendedTime
	if self.showExtendedTime then
		extendedTime, duration = self:GetExtendedTime(name, duration, expirationTime, self.unit)
	end

	self.buffName = name
	self.iconPath = icon
	self.count = count
	self.duration = duration
	self.expirationTime = expirationTime
	self.shownName = shownName
	self.extendedTime = extendedTime

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

	if self.showExtendedTime and self.buffName then
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

	if self:ShouldBlink(unitExists) then
		self:Blink()
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
	if self.showSpark and timeLeft <= self.maxTimeLeft then
		self.Spark:Show()
	else
		self.Spark:Hide()
	end
	if self.showTime then
		self.Time:SetText(self:FormatTime(timeLeft))
	end
	if self.showCastTime and self.refreshCastTime then
		self:UpdateCastTime()
	end
end


