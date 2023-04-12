-- Slash commands

local _, NeedToKnow = ...
local String = NeedToKnow.String

function NeedToKnow:AddSlashCommand()
	SlashCmdList["NEEDTOKNOW"] = NeedToKnow.SlashCommand
	SLASH_NEEDTOKNOW1 = "/needtoknow"
	SLASH_NEEDTOKNOW2 = "/ntk"
end

function NeedToKnow.SlashCommand(cmd)
	local args = {}
	for arg in cmd:gmatch("(%S+)") do
		table.insert(args, arg)
	end
	cmd = args[1]
	table.remove(args, 1)

	if not cmd then
		NeedToKnow:ToggleLockUnlock()
	elseif cmd == String.SLASH_RESET then
		-- Reset account and character to default settings
		NeedToKnow:ResetAccountSettings()
		NeedToKnow:ResetCharacterSettings()
		NeedToKnow:LoadProfiles()
		NeedToKnow:UpdateActiveProfile()
		-- TO DO: Not working properly?
	elseif cmd == String.SLASH_PROFILE then
		if args[1] then
			-- Activate profile by name
			local profileName = table.concat(args, " ")
			local profileKey = NeedToKnow:GetProfileByName(profileName)
			if profileKey then
				NeedToKnow:ActivateProfile(profileKey)
			else
				print("NeedToKnow: Unknown profile", profileName)
			end
		else
			-- Print profile key
			local profileKey = NeedToKnow:GetActiveProfile()
			print("NeedToKnow: Current profile is", profileKey)
		end
	else
		print("NeedToKnow: Unknown command", cmd)
	end    
end

