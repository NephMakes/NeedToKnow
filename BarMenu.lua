-- Bar right-click menu

-- local addonName, addonTable = ...
local BarMenu = NeedToKnow.BarMenu
local String = NeedToKnow.String
local Dialog = NeedToKnow.Dialog


--[[ Menu contents ]]--

BarMenu.MainMenu = {
	{varName = "mainHeading", itemType = "heading", headingType = "auraName"},
	{varName = "Enabled", itemType = "boolean", menuText = String.BARMENU_ENABLE},
	{varName = "BuffOrDebuff", itemType = "submenu", menuText = String.BARMENU_BAR_TYPE},
	{varName = "AuraName", itemType = "dialog", dialogText = String.CHOOSENAME_DIALOG, menuText = String.BARMENU_CHOOSENAME},
	{varName = "options", itemType = "submenu", menuText = String.BARMENU_SETTINGS},
	{varName = "BarColor", itemType = "color", menuText = String.BARMENU_BARCOLOR},
	{varName = "moreOptions", itemType = "submenu", menuText = String.BARMENU_MORE_OPTIONS}, 
}

BarMenu.SubMenu = {}
local SubMenu = BarMenu.SubMenu

SubMenu.BuffOrDebuff = {
	-- Bar type
	{varValue = "HELPFUL", itemType = "varValue", menuText = String.BARMENU_HELPFUL},
	{varValue = "HARMFUL", itemType = "varValue", menuText = String.BARMENU_HARMFUL},
	{varValue = "CASTCD", itemType = "varValue", menuText = String.BARMENU_CASTCD},
	{varValue = "EQUIPSLOT", itemType = "varValue", menuText = String.BARMENU_EQUIPSLOT},
	{varValue = "USABLE", itemType = "varValue", menuText = String.BARMENU_USABLE},
	{varValue = "BUFFCD", itemType = "varValue", menuText = String.BARMENU_BUFFCD},
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

SubMenu.HELPFUL = {
	{varName = "Unit", itemType = "submenu", menuText = String.BARMENU_CHOOSEUNIT},
	{varName = "OnlyMine", itemType = "boolean", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", itemType = "boolean", menuText = String.BARMENU_SUM_STACKS},
	-- {varName = "bDetectExtends", itemType = "boolean", menuText = String.BARMENU_TRACK_EXTENDS}, 
}

SubMenu.HARMFUL = {
	{varName = "DebuffUnit", itemType = "submenu", menuText = String.BARMENU_CHOOSEUNIT},
	{varName = "OnlyMine", itemType = "boolean", menuText = String.BARMENU_ONLYMINE},
	{varName = "show_all_stacks", itemType = "boolean", menuText = String.BARMENU_SUM_STACKS},
}

SubMenu.CASTCD = {
	{varName = "append_cd", itemType = "boolean", menuText = String.BARMENU_APPEND_CD}, 
	{varName = "show_charges", itemType = "boolean", menuText = String.BARMENU_SHOW_CHARGES}, 
}

SubMenu.EQUIPSLOT = {
	{varName = "append_cd", itemType = "boolean", menuText = String.BARMENU_APPEND_CD}, 
}

SubMenu.USABLE = {
	{varName = "usable_duration", itemType = "dialog", dialogText = String.USABLE_DURATION_DIALOG, isNumeric = true, menuText = String.BARMENU_USABLE_DURATION},
	{varName = "append_usable", itemType = "boolean", menuText = String.BARMENU_APPEND_USABLE}, 
}

SubMenu.BUFFCD = {
	{varName = "buffcd_duration", itemType = "dialog", dialogText = String.BUFFCD_DURATION_DIALOG, isNumeric = true, menuText = String.BARMENU_BUFFCD_DURATION},
	{varName = "buffcd_reset_spells", itemType = "dialog", dialogText = String.BUFFCD_RESET_DIALOG, menuText = String.BARMENU_BUFFCD_RESET},
	{varName = "append_cd", itemType = "boolean", menuText = String.BARMENU_APPEND_CD}, 
}

SubMenu.TOTEM = {}

SubMenu.moreOptions = {
	{varName = "Show", itemType = "submenu", menuText = String.BARMENU_SHOW}, 
	{varName = "TimeFormat", itemType = "submenu", menuText = String.BARMENU_TIMEFORMAT}, 
	{varName = "VisualCastTime", itemType = "submenu", menuText = String.BARMENU_VISUALCASTTIME},
	{varName = "BlinkSettings", itemType = "submenu", menuText = String.BARMENU_BLINK_SETTINGS}, 
	{varName = "show_text_user", itemType = "dialog", dialogText = String.CHOOSE_OVERRIDE_TEXT, 
		showCheck = true, menuText = String.BARMENU_SHOW_TEXT_USER},
	{varName = "ImportExport", itemType = "dialog", dialogText = String.IMPORTEXPORT_DIALOG, menuText = String.BARMENU_IMPORT_EXPORT},
}

SubMenu.Show = {
	{varName = "show_text", itemType = "boolean", menuText = String.BARMENU_SHOW_NAME},
	{varName = "show_time", itemType = "boolean", menuText = String.BARMENU_SHOW_TIME},
	{varName = "show_count", itemType = "boolean", menuText = String.BARMENU_SHOW_COUNT},
	{varName = "show_spark", itemType = "boolean", menuText = String.BARMENU_SHOW_SPARK},
	{varName = "show_icon", itemType = "boolean", menuText = String.BARMENU_SHOW_ICON},
	{varName = "show_mypip", itemType = "boolean", menuText = String.BARMENU_SHOW_MYPIP},
	{varName = "bDetectExtends", itemType = "boolean", menuText = String.BARMENU_TRACK_EXTENDS}, 
	{varName = "show_ttn1", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN1},
	{varName = "show_ttn2", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN2},
	{varName = "show_ttn3", itemType = "boolean", menuText = String.BARMENU_SHOW_TTN3},
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
	{varName = "blink_label", itemType = "dialog", dialogText = String.CHOOSE_BLINK_TITLE_DIALOG, menuText = String.BARMENU_BLINK_TEXT}, 
	{varName = "MissingBlink", itemType = "color", menuText = String.BARMENU_BLINK_COLOR}, 
	{varName = "blink_ooc", itemType = "boolean", menuText = String.BARMENU_BLINK_OUTSIDE_COMBAT}, 
	{varName = "blink_boss", itemType = "boolean", menuText = String.BARMENU_BLINK_ONLY_BOSS}, 
}

BarMenu.VariableRedirects = {
	-- SubMenuKey = varName
	DebuffUnit = "Unit",  -- Different list of possible values
	EquipmentSlotList = "AuraName",  -- Reused button
}

-- Button text that depends on barType
local ButtonText = {}
ButtonText["AuraName"] = {
	HELPFUL = "Choose buff", 
	HARMFUL = "Choose debuff", 
	CASTCD = "Choose spell, item, or ability", 
	EQUIPSLOT = "Choose item slot", 
	USABLE = "Choose spell or ability", 
	BUFFCD = "Choose buff", 
	TOTEM = "Choose totem", 
}
ButtonText["options"] = {
	HELPFUL = "Buff settings", 
	HARMFUL = "Debuff settings", 
	CASTCD = "Cooldown settings", 
	EQUIPSLOT = "Cooldown settings", 
	USABLE = "Reactive settings", 
	BUFFCD = "Cooldown settings", 
	TOTEM = "Totem settings", 
}
-- e.g. ButtonText[varName][barType]


--[[ BarMenu functions ]]--

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
	for index, menuItem in ipairs(menu) do
		BarMenu:AddButton(barSettings, menuItem, UIDROPDOWNMENU_MENU_VALUE)
	end
	BarMenu:UpdateMenu(barSettings)
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
		info.value = varName
		info.text = BarMenu:GetHeadingText(menuItem.headingType, barSettings)
		if not info.text or info.text == "" then return end  -- No empty headings
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
		-- info.arg1 = menuItem.dialogType
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

function BarMenu:GetHeadingText(headingType, barSettings)
	local text, time
	if headingType == "auraName" then
		-- Show concise summary of what bar does
		text = NeedToKnow:GetPrettyName(barSettings) or ""
		if text ~= "" then
			local barType = barSettings.BuffOrDebuff
			text = text .. " – " .. String["BARMENU_"..barType]
			if barType == "HELPFUL" or barType == "HARMFUL" then
				text = text .. " ("..barSettings.Unit..")"
			elseif barType == "USABLE" then
				time = barSettings.usable_duration
				if not time or time == "" then 
					time = "??"
				end
				text = text .. " ("..time.." s)"
			elseif barType == "BUFFCD" then
				time = barSettings.buffcd_duration
				if not time or time == "" then 
					time = "??"
				end
				text = text .. " ("..time.." s)"
			end
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

function BarMenu.IgnoreToggle(button)
	-- For submenu buttons
	if button then
		_G[button:GetName().."Check"]:Hide()
		button.checked = false
	end
end

function BarMenu.ToggleSetting(button, arg1, arg2, checked)
	-- Button function for true/false settings
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	barSettings[button.value] = button.checked
	NeedToKnow:UpdateBar(groupID, barID)
	BarMenu:UpdateMenu(barSettings)
end

function BarMenu.ChooseSetting(button, arg1, arg2, checked)
	-- Choose this value from list of options
	local groupID = BarMenu.groupID
	local barID = BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local varName = BarMenu.VariableRedirects[UIDROPDOWNMENU_MENU_VALUE] or UIDROPDOWNMENU_MENU_VALUE
	barSettings[varName] = button.value
	NeedToKnow:UpdateBar(groupID, barID)
	BarMenu:UpdateMenu(barSettings)
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

function BarMenu:UpdateMenu(barSettings)
	-- Update menu for current bar settings
	local barType = barSettings.BuffOrDebuff
	local button, text

	-- Update menu heading
	button = BarMenu:GetMenuButton(1, "mainHeading")
	if button then
		text = BarMenu:GetHeadingText("auraName", barSettings)
		button:SetText(text)
	end

	-- Reuse AuraName button for inventory slot
	if barType == "EQUIPSLOT" then
		button = BarMenu:GetMenuButton(1, "AuraName")
		if button then
			local arrow = _G[button:GetName().."ExpandArrow"]
			arrow:Show()
			button.hasArrow = true
			-- To do: Disable button clickable?
			button.oldvalue = button.value
			button.value = "EquipmentSlotList"
			button:SetText(ButtonText["AuraName"][barType])
		end
	else
		-- Restore auraName button 
		button = BarMenu:GetMenuButton(1, "EquipmentSlotList")
		if button then
			local arrow = _G[button:GetName().."ExpandArrow"]
			arrow:Hide()
			button.hasArrow = false
			if button.oldvalue then 
				button.value = button.oldvalue 
			end
			button:SetText(ButtonText["AuraName"][barType])
		end
	end

	-- Options submenu for bar type
	local subMenu = SubMenu[barType] or {}
	SubMenu["options"] = subMenu
	button = BarMenu:GetMenuButton(1, "options")
	if button then
		local arrow = _G[button:GetName().."ExpandArrow"]
		if #subMenu > 0 then
			button:Enable()
			arrow:Show()
		else
			button:Disable()
			arrow:Hide()
		end
		button:SetText(ButtonText["options"][barType])
	end

	-- Disable/enable buttons
	if barSettings.show_all_stacks then
		BarMenu:DisableMenuItem(2, "OnlyMine")
	else
		BarMenu:EnableMenuItem(2, "OnlyMine")
	end
	if barSettings.OnlyMine then
		BarMenu:DisableMenuItem(2, "show_all_stacks")
	else
		BarMenu:EnableMenuItem(2, "show_all_stacks")
	end
	-- Make sure order of operations matches BarEngine.lua

	--[[
	-- Kitjan's code from BarMenu.ToggleSetting()
	local level = BarMenu:GetMenuItemLevel(button)
	if button.value == "OnlyMine" then 
		if button.checked == false then
			BarMenu:UncheckAndDisable(level, "bDetectExtends")
		else
			BarMenu:EnableMenuItem(level, "bDetectExtends")
		end
	elseif button.value == "blink_enabled" then
		if button.checked and barSettings.MissingBlink.a == 0 then
			barSettings.MissingBlink.a = 0.5  -- ???
		end
	end

	if barSettings.blink_enabled and barSettings.MissingBlink.a == 0 then
		barSettings.blink_enabled = false
	end

	-- Kitjan had blink automatically disabling if opacity set to zero
	if barSettings.MissingBlink.a == 0 then
		barSettings.blink_enabled = false
	end
	]]--
end

function BarMenu:GetMenuItemLevel(button)
	local menuLevel = button:GetName():match("%d+")
	return tonumber(menuLevel)
end

function BarMenu:GetMenuButton(menuLevel, buttonValue)
	local listFrameName = "DropDownList"..menuLevel
	local numButtons = _G[listFrameName]["numButtons"]
	for index = 1, numButtons do
		local button = _G[listFrameName.."Button"..index]
		if button.value == buttonValue then
			return button
		end
	end
	-- return nil
end

function BarMenu:EnableMenuItem(menuLevel, valueName)
    local button = BarMenu:GetMenuButton(menuLevel, valueName)
    if button then
        button:Enable()
    end
end

function BarMenu:DisableMenuItem(menuLevel, valueName)
    local button = BarMenu:GetMenuButton(menuLevel, valueName)
    if button then
        button:Disable()
    end
end

function BarMenu:UncheckAndDisable(menuLevel, valueName)
	local button = BarMenu:GetMenuButton(menuLevel, valueName)
	if button then
		button:Disable()
		BarMenu:CheckMenuItem(menuLevel, valueName, false)
	end
end

function BarMenu:CheckMenuItem(menuLevel, valueName, checkItem)
	local button = BarMenu:GetMenuButton(menuLevel, valueName)
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


--[[ Dialog box ]]--

StaticPopupDialogs["NEEDTOKNOW_DIALOG"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnAccept = function(self)
		if self.value then
			BarMenu.ChooseName(self.editBox:GetText(), self.value)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		StaticPopupDialogs["NEEDTOKNOW_DIALOG"].OnAccept(self:GetParent())
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

function BarMenu.ShowDialog(button, dialogText, isNumeric, checked)
	StaticPopupDialogs["NEEDTOKNOW_DIALOG"].text = dialogText
	local dialog = StaticPopup_Show("NEEDTOKNOW_DIALOG")
	dialog.value = button.value  -- varName

	-- Pre-populate text
	local editBox = _G[dialog:GetName().."EditBox"]
	local barSettings = NeedToKnow:GetBarSettings(BarMenu.groupID, BarMenu.barID)
	if dialog.value == "ImportExport" then
		editBox:SetText(NeedToKnow.ExportBarSettingsToString(barSettings))
		editBox:HighlightText()
	else
		editBox:SetText(barSettings[dialog.value])
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

--[[
function BarMenu.ShowDialog(button, dialogType, arg2, checked)
	Dialog:ShowTextInput(button.value)
	-- if dialogType == "text" then
		-- Dialog:ShowTextInput(button.value)
	-- elseif dialogType == "numeric" then
		-- Dialog:ShowNumericInput(button.value)
	-- elseif dialogType == "importExport" then
	-- end
end
]]--

function BarMenu.ChooseName(text, varName)
	-- Make user text the new setting value
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







