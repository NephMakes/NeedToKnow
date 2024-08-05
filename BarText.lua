-- Bar text

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar
local String = NeedToKnow.String

-- local versions of frequently-used global functions
local SecondsToTimeAbbrev = SecondsToTimeAbbrev


--[[ Text ]]--

function Bar:SetUnlockedText()
	-- Set text shown when bar is unlocked and configurable
	-- Called by Bar:Unlock()
	local name 
	local settings = self.settings
	if settings.show_text then
		if settings.show_text_user ~= "" then  -- User-specified replacement text 
			name = settings.show_text_user
		elseif self.barType == "EQUIPSLOT" then
			name = String.GetItemSlotName(settings.AuraName) or ""
		else
			name = settings.AuraName
		end
	else
		name = ""
	end
	local appendedText = self:GetAppendedText()
	-- Could show placeholders for count and extendedTime but makes config view very messy
	self.Text:SetText(name..appendedText)
end

function Bar:SetLockedText()
	-- Set text shown when bar is locked and active
	-- Called by Bar:CheckAura() if duration found

	local name, appendedText, countText, extendedTimeText 
	local settings = self.settings

	if settings.show_text then
		name = self.shownName or self.buffName or ""
	else
		name = ""
	end

	appendedText = self:GetAppendedText()

	local count = self.count
	if settings.show_count and count and count > 1 then
		countText = "  ["..count.."]"
	else
		countText = ""
	end

	local extendedTime = self.extendedTime
	if extendedTime and extendedTime > 1 then
		extendedTimeText = string.format(" + %.0fs", extendedTime)
	else
		extendedTimeText = ""
	end

	self.Text:SetText(name..appendedText..countText..extendedTimeText)
end

function Bar:GetAppendedText()
	local appendedText
	local settings = self.settings
	if settings.append_cd and
		(self.barType == "CASTCD" or self.barType == "BUFFCD" or self.barType == "EQUIPSLOT")
	then
		appendedText = " CD"
	elseif settings.append_usable and self.barType == "USABLE" then
		appendedText = " Usable"
	else
		appendedText = ""
	end
	return appendedText
end


--[[ Time ]]--

-- Time value set in Bar:OnUpdate()

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

