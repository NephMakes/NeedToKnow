-- Interface options panel: Appearance
-- Load after OptionsPanel.lua, ApperancePanel.xml

-- local addonName, addonTable = ...
local AppearancePanel = NeedToKnow.AppearancePanel  -- Temporary. Will be panel frame. 
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

NeedToKnow.OptionSlider = {}
local OptionSlider = NeedToKnow.OptionSlider

--NEEDTOKNOW.MAXBARSPACING = 24
--NEEDTOKNOW.MAXBARPADDING = 12

local LSM = LibStub("LibSharedMedia-3.0", true)
local textureList = LSM:List("statusbar")
local fontList = LSM:List("font")


--[[ Appearance panel ]]--

function AppearancePanel:OnLoad()
	AppearancePanel.SetScripts(self)
	AppearancePanel.SetText(self)

	self.name = NEEDTOKNOW.UIPANEL_APPEARANCE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	self.cancel = NeedToKnowOptions.Cancel
	-- need different way to handle cancel?  users might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function AppearancePanel:SetScripts()
	self:SetScript("OnShow", AppearancePanel.OnShow)
	self:SetScript("OnSizeChanged", AppearancePanel.OnSizeChanged)

	self.backgroundColorButton.variable = "BkgdColor"
	self.backgroundColorButton:SetScript("OnClick", AppearancePanel.ChooseColor)
	self.backgroundColorButton:RegisterForClicks("LeftButtonUp")

	self.barSpacingSlider.variable = "BarSpacing"
	self.barSpacingSlider:SetMinMaxValues(0, 24)
	self.barSpacingSlider:SetValueStep(0.5)

	self.barPaddingSlider.variable = "BarPadding"
	self.barPaddingSlider:SetMinMaxValues(0, 12)
	self.barPaddingSlider:SetValueStep(0.5)

	self.fontSizeSlider.variable = "FontSize"
	self.fontSizeSlider:SetMinMaxValues(5, 20)
	self.fontSizeSlider:SetValueStep(0.5)

	for _, slider in pairs(self.sliders) do
		OptionSlider.OnLoad(slider)
	end

	self.Textures.fnClick = AppearancePanel.OnClickTextureItem
	self.Textures.configure = function(i, btn, label) 
		btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", label))
	end
	self.Textures.List.update = AppearancePanel.UpdateBarTextureDropDown
	self.Textures.normal_color =  { 0.7, 0.7, 0.7, 1 }

	self.Fonts.fnClick = AppearancePanel.OnClickFontItem
	self.Fonts.configure = function(i, btn, label) 
		local fontPath = NeedToKnow.LSM:Fetch("font", label)
		btn.text:SetFont(fontPath, 12)
		btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", "Minimalist"))
	end
	self.Fonts.List.update = AppearancePanel.UpdateBarFontDropDown

	self.editModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.editModeButton:SetScript("OnClick", OptionsPanel.OnConfigModeButtonClick)
	self.playModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.playModeButton:SetScript("OnClick", OptionsPanel.OnPlayModeButtonClick)
end

function AppearancePanel:SetText()
	self.version:SetText(NeedToKnow.version)
	self.subText:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.backgroundColorButton.label:SetText(NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR)

	self.barSpacingSlider.label:SetText("Bar spacing")
	self.barPaddingSlider.label:SetText("Bar padding")
	self.fontSizeSlider.label:SetText("Font size")
	self.fontOutlineMenu.label:SetText("Font outline")

	self.Textures.title:SetText("Texture:")
	self.Fonts.title:SetText("Font:")

	self.editModeButton.Text:SetText(NeedToKnow.String.EDIT_MODE)
	self.editModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
	self.playModeButton.Text:SetText(NeedToKnow.String.PLAY_MODE)
	self.playModeButton.tooltipText = String.PLAY_MODE_TOOLTIP
end

function AppearancePanel:OnShow()
	AppearancePanel:Update()

	-- todo: Cache this? Update needs it to
	local idxCurrent = 1
	for i = 1, #textureList do
		if NeedToKnow.ProfileSettings["BarTexture"] == textureList[i] then
			idxCurrent = i
			break
		end
	end
	local idxScroll = idxCurrent - 3
	if idxScroll < 0 then
		idxScroll = 0
	end
	self.Textures.List.scrollBar:SetValue(idxScroll * self.Textures.List.buttonHeight + 0.1)
	HybridScrollFrame_OnMouseWheel(self.Textures.List, 1, 0.1)

	for i = 1, #fontList do
		if NeedToKnow.ProfileSettings["BarFont"] == fontList[i] then
			idxCurrent = i
			break
		end
	end
	idxScroll = idxCurrent - 3
	if idxScroll < 0 then
		idxScroll = 0
	end
	self.Fonts.List.scrollBar:SetValue(idxScroll * self.Fonts.List.buttonHeight + 0.1)
	HybridScrollFrame_OnMouseWheel(self.Fonts.List, 1, 0.1)
end

function AppearancePanel:Update()
	local self = _G["InterfaceOptionsNeedToKnowAppearancePanel"]
	if not self or not self:IsVisible() then return end

	local settings = NeedToKnow.ProfileSettings

	-- Mimic BarMenu behavior and force swatch alpha = 1
	local r, g, b = unpack(settings.BkgdColor)
	self.backgroundColorButton.normalTexture:SetVertexColor(r, g, b, 1)

	for _, slider in pairs(self.sliders) do
		slider:Update()
	end
	AppearancePanel.UpdateFontOutlineMenu(self)

	AppearancePanel.UpdateBarTextureDropDown()
	AppearancePanel.UpdateBarFontDropDown()
	-- AppearancePanel.UpdateBarFontMenu(self)
end

function AppearancePanel:OnSizeChanged()
	-- Kitjan: Despite my best efforts, the scroll bars insist on being outside the width of their
	local mid = self:GetWidth()/2 --+ _G[self:GetName().."TexturesListScrollBar"]:GetWidth()
	local textures = self.Textures
	local leftTextures = textures:GetLeft()
	if mid and mid > 0 and textures and leftTextures then
		local ofs = leftTextures - self:GetLeft()
		textures:SetWidth(mid - ofs)
	end
end


--[[ Bar Texture ]]--

function AppearancePanel.UpdateBarTextureDropDown()
    local scrollPanel = _G["InterfaceOptionsNeedToKnowAppearancePanelTextures"]
    NeedToKnowOptions.UpdateScrollPanel(scrollPanel, textureList, NeedToKnow.ProfileSettings.BarTexture, NeedToKnow.ProfileSettings.BarTexture)
end

function AppearancePanel.OnClickTextureItem(self)
	NeedToKnow.ProfileSettings["BarTexture"] = self.text:GetText()
	NeedToKnow:Update()
	AppearancePanel:Update()
end


--[[ Bar Font ]]--

function AppearancePanel.UpdateBarFontDropDown()
    local scrollPanel = _G["InterfaceOptionsNeedToKnowAppearancePanelFonts"]
    NeedToKnowOptions.UpdateScrollPanel(scrollPanel, fontList, nil, NeedToKnow.ProfileSettings.BarFont)
end

function AppearancePanel.OnClickFontItem(self)
	NeedToKnow.ProfileSettings["BarFont"] = self.text:GetText()
	NeedToKnow:Update()
	AppearancePanel:Update()
end

--[[
function AppearancePanel:UpdateBarFontMenu()
	local menu = self.barFontMenu
	UIDropDownMenu_SetWidth(menu, 180)
	UIDropDownMenu_Initialize(menu, AppearancePanel.MakeBarFontMenu)
end

function AppearancePanel:MakeBarFontMenu()
	-- Called with self = menu
	local info = {}
	local listFrame = _G["DropDownList1"]
	local exampleFont = CreateFont("NeedToKnow_BarFontExample")
	local button
	for _, fontName in ipairs(fontList) do
		info.text = fontName
		info.checked = (NeedToKnow.ProfileSettings["BarFont"] == fontName)
		-- exampleFont:SetFont(NeedToKnow.LSM:Fetch("font", fontName), 12)
		-- info.fontObject = exampleFont
		button = UIDropDownMenu_AddButton(info)
		-- local buttonText = _G[button:GetName().."NormalText"]
		-- buttonText:SetFont(NeedToKnow.LSM:Fetch("font", fontName), 12)
	end
end
]]--


--[[ Color buttons ]]--

function AppearancePanel:ChooseColor()
	local variable = self.variable
	info = UIDropDownMenu_CreateInfo()
	info.r, info.g, info.b, info.opacity = unpack(NeedToKnow.ProfileSettings[variable])
	info.opacity = 1 - info.opacity
	info.hasOpacity = true
	info.swatchFunc = AppearancePanel.SetColor
	info.opacityFunc = AppearancePanel.SetOpacity
	info.cancelFunc = AppearancePanel.CancelColor
	info.extraInfo = variable
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
		NeedToKnow.ProfileSettings[variable] = {previousValues.r, previousValues.g, previousValues.b, previousValues.opacity}
		NeedToKnow:Update()
		AppearancePanel:Update()
	end
end


--[[ Font outline ]]--

local fontOutlineMenuContents = {
	{text = "None", arg1 = 0}, 
	{text = "Thin", arg1 = 1}, 
	{text = "Thick", arg1 = 2}, 
}

function AppearancePanel:UpdateFontOutlineMenu()
	local menu = self.fontOutlineMenu
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
	NeedToKnow:Update()
	local panel = _G["InterfaceOptionsNeedToKnowAppearancePanel"]
	UIDropDownMenu_SetText(panel.fontOutlineMenu, arg2)
end



--[[ Sliders ]]--

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

