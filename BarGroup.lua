-- local addonName, addonTable = ...
local Bar = NeedToKnow.Bar

-- ---------
-- Bar Group
-- ---------

local BarGroup = NeedToKnow.BarGroup

function BarGroup:OnLoad()
	-- Called by NeedToKnow_GroupTemplate
	Mixin(self, BarGroup) -- Inherit BarGroup methods
	self.bar = {} -- Table of bar frames
end

function BarGroup:Update()
	-- Called by NeedToKnow:Update()

	local groupID = self:GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	local bar

	for barID = 1, groupSettings.NumberBars do
		if not groupSettings.Bars[barID] then
			groupSettings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
		end

		if self.bar[barID] then
			bar = self.bar[barID]
		else
			bar = Bar:New(self, barID)
			self.bar[barID] = bar
		end
		bar:SetWidth(groupSettings.Width)
		if barID > 1 then
			bar:SetPoint("TOP", self.bar[barID-1], "BOTTOM", 0, -NeedToKnow.ProfileSettings.BarSpacing)
		else
			bar:SetPoint("TOPLEFT")
		end

		bar:Update()
		if not groupSettings.Enabled then
			bar:Inactivate()
		end
	end

	local resizeButton = self.ResizeButton
	resizeButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -8)
	if NeedToKnow.CharSettings["Locked"] then
		resizeButton:Hide()
	else
		resizeButton:Show()
	end

	-- Hide and disable unused bars
	local barID = groupSettings.NumberBars + 1
	while true do
		bar = self.bar[barID]
		if bar then
			bar:Hide()
			bar:Inactivate()
			barID = barID + 1
		else
			break
		end
	end

	if groupSettings.Position then
		-- Early in loading process (before PLAYER_LOGIN) might not know position yet
		self:SetPosition(groupSettings.Position, groupSettings.Scale)
	end

	if NeedToKnow.IsVisible and groupSettings.Enabled then
		self:Show()
	else
		self:Hide()
	end
end

function BarGroup:SetPosition(position, scale)
	local point, relativePoint, xOfs, yOfs = unpack(position)
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
	self:SetScale(scale)
end

function BarGroup:SetBarWidth(width)
	groupID = self:GetID()
	for barID = 1, NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"] do
		local bar = self.bar[barID]
		bar:SetWidth(width)
		bar.Text:SetWidth(width - 60)
		bar:SetBackgroundSize(bar.settings.show_icon)
	end
end

function BarGroup:SavePosition()
	local groupID = self:GetID()
	local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
	NeedToKnow.ProfileSettings.Groups[groupID]["Position"] = {point, relativePoint, xOfs, yOfs}
	NeedToKnow.ProfileSettings.Groups[groupID]["Scale"] = self:GetScale()
end

function BarGroup:SaveBarWidth()
	NeedToKnow.ProfileSettings.Groups[self:GetID()]["Width"] = self.bar[1]:GetWidth()
end


-- -------------
-- Resize Button
-- -------------

local ResizeButton = NeedToKnow.ResizeButton

function ResizeButton:OnLoad()
	self.Texture:SetVertexColor(0.6, 0.6, 0.6)
	self:SetScript("OnEnter", ResizeButton.OnEnter)
	self:SetScript("OnLeave", ResizeButton.OnLeave)
	self:SetScript("OnMouseDown", ResizeButton.OnMouseDown)
	self:SetScript("OnMouseUp", ResizeButton.OnMouseUp)
end

function ResizeButton:OnEnter()
	local tooltip = _G["GameTooltip"]
	GameTooltip_SetDefaultAnchor(tooltip, self)
	tooltip:AddLine(NEEDTOKNOW.RESIZE_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	tooltip:Show()
	self.Texture:SetVertexColor(1, 1, 1)
end

function ResizeButton:OnLeave()
	GameTooltip:Hide()
	self.Texture:SetVertexColor(0.6, 0.6, 0.6)
end

function ResizeButton:OnMouseDown()
	local group = self:GetParent()
	group.oldX = group:GetLeft()
	group.oldY = group:GetTop()
	group.oldScale = group:GetScale()
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", group.oldX, group.oldY)
	self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
	self.oldWidth = group.bar[1]:GetWidth()
	self:SetScript("OnUpdate", ResizeButton.OnUpdate)
end

function ResizeButton:OnMouseUp()
	self:SetScript("OnUpdate", nil)
	local group = self:GetParent()
	group:SavePosition()
	group:SaveBarWidth()
end

function ResizeButton:OnUpdate()
	local uiScale = UIParent:GetScale()
	local cursorX, cursorY = GetCursorPosition(UIParent)
	local group = self:GetParent()

	-- Find new scale
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.25, newYScale)

	-- Clamp scale so bars are integer pixels tall
	local barHeight = group.bar[1]:GetHeight()
	local newHeight = newScale * barHeight
	newHeight = math.floor(newHeight + 0.0002) -- small addition so won't shrink on click
	newScale = newHeight / barHeight  

	-- Find new frame coords to keep same on-screen position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	local newPosition = {"TOPLEFT", "BOTTOMLEFT", newX, newY}

	-- Find new bar width
	local newWidth = ((cursorX - self.oldCursorX)/uiScale + self.oldWidth*group.oldScale)/newScale
	-- Clamp width so bars are integer pixels wide
	newWidth = math.floor(max(50, newWidth) + 0.0002 ) -- small addition so won't shrink on click

	group:SetPosition(newPosition, newScale)
	group:SetBarWidth(newWidth)
end






