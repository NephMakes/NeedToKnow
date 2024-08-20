-- Blink bar when aura/cooldown/etc absent

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

function Bar:RegisterBlinkEvents()
	local settings = self.settings
	if not settings.blink_ooc then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if settings.blink_boss then
		self:RegisterBossFight()
	end
end

function Bar:UnregisterBlinkEvents()
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterBossFight()
end

function Bar:PLAYER_REGEN_DISABLED()
	self:UpdateTracking()
end

function Bar:PLAYER_REGEN_ENABLED()
	self:UpdateTracking()
end

function Bar:ShouldBlink(barSettings, unitExists)
	-- Determine if bar should blink, return true/false
	-- Called by Bar:OnDurationAbsent
	if barSettings.blink_enabled then
		local shouldBlink = unitExists and not UnitIsDead(self.unit)
		if shouldBlink and not barSettings.blink_ooc and not UnitAffectingCombat("player") then
			shouldBlink = false
		end
		if shouldBlink and barSettings.blink_boss then
			if UnitIsFriend(self.unit, "player") then
				shouldBlink = NeedToKnow.isBossFight
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
	-- Called by Bar:UpdateTracking
	if not self.isBlinking then
		self.isBlinking = true
		self.blinkPhase = 0

		-- Bar appearance
		local blinkColor = barSettings.MissingBlink
		self.Texture:SetVertexColor(blinkColor.r, blinkColor.g, blinkColor.b, blinkColor.a)
		self:SetValue(self.maxTimeLeft)
		self.Spark:Hide()
		self.Time:Hide()
		self.icon:Hide()
		self.CastTime:Hide()

		-- Bar text
		if barSettings.blink_label and barSettings.blink_label ~= "" then
			self.Text:SetText(barSettings.blink_label)
		else
			local oldText = self.Text:GetText()
			if not oldText or oldText == "" then
				self:SetUnlockedText()
			end
		end
	end
end

function Bar:UpdateBlink(elapsed)
	-- Called by Bar:OnUpdate
	self.blinkPhase = self.blinkPhase + elapsed/0.7  -- elapsed/CYCLE_DURATION
	if self.blinkPhase >= 1 then
		self.blinkPhase = self.blinkPhase%1  -- Keep decimal remainder
	end
	self.Texture:SetAlpha(self.settings.MissingBlink.a * 
		(0.6 + 0.4 * math.cos(2 * math.pi * self.blinkPhase))
	)
end
