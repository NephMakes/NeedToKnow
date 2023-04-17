-- Interface options panel: Appearance
-- Load after AppearancePanel.xml, OptionsPanel.lua

local addonName, NeedToKnow = ...

NeedToKnow.AppearancePanel = InterfaceOptionsNeedToKnowAppearancePanel
NeedToKnow.OptionSlider = {}

local AppearancePanel = NeedToKnow.AppearancePanel
local OptionSlider = NeedToKnow.OptionSlider
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String


--[[ Appearance panel ]]--

function AppearancePanel:OnLoad()
	self:SetScripts()
	self:SetText()

	-- Register for Blizz Interface Options panel
	self.name = String.APPEARANCE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	self.cancel = NeedToKnow.Cancel
	-- Need different way to handle cancel?  Might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function AppearancePanel:SetScripts()
	self:SetScript("OnShow", self.Update)

	-- Drop down menus
	self:OnLoadBarTextureMenu()
	self:OnLoadBarFontMenu()

	-- Color buttons
	self.backgroundColorButton.variable = "BkgdColor"
	self.borderColorButton.variable = "BorderColor"
	self.fontColorButton.variable = "FontColor"
	for _, button in pairs(self.colorButtons) do
		button:SetScript("OnClick", self.ChooseColor)
		button:RegisterForClicks("LeftButtonUp")
	end

	-- Sliders
	self.barPaddingSlider.variable = "BarPadding"
	self.barPaddingSlider:SetMinMaxValues(0, 12)
	self.barSpacingSlider.variable = "BarSpacing"
	self.barSpacingSlider:SetMinMaxValues(0, 24)
	self.fontSizeSlider.variable = "FontSize"
	self.fontSizeSlider:SetMinMaxValues(5, 20)
	for _, slider in pairs(self.sliders) do
		slider:SetValueStep(0.5)
		OptionSlider.OnLoad(slider)
	end

	self.editModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.editModeButton:SetScript("OnClick", OptionsPanel.OnConfigModeButtonClick)
	self.playModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.playModeButton:SetScript("OnClick", OptionsPanel.OnPlayModeButtonClick)
end

function AppearancePanel:SetText()
	self.title:SetText(addonName.." v"..NeedToKnow.version)
	self.subText:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.barAppearanceTitle:SetText(String.BAR_APPEARANCE)

	self.backgroundColorButton.label:SetText(String.BACKGROUND_COLOR)
	self.borderColorButton.label:SetText(String.BORDER_COLOR)
	self.fontColorButton.label:SetText(String.FONT_COLOR)

	self.barSpacingSlider.label:SetText(String.BAR_SPACING)
	self.barPaddingSlider.label:SetText(String.BORDER_SIZE)
	self.fontSizeSlider.label:SetText(String.FONT_SIZE)
	self.fontOutlineMenu.label:SetText(String.FONT_OUTLINE)
	self.barFontMenu.label:SetText(String.FONT)
	self.barTextureMenu.label:SetText(String.BAR_TEXTURE)

	self.editModeButton.Text:SetText(NeedToKnow.String.EDIT_MODE)
	self.editModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
	self.playModeButton.Text:SetText(NeedToKnow.String.PLAY_MODE)
	self.playModeButton.tooltipText = String.PLAY_MODE_TOOLTIP
end

function AppearancePanel:Update()
	if not self:IsVisible() then return end
	local settings = NeedToKnow.ProfileSettings

	self:UpdateBarTextureMenu()
	self:UpdateBarFontMenu()
	self:UpdateFontOutlineMenu()

	-- local settings = NeedToKnow.ProfileSettings
	-- local r, g, b = unpack(NeedToKnow.ProfileSettings.BkgdColor)
	-- self.backgroundColorButton.normalTexture:SetVertexColor(r, g, b, 1)
	self.backgroundColorButton.normalTexture:SetVertexColor(unpack(settings.BkgdColor))
	self.borderColorButton.normalTexture:SetVertexColor(unpack(settings.BorderColor))
	self.fontColorButton.normalTexture:SetVertexColor(unpack(settings.FontColor))

	for _, slider in pairs(self.sliders) do
		slider:Update()
	end
end


--[[ Bar texture menu ]]--

-- local selectedColor = {0.1, 0.6, 0.8, 1}  -- Blue
local selectedColor = {1, 0.82, 0, 1}  -- NormalFont yellow
local unselectedColor = {0.6, 0.6, 0.6, 1}

function AppearancePanel:OnLoadBarTextureMenu()
	local menu = self.barTextureMenu
	UIDropDownMenu_SetWidth(menu, 172)
	menu.Text:SetDrawLayer("OVERLAY")  -- So it's not behind bar texture
	menu.customButtons = {}
	local button
	for i, textureName in ipairs(NeedToKnow.LSM:List("statusbar")) do
		menu.customButtons[i] = CreateFrame("Button", menu:GetName().."Button"..i, menu, "NeedToKnowBarTextureMenuButtonTemplate")
		button = menu.customButtons[i]
		button.text:SetText(textureName)
		button.texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", textureName))
		button:SetScript("OnClick", AppearancePanel.OnClickBarTextureMenuItem)
	end
end

function AppearancePanel:UpdateBarTextureMenu()
	local menu = self.barTextureMenu
	UIDropDownMenu_Initialize(menu, AppearancePanel.MakeBarTextureMenu)
	UIDropDownMenu_OnHide(DropDownList1)  -- So custom buttons don't show in other menus
	local textureName = NeedToKnow.ProfileSettings.BarTexture
	if textureName then
		menu.Text:SetText(textureName)
		menu.texture:SetTexture(NeedToKnow.LSM:Fetch("statusbar", textureName))
		menu.texture:SetVertexColor(unpack(selectedColor))
	end
end

function AppearancePanel:MakeBarTextureMenu()
	-- Called with self = menu
	local info = {}
	local button
	local currentTexture = NeedToKnow.ProfileSettings.BarTexture
	for i, customButton in ipairs(self.customButtons) do
		info.customFrame = customButton
		button = UIDropDownMenu_AddButton(info)  -- button not returned in Classic_Era
		button = button or _G["DropDownList1Button"..i]
		customButton = button.customFrame
		if currentTexture == customButton.text:GetText() then
			customButton.texture:SetVertexColor(unpack(selectedColor))
		else
			customButton.texture:SetVertexColor(unpack(unselectedColor))
		end
	end
end

function AppearancePanel:OnClickBarTextureMenuItem()
	-- Called with self = customButton
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	NeedToKnow.ProfileSettings.BarTexture = self.text:GetText()
	AppearancePanel:Update()
	NeedToKnow:Update()
end


--[[ Bar font menu ]]--

function AppearancePanel:OnLoadBarFontMenu()
	local menu = self.barFontMenu
	UIDropDownMenu_SetWidth(menu, 172)
	menu.customButtons = {}  -- So we don't change other menus' fonts
	local button
	for i, fontName in ipairs(NeedToKnow.LSM:List("font")) do
		menu.customButtons[i] = CreateFrame("Button", menu:GetName().."Button"..i, menu, "NeedToKnowBarFontMenuButtonTemplate")
		button = menu.customButtons[i]
		button.text:SetText(fontName)
		button.text:SetFont(NeedToKnow.LSM:Fetch("font", fontName), 10)
		button:SetScript("OnClick", AppearancePanel.OnClickBarFontMenuItem)
	end
end

function AppearancePanel:UpdateBarFontMenu()
	local menu = self.barFontMenu
	UIDropDownMenu_Initialize(menu, AppearancePanel.MakeBarFontMenu)
	UIDropDownMenu_OnHide(DropDownList1)  -- So custom buttons don't show in other menus
	local fontName = NeedToKnow.ProfileSettings.BarFont
	if fontName then
		menu.Text:SetText(fontName)
		menu.Text:SetFont(NeedToKnow.LSM:Fetch("font", fontName), 10)
	end
end

function AppearancePanel:MakeBarFontMenu()
	-- Called with self = menu
	local info = {}
	local button
	local currentFont = NeedToKnow.ProfileSettings.BarFont
	for i, customButton in ipairs(self.customButtons) do
		info.customFrame = customButton
		local button = UIDropDownMenu_AddButton(info)  -- button not returned in Classic_Era
		button = button or _G["DropDownList1Button"..i]
		customButton = button.customFrame
		if currentFont == customButton.text:GetText() then
			customButton.check:Show()
			customButton.uncheck:Hide()
		else
			customButton.check:Hide()
			customButton.uncheck:Show()
		end
	end
end

function AppearancePanel:OnClickBarFontMenuItem()
	-- Called with self = customButton
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	NeedToKnow.ProfileSettings.BarFont = self.text:GetText()
	AppearancePanel:Update()
	NeedToKnow:Update()
end


--[[ Font outline menu ]]--

local fontOutlineMenuContents = {
	{text = String.FONT_OUTLINE_NONE, arg1 = 0}, 
	{text = String.FONT_OUTLINE_THIN, arg1 = 1}, 
	{text = String.FONT_OUTLINE_THICK, arg1 = 2}, 
}

function AppearancePanel:UpdateFontOutlineMenu()
	local menu = self.fontOutlineMenu
	UIDropDownMenu_SetWidth(menu, 96)
	UIDropDownMenu_Initialize(menu, AppearancePanel.MakeFontOutlineMenu)

	-- Show current setting
	local setting = NeedToKnow.ProfileSettings.FontOutline
	for i, entry in ipairs(fontOutlineMenuContents) do
		if entry.arg1 == setting then
			UIDropDownMenu_SetText(menu, entry.text)
			break
		end
	end
end

function AppearancePanel:MakeFontOutlineMenu()
	-- Called with self = menu
	local info = {}
	local setting = NeedToKnow.ProfileSettings.FontOutline
	info.func = AppearancePanel.OnFontOutlineMenuClick
	for i, entry in ipairs(fontOutlineMenuContents) do
		info.text = entry.text
		info.arg1 = entry.arg1
		info.arg2 = entry.text
		info.checked = (entry.arg1 == setting)
		UIDropDownMenu_AddButton(info)
	end
end

function AppearancePanel:OnFontOutlineMenuClick(arg1, arg2)
	-- called with self = DropDownList button
	NeedToKnow.ProfileSettings.FontOutline = arg1
	UIDropDownMenu_SetText(AppearancePanel.fontOutlineMenu, arg2)
	NeedToKnow:Update()
end


--[[ Color buttons (background color) ]]--

function AppearancePanel:ChooseColor()
	local info = {}
	info.r, info.g, info.b, info.opacity = unpack(NeedToKnow.ProfileSettings[self.variable])
	info.opacity = 1 - info.opacity
	info.hasOpacity = true
	info.swatchFunc = AppearancePanel.SetColor
	info.opacityFunc = AppearancePanel.SetOpacity
	info.cancelFunc = AppearancePanel.CancelColor
	info.extraInfo = self.variable
	-- Kitjan: Not sure if I should leave this state around or not.  It seems like the
	-- correct strata to have it at anyway, so I'm going to leave it there for now
	ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	OpenColorPicker(info)
end

function AppearancePanel.SetColor()
	local variable = ColorPickerFrame.extraInfo
	local r, g, b = ColorPickerFrame:GetColorRGB()
	NeedToKnow.ProfileSettings[variable][1] = r
	NeedToKnow.ProfileSettings[variable][2] = g
	NeedToKnow.ProfileSettings[variable][3] = b
	NeedToKnow:Update()
	AppearancePanel:Update()
end

function AppearancePanel.SetOpacity()
	local variable = ColorPickerFrame.extraInfo
	NeedToKnow.ProfileSettings[variable][4] = 1 - OpacitySliderFrame:GetValue()
	NeedToKnow:Update()
	AppearancePanel:Update()
end

function AppearancePanel.CancelColor(previousValues)
	if previousValues then
		local variable = ColorPickerFrame.extraInfo
		NeedToKnow.ProfileSettings[variable] = {previousValues.r, previousValues.g, previousValues.b, 1 - previousValues.opacity}
		NeedToKnow:Update()
		AppearancePanel:Update()
	end
end


--[[ Sliders (border size, bar spacing, font size) ]]--

function OptionSlider:OnLoad()
	self.Update = OptionSlider.Update
	self:SetScript("OnValueChanged", OptionSlider.OnValueChanged)
	self.editBox:SetScript("OnTextChanged", OptionSlider.OnEditBoxTextChanged)
	self.editBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
	self.editBox:SetScript("OnEscapePressed", OptionSlider.OnEditBoxEscapePressed)
	self.editBox:SetScript("OnEditFocusLost", OptionSlider.OnEditBoxFocusLost)
end

function OptionSlider:Update()
	local value = NeedToKnow.ProfileSettings[self.variable]
	self:SetValue(value)
	self.editBox:SetText(value)
	self.editBox.oldValue = value
end

function OptionSlider:OnValueChanged(value, isUserInput)
	if isUserInput then
		NeedToKnow.ProfileSettings[self.variable] = value
		self.editBox:SetText(value)
		self.editBox.oldValue = value
		NeedToKnow:Update()
	end
end

function OptionSlider:OnEditBoxTextChanged(isUserInput)
	-- Called with self = editBox
	local value = tonumber(self:GetText())
	if value and isUserInput then
		NeedToKnow.ProfileSettings[self:GetParent().variable] = value
		self:GetParent():SetValue(value)
		NeedToKnow:Update()
	end
end

function OptionSlider:OnEditBoxEscapePressed()
	-- Called with self = editBox
	if self.oldValue then
		NeedToKnow.ProfileSettings[self:GetParent().variable] = self.oldValue
		self:GetParent():SetValue(self.oldValue)
		NeedToKnow:Update()
	end
	EditBox_ClearFocus(self)
end

function OptionSlider:OnEditBoxFocusLost(value)
	-- Called with self = editBox
	local value = tonumber(self:GetText())
	if value then
		self.oldValue = value
	elseif self.oldValue then
		self:SetText(self.oldValue)
	end
	EditBox_ClearHighlight(self)
end


--[[  ]]--

do
	AppearancePanel:OnLoad()
end




