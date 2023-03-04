-- Load after AppearancePanel.lua

local addonName, addonTable = ...
NeedToKnow.ScrollFrame = {}
local ScrollFrame = NeedToKnow.ScrollFrame


-- -----------------------------------
-- INTERFACE OPTIONS PANEL: PROFILE
-- -----------------------------------

-- NeedToKnowOptions.DefaultSelectedColor = {0.1, 0.6, 0.8, 1}
-- NeedToKnowOptions.DefaultNormalColor = {0.7, 0.7, 0.7, 0}



--[[ ScrollFrame ]]-- 

-- From AppearancePanel.SetScripts():
-- 
--	self.Textures.variable = "BarTexture"
--	self.Textures.itemList = LSM:List("statusbar")
--	self.Textures.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
--	self.Textures.List.update = AppearancePanel.UpdateBarTextureScrollFrame
--	self.Textures.updateButton = function(button, label) 
--		button.Bg:SetTexture(NeedToKnow.LSM:Fetch("statusbar", label))
--	end
--	self.Textures.normal_color = {0.7, 0.7, 0.7, 1}
--	self.Textures.onClick = AppearancePanel.OnClickScrollItem
-- 
--	self.Fonts.variable = "BarFont"
--	self.Fonts.itemList = LSM:List("font")
--	self.Fonts.List:SetScript("OnSizeChanged", ScrollFrame.OnSizeChanged)
--	self.Fonts.List.update = AppearancePanel.UpdateBarFontScrollFrame
--	self.Fonts.updateButton = function(button, label) 
--		button.text:SetFont(NeedToKnow.LSM:Fetch("font", label), 12)
--	end
--	self.Fonts.onClick = AppearancePanel.OnClickScrollItem

--[[
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
]]--

ScrollFrame.normalColor = {0.7, 0.7, 0.7, 0}
ScrollFrame.selectedColor = {0.1, 0.6, 0.8, 1}

function ScrollFrame:OnLoad()
end

function ScrollFrame:OnShow()
	-- Scroll to selected option
	local scrollIndex = 1
	for i = 1, #self.itemList do
		if NeedToKnow.ProfileSettings[self.variable] == self.itemList[i] then
			scrollIndex = i
			break
		end
	end
	scrollIndex = scrollIndex - 1
	self.List.scrollBar:SetValue(scrollIndex * self.List.buttonHeight + 0.1)
	HybridScrollFrame_OnMouseWheel(self.List, 1, 0.1)  -- Neph: Why is this here?
end

function ScrollFrame:OnSizeChanged()
	-- called with self = scrollFrame.List
    HybridScrollFrame_CreateButtons(self, "NeedToKnowScrollItemTemplate")
	for _, button in pairs(self.buttons) do
		button:SetScript("OnClick", 
			function()
				local scrollFrame = self:GetParent()
				scrollFrame.onClick(button)
			end
		)
	end
    local old_value = self.scrollBar:GetValue()
    local max_value = self.range or self:GetHeight()
    self.scrollBar:SetValue(min(old_value, max_value))
end

-- function NeedToKnowOptions.OnScrollFrameScrolled(self)
	-- local scrollPanel = self:GetParent()
	-- local fn = scrollPanel.Update
	-- if fn then fn(scrollPanel) end
-- end

function ScrollFrame:UpdateScrollItems(selectedItem, checkedItem)
	-- Called with self = scrollFrame
	local itemList = self.itemList
	local listFrame = self.List
	local buttons = listFrame.buttons
	HybridScrollFrame_Update(listFrame, #(itemList) * buttons[1]:GetHeight(), listFrame:GetHeight())

	local label
	for i, button in ipairs(buttons) do
		label = itemList[i + HybridScrollFrame_GetOffset(listFrame)]
		if label then
			button:Show()
			button.text:SetText(label)

			if label == selectedItem then
				local color = self.selected_color or ScrollFrame.selectedColor
				button.Bg:SetVertexColor(unpack(color))
			else
				local color = self.normal_color or ScrollFrame.normalColor
				button.Bg:SetVertexColor(unpack(color))
			end

			if label == checkedItem then
				button.Check:Show()
			else
				button.Check:Hide()
			end

			self.updateButton(button, label)
		else
			button:Hide()
		end
	end
end

--[[
function AppearancePanel:UpdateBarTextureScrollFrame()
	-- called by AppearancePanel:Update(), HybridScrollFrame_SetOffset()
	local scrollFrame = AppearancePanel.Textures
	local settings = NeedToKnow.ProfileSettings
	ScrollFrame.UpdateScrollItems(scrollFrame, settings.BarTexture, settings.BarTexture)
end

function AppearancePanel:UpdateBarFontScrollFrame()
	-- called by AppearancePanel:Update(), HybridScrollFrame_SetOffset()
	local scrollFrame = AppearancePanel.Fonts
	local settings = NeedToKnow.ProfileSettings
	ScrollFrame.UpdateScrollItems(scrollFrame, nil, settings.BarFont)
end

function AppearancePanel:OnClickScrollItem()
	-- Called with self = list button
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	scrollFrame = self:GetParent():GetParent():GetParent()
	NeedToKnow.ProfileSettings[scrollFrame.variable] = self.text:GetText()
	NeedToKnow:Update()
	AppearancePanel:Update()
end
]]--

--[[
function NeedToKnowOptions.UpdateScrollPanel(panel, itemList, selectedItem, checkedItem)
	-- local itemList = self.itemList
	local listFrame = panel.List
	local buttons = listFrame.buttons
	HybridScrollFrame_Update(listFrame, #itemList * buttons[1]:GetHeight(), listFrame:GetHeight())

	local label
	for i, button in ipairs(buttons) do
		label = itemList[i + HybridScrollFrame_GetOffset(listFrame)]
		if label then
			button:Show()
			button.text:SetText(label)

			if label == selectedItem then
				button.Bg:SetVertexColor(0.1, 0.6, 0.8, 1)
			else
				button.Bg:SetVertexColor(0.7, 0.7, 0.7, 0)
			end

			if label == checkedItem then
				button.Check:Show()
			else
				button.Check:Hide()
			end
		else
			button:Hide()
		end
	end
end
]]--


