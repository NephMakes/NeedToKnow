-- Load after AppearancePanel.lua

local addonName, addonTable = ...
NeedToKnow.ScrollFrame = {}
local ScrollFrame = NeedToKnow.ScrollFrame

local trace = print

local GetActiveTalentGroup = _G.GetActiveSpecGroup or _G.GetActiveTalentGroup   -- Retail or Classic

function NeedToKnow.FindProfileByName(profName)
    local key
    for k,t in pairs(NeedToKnow_Profiles) do
        if t.name == profName then
            return k
        end
    end
end

function NeedToKnow.SlashCommand(cmd)
	local args = {}
	for arg in cmd:gmatch("(%S+)") do
		table.insert(args, arg)
	end

	cmd = args[1]
	table.remove(args, 1)

	if not cmd then
		NeedToKnow:ToggleLockUnlock()
	elseif ( cmd == NEEDTOKNOW.CMD_RESET ) then
		NeedToKnow.Reset();
	elseif ( cmd == NEEDTOKNOW.CMD_PROFILE ) then
		if args[1] then
			local profileName = table.concat(args, " ")
			local key = NeedToKnow.FindProfileByName( profileName )
			if key then
				NeedToKnow.ChangeProfile(key)
				NeedToKnowOptions.UIPanel_Profile_Update()
			else
				print("Could not find a profile named '", profileName, "'");
			end
		else
			local spec = GetActiveTalentGroup()
			local profile = NeedToKnow.CharSettings.Specs[spec]
			print("Current NeedToKnow profile is \""..profile.."\"") -- LOCME!
		end
	else
		print("Unknown NeedToKnow command", cmd)
	end    
end


-- -----------------------------------
-- INTERFACE OPTIONS PANEL: PROFILE
-- -----------------------------------

NeedToKnowOptions.DefaultSelectedColor =   { 0.1, 0.6, 0.8, 1 }
NeedToKnowOptions.DefaultNormalColor = { 0.7, 0.7, 0.7, 0 }

function NeedToKnowOptions.UIPanel_Profile_OnLoad(self)
	self.name = NEEDTOKNOW.UIPANEL_PROFILE;
	self.parent = "NeedToKnow";
	self.default = NeedToKnow.ResetCharacter;
	---- self.cancel = NeedToKnow.Cancel;
	---- need different way to handle cancel?  users might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self);

	local panelName = self:GetName();
	_G[panelName.."Version"]:SetText(NEEDTOKNOW.VERSION);
	_G[panelName.."SubText1"]:SetText(NEEDTOKNOW.UIPANEL_PROFILES_SUBTEXT1);

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

function NeedToKnowOptions.UIPanel_Profile_OnShow(self)
	NeedToKnowOptions.RebuildProfileList(self)
	NeedToKnowOptions.UIPanel_Profile_Update()
end

function NeedToKnowOptions.UIPanel_Profile_Update()
    local panelName = "InterfaceOptionsNeedToKnowProfilePanel";
    local title
	-- FIXME: Use GetSpecializationInfoForClassID(UnitClass("player"), GetSpecialization()) instead of primary
    _G[panelName.."ProfilesTitle"]:SetText(NEEDTOKNOW.UIPANEL_CURRENTPRIMARY)
    local self = _G[panelName]
    if not self:IsVisible() then return end
    NeedToKnowOptions.UpdateProfileList()
end

function NeedToKnowOptions.RebuildProfileList(profilePanel)
    local scrollPanel = profilePanel.Profiles
    local oldKey
    if ( scrollPanel.curSel and scrollPanel.profileMap ) then
        oldKey = scrollPanel.profileMap[scrollPanel.curSel].key
    end

    if not scrollPanel.profileNames then
        scrollPanel.profileNames = { }
    end
    scrollPanel.profileMap = { }

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
            allRefs[profName] = { ref = rProfile, global=true, key=profKey }
            if ( profKey == oldKey ) then
                scrollPanel.curSel = profName;
            end
        end
    end
    while n < #allNames do
        table.remove(allNames)
    end

    table.sort(allNames, function(lhs,rhs) return string.upper(lhs)<string.upper(rhs) end )
    NeedToKnowOptions.UpdateProfileList()
end

function NeedToKnowOptions.IsProfileNameAvailable(newName)
    if not newName or newName == "" then
        return false;
    end

    for k, profile in pairs(NeedToKnow_Profiles) do
        if profile.name == newName then
            return false;
        end
    end
    return true;
end

function NeedToKnowOptions.UpdateProfileList()
    local panel = _G["InterfaceOptionsNeedToKnowProfilePanel"]
    local scrollPanel = panel.Profiles
    if scrollPanel.profileNames then
        local curProfile
        for n,r in pairs(scrollPanel.profileMap) do
            if r.ref == NeedToKnow.ProfileSettings then
                curProfile = n
                break;
            end
        end

	if not scrollPanel.curSel or not scrollPanel.profileMap[scrollPanel.curSel] then
            scrollPanel.curSel = curProfile
        end
        local curSel = scrollPanel.curSel

        NeedToKnowOptions.UpdateScrollPanel(scrollPanel, scrollPanel.profileNames, curSel, curProfile)

        local optionsPanel = scrollPanel:GetParent()
        if curSel == curProfile then
            optionsPanel.SwitchToBtn:Disable()
        else
            optionsPanel.SwitchToBtn:Enable()
        end

        if curSel == curProfile then
            optionsPanel.DeleteBtn:Disable()
        else
            optionsPanel.DeleteBtn:Enable()
        end

        local curEntry = optionsPanel.NewName:GetText()
        if NeedToKnowOptions.IsProfileNameAvailable(curEntry) then
            optionsPanel.RenameBtn:Enable()
            optionsPanel.CopyBtn:Enable()
        else
            optionsPanel.RenameBtn:Disable()
            optionsPanel.CopyBtn:Disable()
        end

        local rSelectedProfile = scrollPanel.profileMap[curSel].ref;
        local rSelectedKey = scrollPanel.profileMap[curSel].key;
        if ( rSelectedProfile and rSelectedKey and NeedToKnow_Globals.Profiles[rSelectedKey] == rSelectedProfile ) then
            optionsPanel.PrivateBtn:Show();
            optionsPanel.PublicBtn:Hide();
        else
            optionsPanel.PrivateBtn:Hide();
            optionsPanel.PublicBtn:Show();
        end
    end
end

function NeedToKnowOptions.UIPanel_Profile_SwitchToSelected(panel)
    local scrollPanel = panel.Profiles
    local curSel = scrollPanel.curSel
    if curSel then
        NeedToKnow.ChangeProfile( scrollPanel.profileMap[curSel].key )
        NeedToKnowOptions.UpdateProfileList()
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
};
function NeedToKnowOptions.UIPanel_Profile_DeleteSelected(panel)
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
                NeedToKnow_Profiles[k] = nil;
                if NeedToKnow_Globals.Profiles[k] then 
                    print("NeedToKnow: deleted account-wide profile", NeedToKnow_Globals.Profiles[k].name) -- LOCME
                    NeedToKnow_Globals.Profiles[k] = nil;
                elseif NeedToKnow_CharSettings.Profiles[k] then 
                    print("NeedToKnow: deleted character profile", NeedToKnow_CharSettings.Profiles[k].name) -- LOCME
                    NeedToKnow_CharSettings.Profiles[k] = nil;
                end
                NeedToKnowOptions.RebuildProfileList(panel)
            end
        end
        StaticPopup_Show("NEEDTOKNOW.CONFIRMDLG");
    end
end

function NeedToKnowOptions.UIPanel_Profile_CopySelected(panel)
    local scrollPanel = panel.Profiles
    local curSel = scrollPanel.curSel
    local edit = panel.NewName
    local newName = edit:GetText()
    edit:ClearFocus()
    if scrollPanel.curSel and NeedToKnowOptions.IsProfileNameAvailable(newName) then
        local keyNew = NeedToKnow.CreateProfile(CopyTable(scrollPanel.profileMap[curSel].ref), nil, newName)
        NeedToKnow.ChangeProfile(keyNew)
        NeedToKnowOptions.RebuildProfileList(panel)
        edit:SetText("");
        print("NeedToKnow: Copied",curSel,"to",newName,"and made it the active profile")
    end
end

function NeedToKnowOptions.UIPanel_Profile_RenameSelected(panel)
    local scrollPanel = panel.Profiles
    local edit = panel.NewName
    local newName = edit:GetText()
    edit:ClearFocus()
    if scrollPanel.curSel and NeedToKnowOptions.IsProfileNameAvailable(newName) then
        local key = scrollPanel.profileMap[scrollPanel.curSel].key
        print("NeedToKnow: Renaming profile",NeedToKnow_Profiles[key].name,"to",newName)
        NeedToKnow_Profiles[key].name = newName;
        edit:SetText("");
        NeedToKnowOptions.RebuildProfileList(panel)
    end
end

function NeedToKnowOptions.UIPanel_Profile_PublicizeSelected(panel)
    local scrollPanel = panel.Profiles
    if scrollPanel.curSel then
        local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
        local key = scrollPanel.profileMap[scrollPanel.curSel].key
        NeedToKnow_Globals.Profiles[key] = ref
        NeedToKnow_CharSettings.Profiles[key] = nil
        NeedToKnowOptions.RebuildProfileList(panel)
    end
end

function NeedToKnowOptions.UIPanel_Profile_PrivatizeSelected(panel)
    local scrollPanel = panel.Profiles
    if scrollPanel.curSel then
        local ref = scrollPanel.profileMap[scrollPanel.curSel].ref
        local key = scrollPanel.profileMap[scrollPanel.curSel].key
        NeedToKnow_Globals.Profiles[key] = nil
        NeedToKnow_CharSettings.Profiles[key] = ref
        NeedToKnowOptions.RebuildProfileList(panel)
    end
end


--[[ ScrollFrame ]]-- 

-- From AppearancePanel.SetScripts():
-- 
--	self.Textures.variable = "BarTexture"
--	self.Textures.itemList = LSM:List("statusbar")
--	self.Textures.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
--	self.Textures.List.update = AppearancePanel.UpdateBarTextureScrollFrame
--	self.Textures.updateButton = function(button, label) 
--		button.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", label))
--	end
--	self.Textures.normal_color = {0.7, 0.7, 0.7, 1}
--	self.Textures.onClick = AppearancePanel.OnClickScrollItem
-- 
--	self.Fonts.variable = "BarFont"
--	self.Fonts.itemList = LSM:List("font")
--	self.Fonts.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
--	self.Fonts.List.update = AppearancePanel.UpdateBarFontScrollFrame
--	self.Fonts.updateButton = function(button, label) 
--		button.text:SetFont(NeedToKnow.LSM:Fetch("font", label), 12)
--	end
--	self.Fonts.onClick = AppearancePanel.OnClickScrollItem

--[[
function AppearancePanel:OnSizeChanged()
	-- Kitjan: Despite my best efforts, the scroll bars insist on being outside the width of their
	local mid = self:GetWidth()/2 --+ _G[self:GetName().."TexturesListScrollBar"]:GetWidth()
	local textures = self.Textures
	local leftTextures = textures:GetLeft()
	if mid and mid > 0 and textures and leftTextures then
		local ofs = leftTextures - self:GetLeft()
		textures:SetWidth(mid - ofs)
	end
end
]]--

ScrollFrame.normalColor = {0.7, 0.7, 0.7, 0}
ScrollFrame.selectedColor = {0.1, 0.6, 0.8, 1}

function ScrollFrame:OnLoad()
end

function ScrollFrame:OnShow()
	-- Scroll to selected option
	local scrollIndex = 1
	for i = 1, #self.itemList do
		if NeedToKnow.ProfileSettings[self.variable] == self.itemList[i] then
			scrollIndex = i
			break
		end
	end
	scrollIndex = scrollIndex - 1
	self.List.scrollBar:SetValue(scrollIndex * self.List.buttonHeight + 0.1)
	HybridScrollFrame_OnMouseWheel(self.List, 1, 0.1)  -- Neph: Why is this here?
end

function ScrollFrame:OnSizeChanged()
	-- called with self = scrollFrame.List
    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
	for _, button in pairs(self.buttons) do
		button:SetScript("OnClick", 
			function()
				local scrollFrame = self:GetParent()
				scrollFrame.onClick(button)
			end
		)
	end
    local old_value = self.scrollBar:GetValue()
    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value))
end

-- function NeedToKnowOptions.OnScrollFrameScrolled(self)
	-- local scrollPanel = self:GetParent()
	-- local fn = scrollPanel.Update
	-- if fn then fn(scrollPanel) end
-- end

function ScrollFrame:UpdateScrollItems(selectedItem, checkedItem)
	-- Called with self = scrollFrame
	local itemList = self.itemList
	local listFrame = self.List
	local buttons = listFrame.buttons
	HybridScrollFrame_Update(listFrame, #(itemList) * buttons[1]:GetHeight(), listFrame:GetHeight())

	local label
	for i, button in ipairs(buttons) do
		label = itemList[i + HybridScrollFrame_GetOffset(listFrame)]
		if label then
			button:Show()
			button.text:SetText(label)

			if label == selectedItem then
				local color = self.selected_color or ScrollFrame.selectedColor
				button.Bg:SetVertexColor(unpack(color))
			else
				local color = self.normal_color or ScrollFrame.normalColor
				button.Bg:SetVertexColor(unpack(color))
			end

			if label == checkedItem then
				button.Check:Show()
			else
				button.Check:Hide()
			end

			self.updateButton(button, label)
		else
			button:Hide()
		end
	end
end

--[[
function AppearancePanel:UpdateBarTextureScrollFrame()
	-- called by AppearancePanel:Update(), HybridScrollFrame_SetOffset()
	local scrollFrame = AppearancePanel.Textures
	local settings = NeedToKnow.ProfileSettings
	ScrollFrame.UpdateScrollItems(scrollFrame, settings.BarTexture, settings.BarTexture)
end

function AppearancePanel:UpdateBarFontScrollFrame()
	-- called by AppearancePanel:Update(), HybridScrollFrame_SetOffset()
	local scrollFrame = AppearancePanel.Fonts
	local settings = NeedToKnow.ProfileSettings
	ScrollFrame.UpdateScrollItems(scrollFrame, nil, settings.BarFont)
end

function AppearancePanel:OnClickScrollItem()
	-- Called with self = list button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	scrollFrame = self:GetParent():GetParent():GetParent()
	NeedToKnow.ProfileSettings[scrollFrame.variable] = self.text:GetText()
	NeedToKnow:Update()
	AppearancePanel:Update()
end
]]--

function NeedToKnowOptions.UpdateScrollPanel(panel, list, selected, checked)
	-- local Value = _G[panel:GetName().."Value"]
	-- Value:SetText(checked)

	local PanelList = panel.List
	local buttons = PanelList.buttons
	HybridScrollFrame_Update(PanelList, #(list) * buttons[1]:GetHeight() , PanelList:GetHeight())

	local numButtons = #buttons;
	local scrollOffset = HybridScrollFrame_GetOffset(PanelList);
	local label;
	for i = 1, numButtons do
		local idx = i + scrollOffset
		label = list[idx]
		if ( label ) then
			buttons[i]:Show();
			buttons[i].text:SetText(label);

			if ( label == checked ) then
				buttons[i].Check:Show();
			else
				buttons[i].Check:Hide();
			end
			if ( label == selected ) then
				local color = panel.selected_color
				if not color then color = NeedToKnowOptions.DefaultSelectedColor end
				buttons[i].Bg:SetVertexColor(unpack(color));
			else
				local color = panel.normal_color
				if not color then color = NeedToKnowOptions.DefaultNormalColor end
				buttons[i].Bg:SetVertexColor(unpack(color));
			end

			panel.configure(i, buttons[i], label)
		else
			buttons[i]:Hide();
		end
	end
end



