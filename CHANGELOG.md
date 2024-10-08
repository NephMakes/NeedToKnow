# Changelog

## NeedToKnow

### v4.X.X (2024-XX-XX)

### v4.7.7 (2024-08-26)
* Breaking change: Default settings should now provide cleaner experience for first-time users and new characters. Groups and bars on inactive profiles will likely need to be re-enabled. 
* Fixed: Buffs and debuffs tracked by spell ID on target/focus should now work again
* Fixed: Cooldown bars should no longer show rune cooldowns for Classic Death Knights
* Fixed: Equipped item cooldowns should now show properly when equipping an item
* Fixed: Cast timer should no longer disappear after first use
* Changed: Bars set to "Show sum of all" while tracking more than one spell/etc now show name, count, and icon for last effect to expire (was first to expire)

### v4.7.6 (2024-08-21)
* Fixed: Bars for equipment slot cooldowns can now show icon
* Fixed: Tracking buffs/debuffs on target of target should work again
* Fixed: Cast timer should work again on Retail

### v4.7.5 (2024-08-16)
* Another attempt at fixing cooldown issues in patch 11.0.2

### v4.7.4 (2024-08-15)
* Updated Table of Contents for Retail patch 11.0.2
* Fixed Lua errors with cooldowns in patch 11.0.2 (I think)
* Fixed: "Show sum of all" should now correctly sum across multiple instances of the same aura
* Fixed: "Show sum of all" should now work correctly with "Only show mine"

### v4.7.3 (2024-08-11)
* Fixed: "Show sum of all" now correctly describes bar behavior (formerly "Sum from all casters")
* Fixed: Equipped item cooldowns now show inventory slot name
* Removed: "Append CD" and "Append usable" (redundant with "Custom bar text")

### v4.7.2 (2024-07-30)
* Fixed more API bugs with Retail patch 11.0.2

### v4.7.1 (2024-07-30)
* Updated various API calls for Retail patch 11.0.2
* Updated .toc for Retail patch 11.0.2

### v4.7.0 (2024-06-04)
* Added tab to bar groups to access options and lock addon

### v4.6.6
* Fixed bug with picking colors (thanks tuxedobob!)
* Fixed profile switching in Cata classic
* Updated .toc files

### v4.6.5
* Updated .toc

### v4.6.4
* Another attempt to fix login error with profiles

### v4.6.3
* Updated for Wrath Classic patch 3.4.2
* Updated for Retail patch 10.1
* Fixed Lua error with UpdateActiveProfile (I think)
* Fixed Lua error with ITEM_NAMES

### v4.6.2
* Fixed Appearance panel drop-down menus in Classic Era 
* Back-end overhaul continues

### v4.6.1
* Fixed several bugs in Classic Era
* Revised back-end profile handling
* Updated for Retail patch 10.0.7

### v4.6.0
* Overhaul: Profiles option panel

### v4.5.1
* Fixed item cooldown (API change)

### v4.5.0
* Added options: border color, font color
* Updated for patch 10.0.5
* Updated for Wrath classic patch 3.4.1 (Ulduar)

### v4.4.2
* Fixed "profile key" error message on login and level up
* Fixed bar background always appearing black
* Appearance options now easier to set precisely
* "Replace bar text" dialog now explains how to individually replace multiple spells and abilities
* Removed "Show * if mine" option: was never actually implemented
* Removed "Show tooltip number" options: didn't necessarily show tooltip numbers
* Improved crispness and consistency of bar edges and borders

### v4.4.1
* Fixed lua error when showing Appearance options panel

### v4.4.0
* Added option: Group direction (bar group grows up / down)
* Added option: Condense bar group (move bars to fill gaps)

### v4.3.5
* Fixed bars missing text when blinking
* Fixed blink not starting/stopping when entering/leaving combat
* Bars now blink more urgently

### v4.3.4
* Bar right-click menus now better organized
* User input dialogs now more descriptive
* Fixed issue where some buffs could cause lua error (Horn of Winter, for example)
* Back-end overhaul continues

### v4.3.3
* Fixed Death Knight runes triggering cooldown bars in Classic
* Fixed cast time indicator not hiding when turned off
* Fixed appearance sliders not rounding numbers
* Back-end overhaul continues

### v4.3.2
* Cooldown bars should no longer scan tooltips. Hopefully fixes patch 10.0.2 bugs. 

### v4.3.1
* Update to hopefully fix bug with patch 10.0.2 changes to tooltip API

### v4.3.0
* Back-end overhaul continues
* BarMenu now shows that bars can track item cooldowns by name
* Removed unnecessary references to InterfaceOptionsFramePanelContainer (removed in Dragonflight)

### v4.2.0
* Monitoring target of target should now work properly
* Indefinite buffs and debuffs now colored properly
* Cast time indicators now show properly for dark colors
* Refresh rate increased to 40 fps (was 33 fps)
* Back-end overhaul continues
* Some XML fixes, but v10.0.0 not yet supported

### v4.1.2
* Another attempt at fixing retail XML errors with Backdrop in NeedToKnow_Options.xml

### v4.1.1
* Fixed Lua error with m_last_guid in BarEngine.lua
* Fixed Retail XML errors with Backdrop in NeedToKnow_Options.xml

### v4.1.0
* Added compatibility with WoW Classic (Wrath)
* Major back-end overhaul in progress
* Code now organized into smaller, logical chunks
* Now using more-consistent, object-oriented name and function schemes
* Now creating fewer global variables
* Now using XML for static layout only
* Increased bar frame rate
* Quarantined legacy code for player power and removed user-facing references
* Updated Addon description text

### v4.0.30
* Fixed moving/sizing bug caused by anchor API change

### v4.0.29
* Updated for patch 8.3

### v4.0.28
* More fixes for UNIT_SPELLCAST event changes

### v4.0.27 (beta)
* Update for WoW 8.0 Battle for Azeroth
* Supports new PlaySound() arguments
* UnitAura() no longer returns rank
* UnitAura() no longer supports query by spell name
* UNIT_SPELLCAST_SUCCEEDED no longer provides spell name and rank.
* COMBAT_LOG_EVENT_UNFILTERED no longer has event payload. Using CombatLogGetCurrentEventInfo()
* Removed reference to nonexistent NeedToKnow_GroupOptionsTemplate.xml in toc
* Removed power bar functionality (was experimental anyway)
* Thanks to jofmayer(Curse)/endymonium(Github) for code guidance

### 4.0.03
 * Added "Last Raid Recipient" as a target for buff bars.  Great for spells like Beacon of Light, Lifebloom, Earth Shield, etc.
 * Improved the system used for "Detect Extends".  Hopefully this will fix the occasional occurrance of wildly incorrect extends.  This also improves performance of those bars a little.

### 4.0.02
 * Fixed: Cancelling out of the interface options could cause values set to false to reset to true the next time the profile was loaded
 * Tweaked "boss only" blink bars so that if the target is friendly, NTK will track if anyone in the raid is in combat with a boss
 * Improved the look of the per-bar configuration menu, getting rid of radio button backgrounds 
 * Improved the usability of the equipment slot feature, changing the buff/debuff name into a submenu when equipment slot is chosen
 * New feature: Import/Export bar settings. This allows settings to be copy and pasted between bars, or shared between users, or with me as tech support. This replaces the old "clear settings" menu option. To clear the settings now, just blank out the import/export string.

### 4.0.01
 * Fixed: Characters which had never used NTK before could only use the first bar group (Ticket 116)

### 4.0.00
 * Major update to support profiles
 * Greatly improved the UI for selecting fonts and bar textures
 * New bar type: Equipment slot
 * Increased the maximum bars per group 
 * Reduced the minimum bar scale to 25%, allowing for very thin bars
 * Updated toc for 4.3

### 3.2.08
* Fixed: blink didn't work with weapon imbues

### 3.2.06
* Updated combat log hander for 4.1 (targettarget bars). Also tried to make it a little more efficient
* fixed: "sum stacks from all casters" only worked for buffs
* Fixed problem with cooldowns sometimes not working after spec switch

### 3.2.05
* Added some sanity checks around weapon imbues. Should prevent the lua errors, though the corresponding bars won't work. It'll complain (a lot) in your chat window.
* Listening to ACTIVE_TALENT_GROUP_CHANGED as well as PLAYER_TALENT_UPDATE
* Listening to SPELL_UPDATE_COOLDOWN as well as ACTIONBAR_UPDATE_COOLDOWN
* Fixed: The code that was supposed to stop cooldown bars from disappearing was actually preventing it from detecting cooldown resets sometimes. 

### 3.2.04
* Fixed refactoring bug in auto shot bars causing a lua error

### 3.2.03
* Trying again to get bar initialization to happen reliably

### 3.2.02
* Fixed: Cooldown bars initialized too soon, resulting in failure to find the item/spell

### 3.2.01
* Fixed: "Usable" bars caused massive lua errors and didn't work

### 3.2.0
* internal cooldown bars can now be told to reset to 0 based on the presence of another buff. (for example, eclipse resets Nature's Grace)
* Fairly massive restructuring to split up the monolithic Bar_AuraCheck function (Ticket 56)
* Fixed berserk tracking on multiple weapons. This never worked before, it turns out. (Ticket 84)
* Some changes for perf improvements
* Spell cooldown bars try a bit harder to figure out what you meant to watch. Before, Swipe would end up watching cat Swipe (same name as bear Swipe), which has no cooldown. Explosive Trap works now, too. (Ticket 85)
* A bar watching your pet will update when your pet changes
* Min scale reduced from 0.6 to 0.25

### 3.1.9
* Fix Lua error tracking certain DK spell cooldowns

### 3.1.8
* Fixes cooldown tracking in 4.0.1

### 3.1.7
* Maybe works with Cataclysm now?
* More robust rune vs spell cd detection for DKs (Ticket 72)
* Added support to the text override for a list of names, corresponding to the list of spells to watch for (Ticket 43)

### 3.1.6
* Can now turn off the display of stack count (Ticket 52)
* Can now override the name that is displayed (Ticket 43)

### 3.1.5
* Spell cooldowns for spells like Stealth will now start when the spell ends, instead of looping when the spell is cast
* The logic to hide a cooldown that was just the GCD has been improved. Spell cooldown timers will no longer disappear when they become GCD limited (if there was 1s left and you begin a 1.2s GCD, the bar would disappear before.) This logic has then been extended to cover DK rune cooldowns (if you had a spell which required runes, but the runes had a longer cooldown than the spell had remaining, the bar would display the cooldown for the runes.)

### 3.1.4
* Cyrillic fixes from kolod on curseforge (ticket 74)
* Groups can only be sized such that the bars are an integer number of pixels tall. Hopefully this will improve ticket 70
* Fixed non-deterministic texture ordering on the bars, which could put the visual cast time under the bar. (Ticket 73)

### 3.1.3
* Fixed a LUA error caused by 3.3.5 edit box changes when entering the name of the spell to watch

### 3.1.2
* Added zhCN & zhTW localization. Thanks, wowui.cn! 
* Change tooltip anchor to above group
* Added new options panel: Appearance. Moved texture, font, bar spacing, bar padding, and background color options to it
* Changed lock/unlock button to config mode / play mode buttons
* Fixed a LUA error if the addon was loaded with totems out
* Replaced use of StatusBar widget with custom Texture management both because our bars have two textures and because Blizzard can't set their texture coordinates correctly any more. Fixes ticket 51
* Fixed a bug with the double-bar feature when resizing the group. This was done automatically for the main texture before, but not for the second. Now it's done for both, yay.
* Small memory optimization
* The second texture gets image and color updated the same time the primary one does, meaning it will update without a /reload
* Updating the bar appearance was being shortcut if the bar was currently blinking, so had to set the color twice. 

### 3.1.1
* Fixed: Auto Shot CD reset on every spell cast, not just Auto Shot

### 3.1.0
* Fixed: All the numeric dialogs in the config menus were using the same help text.
* New option for buffs/debuffs: Show all stacks. Can be used to watch a category of spells (like HoTs), or to watch procs from Berserker
* Auto Shot now works as a spell cooldown
* Fixed bar texturing tiling instead of stretching in 3.3.3 
* Fixed "infinite" duration buffs not correctly displaying 
* Add new bar type: Usable. Designed with Victory Rush in mind.

### 3.0.3
* Watching the offhand enchant would display the name of the mainhand enchant, which could cause a lua error if there was no mainhand enchant
* Reverted a partial import/export feature that snuck in

### 3.0.2
* Fixed a bug with blink. It defaults to 0.5 alpha and disabled, by the legacy loading code saw the 0.5 and figured it should enable blink. Worked great if you still had old settings, but starting from scratch was a bit of disaster. Sorry new users!

### 3.0.1
* Fixed a bug with the "Unit" setting from a buff or debuff bar causing other bar types (like spell cooldown) 
* Removed the display of charges from buff cooldown bars. Easy enough to put back if people miss it, but it surprised me.
* Fixed a small pef bug: every bar was doing one extra loop checking for the presence of the buff ""
* If the internal buff cooldown was shorter than the duration of the buff, the bar wouldn't disappear (and the spark would go negative)

### 3.0.0
* Created a "Settings" submenu whose contents depends on the BuffOrDebuff variable. This should allow for more bar types without confusing the menu too much.
* Added new bar type: "internal cooldown" for proc cooldown timers
* Added new bar type: "spell cooldown" for tracking spell and item cooldown timers
* Fixed: Temporary weapon enchants now use a substring search. "Poison" will pick up all rogue poisons. This also fixed a lua error that could occur when watching weapon buffs
* Added: Can show an asterisk when the bar is tracking a spell cast by the player 
* Improved: Added a blink enable besides just setting the alpha to 0. The alpha thing confused too many people
* Added more blink options: only in combat, only if boss, and a label for blinking bars

### 2.8.6
* Improved: Blinking bars try to be a little smarter about when to blink and when to just be hidden. Especially the case of debuff bars blinking when no target.
* Improved: Weapon imbue names now capture (I hope) the full name from the tooltip to compare against. The name to watch for (in the NTK config) is then regarded as a substring search. So you could configure NTK to watch for Poison to catch all poisons.

### 2.8.5
* Added: Option to show a spell icon to the left of active bars
* Added: Option to change the font used on NeedToKnow bars (in the interface options dialog)

### 2.8.4
* Added: Option to show certain bar elements: aura name, time remaining, and the "spark" (ticket 8)
* Added: Option to blink the bar when it would otherwise be missing (ticket 7)
* Fixed: Weapon imbue bars disappear on teleport (ticket 9)
* Fixed: Spark incorrectly visible on weapon imbues (ticket 6)

### 2.8.3
* Fixed some problems upgrading from older versions of NeedToKnow (ticket 5)

### 2.8.2
* Beta Support for temporary weapon enchants. Only tested with elemental and restoration shaman (not enhancement or rogues.)

### 2.8.1
* Fixed: Watching totem by spellid did not work
* Fixed: Logging in when the character was in the second spec would use the first spec's setting

### 2.8.0
* Added the ability to track increases in spell duration, especially useful for dps druids
* Marked as being a 3.3 addon
* Fixed: Took advantage of a new 3.3 API to get the spell id of active buffs and debuffs.  Bars that check spellid should be much more reliable and, for example, be able to tell the difference between the two different Death's Verdict procs
* Fixed: Totem timing is much more accurate
* Fixed: Visual cast times now updates based on changes in haste and other casting-time-affecting abilities

### 2.7.1
* Fixed: Accidentally removed the background color picker

### 2.7.0
* Added options for how the time text is formatted. The current style is the default, with mm:ss and ss.t as other options
* Added "visual cast time" overlay which can be used to tell when there's less than some critical amount of time left on an aura
* Hid the spark when the aura lasts longer than the bar (either an infinite duration, or using the Max duration feature.)
* Hid the time text when the aura has an infinite duration

### 2.6.0
* Added support for a new "Buff or Debuff" type: Totem. Type in the name of the totem to watch for (can be a partial string.)
* Fixed a parse error in the DE localization
* Slightly improved performance of "target of target"
* Added two new /ntk options: show and hide. They can be used to temporarily show and hide the ntk groups.

### 2.5.2
* Changed event parsing to try to be more robust (see autobot's errors)

### 2.5.1
* Trying a different strategy for identifying "only cast by me" spells
* When editing the watched auras, the edit field starts with the current value
* Configuring by SpellID is automatically detected and does not need a menu item checked

### 2.5
* Fixed ToT issue
* Added support for SpellID

### 2.4.3
* Added SharedMedia support, uses LibSharedMedia-3.0
* Greatly improved performance

### 2.4.2
* Fixed a bug with the multiple buffs per line
* Fixed a small bug with resize button showing
* Optimized performance slightly

### 2.4.1 
* Fixed character restriction on buff names, now accepts up to 255 characters.
* Added Russian localization

### 2.4
* Brought up to 3.2 API standards
* Added multiple buffs/debuffs per bar
* Dual-Specialization support

### Version 2.2
* Added option to show bars with a fixed maximum duration
* Fixed an issue with targetoftarget
* Added koKR localization.  Thanks, metalchoir! 
* Added deDE localization.  Thanks, sp00n & Fxfighter! 

### Version 2.1
* Updated for WoW 3.1 
* Can now track spells cast by player's pet or vehicle
* Can now track buffs/debuffs on player's vehicle
* Added options for background color, bar spacing, bar padding, bar opacity
* Fixed a problem with buff charges not showing as consumed

### Version 2.0.1
* Updated for WoW 3.0
* Can now track (de)buffs applied by others
* Added option to only show buffs/debuffs if applied by self

### Version 2.0
* Added support for monitoring debuffs
* Added support for variable numbers of bars
* Added support for separate groups of bars
* Added support for monitoring buffs/debuffs on target, focus, pet, or target of target
* Bars are now click-through while locked
* Reminder icons have been been greatly expanded in functionality and split off into their own addon: TellMeWhen
* Cleaner bar graphics
* Users of older versions will need to re-enter settings 

### Version 1.2
* Updated for WoW 2.4 API changes

### Version 1.1.1
* Icons should now work properly with item cooldowns.
* Reset button should now work properly when you first use the AddOn.

### Version 1.1
* Icons will now show when reactive abilities (Riposte, Execute, etc.) are available.  
* Added options for bar color and texture.  
* Added graphical user interface.  Most slash commands gone.  
* Added localization support.  Translations would be much appreciated.  
* Users of older version will need to re-enter settings.  

### Version 1.0
* Hello world!

