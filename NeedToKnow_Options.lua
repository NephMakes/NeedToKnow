-- Load after AppearancePanel.lua

local addonName, addonTable = ...

local trace = print

local GetActiveTalentGroup = _G.GetActiveSpecGroup

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
		btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar","Minimalist"))
	end
	self.Profiles.List:SetScript("OnSizeChanged", NeedToKnow.ScrollFrame.OnSizeChanged)
	self.Profiles.List.update = NeedToKnowOptions.UpdateProfileList
	self.Profiles.fnClick = function(self)
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

-----

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



