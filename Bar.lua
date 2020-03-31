-- local addonName, addonTable = ...

local Bar = NeedToKnow.Bar

function Bar:OnLoad()
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEnter", Bar.OnEnter)
	self:SetScript("OnLeave", Bar.OnLeave)
	self:SetScript("OnDragStart", Bar.OnDragStart)
	self:SetScript("OnDragStop", Bar.OnDragStop)
	self:SetScript("OnSizeChanged", Bar.OnSizeChanged)
	self:SetScript("OnMouseUp", Bar.OnMouseUp)
	--	self.ShowMenu = Bar.ShowMenu

	--	self.Update = Bar.Update
	--	self.SetBackground = Bar.SetBackground

	--	self:SetScript("OnEvent", Bar.OnEvent)
	--	self.SetScripts = Bar.SetScripts
	--	self.ClearScripts = Bar.ClearScripts
	--	self.SetValue = Bar.SetValue
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
	NeedToKnow.Bar_OnSizeChanged(self)
end

function Bar:OnMouseUp(button)
	if (button == "RightButton") then
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
		NeedToKnow.BarMenu.ShowMenu(self)
	end
end

--[[

function Bar:SetAppearance()
	-- replaces NeedToKnow.ConfigureVisibleBar(bar, count, extended, buff_stacks)
end

function Bar:SetBackground()
	-- replaces NeedToKnow.SizeBackground(bar, i_show_icon)
end

function Bar:SetValue()
	-- replaces mfn_SetStatusBarValue(bar,texture,value,value0)
end

]]--

--[[
function Bar:Update()
end

function Bar:SetScripts()
end

function Bar:ClearScripts()
end

function Bar:OnEvent()
end
]]--




