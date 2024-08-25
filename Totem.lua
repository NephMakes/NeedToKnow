-- Track totems

local _, NeedToKnow = ...
NeedToKnow.TotemBarMixin = {}
local BarMixin = NeedToKnow.TotemBarMixin

local GetTotemInfo = GetTotemInfo
local GetSpellInfo = GetSpellInfo

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	-- Functions where Classic and Retail versions have different return structure
	GetSpellInfo = function(spell) 
		local info = C_Spell.GetSpellInfo(spell)
		if info then
			return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
	end
end


--[[ BarMixin ]]--

function BarMixin:SetBarTypeInfo()
	-- Called by Bar:SetBarType
	self.settings.Unit = "player"
	self.checkOnNoTimeLeft = nil  -- For Bar:OnUpdate
end

function BarMixin:SetBarTypeSpells()
	-- Nothing to do
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
end

function BarMixin:PLAYER_TOTEM_UPDATE(totemSlot)
	self:UpdateTracking()
end

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get totem info
	local spellName = spellEntry.name or GetSpellInfo(spellEntry.id)
	for index = 1, 4 do
		local _, name, startTime, duration, iconID = GetTotemInfo(index)  
		if name and name:find(spellName) then
			return {
				name = name, 
				iconID = iconID, 
				count = 1, 
				duration = duration, 
				expirationTime = startTime + duration, 
				-- extraValues = nil, 
				shownName = spellEntry.shownName, 
				stacks = 1, 
			}
		end
	end
end

