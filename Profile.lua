-- Profiles are complete sets of NeedToKnow settings for one specialization

local _, NeedToKnow = ...
local DefaultSettings = NeedToKnow.DefaultSettings

--[[
NeedToKnow.accountSettings: Reference to saved variable with account-wide profiles
NeedToKnow.characterSettings: Reference to saved variable with character-specific profiles
NeedToKnow.profiles: All profiles available to character {[profileKey] = settings}
NeedToKnow.characterSettings.Specs: Active profiles for each spec {[specIndex] = profileKey}
NeedToKnow.profileSettings: Reference to settings for current active profile
]]--


function NeedToKnow:GetProfileSettings()
	-- Deprecated. Use NeedToKnow.profileSettings insead. 
	return self.profileSettings
end

function NeedToKnow:CreateBlankProfile()
	-- Make new profile with default settings and return its key
	local profileKey = self:CreateProfile(CopyTable(DefaultSettings.profile))
	return profileKey
end

function NeedToKnow:CreateProfile(settings)
	-- Make new profile with given settings and return its key
	local profileKey = self:GetNewProfileKey()
	settings.name = self:GetNewProfileName()
	self.profiles[profileKey] = settings
	self:SetProfileToCharacter(profileKey)  -- Character-specific by default
	return profileKey
end

function NeedToKnow:GetNewProfileKey()
	-- Return unique profile key with format "G[integer]"
	local settings = self.accountSettings
	local n = settings.NextProfile or 1
	while self.profiles["G"..n] do
		n = n + 1
	end
	if not settings.NextProfile or settings.NextProfile <= n then
		settings.NextProfile = n + 1
	end
	return "G"..n
end

function NeedToKnow:GetNewProfileName()
	-- Return unique profile name with format "[Character]-[Server] [integer]"
	local i = 1
	local name = UnitName("player") .. "-" .. GetRealmName()
	while not self:IsProfileNameAvailable(name) do
		i = i + 1
		name = name .. " " .. i
	end
	return name
end

function NeedToKnow:IsProfileNameAvailable(name)
	-- Return true if valid name not used by another profile, else return false
	if not name or name == "" then
		return false
	end
	for _, profile in pairs(self.profiles) do
		if profile.name == name then
			return false
		end
	end
	return true
end

function NeedToKnow:CopyProfile(profileKey)
	-- Make new profile with same settings and return its key
	local profile = CopyTable(self.profiles[profileKey])
	local name = self:GetProfileCopyName(profile.name)
	profileKey = self:CreateProfile(profile)
	self:RenameProfile(profileKey, name)
	return profileKey
end

function NeedToKnow:GetProfileCopyName(oldName)
	-- Return unique profile name with format "[Old name] copy [integer]"
	local newName = oldName .. " copy"
	local i = 1
	while not self:IsProfileNameAvailable(newName) do
		i = i + 1
		newName = oldName .. " copy " .. i
	end
	return newName
end

function NeedToKnow:RenameProfile(profileKey, newName)
	if self:IsProfileNameAvailable(newName) then
		self.profiles[profileKey].name = newName
	else
		print("NeedToKnow: Profile name", newName, "already in use")
	end
end

function NeedToKnow:SetProfileToAccount(profileKey)
	-- Make profile usable by all characters on this account
	local profile = self.profiles[profileKey]
	self.accountSettings.Profiles[profileKey] = profile
	self.characterSettings.Profiles[profileKey] = nil
end

function NeedToKnow:SetProfileToCharacter(profileKey)
	-- Make profile only usable by this character
	local profile = self.profiles[profileKey]
	self.accountSettings.Profiles[profileKey] = nil
	self.characterSettings.Profiles[profileKey] = profile
end

--function NeedToKnow:IsProfileToAccount(profileKey)
--	if self.accountSettings.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end

--function NeedToKnow:IsProfileToCharacter(profileKey)
--	if self.characterSettings.Profiles[profileKey] then
--		return true
--	else
--		return false
--	end
--end

function NeedToKnow:DeleteProfile(profileKey)
	if profileKey == self:GetActiveProfile() then
		print("NeedToKnow: Can't delete active profile")
	else
		self.profiles[profileKey] = nil
		self.accountSettings.Profiles[profileKey] = nil
		self.characterSettings.Profiles[profileKey] = nil
	end
end

function NeedToKnow:LoadProfiles()
	self.profiles = {}  -- All profiles available to character {[profileKey] = settings}
	local accountSettings = self.accountSettings
	local characterSettings = self.characterSettings

	-- Populate NeedToKnow.profiles from saved variables
	local maxKeyIndex = 0  -- To update accountSettings.NextProfile
	local profilesByName = {}  -- To fix duplicate profile names
	local aFixups = {}  -- To fix duplicate profile keys
	for key, settings in pairs(accountSettings.Profiles) do
		if settings.bUncompressed then
			NeedToKnow:CompressProfileSettings(settings)
		end

		-- Fix duplicate profile name
		if profilesByName[settings.name] then
			local newName = NeedToKnow:GetNonduplicateProfileName(oldName)
			print("NeedToKnow: Duplicate profile name", settings.name .. ".", "Renaming", newName)
			settings.name = newName
		end
		profilesByName[settings.name] = settings

		-- Update maxKeyIndex for NextProfile
		local keyIndex = tonumber(key:sub(2))
		if keyIndex > maxKeyIndex then 
			maxKeyIndex = keyIndex
		end

		self.profiles[key] = settings
	end
	for key, settings in pairs(characterSettings.Profiles) do
		-- Fix duplicate profile name
		if profilesByName[settings.name] then
			local newName = NeedToKnow:GetNonduplicateProfileName(oldName)
			print("NeedToKnow: Duplicate profile name", settings.name .. ".", "Renaming", newName)
			settings.name = newName
		end
		profilesByName[settings.name] = settings

		-- Check if duplicate profileKey
		if NeedToKnow.profiles[key] then
			print("NeedToKnow: Duplicate profile key", key .. ". May encounter error with profile", 
				settings.name, "or", NeedToKnow.profiles[key].name
			)
			local newKey = NeedToKnow:GetNewProfileKey()
			aFixups[key] = newKey
		end

		-- Update maxKeyIndex for NextProfile
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

function NeedToKnow:GetNonduplicateProfileName(oldName)
	-- Return unique profile name with format "[Old name] [integer]"
	local i = 2
	local newName = oldName .. " " .. i
	while not self:IsProfileNameAvailable(newName) do
		i = i + 1
		newName = oldName .. " " .. i
	end
	return newName
end

function NeedToKnow:SetProfileForSpec(profileKey, specIndex)
	self.characterSettings.Specs[specIndex] = profileKey
end

function NeedToKnow:GetProfileForSpec(specIndex)
	local profileKey = self.characterSettings.Specs[specIndex]
	return profileKey
end

function NeedToKnow:GetActiveProfile()
	local profileKey = self:GetProfileForSpec(self.GetSpecIndex())
	return profileKey
end

function NeedToKnow:GetProfileByName(name)
	for profileKey, profile in pairs(self.profiles) do
		if profile.name == name then
			return profileKey
		end
	end
end

function NeedToKnow:ActivateProfile(profileKey)
	local oldSettings = self.profileSettings
	local newSettings = self.profiles[profileKey]
	if newSettings and newSettings ~= oldSettings then
		if oldSettings and oldSettings.bUncompressed then
			self:CompressProfileSettings(oldSettings)
		end
		self:UncompressProfileSettings(newSettings)
		self.profileSettings = newSettings
		self.ProfileSettings = self.profileSettings  -- Deprecated
		self:SetProfileForSpec(profileKey, self.GetSpecIndex())
		self:Update()
		self.OptionsPanel:Update()
		self.AppearancePanel:Update()
		self.ProfilePanel:UpdateProfileList()  -- TO DO: Fix update function
	end
end

function NeedToKnow:UpdateActiveProfile()
	-- Load profile for current spec. Make new one if doesn't already exist. 
	local specIndex = self.GetSpecIndex()
	local profileKey = self:GetProfileForSpec(specIndex)
	if not profileKey then
		local name, realm = UnitFullName("player")
		print("NeedToKnow: Making new profile for", name.."-"..realm, "specialization", specIndex)
		profileKey = self:CreateBlankProfile()
	elseif not NeedToKnow.profiles[profileKey] then
	-- elseif NeedToKnow.profiles and not NeedToKnow.profiles[profileKey] then
		print("NeedToKnow: Profile", profileKey, "not found. Making new blank profile.")
		profileKey = self:CreateBlankProfile()
	end
	self:ActivateProfile(profileKey)
end




