-- Track spell, item, and proc cooldowns

local addonName, addonTable = ...
local Cooldown = NeedToKnow.Cooldown


-- ---------------
-- Kitjan's locals
-- ---------------

local g_GetTime           = GetTime
local g_GetSpellInfo      = GetSpellInfo
local g_GetSpellPowerCost = GetSpellPowerCost
local g_GetSpellTabInfo   = GetSpellTabInfo
local g_GetNumSpellTabs   = GetNumSpellTabs

local c_AUTO_SHOT_NAME = g_GetSpellInfo(75)  -- Localized name for Auto Shot

local m_last_cast      = addonTable.m_last_cast
local m_last_cast_head = addonTable.m_last_cast_head
local m_last_cast_tail = addonTable.m_last_cast_tail
local m_last_guid      = addonTable.m_last_guid


-- ------------------
-- Cooldown functions
-- ------------------

function Cooldown.SetUpSpell(bar, entry)
	-- Attempt to figure out if a name is an item or a spell, and if a spell
	-- try to choose a spell with that name that has a cooldown
	-- This may fail for valid names if the client doesn't have the data for
	-- that spell yet (just logged in or changed talent specs), in which case 
	-- we mark that spell to try again later

	local id = entry.id
	local name = entry.name
	local idx = entry.idxName
	if ( not id ) then
		if ( (name == "Auto Shot") or (name == c_AUTO_SHOT_NAME) ) then
			bar.settings.bAutoShot = true
			bar.cd_functions[idx] = Cooldown.GetAutoShotCooldown
		else
			local item_id = Cooldown.GetItemIDString(name)
			if ( item_id ) then
				entry.id = item_id
				entry.name = nil
				bar.cd_functions[idx] = Cooldown.GetItemCooldown
			else
				local betterSpellID
				-- betterSpellID = Cooldown.TryToFindSpellWithCD(name)
				betterSpellID = Cooldown:GetSpell(name)
				if ( nil ~= betterSpell ) then
					entry.id = betterSpell
					entry.name = nil
					bar.cd_functions[idx] = Cooldown.GetSpellCooldown
				elseif ( not GetSpellCooldown(name) ) then
					bar.cd_functions[idx] = Cooldown.GetUnresolvedCooldown
				else
					bar.cd_functions[idx] = Cooldown.GetSpellCooldown
				end

				if ( bar.cd_functions[idx] == Cooldown.GetSpellCooldown ) then
					local key = entry.id or entry.name
					if ( bar.settings.show_charges and GetSpellCharges(key) ) then
						bar.cd_functions[idx] = Cooldown.GetSpellChargesCooldown
					end
				end
			end
		end
	end
end

function Cooldown.GetItemCooldown(bar, entry)
	-- Wrapper around GetItemCooldown
	-- Expected to return start, duration, enabled, name, iconpath
	local start, duration, enabled = GetItemCooldown(entry.id);
	if ( start ) then
		local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(entry.id);
		return start, duration, enabled, name, icon;
	end
end

function Cooldown.GetItemIDString(id_or_name)
    local _, link = GetItemInfo(id_or_name)
    if ( link ) then
        local idstring = link:match("item:(%d+):")
        if ( idstring ) then
            return idstring
        end
    end
end

-- function Cooldown.TryToFindSpellWithCD(spellEntry)
function Cooldown:GetSpell(spellEntry)
	-- todo: cache this result?
	if ( Cooldown.DetermineShortCooldownFromTooltip(spellEntry) > 0 ) then 
		return spellEntry;
	end
	-- Search player's spellbook
	for iBook = 1, g_GetNumSpellTabs() do
		local sBook, _, iFirst, nSpells = GetSpellTabInfo(iBook);
		for iSpell = iFirst+1, iFirst+nSpells do
			local spellName = GetSpellInfo(iSpell, sBook);
			if ( spellName == spellEntry ) then
				local sLink = GetSpellLink(iSpell, sBook);
				local spellID = sLink:match("spell:(%d+)");
				local start = GetSpellCooldown(spellID);
				if ( start ) then
					local ttcd = Cooldown.DetermineShortCooldownFromTooltip(spellID);
					if ( ttcd and (ttcd > 0) ) then
						return spellID;
					end
				end
			end
		end
	end
end

function Cooldown.DetermineShortCooldownFromTooltip(spell)
	-- Looks at the tooltip for the given spell to see if a cooldown 
	-- is listed with a duration in seconds.  Longer cooldowns don't
	-- need this logic, so we don't need to do unit conversion

	-- Stores cooldown info as NeedToKnow.short_cds
	-- But why? 

	if ( not NeedToKnow.short_cds ) then
		NeedToKnow.short_cds = {}
	end
	if ( not NeedToKnow.short_cds[spell] ) then
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
			local tt = CreateFrame("GameTooltip", ttname)
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

function Cooldown.GetSpellCooldown(bar, entry)
    -- Wrapper around GetSpellCooldown with extra sauce
    -- Expected to return start, cd_len, enable, buffName, iconpath
    local barSpell = entry.id or entry.name
    local start, duration, enabled = GetSpellCooldown(barSpell)
    if ( start and start > 0 ) then
        local spellName, _, spellIconPath, _, _, _, spellId = g_GetSpellInfo(barSpell)
        if ( not spellName ) then 
            if ( not NeedToKnow.GSIBroken ) then 
                NeedToKnow.GSIBroken = {} 
            end
            if ( not NeedToKnow.GSIBroken[barSpell] ) then
                print("NeedToKnow: Warning! Unable to get spell info for",barSpell,".  Try using Spell ID instead.")
                NeedToKnow.GSIBroken[barSpell] = true;
            end
            spellName = tostring(barSpell)
        end

        if ( enabled == 0 ) then 
            -- Filter out conditions like Stealth while stealthed
            start = nil
        elseif ( NeedToKnow.is_DK == 1 ) then
		    local usesRunes = nil
		    local costInfo = g_GetSpellPowerCost(spellId)
			local nCosts = table.getn(costInfo)
			for iCost = 1, nCosts do
			    if ( costInfo[iCost].type == SPELL_POWER_RUNES ) then  
				    usesRunes = true
				end
			end

			if ( usesRunes ) then
				-- Filter out rune cooldown artificially extending the cd
				if ( duration <= 10 ) then
					local tNow = g_GetTime()
					if ( bar.expirationTime and (tNow < bar.expirationTime) ) then
						-- We've already seen the correct CD for this; keep using it
						start = bar.expirationTime - bar.duration
						duration = bar.duration
					elseif m_last_sent and m_last_sent[spellName] and m_last_sent[spellName] > (tNow - 1.5) then
						-- We think the spell was just cast, and a CD just started but it's short.
						-- Look at the tooltip to tell what the correct CD should be. If it's supposed
						-- to be short (Ghoul Frenzy, Howling Blast), then start a CD bar
						duration = Cooldown.DetermineShortCooldownFromTooltip(barSpell)
						if ( (duration == 0) or (duration > 10) ) then
							start = nil
						end
					else
						start = nil
					end
				end
			end
        end
        
        if ( start ) then
            return start, duration, enabled, spellName, spellIconPath
        end
    end
end

function Cooldown.GetSpellChargesCooldown(bar, entry)
	local barSpell = entry.id or entry.name
	local cur, max, charge_start, recharge = GetSpellCharges(barSpell)
	if ( cur ~= max ) then
		local start, cd_len, enable, spellName, spellIconPath 
		if ( cur == 0 ) then
			start, cd_len, enable, spellName, spellIconPath = Cooldown.GetSpellCooldown(bar, entry)
			return start, cd_len, enable, spellName, spellIconPath, max, charge_start
		else
			local spellName, _, spellIconPath = g_GetSpellInfo(barSpell)
			if ( not spellName ) then 
				spellName = barSpell 
			end
			return charge_start, recharge, 1, spellName, spellIconPath, max-cur
		end
	end
end

function Cooldown.GetAutoShotCooldown(bar)
    -- Helper for mfn_AuraCheck_CASTCD which gets the autoshot cooldown
    local tNow = g_GetTime()
    if ( bar.tAutoShotStart and bar.tAutoShotStart + bar.tAutoShotCD > tNow ) then
        local n, _, icon = g_GetSpellInfo(75)
        return bar.tAutoShotStart, bar.tAutoShotCD, 1, c_AUTO_SHOT_NAME, icon
    else
        bar.tAutoShotStart = nil
    end
end

function Cooldown.GetUnresolvedCooldown(bar, entry)
	-- Helper for mfn_AuraCheck_CASTCD for names we haven't figured out yet
	Cooldown.SetUpSpell(bar, entry)
	local fn = bar.cd_functions[entry.idxName]
	if ( Cooldown.GetUnresolvedCooldown ~= fn ) then
		return fn(bar, entry)
	end
end

