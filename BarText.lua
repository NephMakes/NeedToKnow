-- Bar text

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

-- local versions of frequently-used global functions
local SecondsToTimeAbbrev = SecondsToTimeAbbrev


function Bar:UpdateReplacementText()
	-- Called by Bar:UpdateSpells()
	self.spell_names = {}
	for shownName in self.settings.show_text_user:gmatch("([^,]+)") do
		shownName = strtrim(shownName)
		table.insert(self.spell_names, shownName)
	end
end

function Bar:UpdateBarText(barSettings, count, extended)
	-- Called by Bar:CheckAura() if duration found

	local settings = barSettings or self.settings
	local text = ""

	local name = ""
	if settings.show_text then
		name = self.buffName
		if settings.show_text_user ~= "" then
			local idx = self.idxName
			if idx > #self.spell_names then 
				idx = #self.spell_names
			end
			name = self.spell_names[idx]
		end
	end

	if not settings.show_count then
		count = 1
	end

	local to_append = self:ComputeText(name, count, extended)
	if to_append and to_append ~= "" then
		text = text .. to_append
	end

	if ( settings.append_cd 
		and (settings.BuffOrDebuff == "CASTCD" 
		or settings.BuffOrDebuff == "BUFFCD"
		or settings.BuffOrDebuff == "EQUIPSLOT" ) ) 
	then
		text = text .. " CD"
	elseif settings.append_usable and settings.BuffOrDebuff == "USABLE" then
		text = text .. " Usable"
	end

	self.text:SetText(text)
end

function Bar:ComputeText(buffName, count, extended)
	-- Called by Bar:UpdateBarText()
	local text = buffName
	if count > 1 then
		text = buffName.."  ["..count.."]"
	end
	if extended and extended > 1 then
		text = text..string.format(" + %.0fs", extended)
	end
	return text
end

function Bar:SetUnlockedText(barSettings)
	-- Called by Bar:Unlock()
	local settings = barSettings or self.settings
	local text = ""
	if settings.show_text then
		if settings.show_text_user ~= "" then
			text = settings.show_text_user
		else
			text = text .. NeedToKnow:GetPrettyName(settings)
		end
		if ( settings.append_cd and (
			settings.BuffOrDebuff == "CASTCD"
			or settings.BuffOrDebuff == "BUFFCD"
			or settings.BuffOrDebuff == "EQUIPSLOT" 
			) 
		) 
		then
			text = text .. " CD"
		elseif settings.append_usable and settings.BuffOrDebuff == "USABLE" then
			text = text .. " Usable"
		end
		if settings.bDetectExtends == true then
			text = text .. " + 3s"
		end
	end
	self.Text:SetText(text)
end

function Bar:FormatTimeSingle(duration)
    return string.format(SecondsToTimeAbbrev(duration))
end

function Bar:FormatTimeTwoUnits(duration)
	if duration < 6040 then
		local minutes = floor(duration / 60)
		local seconds = floor(duration - minutes * 60)
		return string.format("%02d:%02d", minutes, seconds)
	else
		return self:FormatTimeSingle(duration)
	end
end

function Bar:FormatTimeDecimal(duration)
	return string.format("%0.1f", duration)
end

