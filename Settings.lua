-- Handle saved variables, default settings, settings for bars and bar groups

local _, NeedToKnow = ...
local DefaultSettings = NeedToKnow.DefaultSettings

--[[
Profiles are complete sets of NeedToKnow settings for one specialization
NeedToKnow_Globals: Saved variable. Has account-wide profiles. 
NeedToKnow_CharSettings: Saved variable per character. Has character-specific profiles. 
NeedToKnow.accountSettings: Reference to saved variable with account-wide profiles
NeedToKnow.characterSettings: Reference to saved variable with character-specific profiles
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
	else
		self:ResetCharacterSettings()
	end
end

function NeedToKnow:ResetAccountSettings()
	NeedToKnow_Globals = CopyTable(DefaultSettings.account)
	self.accountSettings = NeedToKnow_Globals
end

function NeedToKnow:ResetCharacterSettings()
	NeedToKnow_CharSettings = CopyTable(DefaultSettings.character)
	self.characterSettings = NeedToKnow_CharSettings
end

function NeedToKnow:GetBarGroupSettings(groupID)
	return self.profileSettings.Groups[groupID]
end

function NeedToKnow:GetGroupSettings(groupID)
	-- Deprecated. Use GetBarGroupSetting() instead. 
	return self.profileSettings.Groups[groupID]
end

function NeedToKnow:GetBarSettings(groupID, barID)
	local groupSettings = self:GetBarGroupSettings(groupID)
	return groupSettings.Bars[barID]
end

function NeedToKnow:CompressProfileSettings(profileSettings)
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
	NeedToKnow:RemoveDefaultSettings(profileSettings, DefaultSettings.profile)
end

function NeedToKnow:UncompressProfileSettings(profileSettings)
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

	self:AddDefaultSettings(profileSettings, DefaultSettings.profile)
	profileSettings.bUncompressed = true

	-- Deprecated legacy code from unfinished feature to change number of bar groups
	profileSettings.nGroups = 4
	for groupID = 1, profileSettings.nGroups do
		if not profileSettings.Groups[groupID] then
			profileSettings.Groups[groupID] = CopyTable(DefaultSettings.barGroup)
			local groupSettings = profileSettings.Groups[groupID]
			groupSettings.Enabled = false
			groupSettings.Position[4] = -100 - (groupID-1) * 100
		end
	end
end

function NeedToKnow:RemoveDefaultSettings(object, default, debugString)
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
			if self:RemoveDefaultSettings(v, defaultValue, debugString .. " " .. i) then
				object[i] = nil
			end
		end
	else
		for k, v in pairs(object) do
			if self:RemoveDefaultSettings(object[k], default[k], debugString .. " " .. k) then
				object[k] = nil
			end
		end
	end

	-- Return true if object is empty table
	local fn = pairs(object)
	return fn(object) == nil
end

function NeedToKnow:AddDefaultSettings(object, default)
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
				object[i] = self.DeepCopy(defaultValue)
			else
				self:AddDefaultSettings(object[i], defaultValue)
			end
		end
	else
		for key, value in pairs(default) do
			if object[key] == nil then
				if type(value) == "table" then
					object[key] = self.DeepCopy(value)
				else
					object[key] = value
				end
			else
				self:AddDefaultSettings(object[key], value)
			end
		end
	end
end

function NeedToKnow.DeepCopy(object)
	-- Called by NeedToKnow:AddDefaultSettings()
	if type(object) ~= "table" then
		return object
	else
		local newTable = {}
		for k, v in pairs(object) do
			newTable[k] = NeedToKnow.DeepCopy(v)
		end
		return newTable
	end
end

function NeedToKnow.RestoreTableFromCopy(dest, source)
	-- Called by OptionsPanel:Cancel()
	for key, value in pairs(source) do
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
	for key, value in pairs(dest) do
		if source[key] == nil then
			dest[key] = nil
		end
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


--[[ Default settings ]]--

DefaultSettings.bar = {
	Enabled = true,
	AuraName = "",
	Unit = "player",
	BuffOrDebuff = "HELPFUL",
	OnlyMine = true,
	BarColor = {r = 0.6, g = 0.6, b = 0.6, a = 1},
	MissingBlink = {r = 1, g = 0, b = 0, a = 1},
	TimeFormat = "Fmt_SingleUnit",
	vct_enabled = false,
	vct_color = {r = 0, g = 0, b = 0, a = 0.4},
	vct_spell = "",
	vct_extra = 0,
	bDetectExtends = false,
	show_text = true,
	show_count = true,
	show_time = true,
	show_spark = true,
	show_icon = false,
	show_all_stacks = false,
	show_charges = true,
	show_text_user = "",
	blink_enabled = false,
	blink_ooc = true,
	blink_boss = false,
	blink_label = "",
	buffcd_duration = 45,  -- Proc internal cooldown (seconds)
	buffcd_reset_spells = "",  -- Buffs that reset proc cooldown
	usable_duration = 0,
	append_cd = false,
	append_usable = false,
}
DefaultSettings.barGroup = {
	Enabled = true,
	NumberBars = 3,
	Position = {"TOPLEFT", "TOPLEFT", 100, -100},
	Scale = 1,
	Width = 270,
	direction = "down", 
	condenseGroup = false, 
	FixedDuration = 0, 
	Bars = {DefaultSettings.bar, DefaultSettings.bar, DefaultSettings.bar},
}
DefaultSettings.profile = {
	name = "",
	nGroups = 4,
	Groups = {DefaultSettings.barGroup},
	BarTexture = "BantoBar",
	BkgdColor = {0, 0, 0, 0.8},
	BorderColor = {0, 0, 0, 1}, 
	BarSpacing = 2,
	BarPadding = 2,  -- Border size
	BarFont = "Fritz Quadrata TT",
	FontOutline = 0,
	FontSize = 12,
	FontColor = {1, 1, 1, 1}, 
}
DefaultSettings.character = {
	Specs = {},  -- Table of active profiles for each spec {[specIndex] = profileKey}
	Locked = false,
	Profiles = {},  -- Character-specific profiles {[profileKey] = profileSettings}
}
DefaultSettings.account = {
	Version = NeedToKnow.version,
	OldVersion = NeedToKnow.version,
	Profiles = {},  -- Account-wide profiles {[profileKey] = profileSettings}
	NextProfile = 1, 
	-- Chars = {},
}

function DefaultSettings:LocalizeDefaultFont()
	local gameFont = GameFontHighlight:GetFont()
	local gameFontName
	local fontList = NeedToKnow.LSM:List("font")
	for _, fontName in ipairs(fontList) do
		local font = NeedToKnow.LSM:Fetch("font", fontName)
		if font == gameFont then
			gameFontName = fontName
			break
		end
	end
	self.profile.BarFont = gameFontName or "Fritz Quadrata TT"
end

do
	DefaultSettings:LocalizeDefaultFont()
end


--[[ Upgrade settings ]]--

-- Old code from Kitjan that might be useful later
--[[
function NeedToKnowLoader.MigrateCharacterSettings()
	-- Import settings from NeedToKnow versions prior to v4.0.0
	-- NeedToKnow v4.0 was released quite some time ago. Time to move on. 

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
	local profileKey = NeedToKnow:CreateProfile(specSettings)
	NeedToKnow:SetProfileForSpec(profileKey, specID)
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




