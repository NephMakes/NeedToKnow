local addonName, NephilistNameplates = ...
local UnitFrame = NephilistNameplates.UnitFrame;

local function ShouldShowBuff(name, caster, nameplateShowPersonal, nameplateShowAll, duration, onlyShowOwnBuffs)
	if ( not name ) then
		return false;
	end
	if ( onlyShowOwnBuffs ) then
		return nameplateShowPersonal and (caster == "player" or caster == "pet" or caster == "vehicle");
	else
		return nameplateShowAll or (
			nameplateShowPersonal and (caster == "player" or caster == "pet" or caster == "vehicle")
		);
	end
end

function UnitFrame:UpdateBuffs()

	local buffFrame = self.BuffFrame;
	if ( self.showBuffs ) then
		buffFrame:Show();
	else
		buffFrame:Hide();
		return;
	end

	local unit = self.displayedUnit;
	local filter;

	buffFrame:ClearAllPoints();
	if ( UnitIsUnit("player", unit) ) then
		buffFrame:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 5);
		-- filter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY";
		filter = "HELPFUL";
	else
		buffFrame:SetPoint("TOPLEFT", self.healthBar, "BOTTOMLEFT", 0, -5);
		local reaction = UnitReaction("player", unit);
		if ( reaction and reaction <= 4 ) then
			-- Reaction 4 is neutral and less than 4 becomes increasingly more hostile
			-- filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY";
			filter = "HARMFUL";
		else
			filter = "NONE";
		end
	end

	-- For buff tooltips:
	buffFrame.unit = unit;
	buffFrame.filter = filter;

	if ( filter == "NONE" ) then
		for i, buff in ipairs(buffFrame.buffList) do
			buff:Hide();
		end
	else
		local _, name, texture, count, duration, expirationTime, caster, nameplateShowPersonal, nameplateShowAll, buff;
		local buffIndex = 1;

		for i = 1, BUFF_MAX_DISPLAY do
			name, texture, count, _, duration, expirationTime, caster, _, nameplateShowPersonal, _, _, _, _, nameplateShowAll = UnitAura(unit, i, filter);

			if ( ShouldShowBuff(name, caster, nameplateShowPersonal, nameplateShowAll, duration, self.onlyShowOwnBuffs) ) then
				if ( not buffFrame.buffList[buffIndex] ) then
					buffFrame.buffList[buffIndex] = CreateFrame("Frame", buffFrame:GetParent():GetName() .. "Buff" .. buffIndex, buffFrame, "NephilistNameplates_BuffButtonTemplate");
					buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
				end
				buff = buffFrame.buffList[buffIndex];
				buff:SetID(i);
				buff.name = name;
				buff.layoutIndex = i;

				buff.Icon:SetTexture(texture);
				-- buff.Icon:SetVertexColor(0.8, 0.8, 0.8);
				if ( count > 1 ) then
					buff.CountFrame.Count:SetText(count);
					buff.CountFrame.Count:Show();
				else
					buff.CountFrame.Count:Hide();
				end

				--[[
				if ( UnitIsUnit("player", unit) ) then
					buff.Border:SetVertexColor(0, 0.3, 0);
					buff.Cooldown:SetSwipeColor(0, 0.8, 0);
				else
					buff.Border:SetVertexColor(0.3, 0, 0);
					buff.Cooldown:SetSwipeColor(0.8, 0, 0);
				end
				]]--
				CooldownFrame_Set(buff.Cooldown, expirationTime - duration, duration, duration > 0, true);

				buff:Show();
				buffIndex = buffIndex + 1;
--[[
			else
				if ( buffFrame.buffList[i] ) then
					buffFrame.buffList[i]:Hide();
				end
]]--
			end
		end
		for i = buffIndex, BUFF_MAX_DISPLAY do
			if (buffFrame.buffList[i]) then
				buffFrame.buffList[i]:Hide();
			end
		end
	end
	buffFrame:Layout(); -- via Blizz HorizontalLayoutFrame
end






