-- Profiles are complete sets of NeedToKnow settings for one specialization

--[[
Important global variables: 
	NeedToKnow_Globals: Saved variable. Has account-wide profiles. 
	NeedToKnow_CharSettings: Saved variable per character. Has character-specific profiles. 
	NeedToKnow_Settings: Saved variable from old versions. No longer used. Deprecated. 
	NeedToKnow_Profiles: Has all profiles available to character. Deprecated. 

	NeedToKnow.profiles = Table of profiles available to character {{profileKey = settings}, ...}
]]--


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

--function NeedToKnow.IsProfileToAccount(profileKey)
--	if NeedToKnow_Globals.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end
--
--function NeedToKnow.IsProfileToCharacter(profileKey)
--	if NeedToKnow_CharSettings.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end

function NeedToKnow.DeleteProfile(profileKey)
	if profileKey == NeedToKnow.GetActiveProfile() then
		print("NeedToKnow: Can't delete active profile")
	else
		NeedToKnow_Profiles[profileKey] = nil
		NeedToKnow_Globals.Profiles[profileKey] = nil
		NeedToKnow_CharSettings.Profiles[profileKey] = nil
	end
end

function NeedToKnow:LoadProfiles()
	-- Called by ExecutiveFrame:PLAYER_LOGIN()

	-- NeedToKnow.profiles = {}
	NeedToKnow_Profiles = {}  -- Deprecated

	if not NeedToKnow_Globals then
		NeedToKnowLoader.Reset(false)
	end
	if not NeedToKnow_CharSettings then
		-- [Kitjan] We'll call talent update right after this, so pass false now
		NeedToKnow.ResetCharacter(false)
	end

	NeedToKnow.CharSettings = NeedToKnow_CharSettings  -- Deprecated

	-- 4.0 settings sanity check 
	if not NeedToKnow_Globals or
		-- not NeedToKnow_Globals["Version"] or
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
--		-- Although name should never be compressed, it could have been prior to 4.0.16
--		if not vS.name then 
--			vS.name = "Default"
--		end
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

--			-- Although name should never be compressed, it could have been prior to 4.0.16
--			if not vS.name then
--				vS.name = "Default"
--			end
			local cur = tonumber(iS:sub(2))
			if cur > maxKey then
				maxKey = cur
			end
			NeedToKnow_Profiles[iS] = vS
		end
	end

	-- Fix character profile collisions by key
	for oS, iS in pairs(aFixups) do
		NeedToKnow_CharSettings.Profiles[iS] = NeedToKnow_CharSettings.Profiles[oS]
		NeedToKnow_CharSettings.Profiles[oS] = nil
	end

	-- Show error message if problem with NextProfile
	if not NeedToKnow_Globals.NextProfile or maxKey > NeedToKnow_Globals.NextProfile then
		print("Warning, NeedToKnow forgot how many profiles it had allocated. New account profiles may hiccup when switching characters.")
		NeedToKnow_Globals.NextProfile = maxKey + 1
	end

	-- Make new blank profile if active one was deleted
	local profileKey = NeedToKnow.GetActiveProfile()
	if profileKey and not NeedToKnow_Profiles[profileKey] then
		print("NeedToKnow: Profile", profileKey, "not found. Making new blank profile.")
		profileKey = NeedToKnow.CreateBlankProfile()
		NeedToKnow.ActivateProfile(profileKey)
	end

	 -- TODO: check the required members for existence and delete any corrupted profiles
end

function NeedToKnow.SetProfileForSpec(profileKey, specIndex)
	NeedToKnow.CharSettings.Specs[specIndex] = profileKey
end

function NeedToKnow.GetProfileForSpec(specIndex)
	local profileKey = NeedToKnow.CharSettings.Specs[specIndex]
	return profileKey
end

function NeedToKnow.GetActiveProfile()
	local profileKey = NeedToKnow.GetProfileForSpec(NeedToKnow.GetSpecIndex())
	return profileKey
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

function NeedToKnow.ActivateProfile(profileKey)
	local oldSettings = NeedToKnow.ProfileSettings
	local newSettings = NeedToKnow_Profiles[profileKey]
	if newSettings and newSettings ~= oldSettings then
		if oldSettings and oldSettings.bUncompressed then
			NeedToKnow.CompressProfileSettings(oldSettings)
		end
		NeedToKnow.UncompressProfileSettings(newSettings)
		NeedToKnow.ProfileSettings = newSettings
		NeedToKnow.SetProfileForSpec(profileKey, NeedToKnow.GetSpecIndex())
		NeedToKnow:Update()
		NeedToKnow.OptionsPanel:Update()
		NeedToKnow.AppearancePanel:Update()
	-- else
		-- print("NeedToKnow: Profile", profileKey, "not found")
		-- Neph: Triggering sometimes when addon appears to be working fine. Why?
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
	NeedToKnow.RemoveDefaultSettings(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
end

function NeedToKnow.UncompressProfileSettings(profileSettings)
	-- Uncompress profile by filling in missing settings from defaults

	-- Make sure arrays have right number of elements for AddDefaultSettings()
	local numberGroups = profileSettings.nGroups
	if numberGroups then
		profileSettings.Groups = profileSettings.Groups or {}
		profileSettings.Groups[numberGroups] = profileSettings.Groups[numberGroups] or {}
	end
	if profileSettings.Groups then
		for _, groupSettings in ipairs(profileSettings.Groups) do
			local numberBars = groupSettings.NumberBars
			if numberBars then
				groupSettings.Bars = groupSettings.Bars or {}
				groupSettings.Bars[numberBars] = groupSettings.Bars[numberBars] or {}
			end
		end
	end

	NeedToKnow.AddDefaultSettings(profileSettings, NEEDTOKNOW.PROFILE_DEFAULTS)
	profileSettings.bUncompressed = true

	-- Deprecated legacy code from unfinished feature to change number of bar groups
	profileSettings.nGroups = 4
	for groupID = 1, profileSettings.nGroups do
		if not profileSettings.Groups[groupID] then
			profileSettings.Groups[groupID] = CopyTable(NEEDTOKNOW.GROUP_DEFAULTS)
			local groupSettings = profileSettings.Groups[groupID]
			groupSettings.Enabled = false
			groupSettings.Position[4] = -100 - (groupID-1) * 100
		end
	end
end

function NeedToKnow.RemoveDefaultSettings(object, default, debugString)
	-- Recursively delete default settings from object
	-- Then return true if object is nil, an empty table, or non-table equal to default

	if not debugString then debugString = "" end
	-- Note: debugString had leading space. Should be revisited.

	if default == nil then  -- Obsolete setting or maybe bUncompressed
		return true
	end

	if type(object) ~= "table" then
		return ((object == default) and (debugString ~= " name"))
		-- Note: Shouldn't compress name because it's read from inactive profiles
	end

	if #object > 0 then  -- Indexed table like Groups or Bars
		for i, v in ipairs(object) do
			local defaultValue = default[i]
			if defaultValue == nil then
				defaultValue = default[1]
			end
			if NeedToKnow.RemoveDefaultSettings(v, defaultValue, debugString .. " " .. i) then
				object[i] = nil
			end
		end
	else
		for k, v in pairs(object) do
			if NeedToKnow.RemoveDefaultSettings(object[k], default[k], debugString .. " " .. k) then
				object[k] = nil
			end
		end
	end

	-- Return true if object is empty table
	local fn = pairs(object)
	return fn(object) == nil
end

function NeedToKnow.AddDefaultSettings(object, default)
	-- Recursively add default settings to object
	if (default == nil) or (type(object) ~= "table") then
		return
	end
	local n = table.maxn(object)  -- Note: table.maxn() deprecated as of Lua 5.2, WoW uses Lua 5.1.1
	if n > 0 then  -- Indexed table like Groups or Bars
		for i = 1, n do
			local defaultValue = default[i]
			if defaultValue == nil then 
				defaultValue = default[1]
			end
			if object[i] == nil then
				object[i] = NeedToKnow.DeepCopy(defaultValue)
			else
				NeedToKnow.AddDefaultSettings(object[i], defaultValue)
			end
		end
	else
		for key, value in pairs(default) do
			if object[key] == nil then
				if type(value) == "table" then
					object[key] = NeedToKnow.DeepCopy(value)
				else
					object[key] = value
				end
			else
				NeedToKnow.AddDefaultSettings(object[key], value)
			end
		end
	end
end

function NeedToKnow:UpdateActiveProfile()
	if NeedToKnow.CharSettings then
		local specIndex = NeedToKnow.GetSpecIndex()
		local profileKey = NeedToKnow.GetProfileForSpec(specIndex)
		if not profileKey then
			print("NeedToKnow: Making new profile for specialization", specIndex)
			profileKey = NeedToKnow.CreateBlankProfile()
		end
		NeedToKnow.ActivateProfile(profileKey)
	end
end

function NeedToKnow.Reset(resetCharacter)
	-- Reset global saved variables to default settings
	-- Called by NeedToKnow.SlashCommand()
    NeedToKnow_Globals = CopyTable(NeedToKnow.DefaultSettings.global)
    if resetCharacter or resetCharacter == nil then
        NeedToKnow.ResetCharacter()
    end
end

function NeedToKnow.ResetCharacter(bCreateSpecProfile)
	-- Reset character saved variables to default settings
	-- Called by NeedToKnow.Reset(), NeedToKnowLoader.Reset(bResetCharacter), ...
	-- local charKey = UnitName("player") .. ' - ' .. GetRealmName()
	NeedToKnow_CharSettings = CopyTable(NEEDTOKNOW.CHARACTER_DEFAULTS)
	NeedToKnow.CharSettings = NeedToKnow_CharSettings
	if bCreateSpecProfile == nil or bCreateSpecProfile then
		NeedToKnow:UpdateActiveProfile()
	end
end


--[[ Deprecated ]]--

function NeedToKnowLoader.Reset(bResetCharacter)
	-- Reset global saved variables to default settings
	-- Called by NeedToKnowLoader.SafeUpgrade()
	NeedToKnow_Globals = CopyTable(NEEDTOKNOW.DEFAULTS)
	if bResetCharacter == nil or bResetCharacter then
		NeedToKnow.ResetCharacter()
	end
end

--[[
-- v4.0 released quite some time ago. Time to move on. 

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

function NeedToKnowLoader.FindFontName(fontPath)
	-- Return font name for given font path
	-- Because old versions stored font path not name?
	-- Or because we're localizing the default font? 
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
]]--

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

function NeedToKnow.FindUnusedNumericSuffix(prefix, defPrefix)
	local suffix = defPrefix or 1
	local candidate = prefix .. suffix
	while NeedToKnow.FindProfileByName(candidate) do 
		suffix = suffix + 1
		candidate = prefix .. suffix
	end
	return candidate
end

function NeedToKnow.FindProfileByName(name)
	for k, t in pairs(NeedToKnow_Profiles) do
		if t.name == name then
			return k
		end
	end
end




