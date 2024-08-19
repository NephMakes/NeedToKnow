-- Track buff cooldowns (passive internal cooldowns on procs)

local _, NeedToKnow = ...
NeedToKnow.BuffCooldownBarMixin = {}
local BarMixin = NeedToKnow.BuffCooldownBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = true
		-- For Bar:OnUpdate. No event that fires on expire. 
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
	self:RegisterEvent("UNIT_AURA")
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("UNIT_AURA")
end

-- function BarMixin:EXAMPLE_EVENT() end

