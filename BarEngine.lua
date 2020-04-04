-- Bar tracking behavior

-- local addonName, addonTable = ...

local Bar = NeedToKnow.Bar

-- Bar:Methods() set by Bar:OnLoad() in BarObject.lua

function Bar:SetScripts()
	self:SetScript("OnEvent", NeedToKnow.Bar_OnEvent)
	if ( self.ticker ) then
		self:SetScript("OnUpdate", self.ticker)
	end

	local settings = self.settings

	local barType = settings.BuffOrDebuff
	if ( barType == "TOTEM" ) then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	elseif ( barType == "CASTCD" ) then
		-- elseif ( "CASTCD" == settings.BuffOrDebuff ) then
		if ( settings.bAutoShot ) then
			self:RegisterEvent("START_AUTOREPEAT_SPELL")
			self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
		end
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	elseif ( barType == "EQUIPSLOT" ) then
		-- elseif ( "EQUIPSLOT" == settings.BuffOrDebuff ) then
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	--[[
	elseif ( barType == "POWER" ) then
		-- elseif ( "POWER" == settings.BuffOrDebuff ) then
		if settings.AuraName == tostring(NEEDTOKNOW.SPELL_POWER_STAGGER) then
			self:RegisterEvent("UNIT_HEALTH")
		else
			self:RegisterEvent("UNIT_POWER")
			self:RegisterEvent("UNIT_DISPLAYPOWER")
		end
	]]--
	elseif ( barType == "USABLE" ) then
		-- elseif ( "USABLE" == settings.BuffOrDebuff ) then
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	elseif ( settings.Unit == "targettarget" ) then
		-- elseif ( settings.Unit == "targettarget" ) then
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

--[[
function Bar:Initialize()
	-- called by Bar:Update()
end
]]--

function Bar:CheckCombatLogRegistration(force)
    if UnitExists(self.unit) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

--[[
function Bar:OnUpdate()
end

function Bar:OnEvent()
end
]]--


