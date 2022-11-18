local addonName, addonTable = ...

local trace = print

NEEDTOKNOW.MAXBARSPACING = 24;
NEEDTOKNOW.MAXBARPADDING = 12;

local GetActiveTalentGroup = _G.GetActiveSpecGroup

local LSM = LibStub("LibSharedMedia-3.0", true);
local textureList = LSM:List("statusbar");
local fontList = LSM:List("font");
local NeedToKnow_OldProfile = nil;
local NeedToKnow_OldSettings = nil;

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
    table.remove(args,1)
    
    if not cmd then
        NeedToKnow.LockToggle();
    elseif ( cmd == NEEDTOKNOW.CMD_RESET ) then
        NeedToKnow.Reset();
    elseif ( cmd == NEEDTOKNOW.CMD_SHOW ) then
        NeedToKnow.Show(true);
    elseif ( cmd == NEEDTOKNOW.CMD_HIDE ) then
        NeedToKnow.Show(false);
    elseif ( cmd == NEEDTOKNOW.CMD_PROFILE ) then
        if args[1] then
            local profileName = table.concat(args, " ")
            local key = NeedToKnow.FindProfileByName( profileName )
            if key then
                NeedToKnow.ChangeProfile(key)
                NeedToKnowOptions.UIPanel_Profile_Update()
            else
                print("Could not find a profile named '",profileName,"'");
            end
        else
            local spec = GetActiveTalentGroup()
            local profile = NeedToKnow.CharSettings.Specs[spec]
            print("Current NeedToKnow profile is \""..profile.."\"") -- LOCME!
        end
    else
        print("Unknown NeedToKnow command",cmd)
    end    
end

function NeedToKnow.LockToggle(bLock)
    if nil == bLock then 
        if NeedToKnow.CharSettings["Locked"] then
            bLock = false;
        else
            bLock = true;
        end
    end

    NeedToKnow.Show(true);
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);

    if NeedToKnow.CharSettings["Locked"] ~= bLock then
        NeedToKnow.CharSettings["Locked"] = bLock;
        NeedToKnow.last_cast = {};
        NeedToKnow.Update();
    end
end


-- -----------------------------
-- INTERFACE OPTIONS PANEL: MAIN
-- -----------------------------

function NeedToKnowOptions.UIPanel_OnLoad(self)
    local panelName = self:GetName();
    local numberbarsLabel = _G[panelName.."NumberbarsLabel"];
    local fixedDurationLabel = _G[panelName.."FixedDurationLabel"];
    _G[panelName.."Version"]:SetText(NEEDTOKNOW.VERSION);
    _G[panelName.."SubText1"]:SetText(NEEDTOKNOW.UIPANEL_SUBTEXT1);
    numberbarsLabel:SetText(NEEDTOKNOW.UIPANEL_NUMBERBARS);
    numberbarsLabel:SetWidth(50);
    fixedDurationLabel:SetText(NEEDTOKNOW.UIPANEL_FIXEDDURATION);
    fixedDurationLabel:SetWidth(50);
end

function NeedToKnowOptions.UIPanel_OnShow()
    NeedToKnow_OldProfile = NeedToKnow.ProfileSettings;
    NeedToKnow_OldSettings = CopyTable(NeedToKnow.ProfileSettings);
    NeedToKnowOptions.UIPanel_Update();
end

function NeedToKnowOptions.UIPanel_Update()
    local panelName = "InterfaceOptionsNeedToKnowPanel";
    if not _G[panelName]:IsVisible() then return end

    local settings = NeedToKnow.ProfileSettings;

    for groupID = 1, settings.nGroups do
        NeedToKnowOptions.GroupEnableButton_Update(groupID);
        NeedToKnowOptions.NumberbarsWidget_Update(groupID);
        _G[panelName.."Group"..groupID.."FixedDurationBox"]:SetText(settings.Groups[groupID]["FixedDuration"] or "");
    end
end

function NeedToKnowOptions.GroupEnableButton_Update(groupID)
    local button = _G["InterfaceOptionsNeedToKnowPanelGroup"..groupID.."EnableButton"];
    button:SetChecked(NeedToKnow.ProfileSettings.Groups[groupID]["Enabled"]);
end

function NeedToKnowOptions.GroupEnableButton_OnClick(self)
    local groupID = self:GetParent():GetID();
    if ( self:GetChecked() ) then
        if groupID > NeedToKnow.ProfileSettings.nGroups then
            NeedToKnow.ProfileSettings.nGroups = groupID
        end
        NeedToKnow.ProfileSettings.Groups[groupID]["Enabled"] = true;
    else
        NeedToKnow.ProfileSettings.Groups[groupID]["Enabled"] = false;
    end
    NeedToKnow.Update();
end

function NeedToKnowOptions.NumberbarsWidget_Update(groupID)
    local widgetName = "InterfaceOptionsNeedToKnowPanelGroup"..groupID.."NumberbarsWidget";
    local text = _G[widgetName.."Text"];
    local leftButton = _G[widgetName.."LeftButton"];
    local rightButton = _G[widgetName.."RightButton"];
    local numberBars = NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"];
    text:SetText(numberBars);
    leftButton:Enable();
    rightButton:Enable();
    if ( numberBars == 1 ) then
        leftButton:Disable();
    elseif ( numberBars == NEEDTOKNOW.MAXBARS ) then
        rightButton:Disable();
    end
end

function NeedToKnowOptions.NumberbarsButton_OnClick(self, increment)
	local groupID = self:GetParent():GetParent():GetID();
	local oldNumber = NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"];
	if ( oldNumber == 1 ) and ( increment < 0 ) then 
		return;
	elseif ( oldNumber == NEEDTOKNOW.MAXBARS ) and ( increment > 0 ) then
		return;
	end
	NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"] = oldNumber + increment;

	local group = _G["NeedToKnow_Group"..groupID]
	group:Update()

	NeedToKnowOptions.NumberbarsWidget_Update(groupID);
end

function NeedToKnowOptions.FixedDurationEditBox_OnTextChanged(self)
    local enteredText = self:GetText();
    if enteredText == "" then
        NeedToKnow.ProfileSettings.Groups[self:GetParent():GetID()]["FixedDuration"] = nil;
    else
        NeedToKnow.ProfileSettings.Groups[self:GetParent():GetID()]["FixedDuration"] = enteredText;
    end
    NeedToKnow.Update();
end

function NeedToKnowOptions.Cancel()
    -- Can't copy the table here since ProfileSettings needs to point to the right place in
    -- NeedToKnow_Globals.Profiles or in NeedToKnow_CharSettings.Profiles
	-- FIXME: This is only restoring a small fraction of the total settings.
    NeedToKnow.RestoreTableFromCopy(NeedToKnow_OldProfile, NeedToKnow_OldSettings);
    -- FIXME: Close context menu if it's open; it may be referring to bar that doesn't exist
    NeedToKnow.Update();
end


-- -----------------------------------
-- INTERFACE OPTIONS PANEL: APPEARANCE
-- -----------------------------------

NeedToKnowOptions.DefaultSelectedColor =   { 0.1, 0.6, 0.8, 1 }
NeedToKnowOptions.DefaultNormalColor = { 0.7, 0.7, 0.7, 0 }

function NeedToKnowOptions.UIPanel_Appearance_OnLoad(self)
    self.name = NEEDTOKNOW.UIPANEL_APPEARANCE;
    self.parent = "NeedToKnow"
    self.default = NeedToKnow.ResetCharacter
    self.cancel = NeedToKnowOptions.Cancel
    -- need different way to handle cancel?  users might open appearance panel without opening main panel
    InterfaceOptions_AddCategory(self)
    
    local panelName = self:GetName()
    _G[panelName.."Version"]:SetText(NEEDTOKNOW.VERSION)
    _G[panelName.."SubText1"]:SetText(NEEDTOKNOW.UIPANEL_APPEARANCE_SUBTEXT1)

    self.Textures.fnClick = NeedToKnowOptions.OnClickTextureItem
    self.Textures.configure = function(i, btn, label) 
        btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar",label))
    end
    self.Textures.List.update = NeedToKnowOptions.UpdateBarTextureDropDown
    self.Textures.normal_color =  { 0.7, 0.7, 0.7, 1 }

    self.Fonts.fnClick = NeedToKnowOptions.OnClickFontItem
    self.Fonts.configure = function(i, btn, label) 
        local fontPath = NeedToKnow.LSM:Fetch("font",label)
        btn.text:SetFont(fontPath, 12)
        btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar","Minimalist"))
    end
    self.Fonts.List.update = NeedToKnowOptions.UpdateBarFontDropDown

    _G[panelName.."TexturesTitle"]:SetText("Texture:") -- LOCME
    _G[panelName.."FontsTitle"]:SetText("Font:") -- LOCME

end

function NeedToKnowOptions.UIPanel_Appearance_OnShow(self)
    NeedToKnowOptions.UIPanel_Appearance_Update();

    -- todo: Cache this? Update needs it to
    local idxCurrent = 1
    for i = 1, #textureList do
        if NeedToKnow.ProfileSettings["BarTexture"] == textureList[i] then
            idxCurrent = i
            break;
        end
    end
    local idxScroll = idxCurrent - 3
    if idxScroll < 0 then
        idxScroll = 0
    end
    self.Textures.List.scrollBar:SetValue(idxScroll * self.Textures.List.buttonHeight+0.1)
    HybridScrollFrame_OnMouseWheel(self.Textures.List, 1, 0.1);

    for i = 1, #fontList do
        if NeedToKnow.ProfileSettings["BarFont"] == fontList[i] then
            idxCurrent = i
            break;
        end
    end
    idxScroll = idxCurrent - 3
    if idxScroll < 0 then
        idxScroll = 0
    end
    self.Fonts.List.scrollBar:SetValue(idxScroll * self.Fonts.List.buttonHeight+0.1)
    HybridScrollFrame_OnMouseWheel(self.Fonts.List, 1, 0.1);
end

function NeedToKnowOptions.UIPanel_Appearance_Update()
    local panelName = "InterfaceOptionsNeedToKnowAppearancePanel";
    local panel = _G[panelName]
    if not panel or not panel:IsVisible() then return end
    
    local settings = NeedToKnow.ProfileSettings;
    local barSpacingSlider = _G[panelName.."BarSpacingSlider"];
    local barPaddingSlider = _G[panelName.."BarPaddingSlider"];
    local fontSizeSlider = _G[panelName.."FontSizeSlider"];
    local fontOutlineSlider = _G[panelName.."FontOutlineSlider"];

    -- Mimic the behavior of the context menu, and force the alpha to one in the swatch
    local r,g,b = unpack(settings.BkgdColor);
    _G[panelName.."BackgroundColorButtonNormalTexture"]:SetVertexColor(r,g,b,1);

    barSpacingSlider:SetMinMaxValues(0, NEEDTOKNOW.MAXBARSPACING);
    barSpacingSlider:SetValue(settings.BarSpacing);
    barSpacingSlider:SetValueStep(0.25);
    barSpacingSlider:SetObeyStepOnDrag(true)
    barPaddingSlider:SetMinMaxValues(0, NEEDTOKNOW.MAXBARPADDING);
    barPaddingSlider:SetValue(settings.BarPadding);
    barPaddingSlider:SetValueStep(0.25);
    barPaddingSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetMinMaxValues(5,20);
    fontSizeSlider:SetValue(settings.FontSize);
    fontSizeSlider:SetValueStep(0.5);
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontOutlineSlider:SetMinMaxValues(0,2);
    fontOutlineSlider:SetValue(settings.FontOutline);
    fontOutlineSlider:SetValueStep(1);
    fontOutlineSlider:SetObeyStepOnDrag(true)

    NeedToKnowOptions.UpdateBarTextureDropDown(_G[panelName.."Textures"]);
    NeedToKnowOptions.UpdateBarFontDropDown(_G[panelName.."Fonts"]);
end

-- -----------------------------------
-- INTERFACE OPTIONS PANEL: PROFILE
-- -----------------------------------

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

    self.Profiles.configure = function(i, btn, label) 
        btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar","Minimalist"))
    end
    self.Profiles.List.update = NeedToKnowOptions.UpdateProfileList
    self.Profiles.fnClick = function(self)
        local scrollPanel = self:GetParent():GetParent():GetParent()
        scrollPanel.curSel = self.text:GetText()
        NeedToKnowOptions.UpdateProfileList()
    end
end

function NeedToKnowOptions.UIPanel_Profile_OnShow(self)
    NeedToKnowOptions.RebuildProfileList(self)
    NeedToKnowOptions.UIPanel_Profile_Update();
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

function NeedToKnowOptions.OnClickTextureItem(self)
    NeedToKnow.ProfileSettings["BarTexture"] = self.text:GetText()
    NeedToKnow.Update()
    NeedToKnowOptions.UIPanel_Appearance_Update()
end

function NeedToKnowOptions.OnClickFontItem(self)
    NeedToKnow.ProfileSettings["BarFont"] = self.text:GetText()
    NeedToKnow.Update()
    NeedToKnowOptions.UIPanel_Appearance_Update()
end

function NeedToKnowOptions.ChooseColor(variable)
    info = UIDropDownMenu_CreateInfo();
    info.r, info.g, info.b, info.opacity = unpack(NeedToKnow.ProfileSettings[variable]);
    info.opacity = 1 - info.opacity;
    info.hasOpacity = true;
    info.opacityFunc = NeedToKnowOptions.SetOpacity;
    info.swatchFunc = NeedToKnowOptions.SetColor;
    info.cancelFunc = NeedToKnowOptions.CancelColor;
    info.extraInfo = variable;
    -- Not sure if I should leave this state around or not.  It seems like the
    -- correct strata to have it at anyway, so I'm going to leave it there for now
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG");
    OpenColorPicker(info);
end

function NeedToKnowOptions.SetColor()
    local variable = ColorPickerFrame.extraInfo;
    local r,g,b = ColorPickerFrame:GetColorRGB();
    NeedToKnow.ProfileSettings[variable][1] = r;
    NeedToKnow.ProfileSettings[variable][2] = g;
    NeedToKnow.ProfileSettings[variable][3] = b;
    NeedToKnow.Update();
    NeedToKnowOptions.UIPanel_Appearance_Update();
end

function NeedToKnowOptions.SetOpacity()
    local variable = ColorPickerFrame.extraInfo;
    NeedToKnow.ProfileSettings[variable][4] = 1 - OpacitySliderFrame:GetValue();
    NeedToKnow.Update();
    NeedToKnowOptions.UIPanel_Appearance_Update();
end

function NeedToKnowOptions.CancelColor(previousValues)
    if ( previousValues ) then
        local variable = ColorPickerFrame.extraInfo;
        NeedToKnow.ProfileSettings[variable] = {previousValues.r, previousValues.g, previousValues.b, previousValues.opacity};
        NeedToKnow.Update();
        NeedToKnowOptions.UIPanel_Appearance_Update();
    end
end

function NeedToKnowOptions.UIPanel_Appearance_OnSizeChanged(self)
    -- Despite my best efforts, the scroll bars insist on being outside the width of their
    local mid = self:GetWidth()/2 --+ _G[self:GetName().."TexturesListScrollBar"]:GetWidth()
    local textures = self.Textures
    local leftTextures = textures:GetLeft()
    if mid and mid > 0 and textures and leftTextures then
        local ofs = leftTextures - self:GetLeft()
        textures:SetWidth(mid - ofs)
    end
end

function NeedToKnowOptions.OnScrollFrameSized(self)
    local old_value = self.scrollBar:GetValue();
    local scrollFrame = self:GetParent();

    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
    --scrollFrame.Update(scrollFrame)

    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value));
    -- Work around a bug in HybridScrollFrame; it can't scroll by whole items (wow 4.1)
    --self.stepSize = self.buttons[1]:GetHeight()*.9
end

function NeedToKnowOptions.UpdateScrollPanel(panel, list, selected, checked)
    local Value = _G[panel:GetName().."Value"]
    Value:SetText(checked)

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

--function NeedToKnowOptions.OnScrollFrameScrolled(self)
    --local scrollPanel = self:GetParent()
    --local fn = scrollPanel.Update
    --if fn then fn(scrollPanel) end
--end
--
function NeedToKnowOptions.UpdateBarTextureDropDown()
    local scrollPanel = _G["InterfaceOptionsNeedToKnowAppearancePanelTextures"]
    NeedToKnowOptions.UpdateScrollPanel(scrollPanel, textureList, NeedToKnow.ProfileSettings.BarTexture, NeedToKnow.ProfileSettings.BarTexture)
end

function NeedToKnowOptions.UpdateBarFontDropDown()
    local scrollPanel = _G["InterfaceOptionsNeedToKnowAppearancePanelFonts"]
    NeedToKnowOptions.UpdateScrollPanel(scrollPanel, fontList, nil, NeedToKnow.ProfileSettings.BarFont)
end

