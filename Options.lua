local addonName, NephilistNameplates = ...

local DriverFrame = NephilistNameplates.DriverFrame
local PlayerPlate = NephilistNameplates.PlayerPlate


--[[ Default settings ]]-- 

NephilistNameplates.Defaults = {
	ColorRareNames = true, 
	HideClassBar = false, 
	ShowBuffs = true, 
	ShowEliteIcon = true, 
	ShowLevel = true, 
	ShowPlayerPlate = false, 
	ShowThreat = false, 
	ShowThreatOnlyInGroup = false, 
	PlayerPlateLocked = true, 
	PlayerPlateOutOfCombatAlpha = 0.2, 
	PlayerPlatePosition = {"TOP", UIParent, "CENTER", 0, -150}, 
	OnlyShowOwnBuffs = true, 
	Version = GetAddOnMetadata(addonName, "Version")
}


--[[ Interface options panel ]]-- 

NephilistNameplates.OptionsPanel = NephilistNameplates:CreateOptionsPanel()

local optionsPanel = NephilistNameplates.OptionsPanel
optionsPanel.savedVariablesName = "NephilistNameplatesOptions"
optionsPanel.defaults = NephilistNameplates.Defaults
optionsPanel.defaultsFunc = NephilistNameplates.Update
optionsPanel.okayFunc = NephilistNameplates.Update

-- Show/Hide

optionsPanel.showHideText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
optionsPanel.showHideText:SetPoint("TOPLEFT", optionsPanel.subtext, "BOTTOMLEFT", 2, -34)

optionsPanel.showLevelButton = optionsPanel:CreateCheckButton("ShowLevel")
local showLevelButton = optionsPanel.showLevelButton
showLevelButton:SetPoint("TOPLEFT", optionsPanel.showHideText, "BOTTOMLEFT", 0, -8)
showLevelButton.onValueChanged = NephilistNameplates.Update

optionsPanel.showBuffsButton = optionsPanel:CreateCheckButton("ShowBuffs")
local showBuffsButton = optionsPanel.showBuffsButton
showBuffsButton:SetPoint("TOPLEFT", showLevelButton, "BOTTOMLEFT", 0, -8)
-- showBuffsButton.onValueChanged = function() end

optionsPanel.onlyShowOwnBuffsButton = optionsPanel:CreateCheckButton("OnlyShowOwnBuffs")
local onlyShowOwnBuffsButton = optionsPanel.onlyShowOwnBuffsButton
onlyShowOwnBuffsButton:SetPoint("TOPLEFT", optionsPanel.showBuffsButton, "BOTTOMLEFT", 0, -8)
-- onlyShowOwnBuffsButton.onValueChanged = function() end

optionsPanel.hideClassBarButton = optionsPanel:CreateCheckButton("HideClassBar")
local hideClassBarButton = optionsPanel.hideClassBarButton
hideClassBarButton:SetPoint("TOPLEFT", optionsPanel.onlyShowOwnBuffsButton, "BOTTOMLEFT", 0, -8)
-- hideClassBarButton.onValueChanged = function() end

local showThreatButton = optionsPanel:CreateCheckButton("ShowThreat")
optionsPanel.showThreatButton = showThreatButton
showThreatButton:SetPoint("LEFT", optionsPanel.showLevelButton, 280, 0)
showThreatButton.onValueChanged = NephilistNameplates.Update

local showThreatOnlyInGroupButton = optionsPanel:CreateCheckButton("ShowThreatOnlyInGroup")
optionsPanel.showThreatOnlyInGroupButton = showThreatOnlyInGroupButton
showThreatOnlyInGroupButton:SetPoint("TOPLEFT", optionsPanel.showThreatButton, "BOTTOMLEFT", 0, -8)
showThreatOnlyInGroupButton.onValueChanged = NephilistNameplates.Update


-- Player nameplate

optionsPanel.playerPlateText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
optionsPanel.playerPlateText:SetPoint("TOPLEFT", optionsPanel.hideClassBarButton, "BOTTOMLEFT", 0, -30)

optionsPanel.showPlayerPlateButton = optionsPanel:CreateCheckButton("ShowPlayerPlate")
local showPlayerPlateButton = optionsPanel.showPlayerPlateButton
showPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.playerPlateText, "BOTTOMLEFT", 0, -8)
showPlayerPlateButton.onValueChanged = PlayerPlate.Update

local lockPlayerPlateButton = optionsPanel:CreateCheckButton("PlayerPlateLocked")
optionsPanel.lockPlayerPlateButton = lockPlayerPlateButton
lockPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.showPlayerPlateButton, "BOTTOMLEFT", 0, -8)
lockPlayerPlateButton.onValueChanged = PlayerPlate.Update

local outOfCombatAlpha = optionsPanel:CreateSlider("PlayerPlateOutOfCombatAlpha")
optionsPanel.outOfCombatAlpha = outOfCombatAlpha
outOfCombatAlpha:SetPoint("TOPLEFT", optionsPanel.lockPlayerPlateButton, "BOTTOMLEFT", 24, -26)
outOfCombatAlpha:SetMinMaxValues(0, 1)
outOfCombatAlpha:SetValueStep(0.05)
outOfCombatAlpha:SetObeyStepOnDrag(true)
outOfCombatAlpha.onValueChanged = PlayerPlate.Update



