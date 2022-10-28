-- Bar tracking behavior
-- Bar:Methods() set by Bar:OnLoad() in BarObject.lua

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar
local Cooldown = NeedToKnow.Cooldown

local UPDATE_INTERVAL = 0.03  -- equivalent to ~33 frames per second

-- Defined in NeedToKnow.lua: 
-- Deprecated: 
local m_last_guid = addonTable.m_last_guid
local mfn_AuraCheck_BUFFCD = addonTable.mfn_AuraCheck_BUFFCD
local mfn_AuraCheck_TOTEM = addonTable.mfn_AuraCheck_TOTEM
local mfn_AuraCheck_USABLE = addonTable.mfn_AuraCheck_USABLE
local mfn_AuraCheck_EQUIPSLOT = addonTable.mfn_AuraCheck_EQUIPSLOT
local mfn_AuraCheck_CASTCD = addonTable.mfn_AuraCheck_CASTCD
local mfn_AuraCheck_Single = addonTable.mfn_AuraCheck_Single
local mfn_AuraCheck_AllStacks = addonTable.mfn_AuraCheck_AllStacks
local mfn_Bar_AuraCheck = NeedToKnow.mfn_Bar_AuraCheck
local mfn_GetSpellCooldown = Cooldown.GetSpellCooldown

--[[ Bar functions ]]--

function Bar:Update()
	-- Update bar behavior and appearance
	-- Called by BarGroup:Update() and various BarMenu:Methods()
    -- Called when addon loaded, locked/unlocked, or bar configuration changed

	-- TO DO: Use instead of NeedToKnow.Bar_Update(groupID, barID)

	-- Get bar settings from NeedToKnow.ProfileSettings
	local groupID = self:GetParent():GetID()
	local barID = self:GetID()
	local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
    local barSettings = groupSettings["Bars"][barID]
    if ( not barSettings ) then
    	-- TO DO: Handle this in Bar:New()
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
			self.is_counter = nil
			self.ticker = NeedToKnow.Bar_OnUpdate

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
					table.insert(self.cd_functions, mfn_GetSpellCooldown)
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

			self:SetScripts()

			-- Events were cleared while unlocked, so need to check the bar again now
			NeedToKnow.mfn_Bar_AuraCheck(self)
		else
            self:ClearScripts()
			self:Hide()
		end
	else
		self:ClearScripts()
		self:Unlock()
	end
end

function Bar:SetScripts()
	self:SetScript("OnEvent", NeedToKnow.Bar_OnEvent)
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
	--[[
	elseif ( barType == "POWER" ) then
		if settings.AuraName == tostring(NEEDTOKNOW.SPELL_POWER_STAGGER) then
			self:RegisterEvent("UNIT_HEALTH")
		else
			self:RegisterEvent("UNIT_POWER")
			self:RegisterEvent("UNIT_DISPLAYPOWER")
		end
	]]--
	elseif ( barType == "USABLE" ) then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	elseif ( settings.Unit == "targettarget" ) then
		-- WORKAROUND: PLAYER_TARGET_CHANGED happens immediately, UNIT_TARGET every couple seconds
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_TARGET")
		-- WORKAROUND: Don't get UNIT_AURA for targettarget
		self:CheckCombatLogRegistration()
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

function Bar:ClearScripts()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)

	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
	self:UnregisterEvent("UNIT_AURA")
	-- self:UnregisterEvent("UNIT_POWER")
	-- self:UnregisterEvent("UNIT_DISPLAYPOWER")
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

function Bar:CheckCombatLogRegistration(force)
    if UnitExists(self.unit) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

--[[
function Bar:OnEvent()
end

function Bar:OnUpdate()
end
]]--

function NeedToKnow.ComputeVCTDuration(bar)
    -- Called by mfn_UpdateVCT, which is called from AuraCheck and possibly 
    -- by Bar_OnUpdate depending on vct_refresh. In addition to refactoring out some 
    -- code from the long AuraCheck, this also provides a convenient hook for other addons

    local vct_duration = 0
    
    local spellToTime = bar.settings.vct_spell
    if ( nil == spellToTime or "" == spellToTime ) then
        spellToTime = bar.buffName
    end
     
    local _, _, _, castTime = g_GetSpellInfo(spellToTime)

    if ( castTime ) then
        vct_duration = castTime / 1000
        bar.vct_refresh = true
    else
        bar.vct_refresh = false
    end
    
    if ( bar.settings.vct_extra ) then
        vct_duration =  vct_duration + bar.settings.vct_extra
    end
    return vct_duration
end

