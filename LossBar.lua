-- Animated bar showing health loss

local addonName, NephilistNameplates = ...
local LossBar = NephilistNameplates.LossBar

-- Local versions of global functions
local GetTime = GetTime
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs  -- Only in retail


--[[ LossBar functions ]]-- 

function LossBar:Initialize()
	self:SetAllPoints(self:GetParent().healthBar)
	self:SetDuration(0.3)  -- 0.25
	self:SetStartDelay(0.1)
	self:SetPauseDelay(0.05)
	self:SetPostponeDelay(0.05)
end

function LossBar:SetDuration(duration)
	self.duration = duration or 0
end

function LossBar:SetStartDelay(delay)
	self.startDelay = delay or 0
end

function LossBar:SetPauseDelay(delay)
	self.pauseDelay = delay or 0
end

function LossBar:SetPostponeDelay(delay)
	self.postponeDelay = delay or 0
end

function LossBar:UpdateHealth(currentHealth, previousHealth)
	-- Called by UnitFrame:UpdateHealth()

	local delta = currentHealth - previousHealth
	local hasLoss = delta < 0
	local hasBegun = self.startTime ~= nil
	local isAnimating = hasBegun and self.progress > 0

	if hasLoss and not hasBegun then
		self:StartAnimation(previousHealth)
	elseif hasLoss and hasBegun and not isAnimating then
		self:PostponeStartTime()
	elseif hasLoss and isAnimating then
		-- Reset starting value and pause briefly
		self.startHealth = self:GetLossProgress(previousHealth, self.startHealth)
		self.startTime = GetTime() + self.pauseDelay
	elseif not hasLoss and hasBegun and currentHealth >= self.startHealth then
		self:CancelAnimation()
	end
end

function LossBar:StartAnimation(startHealth)
	self.startHealth = startHealth
	self.startTime = GetTime() + self.startDelay
	self.progress = 0
	self:Show()
	self:SetValue(self.startHealth)
	self:SetScript("OnUpdate", LossBar.OnUpdate)
end

function LossBar:OnUpdate()
	self:UpdateAnimation(self:GetParent().currentHealth)
end

function LossBar:UpdateAnimation(currentHealth)
	-- Called by UnitFrame:UpdateHealth() and LossBar:OnUpdate()

	if UnitGetTotalAbsorbs then 
		local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0
		if totalAbsorb > 0 then
			self:CancelAnimation()
		end
	end

	if self.startTime then
		local lossBarHealth, progress = self:GetLossProgress(currentHealth, self.startHealth)
		self.progress = progress
		if progress >= 1 then
			self:CancelAnimation()
		else
			self:SetValue(lossBarHealth)
		end
	end
end

function LossBar:GetLossProgress(currentHealth, previousHealth)
	-- Returns lossBarHealth, time progress
	if self.startTime then
		local elapsedTime = GetTime() - self.startTime
		if elapsedTime > 0 then
			local progress = elapsedTime / self.duration
			if progress < 1 and previousHealth > currentHealth then
				local healthDelta = previousHealth - currentHealth
				local lossBarHealth = previousHealth - (progress * healthDelta)
				return lossBarHealth, progress
			end
		else
			return previousHealth, 0
		end
	end
	return 0, 1
end

function LossBar:PostponeStartTime()
	self.startTime = self.startTime + self.postponeDelay
end

function LossBar:CancelAnimation()
	self:Hide()
	self.startTime = nil
	self.progress = nil
	self:SetScript("OnUpdate", nil)
end





