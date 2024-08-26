--[[ 
	Track buff cooldowns (internal cooldowns on procs)

	Cooldown duration has to be set by user :(. Not accurate for multiple 
	instances of same buff (for example from same enchant on dual-wielded 
	melee weapons). Allows specific buffs to reset cooldown (also have to be 
	set by user). 
]]--

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
	local settings = self.settings
	settings.Unit = "player"
	self.buffCooldownDuration = tonumber(settings.buffcd_duration)
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. No event for expired cooldown. 

	-- local duration = tonumber(settings.buffcd_duration)
	-- if not duration or duration < 1 then
	-- 	print("NeedToKnow: Please set internal cooldown time for ", settings.AuraName)
	-- end
end

function BarMixin:SetBarTypeSpells()
	-- Set other buffs that reset tracked buff cooldown
	-- Example: Classic Balance Druid Eclipse resets cooldown on Nature's Grace
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

local function GetBuffInfo(entry)
	-- Get info for first instance of buff on player
	if entry.name then
		return GetAuraDataBySpellName("player", entry.name, "HELPFUL")
	elseif entry.id then
		return GetPlayerAuraBySpellID(entry.id)
	end
end

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get info for cooldown on passive buff proc
	-- Called by Bar:UpdateTracking
	local name, duration, expirationTime, iconID

	local buff = GetBuffInfo(spellEntry)
	local now = GetTime()
	if buff then
		name = buff.name
		iconID = buff.icon
		if buff.expirationTime > 0 then
			local startTime = buff.expirationTime - buff.duration
			expirationTime = startTime + self.buffCooldownDuration
			if expirationTime > now then
				-- Set the clock
				duration = self.buffCooldownDuration
				expirationTime = expirationTime
			end
		elseif buff.expirationTime == 0 then
			-- Buff has indefinite duration
			-- NOTE: Example = ???. Do any indefinite buffs have a cooldown? 
			if self.expirationTime then 
				-- Keep on keepin' on
				duration = self.duration
				expirationTime = self.expirationTime
			else
				-- We have no memory of this, so assume newly applied
				-- (won't be accurate after /reload etc)
				-- Start the clock
				duration = self.buffCooldownDuration
				expirationTime = duration + now
			end
		end
	elseif self.expirationTime and self.expirationTime > now + 0.1 then
		-- Keep on keepin' on
		name = self.buffName
		iconID = self.iconPath
		duration = self.duration
		expirationTime = self.expirationTime
	end

	if duration then
		return {
			name = name, 
			iconID = iconID, 
			count = 1, 
			duration = duration, 
			expirationTime = expirationTime, 
			-- extraValues = nil, 
			shownName = spellEntry.shownName, 
			stacks = 1, 
		}
	end
end

function BarMixin:ProcessTrackedInfo(trackedInfo)
	-- Return nil if reset spell found, trackedInfo otherwise
	-- DEPRECATED: This should really just be rolled into GetTrackedInfo 
	-- so we can remove ProcessTrackedInfo altogether
	if self.reset_spells and trackedInfo and trackedInfo.duration then
		local duration = self:GetBuffCooldownReset(trackedInfo.duration, trackedInfo.expirationTime)
		if not duration then
			trackedInfo = nil
		else 
			trackedInfo.duration = duration
		end
	end
	return trackedInfo
end

function BarMixin:GetBuffCooldownReset(duration, expirationTime)
	-- ...
	-- Example: Classic Druid Eclipse resets internal cooldown on Nature's Grace
	-- Called by Bar:CheckAura()
	local maxStartTime = 0
	local now = GetTime()
	for i, resetSpell in ipairs(self.reset_spells) do
		-- Track when reset buff last applied to player
		local resetBuff = GetBuffInfo(resetSpell)
		local startTime
		if resetBuff then
			if resetBuff.duration == 0 then
				startTime = self.reset_start[i]
				if 0 == startTime then
					startTime = now
				end
			else
				startTime = resetBuff.expirationTime - resetBuff.duration
			end
			self.reset_start[i] = startTime
			if startTime > maxStartTime then 
				maxStartTime = startTime 
			end
		else
			self.reset_start[i] = 0
		end
	end
	if maxStartTime > expirationTime - duration then
		duration = nil
	end
	return duration
end


