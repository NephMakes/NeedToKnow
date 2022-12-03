--[[ Nephilist Options Library v0.6 ]]--

-- Caveats: 
--   CheckButton variables must be boolean (not 1/0)
--   ColorPicker variables must be format {r = 0, g = 0, b = 0}

-- Not yet implemented: 
--   ColorPicker opacity
--   Dependent controls (control:Enable(), control:Disable())
--   Option subcategories
--   "Requires UI reload" popup

local addonName, addonTable = ...; 
local MyAddon = addonTable; 


--[[ Options handling ]]--

function MyAddon.CopyTable(source)
	local copy = {};
	for key, value in pairs(source) do
		if ( type(value) == "table" ) then
			copy[key] = CopyTable(value);
		else
			copy[key] = value;
		end
	end
	return copy;
end
local CopyTable = MyAddon.CopyTable;

local function UpdateTable(destination, source)
	for key, value in pairs(source) do
		if ( type(value) == "table" ) then
			destination[key] = destination[key] or {};
			destination[key] = UpdateTable(destination[key], value);
		elseif ( destination[key] == nil ) then
			destination[key] = value;
		end
	end
	return destination;
end

function MyAddon:UpdateOptions(savedVariablesName, defaults, reset)
	local options = _G[savedVariablesName];
	if ( options and not reset ) then
		options = UpdateTable(options, defaults);
		options.Version = GetAddOnMetadata(addonName, "Version");
	else
		options = CopyTable(defaults); 
		_G[savedVariablesName] = options;
	end
	return options;
end

function MyAddon:GetOption(optionName, options)
	return options[optionName]; 
end

function MyAddon:SetOption(optionName, value, options)
	options[optionName] = value; 
end


--[[ Interface options panel ]]--

function MyAddon:CreateOptionsPanel() 
	local name = "InterfaceOptions"..addonName.."Panel"
	-- local optionsPanel = CreateFrame("Frame", name, InterfaceOptionsFramePanelContainer); 
		-- InterfaceOptionsFramePanelContainer removed in patch 10.0.0
	local optionsPanel = CreateFrame("Frame", name); 

	local title = GetAddOnMetadata(addonName, "Title");
	local version = GetAddOnMetadata(addonName, "Version");
	optionsPanel.title = optionsPanel:CreateFontString(nil, nil, "GameFontNormalLarge");
	optionsPanel.title:SetPoint("TOPLEFT", 16, -16);
	optionsPanel.title:SetText(title.." v"..version);

	optionsPanel.subtext = optionsPanel:CreateFontString(nil, nil, "GameFontHighlightSmall");
	optionsPanel.subtext:SetPoint("TOPLEFT", optionsPanel.title, "BOTTOMLEFT", 0, -8);
	optionsPanel.subtext:SetPoint("RIGHT", optionsPanel, "RIGHT", -32, 0);
	optionsPanel.subtext:SetJustifyH("LEFT");
	optionsPanel.subtext:SetText("");

	optionsPanel.CreateCheckButton = MyAddon.CreateCheckButton;
	optionsPanel.CreateSlider = MyAddon.CreateSlider;
	optionsPanel.CreateDropDownMenu = MyAddon.CreateDropDownMenu;
	optionsPanel.CreateColorPicker = MyAddon.CreateColorPicker;

	optionsPanel.name = addonName;
	optionsPanel.refresh = MyAddon.OptionsPanelRefresh;
	optionsPanel.cancel = MyAddon.OptionsPanelCancel;
	optionsPanel.default = MyAddon.OptionsPanelDefaults;
	optionsPanel.okay = MyAddon.OptionsPanelOkay;
	InterfaceOptions_AddCategory(optionsPanel);

	-- optionsPanel:RegisterEvent("ADDON_LOADED");
	-- optionsPanel:SetScript("OnEvent",  MyAddon.OptionsPanel_OnEvent);

	return optionsPanel;
end
-- Usage: 
--   optionsPanel = MyAddon:CreateOptionsPanel()
--   optionsPanel.savedVariablesName = "MySavedVariables"
--   optionsPanel.okayFunc = DoMoreOnClickOkay
--   optionsPanel.defaults = myDefaults
--   optionsPanel.defaultsFunc = DoMoreOnClickDefaults

--[[
function MyAddon:OptionsPanel_OnEvent(event, ...)
	if ( event == "ADDON_LOADED" ) then
		local arg1 = ...;
		if ( arg1 == addonName ) then
			self.options = _G[self.savedVariablesName];
			-- This can throw an error if saved variables don't exist yet and 
			-- and UpdateOptions() is called on ADDON_LOADED before this is. 
			-- Putting OptionsLibrary.lua later in the toc will fix it, but it's not ideal.   
		end		
	end
end
]]--

function MyAddon:RegisterControl(control, optionsPanel)
	if ( control and optionsPanel ) then
		optionsPanel.controls = optionsPanel.controls or {};
		tinsert(optionsPanel.controls, control);
	end
end

function MyAddon:OptionsPanelRefresh()
	-- Called OnShow()
	self.options = _G[self.savedVariablesName];
	for _, control in next, self.controls do
		control:Refresh();
		control.oldValue = control.value;
	end
end

function MyAddon:OptionsPanelCancel()
	for _, control in next, self.controls do
		MyAddon:SetOption(control.optionName, control.oldValue, self.options);
		if ( control.onValueChanged ) then
			control.onValueChanged(control.oldValue);
		end
	end
end

function MyAddon:OptionsPanelDefaults()
	MyAddon:UpdateOptions(self.savedVariablesName, self.defaults, true)
	self.options = _G[self.savedVariablesName];
	for _, control in next, self.controls do
		-- local defaultValue = self.defaults[control.optionName];
		MyAddon:SetOption(control.optionName, self.defaults[control.optionName], self.options);
		control:Refresh();
		if ( control.onValueChanged ) then
			control.onValueChanged(control.value);
		end
	end
	if ( self.defaultsFunc ) then
		self.defaultsFunc();  -- For options without panel controls, for example
	end
end

function MyAddon:OptionsPanelOkay() 
	if ( self.okayFunc ) then
		self.okayFunc();
	end
end


--[[ CheckButton ]]--

function MyAddon:CreateCheckButton(optionName)
	local name = self:GetName()..optionName.."CheckButton";
	local checkButton = CreateFrame("CheckButton", name, self, "InterfaceOptionsCheckButtonTemplate");
	checkButton.optionName = optionName;
	checkButton:SetScript("OnClick", MyAddon.CheckButtonOnClick);
	checkButton:SetScript("OnEnter", MyAddon.CheckButtonOnEnter);
	checkButton:SetScript("OnLeave", MyAddon.CheckButtonOnLeave);
	checkButton.Refresh = MyAddon.CheckButtonRefresh;
	MyAddon:RegisterControl(checkButton, self); 
	return checkButton;
end
-- Usage: 
--   myButton = optionsPanel:CreateCheckButton("SomeOption")
--   myButton.Text:SetText("Some option")
--   myButton.tooltipText = "Some tooltip text"
--   myButton.onValueChanged = DoSomethingOnClick

function MyAddon:CheckButtonOnClick()
	--[[
	local isChecked = self:GetChecked();
	if ( isChecked ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
	self.value = isChecked;
	]]--
	if ( self:GetChecked() ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
	local value = false;
	if ( self:GetChecked() ) then
		value = true;
	end
	self.value = value;
	MyAddon:SetOption(self.optionName, value, self:GetParent().options);
	if ( self.onValueChanged ) then
		self.onValueChanged(value);
	end
end

function MyAddon:CheckButtonRefresh()
	local value = MyAddon:GetOption(self.optionName, self:GetParent().options);
	self:SetChecked(value);
	self.value = value;
end

function MyAddon:CheckButtonOnEnter()
	if ( self.tooltipText ) then
		GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT");
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	end
	if ( self.tooltipRequirement ) then
		GameTooltip:AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end
end

function MyAddon:CheckButtonOnLeave()
	GameTooltip:Hide();
end


--[[ Slider ]]--

function MyAddon:CreateSlider(optionName)
	local name = self:GetName()..optionName.."Slider";
	local slider = CreateFrame("Slider", name, self, "OptionsSliderTemplate");
	slider.optionName = optionName;
	slider:SetScript("OnValueChanged", MyAddon.SliderOnValueChanged);
	slider:SetScript("OnEnter", MyAddon.SliderOnEnter);
	slider:SetScript("OnLeave", MyAddon.SliderOnLeave);
	slider.Refresh = MyAddon.SliderRefresh;
	MyAddon:RegisterControl(slider, self); 
	slider.Text = _G[slider:GetName().."Text"];  -- No key in template :(
	return slider;
end
-- Usage: 
--   mySlider = optionsPanel:CreateSlider("SomeOption")
--   mySlider.Text:SetText("Some option")
--   mySlider:SetMinMaxValues(min, max)
--   mySlider.onValueChanged = DoSomethingOnAdjust

function MyAddon:SliderOnValueChanged(value)
	MyAddon:SetOption(self.optionName, value, self:GetParent().options);
	self.value = value;
	if ( self.onValueChanged ) then
		self.onValueChanged(value);
	end
end

function MyAddon:SliderRefresh()
	value = MyAddon:GetOption(self.optionName, self:GetParent().options);
	self:SetValue(value);
	self.value = value;
end

function MyAddon:SliderOnEnter()
	if ( self.tooltipText ) then
		GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT");
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	end
	if ( self.tooltipRequirement ) then
		GameTooltip:AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end
end

function MyAddon:SliderOnLeave()
	GameTooltip:Hide();
end



--[[ DropDownMenu]]--

function MyAddon:CreateDropDownMenu(optionName)
	local name = self:GetName()..optionName.."DropDown";
	local dropDownMenu = CreateFrame("Frame", name, self, "UIDropDownMenuTemplate");
	dropDownMenu.optionName = optionName;
	dropDownMenu.Text = dropDownMenu:CreateFontString(nil, nil, "GameFontHighlight");
	dropDownMenu.Text:SetPoint("LEFT", dropDownMenu, "LEFT", 30, 2);
	dropDownMenu.Text:SetText("Dropdown menu text");
	dropDownMenu.Label = dropDownMenu:CreateFontString(nil, nil, "GameFontNormal");
	dropDownMenu.Label:SetPoint("BOTTOMLEFT", dropDownMenu, "TOPLEFT", 16, 3);
	dropDownMenu.Label:SetText("Dropdown menu label");
	dropDownMenu.Refresh = MyAddon.DropDownMenuRefresh;
	MyAddon:RegisterControl(dropDownMenu, self); 
	return dropDownMenu;
end
-- Usage:
--   myMenu = optionsPanel:CreateDropDownMenu("SomeOption")
--   myMenu.Text:SetText("Some option")
--   myMenu.onValueChanged = DoSomethingOnItemSelect
--   myMenu.optionList = menuList  -- Each item formatted {text = text, value = value}

function MyAddon:DropDownMenuRefresh()
	local value = MyAddon:GetOption(self.optionName, self:GetParent().options);
	self.value = value;
	UIDropDownMenu_Initialize(self, MyAddon.DropDownMenuInitialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);
end

function MyAddon:DropDownMenuInitialize(level, menuList)
	-- When called, self is DropDownMenu
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();
	for _, listItem in next, self.optionList do
		info.text = listItem.text;
		info.value = listItem.value;
		info.func = MyAddon.DropDownMenuOnClick;
		info.arg1 = self;
		if ( info.value == selectedValue ) then
			info.checked = 1;
		else
			info.checked = nil;
		end
		UIDropDownMenu_AddButton(info);
	end
end

function MyAddon:DropDownMenuOnClick(dropDownMenu)
	-- When called, self is DropDownList button
	MyAddon:SetOption(dropDownMenu.optionName, self.value, _G[dropDownMenu:GetParent().savedVariablesName]);
	if ( dropDownMenu.onValueChanged ) then
		dropDownMenu.onValueChanged(self.value);
	end
	UIDropDownMenu_SetSelectedValue(dropDownMenu, self.value);
end



--[[ ColorPicker ]]-- 

function MyAddon:GetColor(color)
	local r, g, b = color.r, color.g, color.b;
	return r, g, b;
end

function MyAddon:CreateColorPicker(optionName)
	local colorPicker = CreateFrame("Button", nil, self);
	colorPicker.optionName = optionName;
	colorPicker:SetSize(16, 16);
	colorPicker:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
	colorPicker.normalTexture = colorPicker:GetNormalTexture();
	colorPicker.normalTexture:SetDrawLayer("ARTWORK", 1);
	colorPicker.background = colorPicker:CreateTexture("BACKGROUND", nil, -5);
	colorPicker.background:SetSize(14, 14);
	colorPicker.background:SetColorTexture(1, 1, 1);
	colorPicker.background:SetPoint("CENTER");
	colorPicker.Text = colorPicker:CreateFontString(nil, nil, "GameFontHighlight");
	colorPicker.Text:SetPoint("LEFT", colorPicker, "RIGHT", 8, 0);
	colorPicker.Text:SetText("Color picker text");
	colorPicker:SetScript("OnClick", MyAddon.ColorPickerOnClick);
	colorPicker:SetScript("OnEnter", MyAddon.ColorPickerOnEnter);
	colorPicker:SetScript("OnLeave", MyAddon.ColorPickerOnLeave);
	colorPicker.Refresh = MyAddon.ColorPickerRefresh;
	MyAddon:RegisterControl(colorPicker, self); 
	return colorPicker;
end
-- Usage: 
--   myColorPicker = optionsPanel:CreateColorPicker("SomeOption")
--   myColorPicker.Text:SetText("Some color option")
--   myColorPicker.onValueChanged = DoSomethingOnAdjust  -- Takes color as argument

function MyAddon:ColorPickerRefresh()
	local value = MyAddon:GetOption(self.optionName, self:GetParent().options);
	self.normalTexture:SetVertexColor(value.r, value.g, value.b);
	self.value = value;
end

function MyAddon:ColorPickerOnClick()
	ColorPickerFrame.previousValues = self.value;
	ColorPickerFrame.func = MyAddon.ColorPickerFunc;
	ColorPickerFrame.cancelFunc = MyAddon.ColorPickerCancelFunc;
	ColorPickerFrame.colorPicker = self;
	ColorPickerFrame.savedVariablesName = self:GetParent().savedVariablesName;
	ColorPickerFrame:SetColorRGB(MyAddon:GetColor(self.value));
	ColorPickerFrame:Hide(); -- Need to run the OnShow handler
 	ColorPickerFrame:Show();
end

function MyAddon:ColorPickerFunc()
	-- called by ColorPickerFrame with no self when color selected
	local r, g, b = ColorPickerFrame:GetColorRGB();
	local value = {r = r, g = g, b = b};
	local colorPicker = ColorPickerFrame.colorPicker;
	MyAddon:SetOption(colorPicker.optionName, value, _G[ColorPickerFrame.savedVariablesName]);
	if ( colorPicker.onValueChanged ) then
		colorPicker.onValueChanged(value);
	end
	colorPicker:Refresh();
end

function MyAddon:ColorPickerCancelFunc()
	local previousValues = ColorPickerFrame.previousValues;
	local colorPicker = ColorPickerFrame.colorPicker;
	MyAddon:SetOption(colorPicker.optionName, previousValues, _G[ColorPickerFrame.savedVariablesName]);
	if ( colorPicker.onValueChanged ) then
		colorPicker.onValueChanged(previousValues);
	end
	colorPicker:Refresh();
end

function MyAddon:ColorPickerOnEnter()
	if ( self.tooltipText ) then
		GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT");
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	end
	if ( self.tooltipRequirement ) then
		GameTooltip:AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end
end

function MyAddon:ColorPickerOnLeave()
	GameTooltip:Hide();
end
