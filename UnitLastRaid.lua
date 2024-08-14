--[[
	Unit "lastraid" (and ExtendedTime)

	Track buffs/debuffs on last raid recipient. For example: a Paladin could 
	track Beacon of Light or a Shaman could track Earth Shield without having 
	to focus recipient. 

	NOTE: Kitjan made this option for what appear to be niche use cases, so 
	worth moving to "Advanced options". 

	NOTE: ExtendedTime currently always uses this tracking option even when it 
	doesn't really need to. 
]]--

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

-- Local versions of frequently-used global functions
local UnitGUID = UnitGUID

-- Functions different between Retail and Classic as of 11.0.0
local function GetRetailSpellInfo(spell)
	local info = C_Spell.GetSpellInfo(spell)  -- Only in Retail
	return info.name
end
local GetSpellInfo = GetSpellInfo or GetRetailSpellInfo

-- Deprecated: 
local m_last_guid = NeedToKnow.m_last_guid  -- For ExtendedTime


--[[ ExecutiveFrame ]]--


--[[ Bar ]]--

function Bar:RegisterLastRaid()
	-- Called by Bar:Activate
	self.PLAYER_SPELLCAST_SUCCEEDED = Bar.PLAYER_SPELLCAST_SUCCEEDED
	if not NeedToKnow.BarsForPSS then
		NeedToKnow.BarsForPSS = {}
	end
	NeedToKnow.BarsForPSS[self] = true
	NeedToKnow.RegisterSpellcastSent()
end

function Bar:UnregisterLastRaid()
	-- Called by Bar:Inactivate
	self.PLAYER_SPELLCAST_SUCCEEDED = nil
	if NeedToKnow.BarsForPSS and NeedToKnow.BarsForPSS[self] then
		NeedToKnow.BarsForPSS[self] = nil
		if not next(NeedToKnow.BarsForPSS) then
			NeedToKnow.BarsForPSS = nil
			NeedToKnow.UnregisterSpellcastSent()
		end
	end
end

function Bar:PLAYER_SPELLCAST_SUCCEEDED(unit, ...)
	-- Fake event called by ExecutiveFrame
	local spellName, spellID, target = select(1, ...)
	for _, spell in pairs(self.spells) do
		if spell.id == spellID or spell.name == spellName then
			self.unit = target or "unknown"
			-- print("Updating", self:GetName(), "since it was recast on", self.unit)
			self:CheckAura()
			break
		end
	end
end


--[[ ExtendedTime ]]--

function Bar:RegisterExtendedTime()
	-- Called by Bar:Activate
	for _, entry in pairs(self.spells) do
		local spellName
		if entry.id then
			spellName = GetSpellInfo(entry.id) or entry.id
		else
			spellName = entry.name
		end
		if spellName then
			local r = m_last_guid[spellName]
			if not r then
				m_last_guid[spellName] = {time = 0, dur = 0, expiry = 0}
			end
		end
	end
	NeedToKnow.RegisterSpellcastSent()
end

function Bar:UnregisterExtendedTime()
	-- Called by Bar:Inactivate
	NeedToKnow.UnregisterSpellcastSent()
end

function Bar:GetExtendedTime(auraName, duration, expirationTime, unit)
	-- Called by Bar:OnDurationFound
	local extended
	local curStart = expirationTime - duration
	local guidTarget = UnitGUID(unit)
	local r = m_last_guid[auraName]

	if not r[guidTarget] then 
		-- Should only happen from /reload or /ntk while the aura is active
		-- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
		-- trace("WARNING! allocating guid slot for ", buffName, "on", guidTarget, "due to UNIT_AURA")
		r[guidTarget] = {time = curStart, dur = duration, expiry = expirationTime}
	else
		r = r[guidTarget]
		local oldExpiry = r.expiry
		-- Kitjan: This went off for me, but I don't know a repro yet.  I suspect it has to do with bear/cat switching
		-- if ( oldExpiry > 0 and oldExpiry < curStart ) then
			-- trace("WARNING! stale entry for ", buffName, "on", guidTarget, curStart - r.time, curStart - oldExpiry)
		-- end

		if oldExpiry < curStart then
			r.time = curStart
			r.dur = duration
			r.expiry = expirationTime
		else
			r.expiry = expirationTime
			extended = expirationTime - (r.time + r.dur)
			if extended > 1 then
				duration = r.dur
			else
				extended = nil
			end
		end
	end
	return extended, duration
end

function Bar:ClearExtendedTime()
	-- Called by Bar:OnDurationAbsent
	local r = m_last_guid[self.buffName]
	if r then
		local guidTarget = UnitGUID(self.unit)
		if guidTarget then
			r[guidTarget] = nil
		end
	end
end

