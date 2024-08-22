-- Blink bar when tracked aura/cooldown/etc absent

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

local UnitIsDead = UnitIsDead
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsFriend = UnitIsFriend
local UnitLevel = UnitLevel
local pi = math.pi
local sin = math.sin
local cos = math.cos

function Bar:SetBlinkOptions()
	-- Setting names can be nonintuitive so let's corral them
	-- Called by Bar:SetTrackingOptions
	local settings = self.settings

	self.showBlink = settings.blink_enabled
	self.blinkOutOfCombat = settings.blink_ooc
	self.blinkOnlyBossFight = settings.blink_boss
	self.blinkColor = settings.MissingBlink

	local blinkText = settings.blink_label
	if blinkText and blinkText ~= "" then
		self.blinkText = blinkText
	else
		self.blinkText = nil
	end
end

function Bar:RegisterBlinkEvents()
	if not self.blinkOutOfCombat then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if self.blinkOnlyBossFight then
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

function Bar:ShouldBlink(unitExists)
	-- Return if bar should blink (true/false)
	-- Called by Bar:OnDurationAbsent
	if not self.showBlink then return false end
	local shouldBlink = unitExists and not UnitIsDead(self.unit)
	if shouldBlink and not self.blinkOutOfCombat then
		shouldBlink = UnitAffectingCombat("player")
	end
	if shouldBlink and self.blinkOnlyBossFight then
		if UnitIsFriend(self.unit, "player") then
			shouldBlink = NeedToKnow.isBossFight
		else
			shouldBlink = (UnitLevel(self.unit) == -1)
		end
	end
	return shouldBlink
end

function Bar:Blink()
	-- Called by Bar:OnDurationAbsent
	if self.isBlinking then return end

	self.isBlinking = true
	self.blinkPhase = 0

	local color = self.blinkColor
	self.Texture:SetVertexColor(color.r, color.g, color.b, color.a)
	self:SetValue(self.maxTimeLeft)
	self.Spark:Hide()
	self.Time:Hide()
	self.icon:Hide()
	self.CastTime:Hide()

	if self.blinkText then
		self.Text:SetText(self.blinkText)
	else
		local oldText = self.Text:GetText()
		if not oldText or oldText == "" then
			self:SetUnlockedText()
		end
	end
end

function Bar:UpdateBlink(elapsed)
	-- Called by Bar:OnUpdate
	-- Called very frequently. Be efficient. 
	self.blinkPhase = self.blinkPhase + elapsed/0.7  -- elapsed/CYCLE_DURATION
	if self.blinkPhase >= 1 then
		self.blinkPhase = self.blinkPhase%1  -- Keep decimal remainder
	end
	self.Texture:SetAlpha(self.blinkColor.a * 
		(0.6 + 0.4 * sin(2 * pi * self.blinkPhase))
	)
end
