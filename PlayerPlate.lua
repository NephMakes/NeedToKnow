local addonName, NephilistNameplates = ...

local PlayerPlate = NephilistNameplates.PlayerPlate
local DriverFrame = NephilistNameplates.DriverFrame

local function round(x) 
	return floor(x + 0.5)
end


--[[ Player plate ]]--

-- PlayerPlate is a static frame that acts like Blizz nameplate with self.unit = "player"

do
--	PlayerPlate.texture = PlayerPlate:CreateTexture()
--	PlayerPlate.texture:SetAllPoints()
--	PlayerPlate.texture:SetColorTexture(0, 1, 0, 0.5)
	PlayerPlate:SetWidth(140)
	PlayerPlate:SetHeight(20)
end

function PlayerPlate:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:ADDON_LOADED()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:SetShown()
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:SetOutOfCombat()
	end
end
PlayerPlate:SetScript("OnEvent", PlayerPlate.OnEvent)
PlayerPlate:RegisterEvent("ADDON_LOADED")

function PlayerPlate:ADDON_LOADED()
	DriverFrame:OnNamePlateCreated(self)
	self.UnitFrame:SetUnit("player")
	self:Update()
end

function PlayerPlate:Update()
	-- Called by PlayerPlate:ADDON_LOADED(), DriverFrame:UpdateNamePlateOptions()
	-- and options panel controls
	local self = PlayerPlate
	local options = NephilistNameplatesOptions
	if options.ShowPlayerPlate then 
		self.inUse = true
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")

		self:SetPosition(options.PlayerPlatePosition)
		self:SetLocked(options.PlayerPlateLocked)
		self.outOfCombatAlpha = options.PlayerPlateOutOfCombatAlpha

		self.UnitFrame:SetOptions()
		self.UnitFrame:UpdateAll()
	else
		self.inUse = false
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:UpdateShown()
end

function PlayerPlate:SetPosition(point) 
	PlayerPlate:ClearAllPoints();
	PlayerPlate:SetPoint(unpack(point))
end

function PlayerPlate:UpdateShown()
	-- Called by PlayerPlate:Update()
	if self.inUse then
		self:Show()
		if not InCombatLockdown() then
			self:SetOutOfCombat()
		else
			self:SetShown()
		end
	else
		self:Hide()
	end
end

function PlayerPlate:SetOutOfCombat()
	self:SetAlpha(self.outOfCombatAlpha)
end

function PlayerPlate:SetShown()
	self:SetAlpha(1)
end

function PlayerPlate:SetLocked(isLocked)
	-- Called by PlayerPlate:Update() and [options panel checkbutton]
	self.isLocked = isLocked
	if isLocked then
		self:EnableMouse(false)
	else
		self:EnableMouse(true)
	end
end

function PlayerPlate:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	local strings = NephilistNameplates.Strings
	GameTooltip:AddLine(strings.NephilistNameplates, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.g)
	GameTooltip:AddLine(strings.DragToMove)
	GameTooltip:Show()
end
PlayerPlate:SetScript("OnEnter", PlayerPlate.OnEnter)

function PlayerPlate:OnLeave()
	GameTooltip:Hide()
end
PlayerPlate:SetScript("OnLeave", PlayerPlate.OnLeave)

function PlayerPlate:OnDragStart()
	self:StartMoving()
end
PlayerPlate:SetMovable(true)
PlayerPlate:RegisterForDrag("LeftButton")
PlayerPlate:SetScript("OnDragStart", PlayerPlate.OnDragStart)

function PlayerPlate:OnDragStop()
	self:StopMovingOrSizing()
	self:SetUserPlaced(false)
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
	xOfs, yOfs = round(xOfs), round(yOfs)
	NephilistNameplatesOptions.PlayerPlatePosition = {point, relativeTo, relativePoint, xOfs, yOfs}
end
PlayerPlate:SetScript("OnDragStop", PlayerPlate.OnDragStop)

function PlayerPlate:OnClick(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
	if button == "RightButton" then
		InterfaceAddOnsList_Update()
		InterfaceOptionsFrame_OpenToCategory(NephilistNameplates.OptionsPanel)
	end
end
PlayerPlate:RegisterForClicks("OnClick", "RightButtonUp")
PlayerPlate:SetScript("OnClick", PlayerPlate.OnClick)

--[[
function PlayerPlate:OnClick(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, EngravedRuneFrameTabDropDown, self:GetName(), 0, 0)
		return
	end
	CloseDropDownMenus()
end

function PlayerPlate:InitializeTabDropDown()
	local strings = Engraved.Strings;
	local info = UIDropDownMenu_CreateInfo();

	info.text = strings.LOCK_RUNE_DISPLAY;
	info.func = RuneFrame.SetLocked;
	info.arg1 = true;
	info.isNotRadio = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

--	info.text = strings.OPEN_OPTIONS_MENU;
--	info.func = nil;
--	info.isNotRadio = true;
--	info.notCheckable = true;
--	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
--
--	info.text = strings.RESET_POSITIONS;
--	info.func = nil;
--	info.isNotRadio = true;
--	info.notCheckable = true;
--	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
end
]]--