-- Bar appearance and interaction

-- local addonName, addonTable = ...
local Bar = NeedToKnow.Bar

function Bar:OnLoad()
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEnter",       Bar.OnEnter)
	self:SetScript("OnLeave",       Bar.OnLeave)
	self:SetScript("OnMouseUp",     Bar.OnMouseUp)
	self:SetScript("OnDragStart",   Bar.OnDragStart)
	self:SetScript("OnDragStop",    Bar.OnDragStop)
	self:SetScript("OnSizeChanged", Bar.OnSizeChanged)

	self.SetValue = Bar.SetValue
	--	self.SetAppearance = Bar.SetAppearance
	self.SetBackgroundSize = Bar.SetBackgroundSize
	--	self.Lock = Bar.Lock
	--	self.Unlock = Bar.Unlock

	-- Defined in BarEngine.lua: 
	--	self:SetScript("OnEvent", Bar.OnEvent)
	--	self.Update = Bar.Update
	--	self.SetType = Bar.SetType
	--	self.SetScripts = Bar.SetScripts
	self.ClearScripts = Bar.ClearScripts
	self.CheckCombatLogRegistration = Bar.CheckCombatLogRegistration
end

function Bar:OnEnter()
	local tooltip = _G["GameTooltip"]
	tooltip:SetOwner(self:GetParent(), "ANCHOR_TOPLEFT")
	tooltip:AddLine(NEEDTOKNOW.BAR_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	tooltip:AddLine(NEEDTOKNOW.BAR_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	tooltip:Show()
end

function Bar:OnLeave()
	_G["GameTooltip"]:Hide()
end

function Bar:OnDragStart()
	self:GetParent():StartMoving()
end

function Bar:OnDragStop()
	local group = self:GetParent()
	group:StopMovingOrSizing()
	group:SavePosition()
end

function Bar:OnSizeChanged()
	if ( self.bar1.cur_value ) then 
		self:SetValue(self.bar1, self.bar1.cur_value)
	end
	if ( self.bar2 and self.bar2.cur_value ) then 
		self:SetValue(self.bar2, self.bar2.cur_value, self.bar1.cur_value)
	end
end

function Bar:OnMouseUp(button)
	if ( button == "RightButton" ) then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu.ShowMenu(self)
	end
end

function Bar:SetValue(texture, value, value0)
	local pct0 = 0
	if ( value0 ) then
		pct0 = value0 / self.max_value
		if ( pct0 > 1 ) then 
			pct0 = 1
		end
	end

	if ( value < 0 ) then
		-- Kitjan: Happened to me when there was lag 
		-- right around the time a bar was ending
		value = 0
	end

	local pct = value / self.max_value
	texture.cur_value = value
	if ( pct > 1 ) then 
		pct = 1 
	end

	local w = (pct - pct0) * self:GetWidth()
	if ( w < 1 ) then 
		texture:Hide()
	else
		texture:SetWidth(w)
		texture:SetTexCoord(pct0,0, pct0,1, pct,0, pct,1)
		texture:Show()
	end
end

--[[
function Bar:SetAppearance()
end
]]--

function Bar:SetBackgroundSize(showIcon)
	local background = self.Background
	local barPadding = NeedToKnow.ProfileSettings["BarPadding"]

	local bgWidth = self:GetWidth() + 2*barPadding
	if ( showIcon ) then
		bgWidth = bgWidth + self:GetHeight() + barPadding
	end

	background:ClearAllPoints()
	background:SetPoint("RIGHT", barPadding, 0)
	background:SetWidth(bgWidth)
end

--[[
function Bar:Lock()
	-- Set bar for gameplay
end

function Bar:Unlock()
	-- Set bar for user config
end
]]--


