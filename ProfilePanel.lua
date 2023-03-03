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
	self.NewName:SetScript("OnTextChanged", ProfilePanel.UpdateProfileList)

	-- Profile list scroll frame
	self.Profiles.List:SetScript("OnSizeChanged", NeedToKnow.ScrollFrame.OnSizeChanged)
	self.Profiles.List.update = ProfilePanel.UpdateProfileList
	self.Profiles.onClick = ProfilePanel.OnClickProfileItem
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

    local allNames = scrollPanel.profileNames
    local allRefs = scrollPanel.profileMap

    local n = 0
    local subList = NeedToKnow_Profiles
    if subList then
        for profKey, rProfile in pairs(subList) do
            n = n + 1
            local profName
            if NeedToKnow_Globals.Profiles[profKey] == rProfile then
                profName = 'Account: '..rProfile.name -- FIXME Localization
            else
                profName = 'Character: '..rProfile.name -- Fixme: Character-Server:
            end
            allNames[n] = profName
            allRefs[profName] = {ref = rProfile, global = true, key = profKey}
            if profKey == oldKey then
                scrollPanel.curSel = profName
            end
        end
    end
    while n < #allNames do
        table.remove(allNames)
    end

    table.sort(allNames, function(lhs, rhs) return string.upper(lhs) < string.upper(rhs) end)
    profilePanel:UpdateProfileList()
end

function ProfilePanel:UpdateProfileList()
	-- print(GetTime(), "UpdateProfileList()")
	local self = ProfilePanel
	local panel = ProfilePanel
	local scrollPanel = self.Profiles
	if scrollPanel.profileNames then
		local curProfile
		for n, r in pairs(scrollPanel.profileMap) do
			if r.ref == NeedToKnow.ProfileSettings then
				curProfile = n
				break
			end
		end

		if not scrollPanel.curSel or not scrollPanel.profileMap[scrollPanel.curSel] then
			scrollPanel.curSel = curProfile
		end
		local curSel = scrollPanel.curSel

		NeedToKnowOptions.UpdateScrollPanel(scrollPanel, scrollPanel.profileNames, curSel, curProfile)

		-- Update activate and delete buttons
		if curSel == curProfile then
			self.activateButton:Disable()
			self.deleteButton:Disable()
		else
			self.activateButton:Enable()
			self.deleteButton:Enable()
		end

		-- Update rename and copy buttons
		local curEntry = self.NewName:GetText()
		if NeedToKnow.IsProfileNameAvailable(curEntry) then
			self.renameButton:Enable()
			self.copyButton:Enable()
		else
			self.renameButton:Disable()
			self.copyButton:Disable()
		end

		-- Update to character and to account buttons
		local rSelectedProfile = scrollPanel.profileMap[curSel].ref
		local rSelectedKey = scrollPanel.profileMap[curSel].key
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

function ProfilePanel.OnClickProfileItem(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	panel.Profiles.curSel = button.text:GetText()
	panel:UpdateProfileList()
end


--[[ Buttons ]]--

-- function ProfilePanel:UpdateButtons()
-- end

function ProfilePanel:OnClickActivateButton()
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local curSel = scrollPanel.curSel
	if curSel then
		NeedToKnow.ChangeProfile(scrollPanel.profileMap[curSel].key)
		panel:UpdateProfileList()
	end
end

function ProfilePanel:OnClickRenameButton()
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local editBox = panel.NewName
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

function ProfilePanel:OnClickDeleteButton()
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

function ProfilePanel:OnClickCopyButton()
	-- called with self = button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	local panel = ProfilePanel
	local scrollPanel = panel.Profiles
	local curSel = scrollPanel.curSel
	local edit = panel.NewName
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

function ProfilePanel:OnClickToAccountButton()
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

function ProfilePanel:OnClickToCharacterButton()
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

