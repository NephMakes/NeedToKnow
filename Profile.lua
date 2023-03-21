-- Profiles are complete sets of NeedToKnow settings for one specialization


--[[ Create, copy, rename, delete ]]--

function NeedToKnow.CreateBlankProfile()
	-- Make new profile with default settings and return its key
	local profileKey = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS))
	return profileKey
end

function NeedToKnow.CreateProfile(settings)
	-- Make profile with given settings and return its key
	local profileKey = NeedToKnow.GetNewProfileKey()
	settings.name = NeedToKnow.GetNewProfileName()
	NeedToKnow_Profiles[profileKey] = settings
	NeedToKnow.SetProfileToCharacter(profileKey)
	return profileKey
end

function NeedToKnow.GetNewProfileKey()
	-- Return unique profile key with format "G[integer]"
	local n = NeedToKnow_Globals.NextProfile or 1
	while NeedToKnow_Profiles["G"..n] do
		n = n + 1
	end
	if NeedToKnow_Globals.NextProfile == null or n >= NeedToKnow_Globals.NextProfile then
		NeedToKnow_Globals.NextProfile = n + 1
	end
	return "G"..n
end

function NeedToKnow.GetNewProfileName()
	-- Return unique profile name with format "Character-Server [integer]"
	local i = 1
	local name = UnitName("player") .. "-" .. GetRealmName()
	while not NeedToKnow.IsProfileNameAvailable(name) do
		i = i + 1
		name = name .. " " .. i
	end
	return name
end

function NeedToKnow.IsProfileNameAvailable(name)
	-- Return true if valid name not used by another profile, else return false
	if not name or name == "" then
		return false
	end
	for _, profile in pairs(NeedToKnow_Profiles) do
		if profile.name == name then
			return false
		end
	end
	return true
end

function NeedToKnow.CopyProfile(profileKey)
	-- Called by ProfilePanel.OnClickCopyButton()
	local profile = CopyTable(NeedToKnow_Profiles[profileKey])
	local name = NeedToKnow.GetProfileCopyName(profile.name)
	profileKey = NeedToKnow.CreateProfile(profile)
	NeedToKnow.RenameProfile(profileKey, name)
	return profileKey
end

function NeedToKnow.GetProfileCopyName(oldName)
	-- Return unique profile name with format "[Old name] copy [integer]"
	local newName = oldName .. " copy"
	local i = 1
	while not NeedToKnow.IsProfileNameAvailable(newName) do
		i = i + 1
		newName = oldName .. " copy " .. i
	end
	return newName
end

function NeedToKnow.RenameProfile(profileKey, newName)
	if NeedToKnow.IsProfileNameAvailable(newName) then
		NeedToKnow_Profiles[profileKey].name = newName
	else
		print("NeedToKnow: Profile name", newName, "already in use")
	end
end

function NeedToKnow.SetProfileToAccount(profileKey)
	-- Make profile usable by all characters on this account
	local profile = NeedToKnow_Profiles[profileKey]
	NeedToKnow_Globals.Profiles[profileKey] = profile
	NeedToKnow_CharSettings.Profiles[profileKey] = nil
end

function NeedToKnow.SetProfileToCharacter(profileKey)
	-- Make profile only usable by this character
	local profile = NeedToKnow_Profiles[profileKey]
	NeedToKnow_Globals.Profiles[profileKey] = nil
	NeedToKnow_CharSettings.Profiles[profileKey] = profile
end

function NeedToKnow.DeleteProfile(profileKey)
	if NeedToKnow_Profiles[profileKey] == NeedToKnow.ProfileSettings then
		print("NeedToKnow: Can't delete active profile")
	else
		NeedToKnow_Profiles[profileKey] = nil
		if NeedToKnow_Globals.Profiles[profileKey] then 
			NeedToKnow_Globals.Profiles[profileKey] = nil
		elseif NeedToKnow_CharSettings.Profiles[profileKey] then 
			NeedToKnow_CharSettings.Profiles[profileKey] = nil
		end
	end
end


--[[ Deprecated ]]--

function NeedToKnow.AllocateProfileKey()
	local n = NeedToKnow_Globals.NextProfile or 1
	while NeedToKnow_Profiles["G"..n] do
		n = n + 1
	end
	if NeedToKnow_Globals.NextProfile == null or n >= NeedToKnow_Globals.NextProfile then
		NeedToKnow_Globals.NextProfile = n + 1
	end
	return "G"..n
end

function NeedToKnow.FindProfileByName(name)
	for k, t in pairs(NeedToKnow_Profiles) do
		if t.name == name then
			return k
		end
	end
end

function NeedToKnow.FindUnusedNumericSuffix(prefix, defPrefix)
	local suffix = defPrefix or 1
	local candidate = prefix .. suffix
	while NeedToKnow.FindProfileByName(candidate) do 
		suffix = suffix + 1
		candidate = prefix .. suffix
	end
	return candidate
end


--[[ Activate, compress, uncompress ]]--

function NeedToKnow.GetActiveProfile()
	local profileKey = NeedToKnow.GetProfileForSpec(NeedToKnow.GetSpecIndex())
	return profileKey
end

function NeedToKnow.GetProfileForSpec(specIndex)
	local profileKey = NeedToKnow.CharSettings.Specs[specIndex]
	return profileKey
end

function NeedToKnow.SetProfileForSpec(profileKey, specIndex)
	NeedToKnow.CharSettings.Specs[specIndex] = profileKey
end

function NeedToKnow.GetProfileByName(name)
	for profileKey, profile in pairs(NeedToKnow_Profiles) do
		if profile.name == name then
			return profileKey
		end
	end
end

--function NeedToKnow.GetProfileSettings(profileKey)
--	return NeedToKnow_Profiles[profileKey]
--end

function NeedToKnow.ActivateProfile(profile_key)
	if NeedToKnow_Profiles[profile_key] and NeedToKnow_Profiles[profile_key] ~= NeedToKnow.ProfileSettings then
		-- Compress old profile by removing defaults
		if NeedToKnow.ProfileSettings and NeedToKnow.ProfileSettings.bUncompressed then
			NeedToKnow.CompressProfileSettings(NeedToKnow.ProfileSettings)
		end

		-- Set new active profile
		NeedToKnow.SetProfileForSpec(profile_key, NeedToKnow.GetSpecIndex())
		NeedToKnow.ProfileSettings = NeedToKnow_Profiles[profile_key]

		-- Add missing settings from defaults
		NeedToKnow.UncompressProfileSettings(NeedToKnow.ProfileSettings)

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

		-- Update bars and options panels
		NeedToKnow:Update()
		NeedToKnow:GetOptionsPanel():Update()
		-- To do: Update AppearancePanel
	else
		-- print("NeedToKnow profile", profile_key, "does not exist!")
		-- Neph: This is triggering sometimes when addon appears to be working fine. Why?
	end
end

function NeedToKnow.CompressProfileSettings(profileSettings)
	-- Compress saved variables by removing unused bars/groups and default settings
	for groupIndex, groupSettings in ipairs(profileSettings.Groups) do
		if groupIndex > profileSettings.nGroups then
			profileSettings.Groups[groupIndex] = nil
		elseif groupSettings.NumberBars then
			for barIndex, _ in ipairs(groupSettings.Bars) do
				if barIndex > groupSettings.NumberBars then
					groupSettings.Bars[barIndex] = nil
				end
			end
		end
	end
	NeedToKnow.RemoveDefaultValues(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
end

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
	for i, v in ipairs(t) do
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

function NeedToKnow.UncompressProfileSettings(profileSettings)
	-- Uncompress profile by filling in missing settings from defaults

	-- Make sure arrays have right number of elements 
	-- so AddDefaultsToTable() will find them and fill them in
	if profileSettings.nGroups then
		if not profileSettings.Groups then
			profileSettings.Groups = {}
		end
		if not profileSettings.Groups[profileSettings.nGroups] then
			profileSettings.Groups[profileSettings.nGroups] = {}
		end
		-- profileSettings.Groups = profileSettings.Groups or {}
		-- profileSettings.Groups[profileSettings.nGroups] = profileSettings.Groups[profileSettings.nGroups] or {}
	end
	if profileSettings.Groups then
		for _, g in ipairs(profileSettings.Groups) do
			if g.NumberBars then
				if not g.Bars then
					g.Bars = {}
				end
				if not g.Bars[g.NumberBars] then
					g.Bars[g.NumberBars] = {}
				end
				-- g.Bars = g.Bars or {}
				-- g.Bars[g.NumberBars] = g.Bars[g.NumberBars] or {}
			end
		end
	end

	NeedToKnow.AddDefaultsToTable(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
	profileSettings.bUncompressed = true
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
		for i = 1, n do
			local rhs = def[i]
			if rhs == nil then rhs = def[1] end
			if t[i] == nil then
				t[i] = NeedToKnow.DeepCopy(rhs)
			else
				NeedToKnow.AddDefaultsToTable(t[i], rhs, k .. " " .. i)
			end
		end
		else
		for kD, vD in pairs(def) do
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

function NeedToKnow.Reset(resetCharacter)
	-- Reset global saved variables (NeedToKnow_Globals) to default settings
	-- Called by NeedToKnow.SlashCommand()
    NeedToKnow_Globals = CopyTable(NeedToKnow.DefaultSettings.global)
    if resetCharacter or resetCharacter == nil then
        NeedToKnow.ResetCharacter()
    end
end

function NeedToKnow.ResetCharacter(bCreateSpecProfile)
	-- Called by NeedToKnow.Reset(), NeedToKnowLoader.Reset(bResetCharacter), ...
	-- local charKey = UnitName("player") .. ' - ' .. GetRealmName()
	NeedToKnow_CharSettings = CopyTable(NEEDTOKNOW.CHARACTER_DEFAULTS)
	NeedToKnow.CharSettings = NeedToKnow_CharSettings
	if bCreateSpecProfile == nil or bCreateSpecProfile then
		NeedToKnow.ExecutiveFrame:PLAYER_TALENT_UPDATE()    
	end
end



--[[ NeedToKnowLoader ]]-- 

function NeedToKnowLoader.Reset(bResetCharacter)
	-- Called by NeedToKnowLoader.SafeUpgrade()
	NeedToKnow_Globals = CopyTable(NEEDTOKNOW.DEFAULTS)
	if bResetCharacter == nil or bResetCharacter then
		NeedToKnow.ResetCharacter()
	end
end

function NeedToKnowLoader.RoundSettings(t)
	-- Called by NeedToKnowLoader.MigrateSpec()
	for k, v in pairs(t) do
		local typ = type(v)
		if typ == "number" then
			t[k] = tonumber(string.format("%0.4f", v))
		elseif typ == "table" then
			NeedToKnowLoader.RoundSettings(v)
		end
	end
end

function NeedToKnowLoader.MigrateSpec(specSettings, specID)
	-- Convert old profile for spec
	-- Called by NeedToKnowLoader.MigrateCharacterSettings()

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
	local profileKey = NeedToKnow.CreateProfile(specSettings)
	NeedToKnow.SetProfileForSpec(profileKey, specID)
	return true
end

function NeedToKnowLoader.MigrateCharacterSettings()
	-- Import settings from NeedToKnow versions prior to v4.0.0

    print("NeedToKnow: Migrating settings from", NeedToKnow_Settings["Version"])
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
        for specID = 1,2 do
            local newprofile = oldSettings.Spec[specID]
            for kD,_ in pairs(NEEDTOKNOW.PROFILE_DEFAULTS) do
              if oldSettings[kD] then
                newprofile[kD] = oldSettings[kD]
              end
            end
            bOK = NeedToKnowLoader.MigrateSpec(newprofile, specID)
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
		if iPath == fontPath then
			return fontName
		end
	end
	return NEEDTOKNOW.PROFILE_DEFAULTS.BarFont
end

function NeedToKnow.LoadProfiles()
	-- Called by ExecutiveFrame:PLAYER_LOGIN()

	-- Set default font
	local defPath = GameFontHighlight:GetFont()
	NEEDTOKNOW.PROFILE_DEFAULTS.BarFont = NeedToKnowLoader.FindFontName(defPath)

	NeedToKnow_Profiles = {}

	-- If there had been an error during the previous upgrade, NeedToKnow_Settings 
	-- may be in an inconsistent, halfway state.  
	if not NeedToKnow_Globals then
		NeedToKnowLoader.Reset(false)
	end

	if NeedToKnow_Settings then  -- prior to 4.0
		NeedToKnowLoader.MigrateCharacterSettings()  -- Upgrade from previous versions
	end

	if not NeedToKnow_CharSettings then
		-- We'll call talent update right after this, so pass false now
		NeedToKnow.ResetCharacter(false)
	end
	NeedToKnow.CharSettings = NeedToKnow_CharSettings

	-- 4.0 settings sanity check 
	if not NeedToKnow_Globals or
	   not NeedToKnow_Globals["Version"] or
	   not NeedToKnow_Globals.Profiles
	then
		print("NeedToKnow: Settings corrupted. Resetting.")
		NeedToKnowLoader.Reset()
	end

	-- Populate NeedToKnow_Profiles from NeedToKnow_Globals and NeedToKnow_CharSettings
	local maxKey = 0
	local aByName = {}
	for iS, vS in pairs(NeedToKnow_Globals.Profiles) do
		if vS.bUncompressed then
			NeedToKnow.CompressProfileSettings(vS)
		end
		-- Although name should never be compressed, it could have been prior to 4.0.16
		if not vS.name then 
			vS.name = "Default"
		end
		local cur = tonumber(iS:sub(2))
		if cur > maxKey then 
			maxKey = cur
		end
		NeedToKnow_Profiles[iS] = vS
		if aByName[vS.name] then
			local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
			print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
			vS.name = renamed
		end
		aByName[vS.name] = vS
	end
	local aFixups = {}
	if NeedToKnow_CharSettings.Profiles then
		for iS, vS in pairs(NeedToKnow_CharSettings.Profiles) do
			-- Check for collisions by name
			if aByName[vS.name] then
				local renamed = NeedToKnow.FindUnusedNumericSuffix(vS.name, 2)
				print("Error! the profile name " .. vS.name .. " has been reused!  Renaming one of them to " .. renamed)
				vS.name = renamed
			end
			aByName[vS.name] = vS

			-- Check for collisions by key
			if NeedToKnow_Profiles[iS] then
				print("NeedToKnow error encountered, both", vS.name, "and", NeedToKnow_Profiles[iS].name, "collided as " .. iS .. ".  Some specs may be mapped to one that should have been mapped to the other.")
				local oS = iS
				iS = NeedToKnow.AllocateProfileKey()
				aFixups[oS] = iS
			end

			-- Although name should never be compressed, it could have been prior to 4.0.16
			if not vS.name then
				vS.name = "Default"
			end
			local cur = tonumber(iS:sub(2))
			if cur > maxKey then
				maxKey = cur
			end
			NeedToKnow_Profiles[iS] = vS
			-- local k = NeedToKnow.FindProfileByName(vS.name)
		end
	end

	-- Fix character profile collisions by key
	for oS, iS in pairs(aFixups) do
		NeedToKnow_CharSettings.Profiles[iS] = NeedToKnow_CharSettings.Profiles[oS]
		NeedToKnow_CharSettings.Profiles[oS] = nil
	end

	if not NeedToKnow_Globals.NextProfile or maxKey > NeedToKnow_Globals.NextProfile then
		print("Warning, NeedToKnow forgot how many profiles it had allocated. New account profiles may hiccup when switching characters.")
		NeedToKnow_Globals.NextProfile = maxKey + 1
	end

	-- Make new blank profile if active one was deleted
	-- local profileKey = NeedToKnow.GetActiveProfile()
	local profileKey = NeedToKnow.GetProfileForSpec(NeedToKnow.GetSpecIndex())
	if profileKey and not NeedToKnow_Profiles[profileKey] then
		print("NeedToKnow: Active profile", profileKey, "not found. Making new blank profile.")
		profileKey = NeedToKnow.CreateBlankProfile()
		NeedToKnow.ActivateProfile(profileKey)
	end

	 -- TODO: check the required members for existence and delete any corrupted profiles
end



