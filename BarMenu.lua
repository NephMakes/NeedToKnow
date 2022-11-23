--[[ Bar right-click menu ]]--

-- local addonName, addonTable = ...

local BarMenu = NeedToKnow.BarMenu
local String = NeedToKnow.String
local NeedToKnowRMB = NeedToKnow.BarMenu  -- Deprecated

StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"] = {
	text = String.CHOOSENAME_DIALOG,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnAccept = function(self)
		local text = self.editBox:GetText()
		local variable = self.variable
		if variable ~= nil then
			BarMenu.ChooseName(text, variable)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"].OnAccept(self:GetParent())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self) 
		self:GetParent():Hide()
	end,
	OnHide = function(self)
		self.editBox:SetText("")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

BarMenu.MainMenu = {
	{ VariableName = "Enabled", MenuText = String.BARMENU_ENABLE },
	{ VariableName = "AuraName", MenuText = String.BARMENU_CHOOSENAME, Type = "Dialog", DialogText = "CHOOSENAME_DIALOG" },
	{ VariableName = "BuffOrDebuff", MenuText = String.BARMENU_BUFFORDEBUFF, Type = "Submenu" },
	{ VariableName = "Options", MenuText = "Settings", Type = "Submenu" },
	{},
	{ VariableName = "Show", MenuText = String.BARMENU_SHOW, Type = "Submenu" }, 
	{ VariableName = "TimeFormat", MenuText = String.BARMENU_TIMEFORMAT, Type = "Submenu" }, 
	{ VariableName = "VisualCastTime", MenuText = String.BARMENU_VISUALCASTTIME, Type = "Submenu" },
	{ VariableName = "BlinkSettings", MenuText = "Blink Settings", Type = "Submenu" }, -- LOCME
	{ VariableName = "BarColor", MenuText = String.BARMENU_BARCOLOR, Type = "Color" },
	{},
	{ VariableName = "ImportExport", MenuText = "Import/Export Bar Settings", Type = "Dialog", DialogText = "IMPORTEXPORT_DIALOG" },
}

BarMenu.SubMenus = {
    -- the keys on this table need to match the settings variable names
    BuffOrDebuff = {
          { Setting = "HELPFUL", MenuText = String.BARMENU_HELPFUL },
          { Setting = "HARMFUL", MenuText = String.BARMENU_HARMFUL },
          { Setting = "TOTEM", MenuText = String.BARMENU_TOTEM },
          { Setting = "CASTCD", MenuText = String.BARMENU_CASTCD },
          { Setting = "BUFFCD", MenuText = String.BARMENU_BUFFCD },
          { Setting = "EQUIPSLOT", MenuText = String.BARMENU_EQUIPSLOT },
          { Setting = "USABLE", MenuText = String.BARMENU_USABLE },
          -- NephMakes: USABLE is useful in Classic, but without way to automatically query useable time left feels like low-quality feature. Might help to include cooldown check?
    },
    TimeFormat = {
          { Setting = "Fmt_SingleUnit", MenuText = String.FMT_SINGLEUNIT },
          { Setting = "Fmt_TwoUnits", MenuText = String.FMT_TWOUNITS },
          { Setting = "Fmt_Float", MenuText = String.FMT_FLOAT },
    },
    Unit = {
        { Setting = "player", MenuText = String.BARMENU_PLAYER }, 
        { Setting = "target", MenuText = String.BARMENU_TARGET }, 
        { Setting = "targettarget", MenuText = String.BARMENU_TARGETTARGET }, 
        { Setting = "focus", MenuText = String.BARMENU_FOCUS }, 
        { Setting = "pet", MenuText = String.BARMENU_PET }, 
        { Setting = "vehicle", MenuText = String.BARMENU_VEHICLE }, 
        { Setting = "lastraid", MenuText = String.BARMENU_LAST_RAID },
    },
    DebuffUnit = {
        { Setting = "player", MenuText = String.BARMENU_PLAYER }, 
        { Setting = "target", MenuText = String.BARMENU_TARGET }, 
        { Setting = "targettarget", MenuText = String.BARMENU_TARGETTARGET }, 
        { Setting = "focus", MenuText = String.BARMENU_FOCUS }, 
        { Setting = "pet", MenuText = String.BARMENU_PET }, 
        { Setting = "vehicle", MenuText = String.BARMENU_VEHICLE },
    },
    Opt_HELPFUL = {
      { VariableName = "Unit", MenuText = String.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "bDetectExtends", MenuText = "Track duration increases" }, -- LOCME
      { VariableName = "OnlyMine", MenuText = String.BARMENU_ONLYMINE },
      { VariableName = "show_all_stacks", MenuText = "Sum stacks from all casters" },
    },
    Opt_HARMFUL = {
      { VariableName = "DebuffUnit", MenuText = String.BARMENU_CHOOSEUNIT, Type = "Submenu" },
      { VariableName = "bDetectExtends", MenuText = "Track duration increases" }, -- LOCME
      { VariableName = "OnlyMine", MenuText = String.BARMENU_ONLYMINE },
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
    Opt_USABLE = {
        { VariableName = "usable_duration", MenuText = "Usable duration...",  Type = "Dialog", DialogText = "USABLE_DURATION_DIALOG", Numeric=true },
        { VariableName = "append_usable", MenuText = "Append \"Usable\"" }, -- LOCME
    },
    EquipmentSlotList = {
        { Setting = "1", MenuText = String.ITEM_NAMES[1] },
        { Setting = "2", MenuText = String.ITEM_NAMES[2] },
        { Setting = "3", MenuText = String.ITEM_NAMES[3] },
        { Setting = "4", MenuText = String.ITEM_NAMES[4] },
        { Setting = "5", MenuText = String.ITEM_NAMES[5] },
        { Setting = "6", MenuText = String.ITEM_NAMES[6] },
        { Setting = "7", MenuText = String.ITEM_NAMES[7] },
        { Setting = "8", MenuText = String.ITEM_NAMES[8] },
        { Setting = "9", MenuText = String.ITEM_NAMES[9] },
        { Setting = "10", MenuText = String.ITEM_NAMES[10] },
        { Setting = "11", MenuText = String.ITEM_NAMES[11] },
        { Setting = "12", MenuText = String.ITEM_NAMES[12] },
        { Setting = "13", MenuText = String.ITEM_NAMES[13] },
        { Setting = "14", MenuText = String.ITEM_NAMES[14] },
        { Setting = "15", MenuText = String.ITEM_NAMES[15] },
        { Setting = "16", MenuText = String.ITEM_NAMES[16] },
        { Setting = "17", MenuText = String.ITEM_NAMES[17] },
        { Setting = "18", MenuText = String.ITEM_NAMES[18] },
        { Setting = "19", MenuText = String.ITEM_NAMES[19] },
    },
    PowerTypeList = {},
    VisualCastTime = {
        { VariableName = "vct_enabled", MenuText = String.BARMENU_VCT_ENABLE },
        { VariableName = "vct_color", MenuText = String.BARMENU_VCT_COLOR, Type = "Color" },
        { VariableName = "vct_spell", MenuText = String.BARMENU_VCT_SPELL, Type = "Dialog", DialogText = "CHOOSE_VCT_SPELL_DIALOG" },
        { VariableName = "vct_extra", MenuText = String.BARMENU_VCT_EXTRA, Type = "Dialog", DialogText = "CHOOSE_VCT_EXTRA_DIALOG", Numeric=true },
    },
    Show = {
        { VariableName = "show_icon",      MenuText = String.BARMENU_SHOW_ICON },
        { VariableName = "show_text",      MenuText = String.BARMENU_SHOW_TEXT },
        { VariableName = "show_count",     MenuText = String.BARMENU_SHOW_COUNT },
        { VariableName = "show_time",      MenuText = String.BARMENU_SHOW_TIME },
        { VariableName = "show_spark",     MenuText = String.BARMENU_SHOW_SPARK },
        { VariableName = "show_mypip",     MenuText = String.BARMENU_SHOW_MYPIP },
        { VariableName = "show_ttn1",      MenuText = String.BARMENU_SHOW_TTN1 },
        { VariableName = "show_ttn2",      MenuText = String.BARMENU_SHOW_TTN2 },
        { VariableName = "show_ttn3",      MenuText = String.BARMENU_SHOW_TTN3 },
        { VariableName = "show_text_user", MenuText = String.BARMENU_SHOW_TEXT_USER, Type = "Dialog", DialogText = "CHOOSE_OVERRIDE_TEXT", Checked = function(settings) return "" ~= settings.show_text_user end },
    },
    BlinkSettings = {
        { VariableName = "blink_enabled", MenuText = String.BARMENU_VCT_ENABLE },
        { VariableName = "blink_label", MenuText = "Bar text while blinking...", Type = "Dialog", DialogText="CHOOSE_BLINK_TITLE_DIALOG" }, 
        { VariableName = "MissingBlink", MenuText = "Bar color when blinking...", Type = "Color" }, -- LOCME
        { VariableName = "blink_ooc", MenuText = "Blink out of combat" }, -- LOCME
        { VariableName = "blink_boss", MenuText = "Blink only for bosses" }, -- LOCME
    },
}

BarMenu.VariableRedirects = {
	DebuffUnit = "Unit",
	EquipmentSlotList = "AuraName",
	PowerTypeList = "AuraName",
}


--[[ Functions ]]--

function BarMenu:New()
	local barMenu = CreateFrame("Frame", "NeedToKnowDropDownMenu", nil, "UIDropDownMenuTemplate")
	Mixin(barMenu, BarMenu)  -- Inherit BarMenu methods
	barMenu.barID = 1
	barMenu.groupID = 1
	barMenu:SetScript("OnShow", barMenu.OnShow)
	barMenu:OnShow()
	return barMenu
end

function BarMenu:OnShow()
	UIDropDownMenu_Initialize(self, self.Initialize, "MENU")
end

function BarMenu:Initialize()
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)

	if barSettings.MissingBlink.a == 0 then
		barSettings.blink_enabled = false
	end

	BarMenu.SubMenus.Options = BarMenu.SubMenus["Opt_"..barSettings.BuffOrDebuff]

	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		-- Menu heading
		if barSettings.AuraName and barSettings.AuraName ~= "" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = NeedToKnow.GetPrettyName(barSettings)
			info.isTitle = true
			info.notCheckable = true -- Unindents
			UIDropDownMenu_AddButton(info)
		end

		local mainMenu = BarMenu.MainMenu
		for index, value in ipairs(mainMenu) do
			NeedToKnowRMB.BarMenu_AddButton(barSettings, mainMenu[index])
		end
	end

	if UIDROPDOWNMENU_MENU_LEVEL > 1 then
		-- Submenu heading
		if UIDROPDOWNMENU_MENU_VALUE == "VisualCastTime" then
			-- Show timed spell and/or extra time
			local title = ""
			if barSettings.vct_spell then
				title = title .. barSettings.vct_spell
			end
			local extraTime = tonumber(barSettings.vct_extra)
			if extraTime and extraTime > 0 then
				if title ~= "" then
					title = title .. " + "
				end
				title = title .. string.format("%0.1fs", extraTime)
			end
			if title ~= "" then
				local info = UIDropDownMenu_CreateInfo()
				info.text = title
				info.isTitle = true
				info.notCheckable = true  -- Unindents
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end

		local subMenus = BarMenu.SubMenus
		for _, value in ipairs(subMenus[UIDROPDOWNMENU_MENU_VALUE]) do
			NeedToKnowRMB.BarMenu_AddButton(barSettings, value, UIDROPDOWNMENU_MENU_VALUE)
		end

		if barSettings.OnlyMine == false and UIDROPDOWNMENU_MENU_LEVEL == 2 then
			BarMenu:UncheckAndDisable(2, "bDetectExtends")
		end
		return
	end

	NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
end

function BarMenu:ShowMenu(bar)
	-- Called by Bar:OnMouseUp()
	BarMenu.barID = bar:GetID()
	BarMenu.groupID = bar:GetParent():GetID()
	if not BarMenu.frame then
		BarMenu.frame = BarMenu:New()
    end
    ToggleDropDownMenu(1, nil, BarMenu.frame, "cursor", 0, 0)
    if not DropDownList1:IsShown() then
        ToggleDropDownMenu(1, nil, BarMenu.frame, "cursor", 0, 0)
    end
end

function NeedToKnowRMB.BarMenu_AddButton(barSettings, i_desc, i_parent)
    info = UIDropDownMenu_CreateInfo();
    local item_type = i_desc["Type"];
    info.text = i_desc["MenuText"];
    local varSettings
    if ( nil ~= i_desc["Setting"]) then
        item_type = "SetVar"
        local v = BarMenu.VariableRedirects[i_parent] or i_parent
        varSettings = barSettings[v]
    else
        info.value = i_desc["VariableName"];
        varSettings = barSettings[info.value];
    end
    
    if ( not varSettings and (item_type == "Check" or item_type == "Color") ) then
        print(string.format("NTK: Could not find %s in", info.value), barSettings)
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
        info.func = BarMenu.IgnoreToggle;
        info.disabled = true;
    elseif ( nil == item_type or item_type == "Check" ) then
        info.func = BarMenu.ToggleSetting;
        info.checked = (nil ~= varSettings and varSettings);
        info.hideUnCheck = nil;
        info.isNotRadio = true;
    elseif ( item_type == "SetVar" ) then
        info.func = BarMenu.ChooseSetting;
        info.value = i_desc["Setting"];
        info.checked = (varSettings == info.value);
        info.hideUnCheck = nil;
        info.keepShownOnClick = false;
    elseif ( item_type == "Submenu" ) then
        info.hasArrow = true;
        info.isNotRadio = true;
        info.func = BarMenu.IgnoreToggle;
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
        info.swatchFunc = BarMenu.SetColor;
        info.opacityFunc = BarMenu.SetOpacity;
        info.cancelFunc = BarMenu.CancelColor;
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

function BarMenu.IgnoreToggle(button)
	if button then
		_G[button:GetName().."Check"]:Hide()
		button.checked = false
	end
end

function BarMenu.ToggleSetting(button, arg1, arg2, checked)
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	barSettings[button.value] = button.checked
	NeedToKnow:UpdateBar(groupID, barID)

	-- Update menu items
	local level = BarMenu:GetMenuItemLevel(button)
	if button.value == "OnlyMine" then 
		if button.checked == false then
			BarMenu:UncheckAndDisable(level, "bDetectExtends")
		else
			BarMenu:EnableMenuItem(level, "bDetectExtends")
			BarMenu:CheckMenuItem(level, "show_all_stacks", false)
		end
	elseif button.value == "blink_enabled" then
		if button.checked and barSettings.MissingBlink.a == 0 then
			barSettings.MissingBlink.a = 0.5
		end
	elseif button.value == "show_all_stacks" then
		if button.checked then
			BarMenu:CheckMenuItem(level, "OnlyMine", false)
		end
	end
end

function BarMenu:GetMenuItemLevel(button)
	local menuLevel = button:GetName():match("%d+")
	return tonumber(menuLevel)
end

function BarMenu:GetMenuItem(menuLevel, valueName)
	local listFrameName = "DropDownList"..menuLevel
	local numButtons = _G[listFrameName]["numButtons"]
	for index = 1, numButtons do
		local button = _G[listFrameName.."Button"..index]
		local txt
		if type(button.value) == "table" then
			txt = button.value.variable
		else
			txt = button.value
		end
		if txt == valueName then
			return button
		end
	end
	return nil
end

function BarMenu:CheckMenuItem(menuLevel, valueName, checkItem)
	local button = BarMenu:GetMenuItem(menuLevel, valueName)
	if button then
		local check = _G[button:GetName().."Check"]
		if checkItem then
			check:Show()
			button.checked = true
		else
			check:Hide()
			button.checked = false
		end
		BarMenu.ToggleSetting(button)
	end
end

function BarMenu:EnableMenuItem(menuLevel, valueName)
    local button = BarMenu:GetMenuItem(menuLevel, valueName)
    if button then
        button:Enable()
    end
end

function BarMenu:UncheckAndDisable(menuLevel, valueName)
	local button = BarMenu:GetMenuItem(menuLevel, valueName)
	if button then
		BarMenu:CheckMenuItem(menuLevel, valueName, false)
		button:Disable()
	end
end

function NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
    local barType = barSettings.BuffOrDebuff;
    
    -- Set up the options submenu to the current name and contents
    local Opt = BarMenu.SubMenus["Opt_"..barType];
    if ( not Opt ) then Opt = {} end
    BarMenu.SubMenus.Options = Opt;

    local button = BarMenu:GetMenuItem(1, "Options");
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
        -- lbl = lbl .. String["BARMENU_"..barType].. " Settings";
        lbl = "Settings";
        button:SetText(lbl);
    end

    -- Set up the aura name menu option to behave the right way
    if ( barType == "EQUIPSLOT" ) then
        button = BarMenu:GetMenuItem(1, "AuraName");
        if ( button ) then
            button.oldvalue = button.value
        else
            button = BarMenu:GetMenuItem(1, "PowerTypeList") 
        end
        if ( button ) then
            local arrow = _G[button:GetName().."ExpandArrow"]
            arrow:Show();
            button.hasArrow = true
            button.value = "EquipmentSlotList"
            button:SetText(String.BARMENU_CHOOSESLOT)
            -- TODO: really should disable the button press verb somehow
        end
    else
        button = BarMenu:GetMenuItem(1, "EquipmentSlotList");
        if not button then button = BarMenu:GetMenuItem(1, "PowerTypeList") end
        if ( button ) then
            local arrow = _G[button:GetName().."ExpandArrow"]
            arrow:Hide();
            button.hasArrow = false
            if button.oldvalue then button.value = button.oldvalue end
            button:SetText(String.BARMENU_CHOOSENAME)
        end
    end
end

function BarMenu.ChooseSetting(button, arg1, arg2, checked)
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local setting = BarMenu.VariableRedirects[UIDROPDOWNMENU_MENU_VALUE] or UIDROPDOWNMENU_MENU_VALUE
	barSettings[setting] = button.value
	NeedToKnow:UpdateBar(groupID, barID)

	-- Update menu items
	if setting == "BuffOrDebuff" then
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

function NeedToKnowRMB.BarMenu_ShowNameDialog(self, arg1, arg2, checked)
    if not self.value.text or not NEEDTOKNOW[self.value.text] then return end

    StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME_DIALOG"].text = NEEDTOKNOW[self.value.text]
    local dialog = StaticPopup_Show("NEEDTOKNOW.CHOOSENAME_DIALOG")
    dialog.variable = self.value.variable

    local edit = _G[dialog:GetName().."EditBox"]
    local groupID = BarMenu.groupID
    local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)

    -- TODO: There has to be a better way to do this, this has pretty bad user  feel
    local isNumeric = self.value.numeric or false
    if NeedToKnowRMB.EditBox_Original_OnTextChanged == nil then
        NeedToKnowRMB.EditBox_Original_OnTextChanged = edit:GetScript("OnTextChanged")
    end
    if isNumeric then
        edit:SetScript("OnTextChanged", NeedToKnowRMB.EditBox_Numeric_OnTextChanged)
    else
        edit:SetScript("OnTextChanged", NeedToKnowRMB.EditBox_Original_OnTextChanged)
    end
    
    edit:SetFocus()
    if dialog.variable ~= "ImportExport" then
        edit:SetText(barSettings[dialog.variable])
    else
        edit:SetText(NeedToKnow.ExportBarSettingsToString(barSettings))
        edit:HighlightText()
    end
end

function BarMenu.ChooseName(text, variable)
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	if variable == "ImportExport" then
		NeedToKnow.ImportBarSettingsFromString(text, groupSettings.Bars, barID)
	else
		barSettings[variable] = text
	end
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.SetColor()
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local color = barSettings[ColorPickerFrame.extraInfo]
	color.r, color.g, color.b = ColorPickerFrame:GetColorRGB()
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.SetOpacity()
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local color = barSettings[ColorPickerFrame.extraInfo]
	color.a = 1 - OpacitySliderFrame:GetValue()
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.CancelColor(oldColor)
	if oldColor.r then
		local groupID = BarMenu.groupID
		local barID = BarMenu.barID
		local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
		local color = barSettings[ColorPickerFrame.extraInfo]
		color.r, color.g, color.b = oldColor.r, oldColor.g, oldColor.b
		color.a = 1 - oldColor.opacity
		NeedToKnow:UpdateBar(groupID, barID)
	end
end

