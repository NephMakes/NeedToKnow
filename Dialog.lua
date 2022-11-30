-- Pop-up dialog boxes for user input

-- local addonName, addonTable = ...
local Dialog = NeedToKnow.Dialog
local String = NeedToKnow.String


--[[ Dialog info ]]--

StaticPopupDialogs["NEEDTOKNOW_TEXT_INPUT"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnShow = function(self)
		local text = self.data.currentValue or ""
		self.editBox:SetText(text)
		self.editBox:SetFocus()
	end,
	OnAccept = function(self)
		local text = self.editBox:GetText()
		local data = self.data
		Dialog:SetSetting(data.varName, text, data.groupID, data.barID)
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetParent().editBox:GetText()
		local data = self:GetParent().data
		Dialog:SetSetting(data.varName, text, data.groupID, data.barID)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetText("")
	end,
	timeout = 0,
	exclusive = 1, 
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["NEEDTOKNOW_NUMERIC_INPUT"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 50,
	maxLetters = 0,
	OnShow = function(self)
		local text = tonumber(self.data.currentValue) or ""
		self.editBox:SetText(text)
		self.editBox:SetNumeric(true)
		self.editBox:SetFocus()
	end,
	OnAccept = function(self)
		local value = tonumber(self.editBox:GetText())
		local data = self.data
		Dialog:SetSetting(data.varName, value, data.groupID, data.barID)
	end,
	EditBoxOnEnterPressed = function(self)
		local value = tonumber(self:GetParent().editBox:GetText())
		local data = self:GetParent().data
		Dialog:SetSetting(data.varName, value, data.groupID, data.barID)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetNumeric(false)
		self.editBox:SetText("")
	end,
	timeout = 0,
	exclusive = 1, 
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["NEEDTOKNOW_IMPORT_EXPORT"] = {
	text = "Copy or paste bar settings here", 
	subText = "Clear text to clear settings", 
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	editBoxWidth = 300,
	maxLetters = 0,
	OnShow = function(self)
		self.editBox:SetText(self.data.text)
		self.editBox:HighlightText()
	end,
	OnAccept = function(self)
		local text = self.editBox:GetText()
		Dialog:ImportSettings(text, self.data.groupID, self.data.barID)
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetParent().editBox:GetText()
		local data = self:GetParent().data
		Dialog:ImportSettings(text, data.groupID, data.barID)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetText("")
	end,
	timeout = 0,
	exclusive = 1, 
	whileDead = 1,
	hideOnEscape = 1,
}

local DialogText = {
	HELPFUL = "Enter buff name", 
	HARMFUL = "Enter debuff name", 
	CASTCD = "Enter spell, item, or ability name", 
	USABLE = "Enter spell or ability name", 
	BUFFCD = "Enter buff name", 
	TOTEM = "Enter totem name", 
	usable_duration = "Enter time in seconds\nreactive spell or ability is usable", 
	buffcd_duration = "Enter time in seconds\nfor proc internal cooldown", 
	buffcd_reset_spells = "Enter spell or ability name", 
	vct_spell = "Enter spell or ability name", 
	vct_extra = "Enter time in seconds\nto add to cast time", 
	blink_label = "Enter text to replace\nspell, item, and ability names", 
	show_text_user = "Enter text to replace\nspell, item, and ability names", 
}

local DialogSubText = {
	HELPFUL = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	HARMFUL = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	CASTCD = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	USABLE = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	BUFFCD = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	TOTEM = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	usable_duration = "", 
	buffcd_duration = "For most procs the internal cooldown is 45 seconds", 
	vct_spell = "Leave blank to show cast time for spell with buff or debuff name", 
	vct_extra = "", 
	buffcd_reset_spells = "These spells and abilities reset the internal cooldown. For more than one, enter names separated by commas. Spell IDs accepted.", 
	blink_label = "Clear text to stop replacing", 
	show_text_user = "Clear text to stop replacing", 
}

local DialogData = {} -- Reused table {varName, currentValue, groupID, barID}


--[[ Functions ]]--

function Dialog:ShowInputDialog(dialogType, varName, groupID, barID, currentValue, barType)
	-- Called by BarMenu.ShowDialog()
	local data = DialogData  -- Reused table
	data.varName, data.groupID, data.barID = varName, groupID, barID
	if dialogType == "text" then
		data.currentValue = currentValue or ""
		dialogType = "NEEDTOKNOW_TEXT_INPUT"
	elseif dialogType == "numeric" then
		data.currentValue = currentValue
		dialogType = "NEEDTOKNOW_NUMERIC_INPUT"
	else
		return
	end
	local info = StaticPopupDialogs[dialogType]
	info.text = DialogText[varName] or DialogText[barType]  -- barType text is for AuraName
	info.subText = DialogSubText[varName] or DialogSubText[barType]
	StaticPopup_Show(dialogType, nil, nil, data)
end

function Dialog:SetSetting(varName, value, groupID, barID)
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	barSettings[varName] = value
	NeedToKnow:UpdateBar(groupID, barID)
end

function Dialog:ShowImportExport(groupID, barID)
	-- Called by BarMenu.ShowDialog()
	local barSettings = NeedToKnow:GetBarSettings(groupID, barID)
	local text = NeedToKnow.ExportBarSettingsToString(barSettings)
	local data = DialogData  -- Reused table
	data.groupID, data.barID, data.text = groupID, barID, text
	StaticPopup_Show("NEEDTOKNOW_IMPORT_EXPORT", nil, nil, data)
end

function Dialog:ImportSettings(text, groupID, barID)
	local groupSettings = NeedToKnow:GetGroupSettings(groupID)
	NeedToKnow.ImportBarSettingsFromString(text, groupSettings.Bars, barID)
	NeedToKnow:UpdateBar(groupID, barID)
end

--[[
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

function BarMenu.OnTextChangedNumeric(editBox, isUserInput)
	-- Kitjan wasn't happy with this method because it shows then quickly replaces non-numeric text
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
]]--



