-- Pop-up dialog boxes to input bar settings

local _, NeedToKnow = ...
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
		self.editBox:SetFocus()
	end,
	OnAccept = function(self)
		local value = Dialog:GetNumericValue(self.editBox:GetText())
		local data = self.data
		Dialog:SetSetting(data.varName, value, data.groupID, data.barID)
	end,
	EditBoxOnTextChanged = function(self) 
		local value = Dialog:GetNumericValue(self:GetText())
		local acceptButton = self:GetParent().button1
		if value then
			acceptButton:Enable()
		else
			acceptButton:Disable()
		end
	end, 
	EditBoxOnEnterPressed = function(self)
		local value = Dialog:GetNumericValue(self:GetText())
		if value then
			local data = self:GetParent().data
			Dialog:SetSetting(data.varName, value, data.groupID, data.barID)
			self:GetParent():Hide()
		end
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

StaticPopupDialogs["NEEDTOKNOW_IMPORT_EXPORT"] = {
	text = String.DIALOG_IMPORT_EXPORT, 
	subText = String.DIALOG_SUBTEXT_IMPORT_EXPORT, 
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
	HELPFUL = String.DIALOG_HELPFUL,  
	HARMFUL = String.DIALOG_HARMFUL, 
	CASTCD = String.DIALOG_CASTCD, 
	USABLE = String.DIALOG_USABLE, 
	BUFFCD = String.DIALOG_BUFFCD, 
	TOTEM = String.DIALOG_TOTEM, 
	usable_duration = String.DIALOG_USABLE_TIME, 
	buffcd_duration = String.DIALOG_BUFFCD_TIME, 
	buffcd_reset_spells = String.DIALOG_BUFFCD_SPELL, 
	vct_spell = String.DIALOG_CAST_TIME_SPELL, 
	vct_extra = String.DIALOG_CAST_TIME_ADD, 
	blink_label = String.DIALOG_BLINK_TEXT, 
	-- show_text_user = String.DIALOG_REPLACE_TEXT, 
	show_text_user = String.DIALOG_CUSTOM_TEXT, 
}

local DialogSubText = {
	HELPFUL = String.DIALOG_SUBTEXT_HELPFUL, 
	HARMFUL = String.DIALOG_SUBTEXT_HARMFUL, 
	CASTCD = String.DIALOG_SUBTEXT_CASTCD, 
	USABLE = String.DIALOG_SUBTEXT_USABLE, 
	BUFFCD = String.DIALOG_SUBTEXT_BUFFCD, 
	TOTEM = String.DIALOG_SUBTEXT_TOTEM, 
	usable_duration = String.DIALOG_SUBTEXT_USABLE_TIME, 
	buffcd_duration = String.DIALOG_SUBTEXT_BUFFCD_TIME, 
	buffcd_reset_spells = String.DIALOG_SUBTEXT_BUFFCD_SPELL, 
	vct_spell = String.DIALOG_SUBTEXT_CAST_TIME_SPELL, 
	vct_extra = String.DIALOG_SUBTEXT_CAST_TIME_ADD, 
	blink_label = String.DIALOG_SUBTEXT_BLINK_TEXT, 
	-- show_text_user = String.DIALOG_SUBTEXT_REPLACE_TEXT, 
	show_text_user = String.DIALOG_SUBTEXT_CUSTOM_TEXT, 
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

function Dialog:GetNumericValue(text)
	local value
	if text == "" then
		value = 0  -- Leave blank to set to zero
	else
		value = tonumber(text)
	end
	return value  -- returns number or nil
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
