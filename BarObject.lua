-- Bar appearance and interaction

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar
local String = NeedToKnow.String

NeedToKnow.BarBorder = {}
local BarBorder = NeedToKnow.BarBorder


--[[ NeedToKnow:BarMethods() ]]--

function NeedToKnow:GetBar(groupID, barID)
	return _G["NeedToKnow_Group"..groupID.."Bar"..barID]
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	NeedToKnow:GetBar(groupID, barID):Update()
end


--[[ Bar setup ]]--

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
	self.spark = self.Spark
	self.text = self.Text
	self.time = self.Time
	self.vct = self.CastTime

	Mixin(self.border, BarBorder)
	Mixin(self.icon.border, BarBorder)
end

function Bar:SetAppearanceOptions()
	-- Setting names can be nonintuitive so let's corral them
	-- Called by Bar:Update

	local settings = self.settings
	self.barColor = settings.BarColor
	self.showText = settings.show_text
	self.showCount = settings.show_count
	self.showTime = settings.show_time
	self.showSpark = settings.show_spark
	self.showIcon = settings.show_icon

	local groupSettings = self:GetParent().settings
	self.condenseGroup = groupSettings.condenseGroup
end

function Bar:SetAppearance()
	-- Set bar elements that don't change in combat
	-- Called by Bar:Update()

	local settings = NeedToKnow.ProfileSettings
	local barSettings = self.settings

	self.Texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))
	self.background:SetVertexColor(unpack(settings.BkgdColor))
	self.border:SetVertexColor(unpack(settings.BorderColor))
	self:SetBorder()

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
		self.Text:SetTextColor(unpack(settings.FontColor))
		self.Time:SetFont(fontPath, settings.FontSize, outline)
		self.Time:SetTextColor(unpack(settings.FontColor))
	end

	local time = self.Time
	if self.showTime then
		if barSettings.TimeFormat == "Fmt_TwoUnits" then
			self.FormatTime = self.FormatTimeTwoUnits
		elseif barSettings.TimeFormat == "Fmt_Float" then
			self.FormatTime = self.FormatTimeDecimal
		else
			self.FormatTime = self.FormatTimeSingle
		end
		time:Show()
	else
		time:Hide()
	end

	local icon = self.icon
	if self.showIcon then
		icon.border:SetVertexColor(unpack(settings.BkgdColor))
		icon.background:SetVertexColor(unpack(settings.BkgdColor))
		icon:Show()
	else
		icon:Hide()
	end

	if self.showCastTime then
		local color = self.castTimeColor
		self.CastTime:SetColorTexture(color.r, color.g, color.b, color.a)
	else
		self.CastTime:Hide()
	end
end

function Bar:SetBorder()
	-- Called by Bar:SetAppearance(), BarGroup:SetBarWidth()
	local borderSize = NeedToKnow.ProfileSettings.BarPadding
	self.border:SetBorderSize(borderSize)
	local icon = self.icon
	PixelUtil.SetPoint(icon, "TOPRIGHT", self, "TOPLEFT", -borderSize, 0)
	PixelUtil.SetPoint(icon, "BOTTOMRIGHT", self, "BOTTOMLEFT", -borderSize, 0)
	PixelUtil.SetWidth(icon, self:GetHeight())
	icon.border:SetBorderSize(borderSize)
	icon.border.right:Hide()  -- For uniform border if alpha < 1
end


--[[ Bar border ]]--

function BarBorder:SetVertexColor(r, g, b, a)
	for _, texture in pairs(self.textures) do
		texture:SetVertexColor(r, g, b, a)
	end
end

function BarBorder:SetBorderSize(borderSize)
	-- Set border size, clamped to whole pixels
	PixelUtil.SetPoint(self.left, "TOPRIGHT", self, "TOPLEFT", 0, borderSize)
	PixelUtil.SetPoint(self.left, "BOTTOMRIGHT", self, "BOTTOMLEFT", 0, -borderSize)
	PixelUtil.SetWidth(self.left, borderSize)

	PixelUtil.SetPoint(self.right, "TOPLEFT", self, "TOPRIGHT", 0, borderSize)
	PixelUtil.SetPoint(self.right, "BOTTOMLEFT", self, "BOTTOMRIGHT", 0, -borderSize)
	PixelUtil.SetWidth(self.right, borderSize)

	PixelUtil.SetPoint(self.top, "BOTTOMLEFT", self, "TOPLEFT", 0, 0)
	PixelUtil.SetPoint(self.top, "BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
	PixelUtil.SetHeight(self.top, borderSize)

	PixelUtil.SetPoint(self.bottom, "TOPLEFT", self, "BOTTOMLEFT", 0, 0)
	PixelUtil.SetPoint(self.bottom, "TOPRIGHT", self, "BOTTOMRIGHT", 0, 0)
	PixelUtil.SetHeight(self.bottom, borderSize)
end


--[[ Bar behavior ]]--

function Bar:UpdateAppearance()
	-- Set bar elements that can change in combat
	-- Called by Bar:OnDurationFound

	-- Bar color changes when blinking
	local color = self.barColor
	self.Texture:SetVertexColor(color.r, color.g, color.b, color.a)

	-- Icon changes if bar tracks multiple things
	local icon = self.icon
	if self.showIcon and self.iconPath then
		icon.texture:SetTexture(self.iconPath)
		icon:Show()
	else
		icon:Hide()
	end

	if self.duration > 0 then
		if self.showTime then
			self.Time:Show()
		else
			self.Time:Hide()
		end
		if self.showCastTime then
			self:UpdateCastTime()
		end
		-- SetValue and Spark handled by Bar:OnUpdate
	else
		-- Indefinite aura
		self.Time:Hide()
		self.CastTime:Hide()
		self:SetValue(self.maxTimeLeft)
		self.Spark:Hide()
	end
end

function Bar:SetValue(timeLeft)
	-- Called by Bar:OnUpdate, Bar:OnSizeChanged, Bar:UpdateAppearance, Bar:Blink
	-- Called very frequently. Make it efficient. 
	if timeLeft < 0 then 
		timeLeft = 0
	end
	local fractionFull = timeLeft/self.maxTimeLeft
		-- maxTimeLeft set by Bar:OnDurationFound, Bar:OnDurationAbsent, Bar:Unlock
		-- Bar.xml sets default maxTimeLeft = 1
	if fractionFull > 1 then
		fractionFull = 1
	end
	local textureWidth = self:GetWidth() * fractionFull
	if textureWidth < 1 then
		textureWidth = 1
	end
	self.Texture:SetWidth(textureWidth)
	self.Texture:SetTexCoord(0, fractionFull, 0, 1)  -- Crop so it's depleting, not squishing
	self.barValue = timeLeft  -- So bars size properly with resized group
end

function Bar:CondenseBarGroup()
	-- Called by Bar:CheckAura
	if self.isVisible ~= self:IsVisible() then
		self:GetParent():UpdateBarPosition()
		self.isVisible = self:IsVisible()
	end
end


--[[ Bar config ]]--

function Bar:Unlock()
	-- Make bar configurable by player
	-- Called by Bar:Update()

	self:Show()
	self:EnableMouse(true)

	self.maxTimeLeft = 1
	self:SetValue(self.maxTimeLeft)
	local color = self.barColor
	self.Texture:SetVertexColor(color.r, color.g, color.b, color.a)
	self.Time:Hide()
	self.Spark:Hide()
	self:SetUnlockedText()

	if self.showCastTime then
		self.CastTime:SetWidth(self:GetWidth()/8)
		self.CastTime:Show()
	else
		self.CastTime:Hide()
	end

	if self.isEnabled then
		self:SetAlpha(1)
	else
		self:SetAlpha(0.4)
	end
end

function Bar:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(String.BAR_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(String.BAR_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

function Bar:OnLeave()
	GameTooltip:Hide()
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
	-- Called when user resizes BarGroup. Any other time? 
	if self.barValue then 
		self:SetValue(self.barValue)
	end
end

function Bar:OnMouseUp(button)
	if button == "RightButton" then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu:ShowMenu(self)
	end
end


