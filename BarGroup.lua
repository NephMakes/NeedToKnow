-- Bar group functions, including resize button

local addonName, NeedToKnow = ...
local BarGroup = NeedToKnow.BarGroup
local ResizeButton = NeedToKnow.ResizeButton
local BarGroupTab = NeedToKnow.BarGroupTab
local Bar = NeedToKnow.Bar
local String = NeedToKnow.String
local DefaultSettings = NeedToKnow.DefaultSettings

NeedToKnow.MAX_BARGROUPS = 4

function NeedToKnow:MakeBarGroups()
	self.barGroups = {}
	for groupID = 1, self.MAX_BARGROUPS do
		self.barGroups[groupID] = BarGroup:New(groupID)
	end
end

function NeedToKnow:GetBarGroup(groupID)
	return self.barGroups[groupID]
end

function NeedToKnow:GetGroup(groupID)
	-- Deprecated. Use GetBarGroup() instead. 
	return self.barGroups[groupID]
end

function NeedToKnow:UpdateBarGroups()
	for _, group in pairs(self.barGroups) do
		group:Update()
	end
end

function NeedToKnow:UpdateBarGroup(groupID)
	self.barGroups[groupID]:Update()
end

function NeedToKnow:UpdateGroup(groupID)
	-- Deprecated. Use UpdateBarGroup() instead
	self.barGroups[groupID]:Update()
end


--[[ BarGroup ]]--

function BarGroup:New(groupID)
	-- Called by ExecutiveFrame:ADDON_LOADED()
	local group = CreateFrame("Frame", "NeedToKnow_Group"..groupID, UIParent)
	group:SetID(groupID)
	Mixin(group, BarGroup)
	group:OnLoad()
	return group
end

function BarGroup:OnLoad()
	self:SetMovable(true)
	self:SetSize(1, 1)
	self.resizeButton = ResizeButton:New(self)
	self.tab = BarGroupTab:New(self)
	self.bars = {}
end

function BarGroup:Update()
	self.settings = NeedToKnow:GetGroupSettings(self:GetID())

	if not self.settings.Enabled then
		self:Hide()
		for _, bar in pairs(self.bars) do
			bar:Inactivate()
		end
		return
	end

	-- Make missing bars
	local numberBars = self.settings.NumberBars
	for barID = 1, numberBars do
		if not self.bars[barID] then
			self.bars[barID] = Bar:New(self, barID)
		end
		if not self.settings.Bars[barID] then
			self.settings.Bars[barID] = CopyTable(DefaultSettings.bar)
		end
	end

	-- Update bars
	for barID, bar in ipairs(self.bars) do
		if barID > numberBars then
			bar:Hide()
			bar:Inactivate()
		else
			bar:SetWidth(self.settings.Width)
			bar:Update()
		end
	end
	self:UpdateBarPosition()

	self:Show()
	self:SetPosition(self.settings.Position, self.settings.Scale)
	self.resizeButton:Update()
	self.tab:Update()
end

function BarGroup:SetPosition(position, scale)
	self:SetScale(scale)  -- Set scale before PixelUtil calls
	self:ClearAllPoints()
	local point, relativePoint, xOfs, yOfs = unpack(position)
	PixelUtil.SetPoint(self, point, UIParent, relativePoint, xOfs, yOfs)
end

function BarGroup:SetBarWidth(width)
	for _, bar in pairs(self.bars) do
		PixelUtil.SetWidth(bar, width)
		bar.Text:SetWidth(width - 60)
		bar:SetBorder()
	end
end

function BarGroup:UpdateBarPosition()
	-- Called by BarGroup:Update(), Bar:CheckAura()
	local bar, previousBar
	local barSpacing = PixelUtil.GetNearestPixelSize(
		NeedToKnow.ProfileSettings.BarSpacing, self:GetEffectiveScale()
	)
	for barID = 1, self.settings.NumberBars do
		bar = self.bars[barID]
		if not self.settings.condenseGroup or (self.settings.condenseGroup and bar:IsVisible()) then
			bar:ClearAllPoints()
			if self.settings.direction == "up" then
				if not previousBar then
					bar:SetPoint("BOTTOMLEFT")
				else
					bar:SetPoint("BOTTOM", previousBar, "TOP", 0, barSpacing)
				end
			else
				if not previousBar then
					bar:SetPoint("TOPLEFT")
				else
					bar:SetPoint("TOP", previousBar, "BOTTOM", 0, -barSpacing)
				end
			end
			previousBar = bar
		end
	end
end

function BarGroup:SavePosition()
	local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
	local groupSettings = NeedToKnow:GetGroupSettings(self:GetID())
	groupSettings.Position = {point, relativePoint, xOfs, yOfs}
	groupSettings.Scale = self:GetScale()
end

function BarGroup:SaveBarWidth()
	local groupSettings = NeedToKnow:GetGroupSettings(self:GetID())
	groupSettings.Width = self.bars[1]:GetWidth()
end


--[[ ResizeButton ]]--

function ResizeButton:New(barGroup)
	local button = CreateFrame("Button", barGroup:GetName().."ResizeButton", barGroup)
	Mixin(button, ResizeButton)
	button:OnLoad()
	return button
end

function ResizeButton:OnLoad()
	self:SetSize(20, 20)
	self.texture = self:CreateTexture(self:GetName().."Texture", "OVERLAY")
	self.texture:SetTexture("Interface\\AddOns\\NeedToKnow\\Textures\\Resize")
	self.texture:SetAllPoints()
	self.texture:SetVertexColor(0.6, 0.6, 0.6)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
	self:SetScript("OnMouseUp", self.OnMouseUp)
end

function ResizeButton:Update()
	if NeedToKnow.isLocked then
		self:Hide()
	else
		self:Show()
		local group = self:GetParent()
		local numberBars = group.settings.NumberBars
		if group.settings.direction == "up" then
			self:SetPoint("CENTER", group.bars[numberBars], "TOPRIGHT")
			self.texture:SetRotation(math.pi/2)
		else
			self:SetPoint("CENTER", group.bars[numberBars], "BOTTOMRIGHT")
			self.texture:SetRotation(0)
		end
	end
end

function ResizeButton:OnEnter()
	local tooltip = _G["GameTooltip"]
	GameTooltip_SetDefaultAnchor(tooltip, self)
	tooltip:AddLine(String.RESIZE_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	tooltip:Show()
	self.texture:SetVertexColor(1, 1, 1)
end

function ResizeButton:OnLeave()
	GameTooltip:Hide()
	self.texture:SetVertexColor(0.6, 0.6, 0.6)
end

function ResizeButton:OnMouseDown()
	local group = self:GetParent()
	group.oldX, group.oldY = group:GetLeft(), group:GetTop()
	group.oldScale = group:GetScale()
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", group.oldX, group.oldY)
	self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
	self.oldWidth = group.bars[1]:GetWidth()
	self:SetScript("OnUpdate", ResizeButton.OnUpdate)
end

function ResizeButton:OnUpdate()
	local uiScale = UIParent:GetScale()
	local group = self:GetParent()
	local oldScale = group.oldScale
	local cursorX, cursorY = GetCursorPosition(UIParent)

	-- Find new scale, clamped so bars are whole pixels tall
	local newScale = oldScale * (cursorY/uiScale - group.oldY*oldScale) / (self.oldCursorY/uiScale - group.oldY*oldScale)
	local barHeight = group.bars[1]:GetHeight()
	local newHeight = PixelUtil.GetNearestPixelSize(barHeight * newScale, newScale)
	newScale = newHeight / barHeight
	newScale = max(0.3, newScale)

	-- Find new frame coords to keep same on-screen position
	local newX = group.oldX * oldScale / newScale
	local newY = group.oldY * oldScale / newScale
	local newPosition = {"TOPLEFT", "BOTTOMLEFT", newX, newY}

	-- Find new bar width
	local newWidth = ((cursorX - self.oldCursorX)/uiScale + self.oldWidth*oldScale) / newScale
	newWidth = max(50, newWidth)

	group:SetPosition(newPosition, newScale)
	group:SetBarWidth(newWidth)
end

function ResizeButton:OnMouseUp()
	self:SetScript("OnUpdate", nil)
	local group = self:GetParent()
	group:SavePosition()
	group:SaveBarWidth()
end


--[[ BarGroupTab ]]--

function BarGroupTab:New(barGroup)
	local tab = CreateFrame("Button", barGroup:GetName().."Tab", barGroup, "NeedToKnow_BarGroupTabTemplate")
	Mixin(tab, BarGroupTab)
	tab:OnLoad()
	return tab
end

function BarGroupTab:OnLoad()
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnClick", self.OnClick)
	self:SetScript("OnDragStart", self.OnDragStart)
	self:SetScript("OnDragStop", self.OnDragStop)
	self:RegisterForClicks("RightButtonUp")
	self:RegisterForDrag("LeftButton")
	UIDropDownMenu_Initialize(self.menu, self.InitializeDropDown, "MENU")
end

function BarGroupTab:Update()
	if NeedToKnow.isLocked then
		self:Hide()
	else
		self:Show()
		local barGroup = self:GetParent()
		self.text:SetText(String.BAR_GROUP.." "..barGroup:GetID())

		-- Orient up/down
		self:ClearAllPoints()
		self.text:ClearAllPoints()
		self.highlight:ClearAllPoints()
		local borderSize = NeedToKnow.ProfileSettings.BarPadding
		if barGroup.settings.direction == "up" then
			self:SetPoint("TOPLEFT", barGroup, "BOTTOMLEFT", 0, -borderSize)
			self.text:SetPoint("LEFT", self.leftTexture, "RIGHT", 0, 5)
			self.highlight:SetPoint("LEFT", self.leftTexture, "LEFT", 0, 7)
			self.highlight:SetPoint("RIGHT", self.rightTexture, "RIGHT", 0, 7)
			self.leftTexture:SetTexCoord(0, 0.25, 1, 0)
			self.middleTexture:SetTexCoord(0.25, 0.75, 1, 0)
			self.rightTexture:SetTexCoord(0.75, 1, 1, 0)
		else
			self:SetPoint("BOTTOMLEFT", barGroup, "TOPLEFT", 0, borderSize)
			self.text:SetPoint("LEFT", self.leftTexture, "RIGHT", 0, -5)
			self.highlight:SetPoint("LEFT", self.leftTexture, "LEFT", 0, -7)
			self.highlight:SetPoint("RIGHT", self.rightTexture, "RIGHT", 0, -7)
			self.leftTexture:SetTexCoord(0, 0.25, 0, 1)
			self.middleTexture:SetTexCoord(0.25, 0.75, 0, 1)
			self.rightTexture:SetTexCoord(0.75, 1, 0, 1)
		end
	end
end

function BarGroupTab:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(String.BAR_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(String.BAR_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

function BarGroupTab:OnLeave()
	_G["GameTooltip"]:Hide()
end

function BarGroupTab:OnClick(mouseButton)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	if mouseButton == "RightButton" then
		ToggleDropDownMenu(1, nil, self.menu, self:GetName(), 0, 0)
		return
	end
	CloseDropDownMenus()
end

function BarGroupTab:InitializeDropDown()
	local info = UIDropDownMenu_CreateInfo()

	info.text = String.GROUP_OPTIONS
	info.func = BarGroupTab.OpenOptionsPanel
	info.isNotRadio = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	info.text = String.LOCK_AND_ACTIVATE
	info.func = NeedToKnow.Lock
	info.isNotRadio = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

function BarGroupTab:OpenOptionsPanel()
	Settings.OpenToCategory(addonName)  -- Blizz function
end

function BarGroupTab:OnDragStart()
	self:GetParent():StartMoving()
end

function BarGroupTab:OnDragStop()
	local barGroup = self:GetParent()
	barGroup:StopMovingOrSizing()
	barGroup:SavePosition()
end


