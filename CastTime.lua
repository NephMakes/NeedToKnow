-- Cast timer: Shaded region on bar showing time needed to cast a specific 
-- spell before time expires. For example: for Shadow Priest to cast Vampiric 
-- Touch before its debuff expires. Or for Shaman to cast Lava Burst before 
-- Flame Shock expires. 

-- Kitjan originally called this "Visual Cast Time" (vct)

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

-- Functions different between Retail and Classic as of 11.0.0
local function GetRetailSpellInfo(spell)
	local info = C_Spell.GetSpellInfo(spell)  -- Only in Retail
	return nil, nil, nil, info.castTime
end
local GetSpellInfo = GetSpellInfo or GetRetailSpellInfo


--[[ CastTime ]]--

function Bar:UpdateCastTime()
	-- Update for current cast speed (affected by spell haste, etc)
	-- Called by Bar:OnUpdate, Bar:UpdateAppearance
	-- Called very frequently. Make it efficent. 
	local castDuration = self:GetCastTimeDuration()
	local barWidth = self:GetWidth()
	local castWidth = barWidth * castDuration / self.maxTimeLeft
		-- maxTimeLeft set by Bar:OnDurationFound, Bar:OnDurationAbsent, 
		-- Bar:Unlock.  Bar.xml sets default maxTimeLeft = 1
	if castWidth > barWidth then
		castWidth = barWidth
	end
	if castWidth < 1 then
		castWidth = 1
	end
	self.CastTime:SetWidth(castWidth)
end

function Bar:GetCastTimeDuration()
	-- Called by Bar:UpdateCastTime
	-- Called very frequently. Make it efficent. 
	local spell = self.settings.vct_spell
	if not spell or spell == "" then
		spell = self.buffName
	end
	local _, _, _, castDuration = GetSpellInfo(spell)
	if castDuration then
		castDuration = castDuration / 1000  -- Want seconds not milliseconds
		self.refreshCastTime = true
	else
		castDuration = 0
		self.refreshCastTime = false
	end
	if self.settings.vct_extra then
		-- Extra time set by user (latency, for example)
		castDuration = castDuration + self.settings.vct_extra
	end
	return castDuration
end

