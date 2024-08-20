-- Track buff cooldowns (passive internal cooldowns on procs)

local _, NeedToKnow = ...
NeedToKnow.BuffCooldownBarMixin = {}
local BarMixin = NeedToKnow.BuffCooldownBarMixin


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetBuffCooldownInfo
	-- local duration = tonumber(settings.buffcd_duration)
	-- if not duration or duration < 1 then
	-- 	print("NeedToKnow: Please set internal cooldown time for ", settings.AuraName)
	-- end
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event for expired cooldown. 
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterUnitEvent("UNIT_AURA", "player")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("UNIT_AURA")
end


--[[ Bar tracking ]]--

function BarMixin:UNIT_AURA(unit, updateInfo)
	self:UpdateTracking()
end

