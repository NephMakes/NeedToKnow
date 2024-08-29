--[[
	Track spell, item, and spell charge cooldowns

	Kitjan made this bar type cover all three cases. It tries to figure out 
	spell vs item from the entryName/entryID. Spell charges require an 
	additional setting. 

	[Kitjan]: ACTIVE_TALENT_GROUP_CHANGED is only event guaranteed on talent 
	switch, but client might not have spell info yet. So checking cooldowns 
	should fail silently and try again later. 
]]--

local _, NeedToKnow = ...
NeedToKnow.SpellCooldownBarMixin = {}
local BarMixin = NeedToKnow.SpellCooldownBarMixin

local GetTime = GetTime
local GetItemInfo = C_Item.GetItemInfo
local GetItemCooldown = C_Container.GetItemCooldown
local GetRuneCooldown = GetRuneCooldown

-- Functions with different return structure in Retail and Classic
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	GetSpellInfo = function(spell)
		local info = C_Spell.GetSpellInfo(spell)
		if info then
			return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
	end
	GetSpellCooldown = function(spell)
		local info = C_Spell.GetSpellCooldown(spell)
		if info then
			return info.startTime, info.duration, info.isEnabled, info.modRate
		end
	end
	GetSpellCharges = function(spell)
		local info = C_Spell.GetSpellCharges(spell)
		if info then
			return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration, info.chargeModRate
		end
	end
end


--[[ Local functions ]]--

local function IsItemCooldown(itemIdentifier)
	local isItemCooldown, itemID
	local name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemIdentifier)
	if link then
		isItemCooldown = true
		itemID = link:match("item:(%d+):")
	end
	return isItemCooldown, name, icon, itemID
end

local function IsSpellCooldown(spellIdentifier)
	local isSpellCooldown, name, icon, spellID
	local start, _, _ = GetSpellCooldown(spellIdentifier)
	if start then
		isSpellCooldown = true
		name, _, icon, _, _, _, spellID = GetSpellInfo(spellIdentifier)
	end
	return isSpellCooldown, name, icon, spellID
end

local GLOBAL_SPELLID = 61304  -- Global cooldown
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	GLOBAL_SPELLID = 29515  -- "TEST Scorch"
end

local function IsGlobalCooldown(start, duration)
	local globalStart, globalDuration = GetSpellCooldown(GLOBAL_SPELLID)
	return (start == globalStart) and (duration == globalDuration)
end

local function round(value, decimalPlaces)
    local order = 10^(decimalPlaces or 0)
    return math.floor(value * order + 0.5) / order
end

local function IsRuneCooldown(duration)
	-- For Classic Death Knights
	local runeDuration
	for runeIndex = 1, 6 do
		_, runeDuration = GetRuneCooldown(runeIndex)
		if round(duration, 2) == round(runeDuration, 2) then
			-- duration and runeDuration accurate to different digits
			return true
		end
	end
end


--[[ Bar setup ]]--

function BarMixin:SetBarTypeOptions()
	local settings = self.settings
	settings.Unit = "player"
	self.showChargeCooldown = settings.show_charges
	self.checkOnNoTimeLeft = true  -- For Bar:OnUpdate. 
		-- No event when item cooldowns expire. Others fire too soon. 

	-- Set extra information for Bar:GetTrackedInfo
	for _, spellEntry in pairs(self.spells) do
		self:SetCooldownSpell(spellEntry)
	end
end

function BarMixin:SetCooldownSpell(spellEntry)
	-- Set appropriate cooldown function (spell/item/charges)

	-- Try item cooldown
	if spellEntry.name then
		-- Config by itemID not supported: values overlap with spellID
		local isItemCooldown, _, iconID, itemID = IsItemCooldown(spellEntry.name)
		if isItemCooldown then
			self.GetTrackedCooldown = self.GetTrackedItemCooldown
			spellEntry.hasFunction = true
			spellEntry.icon = iconID
			spellEntry.id = itemID  -- GetItemCooldown() only accepts itemIDs
			return
		end
	end

	-- Try spell cooldown
	local spell = spellEntry.id or spellEntry.name
	local isSpellCooldown, name, iconID, spellID = IsSpellCooldown(spell)
	if isSpellCooldown then
		if self.showChargeCooldown and GetSpellCharges(spell) then
			-- Spell charge cooldown
			self.GetTrackedCooldown = self.GetTrackedSpellChargesCooldown
		else
			-- Spell cooldown
			self.GetTrackedCooldown = self.GetTrackedSpellCooldown
		end
		spellEntry.hasFunction = true
		spellEntry.name = name
		spellEntry.icon = iconID
		spellEntry.id = spellID
		return
	end

	-- Try again later: maybe just logged in or recently changed talents
	spellEntry.hasFunction = false
end

function BarMixin:RegisterBarTypeEvents()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

function BarMixin:UnregisterBarTypeEvents()
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
end


--[[ Bar tracking ]]--

function BarMixin:ACTIONBAR_UPDATE_COOLDOWN()
	self:UpdateTracking()
end

function BarMixin:SPELL_UPDATE_COOLDOWN()
	self:UpdateTracking()
end

function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Called by Bar:UpdateTracking
	if not spellEntry.hasFunction then
		self:SetCooldownSpell(spellEntry)
	end
	if spellEntry.hasFunction then
		return self:GetTrackedCooldown(spellEntry)
	end
end

function BarMixin:GetTrackedSpellCooldown(spellEntry)
	-- Called as self:GetTrackedCooldown
	local spell = spellEntry.id or spellEntry.name
	local start, duration, enabled = GetSpellCooldown(spell)
	if not duration or 
		(duration == 0) or (enabled == 0) or
		IsGlobalCooldown(start, duration) or
		(NeedToKnow.isClassicDeathKnight and IsRuneCooldown(duration)) 
	then 
		return 
	end
	return {
		name = spellEntry.name, 
		iconID = spellEntry.icon, 
		count = 1, 
		duration = duration, 
		expirationTime = start + duration, 
		-- extraValues = nil, 
		shownName = spellEntry.shownName, 
		stacks = 1, 
	}
end

function BarMixin:GetTrackedItemCooldown(spellEntry)
	-- Called as self:GetTrackedCooldown
	local start, duration, enabled = GetItemCooldown(spellEntry.id)
	if not duration or 
		(duration == 0) or (enabled == 0) or
		IsGlobalCooldown(start, duration)
	then 
		return 
	end
	return {
		name = spellEntry.name, 
		iconID = spellEntry.icon, 
		count = 1, 
		duration = duration, 
		expirationTime = start + duration, 
		-- extraValues = nil, 
		shownName = spellEntry.shownName, 
		stacks = 1, 
	}
end

function BarMixin:GetTrackedSpellChargesCooldown(spellEntry)
	-- [Kitjan]: "Show first and last charge cooldown"
	-- [NephMakes]: Not sure this does the same thing as before (old code below)
	-- Called as self:GetTrackedCooldown
	local spell = spellEntry.id or spellEntry.name
	local currentCharges, maxCharges, start, duration = GetSpellCharges(spell)
	if not duration or 
		(currentCharges == maxCharges) or
		IsGlobalCooldown(start, duration) or
		(NeedToKnow.isClassicDeathKnight and IsRuneCooldown(duration)) 
	then
		return
	end
	return {
		name = spellEntry.name, 
		iconID = spellEntry.icon, 
		count = maxCharges - currentCharges, 
		duration = duration, 
		expirationTime = start + duration, 
		-- extraValues = nil, 
		shownName = spellEntry.shownName, 
		stacks = 1, 
	}
end

function BarMixin:ProcessTrackedInfo(trackedInfo)
	-- Nothing to do
	return trackedInfo
end



--[[ Old code ]]--

--[[
function BarMixin:GetTrackedInfo(spellEntry, allStacks)
	-- Get cooldown info for spell, item, or spell charges
	local GetCooldown = spellEntry.cooldownFunction
	if not GetCooldown then return end

	local start, duration, enabled, name, iconID, count, start2 = GetCooldown(self, spellEntry)
	if not start or not duration then return end
	if IsGlobalCooldown(start, duration) then return end

	local expirationTime = start + duration
	if expirationTime > GetTime() + 0.1 then  -- Why + 0.1?
		if start2 then  -- returned by bar:GetSpellChargesCooldown if no charges left
			self:AddTrackedInfo(allStacks, duration, name, 1, start2 + duration, iconID, spellEntry.shownName)
			count = count - 1
		else
			if not count then count = 1 end
		end
		self:AddTrackedInfo(allStacks, duration, name, count, expirationTime, iconID, spellEntry.shownName)
	end
end

function BarMixin:GetSpellCooldown(spellEntry)
	local spell = spellEntry.id or spellEntry.name
	local start, duration, enabled = GetSpellCooldown(spell)
	if start and start > 0 then
		if enabled == 0 then
			-- Cooldown hasn't started yet
			start = nil
		elseif NeedToKnow.isClassicDeathKnight and IsRuneCooldown(duration) then
			start = nil
		end
		if start then
			return start, duration, enabled, spellEntry.name, spellEntry.icon
		end
	end
end

function BarMixin:GetItemCooldown(spellEntry)
	local start, duration, enabled = GetItemCooldown(spellEntry.id)
	if start then
		return start, duration, enabled, spellEntry.name, spellEntry.icon
	end
end

function BarMixin:GetSpellChargesCooldown(spellEntry)
	local spell = spellEntry.id or spellEntry.name
	local currentCharges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spell)
	if currentCharges ~= maxCharges then
		if currentCharges == 0 then
			local start, duration, enabled, name, icon = self:GetSpellCooldown(spellEntry)
			return start, duration, enabled, name, icon, maxCharges, chargeStart
		else
			return chargeStart, chargeDuration, 1, spellEntry.name, spellEntry.icon, maxCharges - currentCharges
		end
	end
end

function BarMixin:GetUnresolvedCooldown(spellEntry)
	self:SetCooldownSpell(spellEntry)
	local f = spellEntry.cooldownFunction
	if f ~= self.GetUnresolvedCooldown then
		return f(bar, spellEntry)
	end
end
]]--

