-- Interface options panel: Profile
-- Load after ProfilePanel.xml

local addonName, addonTable = ...
local ProfilePanel = InterfaceOptionsNeedToKnowProfilePanel
local String = NeedToKnow.String

function ProfilePanel:OnLoad()
	self:SetScripts()
	self:SetText()

	-- Register with Blizz Interface Options panel
	self.name = String.PROFILE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	-- self.cancel = NeedToKnow.Cancel
	-- Need different way to handle cancel?  Might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function ProfilePanel:SetScripts()
	self:SetScript("OnShow", self.OnShow)

	self.activateButton:SetScript("OnClick", self.OnClickActivateButton)
	self.renameButton:SetScript("OnClick", self.OnClickRenameButton)
	self.deleteButton:SetScript("OnClick", self.OnClickDeleteButton)
	self.copyButton:SetScript("OnClick", self.OnClickCopyButton)
	self.toAccountButton:SetScript("OnClick", self.OnClickToAccountButton)
	self.toCharacterButton:SetScript("OnClick", self.OnClickToCharacterButton)
	self.editBox:SetScript("OnTextChanged", ProfilePanel.OnEditBoxTextChanged)

	-- Profile list scroll frame
	self.Profiles.List:SetScript("OnSizeChanged", ProfilePanel.OnScrollFrameSizeChanged)
end

function ProfilePanel:SetText()
	self.title:SetText("NeedToKnow v"..NeedToKnow.version)
	self.subText:SetText(String.PROFILE_PANEL_SUBTEXT)
	self.Profiles.title:SetText(String.PROFILES)
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
	self.newNameLabel:SetText(String.NEW_PROFILE_NAME)
end

function ProfilePanel:OnShow()
	self:UpdateProfileList()
	self:Update()
end

function ProfilePanel:UpdateProfileList()
	local scrollPanel = self.Profiles

	local oldKey
	if self.selectedProfileName and scrollPanel.profileMap then
		oldKey = scrollPanel.profileMap[self.selectedProfileName].key
	end

	self.profileNames = self.profileNames or {}
	scrollPanel.profileMap = {}
	local profileNames = self.profileNames
	local profileMap = scrollPanel.profileMap
	local i = 0
	if NeedToKnow_Profiles then
		for profileKey, rProfile in pairs(NeedToKnow_Profiles) do
			i = i + 1
			local name
			if NeedToKnow_Globals.Profiles[profileKey] == rProfile then
				name = 'Account: '..rProfile.name
			else
				name = 'Character: '..rProfile.name
			end
			profileNames[i] = name
			profileMap[name] = {ref = rProfile, global = true, key = profileKey}
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
	local scrollPanel = self.Profiles
	if scrollPanel.profileMap then
		-- Get current profile name
		for name, r in pairs(scrollPanel.profileMap) do
			if r.ref == NeedToKnow.ProfileSettings then
				self.currentProfileName = name
				break
			end
		end

		if not self.selectedProfileName or not scrollPanel.profileMap[self.selectedProfileName] then
			self.selectedProfileName = self.currentProfileName
		end

		self:UpdateProfileScrollFrame()
		self:UpdateButtons()
	end
end

function ProfilePanel.OnEditBoxTextChanged(editBox)
	ProfilePanel:UpdateButtons()
end



--[[ Profile list scroll frame ]]--

function ProfilePanel.OnScrollFrameSizeChanged(scrollFrame)
    HybridScrollFrame_CreateButtons(scrollFrame, "NeedToKnowScrollItemTemplate")
	for _, button in pairs(scrollFrame.buttons) do
		button:SetScript("OnClick", ProfilePanel.OnClickProfileButton)
	end
    local old_value = scrollFrame.scrollBar:GetValue()
    local max_value = scrollFrame.range or scrollFrame:GetHeight()
    scrollFrame.scrollBar:SetValue(min(old_value, max_value))
end

function ProfilePanel:UpdateProfileScrollFrame()
	local scrollFrame = self.Profiles.List
	local buttons = scrollFrame.buttons
	local profileNames = self.profileNames

	HybridScrollFrame_Update(scrollFrame, #profileNames * buttons[1]:GetHeight(), scrollFrame:GetHeight())

	-- Update profile buttons
	local name
	for i, button in ipairs(buttons) do
		name = profileNames[i + HybridScrollFrame_GetOffset(scrollFrame)]
		if name then
			button:Show()
			button.text:SetText(name)
			if name == self.selectedProfileName then
				button.highlight:Show()
			else
				button.highlight:Hide()
			end
			if name == self.currentProfileName then
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
	ProfilePanel.selectedProfileName = button.text:GetText()
	ProfilePanel:Update()
end


--[[ Panel buttons ]]--

function ProfilePanel:UpdateButtons()
	-- Activate, Delete
	if self.selectedProfileName == self.currentProfileName then
		self.activateButton:Disable()
		self.deleteButton:Disable()
	else
		self.activateButton:Enable()
		self.deleteButton:Enable()
	end

	-- Rename, Copy
	if NeedToKnow.IsProfileNameAvailable(self.editBox:GetText()) then
		self.renameButton:Enable()
		self.copyButton:Enable()
	else
		self.renameButton:Disable()
		self.copyButton:Disable()
	end

	-- To Character, To Account
	local profileMap = self.Profiles.profileMap
	local selectedProfile = profileMap[self.selectedProfileName].ref
	local selectedProfileKey = profileMap[self.selectedProfileName].key
	if selectedProfile and selectedProfileKey and 
		NeedToKnow_Globals.Profiles[selectedProfileKey] == selectedProfile
	then
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
	local profileMap = panel.Profiles.profileMap
	if profileName then
		NeedToKnow.ChangeProfile(profileMap[profileName].key)
		panel:Update()
	end
end

function ProfilePanel.OnClickRenameButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local editBox = panel.editBox
	local oldName = panel.selectedProfileName
	local newName = editBox:GetText()
	local profileMap = panel.Profiles.profileMap
	editBox:ClearFocus()
	if oldName and NeedToKnow.IsProfileNameAvailable(newName) then
		local key = profileMap[oldName].key
		NeedToKnow_Profiles[key].name = newName
		editBox:SetText("")
		panel:UpdateProfileList()
	end
end

StaticPopupDialogs["NEEDTOKNOW.CONFIRMDLG"] = {
    button1 = YES,
    button2 = NO,
    timeout = 0,
    hideOnEscape = 1,
    OnShow = function(self)
        self.oldStrata = self:GetFrameStrata()
        self:SetFrameStrata("TOOLTIP")
    end,
    OnHide = function(self)
        if self.oldStrata then 
            self:SetFrameStrata(self.oldStrata) 
        end
    end
}

function ProfilePanel.OnClickDeleteButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.Profiles.profileMap
	if profileName then
		local k = profileMap[profileName].key
		local dlgInfo = StaticPopupDialogs["NEEDTOKNOW.CONFIRMDLG"]
		dlgInfo.text = "Are you sure you want to delete NeedToKnow profile: ".. profileName .."?"
		dlgInfo.OnAccept = function(self, data)
			if NeedToKnow_Profiles[k] == NeedToKnow.ProfileSettings then
				print("NeedToKnow: Won't delete the active profile!")
			else
				NeedToKnow_Profiles[k] = nil
				if NeedToKnow_Globals.Profiles[k] then 
					NeedToKnow_Globals.Profiles[k] = nil
				elseif NeedToKnow_CharSettings.Profiles[k] then 
					NeedToKnow_CharSettings.Profiles[k] = nil
				end
				panel:UpdateProfileList()
			end
		end
		StaticPopup_Show("NEEDTOKNOW.CONFIRMDLG")
	end
end

function ProfilePanel.OnClickCopyButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.Profiles.profileMap
	local edit = panel.editBox
	local newName = edit:GetText()
	edit:ClearFocus()
	if profileName and NeedToKnow.IsProfileNameAvailable(newName) then
		local newKey = NeedToKnow.CreateProfile(CopyTable(profileMap[profileName].ref), nil, newName)
		NeedToKnow.ChangeProfile(newKey)
		panel:UpdateProfileList()
		edit:SetText("")
	end
end

function ProfilePanel.OnClickToAccountButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.Profiles.profileMap
	if profileName then
		local key = profileMap[profileName].key
		local ref = profileMap[profileName].ref
		NeedToKnow_Globals.Profiles[key] = ref
		NeedToKnow_CharSettings.Profiles[key] = nil
		panel:UpdateProfileList()
	end
end

function ProfilePanel.OnClickToCharacterButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.Profiles.profileMap
	if profileName then
		local ref = profileMap[profileName].ref
		local key = profileMap[profileName].key
		NeedToKnow_Globals.Profiles[key] = nil
		NeedToKnow_CharSettings.Profiles[key] = ref
		panel:UpdateProfileList()
	end
end


--[[ ]]--

do
	ProfilePanel:OnLoad()
end

