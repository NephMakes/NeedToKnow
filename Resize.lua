-- Change height and width of timer bars

-- local addonName, addonTable = ...

NeedToKnow.ResizeButton = {}
local ResizeButton = NeedToKnow.ResizeButton

function NeedToKnow.Resizebutton_OnEnter(self)
	-- self is Resize button
    local tooltip = _G["GameTooltip"];
    GameTooltip_SetDefaultAnchor(tooltip, self);
    tooltip:AddLine(NEEDTOKNOW.RESIZE_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
    tooltip:Show();
end

function NeedToKnow.StartSizing(self, button)
	-- self is Resize button
    local group = self:GetParent();
    local groupID = self:GetParent():GetID();
    group.oldScale = group:GetScale();
    group.oldX = group:GetLeft();
    group.oldY = group:GetTop();
		group:ClearAllPoints();
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", group.oldX, group.oldY);
    self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent);
    self.oldWidth = _G[group:GetName().."Bar1"]:GetWidth();
    self:SetScript("OnUpdate", NeedToKnow.Sizing_OnUpdate);
end

function NeedToKnow.Sizing_OnUpdate(self)
	-- self is Resize button
    local uiScale = UIParent:GetScale();
    local cursorX, cursorY = GetCursorPosition(UIParent);
    local group = self:GetParent();
    local groupID = self:GetParent():GetID();

    -- calculate & set new scale
    local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale) ;
    local newScale = max(0.25, newYScale);
    
    -- clamp the scale so bars are whole number of pixels tall
    local bar1 = _G[group:GetName().."Bar1"]
    local barHeight = bar1:GetHeight()
    local newHeight = newScale * barHeight
    newHeight = math.floor(newHeight + 0.0002)
    newScale = newHeight / barHeight
    group:SetScale(newScale);

    -- set new frame coords to keep same on-screen position
    local newX = group.oldX * group.oldScale / newScale;
    local newY = group.oldY * group.oldScale / newScale;
    group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY);

    -- calculate & set new bar width
    local newWidth = max(50, ((cursorX - self.oldCursorX)/uiScale + self.oldWidth * group.oldScale)/newScale);
    NeedToKnow.SetWidth(groupID, newWidth);
end

function NeedToKnow.StopSizing(self, button)
	-- self is Resize button
    self:SetScript("OnUpdate", nil)
    local groupID = self:GetParent():GetID();
    NeedToKnow.ProfileSettings.Groups[groupID]["Scale"] = self:GetParent():GetScale();
    NeedToKnow.SavePosition(self:GetParent(), groupID);
end



-- TO DO: Move this to BarConfig.lua or equivalent
-- TO DO: Should be something like BarGroup:SetWidth()
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

-- TO DO: Move this to BarConfig.lua or equivalent
-- TO DO: Should be something like BarGroup:SavePosition()
function NeedToKnow.SavePosition(group, groupID)
    groupID = groupID or group:GetID();
    local point, _, relativePoint, xOfs, yOfs = group:GetPoint();
    NeedToKnow.ProfileSettings.Groups[groupID]["Position"] = {point, relativePoint, xOfs, yOfs};
end
