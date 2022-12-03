local addonName, NephilistNameplates = ...

-- Namespaces
NephilistNameplates.DriverFrame = CreateFrame("Frame", "NephilistNameplatesFrame", UIParent)
NephilistNameplates.PlayerPlate = CreateFrame("Button", "NephilistNameplatesPlayerPlate", UIParent)
NephilistNameplates.UnitFrame = {}
NephilistNameplates.Strings = {}
NephilistNameplates.LossBar = {}

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame
local PlayerPlate = NephilistNameplates.PlayerPlate

function NephilistNameplates:Update()
	-- Called by "Okay" button of addon options panel and various checkboxes
	DriverFrame:UpdateNamePlateOptions()
end


--[[ Driver frame ]]--

function DriverFrame:OnEvent(event, ...) 
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:OnAddonLoaded()
		end
	elseif event == "VARIABLES_LOADED" then
		self:HideBlizzard()
		self:UpdateNamePlateOptions();
	elseif event == "NAME_PLATE_CREATED" then 
		local nameplate = ...
		self:OnNamePlateCreated(nameplate)
	elseif event == "NAME_PLATE_UNIT_ADDED" then 
		local unit = ...
		self:OnNamePlateAdded(unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then 
		local unit = ...
		self:OnNamePlateRemoved(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged()
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		-- Fires OnEnter and OnLeave
		local nameplate = C_NamePlate.GetNamePlateForUnit("mouseover")
		if nameplate then 
			nameplate.UnitFrame:ShowMouseoverHighlight()
		end
	elseif event == "DISPLAY_SIZE_CHANGED" then
		self:UpdateNamePlateOptions()
	elseif 
		event == "PLAYER_TALENT_UPDATE" or
		event == "ACTIVE_TALENT_GROUP_CHANGED" or
		event == "TALENT_GROUP_ROLE_CHANGED"
	then
		self:UpdateNamePlateOptions()
	elseif event == "CVAR_UPDATE" then
		self:UpdateNamePlateOptions()
--		local name = ...
--		if name == "SHOW_CLASS_COLOR_IN_V_KEY" then
--			self:UpdateNamePlateOptions()
--		end
	end
end
DriverFrame:SetScript("OnEvent", DriverFrame.OnEvent)
DriverFrame:RegisterEvent("ADDON_LOADED")
DriverFrame:RegisterEvent("VARIABLES_LOADED")
DriverFrame:RegisterEvent("NAME_PLATE_CREATED")
DriverFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
DriverFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
DriverFrame:RegisterEvent("CVAR_UPDATE")
DriverFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
DriverFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
DriverFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
DriverFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
DriverFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
-- DriverFrame:RegisterEvent("PLAYER_LOGIN")
-- DriverFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- DriverFrame:RegisterEvent("PLAYER_LOGOUT")
-- "SHOW_NAMEPLATE_LOSE_AGGRO_FLASH" 

function DriverFrame:OnAddonLoaded()
	NephilistNameplates:LocalizeStrings()

	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		-- Classic WoW
		DriverFrame:RegisterEvent("TALENT_GROUP_ROLE_CHANGED")
		-- Disable Retail-only options
		local optionsPanel = NephilistNameplates.OptionsPanel
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.showBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.onlyShowOwnBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.hideClassBarButton)
	end

--	local reset = false
--	if NephilistNameplatesOptions and NephilistNameplates.Version and NephilistNameplates.Version < "2.0.3" then
--		reset = true
--	end
	NephilistNameplates:UpdateOptions("NephilistNameplatesOptions", NephilistNameplates.Defaults, false)
end

function DriverFrame:HideBlizzard()
	NamePlateDriverFrame:UnregisterAllEvents()
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then  
		ClassNameplateManaBarFrame:Hide()
		ClassNameplateManaBarFrame:UnregisterAllEvents()
		ClassNameplateManaBarFrame:HookScript("OnShow", function(self) self:Hide() end)
			-- Blizz mana bar appearing on level-up
		--[[
		local checkBox = InterfaceOptionsNamesPanelUnitNameplatesMakeLarger
		if checkBox then
			function checkBox.setFunc(value)
				if value == "1" then
					SetCVar("NamePlateHorizontalScale", checkBox.largeHorizontalScale)
					SetCVar("NamePlateVerticalScale", checkBox.largeVerticalScale)
				else
					SetCVar("NamePlateHorizontalScale", checkBox.normalHorizontalScale)
					SetCVar("NamePlateVerticalScale", checkBox.normalVerticalScale)
				end
				DriverFrame:UpdateNamePlateOptions()
			end
		end
		]]--
		-- Should now be covered by blanket CVAR_UPDATE event
	end
end

function DriverFrame:UpdateNamePlateOptions()
	-- Get cvars
	local enemyOptions = NephilistNameplates.EnemyFrameOptions
	local friendlyOptions = NephilistNameplates.FriendlyFrameOptions
	enemyOptions.showClassColor = GetCVarBool("ShowClassColorInNameplate")
	friendlyOptions.showClassColor = GetCVarBool("ShowClassColorInFriendlyNameplate")
	-- enemyOptions.playLoseAggroHighlight = GetCVarBool("ShowNamePlateLoseAggroFlash")

	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		local baseNamePlateWidth = 110
		local baseNamePlateHeight = 45
		-- local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"))
		-- local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"))
		-- C_NamePlate.SetNamePlateOtherSize(baseNamePlateWidth * horizontalScale, baseNamePlateHeight)
		-- /script SetCVar("nameplateHorizontalScale", 0.5)
		-- /script print(GetCVar("nameplateVerticalScale"))
		C_NamePlate.SetNamePlateSelfSize(baseNamePlateWidth, baseNamePlateHeight)
			-- Creates taint in combat
	end

	DriverFrame:UpdateThreatRole()

	-- Update frames
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		unitFrame:SetOptions()
		unitFrame:UpdateAll()
	end
	PlayerPlate:Update()
	DriverFrame:UpdateClassResourceBar()  -- In Power.lua
end

function DriverFrame:UpdateThreatRole()
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		self.threatRole = GetSpecializationRole(GetSpecialization())
	else
		self.threatRole = GetTalentGroupRole(GetActiveTalentGroup())
	end
end

function DriverFrame:OnNamePlateCreated(nameplate)
	local unitFrame = CreateFrame("Button", "$parentUnitFrame", nameplate, "NephilistNameplatesTemplate")
	unitFrame:SetAllPoints()
	unitFrame:EnableMouse(false)
	Mixin(unitFrame, UnitFrame)  -- Inherit UnitFrame:Methods()
	unitFrame:Initialize()
end

function DriverFrame:OnNamePlateAdded(unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
	local unitFrame = namePlate.UnitFrame
	unitFrame:SetUnit(unit)
	unitFrame:SetOptions()
	unitFrame:UpdateAll()
	self:UpdateClassResourceBar()
end

function DriverFrame:OnNamePlateRemoved(unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
	namePlate.UnitFrame:SetUnit(nil)
end

function DriverFrame:OnTargetChanged()
	DriverFrame:UpdateClassResourceBar()  -- in Power.lua
end
