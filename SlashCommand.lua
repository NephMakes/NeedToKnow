-- Slash commands

-- local addonName, addonTable = ...
local String = NeedToKnow.String

function NeedToKnow.AddSlashCommand()
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
		NeedToKnow.ToggleLockUnlock()
	elseif cmd == String.SLASH_RESET then
		-- Reset character settings and global saved variables (NeedToKnow_Globals)
		NeedToKnow.Reset(true)
	elseif cmd == String.SLASH_PROFILE then
		if args[1] then
			local profileName = table.concat(args, " ")
			local profileKey = NeedToKnow.FindProfileByName(profileName)
			if profileKey then
				NeedToKnow.ChangeProfile(profileKey)
				-- NeedToKnowOptions.UIPanel_Profile_Update()
			else
				print("NeedToKnow: Unknown profile", profileName)
			end
		else
			local specIndex = NeedToKnow.GetSpecIndex()
			local profileKey = NeedToKnow.CharSettings.Specs[specIndex]
			print("NeedToKnow: Current profile is", profileKey)
		end
	else
		print("NeedToKnow: Unknown command", cmd)
	end    
end

