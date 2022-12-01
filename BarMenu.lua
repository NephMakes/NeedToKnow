-- Bar right-click menu

-- local addonName, addonTable = ...
local BarMenu = NeedToKnow.BarMenu
local String = NeedToKnow.String
local Dialog = NeedToKnow.Dialog


--[[ Menu contents ]]--

local MainMenu = {
	{value = "mainHeading", itemType = "heading", headingType = "auraName"},
	{value = "AuraName", itemType = "dialog", dialogType = "text", menuText = String.CHOOSE_SPELL_ITEM_ABILITY},
	{value = "BuffOrDebuff", itemType = "submenu", menuText = String.BARTYPE},
	{value = "options", itemType = "submenu", menuText = String.SETTINGS},
	{value = "moreOptions", itemType = "submenu", menuText = String.MORE_OPTIONS}, 
	{value = "BarColor", itemType = "color", menuText = String.COLOR},
	{value = "Enabled", itemType = "boolean", menuText = String.ENABLE_BAR},
}

local SubMenu = {}

SubMenu.BuffOrDebuff = {
	-- Bar type
	{value = "HELPFUL", itemType = "varValue", menuText = String.BARTYPE_HELPFUL},
	{value = "HARMFUL", itemType = "varValue", menuText = String.BARTYPE_HARMFUL},
	{value = "CASTCD", itemType = "varValue", menuText = String.BARTYPE_CASTCD},
	{value = "EQUIPSLOT", itemType = "varValue", menuText = String.BARTYPE_EQUIPSLOT},
	{value = "USABLE", itemType = "varValue", menuText = String.BARTYPE_USABLE},
	{value = "BUFFCD", itemType = "varValue", menuText = String.BARTYPE_BUFFCD},
	{value = "TOTEM", itemType = "varValue", menuText = String.BARTYPE_TOTEM},
}

SubMenu.Unit = {
	{value = "player", itemType = "varValue", menuText = String.UNIT_PLAYER}, 
	{value = "target", itemType = "varValue", menuText = String.UNIT_TARGET}, 
	{value = "focus", itemType = "varValue", menuText = String.UNIT_FOCUS}, 
	{value = "pet", itemType = "varValue", menuText = String.UNIT_PET}, 
	{value = "targettarget", itemType = "varValue", menuText = String.UNIT_TARGETTARGET}, 
	{value = "vehicle", itemType = "varValue", menuText = String.UNIT_VEHICLE}, 
	{value = "lastraid", itemType = "varValue", menuText = String.UNIT_LAST_RAID},
}

SubMenu.debuffUnit = {
	{value = "player", itemType = "varValue", menuText = String.UNIT_PLAYER}, 
	{value = "target", itemType = "varValue", menuText = String.UNIT_TARGET}, 
	{value = "focus", itemType = "varValue", menuText = String.UNIT_FOCUS}, 
	{value = "pet", itemType = "varValue", menuText = String.UNIT_PET}, 
	{value = "targettarget", itemType = "varValue", menuText = String.UNIT_TARGETTARGET}, 
	{value = "vehicle", itemType = "varValue", menuText = String.UNIT_VEHICLE},
}

SubMenu.gearSlot = {
	{value = "1", itemType = "varValue", menuText = String.ITEM_NAMES[1]},
	{value = "2", itemType = "varValue", menuText = String.ITEM_NAMES[2]},
	{value = "3", itemType = "varValue", menuText = String.ITEM_NAMES[3]},
	{value = "4", itemType = "varValue", menuText = String.ITEM_NAMES[4]},
	{value = "5", itemType = "varValue", menuText = String.ITEM_NAMES[5]},
	{value = "6", itemType = "varValue", menuText = String.ITEM_NAMES[6]},
	{value = "7", itemType = "varValue", menuText = String.ITEM_NAMES[7]},
	{value = "8", itemType = "varValue", menuText = String.ITEM_NAMES[8]},
	{value = "9", itemType = "varValue", menuText = String.ITEM_NAMES[9]},
	{value = "10", itemType = "varValue", menuText = String.ITEM_NAMES[10]},
	{value = "11", itemType = "varValue", menuText = String.ITEM_NAMES[11]},
	{value = "12", itemType = "varValue", menuText = String.ITEM_NAMES[12]},
	{value = "13", itemType = "varValue", menuText = String.ITEM_NAMES[13]},
	{value = "14", itemType = "varValue", menuText = String.ITEM_NAMES[14]},
	{value = "15", itemType = "varValue", menuText = String.ITEM_NAMES[15]},
	{value = "16", itemType = "varValue", menuText = String.ITEM_NAMES[16]},
	{value = "17", itemType = "varValue", menuText = String.ITEM_NAMES[17]},
	{value = "18", itemType = "varValue", menuText = String.ITEM_NAMES[18]},
	{value = "19", itemType = "varValue", menuText = String.ITEM_NAMES[19]},
}

SubMenu.HELPFUL = {
	{value = "Unit", itemType = "submenu", menuText = String.CHOOSE_UNIT},
	{value = "OnlyMine", itemType = "boolean", menuText = String.ONLY_MINE},
	{value = "show_all_stacks", itemType = "boolean", menuText = String.SUM_ALL_CASTERS},
}

SubMenu.HARMFUL = {
	{value = "debuffUnit", itemType = "submenu", menuText = String.CHOOSE_UNIT},
	{value = "OnlyMine", itemType = "boolean", menuText = String.ONLY_MINE},
	{value = "show_all_stacks", itemType = "boolean", menuText = String.SUM_ALL_CASTERS},
}

SubMenu.CASTCD = {
	{value = "show_charges", itemType = "boolean", menuText = String.SHOW_CHARGE_COOLDOWN}, 
	{value = "append_cd", itemType = "boolean", menuText = String.APPEND_CD}, 
}

SubMenu.EQUIPSLOT = {
	{value = "append_cd", itemType = "boolean", menuText = String.APPEND_CD}, 
}

SubMenu.USABLE = {
	{value = "usable_duration", itemType = "dialog", dialogType = "numeric", menuText = String.SET_USABLE_DURATION},
	{value = "append_usable", itemType = "boolean", menuText = String.APPEND_USABLE}, 
}

SubMenu.BUFFCD = {
	{value = "buffcd_duration", itemType = "dialog", dialogType = "numeric", menuText = String.SET_BUFFCD_DURATION},
	{value = "buffcd_reset_spells", itemType = "dialog", dialogType = "text", menuText = String.BUFFCD_RESET},
	{value = "append_cd", itemType = "boolean", menuText = String.APPEND_CD}, 
}

SubMenu.TOTEM = {}

SubMenu.moreOptions = {
	{value = "show", itemType = "submenu", menuText = String.SHOW}, 
	{value = "TimeFormat", itemType = "submenu", menuText = String.TIME_FORMAT}, 
	{value = "textOptions", itemType = "submenu", menuText = String.TEXT_OPTIONS}, 
	{value = "castTimeOptions", itemType = "submenu", menuText = String.CAST_TIME},
	{value = "blinkOptions", itemType = "submenu", menuText = String.BLINK_SETTINGS}, 
	{value = "ImportExport", itemType = "dialog", dialogType = "importExport", menuText = String.IMPORT_EXPORT_SETTINGS},
}

SubMenu.show = {
	{value = "show_text", itemType = "boolean", menuText = String.SHOW_NAME},
	{value = "show_time", itemType = "boolean", menuText = String.SHOW_TIME},
	{value = "show_count", itemType = "boolean", menuText = String.SHOW_COUNT},
	{value = "show_spark", itemType = "boolean", menuText = String.SHOW_SPARK},
	{value = "show_icon", itemType = "boolean", menuText = String.SHOW_ICON},
}

SubMenu.textOptions = {
	{value = "show_text_user", itemType = "dialog", dialogType = "text", showCheck = true, menuText = String.REPLACE_BAR_TEXT},
	{value = "show_mypip", itemType = "boolean", menuText = String.SHOW_MYPIP},
	{value = "bDetectExtends", itemType = "boolean", menuText = String.SHOW_TIME_ADDED}, 
	{value = "show_ttn1", itemType = "boolean", menuText = String.SHOW_TTN1},
	{value = "show_ttn2", itemType = "boolean", menuText = String.SHOW_TTN2},
	{value = "show_ttn3", itemType = "boolean", menuText = String.SHOW_TTN3},
}

SubMenu.TimeFormat = {
	{varValue = "Fmt_SingleUnit", itemType = "varValue", menuText = String.TIME_SINGLE_UNIT},
	{varValue = "Fmt_TwoUnits", itemType = "varValue", menuText = String.TIME_MIN_SEC},
	{varValue = "Fmt_Float", itemType = "varValue", menuText = String.TIME_DECIMAL},
}

SubMenu.castTimeOptions = {
	-- {itemType = "heading", headingType = "castTime"}, 
	{value = "vct_enabled", itemType = "boolean", menuText = String.CAST_TIME_ENABLE},
	{value = "vct_color", itemType = "color", menuText = String.COLOR},
	{value = "vct_spell", itemType = "dialog", dialogType = "text", showCheck = true, menuText = String.CAST_TIME_CHOOSE_SPELL},
	{value = "vct_extra", itemType = "dialog", dialogType = "numeric", showCheck = true, menuText = String.CAST_TIME_ADD_TIME},
}

SubMenu.blinkOptions = {
	{value = "blink_enabled", itemType = "boolean", menuText = String.BLINK_ENABLE},
	{value = "MissingBlink", itemType = "color", menuText = String.BLINK_COLOR}, 
	{value = "blink_ooc", itemType = "boolean", menuText = String.BLINK_OUT_OF_COMBAT}, 
	{value = "blink_boss", itemType = "boolean", menuText = String.BLINK_ONLY_BOSS}, 
	{value = "blink_label", itemType = "dialog", dialogType = "text", showCheck = true, menuText = String.BLINK_TEXT}, 
}

local VariableRedirects = {
	-- Format: subMenuKey = varName
	debuffUnit = "Unit",  -- Different list of possible values
	gearSlot = "AuraName",  -- Reused button
}

-- Button text that depends on barType
local ButtonText = {}
ButtonText["barType"] = {
	-- For GetHeadingText()
	HELPFUL = String.BARTYPE_HELPFUL, 
	HARMFUL = String.BARTYPE_HARMFUL, 
	CASTCD = String.BARTYPE_CASTCD, 
	EQUIPSLOT = String.BARTYPE_EQUIPSLOT, 
	USABLE = String.BARTYPE_USABLE, 
	BUFFCD = String.BARTYPE_BUFFCD, 
	TOTEM = String.BARTYPE_TOTEM, 
}
ButtonText["options"] = {
	-- barType options submenu
	HELPFUL = String.BUFF_SETTINGS, 
	HARMFUL = String.DEBUFF_SETTINGS, 
	CASTCD = String.COOLDOWN_SETTINGS, 
	EQUIPSLOT = String.COOLDOWN_SETTINGS, 
	USABLE = String.USABLE_SETTINGS, 
	BUFFCD = String.COOLDOWN_SETTINGS, 
	TOTEM = String.TOTEM_SETTINGS, 
}


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
	barMenu.groupID, barMenu.barID = 1
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
		menu = MainMenu
	elseif UIDROPDOWNMENU_MENU_LEVEL > 1 then
		menu = SubMenu[UIDROPDOWNMENU_MENU_VALUE]
	end
	for index, menuItem in ipairs(menu) do
		BarMenu:AddButton(barSettings, menuItem, UIDROPDOWNMENU_MENU_VALUE)
	end
	BarMenu:UpdateMenu(barSettings)
end

function BarMenu:AddButton(barSettings, menuItem, subMenuKey)
	-- Make clickable item for dropdown menu

	local itemType = menuItem.itemType
	local value = menuItem.value

	-- Make info for UIDropDownMenu_AddButton()
	info = {}
	info.text = menuItem.menuText
	info.notCheckable = false  -- Indent everything
	info.hideUnCheck = true  -- Hide empty checkbox/radio
	info.keepShownOnClick = true
	if itemType == "heading" then
		info.value = value
		info.text = BarMenu:GetHeadingText(menuItem.headingType, barSettings)
		if not info.text or info.text == "" then return end  -- No empty headings
		info.isTitle = true
		info.notCheckable = true  -- Unindent
	elseif itemType == "submenu" then
		info.value = value
		info.func = BarMenu.IgnoreToggle
		info.hasArrow = true
		info.isNotRadio = true
	elseif itemType == "boolean" then
		info.value = value
		info.func = BarMenu.ToggleSetting
		info.checked = (barSettings[value] == true)
		info.hideUnCheck = nil
		info.isNotRadio = true
	elseif itemType == "varValue" then
		-- Value to select from list of options
		info.value = menuItem.value
		info.func = BarMenu.ChooseSetting
		if subMenuKey then
			value = VariableRedirects[subMenuKey] or subMenuKey
			info.checked = (barSettings[value] == menuItem.value)
		end
		info.hideUnCheck = nil
		info.keepShownOnClick = false
	elseif itemType == "dialog" then
		info.value = value
		info.func = BarMenu.ShowDialog
		info.arg1 = menuItem.dialogType
		info.keepShownOnClick = false
		if menuItem.showCheck then
			info.checked = (barSettings[value] and barSettings[value] ~= "" and barSettings[value] ~= 0)
			info.hideUnCheck = nil
			info.isNotRadio = true
		end
	elseif itemType == "color" then
		info.value = value
		info.hasColorSwatch = 1
		info.hasOpacity = true
		local color = barSettings[value]
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
		-- and show user if important info missing
		text = NeedToKnow:GetPrettyName(barSettings)
		if not text or text == "" then text = "??" end
		if text ~= "" then
			local barType = barSettings.BuffOrDebuff
			text = text.." – "..ButtonText["barType"][barType]
			if barType == "HELPFUL" or barType == "HARMFUL" then
				text = text.." ("..barSettings.Unit..")"
			elseif barType == "USABLE" then
				time = barSettings.usable_duration
				if not time or time == "" then time = "??" end
				text = text.." ("..time.." s)"
			elseif barType == "BUFFCD" then
				time = barSettings.buffcd_duration
				if not time or time == "" then time = "??" end
				text = text.." ("..time.." s)"
			end
		end
	elseif headingType == "castTime" then
		-- Show timed spell and/or extra time
		text = barSettings.vct_spell or ""
		time = tonumber(barSettings.vct_extra)
		if time and time > 0 then
			if text ~= "" then text = text.." + " end
			text = text..string.format("%0.1fs", time)
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
	local groupID, barID = BarMenu.groupID, BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	barSettings[button.value] = button.checked
	NeedToKnow:UpdateBar(groupID, barID)
	BarMenu:UpdateMenu(barSettings)
end

function BarMenu.ChooseSetting(button, arg1, arg2, checked)
	-- Choose this value from list of options
	local groupID, barID = BarMenu.groupID, BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local varName = VariableRedirects[UIDROPDOWNMENU_MENU_VALUE] or UIDROPDOWNMENU_MENU_VALUE
	barSettings[varName] = button.value
	NeedToKnow:UpdateBar(groupID, barID)
	BarMenu:UpdateMenu(barSettings)
end

function BarMenu.ShowDialog(button, dialogType, arg2, checked)
	-- For text and numeric user input
	local groupID, barID = BarMenu.groupID, BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	if dialogType == "importExport" then
		Dialog:ShowImportExport(groupID, barID)
	else
		local varName = button.value
		local currentValue = barSettings[varName]
		local barType = barSettings.BuffOrDebuff
		Dialog:ShowInputDialog(dialogType, varName, groupID, barID, currentValue, barType)
	end
end

function BarMenu.SetColor()
	local groupID, barID = BarMenu.groupID, BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local color = barSettings[ColorPickerFrame.extraInfo]
	color.r, color.g, color.b = ColorPickerFrame:GetColorRGB()
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.SetOpacity()
	local groupID, barID = BarMenu.groupID, BarMenu.barID
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local color = barSettings[ColorPickerFrame.extraInfo]
	color.a = 1 - OpacitySliderFrame:GetValue()
	NeedToKnow:UpdateBar(groupID, barID)
end

function BarMenu.CancelColor(oldColor)
	if oldColor.r then
		local groupID, barID = BarMenu.groupID, BarMenu.barID
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
			button.value = "gearSlot"
		end
	else
		-- Restore auraName button 
		button = BarMenu:GetMenuButton(1, "gearSlot")
		if button then
			local arrow = _G[button:GetName().."ExpandArrow"]
			arrow:Hide()
			button.hasArrow = false
			if button.oldvalue then 
				button.value = button.oldvalue 
			end
		end
	end

	-- Set options submenu for bar type
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

	-- Kitjan had blink automatically disabling if opacity set to zero
	if barSettings.MissingBlink.a == 0 then
		barSettings.blink_enabled = false
	end
	]]--
end

--[[
function BarMenu:GetMenuItemLevel(button)
	local menuLevel = button:GetName():match("%d+")
	return tonumber(menuLevel)
end
]]--

function BarMenu:GetMenuButton(menuLevel, buttonValue)
	local listFrameName = "DropDownList"..menuLevel
	local numButtons = _G[listFrameName]["numButtons"]
	for index = 1, numButtons do
		local button = _G[listFrameName.."Button"..index]
		if button.value == buttonValue then
			return button
		end
	end
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

--[[
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
]]--


