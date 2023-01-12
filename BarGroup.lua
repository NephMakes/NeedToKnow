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
	self.bars = {}
end

function BarGroup:Update()
	-- Called by NeedToKnow:Update(), NeedToKnow:UpdateBarGroup()
	self.settings = NeedToKnow:GetGroupSettings(self:GetID())

	if not self.settings.Enabled then
		self:Hide()
		for barID, bar in ipairs(self.bars) do
			bar:Inactivate()
		end
		return
	else
		self:Show()
		self:SetPosition(self.settings.Position, self.settings.Scale)
		self.resizeButton:Update()
	end

	-- Make missing bars
	local numberBars = self.settings.NumberBars
	for barID = 1, numberBars do
		if not self.bars[barID] then
			self.bars[barID] = Bar:New(self, barID)
		end
		if not self.settings.Bars[barID] then
			self.settings.Bars[barID] = CopyTable(NEEDTOKNOW.BAR_DEFAULTS)
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
end

function BarGroup:SetPosition(position, scale)
	self:ClearAllPoints()
	self:SetScale(scale)
	local point, relativePoint, xOfs, yOfs = unpack(position)
	PixelUtil.SetPoint(self, point, UIParent, relativePoint, xOfs, yOfs)
end

function BarGroup:SetBarWidth(width)
	for barID, bar in ipairs(self.bars) do
		PixelUtil.SetWidth(bar, width)
		bar:SetBorder()
		bar.Text:SetWidth(width - 60)
	end
end

function BarGroup:UpdateBarPosition()
	-- Called by BarGroup:Update(), Bar:CheckAura()
	local bar, previousBar
	-- local barSpacing = NeedToKnow.ProfileSettings.BarSpacing
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

function ResizeButton:OnMouseUp()
	self:SetScript("OnUpdate", nil)
	local group = self:GetParent()
	group:SavePosition()
	group:SaveBarWidth()
end






