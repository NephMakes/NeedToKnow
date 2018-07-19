local trace = print

NEEDTOKNOW.MAXBARSPACING = 24;
NEEDTOKNOW.MAXBARPADDING = 12;

local GetActiveTalentGroup = _G.GetActiveSpecGroup

local LSM = LibStub("LibSharedMedia-3.0", true);
local textureList = LSM:List("statusbar");
local fontList = LSM:List("font");
local NeedToKnow_OldProfile = nil;
local NeedToKnow_OldSettings = nil;

NeedToKnowOptions = {}
NeedToKnowRMB = {}

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
    PlaySound("UChatScrollButton");

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
    NeedToKnow_OldProfile =NeedToKnow.ProfileSettings;
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
    NeedToKnow.Group_Update(groupID);
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
    barPaddingSlider:SetMinMaxValues(0, NEEDTOKNOW.MAXBARPADDING);
    barPaddingSlider:SetValue(settings.BarPadding);
    barPaddingSlider:SetValueStep(0.25);
    fontSizeSlider:SetMinMaxValues(5,20);
    fontSizeSlider:SetValue(settings.FontSize);
    fontSizeSlider:SetValueStep(0.5);
    fontOutlineSlider:SetMinMaxValues(0,2);
    fontOutlineSlider:SetValue(settings.FontOutline);
    fontOutlineSlider:SetValueStep(1);

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

-- --------
-- BAR GUI
-- --------

NeedToKnowRMB.CurrentBar = { groupID = 1, barID = 1 };        -- a dirty hack, i know.  

StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"] = {
    text = NEEDTOKNOW.CHOOSENAME_DIALOG,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    editBoxWidth = 300,
    maxLetters = 0,
    OnAccept = function(self)
        local text = self.editBox:GetText();
        local variable = self.variable;
        if ( nil ~= variable ) then
            NeedToKnowRMB.BarMenu_ChooseName(text, variable);
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"].OnAccept(self:GetParent())
        self:GetParent():Hide();
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide();
    end,
    OnHide = function(self)
    -- Removed for wow 3.3.5, it seems like there is a focu stack
    -- now that obsoletes this anyway.  If not, there isn't a 
    -- single ChatFrameEditBox anymore, there's ChatFrame1EditBox etc.
        -- if ( ChatFrameEditBox:IsVisible() ) then
        --    ChatFrameEditBox:SetFocus();
        -- end
        self.editBox:SetText("");
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
};

NeedToKnowRMB.BarMenu_MoreOptions = {
    { VariableName = "Enabled", MenuText = NEEDTOKNOW.BARMENU_ENABLE },
    { VariableName = "AuraName", MenuText = NEEDTOKNOW.BARMENU_CHOOSENAME, Type = "Dialog", DialogText = "CHOOSENAME_DIALOG" },
    { VariableName = "BuffOrDebuff", MenuText = NEEDTOKNOW.BARMENU_BUFFORDEBUFF, Type = "Submenu" },
    { VariableName = "Options", MenuText = "Settings", Type = "Submenu" },
    {},
    { VariableName = "TimeFormat", MenuText = NEEDTOKNOW.BARMENU_TIMEFORMAT, Type = "Submenu" }, 
    { VariableName = "Show", MenuText = NEEDTOKNOW.BARMENU_SHOW, Type = "Submenu" }, 
    { VariableName = "VisualCastTime", MenuText = NEEDTOKNOW.BARMENU_VISUALCASTTIME, Type = "Submenu" },
    { VariableName = "BlinkSettings", MenuText = "Blink Settings", Type = "Submenu" }, -- LOCME
    { VariableName = "BarColor", MenuText = NEEDTOKNOW.BARMENU_BARCOLOR, Type = "Color" },
    {},
    { VariableName = "ImportExport", MenuText = "Import/Export Bar Settings", Type = "Dialog", DialogText = "IMPORTEXPORT_DIALOG" },
}

NeedToKnowRMB.BarMenu_SubMenus = {
    -- the keys on this table need to match the settings variable names
    BuffOrDebuff = {
          { Setting = "HELPFUL", MenuText = NEEDTOKNOW.BARMENU_HELPFUL },
          { Setting = "HARMFUL", MenuText = NEEDTOKNOW.BARMENU_HARMFUL },
          { Setting = "TOTEM", MenuText = NEEDTOKNOW.BARMENU_TOTEM },
          { Setting = "CASTCD", MenuText = NEEDTOKNOW.BARMENU_CASTCD },
          { Setting = "BUFFCD", MenuText = NEEDTOKNOW.BARMENU_BUFFCD },
-- Now that Victory Rush adds a buff when you can use it, this confusing option is being removed.
-- The code that drives it remains so that any existing users' bars won't break.
--          { Setting = "USABLE", MenuText = NEEDTOKNOW.BARMENU_USABLE },
          { Setting = "EQUIPSLOT", MenuText = NEEDTOKNOW.BARMENU_EQUIPSLOT },
          { Setting = "POWER", MenuText = NEEDTOKNOW.BARMENU_POWER }
    },
    TimeFormat = {
          { Setting = "Fmt_SingleUnit", MenuText = NEEDTOKNOW.FMT_SINGLEUNIT },
          { Setting = "Fmt_TwoUnits", MenuText = NEEDTOKNOW.FMT_TWOUNITS },
          { Setting = "Fmt_Float", MenuText = NEEDTOKNOW.FMT_FLOAT },
    },
    Unit = {
        { Setting = "player", MenuText = NEEDTOKNOW.BARMENU_PLAYER }, 
        { Setting = "target", MenuText = NEEDTOKNOW.BARMENU_TARGET }, 
        { Setting = "targettarget", MenuText = NEEDTOKNOW.BARMENU_TARGETTARGET }, 
        { Setting = "focus", MenuText = NEEDTOKNOW.BARMENU_FOCUS }, 
        { Setting = "pet", MenuText = NEEDTOKNOW.BARMENU_PET }, 
        { Setting = "vehicle", MenuText = NEEDTOKNOW.BARMENU_VEHICLE }, 
        { Setting = "lastraid", MenuText = NEEDTOKNOW.BARMENU_LAST_RAID },
    },
    DebuffUnit = {
        { Setting = "player", MenuText = NEEDTOKNOW.BARMENU_PLAYER }, 
        { Setting = "target", MenuText = NEEDTOKNOW.BARMENU_TARGET }, 
        { Setting = "targettarget", MenuText = NEEDTOKNOW.BARMENU_TARGETTARGET }, 
        { Setting = "focus", MenuText = NEEDTOKNOW.BARMENU_FOCUS }, 
        { Setting = "pet", MenuText = NEEDTOKNOW.BARMENU_PET }, 
        { Setting = "vehicle", MenuText = NEEDTOKNOW.BARMENU_VEHICLE },
    },
    Opt_HELPFUL = {
      { VariableName = "Unit", MenuText = NEEDTOKNOW.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "bDetectExtends", MenuText = "Track duration increases" }, -- LOCME
      { VariableName = "OnlyMine", MenuText = NEEDTOKNOW.BARMENU_ONLYMINE },
      { VariableName = "show_all_stacks", MenuText = "Sum stacks from all casters" },
    },
    Opt_HARMFUL = {
      { VariableName = "DebuffUnit", MenuText = NEEDTOKNOW.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "bDetectExtends", MenuText = "Track duration increases" }, -- LOCME
      { VariableName = "OnlyMine", MenuText = NEEDTOKNOW.BARMENU_ONLYMINE },
      { VariableName = "show_all_stacks", MenuText = "Sum stacks from all casters" },
    },
    Opt_TOTEM = {},
    Opt_CASTCD = 
    {
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
        { VariableName = "show_charges", MenuText = "Show first and last charge CD" }, -- LOCME
    },
    Opt_EQUIPSLOT = 
    {
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
    },
    Opt_POWER = 
    {
      { VariableName = "Unit", MenuText = NEEDTOKNOW.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "power_sole", MenuText = "Only Show When Primary" }, -- LOCME
    },
    Opt_BUFFCD = 
    {
        { VariableName = "buffcd_duration", MenuText = "Cooldown duration...", Type = "Dialog", DialogText = "BUFFCD_DURATION_DIALOG", Numeric=true },
        { VariableName = "buffcd_reset_spells", MenuText = "Reset on buff...", Type = "Dialog", DialogText = "BUFFCD_RESET_DIALOG" },
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
    },
    Opt_USABLE =
    {
        { VariableName = "usable_duration", MenuText = "Usable duration...",  Type = "Dialog", DialogText = "USABLE_DURATION_DIALOG", Numeric=true },
        { VariableName = "append_usable", MenuText = "Append \"Usable\"" }, -- LOCME
    },
    EquipmentSlotList =
    {
        { Setting = "1", MenuText = NEEDTOKNOW.ITEM_NAMES[1] },
        { Setting = "2", MenuText = NEEDTOKNOW.ITEM_NAMES[2] },
        { Setting = "3", MenuText = NEEDTOKNOW.ITEM_NAMES[3] },
        { Setting = "4", MenuText = NEEDTOKNOW.ITEM_NAMES[4] },
        { Setting = "5", MenuText = NEEDTOKNOW.ITEM_NAMES[5] },
        { Setting = "6", MenuText = NEEDTOKNOW.ITEM_NAMES[6] },
        { Setting = "7", MenuText = NEEDTOKNOW.ITEM_NAMES[7] },
        { Setting = "8", MenuText = NEEDTOKNOW.ITEM_NAMES[8] },
        { Setting = "9", MenuText = NEEDTOKNOW.ITEM_NAMES[9] },
        { Setting = "10", MenuText = NEEDTOKNOW.ITEM_NAMES[10] },
        { Setting = "11", MenuText = NEEDTOKNOW.ITEM_NAMES[11] },
        { Setting = "12", MenuText = NEEDTOKNOW.ITEM_NAMES[12] },
        { Setting = "13", MenuText = NEEDTOKNOW.ITEM_NAMES[13] },
        { Setting = "14", MenuText = NEEDTOKNOW.ITEM_NAMES[14] },
        { Setting = "15", MenuText = NEEDTOKNOW.ITEM_NAMES[15] },
        { Setting = "16", MenuText = NEEDTOKNOW.ITEM_NAMES[16] },
        { Setting = "17", MenuText = NEEDTOKNOW.ITEM_NAMES[17] },
        { Setting = "18", MenuText = NEEDTOKNOW.ITEM_NAMES[18] },
        { Setting = "19", MenuText = NEEDTOKNOW.ITEM_NAMES[19] },
    },
    PowerTypeList =
    {
    },
    VisualCastTime = {
        { VariableName = "vct_enabled", MenuText = NEEDTOKNOW.BARMENU_VCT_ENABLE },
        { VariableName = "vct_color", MenuText = NEEDTOKNOW.BARMENU_VCT_COLOR, Type = "Color" },
        { VariableName = "vct_spell", MenuText = NEEDTOKNOW.BARMENU_VCT_SPELL, Type = "Dialog", DialogText = "CHOOSE_VCT_SPELL_DIALOG" },
        { VariableName = "vct_extra", MenuText = NEEDTOKNOW.BARMENU_VCT_EXTRA, Type = "Dialog", DialogText = "CHOOSE_VCT_EXTRA_DIALOG", Numeric=true },
    },
    Show = {
        { VariableName = "show_icon",      MenuText = NEEDTOKNOW.BARMENU_SHOW_ICON },
        { VariableName = "show_text",      MenuText = NEEDTOKNOW.BARMENU_SHOW_TEXT },
        { VariableName = "show_count",     MenuText = NEEDTOKNOW.BARMENU_SHOW_COUNT },
        { VariableName = "show_time",      MenuText = NEEDTOKNOW.BARMENU_SHOW_TIME },
        { VariableName = "show_spark",     MenuText = NEEDTOKNOW.BARMENU_SHOW_SPARK },
        { VariableName = "show_mypip",     MenuText = NEEDTOKNOW.BARMENU_SHOW_MYPIP },
        { VariableName = "show_ttn1",      MenuText = NEEDTOKNOW.BARMENU_SHOW_TTN1 },
        { VariableName = "show_ttn2",      MenuText = NEEDTOKNOW.BARMENU_SHOW_TTN2 },
        { VariableName = "show_ttn3",      MenuText = NEEDTOKNOW.BARMENU_SHOW_TTN3 },
        { VariableName = "show_text_user", MenuText = NEEDTOKNOW.BARMENU_SHOW_TEXT_USER, Type = "Dialog", DialogText = "CHOOSE_OVERRIDE_TEXT", Checked = function(settings) return "" ~= settings.show_text_user end },
    },
    BlinkSettings = {
        { VariableName = "blink_enabled", MenuText = NEEDTOKNOW.BARMENU_VCT_ENABLE },
        { VariableName = "blink_label", MenuText = "Bar text while blinking...", Type = "Dialog", DialogText="CHOOSE_BLINK_TITLE_DIALOG" }, 
        { VariableName = "MissingBlink", MenuText = "Bar color when blinking...", Type = "Color" }, -- LOCME
        { VariableName = "blink_ooc", MenuText = "Blink out of combat" }, -- LOCME
        { VariableName = "blink_boss", MenuText = "Blink only for bosses" }, -- LOCME
    },
};

NeedToKnowRMB.VariableRedirects = 
{
  DebuffUnit = "Unit",
  EquipmentSlotList = "AuraName",
  PowerTypeList = "AuraName",
}

function NeedToKnowRMB.ShowMenu(bar)
    NeedToKnowRMB.CurrentBar["barID"] = bar:GetID();
    NeedToKnowRMB.CurrentBar["groupID"] = bar:GetParent():GetID();
    if not NeedToKnowRMB.DropDown then
        NeedToKnowRMB.DropDown = CreateFrame("Frame", "NeedToKnowDropDown", nil, "NeedToKnow_DropDownTemplate") 
    end

    -- There's no OpenDropDownMenu that forces it to show in the new place,
    -- so we have to check if the first Toggle opened or closed it
    ToggleDropDownMenu(1, nil, NeedToKnowRMB.DropDown, "cursor", 0, 0);
    if not DropDownList1:IsShown() then
        ToggleDropDownMenu(1, nil, NeedToKnowRMB.DropDown, "cursor", 0, 0);
    end
end

function NeedToKnowRMB.BarMenu_AddButton(barSettings, i_desc, i_parent)
    info = UIDropDownMenu_CreateInfo();
    local item_type = i_desc["Type"];
    info.text = i_desc["MenuText"];
    local varSettings
    if ( nil ~= i_desc["Setting"]) then
        item_type = "SetVar"
        local v = NeedToKnowRMB.VariableRedirects[i_parent] or i_parent
        varSettings = barSettings[v]
    else
        info.value = i_desc["VariableName"];
        varSettings = barSettings[info.value];
    end
    
    if ( not varSettings and (item_type == "Check" or item_type == "Color") ) then
        print (string.format("NTK: Could not find %s in", info.value), barSettings); 
        return
    end
    
    info.hasArrow = false;
    local b = i_desc["Checked"]
    if b then
        if type(b) == "function" then
            info.checked = b(barSettings)
        else
            info.checked = b
        end
    end

    info.keepShownOnClick = true;
    info.notCheckable = false; -- indent everything
    info.hideUnCheck = true; -- but hide the empty checkbox/radio

    if ( not item_type and not text and not info.value ) then
        info.func = NeedToKnowRMB.BarMenu_IgnoreToggle;
        info.disabled = true;
    elseif ( nil == item_type or item_type == "Check" ) then
        info.func = NeedToKnowRMB.BarMenu_ToggleSetting;
        info.checked = (nil ~= varSettings and varSettings);
        info.hideUnCheck = nil;
        info.isNotRadio = true;
    elseif ( item_type == "SetVar" ) then
        info.func = NeedToKnowRMB.BarMenu_ChooseSetting;
        info.value = i_desc["Setting"];
        info.checked = (varSettings == info.value);
        info.hideUnCheck = nil;
        info.keepShownOnClick = false;
    elseif ( item_type == "Submenu" ) then
        info.hasArrow = true;
        info.isNotRadio = true;
        info.func = NeedToKnowRMB.BarMenu_IgnoreToggle;
    elseif ( item_type == "Dialog" ) then
        info.func = NeedToKnowRMB.BarMenu_ShowNameDialog;
        info.keepShownOnClick = false;
        info.value = {variable = i_desc.VariableName, text = i_desc.DialogText, numeric = i_desc.Numeric };
    elseif ( item_type == "Color" ) then
        info.hasColorSwatch = 1;
        info.hasOpacity = true;
        info.r = varSettings.r;
        info.g = varSettings.g;
        info.b = varSettings.b;
        info.opacity = 1 - varSettings.a;
        info.swatchFunc = NeedToKnowRMB.BarMenu_SetColor;
        info.opacityFunc = NeedToKnowRMB.BarMenu_SetOpacity;
        info.cancelFunc = NeedToKnowRMB.BarMenu_CancelColor;

        info.func = UIDropDownMenuButton_OpenColorPicker;
        info.keepShownOnClick = false;
    end
  
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
    
    -- Code to get the button copied from UIDropDownMenu_AddButton
    local level = UIDROPDOWNMENU_MENU_LEVEL;
    local listFrame = _G["DropDownList"..level];
    local index = listFrame and (listFrame.numButtons) or 1;
    local listFrameName = listFrame:GetName();
    local buttonName = listFrameName.."Button"..index;
    if ( item_type == "Color" ) then
        -- Sadly, extraInfo isn't a field propogated to the button
        local button = _G[buttonName];
        button.extraInfo = info.value;
    end
    if ( info.hideUnCheck ) then
        local checkBG = _G[buttonName.."UnCheck"];
        checkBG:Hide();
    end
end

function NeedToKnowRMB.BarMenu_Initialize()
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local barSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID];

    if ( barSettings.MissingBlink.a == 0 ) then
        barSettings.blink_enabled = false;
    end
    NeedToKnowRMB.BarMenu_SubMenus.Options = NeedToKnowRMB.BarMenu_SubMenus["Opt_"..barSettings.BuffOrDebuff];
   
    if ( UIDROPDOWNMENU_MENU_LEVEL > 1 ) then
        if ( UIDROPDOWNMENU_MENU_VALUE == "VisualCastTime" ) then
            -- Create a summary title for the visual cast time submenu
            local title = "";
            if ( barSettings.vct_spell and "" ~= barSettings.vct_spell ) then
                title = title .. barSettings.vct_spell;
            end
            local fExtra = tonumber(barSettings.vct_extra);
            if ( fExtra and fExtra > 0 ) then
                if ("" ~= title) then
                    title = title .. " + ";
                end
                title = title .. string.format("%0.1fs", fExtra);
            end
            if ( "" ~= title ) then
                local info = UIDropDownMenu_CreateInfo();
                info.text = title;
                info.isTitle = true;
                info.notCheckable = true; -- unindent
                UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
            end
        end
        
        local subMenus = NeedToKnowRMB.BarMenu_SubMenus;
        for index, value in ipairs(subMenus[UIDROPDOWNMENU_MENU_VALUE]) do
            NeedToKnowRMB.BarMenu_AddButton(barSettings, value, UIDROPDOWNMENU_MENU_VALUE);
        end

        if ( false == barSettings.OnlyMine and UIDROPDOWNMENU_MENU_LEVEL == 2 ) then
            NeedToKnowRMB.BarMenu_UncheckAndDisable(2, "bDetectExtends", false);
        end
        return;
    end
    
    -- show name
    if ( barSettings.AuraName ) and ( barSettings.AuraName ~= "" ) then
        local info = UIDropDownMenu_CreateInfo();
        info.text = NeedToKnow.PrettyName(barSettings);
        info.isTitle = true;
        info.notCheckable = true; --unindent
        UIDropDownMenu_AddButton(info);
    end

    local moreOptions = NeedToKnowRMB.BarMenu_MoreOptions;
    for index, value in ipairs(moreOptions) do
        NeedToKnowRMB.BarMenu_AddButton(barSettings, moreOptions[index]);
    end

    NeedToKnowRMB.BarMenu_UpdateSettings(barSettings);
end

function NeedToKnowRMB.BarMenu_IgnoreToggle(self, a1, a2, checked)
    local button = NeedToKnowRMB.BarMenu_GetItem(NeedToKnowRMB.BarMenu_GetItemLevel(self), self.value);
    if ( button ) then
        local checkName = button:GetName() .. "Check";
        _G[checkName]:Hide();
        button.checked = false;
    end
end

function NeedToKnowRMB.BarMenu_ToggleSetting(self, a1, a2, checked)
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local barSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID];
    barSettings[self.value] = self.checked;
    local level = NeedToKnowRMB.BarMenu_GetItemLevel(self);
    
    if ( self.value == "OnlyMine" ) then 
        if ( false == self.checked ) then
            NeedToKnowRMB.BarMenu_UncheckAndDisable(level, "bDetectExtends", false);
        else
            NeedToKnowRMB.BarMenu_EnableItem(level, "bDetectExtends");
            NeedToKnowRMB.BarMenu_CheckItem(level, "show_all_stacks", false);
        end
    elseif ( self.value == "blink_enabled" ) then
        if ( true == self.checked and barSettings.MissingBlink.a == 0 ) then
            barSettings.MissingBlink.a = 0.5
        end
    elseif ( self.value == "show_all_stacks" ) then
        if ( true == self.checked ) then
            NeedToKnowRMB.BarMenu_CheckItem(level, "OnlyMine", false);
        end
    end
    NeedToKnow.Bar_Update(groupID, barID);
end

function NeedToKnowRMB.BarMenu_GetItemLevel(i_button)
    local path = i_button:GetName();
    local levelStr = path:match("%d+");
    return tonumber(levelStr);
end

function NeedToKnowRMB.BarMenu_GetItem(i_level, i_valueName)
    local listFrame = _G["DropDownList"..i_level];
    local listFrameName = listFrame:GetName();
    local n = listFrame.numButtons;
    for index=1,n do
        local button = _G[listFrameName.."Button"..index];
        local txt;
        if ( type(button.value) == "table" ) then
            txt = button.value.variable;
        else
            txt = button.value;
        end
        if ( txt == i_valueName ) then
            return button;
        end
    end
    return nil;
end

function NeedToKnowRMB.BarMenu_CheckItem(i_level, i_valueName, i_bCheck)
    local button = NeedToKnowRMB.BarMenu_GetItem(i_level, i_valueName);
    if ( button ) then
        local checkName = button:GetName() .. "Check";
        local check = _G[checkName];
        if ( i_bCheck ) then
            check:Show();
            button.checked = true;
        else
            check:Hide();
            button.checked = false;
        end
        NeedToKnowRMB.BarMenu_ToggleSetting(button);
    end
end

function NeedToKnowRMB.BarMenu_EnableItem(i_level, i_valueName)
    local button = NeedToKnowRMB.BarMenu_GetItem(i_level, i_valueName)
    if ( button ) then
        button:Enable();
    end
end

function NeedToKnowRMB.BarMenu_UncheckAndDisable(i_level, i_valueName)
    local button = NeedToKnowRMB.BarMenu_GetItem(i_level, i_valueName);
    if ( button ) then
        NeedToKnowRMB.BarMenu_CheckItem(i_level, i_valueName, false);
        button:Disable();
    end
end

function NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
    local type = barSettings.BuffOrDebuff;
    
    -- Set up the options submenu to the corrent name and contents
    local Opt = NeedToKnowRMB.BarMenu_SubMenus["Opt_"..type];
    if ( not Opt ) then Opt = {} end
    NeedToKnowRMB.BarMenu_SubMenus.Options = Opt;
    local button = NeedToKnowRMB.BarMenu_GetItem(1, "Options");
    if button then
        local arrow = _G[button:GetName().."ExpandArrow"]
        local lbl = ""
        if #Opt == 0 then
            lbl = lbl .. "No "
            button:Disable();
            arrow:Hide();
        else
            button:Enable();
            arrow:Show();
        end
        -- LOCME
        lbl = lbl .. NEEDTOKNOW["BARMENU_"..type].. " Settings";
        button:SetText(lbl);
    end

    -- Set up the aura name menu option to behave the right way
    if ( type == "EQUIPSLOT" ) then
        button = NeedToKnowRMB.BarMenu_GetItem(1, "AuraName");
        if ( button ) then
            button.oldvalue = button.value
        else
            button = NeedToKnowRMB.BarMenu_GetItem(1, "PowerTypeList") 
        end
        if ( button ) then
            local arrow = _G[button:GetName().."ExpandArrow"]
            arrow:Show();
            button.hasArrow = true
            button.value = "EquipmentSlotList"
            button:SetText(NEEDTOKNOW.BARMENU_CHOOSESLOT)
            -- TODO: really should disable the button press verb somehow
        end
    elseif ( type == "POWER" ) then
        button = NeedToKnowRMB.BarMenu_GetItem(1, "AuraName");
        if ( button ) then
          button.oldvalue = button.value
        else
            button = NeedToKnowRMB.BarMenu_GetItem(1, "EquipmentSlotList") 
        end
        if ( button ) then
            local arrow = _G[button:GetName().."ExpandArrow"]
            arrow:Show();
            button.hasArrow = true
            button.value = "PowerTypeList"
            button:SetText(NEEDTOKNOW.BARMENU_CHOOSEPOWER)
            -- TODO: really should disable the button press verb somehow
        end
    else
        button = NeedToKnowRMB.BarMenu_GetItem(1, "EquipmentSlotList");
        if not button then button = NeedToKnowRMB.BarMenu_GetItem(1, "PowerTypeList") end
        if ( button ) then
            local arrow = _G[button:GetName().."ExpandArrow"]
            arrow:Hide();
            button.hasArrow = false
            if button.oldvalue then button.value = button.oldvalue end
            button:SetText(NEEDTOKNOW.BARMENU_CHOOSENAME)
        end
    end
end

function NeedToKnowRMB.BarMenu_ChooseSetting(self, a1, a2, checked)
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local barSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID]
    local v = NeedToKnowRMB.VariableRedirects[UIDROPDOWNMENU_MENU_VALUE] or UIDROPDOWNMENU_MENU_VALUE
    barSettings[v] = self.value;
    NeedToKnow.Bar_Update(groupID, barID);
    
    if ( v == "BuffOrDebuff" ) then
        NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
    end
end

-- TODO: There has to be a better way to do this, this has pretty bad user feel
function NeedToKnowRMB.EditBox_Numeric_OnTextChanged(self, isUserInput)
    if ( isUserInput ) then
        local txt = self:GetText();
        local culled = txt:gsub("[^0-9.]",""); -- Remove non-digits
        local iPeriod = culled:find("[.]");
        if ( nil ~= iPeriod ) then
            local before = culled:sub(1, iPeriod);
            local after = string.gsub( culled:sub(iPeriod+1), "[.]", "" );
            culled = before .. after;
        end
        if ( txt ~= culled ) then
            self:SetText(culled);
        end
    end
    
    if ( NeedToKnowRMB.EditBox_Original_OnTextChanged ) then
        NeedToKnowRMB.EditBox_Original_OnTextChanged(self, isUserInput);
    end
end

NeedToKnowIE = {}
function NeedToKnowIE.CombineKeyValue(key,value)
    local vClean = value
    if type(vClean) == "string" and value:byte(1) ~= 123 then
        if (tostring(tonumber(vClean)) == vClean) or vClean == "true" or vClean == "false" then
            vClean = '"' .. vClean .. '"'
        elseif (vClean:find(",") or vClean:find("}") or vClean:byte(1) == 34) then
            vClean = '"' .. tostring(value):gsub('"', '\\"') .. '"'
        end
    end

    if key then
        -- not possible for key to contain = right now, so we don't have to sanitize it
        return key .. "=" .. tostring(vClean)
    else
        return vClean
    end
end

function NeedToKnowIE.TableToString(v)
    local i = 1
    local ret= "{"
    for index, value in pairs(v) do
        if i ~= 1 then
            ret = ret .. ","
        end
        local k
        if index ~= i then
            k = NEEDTOKNOW.SHORTENINGS[index] or index 
        end
        if  type(value) == "table" then
            value = NeedToKnowIE.TableToString(value)
        end
        ret = ret .. NeedToKnowIE.CombineKeyValue(k, value)
        i = i+1;
    end
    ret = ret .. "}"
    return ret
end

function NeedToKnowIE.ExportBarSettingsToString(barSettings)
    local pruned = CopyTable(barSettings)
    NeedToKnow.RemoveDefaultValues(pruned, NEEDTOKNOW.BAR_DEFAULTS)
    return 'bv1:' .. NeedToKnowIE.TableToString(pruned);
end

--[[ Test Cases
/script MemberDump( NeedToKnowIE.StringToTable( '{a,b,c}' ) )
    members
      1 a
      2 b
      3 c

/script MemberDump( NeedToKnowIE.StringToTable( '{Aura=Frost Fever,Unit=target,Clr={g=0.4471,r=0.2784},Typ=HARMFUL}' ) )
    members
      BuffOrDebuff HARMFUL
      BarColor table: 216B04C0
      |  g 0.4471
      |  r 0.2784
      AuraName Frost Fever
      Unit target

/script MemberDump( NeedToKnowIE.StringToTable( '{"a","b","c"}' ) )
    members
      1 a
      2 b
      3 c

/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c","{c={d}}"}' ) )
    members
      1 a,b
      2 b=c
      3 {c={d}}

/script local t = {'\\",\'','}'} local p = NeedToKnowIE.TableToString(t) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {"\\",'","}"}
    members
      1 \",'
      2 }

/script local p = NeedToKnowIE.TableToString( {} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {}
    members

    I don't think this can come up, but might as well be robust
/script local p = NeedToKnowIE.TableToString( {{{}}} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {{{}}}
    members
      1 table: 216A2428
      |  1 table: 216A0510

    I don't think this can come up, but might as well be robust
/script local p = NeedToKnowIE.TableToString( {{{"a"}}} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {{{a}}}
    members
      1 table: 27D68048
      |  1 table: 27D68098
      |  |  1 a

    User Error                                   1234567890123456789012
/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c","{c={d}}",{' ) )
    Unexpected end of string
    nil

    User Error                                   1234567890123456789012
/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c""{c={d}}"' ) )
    Illegal quote at 12
    nil
]]--
function NeedToKnowIE.StringToTable(text, ofs)
    local cur = ofs or 1

    if text:byte(cur+1) == 125 then
        return {},cur+1
    end

    local i = 0
    local ret = {}
    while text:byte(cur) ~= 125 do
        if not text:byte(cur) then
            print("Unexpected end of string")
            return nil,nil
        end
        i = i + 1
        cur = cur + 1 -- advance past the { or ,
        local hasKey, eq, delim
        -- If it's not a quote or a {, it should be a key+equals or value+delimeter
        if text:byte(cur) ~= 34 and text:byte(cur) ~= 123 then 
            eq = text:find("=", cur)
            local comma = text:find(",", cur) 
            delim = text:find("}", cur) or comma
            if comma and delim > comma then
                delim = comma 
            end

            if not delim then 
                print("Unexpected end of string")
                return nil, nil
            end
            hasKey = (eq and eq < delim)
        end

        local k,v
        if not hasKey then
            k = i
        else
            k = text:sub(cur,eq-1)
            k = NEEDTOKNOW.LENGTHENINGS[k] or k
            if not k or k == "" then
                print("Error parsing key at", cur)
                return nil,nil
            end
            cur = eq+1
        end

        if not text:byte(cur) then 
            print("Unexpected end of string")
            return nil,nil
        elseif text:byte(cur) == 123 then -- '{'
            v, cur = NeedToKnowIE.StringToTable(text, cur)
            if not v then return nil,nil end
            cur = cur+1
        else
            if text:byte(cur) == 34 then -- '"'
                -- find the closing quote
                local endq = cur
                delim=nil
                while not delim do
                    endq = text:find('"', endq+1)
                    if not endq then
                        print("Could not find closing quote begun at", cur)
                        return nil, nil
                    end
                    if text:byte(endq-1) ~= 92 then -- \
                        delim = endq+1
                        if text:byte(delim) ~= 125 and text:byte(delim) ~= 44 then
                            print("Illegal quote at", endq)
                            return nil, nil
                        end
                    end
                end
                v = text:sub(cur+1,delim-2)
                v = gsub(v, '\\"', '"')
            else
                v = text:sub(cur,delim-1)
                local n = tonumber(v)
                if tostring(n) == v  then
                    v = n
                elseif v == "true" then
                    v = true
                elseif v == "false" then
                    v = false
                end
            end
            if v==nil or v == "" then
                print("Error parsing value at",cur)
            end
            cur = delim
        end

        ret[k] = v
    end

    return ret,cur
end

function NeedToKnowIE.ImportBarSettingsFromString(text, bars, barID)
    local pruned
    if text and text ~= "" then
        local ver, packed = text:match("bv(%d+):(.*)")
        if not ver then
            print("Could not find bar settings header")
        elseif not packed then
            print("Could not find bar settings")
        end
        pruned = NeedToKnowIE.StringToTable(packed)
    else
        pruned = {}
    end

    if pruned then
        NeedToKnow.AddDefaultsToTable(pruned, NEEDTOKNOW.BAR_DEFAULTS)
        bars[barID] = pruned
    end
end

function NeedToKnowRMB.BarMenu_ShowNameDialog(self, a1, a2, checked)
    if not self.value.text or not NEEDTOKNOW[self.value.text] then return end

    StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"].text = NEEDTOKNOW[self.value.text];
    local dialog = StaticPopup_Show("NEEDTOKNOW.CHOOSENAME_DIALOG");
    dialog.variable = self.value.variable;

    local edit = _G[dialog:GetName().."EditBox"];
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local barSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID];

    local numeric = self.value.numeric or false;
    -- TODO: There has to be a better way to do this, this has pretty bad user  feel
    if ( nil == NeedToKnowRMB.EditBox_Original_OnTextChanged ) then
        NeedToKnowRMB.EditBox_Original_OnTextChanged = edit:GetScript("OnTextChanged");
    end
    if ( numeric ) then
        edit:SetScript("OnTextChanged", NeedToKnowRMB.EditBox_Numeric_OnTextChanged);
    else
        edit:SetScript("OnTextChanged", NeedToKnowRMB.EditBox_Original_OnTextChanged);
    end
    
    edit:SetFocus();
    if ( dialog.variable ~= "ImportExport" ) then
        edit:SetText( barSettings[dialog.variable] );
    else
        edit:SetText( NeedToKnowIE.ExportBarSettingsToString(barSettings) );
        edit:HighlightText();
    end
end

function NeedToKnowRMB.BarMenu_ChooseName(text, variable)
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local barSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID];
    if ( variable ~= "ImportExport" ) then
        barSettings[variable] = text;
    else
        NeedToKnowIE.ImportBarSettingsFromString(text, NeedToKnow.ProfileSettings.Groups[groupID]["Bars"], barID);
    end

    NeedToKnow.Bar_Update(groupID, barID);
end

function MemberDump(v, bIndex, filter, indent, recurse)
    if v == nil then 
        print("nil")
        return
    elseif type(v) == "table" then
		if not indent then 
			indent = " " 
			print("members")
		end
		for index, value in pairs(v) do
			if (not filter) or (type(index) == "string" and index:find(filter)) then
				print(indent, index, value);
				if (recurse and type(value) == "table") then 
				    MemberDump(value, nil, nil, indent.." | ",true) 
				end
			end
		end
    else
        if not indent then indent = "" end
        print(indent,v)
    end
	
	if type(v) == "table" or not recurse then
		local mt = getmetatable(v)
		if ( mt ) then
			print("metatable")
			for index, value in pairs(mt) do
				if (not filter) or (type(index) == "string" and index:find(filter)) then
					print(indent, index, value);
				end
			end
			if ( mt.__index and bIndex) then
				print("__index")
				for index, value in pairs(mt.__index) do
					if (not filter) or (type(index) == "string" and index:find(filter)) then
						print(indent, index, value);
					end
				end
			end
		end
    end
end

function NeedToKnowRMB.BarMenu_SetColor()
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local varSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID][ColorPickerFrame.extraInfo];

    varSettings.r,varSettings.g,varSettings.b = ColorPickerFrame:GetColorRGB();
    NeedToKnow.Bar_Update(groupID, barID);
end

function NeedToKnowRMB.BarMenu_SetOpacity()
    local groupID = NeedToKnowRMB.CurrentBar["groupID"];
    local barID = NeedToKnowRMB.CurrentBar["barID"];
    local varSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID][ColorPickerFrame.extraInfo];

    varSettings.a = 1 - OpacitySliderFrame:GetValue();
    NeedToKnow.Bar_Update(groupID, barID);
end

function NeedToKnowRMB.BarMenu_CancelColor(previousValues)
    if ( previousValues.r ) then
        local groupID = NeedToKnowRMB.CurrentBar["groupID"];
        local barID = NeedToKnowRMB.CurrentBar["barID"];
        local varSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID][ColorPickerFrame.extraInfo];

        varSettings.r = previousValues.r;
        varSettings.g = previousValues.g;
        varSettings.b = previousValues.b;
        varSettings.a = 1 - previousValues.opacity;
        NeedToKnow.Bar_Update(groupID, barID);
    end
end


-- -------------
-- RESIZE BUTTON
-- -------------

function NeedToKnow.Resizebutton_OnEnter(self)
    local tooltip = _G["GameTooltip"];
    GameTooltip_SetDefaultAnchor(tooltip, self);
    tooltip:AddLine(NEEDTOKNOW.RESIZE_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
    tooltip:Show();
end

function NeedToKnow.StartSizing(self, button)
    local group = self:GetParent();
    local groupID = self:GetParent():GetID();
    group.oldScale = group:GetScale();
    group.oldX = group:GetLeft();
    group.oldY = group:GetTop();
    --    group:ClearAllPoints();
    --    group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", group.oldX, group.oldY);
    self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent);
    self.oldWidth = _G[group:GetName().."Bar1"]:GetWidth();
    self:SetScript("OnUpdate", NeedToKnow.Sizing_OnUpdate);
end

function NeedToKnow.Sizing_OnUpdate(self)
    local uiScale = UIParent:GetScale();
    local cursorX, cursorY = GetCursorPosition(UIParent);
    local group = self:GetParent();
    local groupID = self:GetParent():GetID();

    -- calculate & set new scale
    local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale) ;
    local newScale = max(0.25, newYScale);
    
    -- clamp the scale so the group is a whole number of pixels tall
    local bar1 = _G[group:GetName().."Bar1"]
    local barHeight = bar1:GetHeight()
    local newHeight = newScale * barHeight
    newHeight = math.floor(newHeight + 0.0002)
    newScale = newHeight / barHeight
    group:SetScale(newScale);

    -- set new frame coords to keep same on-screen position
    local newX = group.oldX * group.oldScale / newScale;
    local newY = group.oldY * group.oldScale / newScale;
    group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY);

    -- calculate & set new bar width
    local newWidth = max(50, ((cursorX - self.oldCursorX)/uiScale + self.oldWidth * group.oldScale)/newScale);
    NeedToKnow.SetWidth(groupID, newWidth);
    
end

function NeedToKnow.SetWidth(groupID, width)    
    for barID = 1, NeedToKnow.ProfileSettings.Groups[groupID]["NumberBars"] do
        local bar = _G["NeedToKnow_Group"..groupID.."Bar"..barID];
        local background = _G[bar:GetName().."Background"];
        local text = _G[bar:GetName().."Text"];
        bar:SetWidth(width);
        text:SetWidth(width-60);
        NeedToKnow.SizeBackground(bar, bar.settings.show_icon);
    end
    NeedToKnow.ProfileSettings.Groups[groupID]["Width"] = width;        -- move this to StopSizing?
end

function NeedToKnow.StopSizing(self, button)
    self:SetScript("OnUpdate", nil)
    local groupID = self:GetParent():GetID();
    NeedToKnow.ProfileSettings.Groups[groupID]["Scale"] = self:GetParent():GetScale();
    NeedToKnow.SavePosition(self:GetParent(), groupID);
end

function NeedToKnow.SavePosition(group, groupID)
    groupID = groupID or group:GetID();
    local point, _, relativePoint, xOfs, yOfs = group:GetPoint();
    NeedToKnow.ProfileSettings.Groups[groupID]["Position"] = {point, relativePoint, xOfs, yOfs};
end
