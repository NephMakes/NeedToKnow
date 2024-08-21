-- Track totems

local _, NeedToKnow = ...
NeedToKnow.TotemBarMixin = {}
local BarMixin = NeedToKnow.TotemBarMixin

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetTotemInfo
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:SetBarTypeSpells()
	-- Nothing to do
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
end

function BarMixin:PLAYER_TOTEM_UPDATE(totemSlot)
	self:UpdateTracking()
end
