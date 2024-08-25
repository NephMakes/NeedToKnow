-- Bar text

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar
local String = NeedToKnow.String

-- local versions of frequently-used global functions
local SecondsToTimeAbbrev = SecondsToTimeAbbrev


--[[ Text ]]--

function Bar:SetUnlockedText()
	-- Set text shown when bar is unlocked and configurable
	-- Called by Bar:Unlock(), Bar:Blink()
	local name 
	local settings = self.settings
	if self.showText then
		if settings.show_text_user ~= "" then
			-- User-specified replacement text 
			name = settings.show_text_user
		elseif self.barType == "EQUIPSLOT" or self.barType == "EQUIPBUFF" then
			name = String.GetInventorySlotName(settings.AuraName)
		else
			name = settings.AuraName
		end
	else
		name = ""
	end
	-- Placeholders for count and extendedTime would make config view messy 
	self.Text:SetText(name)
end

function Bar:SetLockedText()
	-- Set text shown when bar is locked and active
	-- Called by Bar:OnDurationFound() if duration found

	local name, countText, stackText, extendedTimeText 

	if self.showText then
		name = self.shownName or self.buffName or ""
	else
		name = ""
	end

	local count = self.count
	if self.showCount and count and count > 1 then
		countText = "  ["..count.."]"
	else
		countText = ""
	end

	local stacks = self.stacks
	if self.showAllStacks and stacks and stacks > 1 then
		stacks = stacks - 1  -- Show extra stacks
		stackText = "  +"..stacks
	else
		stackText = ""
	end

	local extendedTime = self.extendedTime
	if extendedTime and extendedTime > 1 then
		extendedTimeText = string.format(" + %.0fs", extendedTime)
	else
		extendedTimeText = ""
	end

	self.Text:SetText(name..countText..stackText..extendedTimeText)
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

