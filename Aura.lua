-- Track auras (buffs and debuffs)

local _, NeedToKnow = ...
NeedToKnow.AuraBarMixin = {}
local BarMixin = NeedToKnow.AuraBarMixin


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
--	local settings = self.settings
--
--	-- Set tracking function
--	if settings.show_all_stacks then
--		self.GetTrackedInfo = self.GetAuraInfoAllStacks
--	else
--		self.GetTrackedInfo = self.GetAuraInfo
--	end
--
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

