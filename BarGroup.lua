-- local addonName, addonTable = ...

-- ---------
-- Bar Group
-- ---------

local BarGroup = NeedToKnow.BarGroup

function BarGroup:OnLoad()
	-- self.Update = BarGroup.Update
	self.SetPosition = BarGroup.SetPosition
	self.SetBarWidth = BarGroup.SetBarWidth
	self.SavePosition = BarGroup.SavePosition
	self.SaveBarWidth = BarGroup.SaveBarWidth
end

function NeedToKnow.UpdateBarGroup(groupID)
	-- Called in NeedToKnow.lua and NeedToKnow_Options.lua

	local groupName = "NeedToKnow_Group"..groupID
	local group = _G[groupName]
	local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

	-- group.bar = {}
	-- local bar = group.bar
	local bar
	for barID = 1, groupSettings.NumberBars do
		local barName = groupName.."Bar"..barID
		--[[ 
		if not bar[barID] then
			bar[barID] = CreateFrame("Frame", barName, group, "NeedToKnow_BarTemplate")
			bar:SetID(barID)
		end
		]]--
		bar = _G[barName] or CreateFrame("Frame", barName, group, "NeedToKnow_BarTemplate")
		bar:SetID(barID)

		if ( barID > 1 ) then
			bar:SetPoint("TOP", _G[groupName.."Bar"..(barID-1)], "BOTTOM", 0, -NeedToKnow.ProfileSettings.BarSpacing)
		else
			bar:SetPoint("TOPLEFT", group, "TOPLEFT")
		end

		NeedToKnow.Bar_Update(groupID, barID)

		if ( not groupSettings.Enabled ) then
			NeedToKnow.ClearScripts(bar)
		end
	end

	local resizeButton = group.ResizeButton
	resizeButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -8)
	if ( NeedToKnow.CharSettings["Locked"] ) then
		resizeButton:Hide()
	else
		resizeButton:Show()
	end

	local barID = groupSettings.NumberBars+1
	while true do
		bar = _G[groupName.."Bar"..barID]
		if bar then
			bar:Hide()
			NeedToKnow.ClearScripts(bar)
			barID = barID + 1
		else
			break
		end
	end

	if groupSettings.Position then
		-- Early in loading process (before PLAYER_LOGIN) might not know position yet
		group:SetPosition(groupSettings.Position, groupSettings.Scale)
	end

	if ( NeedToKnow.IsVisible and groupSettings.Enabled ) then
		group:Show()
	else
		group:Hide()
	end
end

--[[
function BarGroup:Update()
    local groupSettings = NeedToKnow.ProfileSettings.Groups[self:GetID()]
    -- ...
end
]]--

function BarGroup:SetPosition(position, scale)
	local point, relativePoint, xOfs, yOfs = unpack(position)
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
	self:SetScale(scale)
end

function BarGroup:SetBarWidth(width)
	groupID = self:GetID()
	for barID = 1, NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"] do
		local bar = _G["NeedToKnow_Group"..groupID.."Bar"..barID]
		local text = bar.Text
		bar:SetWidth(width)
		text:SetWidth(width - 60)
		NeedToKnow.SizeBackground(bar, bar.settings.show_icon)
	end
end

function BarGroup:SavePosition()
	local groupID = self:GetID()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    NeedToKnow.ProfileSettings.Groups[groupID]["Position"] = {point, relativePoint, xOfs, yOfs}
    NeedToKnow.ProfileSettings.Groups[groupID]["Scale"] = self:GetScale()
end

function BarGroup:SaveBarWidth()
	local groupID = self:GetID()
	local width = _G["NeedToKnow_Group"..groupID.."Bar"..1]:GetWidth()
	NeedToKnow.ProfileSettings.Groups[groupID]["Width"] = width
	-- NeedToKnow.ProfileSettings.Groups[self:GetID()]["Width"] = self.bar[1]:GetWidth()
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
	self.oldWidth = _G[group:GetName().."Bar1"]:GetWidth()
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
	local bar1 = _G[group:GetName().."Bar1"]

	-- Find new scale
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.25, newYScale)
	local barHeight = bar1:GetHeight()
	local newHeight = newScale * barHeight
	newHeight = math.floor(newHeight + 0.0002) 
		-- clamp so bars are integer pixels tall
		-- small addition so won't get smaller on click
	newScale = newHeight / barHeight  

	-- Find new frame coords to keep same on-screen position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	local newPosition = {"TOPLEFT", "BOTTOMLEFT", newX, newY}

	-- Find new bar width
	local newWidth = ((cursorX - self.oldCursorX)/uiScale + self.oldWidth*group.oldScale)/newScale
	newWidth = math.floor(max(50, newWidth) + 0.0002 )
		-- clamp so bars are integer pixels wide
		-- small addition so won't get smaller on click

	group:SetPosition(newPosition, newScale)
	group:SetBarWidth(newWidth)
end






