
--------------------
NeedToKnow
by Kitjan
--------------------


NeedToKnow allows you to monitor specific buffs and debuffs of your choosing as timer bars that always appear in a consistent place on your screen in a consistent color.  It's especially useful for monitoring frequently used short-duration buffs and debuffs.  For example, a rogue could configure NeedToKnow to show timer bars for Slice and Dice, Rupture, and their own stack of Deadly Poison VII.  A death knight could use it to track their own diseases on a mob.  NeedToKnow also works with procs and on-use trinkets.  The number, size, position, and appearance of timer bars are all customizable.  


------------
Instructions
------------

General options are available in the Blizzard interface options menu.  You can type "/needtoknow" or "/ntk" to lock/unlock the addon.  To configure individual bars, right click them while unlocked.  Bars work while locked.  (The bars should be unlocked the first time you log in with NTK.)

When entering your settings, be careful with your spelling and capitalization.  Also remember that buffs and debuffs sometimes have different names than the items and abilities that apply them.  The Death Knight ability Icy Touch, for example, applies a DoT called Frost Fever.   


----------
Change log
----------
4.0.03
 - Added "Last Raid Recipient" as a target for buff bars.  Great for spells like Beacon of Light, Lifebloom, Earth Shield, etc.
 - Improved the system used for "Detect Extends".  Hopefully this will fix the occasional occurrance of wildly incorrect extends.  This also improves performance of those bars a little.

4.0.02
 - Fixed: Cancelling out of the interface options could cause values set to false to reset to true the next time the profile was loaded
 - Tweaked "boss only" blink bars so that if the target is friendly, NTK will track if anyone in the raid is in combat with a boss
 - Improved the look of the per-bar configuration menu, getting rid of radio button backgrounds 
 - Improved the usability of the equipment slot feature, changing the buff/debuff name into a submenu when equipment slot is chosen
 - New feature: Import/Export bar settings. This allows settings to be copy and pasted between bars, or shared between users, or with me as tech support. This replaces the old "clear settings" menu option. To clear the settings now, just blank out the import/export string.

4.0.01
 - Fixed: Characters which had never used NTK before could only use the first bar group (Ticket 116)

4.0.00
 -Major update to support profiles
 - Greatly improved the UI for selecting fonts and bar textures
 - New bar type: Equipment slot
 - Increased the maximum bars per group 
 - Reduced the minimum bar scale to 25%, allowing for very thin bars
 - Updated toc for 4.3

3.2.08
- Fixed: blink didn't work with weapon imbues

3.2.06
- Updated combat log hander for 4.1 (targettarget bars). Also tried to make it a little more efficient
- fixed: "sum stacks from all casters" only worked for buffs
- Fixed problem with cooldowns sometimes not working after spec switch

3.2.05
- Added some sanity checks around weapon imbues. Should prevent the lua errors, though the corresponding bars won't work. It'll complain (a lot) in your chat window.
- Listening to ACTIVE_TALENT_GROUP_CHANGED as well as PLAYER_TALENT_UPDATE
- Listening to SPELL_UPDATE_COOLDOWN as well as ACTIONBAR_UPDATE_COOLDOWN
- Fixed: The code that was supposed to stop cooldown bars from disappearing was actually preventing it from detecting cooldown resets sometimes. 

3.2.04
- Fixed refactoring bug in auto shot bars causing a lua error

3.2.03
- Trying again to get bar initialization to happen reliably

3.2.02
- Fixed: Cooldown bars initialized too soon, resulting in failure to find the item/spell

3.2.01
- Fixed: "Usable" bars caused massive lua errors and didn't work

3.2.0
- internal cooldown bars can now be told to reset to 0 based on the presence of another buff. (for example, eclipse resets Nature's Grace)
- Fairly massive restructuring to split up the monolithic Bar_AuraCheck function (Ticket 56)
- Fixed berserk tracking on multiple weapons. This never worked before, it turns out. (Ticket 84)
- Some changes for perf improvements
- Spell cooldown bars try a bit harder to figure out what you meant to watch. Before, Swipe would end up watching cat Swipe (same name as bear Swipe), which has no cooldown. Explosive Trap works now, too. (Ticket 85)
- A bar watching your pet will update when your pet changes
- Min scale reduced from 0.6 to 0.25

3.1.9
- Fix Lua error tracking certain DK spell cooldowns

3.1.8
- Fixes cooldown tracking in 4.0.1

3.1.7
- Maybe works with Cataclysm now?
- More robust rune vs spell cd detection for DKs (Ticket 72)
- Added support to the text override for a list of names, corresponding to the list of spells to watch for (Ticket 43)

3.1.6
- Can now turn off the display of stack count (Ticket 52)
- Can now override the name that is displayed (Ticket 43)

3.1.5
- Spell cooldowns for spells like Stealth will now start when the spell ends, instead of looping when the spell is cast
- The logic to hide a cooldown that was just the GCD has been improved. Spell cooldown timers will no longer disappear when they become GCD limited (if there was 1s left and you begin a 1.2s GCD, the bar would disappear before.) This logic has then been extended to cover DK rune cooldowns (if you had a spell which required runes, but the runes had a longer cooldown than the spell had remaining, the bar would display the cooldown for the runes.)

3.1.4
- Cyrillic fixes from kolod on curseforge (ticket 74)
- Groups can only be sized such that the bars are an integer number of pixels tall. Hopefully this will improve ticket 70
- Fixed non-deterministic texture ordering on the bars, which could put the visual cast time under the bar. (Ticket 73)

3.1.3
- Fixed a LUA error caused by 3.3.5 edit box changes when entering the name of the spell to watch

3.1.2
- Added zhCN & zhTW localization. Thanks, wowui.cn! 
- Change tooltip anchor to above group
- Added new options panel: Appearance. Moved texture, font, bar spacing, bar padding, and background color options to it
- Changed lock/unlock button to config mode / play mode buttons
- Fixed a LUA error if the addon was loaded with totems out
- Replaced use of StatusBar widget with custom Texture management both because our bars have two textures and because Blizzard can't set their texture coordinates correctly any more. Fixes ticket 51
- Fixed a bug with the double-bar feature when resizing the group. This was done automatically for the main texture before, but not for the second. Now it's done for both, yay.
- Small memory optimization
- The second texture gets image and color updated the same time the primary one does, meaning it will update without a /reload
- Updating the bar appearance was being shortcut if the bar was currently blinking, so had to set the color twice. 

3.1.1
- Fixed: Auto Shot CD reset on every spell cast, not just Auto Shot

3.1.0
- Fixed: All the numeric dialogs in the config menus were using the same help text.
- New option for buffs/debuffs: Show all stacks. Can be used to watch a category of spells (like HoTs), or to watch procs from Berserker
- Auto Shot now works as a spell cooldown
- Fixed bar texturing tiling instead of stretching in 3.3.3 
- Fixed "infinite" duration buffs not correctly displaying 
- Add new bar type: Usable. Designed with Victory Rush in mind.

3.0.3
- Watching the offhand enchant would display the name of the mainhand enchant, which could cause a lua error if there was no mainhand enchant
- Reverted a partial import/export feature that snuck in

3.0.2
- Fixed a bug with blink. It defaults to 0.5 alpha and disabled, by the legacy loading code saw the 0.5 and figured it should enable blink. Worked great if you still had old settings, but starting from scratch was a bit of disaster. Sorry new users!

3.0.1
- Fixed a bug with the "Unit" setting from a buff or debuff bar causing other bar types (like spell cooldown) 
- Removed the display of charges from buff cooldown bars. Easy enough to put back if people miss it, but it surprised me.
- Fixed a small pef bug: every bar was doing one extra loop checking for the presence of the buff ""
- If the internal buff cooldown was shorter than the duration of the buff, the bar wouldn't disappear (and the spark would go negative)

3.0.0
- Created a "Settings" submenu whose contents depends on the BuffOrDebuff variable. This should allow for more bar types without confusing the menu too much.
- Added new bar type: "internal cooldown" for proc cooldown timers
- Added new bar type: "spell cooldown" for tracking spell and item cooldown timers
- Fixed: Temporary weapon enchants now use a substring search. "Poison" will pick up all rogue poisons. This also fixed a lua error that could occur when watching weapon buffs
- Added: Can show an asterisk when the bar is tracking a spell cast by the player 
- Improved: Added a blink enable besides just setting the alpha to 0. The alpha thing confused too many people
- Added more blink options: only in combat, only if boss, and a label for blinking bars

2.8.6
- Improved: Blinking bars try to be a little smarter about when to blink and when to just be hidden. Especially the case of debuff bars blinking when no target.
- Improved: Weapon imbue names now capture (I hope) the full name from the tooltip to compare against. The name to watch for (in the NTK config) is then regarded as a substring search. So you could configure NTK to watch for Poison to catch all poisons.

2.8.5
- Added: Option to show a spell icon to the left of active bars
- Added: Option to change the font used on NeedToKnow bars (in the interface options dialog)

2.8.4
- Added: Option to show certain bar elements: aura name, time remaining, and the "spark" (ticket 8)
- Added: Option to blink the bar when it would otherwise be missing (ticket 7)
- Fixed: Weapon imbue bars disappear on teleport (ticket 9)
- Fixed: Spark incorrectly visible on weapon imbues (ticket 6)

2.8.3
- Fixed some problems upgrading from older versions of NeedToKnow (ticket 5)

2.8.2
- Beta Support for temporary weapon enchants. Only tested with elemental and restoration shaman (not enhancement or rogues.)

2.8.1
- Fixed: Watching totem by spellid did not work
- Fixed: Logging in when the character was in the second spec would use the first spec's setting

2.8.0
- Added the ability to track increases in spell duration, especially useful for dps druids
- Marked as being a 3.3 addon
- Fixed: Took advantage of a new 3.3 API to get the spell id of active buffs and debuffs.  Bars that check spellid should be much more reliable and, for example, be able to tell the difference between the two different Death's Verdict procs
- Fixed: Totem timing is much more accurate
- Fixed: Visual cast times now updates based on changes in haste and other casting-time-affecting abilities

2.7.1
- Fixed: Accidentally removed the background color picker

2.7.0
- Added options for how the time text is formatted. The current style is the default, with mm:ss and ss.t as other options
- Added "visual cast time" overlay which can be used to tell when there's less than some critical amount of time left on an aura
- Hid the spark when the aura lasts longer than the bar (either an infinite duration, or using the Max duration feature.)
- Hid the time text when the aura has an infinite duration

2.6.0
- Added support for a new "Buff or Debuff" type: Totem. Type in the name of the totem to watch for (can be a partial string.)
- Fixed a parse error in the DE localization
- Slightly improved performance of "target of target"
- Added two new /ntk options: show and hide. They can be used to temporarily show and hide the ntk groups.

2.5.2
-Changed event parsing to try to be more robust (see autobot's errors)

2.5.1
-Trying a different strategy for identifying "only cast by me" spells
-When editing the watched auras, the edit field starts with the current value
-Configuring by SpellID is automatically detected and does not need a menu item checked

2.5
-Fixed ToT issue
-Added support for SpellID

2.4.3
-Added SharedMedia support, uses LibSharedMedia-3.0
-Greatly improved performance

2.4.2
-Fixed a bug with the multiple buffs per line
-Fixed a small bug with resize button showing
-Optimized performance slightly

2.4.1 

-Fixed character restriction on buff names, no accepts up to 255 characters.
-Added Russian localization

2.4

-Brought up to 3.2 API standards
-Added multiple buffs/debuffs per bar
-Dual-Specialization support

Version 2.2
-  Added option to show bars with a fixed maximum duration
-  Fixed an issue with targetoftarget
-  Added koKR localization.  Thanks, metalchoir! 
-  Added deDE localization.  Thanks, sp00n & Fxfighter! 

Version 2.1
-  Updated for WoW 3.1 
-  Can now track spells cast by player's pet or vehicle
-  Can now track buffs/debuffs on player's vehicle
-  Added options for background color, bar spacing, bar padding, bar opacity
-  Fixed a problem with buff charges not showing as consumed

Version 2.0.1
-  Updated for WoW 3.0
-  Can now track (de)buffs applied by others
-  Added option to only show buffs/debuffs if applied by self

Version 2.0
-  Added support for monitoring debuffs
-  Added support for variable numbers of bars
-  Added support for separate groups of bars
-  Added support for monitoring buffs/debuffs on target, focus, pet, or target of target
-  Bars are now click-through while locked
-  Reminder icons have been been greatly expanded in functionality and split off into their own addon: TellMeWhen
-  Cleaner bar graphics
-  Users of older versions will need to re-enter settings 

Version 1.2
-  Updated for WoW 2.4 API changes

Version 1.1.1
-  Icons should now work properly with item cooldowns.
-  Reset button should now work properly when you first use the AddOn.

Version 1.1
-  Icons will now show when reactive abilities (Riposte, Execute, etc.) are available.  
-  Added options for bar color and texture.  
-  Added graphical user interface.  Most slash commands gone.  
-  Added localization support.  Translations would be much appreciated.  
-  Users of older version will need to re-enter settings.  

Version 1.0
-  Hello world!

