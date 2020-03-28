-- Track player power like energy and combo points

-- Kitjan marked  player power as an "experimental" feature. 
-- NephMakes removed support in NeedToKnow v4.0.27 (Battle for Azeroth). 
-- Quarantining relevant code here in case it gets revisited. 

local addonName, addonTable = ...

NEEDTOKNOW.SPELL_POWER_LEGACY_CP = -1
-- Since i've seen the built-in stuff using -2, I'm going to go further negative
NEEDTOKNOW.SPELL_POWER_STAGGER = -1003
NEEDTOKNOW.SPELL_POWER_PRIMARY = -1002

function NeedToKnow.GetPowerName(pt)
    local name = NEEDTOKNOW.POWER_TYPES[pt]  -- Doesn't appear to be defined anywhere
	if not name then 
	    print("NeedToKnow: Could not find power", pt)
	    return tostring(pt)
	end
	return name
end

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

