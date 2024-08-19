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
	local settings = self.settings

	-- Aura events
	if self.unit ~= "targettarget" then
		-- UNIT_AURA doesn't fire for target of target
		self:RegisterEvent("UNIT_AURA")
	end

	-- Unit events
	if self.unit == "target" then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif self.unit == "focus" then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif self.unit == "pet" then
		self:RegisterEvent("UNIT_PET")
		-- self:RegisterUnitEvent("UNIT_PET", "pet")  -- TODO
	elseif self.unit == "targettarget" then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		self:RegisterCombatLog() 
	elseif settings.Unit == "lastraid" then
		self:RegisterLastRaid()
	end
end

function BarMixin:RegisterCombatLog()
	-- For monitoring target of target
	if UnitExists(self.unit) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function BarMixin:UnregisterBarTypeEvents()
	-- Called by Bar:Inactivate
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterLastRaid()
end

-- function BarMixin:EXAMPLE_EVENT() end

