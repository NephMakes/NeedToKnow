-- Player and specialization settings

local addonName, addonTable = ...

local GetSpec = _G.GetSpecialization or _G.GetActiveTalentGroup  -- Retail or Classic

function NeedToKnow.RemoveDefaultValues(t, def, k)
  if not k then k = "" end
  if def == nil then
    -- Some obsolete setting, or perhaps bUncompressed
    return true
  end
  -- Never want to compress name since it's read from inactive profiles
  -- Note: k was just for debugging, so it's got a leading space as part
  -- of how the debugging string was built.  This mechanism should probably
  -- be revisited.
  if type(t) ~= "table" then
    return ((k~=" name") and (t == def))
  end
  
  if #t > 0 then
    -- An array, like Groups or Bars. Compare each element against def[1]
    for i,v in ipairs(t)do
      local rhs = def[i]
      if rhs == nil then rhs = def[1] end
      if NeedToKnow.RemoveDefaultValues(v, rhs, k .. " " .. i) then
        t[i] = nil
      end
    end
  else
    for kT, vT in pairs(t) do
      if NeedToKnow.RemoveDefaultValues(t[kT], def[kT], k .. " " .. kT) then
        t[kT] = nil
      end
    end
  end
  local fn = pairs(t)
  return fn(t) == nil
end

function NeedToKnow.CompressProfile(profileSettings)
	-- Compress saved variables by removing unused bars/groups and default settings
    for iG, vG in ipairs(profileSettings["Groups"]) do
        if iG > profileSettings.nGroups then
            profileSettings["Groups"][iG] = nil
        elseif vG.NumberBars then
            for iB, vB in ipairs(vG["Bars"]) do
                if iB > vG.NumberBars then
                    vG["Bars"][iB] = nil
                end
            end
        end
    end
    NeedToKnow.RemoveDefaultValues(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
end

-- DEBUG: remove k, it's just for debugging
function NeedToKnow.AddDefaultsToTable(t, def, k)
    if type(t) ~= "table" then return end
        if def == nil then
            return
        end
    if not k then k = "" end
    local n = table.maxn(t)
    if n > 0 then
        for i=1,n do
            local rhs = def[i]
            if rhs == nil then rhs = def[1] end
            if t[i] == nil then
                t[i] = NeedToKnow.DeepCopy(rhs)
            else
                NeedToKnow.AddDefaultsToTable(t[i], rhs, k .. " " .. i)
            end
        end
        else
        for kD,vD in pairs(def) do
            if t[kD] == nil then
                if type(vD) == "table" then
                    t[kD] = NeedToKnow.DeepCopy(vD)
                else
                    t[kD] = vD
                end
            else
                NeedToKnow.AddDefaultsToTable(t[kD], vD, k .. " " .. kD)
            end
        end
    end
end

function NeedToKnow.UncompressProfile(profileSettings)
	-- Uncompress profile by filling in missing settings from defaults

    -- Make sure the arrays have the right number of elements so that
    -- AddDefaultsToTable will find them and fill them in
    if profileSettings.nGroups then
        if not profileSettings.Groups then
            profileSettings.Groups = {}
        end
        if not profileSettings.Groups[profileSettings.nGroups] then
            profileSettings.Groups[profileSettings.nGroups] = {}
        end
    end
    if profileSettings.Groups then
        for i, g in ipairs(profileSettings.Groups) do
            if g.NumberBars then
                if not g.Bars then
                    g.Bars = {}
                end
                if not g.Bars[g.NumberBars] then
                    g.Bars[g.NumberBars] = {}
                end
            end
        end
    end    
    NeedToKnow.AddDefaultsToTable(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
    profileSettings.bUncompressed = true
end

function NeedToKnow.ChangeProfile(profile_key)
	if NeedToKnow_Profiles[profile_key] and
		 NeedToKnow_Profiles[profile_key] ~= NeedToKnow.ProfileSettings
	then
		-- Compress old profile by removing defaults
		if NeedToKnow.ProfileSettings and NeedToKnow.ProfileSettings.bUncompressed then
			NeedToKnow.CompressProfile(NeedToKnow.ProfileSettings)
		end

		-- Switch to new profile
		NeedToKnow.ProfileSettings = NeedToKnow_Profiles[profile_key]
		local spec = GetSpec()
		NeedToKnow.CharSettings.Specs[spec] = profile_key

		-- Add missing settings from defaults
		NeedToKnow.UncompressProfile(NeedToKnow.ProfileSettings)

		-- FIXME: We currently display 4 groups in the options UI, not nGroups
		-- FIXME: We don't handle nGroups changing (showing/hiding groups based on nGroups changing)
		-- Forcing 4 groups for now
		NeedToKnow.ProfileSettings.nGroups = 4
		for groupID = 1, 4 do
			if not NeedToKnow.ProfileSettings.Groups[groupID] then
				NeedToKnow.ProfileSettings.Groups[groupID] = CopyTable(NEEDTOKNOW.GROUP_DEFAULTS)
				local groupSettings = NeedToKnow.ProfileSettings.Groups[groupID]
				groupSettings.Enabled = false
				groupSettings.Position[4] = -100 - (groupID-1) * 100
			end
		end

		-- Update bars and options panel
		NeedToKnow:Update()
		NeedToKnow:GetOptionsPanel():Update()
	else
		-- print("NeedToKnow profile", profile_key, "does not exist!")
		-- Triggering sometimes when addon appears to be working fine. Why?
	end
end

function NeedToKnowLoader.Reset(bResetCharacter)
    NeedToKnow_Globals = CopyTable( NEEDTOKNOW.DEFAULTS )
    if ( bResetCharacter == nil or bResetCharacter ) then
        NeedToKnow.ResetCharacter()
    end
end

function NeedToKnow.ResetCharacter(bCreateSpecProfile)
	local charKey = UnitName("player") .. ' - ' .. GetRealmName(); 
	NeedToKnow_CharSettings = CopyTable(NEEDTOKNOW.CHARACTER_DEFAULTS)
	NeedToKnow.CharSettings = NeedToKnow_CharSettings
	if ( bCreateSpecProfile == nil or bCreateSpecProfile ) then
		NeedToKnow.ExecutiveFrame:PLAYER_TALENT_UPDATE()    
	end
end

function NeedToKnow.AllocateProfileKey()
    local n = NeedToKnow_Globals.NextProfile or 1
    while NeedToKnow_Profiles["G"..n] do
        n = n+1
    end
    if ( NeedToKnow_Globals.NextProfile == null or n >= NeedToKnow_Globals.NextProfile ) then
        NeedToKnow_Globals.NextProfile = n+1
    end
    return "G"..n;
end

function NeedToKnow.FindUnusedNumericSuffix(prefix, defPrefix)
    local suffix = defPrefix
    if ( not suffix ) then suffix = 1 end

    local candidate = prefix .. suffix
    while ( NeedToKnow.FindProfileByName(candidate) ) do 
        suffix = suffix + 1
        candidate = prefix .. suffix
    end
    return candidate;
end

function NeedToKnow.CreateProfile(settings, idxSpec, nameProfile)
    if ( not nameProfile ) then
        local prefix = UnitName("player") .. "-"..GetRealmName() .. "." 
        nameProfile = NeedToKnow.FindUnusedNumericSuffix(prefix, idxSpec)
    end
    settings.name = nameProfile

    local keyProfile
    for k, t in pairs(NeedToKnow_Globals.Profiles) do
        if ( t.name == nameProfile ) then
            keyProfile = k
            break;
        end
    end

    if ( not keyProfile ) then
        keyProfile = NeedToKnow.AllocateProfileKey()
    end

    if ( NeedToKnow_CharSettings.Profiles[keyProfile] ) then
        print("NeedToKnow: Clearing profile ",nameProfile); -- FIXME - Localization
    else
        print("NeedToKnow: Adding profile",nameProfile) -- FIXME - Localization
    end

    if ( idxSpec ) then
        NeedToKnow.CharSettings.Specs[idxSpec] = keyProfile
    end
    NeedToKnow_CharSettings.Profiles[keyProfile] = settings
    NeedToKnow_Profiles[keyProfile] = settings
    return keyProfile
end

function NeedToKnowLoader.RoundSettings(t)
  for k,v in pairs(t) do
    local typ = type(v)
    if typ == "number" then
      t[k] = tonumber(string.format("%0.4f",v))
    elseif typ == "table" then
      NeedToKnowLoader.RoundSettings(v)
    end
  end    
end

function NeedToKnowLoader.MigrateSpec(specSettings, idxSpec)
    if ( not specSettings or not specSettings.Groups or not specSettings.Groups[1] or not 
       specSettings.Groups[2] or not specSettings.Groups[3] or not specSettings.Groups[4] ) then
        return false
    end
    
    -- Round floats to 0.00001, since old versions left really strange values of
    -- BarSpacing and BarPadding around
    NeedToKnowLoader.RoundSettings(specSettings)
    specSettings.Spec = nil
    specSettings.Locked = nil
    specSettings.nGroups = 4
    specSettings.BarFont = NeedToKnowLoader.FindFontName(specSettings.BarFont)
    NeedToKnow.CreateProfile(specSettings, idxSpec)
    return true
end

function NeedToKnowLoader.MigrateCharacterSettings()
    print("NeedToKnow: Migrating settings from", NeedToKnow_Settings["Version"]);
    local oldSettings = NeedToKnow_Settings
    NeedToKnow.ResetCharacter(false)
    if ( not oldSettings["Spec"] ) then 
        NeedToKnow_Settings = nil 
        return 
    end

    -- Kitjan: Blink was controlled purely by the alpha of MissingBlink for awhile,
    -- But then I introduced an explicit blink_enabled variable.  Fill that in
    -- if it's missing
    for kS,vS in pairs(oldSettings["Spec"]) do
      for kG,vG in pairs(vS["Groups"]) do
        for kB,vB in pairs(vG["Bars"]) do
            if ( nil == vB.blink_enabled and vB.MissingBlink ) then
                vB.blink_enabled = vB.MissingBlink.a > 0
            end
        end
      end
    end

    NeedToKnow.CharSettings["Locked"] = oldSettings["Locked"]

    local bOK
    if ( oldSettings["Spec"] ) then -- The Spec member existed from versions 2.4 to 3.1.7
        for idxSpec = 1,2 do
            local newprofile = oldSettings.Spec[idxSpec]
            for kD,_ in pairs(NEEDTOKNOW.PROFILE_DEFAULTS) do
              if oldSettings[kD] then
                newprofile[kD] = oldSettings[kD]
              end
            end
            bOK = NeedToKnowLoader.MigrateSpec(newprofile, idxSpec)
        end
    -- if before dual spec support, copy old settings to both specs    
    elseif ( oldSettings["Version"] >= "2.0" and oldSettings["Groups"] ) then    
        bOK = NeedToKnowLoader.MigrateSpec(oldSettings, 1) and 
              NeedToKnowLoader.MigrateSpec(CopyTable(oldSettings), 2)

        -- save group positions if upgrading from version that used layout-local.txt
        if ( bOK and NeedToKnow_Settings.Version < "2.1" ) then    
            for groupID = 1, 4 do -- Prior to 3.2, there were always 4 groups
                NeedToKnow.SavePosition(_G["NeedToKnow_Group"..groupID], groupID)
            end
        end        
    end
        
    if not bOK then
        print("Old NeedToKnow character settings corrupted or not compatible with current version... starting from scratch")
        NeedToKnow.ResetCharacter()
    end
    NeedToKnow_Settings = nil
end

function NeedToKnowLoader.FindFontName(fontPath)
    local fontList = NeedToKnow.LSM:List("font")
    for i = 1, #fontList do
        local fontName = fontList[i]
        local iPath = NeedToKnow.LSM:Fetch("font", fontName)
        if ( iPath == fontPath ) then
            return fontName
        end
    end
    return NEEDTOKNOW.PROFILE_DEFAULTS.BarFont
end

function NeedToKnowLoader.SafeUpgrade()
    local defPath = GameFontHighlight:GetFont()
    NEEDTOKNOW.PROFILE_DEFAULTS.BarFont = NeedToKnowLoader.FindFontName(defPath)
    NeedToKnow_Profiles = {}

    -- If there had been an error during the previous upgrade, NeedToKnow_Settings 
    -- may be in an inconsistent, halfway state.  
    if not NeedToKnow_Globals then
        NeedToKnowLoader.Reset(false)
    end

    if NeedToKnow_Settings then -- prior to 4.0
        NeedToKnowLoader.MigrateCharacterSettings()
    end
    if not NeedToKnow_CharSettings then
        -- we'll call talent update right after this, so we pass false now
        NeedToKnow.ResetCharacter(false)
    end
    NeedToKnow.CharSettings = NeedToKnow_CharSettings

    -- 4.0 settings sanity check 
    if not NeedToKnow_Globals or
       not NeedToKnow_Globals["Version"] or
       not NeedToKnow_Globals.Profiles
    then
        print("NeedToKnow settings corrupted, resetting")
        NeedToKnowLoader.Reset()
    end

    local maxKey = 0
    local aByName = {}
    for iS,vS in pairs(NeedToKnow_Globals.Profiles) do
        if vS.bUncompressed then
            NeedToKnow.CompressProfile(vS)
        end
        -- Although name should never be compressed, it could have been prior to 4.0.16
        if not vS.name then vS.name = "Default" end
        local cur = tonumber(iS:sub(2))
        if ( cur > maxKey ) then maxKey = cur end
        NeedToKnow_Profiles[iS] = vS
        if aByName[ vS.name ] then
            local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
            print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
            vS.name = renamed;
        end
        aByName[vS.name] = vS
    end

    local aFixups = {}
    if NeedToKnow_CharSettings.Profiles then
        for iS,vS in pairs(NeedToKnow_CharSettings.Profiles) do
            -- Check for collisions by name
            if aByName[ vS.name ] then
                local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
                print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
                vS.name = renamed;
            end
            aByName[vS.name] = vS

            -- Check for collisions by key
            if ( NeedToKnow_Profiles[iS] ) then
                print("NeedToKnow error encountered, both", vS.name, "and", NeedToKnow_Profiles[iS].name, "collided as " .. iS .. ".  Some specs may be mapped to one that should have been mapped to the other.");
                local oS = iS;
                iS = NeedToKnow.AllocateProfileKey();
                aFixups[oS] = iS
            end

            -- Although name should never be compressed, it could have been prior to 4.0.16
            if not vS.name then vS.name = "Default" end
            local cur = tonumber(iS:sub(2))
            if ( cur > maxKey ) then maxKey = cur end
            NeedToKnow_Profiles[iS] = vS
            local k = NeedToKnow.FindProfileByName(vS.name);
        end
    end

    -- fixup character profile collisions by key
    for oS,iS in pairs(aFixups) do
      NeedToKnow_CharSettings.Profiles[iS] = NeedToKnow_CharSettings.Profiles[oS]; 
      NeedToKnow_CharSettings.Profiles[oS] = nil; 
    end

    if ( not NeedToKnow_Globals.NextProfile or maxKey > NeedToKnow_Globals.NextProfile ) then
        print("Warning, NeedToKnow forgot how many profiles it had allocated.  New account profiles may hiccup when switching characters.")
        NeedToKnow_Globals.NextProfile = maxKey + 1
    end

    local spec = GetSpec()
    local curKey = NeedToKnow.CharSettings.Specs[spec]
    if ( curKey and not NeedToKnow_Profiles[curKey] ) then
        print("Current profile (" .. curKey .. ") has been deleted!");
        curKey = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS), spec)
        local curProf = NeedToKnow_Profiles[curKey]
        NeedToKnow.CharSettings.Specs[spec] = curKey
    end

     -- TODO: check the required members for existence and delete any corrupted profiles
end

function NeedToKnow.DeepCopy(object)
    if type(object) ~= "table" then
        return object
    else
        local new_table = {}
        for k,v in pairs(object) do
            new_table[k] = NeedToKnow.DeepCopy(v)
        end
        return new_table
    end
end

---- Copies anything (int, table, whatever).  Unlike DeepCopy (and CopyTable), CopyRefGraph can 
---- recreate a recursive reference structure (CopyTable will stack overflow.)
---- Copied from http://lua-users.org/wiki/CopyTable
--[[
function NeedToKnow.CopyRefGraph(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
]]--

function NeedToKnow.RestoreTableFromCopy(dest, source)
    for key,value in pairs(source) do
        if type(value) == "table" then
           if dest[key] then
               NeedToKnow.RestoreTableFromCopy(dest[key], value)
           else
               dest[key] = value
           end
        else
            dest[key] = value
        end
    end
    for key,value in pairs(dest) do
        if source[key] == nil then
            dest[key] = nil
        end
    end
end



