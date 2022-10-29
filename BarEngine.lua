-- Bar tracking behavior

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar
local Cooldown = NeedToKnow.Cooldown

local UPDATE_INTERVAL = 0.025  -- 40 fps

-- Local versions of frequently-used global functions
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetSpellInfo = GetSpellInfo
local UnitRangedDamage = UnitRangedDamage

-- Deprecated: 
local m_last_guid = addonTable.m_last_guid


 

-- ---------
-- Bar Setup
-- ---------

function Bar:Update()
	-- Update bar behavior and appearance
	-- Called by BarGroup:Update() and various BarMenu:Methods()
	-- when addon loaded, locked/unlocked, or bar configuration changed

	-- Get bar settings from NeedToKnow.ProfileSettings
	local groupID = self:GetParent():GetID()
	local barID = self:GetID()
	local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
    local barSettings = groupSettings["Bars"][barID]
    if ( not barSettings ) then
        groupSettings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
        barSettings = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
    end
    self.settings = barSettings
	local settings = self.settings

	self.auraName = settings.AuraName

	if (
    	settings.BuffOrDebuff == "BUFFCD" or
		settings.BuffOrDebuff == "TOTEM" or
		settings.BuffOrDebuff == "USABLE" or
		settings.BuffOrDebuff == "EQUIPSLOT" or
		settings.BuffOrDebuff == "CASTCD"
	) then
        settings.Unit = "player"
    end
	self.unit = settings.Unit

	self.fixedDuration = tonumber(groupSettings.FixedDuration)
	if not self.fixedDuration or 0 >= self.fixedDuration then
		self.fixedDuration = nil
	end

	self.max_value = 1
	self:SetValue(self.bar1, 1)

	self.nextUpdate = GetTime() + UPDATE_INTERVAL

	self:SetAppearance()

	if ( NeedToKnow.CharSettings["Locked"] ) then
		local enabled = groupSettings.Enabled and settings.Enabled
		if enabled then
			-- Set up the bar to be functional

			-- click through
			self:EnableMouse(false)

			-- Split list of spell names    
			self.spells = {}
			self.cd_functions = {}
			local iSpell = 0
			for barSpell in self.auraName:gmatch("([^,]+)") do
				iSpell = iSpell+1
				barSpell = strtrim(barSpell)
				local _, nDigits = barSpell:find("^-?%d+")
				if ( nDigits == barSpell:len() ) then
					table.insert(self.spells, { idxName=iSpell, id=tonumber(barSpell) } )
				else
					table.insert(self.spells, { idxName=iSpell, name=barSpell } )
				end
			end

            -- Split the user name overrides
			self.spell_names = {}
			for un in settings.show_text_user:gmatch("([^,]+)") do
				un = strtrim(un)
				table.insert(self.spell_names, un)
			end

            -- Split the "reset" spells (for internal cooldowns which reset when the player gains an aura)
			if settings.buffcd_reset_spells and settings.buffcd_reset_spells ~= "" then
				self.reset_spells = {}
				self.reset_start = {}
				iSpell = 0
				for resetSpell in settings.buffcd_reset_spells:gmatch("([^,]+)") do
					iSpell = iSpell+1
					resetSpell = strtrim(resetSpell)
					local _, nDigits = resetSpell:find("^%d+")
					if ( nDigits == resetSpell:len() ) then
						table.insert(self.reset_spells, { idxName = iSpell, id=tonumber(resetSpell) } )
					else
						table.insert(self.reset_spells, { idxName = iSpell, name=resetSpell} )
					end
					table.insert(self.reset_start, 0)
				end
			else
				self.reset_spells = nil
				self.reset_start = nil
			end

			settings.bAutoShot = nil
			-- self.is_counter = nil
			self.ticker = self.OnUpdate

            -- Determine which helper functions to use
			if "BUFFCD" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_BUFFCD
			elseif "TOTEM" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_TOTEM
			elseif "USABLE" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_USABLE
			elseif "EQUIPSLOT" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_EQUIPSLOT
			-- elseif "POWER" == barSettings.BuffOrDebuff then
				-- bar.fnCheck = NeedToKnow.mfn_AuraCheck_POWER
				-- bar.is_counter = true
				-- bar.ticker = nil
				-- bar.ticking = false
			elseif "CASTCD" == settings.BuffOrDebuff then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_CASTCD
				for idx, entry in ipairs(self.spells) do
					table.insert(self.cd_functions, Cooldown.GetSpellCooldown)
					Cooldown.SetUpSpell(self, entry)
				end
			elseif settings.show_all_stacks then
				self.fnCheck = NeedToKnow.mfn_AuraCheck_AllStacks
			else
				self.fnCheck = NeedToKnow.mfn_AuraCheck_Single
			end

			if ( settings.BuffOrDebuff == "BUFFCD" ) then
				local duration = tonumber(settings.buffcd_duration)
				if (not duration or duration < 1) then
					print("NeedToKnow: Please set internal cooldown duration for:", settings.AuraName)
					enabled = false
				end
			end

			self:Activate()

			-- Events were cleared while unlocked, so need to check the bar again now
			NeedToKnow.mfn_Bar_AuraCheck(self)
		else
            self:Inactivate()
			self:Hide()
		end
	else
		self:Inactivate()
		self:Unlock()
	end
end

function Bar:Activate()
	-- Called by Bar:Update() if NeedToKnow is locked

	self:SetScript("OnEvent", self.OnEvent)
	if ( self.ticker ) then
		-- This check is a legacy of power tracking i think
		self:SetScript("OnUpdate", self.ticker)
	end

	local settings = self.settings

	local barType = settings.BuffOrDebuff
	if ( barType == "TOTEM" ) then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	elseif ( barType == "CASTCD" ) then
		if ( settings.bAutoShot ) then
			self:RegisterEvent("START_AUTOREPEAT_SPELL")
			self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
		end
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	elseif ( barType == "EQUIPSLOT" ) then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
--	elseif ( barType == "POWER" ) then
--		if settings.AuraName == tostring(NEEDTOKNOW.SPELL_POWER_STAGGER) then
--			self:RegisterEvent("UNIT_HEALTH")
--		else
--			self:RegisterEvent("UNIT_POWER")
--			self:RegisterEvent("UNIT_DISPLAYPOWER")
--		end
	elseif ( barType == "USABLE" ) then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	elseif ( settings.Unit == "targettarget" ) then
		-- PLAYER_TARGET_CHANGED happens immediately, UNIT_TARGET every couple seconds
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		self:CheckCombatLogRegistration() -- We don't get UNIT_AURA for targettarget
	else
		self:RegisterEvent("UNIT_AURA")
	end

	if ( self.unit == "focus" ) then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif ( self.unit == "target" ) then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif ( self.unit == "pet" ) then
		self:RegisterEvent("UNIT_PET")
	elseif ( "lastraid" == settings.Unit ) then
		if ( not NeedToKnow.BarsForPSS ) then
			NeedToKnow.BarsForPSS = {}
		end
		NeedToKnow.BarsForPSS[self] = true
		NeedToKnow.RegisterSpellcastSent()
	end

	if ( settings.bDetectExtends ) then
		local idx, entry
		for idx, entry in ipairs(self.spells) do
			local spellName
			if ( entry.id ) then
				spellName = GetSpellInfo(entry.id)
			else
				spellName = entry.name
			end
			if ( spellName ) then
				local r = m_last_guid[spellName]
				if ( not r ) then
					m_last_guid[spellName] = { time=0, dur=0, expiry=0 }
				end
			else
				print("Warning! NeedToKnow could not get name for ", entry.id)
			end
		end
		NeedToKnow.RegisterSpellcastSent()
	end

	if ( settings.blink_enabled and settings.blink_boss ) then
		if ( not NeedToKnow.BossStateBars ) then
			NeedToKnow.BossStateBars = {}
		end
		NeedToKnow.BossStateBars[self] = 1;
	end
end

function Bar:CheckCombatLogRegistration()
	-- Used to track auras on target of target
    if UnitExists(self.unit) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function Bar:Inactivate()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)

	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("START_AUTOREPEAT_SPELL")
	self:UnregisterEvent("STOP_AUTOREPEAT_SPELL")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	if ( NeedToKnow.BossStateBars ) then
		NeedToKnow.BossStateBars[self] = nil;
	end
	if ( self.settings.bDetectExtends ) then
		NeedToKnow.UnregisterSpellcastSent()
	end
	if ( NeedToKnow.BarsForPSS and NeedToKnow.BarsForPSS[self] ) then
		NeedToKnow.BarsForPSS[self] = nil
		if ( nil == next(NeedToKnow.BarsForPSS) ) then
			NeedToKnow.BarsForPSS = nil
			NeedToKnow.UnregisterSpellcastSent();
		end
	end
end


-- --------------
-- Event handling
-- --------------

local c_AURAEVENTS = {
	-- COMBAT_LOG_EVENT_UNFILTERED events where select(6,...) is caster, 
	-- 9 is spellid, and 10 is spell name. Used for target of target. 
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true
}
local AUTO_SHOT_NAME = GetSpellInfo(75)

-- Define the event dispatching table.  Note, this comes last as the referenced 
-- functions must already be declared.  Avoiding the re-evaluation of all that
-- is one of the reasons this is an optimization!
local EDT = {}
EDT["COMBAT_LOG_EVENT_UNFILTERED"] = function(self, unit, ...)
    -- local combatEvent = select(1, ...)
    local tod, event, hideCaster, guidCaster, sourceName, sourceFlags, sourceRaidFlags, guidTarget, nameTarget, _, _, spellid, spell = CombatLogGetCurrentEventInfo()

    if ( c_AURAEVENTS[combatEvent] ) then
        -- local guidTarget = select(7, ...)
        if ( guidTarget == UnitGUID(self.unit) ) then
            -- local idSpell, nameSpell = select(11, ...)
            if (self.auraName:find(idSpell) or
                self.auraName:find(nameSpell)) 
            then 
                NeedToKnow.mfn_Bar_AuraCheck(self)
            end
        end
    elseif ( combatEvent == "UNIT_DIED" ) then
        -- local guidDeceased = select(7, ...) 
        -- if ( guidDeceased == UnitGUID(self.unit) ) then
        if ( guidTarget == UnitGUID(self.unit) ) then
            NeedToKnow.mfn_Bar_AuraCheck(self)
        end
    end 
end
EDT["PLAYER_TOTEM_UPDATE"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["ACTIONBAR_UPDATE_COOLDOWN"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_COOLDOWN"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["SPELL_UPDATE_USABLE"] = NeedToKnow.mfn_Bar_AuraCheck
EDT["UNIT_AURA"] = NeedToKnow.fnAuraCheckIfUnitMatches
EDT["UNIT_HEALTH"] = NeedToKnow.mfn_Bar_AuraCheck  -- Legacy of power tracking?
EDT["PLAYER_TARGET_CHANGED"] = function(self, unit)
    if self.unit == "targettarget" then
        self:CheckCombatLogRegistration()
    end
    NeedToKnow.mfn_Bar_AuraCheck(self)
end  
EDT["PLAYER_FOCUS_CHANGED"] = EDT["PLAYER_TARGET_CHANGED"]
EDT["UNIT_TARGET"] = function(self, unit)
    if unit == "target" and self.unit == "targettarget" then
        self:CheckCombatLogRegistration()
    end
    NeedToKnow.mfn_Bar_AuraCheck(self)
end  
EDT["UNIT_PET"] = NeedToKnow.fnAuraCheckIfUnitPlayer
EDT["PLAYER_SPELLCAST_SUCCEEDED"] = function(self, unit, ...)
    local spellName, spellID, tgt = select(1,...)
    local i,entry
    for i,entry in ipairs(self.spells) do
        if entry.id == spellID or entry.name == spellName then
            self.unit = tgt or "unknown"
            --trace("Updating",self:GetName(),"since it was recast on",self.unit)
            NeedToKnow.mfn_Bar_AuraCheck(self)
            break;
        end
    end
end
EDT["START_AUTOREPEAT_SPELL"] = function(self, unit, ...)
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
EDT["STOP_AUTOREPEAT_SPELL"] = function(self, unit, ...)
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
EDT["UNIT_SPELLCAST_SUCCEEDED"] = function(self, unit, ...)
    local spellID  = select(2, ...)
    local spellName = select(1, GetSpellInfo(spellId))
    if ( self.settings.bAutoShot and unit == "player" and spellName == AUTO_SHOT_NAME ) then
        local interval = UnitRangedDamage("player")
        self.tAutoShotCD = interval
        self.tAutoShotStart = GetTime()
        NeedToKnow.mfn_Bar_AuraCheck(self)
    end
end

-- function NeedToKnow.Bar_OnEvent(self, event, unit, ...)
function Bar:OnEvent(event, unit, ...)
	local fn = EDT[event]
	if fn then 
		fn(self, unit, ...)
	end
end

-- --------
-- OnUpdate
-- --------

function Bar:OnUpdate(elapsed)
	-- Fired very frequently. Make sure it's efficient. 
	local now = GetTime()
	if now > self.nextUpdate then
		self.nextUpdate = now + UPDATE_INTERVAL

		if self.blink then
			self.blink_phase = self.blink_phase + UPDATE_INTERVAL
			if self.blink_phase >= 2 then
				self.blink_phase = 0
			end
			local a = self.blink_phase
			if a > 1 then
				a = 2 - a
			end

			self.bar1:SetVertexColor(self.settings.MissingBlink.r, self.settings.MissingBlink.g, self.settings.MissingBlink.b)
			self.bar1:SetAlpha(self.settings.MissingBlink.a * a)
			return
		end
        
		if self.duration and self.duration > 0 then
			local duration = self.fixedDuration or self.duration
			local bar1_timeLeft = self.expirationTime - now
			if bar1_timeLeft < 0 then
				if ( self.settings.BuffOrDebuff == "CASTCD" or
					self.settings.BuffOrDebuff == "BUFFCD" or
					self.settings.BuffOrDebuff == "EQUIPSLOT" )
				then
		-- WORKAROUND: Some of these (like item cooldowns) don't fire an event when the CD expires.
		--   others fire the event too soon.  So we have to keep checking.
					NeedToKnow.mfn_Bar_AuraCheck(self)
					return
				end
				bar1_timeLeft = 0
			end

			self:SetValue(self.bar1, bar1_timeLeft);

			if self.settings.show_time then
				local fn = NeedToKnow[self.settings.TimeFormat]
				local oldText = self.time:GetText()
				local newText
				if fn then
					newText = fn(bar1_timeLeft)
				else 
					newText = string.format(SecondsToTimeAbbrev(bar1_timeLeft))
				end
				if newText ~= oldText then
					self.time:SetText(newText)
				end
			else
				self.time:SetText("")
			end
            
			if self.settings.show_spark and bar1_timeLeft <= duration then
				self.spark:SetPoint("CENTER", self, "LEFT", self:GetWidth()*bar1_timeLeft/duration, 0)
				self.spark:Show()
			else
				self.spark:Hide()
			end
            
			if self.settings.vct_enabled and self.vct_refresh then
				self:UpdateCastTime()
			end

			if self.max_expirationTime then
				local bar2_timeLeft = self.max_expirationTime - GetTime()
				self:SetValue(self.bar2, bar2_timeLeft, bar1_timeLeft)
            end
		end
	end
end


