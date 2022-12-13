-- local addonName, addonTable = ...

local BarGroup = NeedToKnow.BarGroup
local ResizeButton = NeedToKnow.ResizeButton
local Bar = NeedToKnow.Bar
local String = NeedToKnow.String

NeedToKnow.MAX_BARGROUPS = 4


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
	-- self.settings = NeedToKnow:GetGroupSettings(self:GetID())
	self.bars = {}
end

function BarGroup:Update()
	-- Called by NeedToKnow:Update()

	local groupID = self:GetID()
	-- self.settings = NeedToKnow:GetGroupSettings(groupID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	local numberBars = groupSettings.NumberBars

	-- Make and/or update bars
	for barID = 1, numberBars do
		if not self.bars[barID] then
			self.bars[barID] = Bar:New(self, barID)
		end
		local bar = self.bars[barID]

		bar:SetWidth(groupSettings.Width)
		if barID > 1 then
			bar:SetPoint("TOP", self.bars[barID-1], "BOTTOM", 0, -NeedToKnow.ProfileSettings.BarSpacing)
		else
			bar:SetPoint("LEFT")
		end

		if not groupSettings.Bars[barID] then
			groupSettings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
		end
		bar:Update()

		if not groupSettings.Enabled then
			bar:Inactivate()
		end
	end
	for barID, bar in ipairs(self.bars) do
		if barID > numberBars then
			bar:Hide()
			bar:Inactivate()
		end
	end

	self.resizeButton:SetPoint("CENTER", self.bars[numberBars], "BOTTOMRIGHT")
	if NeedToKnow.CharSettings["Locked"] then
		self.resizeButton:Hide()
	else
		self.resizeButton:Show()
	end

	self:SetPosition(groupSettings.Position, groupSettings.Scale)
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
	for barID, bar in ipairs(self.bars) do
		bar:SetWidth(width)
		bar.Text:SetWidth(width - 60)
		bar:SetBackgroundSize(bar.settings.show_icon)
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
	local barHeight = group.bars[1]:GetHeight()
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






