-- For bar behavior that changes when fighting bosses (Blink)

local _, NeedToKnow = ...
local ExecutiveFrame = NeedToKnow.ExecutiveFrame
local Bar = NeedToKnow.Bar

function Bar:RegisterBossFight()
	ExecutiveFrame.BossFightBars[self] = true  -- old:  = 1
	ExecutiveFrame:UpdateBossFightEvents()
end

function Bar:UnregisterBossFight()
	ExecutiveFrame.BossFightBars[self] = nil
	ExecutiveFrame:UpdateBossFightEvents()
end

function ExecutiveFrame:UpdateBossFightEvents()
	if next(self.BossFightBars) ~= nil then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function ExecutiveFrame:GetBossFight()
	-- Called by ExecutiveFrame:PLAYER_REGEN_DISABLED()
	NeedToKnow.isBossFight = nil
	if UnitExists("boss1") then
		NeedToKnow.isBossFight = true
	elseif UnitLevel("target") == -1 then
		NeedToKnow.isBossFight = true
	elseif IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			if UnitLevel("raid"..i.."target") == -1 then
				NeedToKnow.isBossFight = true
				break
			end
		end
	elseif IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do 
			if UnitLevel("party"..i.."target") == -1 then
				NeedToKnow.isBossFight = true
				break
			end
		end
	end
	if not NeedToKnow.isBossFight then
		-- Keep checking in case boss shows up later or was face-pulled
		self:RegisterEvent("UNIT_TARGET")
	end
	self:UpdateBossFightBars()
end

function ExecutiveFrame:UpdateBossFight(unit)
	-- Called by ExecutiveFrame:UNIT_TARGET()
	if UnitLevel(unit.."target") == -1 then
		NeedToKnow.isBossFight = true
		self:UnregisterEvent("UNIT_TARGET")
		self:UpdateBossFightBars()
	end
end

function ExecutiveFrame:ClearBossFight()
	-- Called by ExecutiveFrame:PLAYER_REGEN_ENABLED()
	NeedToKnow.isBossFight = nil
	self:UnregisterEvent("UNIT_TARGET")
	self:UpdateBossFightBars()
end

function ExecutiveFrame:UpdateBossFightBars()
	for bar, _ in pairs(self.BossFightBars) do
		bar:UpdateTracking()
	end
end

