-- Bar tracking behavior
-- Bar:Methods() set by Bar:OnLoad() in BarObject.lua

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar
local Cooldown = NeedToKnow.Cooldown

local UPDATE_INTERVAL = 0.03  -- equivalent to ~33 frames per second

-- Local versions of global functions
local GetTime = GetTime

-- Deprecated: 
local m_last_guid = addonTable.m_last_guid
local mfn_GetSpellCooldown = Cooldown.GetSpellCooldown


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

-- ---------------------
-- Bar tracking behavior
-- ---------------------

function Bar:UpdateAppearance()
	-- For bar elements that can change in combat
	-- Called by mfn_Bar_AuraCheck

	local barSettings = self.settings

	local icon = self.Icon
	if ( barSettings.show_icon and self.iconPath ) then
		icon:SetTexture(self.iconPath)
		icon:Show()
		self:SetBackgroundSize(true)
	else
		icon:Hide()
		self:SetBackgroundSize(false)
	end
	-- Blinking bars don't have an icon

	local barColor = barSettings.BarColor
	self.Texture:SetVertexColor(barColor.r,barColor.g, barColor.b)
	self.Texture:SetAlpha(barColor.a)
	if ( self.max_expirationTime and self.max_expirationTime ~= self.expirationTime ) then 
		self.Texture2:SetVertexColor(barColor.r,barColor.g, barColor.b)
		self.Texture2:SetAlpha(barColor.a)
		self.Texture2:Show()
	else
		self.Texture2:Hide()
	end
	-- Blinking changes bar color
end

function Bar:ConfigureVisible(count, extended, buff_stacks)
	-- Called by mfn_Bar_AuraCheck() if bar.duration found
	-- How is this conceptually different than Bar:UpdateAppearance()?

	if self.duration > 0 then
		local duration = self.fixedDuration or self.duration
		self.max_value = duration

		if self.settings.vct_enabled then
			self:UpdateCastTime()
		end
        
		-- Force an update to get all the bars to the current position (sharing code)
		-- This will call UpdateCastTime again, but that seems ok
		self.nextUpdate = UPDATE_INTERVAL
		if self.expirationTime > GetTime() then
			NeedToKnow.Bar_OnUpdate(self, 0)
		end

		self.Time:Show()
    else
		-- Aura with indefinite duration
		self.max_value = 1
		self:SetValue(self.Texture, 1)
		self:SetValue(self.Texture2, 1)
		self.Time:Hide()
		self.Spark:Hide()
		self.CastTime:Hide()
	end

	-- Set bar text

	local txt = ""
	if self.settings.show_mypip then
		txt = txt .. "* "
	end

	local n = ""
	if self.settings.show_text then
		n = self.buffName
		if "" ~= self.settings.show_text_user then
			local idx = self.idxName
			if idx > #self.spell_names then idx = #self.spell_names end
			n = self.spell_names[idx]
		end
	end
	local c = count
	if not self.settings.show_count then
		c = 1
	end
	local to_append = NeedToKnow.ComputeBarText(n, c, extended, buff_stacks, self)
	if to_append and to_append ~= "" then
		txt = txt .. to_append
	end

	if ( self.settings.append_cd 
		and (self.settings.BuffOrDebuff == "CASTCD" 
		or self.settings.BuffOrDebuff == "BUFFCD"
		or self.settings.BuffOrDebuff == "EQUIPSLOT" ) ) 
	then
		txt = txt .. " CD"
	elseif self.settings.append_usable and self.settings.BuffOrDebuff == "USABLE" then
		txt = txt .. " Usable"
	end
	self.text:SetText(txt)
end

--[[
function Bar:OnEvent()
end

function Bar:OnUpdate()
end
]]--


-- ---------
-- Cast time
-- ---------

-- Note: Kitjan's VCT = Visual Cast Time

function Bar:UpdateCastTime()
	local castWidth = 0
	local barDuration = self.fixedDuration or self.duration
	if ( barDuration ) then
		local barWidth = self:GetWidth()
		local castDuration = self:GetCastTimeDuration()
		castWidth = barWidth * castDuration / barDuration
		if castWidth > barWidth then
			castWidth = barWidth
		end
	end

	if ( castWidth > 1 ) then
		self.CastTime:SetWidth(castWidth)
		self.CastTime:Show()
	else
		self.CastTime:Hide()
	end
end

function Bar:GetCastTimeDuration()
	-- Called by Bar:UpdateCastTime(), which is called by AuraCheck 
	-- and possibly Bar_OnUpdate depending on vct_refresh

	local spell = self.settings.vct_spell
	if spell == nil or spell == "" then
		spell = self.buffName
	end

	local castDuration = 0
	local _, _, _, castTime = GetSpellInfo(spell)
	if castTime then
		castDuration = castTime / 1000
		self.vct_refresh = true
	else
		self.vct_refresh = false
	end
	if self.settings.vct_extra then
		castDuration = castDuration + self.settings.vct_extra
	end

	return castDuration
end


