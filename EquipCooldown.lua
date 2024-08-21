-- Track equipped item cooldowns by inventorySlotID

local _, NeedToKnow = ...
NeedToKnow.EquipCooldownBarMixin = {}
local BarMixin = NeedToKnow.EquipCooldownBarMixin
local String = NeedToKnow.String

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetEquipCooldownInfo
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event when item cooldowns expire. 
end

function BarMixin:SetBarTypeSpells()
	-- Show equipment slot name if no custom text
	for _, spellEntry in pairs(self.spells) do
		if not spellEntry.shownName then
			spellEntry.shownName = String.GetInventorySlotName(spellEntry.id)
		end
	end
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

