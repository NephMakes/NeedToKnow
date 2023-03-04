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
	self.editBox:SetScript("OnTextChanged", ProfilePanel.UpdateProfileList)

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

function ProfilePanel:Update()
	-- Called by ProfilePanel:OnShow()
	if not self:IsVisible() then return end
	self:UpdateProfileList()
end


--[[ Profile list scroll frame ]]--

function ProfilePanel.OnScrollFrameSizeChanged(self)
	-- called with self = scrollFrame.List
    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
	for _, button in pairs(self.buttons) do
		button:SetScript("OnClick", ProfilePanel.OnClickProfileButton)
	end
    local old_value = self.scrollBar:GetValue()
    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value))
end

function ProfilePanel:RebuildProfileList()
	local profilePanel = self
	local scrollPanel = profilePanel.Profiles
	local oldKey
	if scrollPanel.curSel and scrollPanel.profileMap then
		oldKey = scrollPanel.profileMap[scrollPanel.curSel].key
	end

	if not scrollPanel.profileNames then
		scrollPanel.profileNames = {}
	end
	scrollPanel.profileMap = {}

	local profileNames = scrollPanel.profileNames
	local allRefs = scrollPanel.profileMap

	local i = 0
	if NeedToKnow_Profiles then
		for profKey, rProfile in pairs(NeedToKnow_Profiles) do
			i = i + 1
			local name
			if NeedToKnow_Globals.Profiles[profKey] == rProfile then
				name = 'Account: '..rProfile.name
			else
				name = 'Character: '..rProfile.name
			end
			profileNames[i] = name
			allRefs[name] = {ref = rProfile, global = true, key = profKey}
			if profKey == oldKey then
				scrollPanel.curSel = name
			end
		end
	end
	while i < #profileNames do
		table.remove(profileNames)
	end

	table.sort(profileNames, function(lhs, rhs) return string.upper(lhs) < string.upper(rhs) end)
	profilePanel:UpdateProfileList()
end

function ProfilePanel:UpdateProfileList()
	-- print(GetTime(), "UpdateProfileList()")
	local self = ProfilePanel
	-- local panel = ProfilePanel
	local scrollPanel = self.Profiles
	if scrollPanel.profileNames then
		-- Get current profile name
		local currentName
		for name, r in pairs(scrollPanel.profileMap) do
			if r.ref == NeedToKnow.ProfileSettings then
				currentName = name
				break
			end
		end

		-- Get selected profile name
		if not scrollPanel.curSel or not scrollPanel.profileMap[scrollPanel.curSel] then
			scrollPanel.curSel = currentName
		end
		local selectedName = scrollPanel.curSel

		self:UpdateProfileScrollFrame(scrollPanel.profileNames, selectedName, currentName)

		-- Update activate and delete buttons
		if selectedName == currentName then
			self.activateButton:Disable()
			self.deleteButton:Disable()
		else
			self.activateButton:Enable()
			self.deleteButton:Enable()
		end

		-- Update rename and copy buttons
		if NeedToKnow.IsProfileNameAvailable(self.editBox:GetText()) then
			self.renameButton:Enable()
			self.copyButton:Enable()
		else
			self.renameButton:Disable()
			self.copyButton:Disable()
		end

		-- Update to-character and to-account buttons
		local rSelectedProfile = scrollPanel.profileMap[selectedName].ref
		local rSelectedKey = scrollPanel.profileMap[selectedName].key
		if rSelectedProfile and rSelectedKey and 
			NeedToKnow_Globals.Profiles[rSelectedKey] == rSelectedProfile
		then
			self.toCharacterButton:Show()
			self.toAccountButton:Hide()
		else
			self.toCharacterButton:Hide()
			self.toAccountButton:Show()
		end
	end
end

function ProfilePanel:UpdateProfileScrollFrame(profileNames, selectedName, currentName)
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
			if name == selectedName then
				button.Bg:Show()
			else
				button.Bg:Hide()
			end
			if name == currentName then
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
	panel:UpdateProfileList()
end


--[[ Buttons ]]--

-- function ProfilePanel:UpdateButtons()
-- end

function ProfilePanel.OnClickActivateButton(button)
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local profileName = scrollPanel.curSel
	if selectedName then
		NeedToKnow.ChangeProfile(scrollPanel.profileMap[profileName].key)
		panel:UpdateProfileList()
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

