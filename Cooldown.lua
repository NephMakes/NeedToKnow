-- Track spell, item, and proc cooldowns

local addonName, addonTable = ...
local Cooldown = NeedToKnow.Cooldown

-- Local versions of frequently-used functions
local GetTime = GetTime
local GetSpellCooldown = GetSpellCooldown
local GetItemCooldown = GetItemCooldown
local GetSpellCharges = GetSpellCharges

-- Kitjan's locals (deprecated)
local g_GetTime           = GetTime
local g_GetSpellInfo      = GetSpellInfo
local g_GetSpellPowerCost = GetSpellPowerCost
local g_GetSpellTabInfo   = GetSpellTabInfo
local g_GetNumSpellTabs   = GetNumSpellTabs


-- ------------------
-- Cooldown functions
-- ------------------

function Cooldown.SetUpSpell(bar, info)
	-- Kitjan: 
	-- This may fail for valid names if the client doesn't have the data for
	-- that spell yet (just logged in or changed talent specs), in which case 
	-- we mark that spell to try again later

	local name, icon, spellID

	-- Check if item cooldown
	if info.name then
		-- Config by itemID not supported: itemID and spellID use overlapping values
		local link
		name, link, _, _, _, _, _, _, _, icon = GetItemInfo(info.name)
		if link then
			local itemID = link:match("item:(%d+):")
			info.id = itemID
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

		if spellID == 75 then  -- Auto Shot
			bar.settings.bAutoShot = true
			info.cooldownFunction = Cooldown.GetAutoShotCooldown
		elseif bar.settings.show_charges and GetSpellCharges(spell) then
			info.cooldownFunction = Cooldown.GetSpellChargesCooldown
		else
			info.cooldownFunction = Cooldown.GetSpellCooldown
		end
	else
		info.cooldownFunction = Cooldown.GetUnresolvedCooldown
	end
end

function Cooldown.GetItemCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	-- Wrapper for GetItemCooldown expected to return start, duration, enabled, name, icon
	-- Called OnUpdate. Make sure it's efficient. 
	local start, duration, enabled = GetItemCooldown(spellInfo.id)
	if start then
		return start, duration, enabled, spellInfo.name, spellInfo.icon
	end
end


function Cooldown.GetSpellCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	-- Wrapper for GetSpellCooldown() expected to return start, duration, enabled, name, icon
	-- Called OnUpdate. Make sure it's efficient.
	local spell = spellInfo.id or spellInfo.name
	local start, duration, enabled = GetSpellCooldown(spell)
	if start and start > 0 then
		if enabled == 0 then  -- Cooldown hasn't started yet
			start = nil
		elseif NeedToKnow.is_DK == 1 then
			-- Don't show rune cooldowns for death knight abilities in Classic
			local usesRunes = false
			local costInfo = g_GetSpellPowerCost(spellInfo.id)
			local nCosts = table.getn(costInfo)
			for iCost = 1, nCosts do
				if costInfo[iCost].type == SPELL_POWER_RUNES then  
					usesRunes = true
				end
			end
			if usesRunes then
				-- Filter out rune cooldown artificially extending the cd
				if duration <= 10 then
					local tNow = g_GetTime()
					if bar.expirationTime and tNow < bar.expirationTime then
						-- We've already seen the correct CD for this, so keep using it
						start = bar.expirationTime - bar.duration
						duration = bar.duration
					elseif m_last_sent and m_last_sent[spellName] and m_last_sent[spellName] > (tNow - 1.5) then
						-- We think the spell was just cast, and a CD just started but it's short.
						-- Look at the tooltip to tell what the correct CD should be. If it's supposed
						-- to be short (Ghoul Frenzy, Howling Blast), then start a CD bar
						duration = Cooldown.DetermineShortCooldownFromTooltip(spell)
						if duration == 0 or duration > 10 then
							start = nil
						end
					else
						start = nil
					end
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
	-- Called OnUpdate. Make sure it's efficient. 
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

function Cooldown.GetAutoShotCooldown(bar, spellInfo)
	-- Called by bar:FindCooldown()
	-- Called OnUpdate. Make sure it's efficient. 
	local now = GetTime()
	if bar.tAutoShotStart and bar.tAutoShotStart + bar.tAutoShotCD > now then
		return bar.tAutoShotStart, bar.tAutoShotCD, 1, spellInfo.name, spellInfo.icon
	else
		bar.tAutoShotStart = nil
	end
end

function Cooldown.GetUnresolvedCooldown(bar, spellInfo)
	-- Set up cooldowns we haven't figured out yet
	Cooldown.SetUpSpell(bar, spellInfo)
	local fn = spellInfo.cooldownFunction
	if fn ~= Cooldown.GetUnresolvedCooldown then
		return fn(bar, spellInfo)
	end
end

function Cooldown.DetermineShortCooldownFromTooltip(spell)
	-- Looks at the tooltip for the given spell to see if a cooldown 
	-- is listed with a duration in seconds.  Longer cooldowns don't
	-- need this logic, so we don't need to do unit conversion

	-- Stores cooldown info as NeedToKnow.short_cds ...But why? 

	if not NeedToKnow.short_cds then
		NeedToKnow.short_cds = {}
	end
	if not NeedToKnow.short_cds[spell] then
		-- Figure out what a cooldown in seconds should look like
		local ref = SecondsToTime(10):lower()
		local unit_ref = ref:match("10 (.+)")

		-- Get the number and unit of the cooldown from the tooltip
		local tt1 = Cooldown.GetUtilityTooltips()
		local lnk = GetSpellLink(spell)
		local cd, n_cd, unit_cd
		if ( lnk and (lnk ~= "") ) then
			tt1:SetHyperlink( lnk )
		
			for iTT = 3, 2, -1 do
				cd = tt1.right[iTT]:GetText()
				if ( cd ) then 
					cd = cd:lower()
					n_cd, unit_cd = cd:match("(%d+) (.+) ")
				end
				if ( n_cd ) then 
					break 
				end
			end
		end

		-- unit_ref will be "|4sec:sec;" in english, so do a find rather than a ==
		if ( not n_cd ) then 
			-- If we couldn't parse the tooltip, assume there's no cd
			NeedToKnow.short_cds[spell] = 0
		elseif (unit_ref:find(unit_cd)) then
			NeedToKnow.short_cds[spell] = tonumber(n_cd)
		else
			-- Not a short cooldown.  Record it as a minute
			NeedToKnow.short_cds[spell] = 60
		end
	end

	return NeedToKnow.short_cds[spell]
end

function Cooldown.GetUtilityTooltips()
	if ( not NeedToKnow_Tooltip1 ) then
		for idxTip = 1, 2 do
			local ttname = "NeedToKnow_Tooltip"..idxTip
			-- local tt = CreateFrame("GameTooltip", ttname)
			local tt = CreateFrame("GameTooltip", ttname, nil, GameTooltipTemplate)
			tt:SetOwner(UIParent, "ANCHOR_NONE")
			tt.left = {}
			tt.right = {}
			-- Most of the tooltip lines share the same text widget,
			-- But we need to query the third one for cooldown info
			for i = 1, 30 do
				tt.left[i] = tt:CreateFontString()
				tt.left[i]:SetFontObject(GameFontNormal)
				if ( i < 5 ) then
					tt.right[i] = tt:CreateFontString()
					tt.right[i]:SetFontObject(GameFontNormal)
					tt:AddFontStrings(tt.left[i], tt.right[i])
				else
					tt:AddFontStrings(tt.left[i], tt.right[4])
				end
			end 
		 end
	end
	local tt1, tt2 = NeedToKnow_Tooltip1, NeedToKnow_Tooltip2
	tt1:ClearLines()
	tt2:ClearLines()
	return tt1, tt2
end
