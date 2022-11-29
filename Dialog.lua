--[[ Pop-up dialog boxes for user input ]]--

-- local addonName, addonTable = ...
local Dialog = NeedToKnow.Dialog
local String = NeedToKnow.String


StaticPopupDialogs["NEEDTOKNOW_TEXT_INPUT"] = {
	-- text = "", 
	-- subText = "", 
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	-- editBoxInstructions = "Edit box instructions", 
	editBoxWidth = 300,
	maxLetters = 0,
	OnShow = function(self)
		-- self.editBox:SetText("")
		self.editBox:SetFocus()
	end,
	OnAccept = nil,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetText("")
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
--		if( GetCurrentArenaSeasonUsesTeams() ) then
--			ArenaTeamInviteByName(PVPTeamDetails.team, parent.editBox:GetText());
--		end
		parent:Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1, 
	whileDead = 1,
	hideOnEscape = 1,
}

-- StaticPopupDialogs["NEEDTOKNOW_TEXT_INPUT"] = {}

-- StaticPopupDialogs["NEEDTOKNOW_IMPORT_EXPORT"] = {}

local DialogText = {
	HELPFUL = "Enter buff name", 
	HARMFUL = "Enter debuff name", 
	CASTCD = "Enter spell, item, or ability name", 
	USABLE = "Enter spell or ability name", 
	BUFFCD = "Enter buff name", 
	TOTEM = "Enter totem name", 
	usable_duration = "Enter time in seconds reactive spell or abiliity is usable", 
	buffcd_duration = "Enter time in seconds for proc internal cooldown", 
	buffcd_reset_spells = "Enter spell or ability name", 
	vct_spell = "Enter spell or ability name", 
	vct_extra = "Enter time in seconds to add to cast time", 
	blink_label = "Enter text", 
	show_text_user = "Enter text", 
}

local DialogSubText = {
	HELPFUL = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	HARMFUL = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	CASTCD = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	USABLE = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	BUFFCD = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	TOTEM = "To track more than one with this bar, enter names in order of priority separated by commas. Spell IDs accepted.", 
	usable_duration = nil, 
	buffcd_duration = "Most procs have a 45 second internal cooldown", 
	vct_spell = "Leave blank to show cast time for spell with buff or debuff name", 
	vct_extra = nil, 
	buffcd_reset_spells = "These spells and abilities reset internal cooldown. For more than one, enter names separated by commas. Spell IDs accepted.", 
	blink_label = "Clear text to stop showing", 
	show_text_user = "Clear text to stop showing", 
}

local DialogData = {} -- Reused table {groupID, barID, varName, currentValue}


--[[ Functions ]]--

function Dialog:ShowTextInput(varName)
	local info = StaticPopupDialogs["NEEDTOKNOW_TEXT_INPUT"]
	info.text = DialogText[varName]
	info.subText = DialogSubText[varName]
	local data = DialogData
	data.groupID = BarMenu.groupID
	data.barID = BarMenu.barID
	data.varName = varName
	-- data.currentValue = 
	local dialog = StaticPopup_Show(info, nil, nil, data)
		-- e.g. self.data.varName
end

function Dialog:SetTextVar(varName, varValue)
end

function Dialog:ShowNumericInput(varName)
end

function Dialog:NumericOnKeyDown(key)
end
--[[
function StackSplitFrame_OnKeyDown(self,key)
	local numKey = gsub(key, "NUMPAD", "");
	if ( key == "BACKSPACE" or key == "DELETE" ) then
		if ( self.typing == 0 or self.split == self.minSplit ) then
			return;
		end

		self.split = floor(self.split / 10);
		if ( self.split <= self.minSplit ) then
			self.split = self.minSplit;
			self.typing = 0;
			StackSplitLeftButton:Disable();
		else
			StackSplitLeftButton:Enable();
		end
		StackSplitText:SetText(self.split);
		if ( self.money == self.maxStack ) then
			StackSplitRightButton:Disable();
		else
			StackSplitRightButton:Enable();
		end
	elseif ( key == "ENTER" ) then
		StackSplitFrameOkay_Click();
	elseif ( GetBindingFromClick(key) == "TOGGLEGAMEMENU" ) then
		StackSplitFrameCancel_Click();
	elseif ( key == "LEFT" or key == "DOWN" ) then
		StackSplitFrameLeft_Click();
	elseif (key == "RIGHT" or key == "UP" ) then
		StackSplitFrameRight_Click();
	elseif ( not ( tonumber(numKey) ) and GetBindingAction(key) ) then
		--Running bindings not used by the StackSplit frame allows players to retain control of their characters.
		RunBinding(GetBindingAction(key));
	end
	
	self.down = self.down or {};
	self.down[key] = true;
end
]]--

function Dialog:NumericOnKeyUp(key)
end
--[[
function StackSplitFrame_OnKeyUp(self,key)
	local numKey = gsub(key, "NUMPAD", "");
	if ( not ( tonumber(numKey) ) and GetBindingAction(key) ) then
		--If we don't run the up bindings as well, interesting things happen (like you never stop moving)
		RunBinding(GetBindingAction(key), "up");
	end
	
	if ( self.down ) then
		self.down[key] = nil;
	end
end
]]--

function Dialog:SetNumericVar(varName, varValue)
end

function Dialog:ShowImportExport()
end





