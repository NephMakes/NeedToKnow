-- Interface options panel: Appearance
-- Load OptionsPanel.lua before this file

-- local addonName, addonTable = ...
local AppearancePanel = NeedToKnow.AppearancePanel  -- Temporary. Will be panel frame. 
local OptionsPanel = NeedToKnow.OptionsPanel
local String = NeedToKnow.String

NEEDTOKNOW.MAXBARSPACING = 24
NEEDTOKNOW.MAXBARPADDING = 12

local LSM = LibStub("LibSharedMedia-3.0", true)
local textureList = LSM:List("statusbar")
local fontList = LSM:List("font")


--[[ Appearance panel ]]--

function AppearancePanel:OnLoad()
	AppearancePanel.SetText(self)
	AppearancePanel.SetScripts(self)

	self.name = NEEDTOKNOW.UIPANEL_APPEARANCE
	self.parent = "NeedToKnow"
	self.default = NeedToKnow.ResetCharacter
	self.cancel = NeedToKnowOptions.Cancel
	-- need different way to handle cancel?  users might open appearance panel without opening main panel
	InterfaceOptions_AddCategory(self)
end

function AppearancePanel:SetText()
	self.version:SetText(NeedToKnow.version)
	self.subText:SetText(String.OPTIONS_PANEL_SUBTEXT)

	self.backgroundColorButton.label:SetText(NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR)

	self.Textures.title:SetText("Texture:")
	self.Fonts.title:SetText("Font:")

	self.editModeButton.Text:SetText(NeedToKnow.String.EDIT_MODE)
	self.editModeButton.tooltipText = String.EDIT_MODE_TOOLTIP
	self.playModeButton.Text:SetText(NeedToKnow.String.PLAY_MODE)
	self.playModeButton.tooltipText = String.PLAY_MODE_TOOLTIP
end

function AppearancePanel:SetScripts()
	self:SetScript("OnShow", AppearancePanel.OnShow)
	self:SetScript("OnSizeChanged", AppearancePanel.OnSizeChanged)

	self.backgroundColorButton:SetScript("OnClick", AppearancePanel.ChooseColor)
	self.backgroundColorButton.variable = "BkgdColor"
	self.backgroundColorButton:RegisterForClicks("LeftButtonUp")

	self.barSpacingSlider:SetScript("OnValueChanged", AppearancePanel.OnBarSpacingChanged)
	self.barSpacingSlider:SetMinMaxValues(0, NEEDTOKNOW.MAXBARSPACING)
	self.barSpacingSlider:SetValueStep(0.5)
	self.barSpacingSlider:SetObeyStepOnDrag(true)

	self.barPaddingSlider:SetScript("OnValueChanged", AppearancePanel.OnBarPaddingChanged)
	self.barPaddingSlider:SetMinMaxValues(0, NEEDTOKNOW.MAXBARPADDING)
	self.barPaddingSlider:SetValueStep(0.5)
	self.barPaddingSlider:SetObeyStepOnDrag(true)

	self.fontSizeSlider:SetScript("OnValueChanged", AppearancePanel.OnFontSizeChanged)
	self.fontSizeSlider:SetMinMaxValues(5, 20)
	self.fontSizeSlider:SetValueStep(0.5)
	self.fontSizeSlider:SetObeyStepOnDrag(true)

	self.fontOutlineSlider:SetScript("OnValueChanged", AppearancePanel.OnFontOutlineChanged)
	self.fontOutlineSlider:SetMinMaxValues(0, 2)
	self.fontOutlineSlider:SetValueStep(1)
	self.fontOutlineSlider:SetObeyStepOnDrag(true)

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

	self.barSpacingSlider:SetValue(settings.BarSpacing)
	self.barPaddingSlider:SetValue(settings.BarPadding)
	self.fontSizeSlider:SetValue(settings.FontSize)
	self.fontOutlineSlider:SetValue(settings.FontOutline)

	AppearancePanel.UpdateBarTextureDropDown()
	AppearancePanel.UpdateBarFontDropDown()
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


--[[ Background color ]]--

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


--[[ Sliders ]]--

function AppearancePanel:OnBarSpacingChanged(value)
	-- Called with self = slider
	NeedToKnow.ProfileSettings["BarSpacing"] = value
	self.Text:SetText(NEEDTOKNOW.UIPANEL_BARSPACING..": "..value)
	NeedToKnow:Update()
end

function AppearancePanel:OnBarPaddingChanged(value)
	-- Called with self = slider
	NeedToKnow.ProfileSettings["BarPadding"] = value
	self.Text:SetText(NEEDTOKNOW.UIPANEL_BARPADDING..": "..value)
	NeedToKnow:Update()
end

function AppearancePanel:OnFontSizeChanged(value)
	-- Called with self = slider
	NeedToKnow.ProfileSettings["FontSize"] = value
	self.Text:SetText("Font Size: "..value)
	NeedToKnow:Update()
end

function AppearancePanel:OnFontOutlineChanged(value)
	-- Called with self = slider
	NeedToKnow.ProfileSettings["FontOutline"] = value
	local str
	if value == 0 then
		str = "None"
	elseif value == 1 then
		str = "Normal"
	else
		str = "Heavy"
	end
	self.Text:SetText("Font Outline: "..str)
	NeedToKnow:Update()
end
