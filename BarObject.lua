-- Bar appearance and interaction

-- local addonName, addonTable = ...
local Bar = NeedToKnow.Bar

function Bar:OnLoad()
	-- Called by NeedToKnow_BarTemplate

	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEnter",       Bar.OnEnter)
	self:SetScript("OnLeave",       Bar.OnLeave)
	self:SetScript("OnMouseUp",     Bar.OnMouseUp)
	self:SetScript("OnDragStart",   Bar.OnDragStart)
	self:SetScript("OnDragStop",    Bar.OnDragStop)
	self:SetScript("OnSizeChanged", Bar.OnSizeChanged)

	self.SetValue = Bar.SetValue

	self.SetAppearance = Bar.SetAppearance
	self.SetBackgroundSize = Bar.SetBackgroundSize
	self.Unlock            = Bar.Unlock
	self.StartBlink        = Bar.StartBlink

	-- Defined in BarEngine.lua: 
	-- self.Update = Bar.Update
	-- self.Initialize = Bar.Initialize
	self.SetScripts                 = Bar.SetScripts
	self.ClearScripts               = Bar.ClearScripts
	self.CheckCombatLogRegistration = Bar.CheckCombatLogRegistration
	-- self:SetScript("OnEvent", Bar.OnEvent)
end

function Bar:OnEnter()
	local tooltip = _G["GameTooltip"]
	tooltip:SetOwner(self:GetParent(), "ANCHOR_TOPLEFT")
	tooltip:AddLine(NEEDTOKNOW.BAR_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	tooltip:AddLine(NEEDTOKNOW.BAR_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	tooltip:Show()
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
	local bar1 = self.bar1
	local bar2 = self.bar2
	if ( bar1.cur_value ) then 
		self:SetValue(bar1, bar1.cur_value)
	end
	if ( bar2 and bar2.cur_value ) then 
		self:SetValue(bar2, bar2.cur_value, bar1.cur_value)
	end
end

function Bar:OnMouseUp(button)
	if ( button == "RightButton" ) then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu.ShowMenu(self)
	end
end

function Bar:SetValue(texture, value, value0)
	-- Called by Bar:OnUpdate(), so we want to be more efficient than this

	value = math.max(value, 0)
	local pct = math.min(value/self.max_value, 1)
	local pct0 = 0
	if ( value0 ) then
		pct0 = math.min(value0/self.max_value, 1)
	end

	local width = (pct - pct0) * self:GetWidth()
	if ( width < 1 ) then 
		texture:Hide()
	else
		texture:SetWidth(width)
		texture:SetTexCoord(pct0,0, pct0,1, pct,0, pct,1)
		texture:Show()
	end
	texture.cur_value = value  -- Do we really need to do this every OnUpdate()?
end

function Bar:SetAppearance()
	-- Called by Bar:Update()

	local settings = NeedToKnow.ProfileSettings
	local barSettings = self.settings

	self.Texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))
	if ( self.bar2 ) then
		self.bar2:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))
	end

	local fontPath = NeedToKnow.LSM:Fetch("font", settings.BarFont)
	if ( fontPath ) then
		local outline = settings.FontOutline
		if ( outline == 0 ) then
			outline = nil
		elseif ( outline == 1 ) then
			outline = "OUTLINE"
		else
			outline = "THICKOUTLINE"
		end
		self.Text:SetFont(fontPath, settings.FontSize, outline)
		self.Time:SetFont(fontPath, settings.FontSize, outline)
	end
	self.Text:SetWidth(self:GetWidth() - 60)

	local icon = self.Icon
    if ( barSettings.show_icon ) then
        local size = self:GetHeight()
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", self, "LEFT", -settings.BarPadding, 0)
        icon:Show()
    else
        icon:Hide()
    end

	local castTime = self.CastTime
	if ( barSettings.vct_enabled ) then
		local castColor = barSettings.vct_color
		castTime:SetColorTexture(castColor.r, castColor.g, castColor.b, castColor.a)
		castTime:SetHeight(self:GetHeight())
	else
		castTime:Hide()
	end
	self.vct = self.CastTime  -- Want to not need this eventually

	-- Background
	self:SetBackgroundSize(barSettings.show_icon)
	self.Background:SetHeight(self:GetHeight() + 2*settings.BarPadding)
	self.Background:SetVertexColor(unpack(settings.BkgdColor))
end

function Bar:SetBackgroundSize(showIcon)
	local background = self.Background
	local barPadding = NeedToKnow.ProfileSettings["BarPadding"]

	local bgWidth = self:GetWidth() + 2*barPadding
	if ( showIcon ) then
		bgWidth = bgWidth + self:GetHeight() + barPadding
	end

	background:ClearAllPoints()
	background:SetPoint("RIGHT", barPadding, 0)
	background:SetWidth(bgWidth)
end

function Bar:Unlock()
	-- Set bar for user config
	-- Called by Bar:Update()

	self:Show()
	self:EnableMouse(true)

	self.Spark:Hide()
	self.Time:Hide()
	if ( self.bar2 ) then
		self.bar2:Hide()
	end
	self.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	self.CastTime:SetWidth(self:GetWidth()/16)
	self.CastTime:Show()

	local settings = self.settings

	local barColor = settings.BarColor
	self.Texture:SetVertexColor(barColor.r, barColor.g, barColor.b)
	self.Texture:SetAlpha(barColor.a)

	local txt = ""
	if ( settings.show_mypip ) then
		txt = txt.."* "
	end
	if ( settings.show_text ) then
		if ( "" ~= settings.show_text_user ) then
			txt = settings.show_text_user
		else
			txt = txt .. NeedToKnow.PrettyName(settings)
		end

		if ( settings.append_cd
			 and (settings.BuffOrDebuff == "CASTCD"
			   or settings.BuffOrDebuff == "BUFFCD"
			   or settings.BuffOrDebuff == "EQUIPSLOT" ) )
		then
			txt = txt .. " CD"
		elseif ( settings.append_usable and settings.BuffOrDebuff == "USABLE" ) then
			txt = txt .. " Usable"
		end

		if ( settings.bDetectExtends == true ) then
			txt = txt .. " + 3s"
		end
	end
	self.Text:SetText(txt)

	if ( settings.Enabled ) then
		self:SetAlpha(1)
	else
		self:SetAlpha(0.4)
	end
end

function Bar:StartBlink()
	local settings = self.settings

	if ( not self.blink ) then
		self.blink = true
		self.blink_phase = 1
		local blinkColor = settings.MissingBlink
		self.bar1:SetVertexColor(blinkColor.r, blinkColor.g, blinkColor.b)
		self.bar1:SetAlpha(blinkColor.a)
	end
	self.max_value = 1
	self:SetValue(self.bar1, 1)
	self.Text:SetText(settings.blink_label)

	self.Time:Hide()
	self.Spark:Hide()
	self.Icon:Hide()
	self:SetBackgroundSize(false)
	if ( self.bar2 ) then
		self.bar2:Hide()
	end
end



