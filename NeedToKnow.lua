local addonName, NeedToKnow = ...
NeedToKnow.version = GetAddOnMetadata(addonName, "Version")


--[[ Namespaces ]]--

NeedToKnow.String = {}  -- Localized strings
NeedToKnow.BarGroup = {}
NeedToKnow.ResizeButton = {}
NeedToKnow.Bar = {}
NeedToKnow.FindAura = {}
NeedToKnow.Cooldown = {}
NeedToKnow.BarMenu = {}
NeedToKnow.Dialog = {}
NeedToKnow.DefaultSettings = {}
NeedToKnow.ExecutiveFrame = CreateFrame("Frame", "NeedToKnow_ExecutiveFrame")

-- Kitjan's addon locals
NeedToKnow.m_last_guid = {}  -- For ExtendedTime
-- Used by Executive Frame:
NeedToKnow.m_last_cast = {}
NeedToKnow.m_last_cast_head = {}
NeedToKnow.m_last_cast_tail = {}


--[[ Load fonts, bar textures, etc (LibSharedMedia) ]]--

NeedToKnow.LSM = LibStub("LibSharedMedia-3.0", true)
local barTextures = {
	["Aluminum"]   = [[Interface\Addons\NeedToKnow\Textures\Aluminum.tga]],
	["Armory"]     = [[Interface\Addons\NeedToKnow\Textures\Armory.tga]],
	["BantoBar"]   = [[Interface\Addons\NeedToKnow\Textures\BantoBar.tga]],
	["DarkBottom"] = [[Interface\Addons\NeedToKnow\Textures\Darkbottom.tga]],
	["Default"]    = [[Interface\Addons\NeedToKnow\Textures\Default.tga]],
	["Flat"]       = [[Interface\Addons\NeedToKnow\Textures\Flat.tga]],
	["Glaze"]      = [[Interface\Addons\NeedToKnow\Textures\Glaze.tga]],
	["Gloss"]      = [[Interface\Addons\NeedToKnow\Textures\Gloss.tga]],
	["Graphite"]   = [[Interface\Addons\NeedToKnow\Textures\Graphite.tga]],
	["Minimalist"] = [[Interface\Addons\NeedToKnow\Textures\Minimalist.tga]],
	["Otravi"]     = [[Interface\Addons\NeedToKnow\Textures\Otravi.tga]],
	["Smooth"]     = [[Interface\Addons\NeedToKnow\Textures\Smooth.tga]],
	["Smooth v2"]  = [[Interface\Addons\NeedToKnow\Textures\Smoothv2.tga]],
	["Striped"]    = [[Interface\Addons\NeedToKnow\Textures\Striped.tga]]
}
for k, v in pairs(barTextures) do
	NeedToKnow.LSM:Register("statusbar", k, v) 
end


--[[ High-level functions ]]--

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


