--[[
	Cast timer
	
	Bar overlay shows time needed to cast a specific spell. For example: for  
	Shadow Priest to cast Vampiric Touch before its debuff expires. Or for 
	Shaman to cast Lava Burst before Flame Shock expires. 

	User can also add extra time to overlay. For latency, or for effects that 
	trigger on a certain amount of time left. 

	Kitjan originally called this "Visual Cast Time" (vct)
]]--

local _, NeedToKnow = ...
local Bar = NeedToKnow.Bar

-- Functions different between Retail and Classic as of 11.0.0
local GetSpellInfo = GetSpellInfo
local function GetRetailSpellInfo(spell)
	local info = C_Spell.GetSpellInfo(spell)  -- Only in Retail
	if info then
		return nil, nil, nil, info.castTime
	end
end
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	GetSpellInfo = GetRetailSpellInfo
end


--[[ CastTime ]]--

function Bar:SetCastTimeOptions()
	local settings = self.settings
	self.showCastTime = settings.vct_enabled
	self.castTimeColor = settings.vct_color
	local spellName = settings.vct_spell
	if spellName == "" then
		spellName = nil
	end
	self.castTimeSpell = spellName
	self.castTimeExtra = settings.vct_extra or 0
end

function Bar:UpdateCastTime()
	-- Update for current cast speed (affected by spell haste, etc)
	-- Called by Bar:OnUpdate, Bar:UpdateAppearance
	-- Very frequent. Be efficent. 
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
	-- Called by Bar:UpdateCastTime. Very frequent. Be efficent. 
	local spell = self.castTimeSpell or self.buffName
	local _, _, _, castDuration = GetSpellInfo(spell)
	if castDuration then
		castDuration = castDuration / 1000  -- Want seconds not milliseconds
		self.refreshCastTime = true
	else
		castDuration = 0
		self.refreshCastTime = nil
	end
	return castDuration + self.castTimeExtra
end

