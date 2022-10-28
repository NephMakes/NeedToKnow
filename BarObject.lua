-- Bar appearance and interaction

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar

--[[
function Bar:New()
	-- Instead of doing it in BarGroup:Update() and elsewhere
end

function Bar:Initialize()
	-- Instead of OnLoad() in XML
	-- called by Bar:Update()?
end
]]--

function Bar:OnLoad()
	-- Called by NeedToKnow_BarTemplate

	-- Bar interaction
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEnter", Bar.OnEnter)
	self:SetScript("OnLeave", Bar.OnLeave)
	self:SetScript("OnMouseUp", Bar.OnMouseUp)
	self:SetScript("OnDragStart", Bar.OnDragStart)
	self:SetScript("OnDragStop", Bar.OnDragStop)
	self:SetScript("OnSizeChanged", Bar.OnSizeChanged)
	
	Mixin(self, Bar) -- Inherit Bar:Methods()

	-- Want to not need these eventually
    self.bar1 = self.Texture
    self.bar2 = self.Texture2
	self.icon = self.Icon
	self.spark = self.Spark
    self.text = self.Text
    self.time = self.Time
	self.vct = self.CastTime
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
	if ( button == "RightButton" ) then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu.ShowMenu(self)
	end
end

function Bar:SetValue(texture, value, value0)
	-- TO DO: Move to BarEngine.lua
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
	-- Set bar elements that don't change in combat
	-- Called by Bar:Update()

	local settings = NeedToKnow.ProfileSettings
	local barSettings = self.settings
	local barHeight = self:GetHeight()

	self.Texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))
	self.Texture2:SetTexture(NeedToKnow.LSM:Fetch("statusbar", settings.BarTexture))

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
		icon:SetSize(barHeight, barHeight)
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
		castTime:SetHeight(barHeight)
	else
		castTime:Hide()
	end

	self:SetBackgroundSize(barSettings.show_icon)
	self.Background:SetHeight(barHeight + 2*settings.BarPadding)
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

--[[
function Bar:UpdateAppearance()
	-- For bar elements that can change in combat
	-- called by mfn_Bar_AuraCheck

	local barSettings = self.settings

	-- Blinking bars don't have an icon
	local icon = self.Icon
	if ( barSettings.show_icon and self.iconPath ) then
		icon:SetTexture(self.iconPath)
		icon:Show()
		self:SetBackgroundSize(true)
	else
		icon:Hide()
		self:SetBackgroundSize(false)
	end

	-- Blinking changes bar color
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
end
]]--

function Bar:Unlock()
	-- Set bar for user config
	-- Called by Bar:Update() and NeedToKnow.Bar_Update

	self:Show()
	self:EnableMouse(true)

	self.Spark:Hide()
	self.Time:Hide()
	self.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	self.CastTime:SetWidth(self:GetWidth()/16)
	self.CastTime:Show()

	local settings = self.settings

	local barColor = settings.BarColor
	self.Texture:SetVertexColor(barColor.r, barColor.g, barColor.b)
	self.Texture:SetAlpha(barColor.a)
	self.Texture2:Hide()

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
		self.Texture:SetVertexColor(blinkColor.r, blinkColor.g, blinkColor.b)
		self.Texture:SetAlpha(blinkColor.a)
	end
	self.max_value = 1
	self:SetValue(self.bar1, 1)
	self.Text:SetText(settings.blink_label)

	self.Time:Hide()
	self.Spark:Hide()
	self.CastTime:Hide()
	self.Texture2:Hide()
	self.Icon:Hide()
	self:SetBackgroundSize(false)
end

function NeedToKnow.ComputeBarText(buffName, count, extended, buff_stacks, bar)
    -- AuraCheck calls on this to compute the "text" of the bar
    -- It is separated out like this in part to be hooked by other addons
    local text
    if ( count > 1 ) then
        text = buffName.."  ["..count.."]"
    else
        text = buffName
    end

    if ( bar.settings.show_ttn1 and buff_stacks.total_ttn[1] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[1]..")"
    end
    if ( bar.settings.show_ttn2 and buff_stacks.total_ttn[2] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[2]..")"
    end
    if ( bar.settings.show_ttn3 and buff_stacks.total_ttn[3] > 0 ) then
        text = text .. " ("..buff_stacks.total_ttn[3]..")"
    end
    if ( extended and extended > 1 ) then
        text = text .. string.format(" + %.0fs", extended)
    end
    return text
end

function NeedToKnow.PrettyName(barSettings)
    if ( barSettings.BuffOrDebuff == "EQUIPSLOT" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NEEDTOKNOW.ITEM_NAMES[idx] end
        return ""
    --[[  
    -- Player power no longer supported
    elseif ( barSettings.BuffOrDebuff == "POWER" ) then
        local idx = tonumber(barSettings.AuraName)
        if idx then return NeedToKnow.GetPowerName(idx) end
        return ""
    ]]--
    else
        return barSettings.AuraName
    end
end

