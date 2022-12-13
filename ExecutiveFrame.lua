-- Addon setup and certain combat functions 

local addonName, addonTable = ...
local ExecutiveFrame = NeedToKnow.ExecutiveFrame

local GetSpec = _G.GetSpecialization or _G.GetActiveTalentGroup  -- Retail or Classic
local GetTime = GetTime

-- Spellcast tracking
local m_last_cast      = addonTable.m_last_cast
local m_last_cast_head = addonTable.m_last_cast_head
local m_last_cast_tail = addonTable.m_last_cast_tail
local m_last_guid      = addonTable.m_last_guid


--[[ ExecutiveFrame functions ]]--

function ExecutiveFrame:OnEvent(event, ...)
	local f = self[event]
	if f then
		f(self, ...)
	end
end
ExecutiveFrame:SetScript("OnEvent", ExecutiveFrame.OnEvent)
ExecutiveFrame:RegisterEvent("ADDON_LOADED")
ExecutiveFrame:RegisterEvent("PLAYER_LOGIN")

function ExecutiveFrame:ADDON_LOADED(addon)
	if addon == addonName then
		if not NeedToKnow.IsVisible then
			NeedToKnow.IsVisible = true
		end

		SlashCmdList["NEEDTOKNOW"] = NeedToKnow.SlashCommand
		SLASH_NEEDTOKNOW1 = "/needtoknow"
		SLASH_NEEDTOKNOW2 = "/ntk"

		-- Make bar groups
		self.barGroups = {}
		-- NeedToKnow.barGroups = {}
		for groupID = 1, NeedToKnow.MAX_BARGROUPS do
			self.barGroups[groupID] = NeedToKnow.BarGroup:New(groupID)
			-- NeedToKnow.barGroups[groupID] = NeedToKnow.BarGroup:New(groupID)
		end

		NeedToKnow.totem_drops = {} -- array 1-4 of precise times totems appeared
		self.BossFightBars = {}
		m_last_cast = {} -- [n] = { spell, target, serial }
		m_last_cast_head = 1
		m_last_cast_tail = 1
		m_last_guid = {} -- [spell][guidTarget] = { time, dur, expiry }
	end
end

function ExecutiveFrame:PLAYER_LOGIN()
	NeedToKnowLoader.SafeUpgrade()

	local _, className = UnitClass("player")
	if className == "DEATHKNIGHT" and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		NeedToKnow.isClassicDeathKnight = true
			-- To filter rune cooldowns out of ability cooldowns
	elseif className == "SHAMAN" then
		NeedToKnow.isShaman = true
			-- For totem bar type in BarMenu
	end
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:PLAYER_TALENT_UPDATE()

	NeedToKnow.guidPlayer = UnitGUID("player")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RefreshRaidMemberNames()

	NeedToKnow:Update()

	self:UnregisterEvent("PLAYER_LOGIN")
	self:UnregisterEvent("ADDON_LOADED")
	NeedToKnowLoader = nil
end

function ExecutiveFrame:PLAYER_TALENT_UPDATE()
	if NeedToKnow.CharSettings then
		local spec = GetSpec()
		local profile_key = NeedToKnow.CharSettings.Specs[spec]
		if not profile_key then
			print("NeedToKnow: Switching to spec", spec, "for the first time")
			profile_key = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS), spec)
		end
		NeedToKnow.ChangeProfile(profile_key)
	end
end

function ExecutiveFrame:ACTIVE_TALENT_GROUP_CHANGED()
	-- Kitjan: This is the only event we're guaranteed to get on a talent switch,
	-- so we have to listen for it.  However, the client may not yet have
	-- the spellbook updates, so trying to evaluate the cooldowns may fail.
	-- This is one of the reasons the cooldown logic has to fail silently
	-- and try again later
	self:PLAYER_TALENT_UPDATE()
end

function ExecutiveFrame:PLAYER_REGEN_DISABLED()
	-- Registered by ExecutiveFrame:UpdateBossFightEvents()
	self:GetBossFight()
end

function ExecutiveFrame:UNIT_TARGET(unit)
	-- Registered by ExecutiveFrame:GetBossFight()
	self:UpdateBossFight(unit)
end

function ExecutiveFrame:PLAYER_REGEN_ENABLED()
	-- Registered by ExecutiveFrame:UpdateBossFightEvents()
	self:ClearBossFight()
end


-- For last raid recipient and detect extends:

function NeedToKnow.RegisterSpellcastSent()
	-- Called by Bar:Activate()
	if ( NeedToKnow.nRegisteredSent ) then
		NeedToKnow.nRegisteredSent = NeedToKnow.nRegisteredSent + 1
	else
		NeedToKnow.nRegisteredSent = 1
		ExecutiveFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
	end
end

function NeedToKnow.UnregisterSpellcastSent()
	-- Called by Bar:Inactivate()
	if ( NeedToKnow.nRegisteredSent ) then
		NeedToKnow.nRegisteredSent = NeedToKnow.nRegisteredSent - 1
		if ( 0 == NeedToKnow.nRegisteredSent ) then
			NeedToKnow.nRegisteredSent = nil
			ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
			ExecutiveFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
			ExecutiveFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

function ExecutiveFrame:UNIT_SPELLCAST_SENT(unit, tgt, lineID, spellID)
	-- For last raid recipient and detect extends
    if unit == "player" then
        -- TODO: I hate to pay this memory cost for every "spell" ever cast.
        --       Would be nice to at least garbage collect this data at some point, but that
        --       may add more overhead than just keeping track of 100 spells.
        if ( not m_last_sent ) then
            m_last_sent = {}
        end
        m_last_sent[spellID] = GetTime()

        -- How expensive a second check do we need?
        if ( m_last_guid[spellID] or NeedToKnow.BarsForPSS ) then
            local r = m_last_cast[m_last_cast_tail]
            if not r then
                r = { spellID=spellID, target=tgt, lineID=lineID }
                m_last_cast[m_last_cast_tail] = r
            else
                r.spellID = spellID
                r.target = tgt
                r.lineID = lineID
            end
            m_last_cast_tail = m_last_cast_tail + 1
            if ( m_last_cast_tail == 2 ) then
                m_last_cast_head = 1
                if ( m_last_guid[spellID] ) then
                    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                else
                    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                end
            end
        end
    end
end

function ExecutiveFrame:UNIT_SPELLCAST_SUCCEEDED(unit, target, lineID, spellID)
	-- For last raid recipient and detect extends
    if unit == "player" then
        local found
        local t = m_last_cast
        local last = m_last_cast_tail-1
        local i
        for i = last,m_last_cast_head,-1  do
            if t[i].spellID == spellID and t[i].serial == serialno then
                found = i
                break
            end
        end
        if found then
            if ( NeedToKnow.BarsForPSS ) then
                local bar, one, spellName
                for bar, one in pairs(NeedToKnow.BarsForPSS) do
                    local unitTarget = NeedToKnow.raid_members[t[found].target or ""]
                    bar:OnEvent("PLAYER_SPELLCAST_SUCCEEDED", "player", spellName, spellID, unitTarget)
                end
            end
            if ( found == last ) then
                m_last_cast_tail = 1
                m_last_cast_head = 1
                self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            else
                m_last_cast_head = found+1
            end
        end
    end
end

function ExecutiveFrame:COMBAT_LOG_EVENT_UNFILTERED()
	-- For last raid recipient and detect extends

    local tod, event, hideCaster, guidCaster, sourceName, sourceFlags, sourceRaidFlags, guidTarget, nameTarget, _, _, spellid, spell = CombatLogGetCurrentEventInfo()

    -- the time that's passed in appears to be time of day, not game time like everything else.
    local time = GetTime() 

    -- TODO: Is checking r.state sufficient or must event be checked instead?
    if ( guidCaster == NeedToKnow.guidPlayer and event=="SPELL_CAST_SUCCESS") then
        -- local guidTarget, nameTarget, _, _, spellid, spell = select(4, ...) -- source_name, source_flags, source_flags2, 

        local found
        local t = m_last_cast
        local last = m_last_cast_tail-1
        local i
        for i = last,m_last_cast_head,-1  do
            if t[i].spell == spell then
                found = i
                break
            end
        end
        if found then
            if ( NeedToKnow.BarsForPSS ) then
                local bar, one
                for bar, one in pairs(NeedToKnow.BarsForPSS) do
                    local unitTarget = NeedToKnow.raid_members[t[found].target or ""]
					bar:OnEvent("PLAYER_SPELLCAST_SUCCEEDED", "player", spell, spellid, unitTarget)
                end
            end

            local rBySpell = m_last_guid[spell]
            if ( rBySpell ) then
                local rByGuid = rBySpell[guidTarget]
                if not rByGuid then
                    rByGuid = { time=time, dur=0, expiry=0 }
                    rBySpell[guidTarget] = rByGuid
                else
                    rByGuid.time= time
                    rByGuid.dur = 0
                    rByGuid.expiry = 0
                end
            end

            if ( found == last ) then
                m_last_cast_tail = 1
                m_last_cast_head = 1
                self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            else
                m_last_cast_head = found+1
            end
        end
    end
end

function ExecutiveFrame:GROUP_ROSTER_UPDATE()
	self:RefreshRaidMemberNames()
end

function ExecutiveFrame:RefreshRaidMemberNames()
	-- For ExecutiveFrame:COMBAT_LOG_EVENT_UNFILTERED()
	-- and ExecutiveFrame:UNIT_SPELLCAST_SUCCEEDED

	-- self.GroupRoster = {}
	NeedToKnow.raid_members = {}

	if IsInRaid() then
		for i = 1, 40 do
			local unit = "raid"..i
			local name = self:GetNameAndServer(unit)
			if name then 
				NeedToKnow.raid_members[name] = unit
			else
				break
			end
		end
	elseif IsInGroup() then
		for i = 1, 5 do
			local unit = "party"..i
			local name = self:GetNameAndServer(unit)
			if name then 
				NeedToKnow.raid_members[name] = unit
			else
				break
			end
		end
	end
	-- Kitjan: Raid pets don't get server name decoration in combat log

	-- Get player and their pet directly
	-- (player will always have a nil server)

	local unit = "player"
	local name = UnitName(unit)
	NeedToKnow.raid_members[name] = unit

	unit = "pet"
	name = UnitName(unit)
	if name then
		NeedToKnow.raid_members[name] = unit
	end
end

function ExecutiveFrame:GetNameAndServer(unit)
	-- Called by ExecutiveFrame:RefreshRaidMemberNames()
	local name, server = UnitName(unit)
	if name and server then 
		return name..'-'..server
	end
	return name
end




