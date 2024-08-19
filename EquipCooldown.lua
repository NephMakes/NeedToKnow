-- Track equipped item cooldowns by inventorySlotID

local _, NeedToKnow = ...
NeedToKnow.EquipCooldownBarMixin = {}
local BarMixin = NeedToKnow.EquipCooldownBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = true
		-- For Bar:OnUpdate. Item cooldowns don't fire event on expire. 
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
end

-- function BarMixin:EXAMPLE_EVENT() end

