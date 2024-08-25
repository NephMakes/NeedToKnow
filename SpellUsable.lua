-- Track reactive spell and abilities

local _, NeedToKnow = ...
NeedToKnow.SpellUsableBarMixin = {}
local BarMixin = NeedToKnow.SpellUsableBarMixin

local IsUsableSpell = C_Spell.IsSpellUsable or IsUsableSpell
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	-- Functions where Classic and Retail versions have different return structure
	GetSpellInfo = function(spell) 
		local info = C_Spell.GetSpellInfo(spell)
		if info then
			return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
	end
end


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:SetBarTypeSpells()
	-- Nothing to do
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("SPELL_UPDATE_USABLE")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("SPELL_UPDATE_USABLE")
end

function BarMixin:SPELL_UPDATE_USABLE()
	self:UpdateTracking()
end

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get info for reactive spell or ability
	local spell = spellEntry.name or spellEntry.id
	if not spell then return end
	local spellName, _, icon = GetSpellInfo(spell)
	if not spellName then return end
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

