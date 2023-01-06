-- Interface options panel: Appearance
-- Load after OptionsPanel.lua, ApperancePanel.xml

local addonName, addonTable = ...
NeedToKnow.AppearancePanel = _G["InterfaceOptionsNeedToKnowAppearancePanel"]
NeedToKnow.OptionSlider = {}
NeedToKnow.ScrollFrame = {}
local AppearancePanel = NeedToKnow.AppearancePanel
local OptionSlider = NeedToKnow.OptionSlider
local ScrollFrame = NeedToKnow.ScrollFrame

local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

local LSM = LibStub("LibSharedMedia-3.0", true)
local textureList = LSM:List("statusbar")
local fontList = LSM:List("font")


--[[ Appearance panel ]]--

function AppearancePanel:OnLoad()
	self:SetScripts()
	self:SetText()

	self.name = NEEDTOKNOW.UIPANEL_APPEARANCE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	self.cancel = NeedToKnowOptions.Cancel
	-- need different way to handle cancel?  users might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function AppearancePanel:SetScripts()
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnSizeChanged", self.OnSizeChanged)

	self.backgroundColorButton.variable = "BkgdColor"
	self.backgroundColorButton:SetScript("OnClick", self.ChooseColor)
	self.backgroundColorButton:RegisterForClicks("LeftButtonUp")

	-- Sliders
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

	self.Textures.variable = "BarTexture"
	-- self.Textures.itemList = textureList
	self.Textures.itemList = LSM:List("statusbar")
	self.Textures.fnClick = ScrollFrame.OnClickScrollItem
	self.Textures.configure = function(i, btn, label) 
		btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", label))
	end
	self.Textures.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
	self.Textures.List.update = AppearancePanel.UpdateBarTextureScrollFrame
	self.Textures.normal_color =  {0.7, 0.7, 0.7, 1}

	self.Fonts.variable = "BarFont"
	-- self.Fonts.itemList = fontList
	self.Fonts.itemList = LSM:List("font")
	self.Fonts.fnClick = ScrollFrame.OnClickScrollItem
	self.Fonts.configure = function(i, btn, label) 
		local fontPath = NeedToKnow.LSM:Fetch("font", label)
		btn.text:SetFont(fontPath, 12)
		btn.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", "Minimalist"))
	end
	self.Fonts.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
	self.Fonts.List.update = AppearancePanel.UpdateBarFontScrollFrame

	self.editModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.editModeButton:SetScript("OnClick", OptionsPanel.OnConfigModeButtonClick)
	self.playModeButton:SetScript("OnEnter", OptionsPanel.OnWidgetEnter)
	self.playModeButton:SetScript("OnClick", OptionsPanel.OnPlayModeButtonClick)
end

function AppearancePanel:SetText()
	self.title:SetText(addonName.." v"..NeedToKnow.version)
	self.subText:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.backgroundColorButton.label:SetText(NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR)

	self.barSpacingSlider.label:SetText("Bar spacing")
	self.barPaddingSlider.label:SetText("Border size")
	self.fontSizeSlider.label:SetText("Font size")
	self.fontOutlineMenu.label:SetText("Font outline")

	self.Textures.title:SetText("Bar texture")
	self.Fonts.title:SetText("Bar font")

	self.editModeButton.Text:SetText(NeedToKnow.String.EDIT_MODE)
	self.editModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
	self.playModeButton.Text:SetText(NeedToKnow.String.PLAY_MODE)
	self.playModeButton.tooltipText = String.PLAY_MODE_TOOLTIP
end

function AppearancePanel:OnShow()
	self:Update()

	-- Kitjan: Cache this? Update needs it to
	-- self:OnTextureScrollFrameShow()
	-- self:OnBarFontScrollFrameShow()
	ScrollFrame.OnShow(self.Textures)
	ScrollFrame.OnShow(self.Fonts)
end

function AppearancePanel:Update()
	if not self:IsVisible() then return end
	local settings = NeedToKnow.ProfileSettings

	local r, g, b = unpack(settings.BkgdColor)
	self.backgroundColorButton.normalTexture:SetVertexColor(r, g, b, 1)

	for _, slider in pairs(self.sliders) do
		slider:Update()
	end
	self:UpdateFontOutlineMenu()

	self:UpdateBarTextureScrollFrame()
	self:UpdateBarFontScrollFrame()
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


--[[ Scroll frames (BarTexture, BarFont) ]]--

ScrollFrame.normalColor = {0.7, 0.7, 0.7, 0}
ScrollFrame.selectedColor = {0.1, 0.6, 0.8, 1}

function ScrollFrame:OnLoad()
end

function ScrollFrame:OnShow()
	local scrollIndex = 1
	for i = 1, #self.itemList do
		if NeedToKnow.ProfileSettings[self.variable] == self.itemList[i] then
			scrollIndex = i
			break
		end
	end
	scrollIndex = scrollIndex - 1
	self.List.scrollBar:SetValue(scrollIndex * self.List.buttonHeight + 0.1)
	HybridScrollFrame_OnMouseWheel(self.List, 1, 0.1)
end

function ScrollFrame:OnSizeChanged()
    local old_value = self.scrollBar:GetValue()
    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
    -- local scrollFrame = self:GetParent()
    -- scrollFrame.Update(scrollFrame)
    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value))
end

-- function NeedToKnowOptions.OnScrollFrameScrolled(self)
	-- local scrollPanel = self:GetParent()
	-- local fn = scrollPanel.Update
	-- if fn then fn(scrollPanel) end
-- end

function ScrollFrame:Update(list, selected, checked)
	local panelList = self.List
	local buttons = self.List.buttons
	HybridScrollFrame_Update(panelList, #(list) * buttons[1]:GetHeight(), panelList:GetHeight())

	local label
	for i = 1, #buttons do
		label = list[i + HybridScrollFrame_GetOffset(panelList)]
		if label then
			buttons[i]:Show()
			buttons[i].text:SetText(label)

			if label == checked then
				buttons[i].Check:Show()
			else
				buttons[i].Check:Hide()
			end
			if label == selected then
				local color = self.selected_color or ScrollFrame.selectedColor
				buttons[i].Bg:SetVertexColor(unpack(color))
			else
				local color = self.normal_color or ScrollFrame.normalColor
				buttons[i].Bg:SetVertexColor(unpack(color))
			end

			self.configure(i, buttons[i], label)
		else
			buttons[i]:Hide()
		end
	end
end

function ScrollFrame:OnClickScrollItem()
	-- Called with self = scroll item
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	scrollFrame = self:GetParent():GetParent():GetParent()
	NeedToKnow.ProfileSettings[scrollFrame.variable] = self.text:GetText()
	NeedToKnow:Update()
	AppearancePanel:Update()
end

function AppearancePanel:UpdateBarTextureScrollFrame()
	local settings = NeedToKnow.ProfileSettings
	local scrollFrame = AppearancePanel.Textures
	ScrollFrame.Update(scrollFrame, scrollFrame.itemList, settings.BarTexture, settings.BarTexture)
end

function AppearancePanel:UpdateBarFontScrollFrame()
	local settings = NeedToKnow.ProfileSettings
	local scrollFrame = AppearancePanel.Fonts
	ScrollFrame.Update(scrollFrame, scrollFrame.itemList, nil, settings.BarFont)
end


--[[ Bar Font ]]--

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


--[[ Color buttons (background color) ]]--

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


--[[ Sliders (bar spacing, bar padding, font size) ]]--

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


--[[ Font outline menu ]]--

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
	-- UIDropDownMenu_SetText(AppearancePanel.fontOutlineMenu, arg2)
end


do
	AppearancePanel:OnLoad()
end
