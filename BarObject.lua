-- Bar appearance and interaction

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar
local String = NeedToKnow.String

-- local versions of frequently-used functions
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local SecondsToTimeAbbrev = SecondsToTimeAbbrev

-- Deprecated: 
local UPDATE_INTERVAL = 0.025  -- Make this an addon-wide variable?


-- ---------
-- Bar setup
-- ---------

function Bar:New(group, barID)
	-- Called by BarGroup:Update()
	bar = CreateFrame("Frame", group:GetName().."Bar"..barID, group, "NeedToKnow_BarTemplate")
	bar:SetID(barID)
	Mixin(bar, Bar) -- Inherit Bar:Methods()
	bar:OnLoad()
	return bar
end

function Bar:OnLoad()
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEnter", Bar.OnEnter)
	self:SetScript("OnLeave", Bar.OnLeave)
	self:SetScript("OnMouseUp", Bar.OnMouseUp)
	self:SetScript("OnDragStart", Bar.OnDragStart)
	self:SetScript("OnDragStop", Bar.OnDragStop)
	self:SetScript("OnSizeChanged", Bar.OnSizeChanged)
	
	-- Want to not need these eventually
    self.bar1 = self.Texture
    self.bar2 = self.Texture2
	self.icon = self.Icon
	self.spark = self.Spark
    self.text = self.Text
    self.time = self.Time
	self.vct = self.CastTime
end

function Bar:SetAppearance()
	-- Set bar elements that don't change in combat
	-- Called by Bar:Update()

	local settings = NeedToKnow.ProfileSettings
	local barSettings = self.settings
	local barHeight = self:GetHeight()

	self.Texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))
	self.Texture2:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))

	local fontPath = NeedToKnow.LSM:Fetch("font", settings.BarFont)
	if fontPath then
		local outline = settings.FontOutline
		if outline == 0 then
			outline = nil
		elseif outline == 1 then
			outline = "OUTLINE"
		else
			outline = "THICKOUTLINE"
		end
		self.Text:SetFont(fontPath, settings.FontSize, outline)
		self.Time:SetFont(fontPath, settings.FontSize, outline)
	end
	self.Text:SetWidth(self:GetWidth() - 60)

	local time = self.Time
	if barSettings.show_time then
		time:Show()
	else
		time:Hide()
	end
	if barSettings.TimeFormat == "Fmt_TwoUnits" then
		self.FormatTime = self.FormatTimeTwoUnits
	elseif barSettings.TimeFormat == "Fmt_Float" then
		self.FormatTime = self.FormatTimeDecimal
	else
		self.FormatTime = self.FormatTimeSingle
	end

	local icon = self.Icon
	if barSettings.show_icon then
		icon:SetSize(barHeight, barHeight)
		icon:ClearAllPoints()
		icon:SetPoint("RIGHT", self, "LEFT", -settings.BarPadding, 0)
		icon:Show()
	else
		icon:Hide()
	end

	local castTime = self.CastTime
	if barSettings.vct_enabled then
		local castColor = barSettings.vct_color
		castTime:SetColorTexture(castColor.r, castColor.g, castColor.b, castColor.a)
		castTime:SetHeight(barHeight)
	else
		castTime:Hide()
	end

	self:SetBackgroundSize(barSettings.show_icon)
	local barPadding = PixelUtil.GetNearestPixelSize(settings.BarPadding, bar:GetEffectiveScale())
	self.Background:SetHeight(barHeight + 2 * barPadding)
	self.Background:SetVertexColor(unpack(settings.BkgdColor))
	-- print(unpack(settings.BkgdColor))
end

function Bar:SetBackgroundSize(showIcon)
	local background = self.Background
	local barPadding = NeedToKnow.ProfileSettings.BarPadding
	barPadding = PixelUtil.GetNearestPixelSize(barPadding, bar:GetEffectiveScale())

	local bgWidth = self:GetWidth() + 2 * barPadding
	if showIcon then
		bgWidth = bgWidth + self:GetHeight() + barPadding
	end

	background:ClearAllPoints()
	background:SetPoint("RIGHT", barPadding, 0)
	background:SetWidth(bgWidth)
end


-- ------------
-- Bar behavior
-- ------------

function Bar:UpdateAppearance()
	-- For bar elements that can change in combat
	-- Called by Bar:CheckAura()

	local barSettings = self.settings

	local icon = self.Icon
	if barSettings.show_icon and self.iconPath then
		icon:SetTexture(self.iconPath)  -- Icon can change if bar tracks multiple spells
		icon:Show()
		self:SetBackgroundSize(true)
	else
		icon:Hide()  -- Blinking bars don't have an icon
		self:SetBackgroundSize(false)
	end

	local barColor = barSettings.BarColor  	-- Blinking changes bar color
	self.Texture:SetVertexColor(barColor.r, barColor.g, barColor.b)
	self.Texture:SetAlpha(barColor.a)
	self.Texture2:SetVertexColor(barColor.r, barColor.g, barColor.b)
	self.Texture2:SetAlpha(barColor.a)
		-- Texture2 getting shown for indefinite auras
	if self.max_expirationTime and self.max_expirationTime ~= self.expirationTime then 
		-- self.Texture2:SetVertexColor(barColor.r, barColor.g, barColor.b)
		-- self.Texture2:SetAlpha(barColor.a)
		self.Texture2:Show()
	else
		self.Texture2:Hide()
	end

	if self.duration > 0 then
		local duration = self.fixedDuration or self.duration
		self.max_value = duration

		if self.settings.vct_enabled then
			self:UpdateCastTime()
		end
        
		-- Kitjan: Force an update to get all the bars to the current position (sharing code)
		-- This will call UpdateCastTime again, but that seems ok
		self.nextUpdate = UPDATE_INTERVAL
		if self.expirationTime > GetTime() then
			self:OnUpdate(0)
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
end

function Bar:SetValue(barTexture, value, value0)
	-- Called by Bar:OnUpdate(), Bar:OnSizeChanged(), others
	-- Called very frequently. Make sure it's efficient. 

	-- bar.Texture2 used for user-determined max bar duration

	value = math.max(value, 0)
	local pct = math.min(value/self.max_value, 1)
	local pct0 = 0
	if value0 then
		pct0 = math.min(value0/self.max_value, 1)
	end

	local width = (pct - pct0) * self:GetWidth()
	if width < 1 then 
		barTexture:Hide()
	else
		barTexture:SetWidth(width)
		barTexture:SetTexCoord(pct0, 0, pct0, 1, pct, 0, pct, 1)
		barTexture:Show()
	end

	barTexture.cur_value = value  -- So bars size properly with resized group
end


-- ----------
-- Bar config
-- ----------

function Bar:Unlock()
	-- Make bar configurable by player
	-- Called by Bar:Update()

	self:Show()
	self:EnableMouse(true)

	self.Spark:Hide()
	self.Time:Hide()
	self.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	local settings = self.settings

	if settings.Enabled then
		self:SetAlpha(1)
	else
		self:SetAlpha(0.4)
	end

	local barColor = settings.BarColor
	self.Texture:SetVertexColor(barColor.r, barColor.g, barColor.b)
	self.Texture:SetAlpha(barColor.a)
	self.Texture2:Hide()

	self:SetUnlockedText(settings)

	if settings.vct_enabled then
		self.CastTime:SetWidth(self:GetWidth()/8)
		self.CastTime:Show()
	else
		self.CastTime:Hide()
	end
end

function Bar:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(String.BAR_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(String.BAR_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

function Bar:OnLeave()
	_G["GameTooltip"]:Hide()
end

function Bar:OnDragStart()
	self:GetParent():StartMoving()
end

function Bar:OnDragStop()
	local group = self:GetParent()
	group:StopMovingOrSizing()
	group:SavePosition()
end

function Bar:OnSizeChanged()
	local bar1 = self.Texture
	local bar2 = self.Texture2
	if ( bar1.cur_value ) then 
		self:SetValue(bar1, bar1.cur_value)
	end
	if ( bar2.cur_value ) then 
		self:SetValue(bar2, bar2.cur_value, bar1.cur_value)
	end
end

function Bar:OnMouseUp(button)
	if button == "RightButton" then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu:ShowMenu(self)
	end
end


-- ---------
-- Cast time
-- ---------

-- Note: Kitjan's VCT = "Visual Cast Time"

function Bar:UpdateCastTime()
	-- Called by Bar:ConfigureVisible()
	-- Called by Bar:OnUpdate() if CastTime used, so make sure it's efficent
	-- Does GetSpellInfo() actually factor in haste etc?

	local castWidth = 0
	local barDuration = self.fixedDuration or self.duration
	if barDuration then
		local barWidth = self:GetWidth()
		local castDuration = self:GetCastTimeDuration()
		castWidth = barWidth * castDuration / barDuration
		if castWidth > barWidth then
			castWidth = barWidth
		end
	end

	if castWidth > 1 then
		self.CastTime:SetWidth(castWidth)
		self.CastTime:Show()
	else
		self.CastTime:Hide()
	end
end

function Bar:GetCastTimeDuration()
	-- Called by Bar:UpdateCastTime()
	-- Which is called by Bar:OnUpdate() if CastTime used, so make sure it's efficent

	local castDuration = 0

	local spell = self.settings.vct_spell
	if not spell or spell == "" then
		spell = self.buffName
	end
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


