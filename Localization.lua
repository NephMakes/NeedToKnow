local addonName, NephilistNameplates = ...

NephilistNameplates.Localization = {}
local Localization = NephilistNameplates.Localization

Localization["enUS"] = {
	DragToMove = "Drag to move. Right click for options.", 
	HideClassBar = "Hide secondary resource bar",
	HideClassBarTooltip = "Hide secondary combat resources like combo points",
	HideClassBarTooltip = "Lock position",
	High = "High", 
	Hidden = "Hidden", 
	LockPlayerPlate = "Lock player nameplate",
	LockPlayerPlateTooltip = "When unlocked, you can move your own nameplate",
	LockPosition = "Lock position",
	NephilistNameplates = "Nephilist Nameplates",
	OnlyShowOwnBuffs = "Only show your own buffs and debuffs",
	OnlyShowOwnBuffsTooltip = "Only show your own buffs and debuffs",
	OutOfCombatOpacity = "Visibility out of combat",
	PlayerPlate = "Player nameplate",
	ReloadAlert = "Some settings will not take effect until you reload the user interface",
	ShowBuffs = "Show buffs and debuffs",
	ShowBuffsTooltip = "Show important buffs and debuffs on nameplates",
	ShowClassResource = "Show class-specific combat resources",
	ShowClassResourceTooltip = "Show combo points, runes, holy power, etc.", 
	ShowHide = "Show/Hide", 
	ShowLevel = "Show unit level and difficulty",
	-- ShowLevelTooltip = "Show unit level and difficulty",
	ShowPlayerPlate = "Show static player nameplate",
	ShowPlayerPlateTooltip = "Show nameplate for your character that doesn't move around on screen",
	-- ShowThreat = "Show threat warning",
	-- ShowThreatTooltip = "Highlight enemies attacking you when healing or doing damage, or not attacking you when tanking", 
	ShowThreat = "Show enemy threat",
	ShowThreatTooltip = "Color enemy health by threat in your role as a tank, healer, or damage dealer",
	ShowThreatOnlyInGroup = "Only when in a group",
	ShowThreatOnlyInGroupTooltip = "Only show threat when in a group",
	Subtext = "These options let you change the appearance of unit nameplates"
}

--[[
Localization["deDE"] = {}
Localization["esES"] = {}
Localization["esMX"] = {}
Localization["frFR"] = {}
Localization["itIT"] = {}
Localization["koKR"] = {}
Localization["ptBR"] = {}
Localization["ruRU"] = {}
Localization["zhCN"] = {}
Localization["zhTW"] = {}
--]]

function NephilistNameplates:LocalizeStrings()
	NephilistNameplates.Strings = Localization[GetLocale()] or Localization["enUS"]
	NephilistNameplates:SetAllTheText()
end

function NephilistNameplates:SetAllTheText()
	local strings = NephilistNameplates.Strings
	local optionsPanel = _G["InterfaceOptionsNephilistNameplatesPanel"]
	optionsPanel.subtext:SetText(strings.Subtext)

	-- Show/Hide
	optionsPanel.showHideText:SetText(strings.ShowHide)
	optionsPanel.hideClassBarButton.Text:SetText(strings.HideClassBar)
	optionsPanel.onlyShowOwnBuffsButton.Text:SetText(strings.OnlyShowOwnBuffs)
	optionsPanel.showBuffsButton.Text:SetText(strings.ShowBuffs)
	optionsPanel.showLevelButton.Text:SetText(strings.ShowLevel)
	optionsPanel.showThreatButton.Text:SetText(strings.ShowThreat)
	optionsPanel.showThreatButton.tooltipText = strings.ShowThreatTooltip
	optionsPanel.showThreatOnlyInGroupButton.Text:SetText(strings.ShowThreatOnlyInGroupTooltip)
	optionsPanel.showThreatOnlyInGroupButton.tooltipText = strings.ShowThreatOnlyInGroupTooltip

	-- Player nameplate
	optionsPanel.playerPlateText:SetText(strings.PlayerPlate)
	optionsPanel.showPlayerPlateButton.Text:SetText(strings.ShowPlayerPlate)
	optionsPanel.showPlayerPlateButton.tooltipText = strings.ShowPlayerPlateTooltip
	optionsPanel.lockPlayerPlateButton.Text:SetText(strings.LockPlayerPlate)
	optionsPanel.lockPlayerPlateButton.tooltipText = strings.LockPlayerPlateTooltip
	optionsPanel.outOfCombatAlpha.Text:SetText(strings.OutOfCombatOpacity)
	optionsPanel.outOfCombatAlpha.High:SetText(strings.High)
	optionsPanel.outOfCombatAlpha.Low:SetText(strings.Hidden)
end


