-- Profiles are complete sets of NeedToKnow settings for one specialization

--[[
NeedToKnow_Globals: Saved variable. Has account-wide profiles. 
NeedToKnow_CharSettings: Saved variable per character. Has character-specific profiles. 

NeedToKnow.accountSettings: Reference to NeedToKnow_Globals
NeedToKnow.characterSettings: Reference to NeedToKnow_CharSettings
NeedToKnow.profiles: Table of profiles available to character {[profileKey] = settings}
NeedToKnow.characterSettings.Specs: Table of active profiles for each spec {[specIndex] = profileKey}
NeedToKnow.profileSettings: Reference to settings for current active profile
]]--


--[[ Settings ]]--

function NeedToKnow:LoadSavedVariables()
	-- Load account-wide saved variable
	if NeedToKnow_Globals then
		self.accountSettings = NeedToKnow_Globals
	else
		self:ResetAccountSettings()
	end
	-- Load character-specific saved variable
	if NeedToKnow_CharSettings then
		self.characterSettings = NeedToKnow_CharSettings
		self.CharSettings = NeedToKnow_CharSettings  -- Deprecated
	else
		self:ResetCharacterSettings()
	end
end

function NeedToKnow:ResetAccountSettings()
	NeedToKnow_Globals = CopyTable(NEEDTOKNOW.DEFAULTS)
	self.accountSettings = NeedToKnow_Globals
end

function NeedToKnow:ResetCharacterSettings()
	NeedToKnow_CharSettings = CopyTable(NEEDTOKNOW.CHARACTER_DEFAULTS)
	self.characterSettings = NeedToKnow_CharSettings
	self.CharSettings = NeedToKnow_CharSettings  -- Deprecated
end

function NeedToKnow:GetCharacterSettings()
	return NeedToKnow.characterSettings
end

function NeedToKnow:GetProfileSettings()
	return NeedToKnow.ProfileSettings
end


--[[ Profiles ]]--

function NeedToKnow.CreateBlankProfile()
	-- Make new profile with default settings and return its key
	local profileKey = NeedToKnow.CreateProfile(CopyTable(NEEDTOKNOW.PROFILE_DEFAULTS))
	return profileKey
end

function NeedToKnow.CreateProfile(settings)
	-- Make new profile with given settings and return its key
	local profileKey = NeedToKnow.GetNewProfileKey()
	settings.name = NeedToKnow.GetNewProfileName()
	NeedToKnow.profiles[profileKey] = settings
	NeedToKnow.SetProfileToCharacter(profileKey)
	return profileKey
end

function NeedToKnow.GetNewProfileKey()
	-- Return unique profile key with format "G[integer]"
	local settings = NeedToKnow.accountSettings
	local n = settings.NextProfile or 1
	while NeedToKnow.profiles["G"..n] do
		n = n + 1
	end
	if not settings.NextProfile or settings.NextProfile <= n then
		settings.NextProfile = n + 1
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
	for _, profile in pairs(NeedToKnow.profiles) do
		if profile.name == name then
			return false
		end
	end
	return true
end

function NeedToKnow.CopyProfile(profileKey)
	-- Make new profile with same settings and return its key
	-- Called by ProfilePanel.OnClickCopyButton()
	local profile = CopyTable(NeedToKnow.profiles[profileKey])
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
		NeedToKnow.profiles[profileKey].name = newName
	else
		print("NeedToKnow: Profile name", newName, "already in use")
	end
end

function NeedToKnow.SetProfileToAccount(profileKey)
	-- Make profile usable by all characters on this account
	local profile = NeedToKnow.profiles[profileKey]
	NeedToKnow.accountSettings.Profiles[profileKey] = profile
	NeedToKnow.characterSettings.Profiles[profileKey] = nil
end

function NeedToKnow.SetProfileToCharacter(profileKey)
	-- Make profile only usable by this character
	local profile = NeedToKnow.profiles[profileKey]
	NeedToKnow.accountSettings.Profiles[profileKey] = nil
	NeedToKnow.characterSettings.Profiles[profileKey] = profile
end

--function NeedToKnow:IsProfileToAccount(profileKey)
--	if self.accountSettings.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end
--
--function NeedToKnow:IsProfileToCharacter(profileKey)
--	if self.characterSettings.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end

function NeedToKnow.DeleteProfile(profileKey)
	if profileKey == NeedToKnow.GetActiveProfile() then
		print("NeedToKnow: Can't delete active profile")
	else
		NeedToKnow.profiles[profileKey] = nil
		NeedToKnow.accountSettings.Profiles[profileKey] = nil
		NeedToKnow.characterSettings.Profiles[profileKey] = nil
	end
end

function NeedToKnow:LoadProfiles()
	-- Called by ExecutiveFrame:PLAYER_LOGIN()
	self.profiles = {}  -- Table of available profiles, {[profileKey] = settings}
	local accountSettings = self.accountSettings
	local characterSettings = self.characterSettings

	-- Populate NeedToKnow.profiles from saved variables
	local maxKeyIndex = 0
	local profilesByName = {}  -- For fixing duplicated profile names
	local aFixups = {}  -- For fixing duplicated profile keys
	for key, settings in pairs(accountSettings.Profiles) do
		if settings.bUncompressed then
			NeedToKnow.CompressProfileSettings(settings)
		end

		-- Fix duplicated profile name
		if profilesByName[settings.name] then
			local newName = NeedToKnow.GetNonduplicateProfileName(oldName)
			print("NeedToKnow: Duplicate profile name", settings.name .. ".", "Renaming", newName)
			settings.name = newName
		end
		profilesByName[settings.name] = settings

		-- Update maxKeyIndex for NeedToKnow_Globals.NextProfile
		local keyIndex = tonumber(key:sub(2))
		if keyIndex > maxKeyIndex then 
			maxKeyIndex = keyIndex
		end

		self.profiles[key] = settings
	end
	for key, settings in pairs(characterSettings.Profiles) do
		-- Fix duplicated profile name
		if profilesByName[settings.name] then
			local newName = NeedToKnow.GetNonduplicateProfileName(oldName)
			print("NeedToKnow: Duplicate profile name", settings.name .. ".", "Renaming", newName)
			settings.name = newName
		end
		profilesByName[settings.name] = settings

		-- Check if duplicate profileKey
		if NeedToKnow.profiles[key] then
			print("NeedToKnow: Duplicate profile key", key .. ". May encounter error with profile", 
				settings.name, "or", NeedToKnow.profiles[key].name
			)
			local newKey = NeedToKnow.GetNewProfileKey()
			aFixups[key] = newKey
		end

		-- Update maxKeyIndex for NeedToKnow_Globals.NextProfile
		local keyIndex = tonumber(key:sub(2))
		if keyIndex > maxKeyIndex then
			maxKeyIndex = keyIndex
		end

		self.profiles[key] = settings
	end

	-- Fix duplicate profile keys
	for oldKey, newKey in pairs(aFixups) do
		local profiles = characterSettings.Profiles
		profiles[newKey] = profiles[oldKey]
		profiles[oldKey] = nil
	end

	-- Fix any problems with NextProfile
	if not accountSettings.NextProfile or accountSettings.NextProfile <= maxKeyIndex then
		-- print("NeedToKnow ERROR (NextProfile): May encounter error with account-wide profiles on other characters.")
		accountSettings.NextProfile = maxKeyIndex + 1
	end
end

function NeedToKnow.GetNonduplicateProfileName(oldName)
	-- Return unique profile name with format "[Old name] [integer]"
	local i = 2
	local newName = oldName .. " " .. i
	while not NeedToKnow.IsProfileNameAvailable(newName) do
		i = i + 1
		newName = oldName .. " " .. i
	end
	return newName
end

function NeedToKnow.SetProfileForSpec(profileKey, specIndex)
	NeedToKnow.characterSettings.Specs[specIndex] = profileKey
end

function NeedToKnow.GetProfileForSpec(specIndex)
	local profileKey = NeedToKnow.characterSettings.Specs[specIndex]
	return profileKey
end

function NeedToKnow.GetActiveProfile()
	local profileKey = NeedToKnow.GetProfileForSpec(NeedToKnow.GetSpecIndex())
	return profileKey
end

function NeedToKnow.GetProfileByName(name)
	for profileKey, profile in pairs(NeedToKnow.profiles) do
		if profile.name == name then
			return profileKey
		end
	end
end

--function NeedToKnow.GetProfileSettings(profileKey)
--	return NeedToKnow.profiles[profileKey]
--end

function NeedToKnow.ActivateProfile(profileKey)
	local oldSettings = NeedToKnow.ProfileSettings
	local newSettings = NeedToKnow.profiles[profileKey]
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
		NeedToKnow.ProfilePanel:UpdateProfileList()  -- TO DO: Fix update function
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
	-- Load profile for current spec. Make new one if doesn't already exist. 
	local specIndex = NeedToKnow.GetSpecIndex()
	local profileKey = NeedToKnow.GetProfileForSpec(specIndex)
	if not profileKey then
		local name, realm = UnitFullName("player")
		print("NeedToKnow: Making new profile for", name .. "-" .. realm, "specialization", specIndex)
		profileKey = NeedToKnow.CreateBlankProfile()
	elseif not NeedToKnow.profiles[profileKey] then
		print("NeedToKnow: Profile", profileKey, "not found. Making new blank profile.")
		profileKey = NeedToKnow.CreateBlankProfile()
	end
	NeedToKnow.ActivateProfile(profileKey)
end


--[[ Old stuff that might be useful when upgrading to new version ]]--

--[[
-- NeedToKnow v4.0 was released quite some time ago. Time to move on. 

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
]]--




