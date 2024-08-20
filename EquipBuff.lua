-- Track temporary buffs on equipped items
-- For example: Poisons and sharpening stones on weapons
-- NOT YET IMPLEMENTED

local _, NeedToKnow = ...
NeedToKnow.EquipBuffBarMixin = {}
local BarMixin = NeedToKnow.EquipBuffBarMixin

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetEquipBuffInfo
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:RegisterBarTypeEvents()
	-- NOTE: Prolly need more events (see wiki)
	self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	-- self:RegisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	-- self:UnregisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

function BarMixin:UNIT_INVENTORY_CHANGED(unit)
	self:UpdateTracking()
end

function BarMixin:WEAPON_ENCHANT_CHANGED()
	-- Only in Retail?
	self:UpdateTracking()
end

