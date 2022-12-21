-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

-- local addonName, addonTable = ...

local String = NeedToKnow.String


--[[ Get objects ]]--

function NeedToKnow:GetBarGroup(groupID)
	return self.barGroups[groupID]
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


--[[ Get settings ]]--

function NeedToKnow:GetCharacterSettings()
	return NeedToKnow.CharSettings
	-- TO DO: Return SavedVariables object
end

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
	-- TO DO: Return SavedVariables object
end

function NeedToKnow:GetGroupSettings(groupID)
	return NeedToKnow.ProfileSettings.Groups[groupID]
end

function NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	return groupSettings.Bars[barID]
end


--[[ Update ]]--

function NeedToKnow:Update()
	if UnitExists("player") then
		for groupID, group in ipairs(NeedToKnow.barGroups) do
			group:Update()
		end
	end
end

function NeedToKnow:UpdateBarGroup(groupID)
	-- NeedToKnow:GetBarGroup(groupID):Update()
	self.barGroups[groupID]:Update()
end

function NeedToKnow:UpdateGroup(groupID)
	 NeedToKnow:UpdateBarGroup(groupID)
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	NeedToKnow:GetBar(groupID, barID):Update()
end


--[[ Lock/unlock ]]--

function NeedToKnow:Lock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	NeedToKnow:GetCharacterSettings().Locked = true
	NeedToKnow.isLocked = true
	NeedToKnow.last_cast = {}  -- Deprecated
	NeedToKnow:Update()
end

function NeedToKnow:Unlock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	NeedToKnow:GetCharacterSettings().Locked = false
	NeedToKnow.isLocked = nil
	NeedToKnow:Update()
end

function NeedToKnow:ToggleLockUnlock()
	if NeedToKnow.isLocked then
		NeedToKnow:Unlock()
	else
		NeedToKnow:Lock()
	end
end


--[[ Text ]]--

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



