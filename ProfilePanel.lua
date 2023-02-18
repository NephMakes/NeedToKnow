-- Interface options panel: Profile

local addonName, addonTable = ...
local ProfilePanel = NeedToKnow.ProfilePanel  -- Temporary
local String = NeedToKnow.String

function ProfilePanel:OnLoad()
	Mixin(self, ProfilePanel)  -- Temporary
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

function ProfilePanel:UpdateProfileList()
end




