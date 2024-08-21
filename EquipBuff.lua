-- Track temporary buffs on equipped items
-- For example: Poisons and sharpening stones on weapons
-- NOT YET IMPLEMENTED

local _, NeedToKnow = ...
NeedToKnow.EquipBuffBarMixin = {}
local BarMixin = NeedToKnow.EquipBuffBarMixin

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.GetTrackedInfo = self.GetEquipBuffInfo
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:SetBarTypeSpells()
	-- Nothing to do
end

function BarMixin:RegisterBarTypeEvents()
	-- NOTE: Prolly need more events (see wiki)
	self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	-- self:RegisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	-- self:UnregisterEvent("WEAPON_ENCHANT_CHANGED")  -- Only in Retail?
end

function BarMixin:UNIT_INVENTORY_CHANGED(unit)
	self:UpdateTracking()
end

function BarMixin:WEAPON_ENCHANT_CHANGED()
	-- Only in Retail?
	self:UpdateTracking()
end

-- Kitjan's old tooltip-scanning code: 
--[[
function NeedToKnow.DetermineTempEnchantFromTooltip(i_invID)
    local tt1,tt2 = NeedToKnow.GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end
]]--

