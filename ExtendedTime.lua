--[[
	ExtendedTime: Option for bar text to show time added to existing 
	aura/cooldown/etc. Example: "Moonfire +3s"

	Use example: Balance Druid in Cataclysm Classic with Glyph of Starfire. 
	Starfire increases duration of Moonfire on target up to a max of 9 sec. 

	[NephMakes]: This appears to be an incredibly niche feature that Kitjan 
	added solely for his Boomkin in original Wrath/Cataclysm. And I think the 
	original use case (tabbing through mobs and increasing Moonfire to max on 
	each) was eventually patched out. Worth moving to "Advanced options". 
	
	[NephMakes]: Kitjan's version of this remembered extendedTime by GUID. 
	Seems very niche for the necessary memory system. And we don't really want 
	to support tracking on non-unitID targets. 
]]--

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

-- Local versions of frequently-used global functions
local UnitGUID = UnitGUID

function Bar:UpdateExtendedTime(trackedInfo)
	-- Called by Bar:OnTrackedPresent

	if not trackedInfo then
		-- Shouldn't happen but future-proofs if called elsewhere
		self:ClearExtendedTime()
		return
	end

	local expirationTime = trackedInfo.expirationTime
	if (expirationTime == 0) or (trackedInfo.duration == 0) then 
		-- Indefinite effect or inactive cooldown
		self:ClearExtendedTime()
		return
	end

	local unitGUID = UnitGUID(self.unit)
	local name = trackedInfo.name
	local oldUnitGUID = self.extendedUnitGUID
	local oldName = self.extendedName
	local oldExpirationTime = self.extendedOldExpirationTime

	if (not oldUnitGUID) or (oldUnitGUID ~= unitGUID) or
		(not oldExpirationTime) or
		((not self.showAllStacks) and (name ~= oldName))
	then
		-- New unit or tracked thing expired or new thing being tracked
		self:ResetExtendedTime(unitGUID, name, expirationTime)
		return
	end
	-- If showAllStacks we don't care about which it is, only that it's 
	-- one of them. And if we have trackedInfo then it is. 

	local extendedTime
	if expirationTime > oldExpirationTime + 1 then
		-- Time extended by more than one second
		extendedTime = expirationTime - oldExpirationTime
	end
	if extendedTime then
		self.extendedTime = extendedTime
	-- else keep old extendedTime if it exists
	end
end

function Bar:ResetExtendedTime(unitGUID, name, expirationTime)
	self.extendedUnitGUID = unitGUID
	self.extendedName = name
	self.extendedOldExpirationTime = expirationTime
	self.extendedTime = nil
end

function Bar:ClearExtendedTime()
	-- Called by Bar:OnTrackedAbsent, Bar:Inactivate, Bar:UpdateExtendedTime
	self.extendedUnitGUID = nil
	self.extendedName = nil
	self.extendedOldExpirationTime = nil
	self.extendedTime = nil
end



