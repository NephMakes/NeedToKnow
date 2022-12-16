-- Interface options panel (Main)
-- Load after OptionsPanel.xml

local addonName, addonTable = ...
NeedToKnow.OptionsPanel = _G["InterfaceOptionsNeedToKnowPanel"]
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

local MAX_GROUPS = 4
local MAX_BARS_PER_GROUP = 9


function NeedToKnow:ShowOptionsPanel()
end


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
	self.version:SetText("v"..NeedToKnow.version)
	self.subText1:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.numberBarsLabel:SetText(String.NUMBER_BARS)
	self.directionLabel:SetText("Group direction")
	self.fixedDurationLabel:SetText(String.MAX_BAR_TIME)

	for groupID, group in ipairs(self.groups) do
		group.enableButton.Text:SetText(String.BAR_GROUP.." "..groupID)
		group.enableButton.tooltipText = String.ENABLE_GROUP_TOOLTIP
		group.directionWidget.upButton.tooltipText = "Group grows up"
		group.directionWidget.downButton.tooltipText = "Group grows down"
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

		group.directionWidget.upButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.directionWidget.upButton:SetScript("OnClick", self.OnDirectionUpClick)
		group.directionWidget.downButton:SetScript("OnEnter", self.OnWidgetEnter)
		group.directionWidget.downButton:SetScript("OnClick", self.OnDirectionDownClick)

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
end

function OptionsPanel:Update()
	-- Called by OptionsPanel:OnShow(), NeedToKnow.ChangeProfile()
	if not self:IsVisible() then return end
	for groupID, group in ipairs(self.groups) do
		local groupSettings = NeedToKnow:GetGroupSettings(groupID)
		self:UpdateGroupEnableButton(groupID)
		self:UpdateNumberBarsWidget(groupID)
		self:UpdateDirectionWidget(groupID, groupSettings)
		group.fixedDurationBox:SetText(groupSettings.FixedDuration or "")
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

function OptionsPanel:UpdateEditPlayModeButtons()
	local playModeButton = self.playModeButton
	local configModeButton = self.configModeButton
	if NeedToKnow.isLocked then
		configModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		configModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		configModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
	else
		configModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		configModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		configModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		playModeButton.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		playModeButton.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
	end
end

function OptionsPanel:Cancel()
	-- Kitjan: Can't copy the table here since ProfileSettings needs to point to the right place in
	-- NeedToKnow_Globals.Profiles or in NeedToKnow_CharSettings.Profiles
	-- Kitjan: FIXME: This is only restoring a small fraction of the total settings.
	NeedToKnow.RestoreTableFromCopy(self.oldProfile, self.oldSettings)
	-- Kitjan: FIXME: Close context menu if it's open; it may be referring to bar that doesn't exist
	NeedToKnow:Update()
end


--[[ Enable group button ]]--

function OptionsPanel:UpdateGroupEnableButton(groupID)
	local button = self.groups[groupID].enableButton
	button:SetChecked(NeedToKnow:GetGroupSettings(groupID).Enabled)
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
	local upButton = widget.upButton
	local downButton = widget.downButton
	if groupSettings.direction == "up" then
		-- upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
		-- downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
		upButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Up")
		downButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Disabled")
	else
		-- upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled")
		-- downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
		upButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Disabled")
		downButton:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Up")
	end
end

function OptionsPanel:OnDirectionUpClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetParent():GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	groupSettings.direction = "up"
	NeedToKnow:UpdateBarGroup(groupID)
	OptionsPanel:UpdateDirectionWidget(groupID, groupSettings)
end

function OptionsPanel:OnDirectionDownClick()
	-- Called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local groupID = self:GetParent():GetParent():GetID()
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	groupSettings.direction = "down"
	NeedToKnow:UpdateBarGroup(groupID)
	OptionsPanel:UpdateDirectionWidget(groupID, groupSettings)
end


--[[ Fixed duration box ]]--

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


do
	OptionsPanel:OnLoad()
end
