-- Track spell and item cooldowns

local _, NeedToKnow = ...
NeedToKnow.SpellCooldownBarMixin = {}
local BarMixin = NeedToKnow.SpellCooldownBarMixin

local GetTime = GetTime


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate
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

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get cooldown info for spell, item, or spell charges
	local GetCooldown = spellEntry.cooldownFunction
	if not GetCooldown then return end
	local start, duration, _, name, iconID, count, start2 = GetCooldown(self, spellEntry)

	-- Filter out global cooldown
	if start and (duration <= 1.5) then
		if self.expirationTime and self.expirationTime <= start + duration then
			start = self.expirationTime - self.duration
			duration = self.duration
		else
			start = nil
		end
	end

	if start and duration then
		local now = GetTime()
		local expirationTime = start + duration
		if expirationTime > now + 0.1 then
			if start2 then  -- returned by Cooldown.GetSpellChargesCooldown
				self:AddTrackedInfo(allStacks, duration, name, 1, start2 + duration, iconID, spellEntry.shownName)
				count = count - 1
			else
				if not count then count = 1 end
			end
			self:AddTrackedInfo(allStacks, duration, name, count, expirationTime, iconID, spellEntry.shownName)
		end
	end
end

