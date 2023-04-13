-- --------------------------------------
-- NeedToKnow
-- by NephMakes (aka lieandswell), Kitjan
-- --------------------------------------

local _, NeedToKnow = ...
local String = NeedToKnow.String


function NeedToKnow:Update()
	self:UpdateBarGroups()
	-- TO DO: Update options panels
end

function NeedToKnow:Lock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	self.isLocked = true
	self.characterSettings.Locked = true
	self.last_cast = {}  -- Deprecated
	self:Update()
end

function NeedToKnow:Unlock()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	self.isLocked = nil
	self.characterSettings.Locked = false
	self:Update()
end

function NeedToKnow:ToggleLockUnlock()
	if self.isLocked then
		self:Unlock()
	else
		self:Lock()
	end
end

function NeedToKnow.GetSpecIndex()
	-- Return index of player's current specialization
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then  -- Retail
		return GetSpecialization()
	elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then  -- Classic Wrath
		return GetActiveTalentGroup()
	else  -- Classic Era
		return 1
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


