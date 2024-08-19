-- Track equipped item cooldowns by inventorySlotID

local _, NeedToKnow = ...
NeedToKnow.EquipCooldownBarMixin = {}
local BarMixin = NeedToKnow.EquipCooldownBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event when item cooldowns expire. 
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

-- function BarMixin:EXAMPLE_EVENT() end

