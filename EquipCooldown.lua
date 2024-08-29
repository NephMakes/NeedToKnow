-- Track equipped item cooldowns by inventorySlotID

local _, NeedToKnow = ...
NeedToKnow.EquipCooldownBarMixin = {}
local BarMixin = NeedToKnow.EquipCooldownBarMixin
local String = NeedToKnow.String

local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemTexture = GetInventoryItemTexture


--[[ BarMixin ]]--

function BarMixin:SetBarTypeOptions()
	self.settings.Unit = "player"
	self.checkOnNoTimeLeft = true 
		-- For Bar:OnUpdate. No event when item cooldowns expire. 

	-- Show equipment slot name if no custom text
	for _, spellEntry in pairs(self.spells) do
		if not spellEntry.shownName then
			spellEntry.shownName = String.GetInventorySlotName(spellEntry.id)
		end
	end
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function BarMixin:ACTIONBAR_UPDATE_COOLDOWN()
	self:UpdateTracking()
end

function BarMixin:UNIT_INVENTORY_CHANGED()
	self:UpdateTracking()
end

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get cooldown info for equipped item by inventorySlotID 
	if not spellEntry.id then return end
	local start, duration, _ = GetInventoryItemCooldown("player", spellEntry.id)
	if start and start > 0 then
		local iconID = GetInventoryItemTexture("player", spellEntry.id)
		return {
			name = spellEntry.id, 
			iconID = iconID, 
			count = 1, 
			duration = duration, 
			expirationTime = start + duration, 
			-- extraValues = nil, 
			shownName = spellEntry.shownName, 
			stacks = 1, 
		}
	end
end

function BarMixin:ProcessTrackedInfo(trackedInfo)
	-- Nothing to do
	return trackedInfo
end


