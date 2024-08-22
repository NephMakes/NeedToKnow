-- Track auras (buffs and debuffs)

local _, NeedToKnow = ...
NeedToKnow.AuraBarMixin = {}
local BarMixin = NeedToKnow.AuraBarMixin

local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetAuraDataBySpellName = C_UnitAuras.GetAuraDataBySpellName
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	local settings = self.settings
	if settings.show_all_stacks then
		self.GetTrackedInfo = self.GetTrackedInfoAllStacks
	else
		self.GetTrackedInfo = self.GetTrackedInfoSingle
	end
	self.filter = self.barType  -- "HELPFUL" or "HARMFUL"
	if settings.OnlyMine then
		self.filter = self.filter.."|PLAYER"
	end
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:SetBarTypeSpells()
	-- Nothing to do
end

function BarMixin:RegisterBarTypeEvents()
	local settings = self.settings
	if self.unit == "player" then
		self:RegisterUnitEvent("UNIT_AURA", "player")
	elseif self.unit == "target" then
		self:RegisterUnitEvent("UNIT_AURA", "target")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif self.unit == "focus" then
		self:RegisterUnitEvent("UNIT_AURA", "focus")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif self.unit == "pet" then
		self:RegisterUnitEvent("UNIT_AURA", "pet")
		self:RegisterUnitEvent("UNIT_PET", "player")
	elseif self.unit == "targettarget" then
		self:RegisterCombatLog() 
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterUnitEvent("UNIT_TARGET", "player", "target")
	elseif self.unit == "vehicle" then
		self:RegisterUnitEvent("UNIT_AURA", "vehicle")
		-- TODO Need event for entering/exiting/changing vehicle
	elseif settings.Unit == "lastraid" then  -- "Last raid recipient"
		-- self.unit set by Bar:PLAYER_SPELLCAST_SUCCEEDED
		self:RegisterLastRaid()
	end
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterLastRaid()
end

function BarMixin:RegisterCombatLog()
	-- For monitoring target of target
	if UnitExists(self.unit) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end


--[[ Bar tracking ]]--

function BarMixin:UNIT_AURA(unit, updateInfo)
	self:UpdateTracking()
end

function BarMixin:UNIT_TARGET(unit)
	if self.unit == "targettarget" and unit == "target" then
		self:RegisterCombatLog()
	end
	self:UpdateTracking()
end

function BarMixin:UNIT_PET(unit)
	self:UpdateTracking()
end

function BarMixin:PLAYER_TARGET_CHANGED()
	self:UpdateTracking()
end

function BarMixin:PLAYER_FOCUS_CHANGED()
	self:UpdateTracking()
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

function BarMixin:COMBAT_LOG_EVENT_UNFILTERED(unit, ...)
	-- To monitor target of target
	local _, event, _, _, _, _, _, targetGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	if auraEvents[event] then
		if targetGUID == UnitGUID(self.unit) then
			if self.buffName:find(spellID) or self.buffName:find(spellName) then 
				self:UpdateTracking()
			end
		end
	elseif event == "UNIT_DIED" then
		if targetGUID == UnitGUID(self.unit) then
			self:UpdateTracking()
		end
	end 
end

function BarMixin:GetTrackedInfoSingle(spellEntry, allStacks)
	-- Get info for first instance of buff/debuff
	local aura
	local entryName = spellEntry.name
	local entryID = spellEntry.id
	if entryName then
		aura = GetAuraDataBySpellName(self.unit, entryName, self.filter)
	elseif entryID and (self.unit == "player") then
		aura = GetPlayerAuraBySpellID(entryID)
	elseif entryID then
		local i = 1
		while true do
			local thisAura = GetAuraDataByIndex(self.unit, i, self.filter)
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

function BarMixin:GetTrackedInfoAllStacks(spellEntry, allStacks)
	-- Get info for all instances of buff/debuff
	local aura
	local i = 1
	while true do
		aura = GetAuraDataByIndex(self.unit, i, self.filter)
		if not aura then break end
		if aura.name == spellEntry.name or aura.spellId == spellEntry.id then 
			self:AddTrackedInfo(allStacks, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, spellEntry.shownName, unpack(aura.points))
		end
		i = i + 1
	end
end


