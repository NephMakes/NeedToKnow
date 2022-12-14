﻿-- Interface options panel (Main)
-- Load after OptionsPanel.xml

local addonName, addonTable = ...
NeedToKnow.OptionsPanel = _G["InterfaceOptionsNeedToKnowPanel"]
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

local MAX_GROUPS = 4
local MAX_BARS_PER_GROUP = 9


function NeedToKnow:ShowOptionsPanel()
end

function OptionsPanel:OnLoad()
	self.groups = {}
	for groupID = 1, MAX_GROUPS do
		self.groups[groupID] = self["group"..groupID]
	end
	self:SetPanelText()
	self:SetPanelScripts()

	self.name = addonName
	self.default = NeedToKnow.ResetCharacter
	self.cancel = self.Cancel
	InterfaceOptions_AddCategory(self)
end

function OptionsPanel:SetPanelText()
	self.version:SetText("v"..NeedToKnow.version)
	self.subText1:SetText(String.OPTIONS_PANEL_SUBTEXT)
	self.numberBarsLabel:SetText(String.NUMBER_BARS)
	self.fixedDurationLabel:SetText(String.MAX_BAR_TIME)

	for groupID, group in ipairs(self.groups) do
		group.enableButton.Text:SetText(String.BAR_GROUP.." "..groupID)
		group.enableButton.tooltipText = String.ENABLE_GROUP_TOOLTIP
		group.fixedDurationBox.tooltipText = String.MAX_BAR_TIME_TOOLTIP
	end

	self.configModeButton.Text:SetText(String.EDIT_MODE)
	self.configModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
	self.playModeButton.Text:SetText(String.PLAY_MODE)
	self.playModeButton.tooltipText = String.PLAY_MODE_TOOLTIP
end

function OptionsPanel:SetPanelScripts()
	self:SetScript("OnShow", self.OnShow)

	for groupID, group in ipairs(self.groups) do
		group.enableButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.enableButton:SetScript("OnClick", self.OnGroupEnableButtonClick)
		group.numberBarsWidget.leftButton:SetScript("OnClick", self.OnNumberBarsLeftButtonClick)
		group.numberBarsWidget.rightButton:SetScript("OnClick", self.OnNumberBarsRightButtonClick)
		group.fixedDurationBox:SetScript("OnEnter", self.OnWidgetEnter)
		group.fixedDurationBox:SetScript("OnTextChanged", self.OnFixedDurationBoxTextChanged)
	end

	self.configModeButton:SetScript("OnEnter", self.OnWidgetEnter)
	self.configModeButton:SetScript("OnClick", self.OnConfigModeButtonClick)
	self.playModeButton:SetScript("OnEnter", self.OnWidgetEnter)
	self.playModeButton:SetScript("OnClick", self.OnPlayModeButtonClick)
end

function OptionsPanel:OnShow()
	self.oldProfile = NeedToKnow:GetProfileSettings()
	self.oldSettings = CopyTable(NeedToKnow:GetProfileSettings())
	self:Update()
	-- if locked then
	-- configModeButton
	-- playModeButton
end

function OptionsPanel:Update()
	-- Called by OptionsPanel:OnShow(), NeedToKnow.ChangeProfile()
	if not self:IsVisible() then return end
	for groupID, group in ipairs(self.groups) do
		self:UpdateGroupEnableButton(groupID)
		self:UpdateNumberBarsWidget(groupID)
		local groupSettings = NeedToKnow:GetGroupSettings(groupID)
		group.fixedDurationBox:SetText(groupSettings.FixedDuration or "")
    end
end

function OptionsPanel:UpdateGroupEnableButton(groupID)
	local button = self.groups[groupID].enableButton
	button:SetChecked(NeedToKnow:GetGroupSettings(groupID).Enabled)
end

function OptionsPanel:UpdateNumberBarsWidget(groupID)
	local widget = self.groups[groupID].numberBarsWidget
	local numberBars = NeedToKnow:GetGroupSettings(groupID).NumberBars
	widget.text:SetText(numberBars)
	widget.leftButton:Enable()
	widget.rightButton:Enable()
	if numberBars == 1 then
		widget.leftButton:Disable()
	elseif numberBars == MAX_BARS_PER_GROUP then
		widget.rightButton:Disable()
	end
end

function OptionsPanel:OnWidgetEnter()
	-- Called with self = widget
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
end

function OptionsPanel:OnGroupEnableButtonClick()
	-- Called with self = button
	local groupID = self:GetParent():GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	if self:GetChecked() then
		if groupID > NeedToKnow.ProfileSettings.nGroups then
			NeedToKnow.ProfileSettings.nGroups = groupID
		end
		groupSettings.Enabled = true
	else
		groupSettings.Enabled = false
	end
	NeedToKnow:Update()
end

function OptionsPanel:OnNumberBarsLeftButtonClick()
	-- Called with self = button
	OptionsPanel:AddBars(self:GetParent():GetParent():GetID(), -1)
end

function OptionsPanel:OnNumberBarsRightButtonClick()
	-- Called with self = button
	OptionsPanel:AddBars(self:GetParent():GetParent():GetID(), 1)
end

function OptionsPanel:AddBars(groupID, increment)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	local oldNumber = groupSettings.NumberBars
	if oldNumber == 1 and increment < 0 then 
		return
	elseif oldNumber == MAX_BARS_PER_GROUP and increment > 0 then
		return
	end
	groupSettings.NumberBars = oldNumber + increment
	NeedToKnow:UpdateBarGroup(groupID)
	OptionsPanel:UpdateNumberBarsWidget(groupID)
end

function OptionsPanel:OnFixedDurationBoxTextChanged()
	-- Called with self = editBox
	local text = self:GetText()
	local groupSettings = NeedToKnow:GetGroupSettings(self:GetParent():GetID())
	if text == "" then
		groupSettings.FixedDuration = nil
	else
		groupSettings.FixedDuration = tonumber(text)
	end
	NeedToKnow:Update()
end

function OptionsPanel:OnConfigModeButtonClick()
	-- Called with self = button
	NeedToKnow:Unlock()
	--	self:Disable()
	--	self:GetParent().playModeButton:Enable()
end

function OptionsPanel:OnPlayModeButtonClick()
	-- Called with self = button
	NeedToKnow:Lock()
	--	self:Disable()
	--	self:GetParent().configModeButton:Enable()
end

function OptionsPanel:Cancel()
	-- Kitjan: Can't copy the table here since ProfileSettings needs to point to the right place in
	-- NeedToKnow_Globals.Profiles or in NeedToKnow_CharSettings.Profiles
	-- Kitjan: FIXME: This is only restoring a small fraction of the total settings.
	NeedToKnow.RestoreTableFromCopy(self.oldProfile, self.oldSettings)
	-- Kitjan: FIXME: Close context menu if it's open; it may be referring to bar that doesn't exist
	NeedToKnow:Update()
end

do
	OptionsPanel:OnLoad()
end
