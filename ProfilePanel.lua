-- Interface options panel: Profile

local addonName, addonTable = ...
local ProfilePanel = NeedToKnow.ProfilePanel  -- Temporary

function ProfilePanel:OnLoad()
	Mixin(self, ProfilePanel)  -- Temporary

	self:SetScript("OnShow", self.OnShow)

	-- Register for Blizz Interface Options panel
	self.name = NEEDTOKNOW.UIPANEL_PROFILE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	---- self.cancel = NeedToKnow.Cancel
	---- need different way to handle cancel?  users might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)

	self:SetText()

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
	local panelName = self:GetName()
	_G[panelName.."Version"]:SetText(NEEDTOKNOW.VERSION)
	_G[panelName.."SubText1"]:SetText(NEEDTOKNOW.UIPANEL_PROFILES_SUBTEXT1)
	_G[panelName.."ProfilesTitle"]:SetText(NEEDTOKNOW.UIPANEL_CURRENTPRIMARY)

	-- self.title:SetText(addonName.." v"..NeedToKnow.version)
	-- self.subText:SetText(String.PROFILE_PANEL_SUBTEXT)
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



