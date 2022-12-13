-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

-- local addonName, addonTable = ...

local String = NeedToKnow.String


-- Get objects

function NeedToKnow:GetBarGroup(groupID)
	return _G["NeedToKnow_Group"..groupID]
end

function NeedToKnow:GetGroup(groupID)
	return NeedToKnow:GetBarGroup(groupID)
end

function NeedToKnow:GetBar(groupID, barID)
	return _G["NeedToKnow_Group"..groupID.."Bar"..barID]
end

function NeedToKnow:GetOptionsPanel()
	return _G["InterfaceOptionsNeedToKnowPanel"]
end


-- Get settings

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
end

function NeedToKnow:GetGroupSettings(groupID)
	return NeedToKnow.ProfileSettings.Groups[groupID]
end

function NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	return groupSettings.Bars[barID]
end


-- Update

function NeedToKnow:Update()
	if UnitExists("player") then
		for groupID = 1, NeedToKnow.MAX_BARGROUPS do
			NeedToKnow:UpdateBarGroup(groupID)
		end
		--[[
		for groupID, group in ipairs(self.barGroups) do
			group:Update()
		end
		]]--
	end
end

function NeedToKnow:UpdateBarGroup(groupID)
	NeedToKnow:GetBarGroup(groupID):Update()
end

function NeedToKnow:UpdateGroup(groupID)
	 NeedToKnow:UpdateBarGroup(groupID)
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	NeedToKnow:GetBar(groupID, barID):Update()
end


-- Lock/unlock

function NeedToKnow.Show(showAddon)
	for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
		local group = NeedToKnow:GetBarGroup(groupID)
		local groupSettings = NeedToKnow:GetGroupSettings(groupID)
		if showAddon and groupSettings.Enabled then
			group:Show()
		else
			group:Hide()
		end
	end
	NeedToKnow.IsVisible = showAddon
end


-- Text

function NeedToKnow:GetPrettyName(barSettings)
	-- Called by Bar:SetUnlockedText() and BarMenu_Initialize (indirectly)
	if barSettings.BuffOrDebuff == "EQUIPSLOT" then
		local index = tonumber(barSettings.AuraName)
		if index then 
			return String.ITEM_NAMES[index] 
		else 
			return ""
		end
	else
		return barSettings.AuraName
	end
end



