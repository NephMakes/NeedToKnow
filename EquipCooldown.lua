-- Track equipped item cooldowns by inventorySlotID

local _, NeedToKnow = ...
NeedToKnow.EquipCooldownBarMixin = {}
local BarMixin = NeedToKnow.EquipCooldownBarMixin

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetEquipCooldownInfo
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event when item cooldowns expire. 
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

function BarMixin:ACTIONBAR_UPDATE_COOLDOWN()
	self:UpdateTracking()
end

