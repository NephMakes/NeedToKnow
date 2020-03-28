-- This file contains (or at least will contain) the code for 
-- the timer bars themselves

local addonName, addonTable = ...

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

    local resizeButton = _G[groupName.."ResizeButton"]
    resizeButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -8)

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

    if ( NeedToKnow.CharSettings["Locked"] ) then
        resizeButton:Hide()
    else
        resizeButton:Show()
    end

    -- Early enough in the loading process (before PLAYER_LOGIN), we might not
    -- know the position yet
    if groupSettings.Position then
        group:ClearAllPoints()
        local point, relativePoint, xOfs, yOfs = unpack(groupSettings.Position)
        group:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        group:SetScale(groupSettings.Scale)
    end
    
    if ( NeedToKnow_Visible and groupSettings.Enabled ) then
        group:Show()
    else
        group:Hide()
    end
end

