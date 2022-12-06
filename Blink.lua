-- Blink bar when tracked aura is missing

local addonName, addonTable = ...
local Bar = NeedToKnow.Bar

-- local versions of frequently-used functions
-- local GetTime = GetTime

-- To do: replace with NeedToKnow.isBossFight
local m_bCombatWithBoss = addonTable.m_bCombatWithBoss

local CYCLE_DURATION = 1

function Bar:ShouldBlink(settings, unitExists)
	-- Determine if bar should blink
	-- Called by Bar:CheckAura()
	if settings.blink_enabled then
		local shouldBlink = unitExists and not UnitIsDead(self.unit)
		if shouldBlink and not UnitAffectingCombat("player") and not settings.blink_ooc then
			shouldBlink = false
		end
		if shouldBlink and settings.blink_boss then
			if UnitIsFriend(self.unit, "player") then
				shouldBlink = m_bCombatWithBoss
				-- shouldBlink = NeedToKnow.isBossFight  -- To do
			else
				shouldBlink = (UnitLevel(self.unit) == -1)
			end
		end
		return shouldBlink
	else
		return false
	end
end

function Bar:Blink(barSettings)
	if not self.isBlinking then
		-- barSettings = barSettings or self.settings

		self.isBlinking = true
		self.blinkPhase = 0

		self:SetBlinkText(barSettings)
		local blinkColor = barSettings.MissingBlink
		self.Texture:SetVertexColor(blinkColor.r, blinkColor.g, blinkColor.b, blinkColor.a)
		-- self.max_value = 1
		self:SetValue(self.bar1, self.max_value)

		self.Time:Hide()
		self.Spark:Hide()
		self.CastTime:Hide()
		self.Icon:Hide()
		self.Texture2:Hide()
		self:SetBackgroundSize(false)
	end
end

function Bar:SetBlinkText(barSettings)
	-- barSettings = barSettings or self.settings
	if barSettings.blink_label and barSettings.blink_label ~= "" then
		self.Text:SetText(barSettings.blink_label)
	else
		local oldText = self.Text:GetText()
		if oldText and oldText ~= "" then
			self.Text:SetText(oldText)
		else
			self.Text:SetText("")
		end
	end
end

function Bar:UpdateBlink(elapsed)
	-- Called by Bar:OnUpdate()
	self.blinkPhase = self.blinkPhase + elapsed/CYCLE_DURATION
	if self.blinkPhase >= 1 then
		self.blinkPhase = self.blinkPhase - 1
	end
	self.bar1:SetAlpha(self.settings.MissingBlink.a * 
		(0.6 + 0.4 * math.cos(2 * math.pi * self.blinkPhase))
	)
end
