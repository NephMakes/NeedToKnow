-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

-- local addonName, addonTable = ...



--[[ Functions ]]--

function NeedToKnow:Update()
	if UnitExists("player") and NeedToKnow.ProfileSettings then
		for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
			NeedToKnow:GetBarGroup(groupID):Update()
		end
	end
end

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

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
end

function NeedToKnow:GetBarGroup(groupID)
	return _G["NeedToKnow_Group"..groupID]
end

function NeedToKnow:GetGroup(groupID)
	return NeedToKnow:GetBarGroup(groupID)
end

function NeedToKnow:GetBar(groupID, barID)
	return _G["NeedToKnow_Group"..groupID.."Bar"..barID]
end

function NeedToKnow:GetGroupSettings(groupID)
	return NeedToKnow.ProfileSettings.Groups[groupID]
end

function NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	return groupSettings.Bars[barID]
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	local bar = NeedToKnow:GetBar(groupID, barID)
	bar:Update()
end



