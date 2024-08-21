-- Track spell and item cooldowns

local _, NeedToKnow = ...
NeedToKnow.SpellCooldownBarMixin = {}
local BarMixin = NeedToKnow.SpellCooldownBarMixin


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetCooldownInfo
	self.checkOnNoTimeLeft = true  
		-- For Bar:OnUpdate. 
		-- No event when item cooldowns expire. Others fire too soon. 
end

function BarMixin:SetBarTypeSpells()
	-- Set appropriate cooldown function for each spellEntry
	self:SetCooldownSpells()
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
end


--[[ Bar tracking ]]--

function BarMixin:ACTIONBAR_UPDATE_COOLDOWN()
	self:UpdateTracking()
end

function BarMixin:SPELL_UPDATE_COOLDOWN()
	self:UpdateTracking()
end
