-- Right-click menu to configure timer bar

-- TO DO: 
-- Bar menu only works properly if loaded after NeedToKnow_Options.lua
-- (the menu items are blank otherwise). Why? Make it more robust and independent. 

-- local addonName, addonTable = ...
-- local BarMenu = NeedToKnow.BarMenu
local NeedToKnowRMB = NeedToKnow.BarMenu

-- Note: 
-- NeedToKnow.BarMenu = CreateFrame("Frame", "NeedToKnowDropDown", nil, "NeedToKnow_DropDownTemplate")
-- Won't work because XML templates loaded last
-- Also, BarMenu:Methods() might clash with inherited UIDropDownMenuTemplate

NeedToKnowRMB.CurrentBar = { groupID = 1, barID = 1 };  -- a dirty hack, i know.  

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
    { VariableName = "Show", MenuText = NEEDTOKNOW.BARMENU_SHOW, Type = "Submenu" }, 
    { VariableName = "TimeFormat", MenuText = NEEDTOKNOW.BARMENU_TIMEFORMAT, Type = "Submenu" }, 
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
          { Setting = "EQUIPSLOT", MenuText = NEEDTOKNOW.BARMENU_EQUIPSLOT },
-- Now that Victory Rush adds a buff when you can use it, this confusing option is being removed.
-- The code that drives it remains so that any existing users' bars won't break.
--          { Setting = "USABLE", MenuText = NEEDTOKNOW.BARMENU_USABLE },
--          { Setting = "POWER", MenuText = NEEDTOKNOW.BARMENU_POWER }
-- Disabling POWER option since it looks like Kitjan never finished implementing it
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
    Opt_CASTCD = {
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
        { VariableName = "show_charges", MenuText = "Show first and last charge CD" }, -- LOCME
    },
    Opt_EQUIPSLOT = {
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
    },
    Opt_BUFFCD = {
        { VariableName = "buffcd_duration", MenuText = "Cooldown duration...", Type = "Dialog", DialogText = "BUFFCD_DURATION_DIALOG", Numeric=true },
        { VariableName = "buffcd_reset_spells", MenuText = "Reset on buff...", Type = "Dialog", DialogText = "BUFFCD_RESET_DIALOG" },
        { VariableName = "append_cd", MenuText = "Append \"CD\"" }, -- LOCME
    },
    Opt_POWER = {
      { VariableName = "Unit", MenuText = NEEDTOKNOW.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "power_sole", MenuText = "Only Show When Primary" }, -- LOCME
    },
    Opt_USABLE = {
        { VariableName = "usable_duration", MenuText = "Usable duration...",  Type = "Dialog", DialogText = "USABLE_DURATION_DIALOG", Numeric=true },
        { VariableName = "append_usable", MenuText = "Append \"Usable\"" }, -- LOCME
    },
    EquipmentSlotList = {
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
    PowerTypeList = {},
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

NeedToKnowRMB.VariableRedirects = {
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
    NeedToKnow:UpdateBar(groupID, barID)
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
    NeedToKnow:UpdateBar(groupID, barID)
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
        -- edit:SetText( NeedToKnowIE.ExportBarSettingsToString(barSettings) );
        edit:SetText( NeedToKnow.ExportBarSettingsToString(barSettings) );
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
		-- NeedToKnowIE.ImportBarSettingsFromString(text, NeedToKnow.ProfileSettings.Groups[groupID]["Bars"], barID);
		NeedToKnow.ImportBarSettingsFromString(text, NeedToKnow.ProfileSettings.Groups[groupID]["Bars"], barID);
	end
	NeedToKnow:UpdateBar(groupID, barID)
end

function NeedToKnowRMB.BarMenu_SetColor()
	local groupID = NeedToKnowRMB.CurrentBar["groupID"];
	local barID = NeedToKnowRMB.CurrentBar["barID"];
	local varSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID][ColorPickerFrame.extraInfo];

	varSettings.r,varSettings.g,varSettings.b = ColorPickerFrame:GetColorRGB();
	NeedToKnow:UpdateBar(groupID, barID)
end

function NeedToKnowRMB.BarMenu_SetOpacity()
	local groupID = NeedToKnowRMB.CurrentBar["groupID"];
	local barID = NeedToKnowRMB.CurrentBar["barID"];
	local varSettings = NeedToKnow.ProfileSettings.Groups[groupID]["Bars"][barID][ColorPickerFrame.extraInfo];

	varSettings.a = 1 - OpacitySliderFrame:GetValue();
	NeedToKnow:UpdateBar(groupID, barID)
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
	NeedToKnow:UpdateBar(groupID, barID)
	end
end

