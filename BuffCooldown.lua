-- Track buff cooldowns (passive internal cooldowns on procs)

local _, NeedToKnow = ...
NeedToKnow.BuffCooldownBarMixin = {}
local BarMixin = NeedToKnow.BuffCooldownBarMixin
local Bar = NeedToKnow.Bar

local GetTime = GetTime
local GetAuraDataBySpellName = C_UnitAuras.GetAuraDataBySpellName
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID


--[[ Bar setup ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	-- self.settings.buffcd_duration  -- TODO
	self.filter = "HELPFUL"
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event for expired cooldown. 

	-- local duration = tonumber(settings.buffcd_duration)
	-- if not duration or duration < 1 then
	-- 	print("NeedToKnow: Please set internal cooldown time for ", settings.AuraName)
	-- end
end

function BarMixin:SetBarTypeSpells()
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

local m_scratch = {}  -- Deprecated
m_scratch.buff_stacks = {
	min = {
		buffName = "", 
		duration = 0, 
		expirationTime = 0, 
		icon = "",
	},
	max = {
		duration = 0, 
		expirationTime = 0, 
	},
	total = 0,
}

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get info for cooldown on passive buff proc
	local buffStacks = m_scratch.buff_stacks
	buffStacks.total = 0
	self:GetAuraInfo(spellEntry, buffStacks)

	local now = GetTime()
	if buffStacks.total > 0 then
		local duration = tonumber(self.settings.buffcd_duration)
		if buffStacks.max.expirationTime == 0 then
			-- TODO: This doesn't work well as a substitute for telling when the aura was applied
			if not self.expirationTime then
				self:AddTrackedInfo(allStacks, duration, buffStacks.min.name, 1, duration + now, buffStacks.min.icon, spellEntry.shownName)
			else
				self:AddTrackedInfo(allStacks, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, spellEntry.shownName)
			end
			return
		end

		local start = buffStacks.max.expirationTime - buffStacks.max.duration
		local expirationTime = start + duration
		if expirationTime > now then
			self:AddTrackedInfo(allStacks, duration, buffStacks.min.name, 1, expirationTime, buffStacks.min.icon, spellEntry.shownName)                   
		end
	elseif self.expirationTime and self.expirationTime > now + 0.1 then
		self:AddTrackedInfo(allStacks, self.duration, self.buffName, 1, self.expirationTime, self.iconPath, spellEntry.shownName)
	end
end

function BarMixin:GetAuraInfo(spellEntry, stacks)
	-- Get info for first instance of buff/debuff
	local aura
	local entryName = spellEntry.name
	local entryID = spellEntry.id
	if entryName then
		aura = GetAuraDataBySpellName("player", entryName, "HELPFUL")
	elseif entryID then
		aura = GetPlayerAuraBySpellID(entryID)
	end
	if aura then
		self:AddTrackedInfo(stacks, aura.duration, aura.name, aura.applications, aura.expirationTime, aura.icon, spellEntry.shownName, unpack(aura.points))
	end
end

function Bar:GetBuffCooldownReset(duration, expirationTime)
	-- Called by Bar:CheckAura()
	-- Example: Classic Druid Eclipse resets internal cooldown on Nature's Grace
	local maxStart = 0
	local tNow = GetTime()
	local buff_stacks = m_scratch.buff_stacks
	buff_stacks.total = 0
	-- Track when reset auras last applied to player
	for i, resetSpell in ipairs(self.reset_spells) do
		local resetDuration, _, _, resetExpiration = self:GetAuraInfo(resetSpell, buff_stacks)
		local tStart
		if buff_stacks.total > 0 then
			if 0 == buff_stacks.max.duration then 
				tStart = self.reset_start[i]
				if 0 == tStart then
					tStart = tNow
				end
			else
				tStart = buff_stacks.max.expirationTime - buff_stacks.max.duration
			end
			self.reset_start[i] = tStart
			if tStart > maxStart then 
				maxStart = tStart 
			end
		else
			self.reset_start[i] = 0
		end
	end
	if maxStart > expirationTime - duration then
		duration = nil
	end
	return duration
end


