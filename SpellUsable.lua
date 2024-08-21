-- Track reactive spell and abilities

local _, NeedToKnow = ...
NeedToKnow.SpellUsableBarMixin = {}
local BarMixin = NeedToKnow.SpellUsableBarMixin

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetSpellUsableInfo
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

