-- Load after libs and before everything else

local addonName, NeedToKnow = ...
NeedToKnow.version = GetAddOnMetadata(addonName, "Version")

-- Namespaces
NeedToKnow.ExecutiveFrame = CreateFrame("Frame", "NeedToKnow_ExecutiveFrame")
NeedToKnow.BarGroup = {}
NeedToKnow.ResizeButton = {}
NeedToKnow.Bar = {}
NeedToKnow.FindAura = {}
NeedToKnow.Cooldown = {}
NeedToKnow.BarMenu = {}
NeedToKnow.Dialog = {}
NeedToKnow.DefaultSettings = {}

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



