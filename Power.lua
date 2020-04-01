-- Track player power like energy and combo points
-- 
-- Kitjan marked power tracking as "experimental". 
-- NephMakes removed support in NeedToKnow v4.0.27 (Battle for Azeroth) 
-- because it was broken and somewhat out of scope. Fight feature bloat! 
-- 
-- Quarantining old code here in case it gets revisited

local addonName, addonTable = ...

local mfn_AddInstanceToStacks = addonTable.mfn_AddInstanceToStacks
local mfn_EnergyBar_OnUpdate = addonTable.mfn_EnergyBar_OnUpdate
local mfn_SetStatusBarValue = addonTable.mfn_SetStatusBarValue


NEEDTOKNOW.SPELL_POWER_LEGACY_CP = -1
-- Since i've seen the built-in stuff using -2, I'm going to go further negative
NEEDTOKNOW.SPELL_POWER_STAGGER = -1003
NEEDTOKNOW.SPELL_POWER_PRIMARY = -1002

function NeedToKnow.GetPowerName(pt)
    local name = NEEDTOKNOW.POWER_TYPES[pt]
	if not name then 
	    print("NeedToKnow: Could not find power", pt)
	    return tostring(pt)
	end
	return name
end

--[[
addonTable.mfn_AuraCheck_POWER = function (bar, bar_entry, all_stacks)
    -- Bar_AuraCheck helper for power and combo points.  The current
    -- amount is reported as the first tooltip number rather than 
    -- stacks since 1 stack doesn't get displayed normally

    local spellName, _, spellIconPath
    local cpt = UnitPowerType(bar.unit)
    local pt = bar_entry.id

    if ( pt ) then
        if pt == NEEDTOKNOW.SPELL_POWER_PRIMARY then pt = cpt end
        if (pt == NEEDTOKNOW.SPELL_POWER_LEGACY_CP) then pt = SPELL_POWER_COMBO_POINTS end

        local curPower, maxPower;
        if (pt == NEEDTOKNOW.SPELL_POWER_STAGGER ) then
		    curPower = UnitStagger(bar.unit)
			maxPower = UnitHealthMax(bar.unit)
        else
            curPower = UnitPower(bar.unit, pt)
            maxPower = UnitPowerMax(bar.unit, pt)
        end

        if ( maxPower and maxPower > 0 and
             (not bar.settings.power_sole or pt == cpt) ) 
        then
            local bTick = false
            if pt == 3 then -- SPELL_POWER_ENERGY
                if (pt == cpt) then
                    bar.power_regen = GetPowerRegen()
                end
                if (bar.power_regen and bar.power_regen > 0) then
                    bTick = true
                end
            end
            if bTick then
                if not bar.ticking then
                    bar.ticker = mfn_EnergyBar_OnUpdate
                    bar:SetScript("OnUpdate", bar.ticker)
                    bar.ticking = true
                end
            elseif bar.ticking then
                bar:SetScript("OnUpdate", nil)
                bar.ticking = false
            end

            if bar.ticking then                
                local now = g_GetTime()
                if not bar.tPower or now - bar.tPower > 2 or bar.last_power ~= curPower then
                    bar.tPower = now
                    bar.last_power = curPower
                    bar.last_power_max = maxPower

                end
            end

            mfn_AddInstanceToStacks(all_stacks, bar_entry, 
                   0,                                          -- duration
                   NeedToKnow.GetPowerName(pt),                -- name
                   1,                                          -- count
                   0,                                          -- expiration time
                   nil,                                        -- icon path
                   bar.unit,                                   -- caster
                   curPower,                                   -- tooltip #1
                   maxPower,                                   -- tooltip #2
                   floor(curPower*1000/maxPower)/10 )          -- tooltip #3
        end
    end
end

addonTable.mfn_EnergyBar_OnUpdate = function(bar, elapsed)
    local now = g_GetTime()
    if ( now > bar.nextUpdate ) then
        bar.nextUpdate = now + c_UPDATE_INTERVAL
        local delta = now - bar.tPower
        local predicted = bar.last_power + bar.power_regen * delta
        local bCapped = false
        if predicted >= bar.last_power_max then
            predicted = bar.last_power_max
            bCapped = true
        elseif predicted <= 0 then
            predicted = 0
            bCapped = true
        end

        bar.max_value = bar.last_power_max
        mfn_SetStatusBarValue(bar, bar.bar1, predicted);

        if bCapped then
            bar.ticking = false
            bar:SetScript("OnUpdate", nil)
        end
    end
end
]]--

--[[
function NeedToKnowLoader.SetPowerTypeList(player_CLASS)
    if player_CLASS == "DRUID" or 
        player_CLASS == "MONK" 
    then
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(NEEDTOKNOW.SPELL_POWER_PRIMARY), MenuText = NeedToKnow.GetPowerName(NEEDTOKNOW.SPELL_POWER_PRIMARY) } ) 
    end
    if player_CLASS == "MONK" 
    then
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(NEEDTOKNOW.SPELL_POWER_STAGGER), MenuText = NeedToKnow.GetPowerName(NEEDTOKNOW.SPELL_POWER_STAGGER) } ) 
    end

	local powerTypesUsed = {}
	
    local numTabs = g_GetNumSpellTabs() 
	for iTab=1,numTabs do 
	    local _,_,offset,numSpells = g_GetSpellTabInfo(iTab) 
	    for iSpell=1,numSpells do 
		    local stype,sid = g_GetSpellBookItemInfo(iSpell+offset, "book") 
			-- print(iTab, iSpell, stype, sid)
			if (stype=="SPELL" or stype=="FUTURESPELL") then
			    NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed);
			end
		end 
	end
	
	local nSpecs = g_GetNumSpecializations()
	for iSpec=1,nSpecs do
	    local spells = {g_GetSpecializationSpells(iSpec)}
		local numSpells = table.getn(spells)
		for iSpell=1,numSpells,2 do
		    local sid = spells[iSpell]
			NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed);
		end
	end
	
	for pt,ptn in pairs(powerTypesUsed) do
        table.insert(NeedToKnowRMB.BarMenu_SubMenus.PowerTypeList,
            { Setting = tostring(pt), MenuText = NeedToKnow.GetPowerName(pt) } ) 
	end
end	
]]--

--[[
function NeedToKnowLoader.AddSpellCost(sid, powerTypesUsed)
    local costInfo = g_GetSpellPowerCost(sid)
	local iCost
	for iCost =1,table.getn(costInfo) do
	    local pt = costInfo[iCost].type
		-- -2 is used as HEALTH for certain self-harming spells
		if ( pt >= 0 ) then
		    local n = g_GetSpellInfo(sid)
			-- print(sid, n, pt)
			powerTypesUsed[pt] = costInfo[iCost].name;
		end
	end
end
]]--

--[[
NTK_LocLoader = {}
function NTK_LocLoader.IsSpellPower(intVarName)
	local subStart, subEnd = intVarName:find("SPELL_POWER_")
	if subStart == 1 then
	    local stringVarName = intVarName:sub(subEnd+1)
		local stringValue = _G[stringVarName]
		if stringValue == nil or type(stringValue) ~= "string" then
		    return nil
		else
			return true, stringValue
		end
	end
	return nil
end
]]--

--[[
function NTK_LocLoader.FindPowerTypes()
    NEEDTOKNOW.POWER_TYPES = {};
    NEEDTOKNOW.POWER_TYPES[SPELL_POWER_MANA] = MANA
    NEEDTOKNOW.POWER_TYPES[NEEDTOKNOW.SPELL_POWER_PRIMARY] = NEEDTOKNOW.BARMENU_POWER_PRIMARY
    NEEDTOKNOW.POWER_TYPES[NEEDTOKNOW.SPELL_POWER_STAGGER] = NEEDTOKNOW.BARMENU_POWER_STAGGER
    NEEDTOKNOW.POWER_TYPES[SPELL_POWER_ALTERNATE_POWER] = NEEDTOKNOW.ALTERNATE_POWER
    
    -- I had found CombatLog_String_PowerType sitting in _G, apparantly added by a blizzard adddon.
    -- However a user had trouble with it not adding Focus, and since it wasn't very public-looking
    -- anyway, I opted to write my own.  I had been hoping to avoid walking all of _G.
    for gkey, gval in pairs(_G) do
        if type(gkey) == "string" and type(gval) == "number" then
    	    local ok, localized = NTK_LocLoader.IsSpellPower(gkey)
    		if ok then 
    		    NEEDTOKNOW.POWER_TYPES[gval] = localized
    		end
    	end
    end
    NEEDTOKNOW.POWER_TYPES[NEEDTOKNOW.SPELL_POWER_LEGACY_CP] = NEEDTOKNOW.POWER_TYPES[SPELL_POWER_COMBO_POINTS]
end
NTK_LocLoader.FindPowerTypes()
NTK_LocLoader = nil
]]--

