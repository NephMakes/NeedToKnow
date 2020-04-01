-- Track spell, item, and proc cooldowns

local addonName, addonTable = ...

-- Kitjan's locals

local g_GetSpellInfo = GetSpellInfo
local c_AUTO_SHOT_NAME = g_GetSpellInfo(75) -- Localized name for Auto Shot

-- Defined here: 
local mfn_GetSpellCooldown = addonTable.mfn_GetSpellCooldown
local mfn_GetSpellChargesCooldown = addonTable.mfn_GetSpellChargesCooldown
local mfn_GetAutoShotCooldown = addonTable.mfn_GetAutoShotCooldown
local mfn_GetUnresolvedCooldown = addonTable.mfn_GetUnresolvedCooldown
local mfn_AuraCheck_CASTCD = addonTable.mfn_AuraCheck_CASTCD
local mfn_AuraCheck_BUFFCD = addonTable.mfn_AuraCheck_BUFFCD
local mfn_AuraCheck_EQUIPSLOT = addonTable.mfn_AuraCheck_EQUIPSLOT

-- Defined elsewhere: 
local mfn_SetStatusBarValue = addonTable.mfn_SetStatusBarValue




