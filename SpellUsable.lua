-- Track reactive spell and abilities

local _, NeedToKnow = ...
NeedToKnow.SpellUsableBarMixin = {}
local BarMixin = NeedToKnow.SpellUsableBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
	self:UnregisterEvent("SPELL_UPDATE_USABLE")
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("SPELL_UPDATE_USABLE")
end

-- function BarMixin:EXAMPLE_EVENT() end

