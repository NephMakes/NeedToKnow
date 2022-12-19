-- Interface options panel (Main)
-- Load after OptionsPanel.xml

local addonName, addonTable = ...
NeedToKnow.OptionsPanel = _G["InterfaceOptionsNeedToKnowPanel"]
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

local MAX_GROUPS = 4
local MAX_BARS_PER_GROUP = 9


-- function NeedToKnow:ShowOptionsPanel() end


--[[ Options panel ]]--

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
	self.title:SetText(addonName.." v"..NeedToKnow.version)
	-- self.version:SetText("v"..NeedToKnow.version)
	self.subText1:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.numberBarsLabel:SetText(String.NUMBER_BARS)
	self.directionLabel:SetText(String.GROUP_DIRECTION)
	self.condenseGroupLabel:SetText(String.CONDENSE_GROUP)
	self.fixedDurationLabel:SetText(String.MAX_BAR_TIME)

	for groupID, group in ipairs(self.groups) do
		group.enableButton.Text:SetText(String.BAR_GROUP.." "..groupID)
		group.enableButton.tooltipText = String.ENABLE_GROUP_TOOLTIP
		group.directionWidget.upButton.tooltipText = String.GROUP_GROWS_UP
		group.directionWidget.downButton.tooltipText = String.GROUP_GROWS_DOWN
		group.condenseGroupButton.tooltipText = String.MOVE_BARS
		group.fixedDurationBox.tooltipText = String.MAX_BAR_TIME_TOOLTIP
	end

	self.editModeButton.Text:SetText(String.EDIT_MODE)
	self.editModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
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
		group.directionWidget.upButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.directionWidget.upButton:SetScript("OnClick", self.OnDirectionUpClick)
		group.directionWidget.downButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.directionWidget.downButton:SetScript("OnClick", self.OnDirectionDownClick)
		group.condenseGroupButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.condenseGroupButton:SetScript("OnClick", self.OnCondenseGroupButtonClick)
		group.fixedDurationBox:SetScript("OnEnter", self.OnWidgetEnter)
		group.fixedDurationBox:SetScript("OnTextChanged", self.OnFixedDurationBoxTextChanged)
	end

	self.editModeButton:SetScript("OnEnter", self.OnWidgetEnter)
	self.editModeButton:SetScript("OnClick", self.OnConfigModeButtonClick)
	self.playModeButton:SetScript("OnEnter", self.OnWidgetEnter)
	self.playModeButton:SetScript("OnClick", self.OnPlayModeButtonClick)
end

function OptionsPanel:OnShow()
	self.oldProfile = NeedToKnow:GetProfileSettings()
	self.oldSettings = CopyTable(NeedToKnow:GetProfileSettings())
	self:Update()
end

function OptionsPanel:Update()
	-- Called by OptionsPanel:OnShow(), NeedToKnow.ChangeProfile()
	if not self:IsVisible() then return end
	for groupID, group in ipairs(self.groups) do
		local groupSettings = NeedToKnow:GetGroupSettings(groupID)
		self:UpdateGroupEnableButton(groupID, groupSettings)
		self:UpdateNumberBarsWidget(groupID, groupSettings)
		self:UpdateDirectionWidget(groupID, groupSettings)
		self:UpdateCondenseGroupButton(groupID, groupSettings)
		self:UpdateFixedDurationBox(groupID, groupSettings)
	end
	-- self:UpdateEditPlayModeButtons()
end

function OptionsPanel:OnWidgetEnter()
	-- Called with self = widget
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
end

function OptionsPanel:OnConfigModeButtonClick()
	-- Called with self = button
	NeedToKnow:Unlock()
	-- OptionsPanel:UpdateEditPlayModeButtons()
end

function OptionsPanel:OnPlayModeButtonClick()
	-- Called with self = button
	NeedToKnow:Lock()
	-- OptionsPanel:UpdateEditPlayModeButtons()
end

--[[
function OptionsPanel:UpdateEditPlayModeButtons()
	local playModeButton = self.playModeButton
	local editModeButton = self.editModeButton
	if NeedToKnow.isLocked then
		editModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		editModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		editModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
	else
		editModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		editModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		editModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
	end
end
]]--

function OptionsPanel:Cancel()
	-- Kitjan: Can't copy the table here since ProfileSettings needs to point to the right place in
	-- NeedToKnow_Globals.Profiles or in NeedToKnow_CharSettings.Profiles
	-- Kitjan: FIXME: This is only restoring a small fraction of the total settings.
	NeedToKnow.RestoreTableFromCopy(self.oldProfile, self.oldSettings)
	-- Kitjan: FIXME: Close context menu if it's open; it may be referring to bar that doesn't exist
	NeedToKnow:Update()
end


--[[ Enable group button ]]--

function OptionsPanel:UpdateGroupEnableButton(groupID, groupSettings)
	local button = self.groups[groupID].enableButton
	button:SetChecked(groupSettings.Enabled)
end

function OptionsPanel:OnGroupEnableButtonClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	if self:GetChecked() then
		groupSettings.Enabled = true
	else
		groupSettings.Enabled = false
	end
	NeedToKnow:UpdateBarGroup(groupID)
end


--[[ Number bars widget ]]--

function OptionsPanel:UpdateNumberBarsWidget(groupID, groupSettings)
	local widget = self.groups[groupID].numberBarsWidget
	local numberBars = groupSettings.NumberBars
	widget.text:SetText(numberBars)
	widget.leftButton:Enable()
	widget.rightButton:Enable()
	if numberBars == 1 then
		widget.leftButton:Disable()
	elseif numberBars == MAX_BARS_PER_GROUP then
		widget.rightButton:Disable()
	end
end

function OptionsPanel:OnNumberBarsLeftButtonClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	OptionsPanel:AddBars(self:GetParent():GetParent():GetID(), -1)
end

function OptionsPanel:OnNumberBarsRightButtonClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
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


--[[ Group direction widget ]]--

function OptionsPanel:UpdateDirectionWidget(groupID, groupSettings)
	local widget = self.groups[groupID].directionWidget
	if groupSettings.direction == "up" then
		widget.upButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Up")
		widget.downButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Disabled")
	else
		widget.upButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Disabled")
		widget.downButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Up")
	end
end

function OptionsPanel:OnDirectionUpClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetParent():GetID()
	local settings = NeedToKnow:GetGroupSettings(groupID)
	settings.direction = "up"
	NeedToKnow:UpdateBarGroup(groupID)
	OptionsPanel:UpdateDirectionWidget(groupID, settings)
end

function OptionsPanel:OnDirectionDownClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetParent():GetID()
	local settings = NeedToKnow:GetGroupSettings(groupID)
	settings.direction = "down"
	NeedToKnow:UpdateBarGroup(groupID)
	OptionsPanel:UpdateDirectionWidget(groupID, settings)
end


--[[ Condense group button ]]--

function OptionsPanel:UpdateCondenseGroupButton(groupID, groupSettings)
	local button = self.groups[groupID].condenseGroupButton
	local value = groupSettings.condenseGroup
	button:SetChecked(value)
end

function OptionsPanel:OnCondenseGroupButtonClick()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetID()
	local settings = NeedToKnow:GetGroupSettings(groupID)
	if self:GetChecked() then
		settings.condenseGroup = true
	else
		settings.condenseGroup = false
	end
	NeedToKnow:UpdateBarGroup(groupID)
end


--[[ Fixed duration box ]]--

function OptionsPanel:UpdateFixedDurationBox(groupID, groupSettings)
	local editBox = self.groups[groupID].fixedDurationBox
	local value = groupSettings.FixedDuration
	if value and tonumber(value) > 0 then
		editBox:SetText(value)
	else
		editBox:SetText("")
	end
end

function OptionsPanel:OnFixedDurationBoxTextChanged()
	-- Called with self = editBox
	local text = self:GetText()
	local groupID = self:GetParent():GetID()
	local settings = NeedToKnow:GetGroupSettings(groupID)
	if text == "" then
		settings.FixedDuration = nil
	else
		settings.FixedDuration = tonumber(text)
	end
	NeedToKnow:UpdateBarGroup(groupID)
end


do
	OptionsPanel:OnLoad()
end
