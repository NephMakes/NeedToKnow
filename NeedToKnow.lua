-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

local addonName, addonTable = ...

local Bar = NeedToKnow.Bar


-- ---------
-- Functions
-- ---------

function NeedToKnow:Update()
	if ( UnitExists("player") and NeedToKnow.ProfileSettings ) then
		for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
			local group = _G["NeedToKnow_Group"..groupID]
			group:Update()
		end
	end
end

function NeedToKnow.Show(bShow)
	NeedToKnow.IsVisible = bShow
	for groupID = 1, NeedToKnow.ProfileSettings.nGroups do
		local groupName = "NeedToKnow_Group"..groupID
		local group = _G[groupName]
		local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
	
		if ( NeedToKnow.IsVisible and groupSettings.Enabled ) then
			group:Show()
		else
			group:Hide()
		end
	end
end

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
end

function NeedToKnow:GetBarGroup(groupID)
	return _G["NeedToKnow_Group"..groupID]
end

function NeedToKnow:GetGroupSettings(groupID)
	return NeedToKnow.ProfileSettings.Groups[groupID]
end

function NeedToKnow:GetBar(groupID, barID)
	return _G["NeedToKnow_Group"..groupID.."Bar"..barID]
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	local bar = NeedToKnow:GetBar(groupID, barID)
	bar:Update()
end

function NeedToKnow.Fmt_SingleUnit(i_fSeconds)
    return string.format(SecondsToTimeAbbrev(i_fSeconds))
end

function NeedToKnow.Fmt_TwoUnits(i_fSeconds)
	if ( i_fSeconds < 6040 ) then
		local nMinutes, nSeconds
		nMinutes = floor(i_fSeconds / 60)
		nSeconds = floor(i_fSeconds - nMinutes*60)
		return string.format("%02d:%02d", nMinutes, nSeconds)
	else
		string.format(SecondsToTimeAbbrev(i_fSeconds))
	end
end

function NeedToKnow.Fmt_Float(i_fSeconds)
	return string.format("%0.1f", i_fSeconds)
end




