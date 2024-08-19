-- Track spell and item cooldowns

local _, NeedToKnow = ...
NeedToKnow.SpellCooldownBarMixin = {}
local BarMixin = NeedToKnow.SpellCooldownBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = true  
		-- For Bar:OnUpdate. 
		-- No event when item cooldowns expire. Others fire too soon. 
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
end

-- function BarMixin:EXAMPLE_EVENT() end

