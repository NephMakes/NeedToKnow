﻿-- Track spell and item cooldowns

--[[
	[Kitjan]: ACTIVE_TALENT_GROUP_CHANGED is only event guaranteed on talent switch, 
	but client might not have spell info yet. So checking cooldowns should fail silently 
	and try again later. 
]]--

local _, NeedToKnow = ...
local Cooldown = NeedToKnow.Cooldown

-- Local versions of global functions
local GetSpellInfo = C_Spell.GetSpellInfo or GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown or GetSpellCooldown
local GetSpellCharges = C_Spell.GetSpellCharges or GetSpellCharges
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local GetItemCooldown = C_Container.GetItemCooldown or GetItemCooldown

function Cooldown.SetUpSpell(bar, info)
	local name, icon, spellID

	-- Check if item cooldown
	if info.name then
		-- Config by itemID not supported: itemID and spellID use overlapping values
		local link
		name, link, _, _, _, _, _, _, _, icon = GetItemInfo(info.name)
		if link then
			info.id = link:match("item:(%d+):")
			info.icon = icon
			info.cooldownFunction = Cooldown.GetItemCooldown
			return
		end
	end

	-- Spell cooldown
	local spell = info.id or info.name
	name, _, icon, _, _, _, spellID = GetSpellInfo(spell)
	local start, duration, enabled = GetSpellCooldown(spell)
	if start then
		info.name = name
		info.id = spellID
		info.icon = icon
		if bar.settings.show_charges and GetSpellCharges(spell) then
			info.cooldownFunction = Cooldown.GetSpellChargesCooldown
		else
			info.cooldownFunction = Cooldown.GetSpellCooldown
		end
	else
		info.cooldownFunction = Cooldown.GetUnresolvedCooldown
		-- Try again later in case we just logged in or recently changed talents
	end
end

function Cooldown.GetItemCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	local start, duration, enabled = GetItemCooldown(spellInfo.id)
	if start then
		return start, duration, enabled, spellInfo.name, spellInfo.icon
	end
end

function Cooldown.GetSpellCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	local spell = spellInfo.id or spellInfo.name
	local start, duration, enabled = GetSpellCooldown(spell)
	if start and start > 0 then
		if enabled == 0 then
			-- Cooldown hasn't started yet
			start = nil
		elseif NeedToKnow.isClassicDeathKnight then
			-- Show ability cooldowns, not rune cooldowns
			for runeIndex = 1, 6 do
				local _, runeDuration = GetRuneCooldown(runeIndex)
				if duration == runeDuration then
					start = nil
					break
				end
			end
		end
		if start then
			return start, duration, enabled, spellInfo.name, spellInfo.icon
		end
	end
end

function Cooldown.GetSpellChargesCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	local spell = spellInfo.id or spellInfo.name
	local currentCharges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spell)
	if currentCharges ~= maxCharges then
		if currentCharges == 0 then
			local start, duration, enabled, name, icon = Cooldown.GetSpellCooldown(bar, spellInfo)
			return start, duration, enabled, name, icon, maxCharges, chargeStart
		else
			return chargeStart, chargeDuration, 1, spellInfo.name, spellInfo.icon, maxCharges - currentCharges
		end
	end
end

function Cooldown.GetUnresolvedCooldown(bar, spellInfo)
	Cooldown.SetUpSpell(bar, spellInfo)
	local fn = spellInfo.cooldownFunction
	if fn ~= Cooldown.GetUnresolvedCooldown then
		return fn(bar, spellInfo)
	end
end
