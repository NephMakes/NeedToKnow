-- Track temporary buffs on equipped items
-- For example: Poisons and sharpening stones on weapons
-- NOT YET IMPLEMENTED

local _, NeedToKnow = ...
NeedToKnow.EquipBuffBarMixin = {}
local BarMixin = NeedToKnow.EquipBuffBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = false  -- For Bar:OnUpdate
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	-- self:RegisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	-- self:UnregisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

-- function BarMixin:EXAMPLE_EVENT() end

