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

function Bar:Blink(settings)
	settings = settings or self.settings

	if not self.isBlinking then
		self.isBlinking = true
		self.blinkPhase = 1
		self.max_value = 1
		self:SetValue(self.bar1, 1)
		local blinkColor = settings.MissingBlink
		self.Texture:SetVertexColor(blinkColor.r, blinkColor.g, blinkColor.b)
		self.Texture:SetAlpha(blinkColor.a)
	end

	if settings.blink_label and settings.blink_label ~= "" then
		self.Text:SetText(settings.blink_label)
	end

	self.Time:Hide()
	self.Spark:Hide()
	self.CastTime:Hide()
	self.Texture2:Hide()
	self.Icon:Hide()
	self:SetBackgroundSize(false)
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
