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
	self:SetSpells()
	self:SetBarType()
	self:SetTrackingOptions()
	self:SetAppearanceOptions()
	self:SetAppearance()

	if NeedToKnow.isLocked then
		if self.isEnabled and groupSettings.Enabled then
			self:EnableMouse(false)  -- Click through
			self:Activate()
			self:UpdateTracking()
		else
			self:Inactivate()
			self:Hide()
		end
	else
		self:Inactivate()
		self:Unlock()
	end
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
end

function Bar:SetBarType()
	-- Must be called after Bar:SetSpells because SpellCooldown 
	-- uses name/ID to determine if spell or item cooldown
	self.barType = self.settings.BuffOrDebuff
	local barTypeMixin = {
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
	-- BarType mixins provide
	--   self:SetBarTypeInfo,
	--   self:SetBarTypeSpells,
	--   self:SetbarTypeOptions, 
	--   self:RegisterBarTypeEvents, 
	--   self:UnregisterBarTypeEvents, 
	--   Most self:EVENTS, 
	--   self:GetTrackedInfo, 
	--   self:ProcessTrackedInfo,  -- Deprecated
	--   ...
	self:SetBarTypeOptions()
end

function Bar:SetTrackingOptions()
	-- Setting names can be nonintuitive so let's corral them. 
	-- Must be called after Bar:SetBarTypeOptions because several bar 
	--   types (cooldowns/etc) set settings.Unit to "player"

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

	self.showAllStacks = settings.show_all_stacks
	if self.showAllStacks then
		self.UpdateTracking = self.UpdateTrackingAllStacks
		self.CheckAura = self.UpdateTrackingAllStacks  -- Deprecated alias
	else
		self.UpdateTracking = self.UpdateTrackingSingle
		self.CheckAura = self.UpdateTrackingSingle  -- Deprecated alias
	end

	self.isEnabled = settings.Enabled
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

function Bar:Activate()
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self.nextUpdate = GetTime()
	self:RegisterBarTypeEvents()
	if self.showBlink then
		self:RegisterBlinkEvents()
	end
end

function Bar:Inactivate()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:UnregisterBarTypeEvents()
	self:ClearExtendedTime()
	self.isBlinking = nil
	self:UnregisterBlinkEvents()
end


--[[ Bar tracking behavior ]]--

function Bar:OnEvent(event, unit, ...)
	local f = self[event]
	if f then
		f(self, unit, ...)
	end
end

function Bar:UpdateTrackingSingle()
	-- Get first instance of tracked aura/etc then act on info
	-- Primary update call for active bars, called by many functions
	-- Called as Bar:UpdateTracking

	local trackedInfo
	local unitExists = self:UnitExists()
	if unitExists then
		for _, spellEntry in pairs(self.spells) do
			trackedInfo = self:GetTrackedInfo(spellEntry)
			if trackedInfo then break end
		end
	end
	trackedInfo = self:ProcessTrackedInfo(trackedInfo)  -- Deprecated

	if trackedInfo then
		self:OnTrackedPresent(trackedInfo)
	else
		self:OnTrackedAbsent(unitExists)
	end
	if self.condenseGroup then
		self:CondenseBarGroup()
	end
end

function Bar:UpdateTrackingAllStacks()
	-- Get all instances of tracked aura/etc then act on info
	-- Primary update call for active bars, called by many functions
	-- Called as Bar:UpdateTracking

	local trackedInfo, newInfo
	local unitExists = self:UnitExists()
	if unitExists then
		for _, spellEntry in pairs(self.spells) do
			newInfo = self:GetTrackedInfo(spellEntry)
			trackedInfo = self:SumTrackedInfo(newInfo, trackedInfo)
		end
	end
	trackedInfo = self:ProcessTrackedInfo(trackedInfo)  -- Deprecated

	if trackedInfo then
		self:OnTrackedPresent(trackedInfo)
	else
		self:OnTrackedAbsent(unitExists)
	end
	if self.condenseGroup then
		self:CondenseBarGroup()
	end
end

--[[
	GetTrackedInfo() defined by BarTypeMixin
	Returns trackedInfo = { 
		name = string, 
		iconID = number, 
		count = number,  -- Count for shown instance only
		duration = number, 
		expirationTime = number, 
		-- extraValues = table of numbers,  -- Not yet implemented
		shownName = string, 
		stacks = number,  -- How many instances (for showAllStacks)
	}
]]--

function Bar:SumTrackedInfo(newInfo, trackedInfo)
	-- Combine info from multiple spells/instances to show sum of all
	-- Called by Bar:UpdateTrackingAllStacks, Bar:GetAuraInfoAllStacks

	if not trackedInfo then return newInfo end
	if not newInfo then return trackedInfo end

	-- Show name/etc for last to expire
	if newInfo.expirationTime > trackedInfo.expirationTime then
		trackedInfo.name = newInfo.name
		trackedInfo.iconID = newInfo.iconID
		trackedInfo.count = newInfo.count
		trackedInfo.expirationTime = newInfo.expirationTime
		trackedInfo.shownName = newInfo.shownName
	end
	if newInfo.duration > trackedInfo.duration then
		trackedInfo.duration = newInfo.duration
	end
	-- extraValues not yet implemented
	trackedInfo.stacks = newInfo.stacks + trackedInfo.stacks

	return trackedInfo
end

function Bar:OnTrackedPresent(trackedInfo)
	-- Update bar to show status of tracked aura/cooldown/etc

	local duration = trackedInfo.duration

	self.name = trackedInfo.name
	self.iconID = trackedInfo.iconID
	self.count = trackedInfo.count
	self.duration = duration
	self.expirationTime = trackedInfo.expirationTime
	self.shownName = trackedInfo.shownName
	-- extraValues not yet implemented
	self.stacks = trackedInfo.stacks

	-- Deprecated aliases
	self.buffName = self.name
	self.iconPath = self.iconID

	if duration > 0 then
		self.maxTimeLeft = self.groupDuration or duration
	else
		-- Indefinite aura (duration == 0)
		self.maxTimeLeft = self.groupDuration or 1
	end

	if self.showExtendedTime then
		self:UpdateExtendedTime(trackedInfo)
	end

	self.isBlinking = false
	self:UpdateAppearance()
	self:SetLockedText()
	self:Show()
	self:OnUpdate(0)
end

function Bar:OnTrackedAbsent(unitExists)
	-- Update bar to show tracked aura/cooldown/etc is absent

	self.name = nil
	self.iconID = nil  -- Keep icon for blink?
	self.count = nil
	self.duration = nil
	self.expirationTime = nil
	self.shownName = nil
	self.stacks = nil

	-- Deprecated aliases
	self.buffName = nil
	self.iconPath = nil

	self.maxTimeLeft = 1

	if self.showExtendedTime then
		self:ClearExtendedTime()
	end

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
			self:UpdateTracking()
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


