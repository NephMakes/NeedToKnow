local addonName, NephilistNameplates = ...

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame
local LossBar = NephilistNameplates.LossBar


NephilistNameplates.EnemyFrameOptions = {
	colorHealthByReaction = true,
	considerSelectionInCombatAsHostile = true,
	greyWhenTapDenied = true,
	-- showClassColor set by DriverFrame:UpdateNamePlateOptions()
	showEliteIcon = true, 
	showName = true, 
	showSelectionHighlight = true, 
}
NephilistNameplates.FriendlyFrameOptions = {
	colorHealthByReaction = true,
	colorHealthWithExtendedColors = true,
	considerSelectionInCombatAsHostile = true,
	-- showClassColor set by DriverFrame:UpdateNamePlateOptions()
	showEliteIcon = true, 
	showName = true,
	showSelectionHighlight = true,
}
NephilistNameplates.PlayerFrameOptions = {
	healthBarColorOverride = CreateColor(0, 0.7, 0), 
	hideCastBar = true, 
	showPowerBar = true,
}
local EnemyFrameOptions = NephilistNameplates.EnemyFrameOptions
local FriendlyFrameOptions = NephilistNameplates.FriendlyFrameOptions
local PlayerFrameOptions = NephilistNameplates.PlayerFrameOptions

local backdropInfo = {
	bgFile = "interface/buttons/white8x8", 
	edgeFile = "interface/buttons/white8x8", 
	edgeSize = 1.5
}


--[[ UnitFrame ]]-- 

-- "UnitFrame" here is non-interactable frame we attach to Blizz "Nameplate#" frames

function UnitFrame:Initialize()
	local healthBar = self.healthBar
	self.healthBackground:SetAllPoints(healthBar)
	healthBar.background = self.healthBackground
--	healthBar.glowTop:SetVertexColor(1, 0, 0, 0.8)
--	healthBar.glowBottom:SetVertexColor(1, 0, 0, 0.8)

--	self.selectionBorder:SetBackdrop(backdropInfo)
--	self.selectionBorder:SetBackdropColor(0, 0, 0, 0)
--	self.selectionBorder:SetBackdropBorderColor(1, 1, 1)
	self.selectionBorder = healthBar.selectionBorder
	for i, texture in ipairs(healthBar.border.Textures) do
		texture:SetVertexColor(0, 0, 0, 1)
	end
	for i, texture in ipairs(self.powerBar.border.Textures) do
		texture:SetVertexColor(0, 0, 0, 1)
	end

	self.optionTable = {}
	self.BuffFrame.buffList = {}

	Mixin(self.lossBar, LossBar)  -- Set LossBar methods
	self.lossBar:Initialize()
end

function UnitFrame:SetUnit(unit)
	self.unit = unit
	self.displayedUnit = unit  -- For vehicles
	self.inVehicle = false
	if unit then
		self:RegisterEvents()
	else
		self:UnregisterEvents()
	end
end

function UnitFrame:UpdateInVehicle() 
	if UnitHasVehicleUI(self.unit) then
		if not self.inVehicle then
			self.inVehicle = true
			local prefix, id, suffix = string.match(self.unit, "([^%d]+)([%d]*)(.*)")
			self.displayedUnit = prefix.."pet"..id..suffix
			self:UpdateEvents()
		end
	else
		if self.inVehicle then
			self.inVehicle = false
			self.displayedUnit = self.unit
			self:UpdateEvents()
		end
	end
end

function UnitFrame:RegisterEvents()
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("UNIT_FACTION")
	-- self:RegisterEvent("UNIT_CONNECTION")
	self:UpdateEvents()
	if UnitIsUnit("player", self.unit) then
		self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
		self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	end
	self:SetScript("OnEvent", UnitFrame.OnEvent)
end

function UnitFrame:UpdateEvents()
	-- These events affected if unit in vehicle
	-- Sometimes getting Lua error when entering/exiting during combat?
	local displayedUnit
	if self.unit ~= self.displayedUnit then
		displayedUnit = self.displayedUnit
	end
	self:RegisterUnitEvent("UNIT_MAXHEALTH", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_HEALTH", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_AURA", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", self.unit, displayedUnit)
	-- self:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", self.unit, displayedUnit)  -- i.e. AFK, DND
end

function UnitFrame:UnregisterEvents()
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
end

function UnitFrame:OnEvent(event, ...)
	local arg1, arg2, arg3, arg4 = ...
	if event == "PLAYER_TARGET_CHANGED" then
		self:UpdateSelectionHighlight()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UpdateAll()
	elseif event == "RAID_TARGET_UPDATE" then
		self:UpdateRaidTarget()
	elseif event == "UNIT_POWER_FREQUENT" then 
		self:UpdatePower()
	elseif event == "UNIT_MAXPOWER" then 
		self:UpdateMaxPower()
	elseif event == "UNIT_DISPLAYPOWER" then 
		self:UpdatePowerBar()
	elseif arg1 == self.unit or arg1 == self.displayedUnit then
		if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
			self:UpdateHealth()
		elseif event == "UNIT_MAXHEALTH" then
			self:UpdateMaxHealth()
			self:UpdateHealth()
		elseif event == "UNIT_AURA" then
			self:UpdateBuffs()
		elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
			if self.optionTable.considerSelectionInCombatAsHostile then
				self:UpdateName()  -- Why is this here?
				self:UpdateThreat()
			end
		elseif event == "UNIT_NAME_UPDATE" then
			self:UpdateName()
			self:UpdateHealthColor()  -- Event can signal we now know unit class
		elseif event == "UNIT_FACTION" then
			self:UpdateName()
			self:UpdateHealthColor()
		elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" or event == "UNIT_PET" then
			self:UpdateAll()
		end
	end
end

function UnitFrame:SetOptions()
	local options = NephilistNameplatesOptions
	self.showBuffs = options.ShowBuffs
	self.onlyShowOwnBuffs = options.OnlyShowOwnBuffs
	self.showLevel = options.ShowLevel
	self.showThreat = options.ShowThreat
	self.threatRole = DriverFrame.threatRole
	self.showThreatOnlyInGroup = options.ShowThreatOnlyInGroup

	if UnitIsUnit("player", self.unit) then
		self.optionTable = PlayerFrameOptions
	elseif UnitIsFriend("player", self.unit) then
		self.optionTable = FriendlyFrameOptions
	else
		self.optionTable = EnemyFrameOptions
	end
end

function UnitFrame:UpdateAll()
	self:UpdateInVehicle()
	if UnitExists(self.displayedUnit) then
		self:UpdateName()
		self:UpdateLevel()
		self:UpdateHealthColor()
		self:UpdateMaxHealth()
		self:UpdateHealth()
		self:UpdateSelectionHighlight()
		self:UpdateMouseoverHighlight()
		self:UpdateRaidTarget()
		self:UpdateCastBar()
		self:UpdatePowerBar()
		self:UpdateBuffs()
		self:UpdateEliteIcon()
		self:UpdateThreat()
	end
end

function UnitFrame:UpdateName() 
	local name = GetUnitName(self.unit, false)
	self.name:SetText(name)
	self.nameHighlight:SetText(name)
	if not self.optionTable.showName then
		self.name:Hide()
		self.nameHighlight:Hide()
	else
		self.name:Show()
		local unitLevel = UnitLevel(self.unit)
		local classification = UnitClassification(self.unit)
		if unitLevel == -1 or classification == "worldboss" then
			self.name:SetTextColor(1.0, 0.6, 0.0)  -- Orange
		elseif classification == "rare" or classification == "rareelite" then
			self.name:SetTextColor(0.3, 0.3, 1.0)  -- Blue
		else
			self.name:SetTextColor(0.7, 0.7, 0.7)  -- Light grey
		end
	end
end

function UnitFrame:UpdateLevel()
	if self.showLevel and not UnitIsUnit("player", self.unit) then
		local unitLevel = UnitLevel(self.unit)
		local levelColor = {r = 0.7, g = 0.7, b = 0.7}
		if UnitCanAttack("player", self.unit) then
			levelColor = GetCreatureDifficultyColor(unitLevel)
		end
		if unitLevel == -1 then
			unitLevel = "??"
			levelColor = {r = 1.0, g = 0.0, b = 0.0}  -- Red
		end
		self.levelText:SetText(unitLevel)
		self.levelText:SetTextColor(levelColor.r, levelColor.g, levelColor.b)
		self.levelText:Show()
	else
		self.levelText:Hide()
	end
end

function UnitFrame:UpdateHealthColor() 
	local r, g, b = self:GetHealthColor()
	local healthBar = self.healthBar
	healthBar:SetStatusBarColor(r, g, b)
	healthBar.highlight:SetVertexColor(r, g, b)
	healthBar.background:SetColorTexture(r/5, g/5, b/5, 1)
end

function UnitFrame:GetHealthColor()
	local unit = self.unit
	local optionTable = self.optionTable

	if not UnitIsConnected(unit) then
		return 0.7, 0.7, 0.7
	end

	if optionTable.healthBarColorOverride then
		local override = optionTable.healthBarColorOverride
		return override.r, override.g, override.b
	end

	if UnitIsPlayer(unit) and optionTable.showClassColor then
		-- Set from cvars by DriverFrame:UpdateNamePlateOptions()
		local _, englishClass = UnitClass(unit)
		local classColor = RAID_CLASS_COLORS[englishClass]
		if classColor then 
			return classColor.r, classColor.g, classColor.b
		end
	end

	if self:IsTapDenied() then
		return 0.4, 0.4, 0.4
	end

	if self.threatColor then
		return self.threatColor.r, self.threatColor.g, self.threatColor.b
	end

	if optionTable.colorHealthByReaction then
		-- Color by unit reaction (neutral, hostile, etc)
		return UnitSelectionColor(unit, optionTable.colorHealthWithExtendedColors)
	end

	if UnitIsFriend("player", unit) then
		return 0.0, 0.8, 0.0
	else
		return 1.0, 0.0, 0.0
	end
end

function UnitFrame:IsTapDenied()
	return self.optionTable.greyWhenTapDenied 
		and UnitIsTapDenied(self.unit)
		and not UnitPlayerControlled(self.unit)
end

function UnitFrame:UpdateMaxHealth() 
	local maxHealth = UnitHealthMax(self.displayedUnit)
	self.healthBar:SetMinMaxValues(0, maxHealth)
	self.lossBar:SetMinMaxValues(0, maxHealth)
end

function UnitFrame:UpdateHealth() 
	local currentHealth = UnitHealth(self.displayedUnit)
	if not self.currentHealth then
		self.currentHealth = currentHealth
	end
	if currentHealth ~= self.currentHealth then
		self.healthBar:SetValue(currentHealth)
		self.lossBar:UpdateHealth(currentHealth, self.currentHealth)
		self.currentHealth = currentHealth
	end
	self.lossBar:UpdateAnimation(currentHealth)
end

function UnitFrame:UpdateSelectionHighlight() 
	if not self.optionTable.showSelectionHighlight then
		self.selectionBorder:Hide()
		return
	end
	if UnitIsUnit(self.displayedUnit, "target") then
		self.selectionBorder:Show()
	else
		self.selectionBorder:Hide()
	end
end

function UnitFrame:ShowMouseoverHighlight()
	self.healthBar.highlight:Show()
	if self.optionTable.showName then
		self.nameHighlight:Show()
	end
	self:SetIgnoreParentAlpha(true)
		-- Default UI behavior:
		--   Classic: nontarget nameplates lower alpha when target exists
		--   Retail:  alpha changes with distance
	self:SetScript("OnUpdate", self.UpdateMouseoverHighlight)
end

function UnitFrame:UpdateMouseoverHighlight()
	-- OnUpdate because UnitIsUnit("mouseover", self.unit) true when UPDATE_MOUSEOVER_UNIT fired OnLeave
	if not UnitIsUnit("mouseover", self.unit) then
		self:HideMouseoverHighlight()
		self:SetScript("OnUpdate", nil)
		if not self.threatAlpha then
			self:SetIgnoreParentAlpha(false)
		end
	end
end

function UnitFrame:HideMouseoverHighlight()
	self.healthBar.highlight:Hide()
	self.nameHighlight:Hide()
end

function UnitFrame:UpdateRaidTarget() 
	local icon = self.RaidTargetFrame.RaidTargetIcon
	local index = GetRaidTargetIndex(self.unit)
	if index then
		SetRaidTargetIconTexture(icon, index)
		icon:Show()
	else
		icon:Hide()
	end
end

function UnitFrame:UpdateEliteIcon() 
	local icon = self.EliteFrame.EliteIcon
	if not self.optionTable.showEliteIcon then
		icon:Hide()
	else
		local classification = UnitClassification(self.unit)
		if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
			icon:Show()
		else
			icon:Hide()
		end
	end
end

function UnitFrame:UpdateCastBar()
	local castBar = self.castBar
	castBar.startCastColor = CreateColor(0.6, 0.6, 0.6)
	castBar.startChannelColor = CreateColor(0.6, 0.6, 0.6)
	castBar.finishedCastColor = CreateColor(0.6, 0.6, 0.6)
	castBar.failedCastColor = CreateColor(0.5, 0.2, 0.2)
	castBar.nonInterruptibleColor = CreateColor(0.3, 0.3, 0.3)
	CastingBarFrame_AddWidgetForFade(castBar, castBar.BorderShield)
	if not self.optionTable.hideCastBar then
		CastingBarFrame_SetUnit(castBar, self.unit, false, true)
	else
		CastingBarFrame_SetUnit(castBar, nil, nil, nil)
	end
end

function UnitFrame:UpdateThreat()
	if not self.showThreat or 
		(not IsInGroup() and self.showThreatOnlyInGroup) or 
		UnitIsFriend("player", self.unit) or 
		UnitIsPlayer(self.unit)
	then
		self:HideThreat()
		return
	end

	local isTanking, status = UnitDetailedThreatSituation("player", self.unit)
	if status then
		if self.threatRole == "TANK" then
			if not isTanking then
				self:ShowThreatBad()
			elseif status < 3 then
				self:ShowThreatDanger()
			else
				self:ShowThreatGood()
			end
		else
			if isTanking then
				self:ShowThreatBad()
			elseif status > 0 then
				self:ShowThreatDanger()
			else
				self:ShowThreatGood()
			end
		end
	else
		self:HideThreat()
	end
end

function UnitFrame:ShowThreatBad()
	-- self.threatBorder:Show()
	self.threatColor = {r = 1, g = 0, b = 0}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:SetVertexColor(1, 0, 0)
	-- self.healthBar.glowBottom:SetVertexColor(1, 0, 0)
	-- self.healthBar.glowTop:Show()
	-- self.healthBar.glowBottom:Show()

	-- Full opacity for nameplates with threat warning (mostly affects Classic)
	self:SetIgnoreParentAlpha(true)
	self.threatAlpha = true
end

function UnitFrame:ShowThreatDanger()
	self.threatColor = {r = 1.0, g = 0, b = 0.5}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:SetVertexColor(1, 0, 0.5)
	-- self.healthBar.glowBottom:SetVertexColor(1, 0, 0.5)
	-- self.healthBar.glowTop:Show()
	-- self.healthBar.glowBottom:Show()

	-- Full opacity for nameplates with threat warning (mostly affects Classic)
	self:SetIgnoreParentAlpha(true)
	self.threatAlpha = true
end

function UnitFrame:ShowThreatGood()
	self.threatColor = {r = 0.6, g = 0.0, b = 0.7}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:Hide()
	-- self.healthBar.glowBottom:Hide()
	self.threatAlpha = nil
	self:UpdateMouseoverHighlight()
end

function UnitFrame:HideThreat()
	self.threatColor = nil
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:Hide()
	-- self.healthBar.glowBottom:Hide()
	self.threatAlpha = nil
	self:UpdateMouseoverHighlight()
end



