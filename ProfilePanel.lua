-- Interface options panel: Profile
-- Load after ProfilePanel.xml

local addonName, addonTable = ...
local ProfilePanel = InterfaceOptionsNeedToKnowProfilePanel
local String = NeedToKnow.String

function ProfilePanel:OnLoad()
	self:SetScripts()
	self:SetText()

	-- Register for Blizz Interface Options panel
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
	self.toCharacterButton:SetScript("OnClick",self.OnClickToCharacterButton)
	self.editBox:SetScript("OnTextChanged", ProfilePanel.OnEditBoxTextChanged)

	-- Profile list scroll frame
	self.Profiles.List:SetScript("OnSizeChanged", ProfilePanel.OnScrollFrameSizeChanged)
	self.Profiles.List.update = ProfilePanel.UpdateProfileList
end

function ProfilePanel:SetText()
	self.title:SetText(addonName.." v"..NeedToKnow.version)
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
	self:RebuildProfileList()
	self:Update()
end

function ProfilePanel:RebuildProfileList()
	local scrollPanel = self.Profiles

	local oldKey
	if scrollPanel.curSel and scrollPanel.profileMap then
		oldKey = scrollPanel.profileMap[scrollPanel.curSel].key
	end

	if not scrollPanel.profileNames then
		scrollPanel.profileNames = {}
	end
	scrollPanel.profileMap = {}

	local profileNames = scrollPanel.profileNames
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
				scrollPanel.curSel = name
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
	local self = ProfilePanel
	if not self:IsVisible() then return end

	local scrollPanel = self.Profiles
	if scrollPanel.profileNames then
		-- Get current profile name
		for name, r in pairs(scrollPanel.profileMap) do
			if r.ref == NeedToKnow.ProfileSettings then
				self.currentProfileName = name
				break
			end
		end

		-- Get selected profile name
		if not scrollPanel.curSel or not scrollPanel.profileMap[scrollPanel.curSel] then
			scrollPanel.curSel = self.currentProfileName
		end
		local selectedName = scrollPanel.curSel
		self.selectedProfileName = selectedName

		self:UpdateProfileScrollFrame(scrollPanel.profileNames)
		self:UpdateButtons()
	end
end

function ProfilePanel.OnEditBoxTextChanged(editBox)
	-- Called with self = editBox
	ProfilePanel:UpdateButtons()
end



--[[ Profile list scroll frame ]]--

function ProfilePanel.OnScrollFrameSizeChanged(self)
	-- Called with self = scrollFrame
    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
	for _, button in pairs(self.buttons) do
		button:SetScript("OnClick", ProfilePanel.OnClickProfileButton)
	end
    local old_value = self.scrollBar:GetValue()
    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value))
end

function ProfilePanel:UpdateProfileScrollFrame(profileNames)
	local scrollFrame = self.Profiles.List
	local buttons = scrollFrame.buttons

	HybridScrollFrame_Update(scrollFrame, #profileNames * buttons[1]:GetHeight(), scrollFrame:GetHeight())

	-- Update profile buttons
	local name
	for i, button in ipairs(buttons) do
		name = profileNames[i + HybridScrollFrame_GetOffset(scrollFrame)]
		if name then
			button:Show()
			button.text:SetText(name)
			if name == self.selectedProfileName then
				button.Bg:Show()
			else
				button.Bg:Hide()
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
	local panel = ProfilePanel
	panel.Profiles.curSel = button.text:GetText()
	panel.selectedProfileName = button.text:GetText()
	panel:Update()
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
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local profileName = scrollPanel.curSel
	if profileName then
		NeedToKnow.ChangeProfile(scrollPanel.profileMap[profileName].key)
		panel:Update()
	end
end

function ProfilePanel.OnClickRenameButton(button)
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local editBox = panel.editBox
	local name = editBox:GetText()
	editBox:ClearFocus()
	if scrollPanel.curSel and NeedToKnow.IsProfileNameAvailable(name) then
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		-- print("NeedToKnow: Renaming profile", NeedToKnow_Profiles[key].name, "to", name)
		NeedToKnow_Profiles[key].name = name
		editBox:SetText("")
		panel:RebuildProfileList()
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
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local curSel = scrollPanel.curSel
	if curSel then
		local k = scrollPanel.profileMap[curSel].key
		local dlgInfo = StaticPopupDialogs["NEEDTOKNOW.CONFIRMDLG"]
		dlgInfo.text = "Are you sure you want to delete the profile: ".. curSel .."?"
		dlgInfo.OnAccept = function(self, data)
			if NeedToKnow_Profiles[k] == NeedToKnow.ProfileSettings then
				print("NeedToKnow: Won't delete the active profile!")
			else
				NeedToKnow_Profiles[k] = nil
				if NeedToKnow_Globals.Profiles[k] then 
					-- print("NeedToKnow: deleted account-wide profile", NeedToKnow_Globals.Profiles[k].name)
					NeedToKnow_Globals.Profiles[k] = nil
				elseif NeedToKnow_CharSettings.Profiles[k] then 
					-- print("NeedToKnow: deleted character profile", NeedToKnow_CharSettings.Profiles[k].name)
					NeedToKnow_CharSettings.Profiles[k] = nil
				end
				panel:RebuildProfileList()
			end
		end
		StaticPopup_Show("NEEDTOKNOW.CONFIRMDLG")
	end
end

function ProfilePanel.OnClickCopyButton(button)
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local curSel = scrollPanel.curSel
	local edit = panel.editBox
	local newName = edit:GetText()
	edit:ClearFocus()
	if scrollPanel.curSel and NeedToKnow.IsProfileNameAvailable(newName) then
		local keyNew = NeedToKnow.CreateProfile(CopyTable(scrollPanel.profileMap[curSel].ref), nil, newName)
		NeedToKnow.ChangeProfile(keyNew)
		panel:RebuildProfileList()
		edit:SetText("")
		-- print("NeedToKnow: Copied", curSel, "to", newName, "and made it the active profile")
	end
end

function ProfilePanel.OnClickToAccountButton(button)
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	if scrollPanel.curSel then
		local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		NeedToKnow_Globals.Profiles[key] = ref
		NeedToKnow_CharSettings.Profiles[key] = nil
		panel:RebuildProfileList()
	end
end

function ProfilePanel.OnClickToCharacterButton(button)
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	if scrollPanel.curSel then
		local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		NeedToKnow_Globals.Profiles[key] = nil
		NeedToKnow_CharSettings.Profiles[key] = ref
		panel:RebuildProfileList()
	end
end


--[[ ]]--

do
	ProfilePanel:OnLoad()
end

