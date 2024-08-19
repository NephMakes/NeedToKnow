-- Track totems

local _, NeedToKnow = ...
NeedToKnow.TotemBarMixin = {}
local BarMixin = NeedToKnow.TotemBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType

	-- Set tracking function

	-- Set other info
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:RegisterBarTypeEvents()
	-- Called by Bar:Activate
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
end

-- function BarMixin:EXAMPLE_EVENT() end

