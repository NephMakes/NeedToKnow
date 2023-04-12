-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

local _, NeedToKnow = ...
local String = NeedToKnow.String


--[[ Bar ]]--

function NeedToKnow:GetBar(groupID, barID)
	return _G["NeedToKnow_Group"..groupID.."Bar"..barID]
end

function NeedToKnow:UpdateBar(groupID, barID)
	-- Called by BarMenu functions
	NeedToKnow:GetBar(groupID, barID):Update()
end


--[[ Update ]]--

function NeedToKnow:Update()
	self:UpdateBarGroups()
	-- TO DO: Update options panels
end


--[[ Lock/unlock ]]--

function NeedToKnow:Lock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	-- NeedToKnow:GetCharacterSettings().Locked = true
	self.characterSettings.Locked = true
	NeedToKnow.isLocked = true
	NeedToKnow.last_cast = {}  -- Deprecated
	NeedToKnow:Update()
	-- self:UpdateBarGroups()
end

function NeedToKnow:Unlock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	-- NeedToKnow:GetCharacterSettings().Locked = false
	self.characterSettings.Locked = false
	NeedToKnow.isLocked = nil
	NeedToKnow:Update()
	-- self:UpdateBarGroups()
end

function NeedToKnow:ToggleLockUnlock()
	if self.isLocked then
		self:Unlock()
	else
		self:Lock()
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
	if type(object) ~= "table" then
		return object
	else
		local newTable = {}
		for k, v in pairs(object) do
			newTable[k] = NeedToKnow.DeepCopy(v)
		end
		return newTable
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


