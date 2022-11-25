--[[ Bar right-click menu ]]--

-- local addonName, addonTable = ...

local BarMenu = NeedToKnow.BarMenu
local String = NeedToKnow.String
local NeedToKnowRMB = NeedToKnow.BarMenu  -- Deprecated


--[[ Menu contents ]]--

BarMenu.MainMenu = {
	{itemType = "heading", headingType = "auraName"},
	{varName = "Enabled", itemType = "boolean", menuText = String.BARMENU_ENABLE},
	{varName = "AuraName", itemType = "dialog", dialogText = String.CHOOSENAME_DIALOG, menuText = String.BARMENU_CHOOSENAME},
	{varName = "BuffOrDebuff", itemType = "submenu", menuText = String.BARMENU_BUFFORDEBUFF},
	{varName = "Options", itemType = "submenu", menuText = "Settings"},
	{itemType = "blank"},
	{varName = "Show", itemType = "submenu", menuText = String.BARMENU_SHOW}, 
	{varName = "TimeFormat", itemType = "submenu", menuText = String.BARMENU_TIMEFORMAT}, 
	{varName = "VisualCastTime", itemType = "submenu", menuText = String.BARMENU_VISUALCASTTIME},
	{varName = "BlinkSettings", itemType = "submenu", menuText = "Blink Settings"}, 
	{varName = "BarColor", itemType = "color", menuText = String.BARMENU_BARCOLOR},
	{itemType = "blank"},
	{varName = "ImportExport", itemType = "dialog", dialogText = String.IMPORTEXPORT_DIALOG, menuText = "Import/Export Bar Settings"},
}

BarMenu.SubMenu = {}
local SubMenu = BarMenu.SubMenu
-- Keys in SubMenu must match variable names

SubMenu.BuffOrDebuff = {
	-- Bar type
	{varValue = "HELPFUL", itemType = "varValue", menuText = String.BARMENU_HELPFUL},
	{varValue = "HARMFUL", itemType = "varValue", menuText = String.BARMENU_HARMFUL},
	{varValue = "CASTCD", itemType = "varValue", menuText = String.BARMENU_CASTCD},
	{varValue = "BUFFCD", itemType = "varValue", menuText = String.BARMENU_BUFFCD},
	{varValue = "EQUIPSLOT", itemType = "varValue", menuText = String.BARMENU_EQUIPSLOT},
	{varValue = "USABLE", itemType = "varValue", menuText = String.BARMENU_USABLE},
	{varValue = "TOTEM", itemType = "varValue", menuText = String.BARMENU_TOTEM},
}

SubMenu.Unit = {
	{varValue = "player", itemType = "varValue", menuText = String.BARMENU_PLAYER}, 
	{varValue = "target", itemType = "varValue", menuText = String.BARMENU_TARGET}, 
	{varValue = "targettarget", itemType = "varValue", menuText = String.BARMENU_TARGETTARGET}, 
	{varValue = "focus", itemType = "varValue", menuText = String.BARMENU_FOCUS}, 
	{varValue = "pet", itemType = "varValue", menuText = String.BARMENU_PET}, 
	{varValue = "vehicle", itemType = "varValue", menuText = String.BARMENU_VEHICLE}, 
	{varValue = "lastraid", itemType = "varValue", menuText = String.BARMENU_LAST_RAID},
}

SubMenu.DebuffUnit = {
	{varValue = "player", itemType = "varValue", menuText = String.BARMENU_PLAYER}, 
	{varValue = "target", itemType = "varValue", menuText = String.BARMENU_TARGET}, 
	{varValue = "targettarget", itemType = "varValue", menuText = String.BARMENU_TARGETTARGET}, 
	{varValue = "focus", itemType = "varValue", menuText = String.BARMENU_FOCUS}, 
	{varValue = "pet", itemType = "varValue", menuText = String.BARMENU_PET}, 
	{varValue = "vehicle", itemType = "varValue", menuText = String.BARMENU_VEHICLE},
}

SubMenu.EquipmentSlotList = {
	{varValue = "1", itemType = "varValue", menuText = String.ITEM_NAMES[1]},
	{varValue = "2", itemType = "varValue", menuText = String.ITEM_NAMES[2]},
	{varValue = "3", itemType = "varValue", menuText = String.ITEM_NAMES[3]},
	{varValue = "4", itemType = "varValue", menuText = String.ITEM_NAMES[4]},
	{varValue = "5", itemType = "varValue", menuText = String.ITEM_NAMES[5]},
	{varValue = "6", itemType = "varValue", menuText = String.ITEM_NAMES[6]},
	{varValue = "7", itemType = "varValue", menuText = String.ITEM_NAMES[7]},
	{varValue = "8", itemType = "varValue", menuText = String.ITEM_NAMES[8]},
	{varValue = "9", itemType = "varValue", menuText = String.ITEM_NAMES[9]},
	{varValue = "10", itemType = "varValue", menuText = String.ITEM_NAMES[10]},
	{varValue = "11", itemType = "varValue", menuText = String.ITEM_NAMES[11]},
	{varValue = "12", itemType = "varValue", menuText = String.ITEM_NAMES[12]},
	{varValue = "13", itemType = "varValue", menuText = String.ITEM_NAMES[13]},
	{varValue = "14", itemType = "varValue", menuText = String.ITEM_NAMES[14]},
	{varValue = "15", itemType = "varValue", menuText = String.ITEM_NAMES[15]},
	{varValue = "16", itemType = "varValue", menuText = String.ITEM_NAMES[16]},
	{varValue = "17", itemType = "varValue", menuText = String.ITEM_NAMES[17]},
	{varValue = "18", itemType = "varValue", menuText = String.ITEM_NAMES[18]},
	{varValue = "19", itemType = "varValue", menuText = String.ITEM_NAMES[19]},
}

SubMenu.Opt_HELPFUL = {
	{varName = "Unit", itemType = "submenu", menuText = String.BARMENU_CHOOSEUNIT},
	{varName = "bDetectExtends", itemType == "boolean", menuText = "Track duration increases"}, 
	{varName = "OnlyMine", itemType == "boolean", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", itemType == "boolean", menuText = "Sum stacks from all casters"},
}

SubMenu.Opt_HARMFUL = {
	{varName = "DebuffUnit", itemType = "submenu", menuText = String.BARMENU_CHOOSEUNIT},
	{varName = "bDetectExtends", itemType = "boolean", menuText = "Track duration increases"}, 
	{varName = "OnlyMine", itemType = "boolean", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", itemType = "boolean", menuText = "Sum stacks from all casters"},
}

SubMenu.Opt_CASTCD = {
	{varName = "append_cd", itemType = "boolean", menuText = "Append \"CD\""}, 
	{varName = "show_charges", itemType = "boolean", menuText = "Show first and last charge CD"}, 
}

SubMenu.Opt_EQUIPSLOT = {
	{varName = "append_cd", itemType = "boolean", menuText = "Append \"CD\""}, 
}

SubMenu.Opt_USABLE = {
	{varName = "usable_duration", itemType = "dialog", dialogText = String.USABLE_DURATION_DIALOG, isNumeric = true, menuText = "Usable duration..."},
	{varName = "append_usable", itemType = "boolean", menuText = "Append \"Usable\""}, 
}

SubMenu.Opt_BUFFCD = {
	{varName = "buffcd_duration", itemType = "dialog", dialogText = String.BUFFCD_DURATION_DIALOG, isNumeric = true, menuText = "Cooldown duration..."},
	{varName = "buffcd_reset_spells", itemType = "dialog", dialogText = String.BUFFCD_RESET_DIALOG, menuText = "Reset on buff..."},
	{varName = "append_cd", itemType = "boolean", menuText = "Append \"CD\""}, 
}

SubMenu.Opt_TOTEM = {}

SubMenu.Show = {
	{varName = "show_icon", itemType = "boolean", menuText = String.BARMENU_SHOW_ICON},
	{varName = "show_text", itemType = "boolean", menuText = String.BARMENU_SHOW_TEXT},
	{varName = "show_count", itemType = "boolean", menuText = String.BARMENU_SHOW_COUNT},
	{varName = "show_time", itemType = "boolean", menuText = String.BARMENU_SHOW_TIME},
	{varName = "show_spark", itemType = "boolean", menuText = String.BARMENU_SHOW_SPARK},
	{varName = "show_mypip", itemType = "boolean", menuText = String.BARMENU_SHOW_MYPIP},
	{varName = "show_ttn1", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN1},
	{varName = "show_ttn2", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN2},
	{varName = "show_ttn3", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN3},
	{varName = "show_text_user", itemType = "dialog", dialogText = String.CHOOSE_OVERRIDE_TEXT, 
		showCheck = true, menuText = String.BARMENU_SHOW_TEXT_USER},
}

SubMenu.TimeFormat = {
	{varValue = "Fmt_SingleUnit", itemType = "varValue", menuText = String.FMT_SINGLEUNIT},
	{varValue = "Fmt_TwoUnits", itemType = "varValue", menuText = String.FMT_TWOUNITS},
	{varValue = "Fmt_Float", itemType = "varValue", menuText = String.FMT_FLOAT},
}

SubMenu.VisualCastTime = {
	{itemType = "heading", headingType = "castTime"}, 
	{varName = "vct_enabled", itemType = "boolean", menuText = String.BARMENU_VCT_ENABLE},
	{varName = "vct_color", itemType = "color", menuText = String.BARMENU_VCT_COLOR},
	{varName = "vct_spell", itemType = "dialog", dialogText = String.CHOOSE_VCT_SPELL_DIALOG, menuText = String.BARMENU_VCT_SPELL},
	{varName = "vct_extra", itemType = "dialog", dialogText = String.CHOOSE_VCT_EXTRA_DIALOG, isNumeric = true, menuText = String.BARMENU_VCT_EXTRA},
}

SubMenu.BlinkSettings = {
	{varName = "blink_enabled", itemType = "boolean", menuText = String.BARMENU_VCT_ENABLE},
	{varName = "blink_label", itemType = "dialog", dialogText = String.CHOOSE_BLINK_TITLE_DIALOG, menuText = "Bar text while blinking..."}, 
	{varName = "MissingBlink", itemType = "color", menuText = "Bar color when blinking..."}, 
	{varName = "blink_ooc", itemType = "boolean", menuText = "Blink out of combat"}, 
	{varName = "blink_boss", itemType = "boolean", menuText = "Blink only for bosses"}, 
}

BarMenu.VariableRedirects = {
	-- SubMenuKey = varName
	DebuffUnit = "Unit",  -- Different list of options
	EquipmentSlotList = "AuraName",  -- Reused setting
}


--[[ Dialog boxes ]]--

StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnAccept = function(self)
		if self.varName then
			BarMenu.ChooseName(self.editBox:GetText(), self.varName)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME"].OnAccept(self:GetParent())
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

-- StaticPopupDialogs["NEEDTOKNOW_TEXT_ENTRY"] = {}

-- StaticPopupDialogs["NEEDTOKNOW_NUMERIC_ENTRY"] = {}

-- StaticPopupDialogs["NEEDTOKNOW_IMPORT_EXPORT"] = {}


--[[ Functions ]]--

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
	UIDropDownMenu_Initialize(self, self.MakeMenu, "MENU")
end

function BarMenu:MakeMenu()
	local barSettings = NeedToKnow:GetBarSettings(BarMenu.groupID, BarMenu.barID)
	local menu

	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		menu = BarMenu.MainMenu
	elseif UIDROPDOWNMENU_MENU_LEVEL > 1 then
		menu = BarMenu.SubMenu[UIDROPDOWNMENU_MENU_VALUE]
	end

	for _, menuItem in ipairs(menu) do
		BarMenu:AddButton(barSettings, menuItem, UIDROPDOWNMENU_MENU_VALUE)

		-- This should be somewhere or something else
		if barSettings.OnlyMine == false and UIDROPDOWNMENU_MENU_LEVEL == 2 then
			BarMenu:UncheckAndDisable(2, "bDetectExtends")
		end
	end

	NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
end

function BarMenu:GetHeadingText(headingType, barSettings)
	local text
	if headingType == "auraName" then
		text = barSettings.AuraName or ""
		if text ~= "" then
			local barType = barSettings.BuffOrDebuff
			text = text .. " – " .. String["BARMENU_"..barType]
			if barType == "HELPFUL" or barType == "HARMFUL" then
				text = text .. " ("..barSettings.Unit..")"
			end
		end
	elseif headingType == "barType" then
		-- Show bar type and unit tracked (if applicable)
		local barType = barSettings.BuffOrDebuff
		text = String["BARMENU_"..barType]
		if barType == "HELPFUL" or barType == "HARMFUL" then
			text = text .. " ("..barSettings.Unit..")"
		end
	elseif headingType == "castTime" then
		-- Show timed spell and/or extra time
		text = barSettings.vct_spell or ""
		local extraTime = tonumber(barSettings.vct_extra)
		if extraTime and extraTime > 0 then
			if text ~= "" then
				text = text .. " + "
			end
			text = text .. string.format("%0.1fs", extraTime)
		end
	end
	return text
end

function BarMenu:AddButton(barSettings, menuItem, subMenuKey)
	-- Make clickable item for dropdown menu

	local itemType = menuItem.itemType
	local varName = menuItem.varName

	-- Make info for UIDropDownMenu_AddButton()
	info = {}
	info.text = menuItem.menuText
	info.notCheckable = false  -- Indent everything
	info.hideUnCheck = true  -- Hide empty checkbox/radio
	info.keepShownOnClick = true
	if itemType == "heading" then
		info.text = BarMenu:GetHeadingText(menuItem.headingType, barSettings)
		info.isTitle = true
		info.notCheckable = true  -- Unindent
	elseif itemType == "submenu" then
		info.value = varName
		info.func = BarMenu.IgnoreToggle
		info.hasArrow = true
		info.isNotRadio = true
	elseif itemType == "boolean" then
		info.value = varName
		info.func = BarMenu.ToggleSetting
		info.checked = (barSettings[varName] == true)
		info.hideUnCheck = nil
		info.isNotRadio = true
	elseif itemType == "varValue" then
		-- Value to select from list of options
		info.value = menuItem.varValue
		info.func = BarMenu.ChooseSetting
		if subMenuKey then
			varName = BarMenu.VariableRedirects[subMenuKey] or subMenuKey
			info.checked = (barSettings[varName] == menuItem.varValue)
		end
		info.hideUnCheck = nil
		info.keepShownOnClick = false
	elseif itemType == "dialog" then
		info.value = varName
		info.func = BarMenu.ShowDialog
		info.arg1 = menuItem.dialogText
		info.arg2 = menuItem.isNumeric
		info.keepShownOnClick = false
		if menuItem.showCheck then
			info.checked = (barSettings[varName] and barSettings[varName] ~= "")
			info.hideUnCheck = nil
			info.isNotRadio = true
		end
	elseif itemType == "color" then
		info.value = varName
		info.hasColorSwatch = 1
		info.hasOpacity = true
		local color = barSettings[varName]
		info.r, info.g, info.b = color.r, color.g, color.b
		info.opacity = 1 - color.a
		info.swatchFunc = BarMenu.SetColor
		info.opacityFunc = BarMenu.SetOpacity
		info.cancelFunc = BarMenu.CancelColor
		info.func = UIDropDownMenuButton_OpenColorPicker
		info.keepShownOnClick = false
	elseif itemType == "blank" then
		info.func = BarMenu.IgnoreToggle
		info.disabled = true
	end

	-- Make button
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- Modify button
	local listFrame = _G["DropDownList"..UIDROPDOWNMENU_MENU_LEVEL]
	local buttonIndex = listFrame.numButtons or 1
	local buttonName = listFrame:GetName().."Button"..buttonIndex
	if itemType == "color" then
		local button = _G[buttonName]
		button.extraInfo = info.value
	end
	if info.hideUnCheck then
		_G[buttonName.."UnCheck"]:Hide()
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
		if button.value == valueName then
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
	-- BarMenu.SubMenu.Options = BarMenu.SubMenu["Opt_"..barSettings.BuffOrDebuff]
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
	-- Choose this value from list of options
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local varName = BarMenu.VariableRedirects[UIDROPDOWNMENU_MENU_VALUE] or UIDROPDOWNMENU_MENU_VALUE
	barSettings[varName] = button.value
	NeedToKnow:UpdateBar(groupID, barID)

	-- Update menu items
	if varName == "BuffOrDebuff" then
		NeedToKnowRMB.BarMenu_UpdateSettings(barSettings)
	end
end

function BarMenu.ShowDialog(button, dialogText, isNumeric, checked)
	StaticPopupDialogs["NEEDTOKNOW.CHOOSENAME"].text = dialogText
	local dialog = StaticPopup_Show("NEEDTOKNOW.CHOOSENAME")
	dialog.varName = button.value

	-- Pre-populate text
	local editBox = _G[dialog:GetName().."EditBox"]
	local barSettings = NeedToKnow:GetBarSettings(BarMenu.groupID, BarMenu.barID)
	if dialog.varName == "ImportExport" then
		editBox:SetText(NeedToKnow.ExportBarSettingsToString(barSettings))
		editBox:HighlightText()
	else
		editBox:SetText(barSettings[dialog.varName])
	end
	editBox:SetFocus()

	-- Only allow user to enter numeric text?
	if not BarMenu.OnTextChangedOriginal then
		BarMenu.OnTextChangedOriginal = editBox:GetScript("OnTextChanged")
	end
	if isNumeric then
		editBox:SetScript("OnTextChanged", BarMenu.OnTextChangedNumeric)
	else
		editBox:SetScript("OnTextChanged", BarMenu.OnTextChangedOriginal)
	end
end

function BarMenu.ChooseName(text, varName)
	-- Set this setting value to text entered by user
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	if varName == "ImportExport" then
		NeedToKnow.ImportBarSettingsFromString(text, groupSettings.Bars, barID)
	else
		barSettings[varName] = text
	end
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.OnTextChangedNumeric(editBox, isUserInput)
    if isUserInput then
        local text = editBox:GetText()
        local culled = text:gsub("[^0-9.]", "") -- Remove non-digits
        local iPeriod = culled:find("[.]")
        if iPeriod ~= nil then
            local before = culled:sub(1, iPeriod)
            local after = string.gsub(culled:sub(iPeriod+1), "[.]", "")
            culled = before .. after
        end
        if text ~= culled then
            editBox:SetText(culled)
        end
    end
    if BarMenu.OnTextChangedOriginal then
        BarMenu.OnTextChangedOriginal(editBox, isUserInput)
    end
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
--	Kitjan had blink automatically disabling if opacity set to zero
--	if barSettings.MissingBlink.a == 0 then
--		barSettings.blink_enabled = false
--	end
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

