-- Interface options panel: Profile
-- Load after ProfilePanel.xml

-- local addonName, addonTable = ...
NeedToKnow.ProfilePanel = InterfaceOptionsNeedToKnowProfilePanel
local ProfilePanel = NeedToKnow.ProfilePanel
local String = NeedToKnow.String

function ProfilePanel:OnLoad()
	self:SetScripts()
	self:SetText()

	-- Register with Blizz Interface Options panel
	self.name = String.PROFILES
	self.parent = "NeedToKnow"
	self.default = ProfilePanel.OnClickDefaultsButton
	-- self.cancel = NeedToKnow.Cancel
	-- Need different way to handle cancel?  Might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function ProfilePanel:SetScripts()
	self:SetScript("OnShow", self.OnShow)
	self.profileScrollFrame:SetScript("OnSizeChanged", self.OnScrollFrameSizeChanged)
	self.profileScrollFrame.update = ProfilePanel.UpdateProfileScrollFrame
	self.activateButton:SetScript("OnClick", self.OnClickActivateButton)
	self.renameButton:SetScript("OnClick", self.OnClickRenameButton)
	self.deleteButton:SetScript("OnClick", self.OnClickDeleteButton)
	self.copyButton:SetScript("OnClick", self.OnClickCopyButton)
	self.toAccountButton:SetScript("OnClick", self.OnClickToAccountButton)
	self.toCharacterButton:SetScript("OnClick", self.OnClickToCharacterButton)
end

function ProfilePanel:SetText()
	self.title:SetText("NeedToKnow v"..NeedToKnow.version)
	self.subText:SetText(String.PROFILE_PANEL_SUBTEXT)
	self.profileScrollFrame.label:SetText(String.PROFILES)
	self.profileScrollFrame.nameLabel:SetText(String.PROFILE_NAME)
	self.profileScrollFrame.typeLabel:SetText(String.USABLE_BY)
	self.activateButton.Text:SetText(String.ACTIVATE)
	self.activateButton.tooltipText = String.ACTIVATE_TOOLTIP
	self.renameButton.Text:SetText(String.RENAME)
	self.renameButton.tooltipText = String.RENAME_TOOLTIP
	self.deleteButton.Text:SetText(String.DELETE)
	self.deleteButton.tooltipText = String.DELETE_TOOLTIP
	self.copyButton.Text:SetText(String.COPY)
	self.copyButton.tooltipText = String.COPY_TOOLTIP
	self.toAccountButton.Text:SetText(String.TO_ACCOUNT)
	self.toAccountButton.tooltipText = String.TO_ACCOUNT_TOOLTIP
	self.toCharacterButton.Text:SetText(String.TO_CHARACTER)
	self.toCharacterButton.tooltipText = String.TO_CHARACTER_TOOLTIP
end

function ProfilePanel:OnShow()
	self:UpdateProfileList()
	self:Update()
end

function ProfilePanel:UpdateProfileList()
	local oldKey
	if self.selectedProfileName and self.profileMap then
		oldKey = self.profileMap[self.selectedProfileName].key
	end

	self.profileMap = {}
	self.profileNames = self.profileNames or {}
	local profileNames = self.profileNames
	local i = 0
	if NeedToKnow.profiles then
		for profileKey, profile in pairs(NeedToKnow.profiles) do
			i = i + 1
			local name, profileType
			if NeedToKnow.accountSettings.Profiles[profileKey] == profile then
				name = profile.name
				profileType = "account"
			else
				name = profile.name
				profileType = "character"
			end
			profileNames[i] = name
			self.profileMap[name] = {key = profileKey, ref = profile, profileType = profileType}
			if profileKey == oldKey then
				self.selectedProfileName = name
			end
		end
	end
	while i < #profileNames do
		table.remove(profileNames)
	end
	table.sort(profileNames, function(lhs, rhs) return string.upper(lhs) < string.upper(rhs) end)

	self:Update()
end

function ProfilePanel:Update()
	if not self:IsVisible() then return end
	if self.profileMap then
		-- Get active profile name
		local profileKey = NeedToKnow.GetActiveProfile()
		self.activeProfileName = NeedToKnow.profiles[profileKey].name

		-- Select active profile by default
		if not self.selectedProfileName or not self.profileMap[self.selectedProfileName] then
			self.selectedProfileName = self.activeProfileName
		end

		self:UpdateProfileScrollFrame()
		self:UpdateButtons()
	end
end


--[[ Profile scroll frame ]]--

function ProfilePanel.OnScrollFrameSizeChanged(scrollFrame)
	HybridScrollFrame_CreateButtons(scrollFrame, "NeedToKnowProfileButtonTemplate")
	for _, button in pairs(scrollFrame.buttons) do
		button:SetScript("OnClick", ProfilePanel.OnClickProfileButton)
	end
	local old_value = scrollFrame.scrollBar:GetValue()
	local max_value = scrollFrame.range or scrollFrame:GetHeight()
	scrollFrame.scrollBar:SetValue(min(old_value, max_value))
end

function ProfilePanel:UpdateProfileScrollFrame()
	local self = ProfilePanel
	local scrollFrame = self.profileScrollFrame
	local buttons = scrollFrame.buttons
	local profileNames = self.profileNames

	HybridScrollFrame_Update(scrollFrame, #profileNames * buttons[1]:GetHeight(), scrollFrame:GetHeight())

	-- Update profile buttons
	local name
	for i, button in ipairs(buttons) do
		name = profileNames[i + HybridScrollFrame_GetOffset(scrollFrame)]
		if name then
			button:Show()
			button.nameText:SetText(name)

			local profileType = self.profileMap[name].profileType
			if profileType == "account" then
				button.typeText:SetText(String.ACCOUNT)
			elseif profileType == "character" then
				button.typeText:SetText(String.CHARACTER)
			end

			if name == self.selectedProfileName then
				button.highlight:Show()
			else
				button.highlight:Hide()
			end

			if name == self.activeProfileName then
				button.Check:Show()
			else
				button.Check:Hide()
			end
		else
			button:Hide()
		end
	end
end

function ProfilePanel.OnClickProfileButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	ProfilePanel.selectedProfileName = button.nameText:GetText()
	ProfilePanel:Update()
end


--[[ Buttons ]]--

function ProfilePanel:UpdateButtons()
	-- Activate, Delete
	if self.selectedProfileName == self.activeProfileName then
		self.activateButton:Disable()
		self.deleteButton:Disable()
	else
		self.activateButton:Enable()
		self.deleteButton:Enable()
	end

	-- To Character, To Account
	local selectedProfileKey = self.profileMap[self.selectedProfileName].key
	if selectedProfileKey and NeedToKnow.accountSettings.Profiles[selectedProfileKey] then
		self.toCharacterButton:Show()
		self.toAccountButton:Hide()
	else
		self.toCharacterButton:Hide()
		self.toAccountButton:Show()
	end
end

function ProfilePanel.OnClickActivateButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.profileMap
	if profileName then
		NeedToKnow.ActivateProfile(profileMap[profileName].key)
		panel:Update()
	end
end

StaticPopupDialogs["NEEDTOKNOW_RENAME_PROFILE"] = {
	text = String.RENAME_PROFILE_DIALOG, 
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnShow = function(self, data)
		self.editBox:SetText(data.oldName)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
	end,
	EditBoxOnTextChanged = function(self) 
		local newName = self:GetText()
		local acceptButton = self:GetParent().button1
		if NeedToKnow.IsProfileNameAvailable(newName) then
			acceptButton:Enable()
		else
			acceptButton:Disable()
		end
	end, 
	EditBoxOnEnterPressed = function(self, data)
		local newName = self:GetParent().editBox:GetText()
		if NeedToKnow.IsProfileNameAvailable(newName) then
			NeedToKnow.RenameProfile(data.profileKey, newName)
			self:GetParent():Hide()
			ProfilePanel:UpdateProfileList()
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
		-- self:ClearFocus()
	end,
	OnAccept = function(self, data)
		local newName = self.editBox:GetText()
		NeedToKnow.RenameProfile(data.profileKey, newName)
		ProfilePanel:UpdateProfileList()
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetText("")
	end,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
}

function ProfilePanel.OnClickRenameButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	if profileName then
		local data = {oldName = profileName, profileKey = panel.profileMap[profileName].key}
		StaticPopup_Show("NEEDTOKNOW_RENAME_PROFILE", nil, nil, data)
	end
end

StaticPopupDialogs["NEEDTOKNOW_DELETE_PROFILE"] = {
	text = String.DELETE_PROFILE_DIALOG, 
	button1 = YES,
	button2 = NO,
	showAlert = 1, 
	OnShow = function(self, data)
		data.oldStrata = self:GetFrameStrata()
		self:SetFrameStrata("TOOLTIP")
	end,
	OnAccept = function(self, data)
		NeedToKnow.DeleteProfile(data.profileKey)
		ProfilePanel:UpdateProfileList()
	end, 
	OnHide = function(self, data)
		if data.oldStrata then 
			self:SetFrameStrata(data.oldStrata) 
		end
	end, 
	hideOnEscape = 1,
	timeout = 0,
}

function ProfilePanel.OnClickDeleteButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	if profileName then
		local data = {profileKey = panel.profileMap[profileName].key}
		StaticPopup_Show("NEEDTOKNOW_DELETE_PROFILE", profileName, nil, data)
	end
end

function ProfilePanel.OnClickCopyButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.profileMap
	if profileName then
		local profileKey = profileMap[profileName].key
		NeedToKnow.CopyProfile(profileKey)
		panel:UpdateProfileList()
	end
end

function ProfilePanel.OnClickToAccountButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.profileMap
	if profileName then
		local profileKey = profileMap[profileName].key
		NeedToKnow.SetProfileToAccount(profileKey)
		panel:UpdateProfileList()
	end
end

function ProfilePanel.OnClickToCharacterButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.profileMap
	if profileName then
		local profileKey = profileMap[profileName].key
		NeedToKnow.SetProfileToCharacter(profileKey)
		panel:UpdateProfileList()
	end
end

function ProfilePanel.OnClickDefaultsButton()
	-- NeedToKnow.ResetCharacter()
	-- ProfilePanel:UpdateProfileList()
	NeedToKnow:ResetCharacterSettings()
	NeedToKnow:LoadProfiles()
	NeedToKnow:UpdateActiveProfile()
	-- TO DO: Not working properly
end


--[[ ]]--

do
	ProfilePanel:OnLoad()
end

