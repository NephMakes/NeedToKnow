-- local addonName, addonTable = ...

local BarGroup = NeedToKnow.BarGroup
local ResizeButton = NeedToKnow.ResizeButton
local Bar = NeedToKnow.Bar

-- ---------
-- Bar Group
-- ---------

function BarGroup:OnLoad()
	self.Update       = BarGroup.Update
	self.SetPosition  = BarGroup.SetPosition
	self.SetBarWidth  = BarGroup.SetBarWidth
	self.SavePosition = BarGroup.SavePosition
	self.SaveBarWidth = BarGroup.SaveBarWidth
	self.bar = {}     -- Table for Bar frames
end

function BarGroup:Update()
	local groupID = self:GetID()
	local groupName = self:GetName()
	local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

	local bar
	for barID = 1, groupSettings.NumberBars do
		if ( self.bar[barID] ) then
			bar = self.bar[barID]
		else
			bar = CreateFrame("Frame", groupName.."Bar"..barID, self, "NeedToKnow_BarTemplate")
			bar:SetID(barID)
			self.bar[barID] = bar
		end

		bar:SetWidth(groupSettings.Width)
		if ( barID > 1 ) then
			bar:SetPoint("TOP", self.bar[barID-1], "BOTTOM", 0, -NeedToKnow.ProfileSettings.BarSpacing)
		else
			bar:SetPoint("TOPLEFT")
		end

		NeedToKnow.Bar_Update(groupID, barID)

		if ( not groupSettings.Enabled ) then
			bar:ClearScripts()
		end
	end

	local resizeButton = self.ResizeButton
	resizeButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -8)
	if ( NeedToKnow.CharSettings["Locked"] ) then
		resizeButton:Hide()
	else
		resizeButton:Show()
	end

	-- Hide and disable unused bars
	local barID = groupSettings.NumberBars + 1
	while true do
		bar = self.bar[barID]
		if ( bar ) then
			bar:Hide()
			bar:ClearScripts()
			barID = barID + 1
		else
			break
		end
	end

	if ( groupSettings.Position ) then
		-- Early in loading process (before PLAYER_LOGIN) might not know position yet
		self:SetPosition(groupSettings.Position, groupSettings.Scale)
	end

	if ( NeedToKnow.IsVisible and groupSettings.Enabled ) then
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
		-- NeedToKnow.SizeBackground(bar, bar.settings.show_icon)
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






