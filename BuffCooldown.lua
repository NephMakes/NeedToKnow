-- Track buff cooldowns (passive internal cooldowns on procs)

local _, NeedToKnow = ...
NeedToKnow.BuffCooldownBarMixin = {}
local BarMixin = NeedToKnow.BuffCooldownBarMixin


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetBuffCooldownInfo
	self.filter = "HELPFUL"
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event for expired cooldown. 

	-- local duration = tonumber(settings.buffcd_duration)
	-- if not duration or duration < 1 then
	-- 	print("NeedToKnow: Please set internal cooldown time for ", settings.AuraName)
	-- end
end

function BarMixin:SetBarTypeSpells()
	self:SetBuffCooldownResetSpells()
end

function BarMixin:SetBuffCooldownResetSpells()
	-- Set spells that reset buff cooldown
	-- For example: Balance Druid's Eclipse resets cooldown on Nature's Grace
	local settings = self.settings
	if settings.buffcd_reset_spells and settings.buffcd_reset_spells ~= "" then
		self.reset_spells = {}
		self.reset_start = {}
		local spellIndex = 0
		for resetSpell in settings.buffcd_reset_spells:gmatch("([^,]+)") do
			spellIndex = spellIndex + 1
			resetSpell = strtrim(resetSpell)
			local _, numDigits = resetSpell:find("^%d+")
			if numDigits == resetSpell:len() then
				table.insert(self.reset_spells, {id = tonumber(resetSpell)})
			else
				table.insert(self.reset_spells, {name = resetSpell})
			end
			table.insert(self.reset_start, 0)
		end
	else
		self.reset_spells = nil
		self.reset_start = nil
	end
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

