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
	self.NewName:SetScript("OnTextChanged", NeedToKnowOptions.UpdateProfileList)

	-- Profiles scroll frame
	self.Profiles.configure = function(i, btn, label) 
		-- btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar","Minimalist"))
		btn.Bg:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue")
		btn.Bg:SetBlendMode("ADD")
	end
	self.Profiles.List:SetScript("OnSizeChanged", NeedToKnow.ScrollFrame.OnSizeChanged)
	self.Profiles.List.update = NeedToKnowOptions.UpdateProfileList
	self.Profiles.onClick = function(self)
		local scrollPanel = self:GetParent():GetParent():GetParent()
		scrollPanel.curSel = self.text:GetText()
		NeedToKnowOptions.UpdateProfileList()
	end
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
	NeedToKnowOptions.RebuildProfileList(self)
	self:Update()
end

function ProfilePanel:Update()
	-- Called by ProfilePanel:OnShow()
	if not self:IsVisible() then return end
	-- local panelName = "InterfaceOptionsNeedToKnowProfilePanel"
	-- _G[panelName.."ProfilesTitle"]:SetText(NEEDTOKNOW.UIPANEL_CURRENTPRIMARY)
	-- Kitjan: Use GetSpecializationInfoForClassID(UnitClass("player"), GetSpecialization()) instead of primary
	NeedToKnowOptions.UpdateProfileList()
end

--[[
function ProfilePanel:UpdateProfileList()
end

function ProfilePanel:RebuildProfileList()
end
]]--


--[[ Buttons ]]--

function ProfilePanel:OnClickActivateButton()
	-- called with self = button
	local scrollPanel = self:GetParent().Profiles
	local curSel = scrollPanel.curSel
	if curSel then
		NeedToKnow.ChangeProfile(scrollPanel.profileMap[curSel].key)
		NeedToKnowOptions.UpdateProfileList()
	end
end

function ProfilePanel:OnClickRenameButton()
	-- called with self = button
	local panel = self:GetParent()
	local scrollPanel = panel.Profiles
	local editBox = panel.NewName
	local name = editBox:GetText()
	editBox:ClearFocus()
	if scrollPanel.curSel and NeedToKnow.IsProfileNameAvailable(name) then
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		-- print("NeedToKnow: Renaming profile", NeedToKnow_Profiles[key].name, "to", name)
		NeedToKnow_Profiles[key].name = name
		editBox:SetText("")
		NeedToKnowOptions.RebuildProfileList(panel)
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
	local panel = self:GetParent()
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
					-- print("NeedToKnow: deleted account-wide profile", NeedToKnow_Globals.Profiles[k].name) -- LOCME
					NeedToKnow_Globals.Profiles[k] = nil
				elseif NeedToKnow_CharSettings.Profiles[k] then 
					-- print("NeedToKnow: deleted character profile", NeedToKnow_CharSettings.Profiles[k].name) -- LOCME
					NeedToKnow_CharSettings.Profiles[k] = nil
				end
				NeedToKnowOptions.RebuildProfileList(panel)
			end
		end
		StaticPopup_Show("NEEDTOKNOW.CONFIRMDLG")
	end
end

function ProfilePanel:OnClickCopyButton()
	-- called with self = button
	local panel = self:GetParent()
	local scrollPanel = panel.Profiles
	local curSel = scrollPanel.curSel
	local edit = panel.NewName
	local newName = edit:GetText()
	edit:ClearFocus()
	if scrollPanel.curSel and NeedToKnow.IsProfileNameAvailable(newName) then
		local keyNew = NeedToKnow.CreateProfile(CopyTable(scrollPanel.profileMap[curSel].ref), nil, newName)
		NeedToKnow.ChangeProfile(keyNew)
		NeedToKnowOptions.RebuildProfileList(panel)
		edit:SetText("")
		-- print("NeedToKnow: Copied", curSel, "to", newName, "and made it the active profile")
	end
end

function ProfilePanel:OnClickToAccountButton()
	-- called with self = button
	local panel = self:GetParent()
	local scrollPanel = panel.Profiles
	if scrollPanel.curSel then
		local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		NeedToKnow_Globals.Profiles[key] = ref
		NeedToKnow_CharSettings.Profiles[key] = nil
		NeedToKnowOptions.RebuildProfileList(panel)
	end
end

function ProfilePanel:OnClickToCharacterButton()
	-- called with self = button
	local panel = self:GetParent()
	local scrollPanel = panel.Profiles
	if scrollPanel.curSel then
		local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
		local key = scrollPanel.profileMap[scrollPanel.curSel].key
		NeedToKnow_Globals.Profiles[key] = nil
		NeedToKnow_CharSettings.Profiles[key] = ref
		NeedToKnowOptions.RebuildProfileList(panel)
	end
end


--[[ ]]--

do
	ProfilePanel:OnLoad()
end

