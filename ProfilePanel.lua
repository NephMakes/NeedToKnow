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
	self.profileScrollFrame:SetScript("OnSizeChanged", self.OnScrollFrameSizeChanged)
	self.activateButton:SetScript("OnClick", self.OnClickActivateButton)
	self.renameButton:SetScript("OnClick", self.OnClickRenameButton)
	self.deleteButton:SetScript("OnClick", self.OnClickDeleteButton)
	self.copyButton:SetScript("OnClick", self.OnClickCopyButton)
	self.toAccountButton:SetScript("OnClick", self.OnClickToAccountButton)
	self.toCharacterButton:SetScript("OnClick", self.OnClickToCharacterButton)
	self.editBox:SetScript("OnTextChanged", self.OnEditBoxTextChanged)
end

function ProfilePanel:SetText()
	self.title:SetText("NeedToKnow v"..NeedToKnow.version)
	self.subText:SetText(String.PROFILE_PANEL_SUBTEXT)
	self.profileScrollFrame.label:SetText(String.PROFILES)
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
	self.editBoxLabel:SetText(String.NEW_PROFILE_NAME)
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
	if NeedToKnow_Profiles then
		for profileKey, profile in pairs(NeedToKnow_Profiles) do
			i = i + 1
			local name, profileType
			if NeedToKnow_Globals.Profiles[profileKey] == profile then
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
		-- Get current profile name
		for name, r in pairs(self.profileMap) do
			if r.ref == NeedToKnow.ProfileSettings then
				self.currentProfileName = name
				break
			end
		end

		-- Get selected profile name
		if not self.selectedProfileName or not self.profileMap[self.selectedProfileName] then
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
	ProfilePanel.selectedProfileName = button.nameText:GetText()
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
	local selectedProfile = self.profileMap[self.selectedProfileName].ref
	local selectedProfileKey = self.profileMap[self.selectedProfileName].key
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
	local profileMap = panel.profileMap
	if profileName then
		NeedToKnow.ChangeProfile(profileMap[profileName].key)
		panel:Update()
	end
end

function ProfilePanel.OnClickRenameButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local oldName = panel.selectedProfileName
	local newName = panel.editBox:GetText()
	local profileMap = panel.profileMap
	panel.editBox:ClearFocus()
	if oldName and NeedToKnow.IsProfileNameAvailable(newName) then
		local key = profileMap[oldName].key
		NeedToKnow_Profiles[key].name = newName
		panel.editBox:SetText("")
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
	local profileMap = panel.profileMap
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
	local profileMap = panel.profileMap
	local newName = panel.editBox:GetText()
	panel.editBox:ClearFocus()
	if profileName and NeedToKnow.IsProfileNameAvailable(newName) then
		local newKey = NeedToKnow.CreateProfile(CopyTable(profileMap[profileName].ref), nil, newName)
		NeedToKnow.ChangeProfile(newKey)
		panel:UpdateProfileList()
		panel.editBox:SetText("")
	end
end

function ProfilePanel.OnClickToAccountButton(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local profileName = panel.selectedProfileName
	local profileMap = panel.profileMap
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
	local profileMap = panel.profileMap
	if profileName then
		local key = profileMap[profileName].key
		local ref = profileMap[profileName].ref
		NeedToKnow_Globals.Profiles[key] = nil
		NeedToKnow_CharSettings.Profiles[key] = ref
		panel:UpdateProfileList()
	end
end


--[[ ]]--

do
	ProfilePanel:OnLoad()
end

