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
	-- TO DO: Return SavedVariables object?
end

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
	-- TO DO: Return SavedVariables object?
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


--[[ ]]--

function NeedToKnow.GetSpecIndex()
	-- Return index of player's current specialization
	if  WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		return GetSpecialization()
	elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
		return GetActiveTalentGroup()
	else  -- Classic Era
		return 1
	end
end


--[[ Table handling functions ]]--

function NeedToKnow.DeepCopy(object)
	-- Called by NeedToKnow.AddDefaultsToTable()
	if type(object) ~= "table" then
		return object
	else
		local new_table = {}
		for k, v in pairs(object) do
			new_table[k] = NeedToKnow.DeepCopy(v)
		end
		return new_table
	end
end

function NeedToKnow.RestoreTableFromCopy(dest, source)
	-- Called by OptionsPanel:Cancel()
	for key, value in pairs(source) do
		if type(value) == "table" then
			if dest[key] then
				NeedToKnow.RestoreTableFromCopy(dest[key], value)
			else
				dest[key] = value
			end
		else
			dest[key] = value
		end
	end
	for key, value in pairs(dest) do
		if source[key] == nil then
			dest[key] = nil
		end
	end
end

---- Copies anything (int, table, whatever).  Unlike DeepCopy (and CopyTable), CopyRefGraph can 
---- recreate a recursive reference structure (CopyTable will stack overflow.)
---- Copied from http://lua-users.org/wiki/CopyTable
--[[
function NeedToKnow.CopyRefGraph(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
]]--


