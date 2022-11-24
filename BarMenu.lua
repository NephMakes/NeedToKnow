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


--[[ Bar menu contents ]]--

BarMenu.MainMenu = {
	{varName = "Enabled", menuText = String.BARMENU_ENABLE},
	{varName = "AuraName", Type = "dialog", dialogText = "CHOOSENAME_DIALOG", menuText = String.BARMENU_CHOOSENAME},
	{varName = "BuffOrDebuff", Type = "submenu", menuText = String.BARMENU_BUFFORDEBUFF},
	{varName = "Options", Type = "submenu", menuText = "Settings"},
	{},
	{varName = "Show", Type = "submenu", menuText = String.BARMENU_SHOW}, 
	{varName = "TimeFormat", Type = "submenu", menuText = String.BARMENU_TIMEFORMAT}, 
	{varName = "VisualCastTime", Type = "submenu", menuText = String.BARMENU_VISUALCASTTIME},
	{varName = "BlinkSettings", Type = "submenu", menuText = "Blink Settings"}, 
	{varName = "BarColor", Type = "color", menuText = String.BARMENU_BARCOLOR},
	{},
	{varName = "ImportExport", Type = "dialog", dialogText = "IMPORTEXPORT_DIALOG", menuText = "Import/Export Bar Settings"},
}

BarMenu.SubMenu = {}
local SubMenu = BarMenu.SubMenu
-- Keys in SubMenu must match variable names

SubMenu.BuffOrDebuff = {
	-- Bar type
	{Setting = "HELPFUL", menuText = String.BARMENU_HELPFUL},
	{Setting = "HARMFUL", menuText = String.BARMENU_HARMFUL},
	{Setting = "CASTCD", menuText = String.BARMENU_CASTCD},
	{Setting = "BUFFCD", menuText = String.BARMENU_BUFFCD},
	{Setting = "EQUIPSLOT", menuText = String.BARMENU_EQUIPSLOT},
	{Setting = "USABLE", menuText = String.BARMENU_USABLE},
	{Setting = "TOTEM", menuText = String.BARMENU_TOTEM},
}

SubMenu.Unit = {
	{Setting = "player", menuText = String.BARMENU_PLAYER}, 
	{Setting = "target", menuText = String.BARMENU_TARGET}, 
	{Setting = "targettarget", menuText = String.BARMENU_TARGETTARGET}, 
	{Setting = "focus", menuText = String.BARMENU_FOCUS}, 
	{Setting = "pet", menuText = String.BARMENU_PET}, 
	{Setting = "vehicle", menuText = String.BARMENU_VEHICLE}, 
	{Setting = "lastraid", menuText = String.BARMENU_LAST_RAID},
}

SubMenu.DebuffUnit = {
	{Setting = "player", menuText = String.BARMENU_PLAYER}, 
	{Setting = "target", menuText = String.BARMENU_TARGET}, 
	{Setting = "targettarget", menuText = String.BARMENU_TARGETTARGET}, 
	{Setting = "focus", menuText = String.BARMENU_FOCUS}, 
	{Setting = "pet", menuText = String.BARMENU_PET}, 
	{Setting = "vehicle", menuText = String.BARMENU_VEHICLE},
}

SubMenu.EquipmentSlotList = {
	{Setting = "1", menuText = String.ITEM_NAMES[1]},
	{Setting = "2", menuText = String.ITEM_NAMES[2]},
	{Setting = "3", menuText = String.ITEM_NAMES[3]},
	{Setting = "4", menuText = String.ITEM_NAMES[4]},
	{Setting = "5", menuText = String.ITEM_NAMES[5]},
	{Setting = "6", menuText = String.ITEM_NAMES[6]},
	{Setting = "7", menuText = String.ITEM_NAMES[7]},
	{Setting = "8", menuText = String.ITEM_NAMES[8]},
	{Setting = "9", menuText = String.ITEM_NAMES[9]},
	{Setting = "10", menuText = String.ITEM_NAMES[10]},
	{Setting = "11", menuText = String.ITEM_NAMES[11]},
	{Setting = "12", menuText = String.ITEM_NAMES[12]},
	{Setting = "13", menuText = String.ITEM_NAMES[13]},
	{Setting = "14", menuText = String.ITEM_NAMES[14]},
	{Setting = "15", menuText = String.ITEM_NAMES[15]},
	{Setting = "16", menuText = String.ITEM_NAMES[16]},
	{Setting = "17", menuText = String.ITEM_NAMES[17]},
	{Setting = "18", menuText = String.ITEM_NAMES[18]},
	{Setting = "19", menuText = String.ITEM_NAMES[19]},
}

SubMenu.Opt_HELPFUL = {
	{varName = "Unit", menuText = String.BARMENU_CHOOSEUNIT, Type = "submenu"},
	{varName = "bDetectExtends", menuText = "Track duration increases"}, 
	{varName = "OnlyMine", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", menuText = "Sum stacks from all casters"},
}

SubMenu.Opt_HARMFUL = {
	{varName = "DebuffUnit", menuText = String.BARMENU_CHOOSEUNIT, Type = "submenu"},
	{varName = "bDetectExtends", menuText = "Track duration increases"}, 
	{varName = "OnlyMine", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", menuText = "Sum stacks from all casters"},
}

SubMenu.Opt_TOTEM = {}

SubMenu.Opt_CASTCD = {
	{varName = "append_cd", menuText = "Append \"CD\""}, 
	{varName = "show_charges", menuText = "Show first and last charge CD"}, 
}

SubMenu.Opt_EQUIPSLOT = {
	{varName = "append_cd", menuText = "Append \"CD\""}, 
}

SubMenu.Opt_BUFFCD = {
	{varName = "buffcd_duration", Type = "dialog", dialogText = "BUFFCD_DURATION_DIALOG", Numeric = true, menuText = "Cooldown duration..."},
	{varName = "buffcd_reset_spells", Type = "dialog", dialogText = "BUFFCD_RESET_DIALOG", menuText = "Reset on buff..."},
	{varName = "append_cd", menuText = "Append \"CD\""}, 
}

SubMenu.Opt_USABLE = {
	{varName = "usable_duration", Type = "dialog", dialogText = "USABLE_DURATION_DIALOG", Numeric = true, menuText = "Usable duration..."},
	{varName = "append_usable", menuText = "Append \"Usable\""}, 
}

SubMenu.Show = {
	{varName = "show_icon", menuText = String.BARMENU_SHOW_ICON},
	{varName = "show_text", menuText = String.BARMENU_SHOW_TEXT},
	{varName = "show_count", menuText = String.BARMENU_SHOW_COUNT},
	{varName = "show_time", menuText = String.BARMENU_SHOW_TIME},
	{varName = "show_spark", menuText = String.BARMENU_SHOW_SPARK},
	{varName = "show_mypip", menuText = String.BARMENU_SHOW_MYPIP},
	{varName = "show_ttn1", menuText = String.BARMENU_SHOW_TTN1},
	{varName = "show_ttn2", menuText = String.BARMENU_SHOW_TTN2},
	{varName = "show_ttn3", menuText = String.BARMENU_SHOW_TTN3},
	{varName = "show_text_user", menuText = String.BARMENU_SHOW_TEXT_USER, Type = "dialog", dialogText = "CHOOSE_OVERRIDE_TEXT", Checked = function(settings) return "" ~= settings.show_text_user end},
}

SubMenu.TimeFormat = {
	{Setting = "Fmt_SingleUnit", menuText = String.FMT_SINGLEUNIT},
	{Setting = "Fmt_TwoUnits", menuText = String.FMT_TWOUNITS},
	{Setting = "Fmt_Float", menuText = String.FMT_FLOAT},
}

SubMenu.VisualCastTime = {
	{varName = "vct_enabled", menuText = String.BARMENU_VCT_ENABLE},
	{varName = "vct_color", menuText = String.BARMENU_VCT_COLOR, Type = "color"},
	{varName = "vct_spell", menuText = String.BARMENU_VCT_SPELL, Type = "dialog", dialogText = "CHOOSE_VCT_SPELL_DIALOG"},
	{varName = "vct_extra", menuText = String.BARMENU_VCT_EXTRA, Type = "dialog", dialogText = "CHOOSE_VCT_EXTRA_DIALOG", Numeric = true},
}

SubMenu.BlinkSettings = {
	{varName = "blink_enabled", menuText = String.BARMENU_VCT_ENABLE},
	{varName = "blink_label", menuText = "Bar text while blinking...", Type = "dialog", dialogText = "CHOOSE_BLINK_TITLE_DIALOG"}, 
	{varName = "MissingBlink", menuText = "Bar color when blinking...", Type = "color"}, 
	{varName = "blink_ooc", menuText = "Blink out of combat"}, 
	{varName = "blink_boss", menuText = "Blink only for bosses"}, 
}

-- Deprecated:
BarMenu.VariableRedirects = {
	DebuffUnit = "Unit",
	EquipmentSlotList = "AuraName",
--	PowerTypeList = "AuraName",
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

	BarMenu.SubMenu.Options = BarMenu.SubMenu["Opt_"..barSettings.BuffOrDebuff]

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
			BarMenu:AddButton(barSettings, mainMenu[index])
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

		local subMenu = BarMenu.SubMenu
		for _, menuItem in ipairs(subMenu[UIDROPDOWNMENU_MENU_VALUE]) do
			BarMenu:AddButton(barSettings, menuItem, UIDROPDOWNMENU_MENU_VALUE)
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

function BarMenu:AddButton(barSettings, menuItem, i_parent)
	-- Make clickable button in dropdown menu

	-- Prepare info for UIDropDownMenu_AddButton
	local item_type = menuItem.Type
	info = UIDropDownMenu_CreateInfo()

	local varSettings

	if menuItem.Setting ~= nil then
		-- Value to select from list
		item_type = "varValue"
		local v = BarMenu.VariableRedirects[i_parent] or i_parent
		varSettings = barSettings[v]
	else
		info.value = menuItem.varName
		varSettings = barSettings[info.value]
	end

	local b = menuItem.Checked  -- Only true for override text
	if b then
		if type(b) == "function" then
			info.checked = b(barSettings)
		else
			info.checked = b
		end
	end

	info.text = menuItem.menuText
	info.hasArrow = false
	info.keepShownOnClick = true
	info.notCheckable = false  -- indent everything
	info.hideUnCheck = true  -- but hide empty checkbox/radio

	if not item_type and not info.text and not info.value then
		-- Blank line
		info.func = BarMenu.IgnoreToggle
		info.disabled = true
	elseif not item_type then
		-- True/false
		info.func = BarMenu.ToggleSetting
		-- info.checked = (nil ~= varSettings and varSettings)
		info.checked = (varSettings == true)
		info.hideUnCheck = nil
		info.isNotRadio = true
	elseif item_type == "varValue" then
		-- Value to select from list
		info.func = BarMenu.ChooseSetting
		info.value = menuItem.Setting
		info.checked = (varSettings == info.value)
		info.hideUnCheck = nil
		info.keepShownOnClick = false
	elseif item_type == "submenu" then
		info.hasArrow = true
		info.isNotRadio = true
		info.func = BarMenu.IgnoreToggle
	elseif item_type == "dialog" then
		info.func = NeedToKnowRMB.BarMenu_ShowNameDialog
		info.keepShownOnClick = false
		info.value = {variable = menuItem.varName, text = menuItem.dialogText, numeric = menuItem.Numeric}
	elseif item_type == "color" then
		info.hasColorSwatch = 1
		info.hasOpacity = true
		info.r = varSettings.r
		info.g = varSettings.g
		info.b = varSettings.b
		info.opacity = 1 - varSettings.a
		info.swatchFunc = BarMenu.SetColor
		info.opacityFunc = BarMenu.SetOpacity
		info.cancelFunc = BarMenu.CancelColor
		info.func = UIDropDownMenuButton_OpenColorPicker
		info.keepShownOnClick = false
	end

	-- Make button
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- Modify button
	local listFrame = _G["DropDownList"..UIDROPDOWNMENU_MENU_LEVEL]
	local index = listFrame and listFrame.numButtons or 1  -- This seems wrong
	local buttonName = listFrame:GetName().."Button"..index
	if item_type == "color" then
		-- Sadly, extraInfo isn't a field propagated to the button
		local button = _G[buttonName]
		button.extraInfo = info.value
	end
	if info.hideUnCheck then
		local checkBG = _G[buttonName.."UnCheck"]
		checkBG:Hide()
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
    local Opt = BarMenu.SubMenu["Opt_"..barType];
    if ( not Opt ) then Opt = {} end
    BarMenu.SubMenu.Options = Opt;

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
        
        -- lbl = lbl .. String["BARMENU_"..barType].. " Settings";
        lbl = "Settings";
        button:SetText(lbl);
    end

    -- Set up the aura name menu option to behave the right way
    if ( barType == "EQUIPSLOT" ) then
        button = BarMenu:GetMenuItem(1, "AuraName");
        if ( button ) then
            button.oldvalue = button.value
--        else
--            button = BarMenu:GetMenuItem(1, "PowerTypeList") 
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
--        if not button then button = BarMenu:GetMenuItem(1, "PowerTypeList") end
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

