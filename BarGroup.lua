-- local addonName, addonTable = ...

-- ---------
-- Bar Group
-- ---------

NeedToKnow.BarGroup = {}
local BarGroup = NeedToKnow.BarGroup

function NeedToKnow.UpdateBarGroup(groupID)
    local groupName = "NeedToKnow_Group"..groupID
    local group = _G[groupName]
    local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]

    local bar
    for barID = 1, groupSettings.NumberBars do
        local barName = groupName.."Bar"..barID
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

    -- Early enough in the loading process (before PLAYER_LOGIN), 
    -- we might not know the position yet
    if groupSettings.Position then
        group:ClearAllPoints()
        local point, relativePoint, xOfs, yOfs = unpack(groupSettings.Position)
        group:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        group:SetScale(groupSettings.Scale)
    end
    
    if ( NeedToKnow.IsVisible and groupSettings.Enabled ) then
        group:Show()
    else
        group:Hide()
    end
end

function NeedToKnow.SetWidth(groupID, width)
    for barID = 1, NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"] do
        local bar = _G["NeedToKnow_Group"..groupID.."Bar"..barID];
        local background = _G[bar:GetName().."Background"];
        local text = _G[bar:GetName().."Text"];
        bar:SetWidth(width);
        text:SetWidth(width-60);
        NeedToKnow.SizeBackground(bar, bar.settings.show_icon);
    end
    NeedToKnow.ProfileSettings.Groups[groupID]["Width"] = width;  -- move this to StopSizing?
end

function NeedToKnow.SavePosition(group, groupID)
    groupID = groupID or group:GetID();
    local point, _, relativePoint, xOfs, yOfs = group:GetPoint();
    NeedToKnow.ProfileSettings.Groups[groupID]["Position"] = {point, relativePoint, xOfs, yOfs};
end

--[[
function BarGroup.SetWidth(groupID, width)
	-- called by ResizeButton:OnUpdate()
end

function BarGroup.SavePosition(group, groupID)
	-- called by ResizeButton:OnMouseUp()
end
]]--

--[[
function BarGroup:SetWidth(width)
	-- would be called by ResizeButton:OnUpdate()
	-- but method needs to be defined before it can be called
	-- and would be overriding normal frame:SetWidth() method
end

function BarGroup:SavePosition()
	-- would be called by ResizeButton:OnMouseUp()
	-- but method needs to be defined before it can be called
end
]]--


-- -------------
-- Resize Button
-- -------------

NeedToKnow.ResizeButton = {}
local ResizeButton = NeedToKnow.ResizeButton

function ResizeButton:OnLoad()
	self.Texture:SetVertexColor(0.6, 0.6, 0.6)
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
	-- Start sizing
	local group = self:GetParent()
	local groupID = group:GetID()
	group.oldScale = group:GetScale()
	group.oldX = group:GetLeft()
	group.oldY = group:GetTop()
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", group.oldX, group.oldY)
	self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
	self.oldWidth = _G[group:GetName().."Bar1"]:GetWidth()
	self:SetScript("OnUpdate", ResizeButton.OnUpdate)
end

function ResizeButton:OnMouseUp()
	-- Stop sizing
    self:SetScript("OnUpdate", nil)
	local group = self:GetParent()
	local groupID = group:GetID()
    NeedToKnow.ProfileSettings.Groups[groupID]["Scale"] = group:GetScale()
    NeedToKnow.SavePosition(group, groupID)
    -- BarGroup.SavePosition(group)
    -- group:SavePosition()
end

function ResizeButton:OnUpdate()
	local uiScale = UIParent:GetScale()
	local cursorX, cursorY = GetCursorPosition(UIParent)
	local group = self:GetParent()
	local groupID = group:GetID()

	-- calculate and set new scale
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.25, newYScale)
	local bar1 = _G[group:GetName().."Bar1"]
	local barHeight = bar1:GetHeight()
	local newHeight = newScale * barHeight
	newHeight = math.floor(newHeight + 0.0002)
	newScale = newHeight / barHeight  -- clamp so bars are whole number of pixels tall
	group:SetScale(newScale)

	-- set new frame coords to keep same on-screen position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)

	-- calculate & set new bar width
	local newWidth = max(50, ((cursorX - self.oldCursorX)/uiScale + self.oldWidth * group.oldScale)/newScale)
	NeedToKnow.SetWidth(groupID, newWidth)
	-- BarGroup.SetWidth(group, groupId, newWidth)
	-- group:SetWidth(newWidth)
end






