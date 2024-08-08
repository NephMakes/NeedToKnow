﻿-- Load early in .toc

local _, NeedToKnow = ...
local Localize = {}

Localize.enUS = {
	-- Bar tooltips
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "Right click bars to set up. More options in Blizzard interface options menu. Type /needtoknow or /ntk to lock and enable.",
	RESIZE_TOOLTIP = "Click and drag to change size",

	-- Bar right-click menu
	ENABLE = ENABLE,  -- "Enable" 
	ENABLE_BAR = "Enable bar",
	COLOR = COLOR,  -- "Color"
	BAR_COLOR = "Bar color",
	CHOOSE_SPELL_ITEM_ABILITY = "Choose spell, item, or ability", 
	BARTYPE = "Bar type",
	BARTYPE_HELPFUL = "Buff",
	BARTYPE_HARMFUL = "Debuff",
	BARTYPE_CASTCD = "Spell or item cooldown",
	-- BARTYPE_EQUIPSLOT = "Equipped item cooldown",
	BARTYPE_EQUIPSLOT = "Item slot cooldown",
	BARTYPE_USABLE = "Reactive spell or ability", 
	BARTYPE_BUFFCD = "Buff internal cooldown",
	BARTYPE_TOTEM = "Totem",
	SETTINGS = SETTINGS, -- "Settings"
	OPTIONS = "Options", 
	MORE_OPTIONS = "More options", 
	BUFF_SETTINGS = "Buff settings", 
	DEBUFF_SETTINGS = "Debuff settings", 
	COOLDOWN_SETTINGS = "Cooldown settings", 
	USABLE_SETTINGS = "Reactive settings", 
	TOTEM_SETTINGS = "Totem settings", 
	IMPORT_EXPORT_SETTINGS = "Import or export settings",
	CLEAR_SETTINGS = "Clear settings",
	CHOOSE_UNIT = "Unit to watch",
	UNIT_PLAYER = PLAYER,  -- "Player"
	UNIT_TARGET = TARGET,  -- "Target"
	UNIT_FOCUS = FOCUS,  -- "Focus"
	UNIT_PET = PET,  -- "Pet"
	UNIT_VEHICLE = "Vehicle",
	UNIT_TARGETTARGET = "Target of target",
	UNIT_LAST_RAID = "Last raid recipient",
	ONLY_MINE = "Only show mine",
	SUM_ALL_CASTERS = "Sum from all casters",
	SUM_ALL_ENTRIES = "Show sum of all entries",
	SHOW_CHARGE_COOLDOWN = "Show first and last charge cooldown",
	BUFFCD_RESET = "Set reset buffs",
	SET_USABLE_DURATION = "Set usable time",
	SET_BUFFCD_DURATION = "Set cooldown time",
	SHOW = SHOW,  -- "Show"
	SHOW_NAME = NAME,  -- "Name"
	SHOW_ICON = "Icon",
	SHOW_COUNT = "Count",
	SHOW_TIME = "Time",
	SHOW_SPARK = "Spark",
	TIME_FORMAT = "Time format", 
	TIME_SINGLE_UNIT = "Single unit (12 s)",
	TIME_MIN_SEC = "Minutes and seconds (01:12)",
	TIME_DECIMAL = "Decimal seconds (12.1)",
	TEXT_OPTIONS = "Text options", 
	-- SHOW_MYPIP = "Show * if mine",
	SHOW_TIME_ADDED = "Show time added",
	SHOW_TTN1 = "Show 1st tooltip number",
	SHOW_TTN2 = "Show 2nd tooltip number",
	SHOW_TTN3 = "Show 3rd tooltip number",
	CUSTOM_BAR_TEXT = "Custom bar text",
	REPLACE_BAR_TEXT = "Replace bar text",
	-- ADD_BAR_TEXT = "Add bar text",
	APPEND_CD = "Append \"CD\"", 
	APPEND_USABLE = "Append \"usable\"", 
	CAST_TIME = "Cast timer",
	CAST_TIME_ENABLE = "Show cast time overlay", 
	CAST_TIME_CHOOSE_SPELL = "Choose other spell",
	CAST_TIME_ADD_TIME = "Add extra time",
	BLINK_SETTINGS = "Blink options", 
	BLINK_ENABLE = "Blink when missing", 
	BLINK_COLOR = "Color when blinking", 
	BLINK_TEXT = "Replace text when blinking", 
	BLINK_OUT_OF_COMBAT = "Blink out of combat", 
	BLINK_ONLY_BOSS = "Blink only for boss fights", 

	-- Input dialog boxes
	DIALOG_HELPFUL = "Enter buff name", 
	DIALOG_HARMFUL = "Enter debuff name", 
	DIALOG_CASTCD = "Enter spell, item, or ability name", 
	DIALOG_USABLE = "Enter spell or ability name", 
	DIALOG_BUFFCD = "Enter buff name", 
	DIALOG_TOTEM = "Enter totem name", 
	DIALOG_USABLE_TIME = "Enter time in seconds\nreactive spell or ability is usable", 
	DIALOG_BUFFCD_TIME = "Enter time in seconds\nfor proc internal cooldown", 
	DIALOG_BUFFCD_SPELL = "Enter spell or ability name", 
	DIALOG_CAST_TIME_SPELL = "Enter spell or ability name", 
	DIALOG_CAST_TIME_ADD = "Enter time in seconds\nto add to cast time", 
	DIALOG_BLINK_TEXT = "Enter text to replace\nspell, item, and ability names", 
	DIALOG_REPLACE_TEXT = "Enter text to replace\nspell, item, and ability names", 
	DIALOG_IMPORT_EXPORT = "Copy or paste bar settings here", 
	DIALOG_SUBTEXT_HELPFUL = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_HARMFUL = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_CASTCD = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_USABLE = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_BUFFCD = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_TOTEM = "To track more than one, enter names in order of priority separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_USABLE_TIME = "", 
	DIALOG_SUBTEXT_BUFFCD_TIME = "For most procs the internal cooldown is 45 seconds", 
	DIALOG_SUBTEXT_BUFFCD_SPELL = "These buffs reset the proc's internal cooldown, too. For more than one, enter names separated by commas. Spell IDs accepted.", 
	DIALOG_SUBTEXT_CAST_TIME_SPELL = "Leave blank to show cast time for spell with buff or debuff name", 
	DIALOG_SUBTEXT_CAST_TIME_ADD = "Leave blank to add no time", 
	DIALOG_SUBTEXT_BLINK_TEXT = "Clear text to stop replacing", 
	DIALOG_SUBTEXT_REPLACE_TEXT = "To individually replace names, enter text in order separated by commas. Clear text to stop replacing", 
	DIALOG_SUBTEXT_IMPORT_EXPORT = "Clear text to clear settings", 

	-- BarGroup tab
	NEEDTOKNOW_GROUP = "NeedToKnow group", 
	GROUP_OPTIONS = "Group options", 
	LOCK_AND_ACTIVATE = "Lock and activate bars", 

	-- Options panel
	OPTIONS_PANEL_SUBTEXT = "These options let you modify NeedToKnow timer bars", 
	BAR_GROUPS = "Bar groups", 
	BAR_GROUP = "Bar group", 
	GROUP = "Group", 
	ENABLE_GROUP_TOOLTIP = "Show and enable this bar group", 
	NUMBER_BARS = "Number of bars", 
	GROUP_DIRECTION = "Group direction", 
	GROUP_GROWS_UP = "Group grows up", 
	GROUP_GROWS_DOWN = "Group grows down", 
	CONDENSE_GROUP = "Condense group", 
	MOVE_BARS = "Move bars to fill gaps", 
	MAX_BAR_TIME = "Max bar time", 
	MAX_BAR_TIME_TOOLTIP = "Set time in seconds when full so bars move at same speed. Leave blank for no fixed time.", 
	EDIT_MODE = "Edit mode", 
	EDIT_MODE_TOOLTIP = "Unlock bars to set what they time", 
	PLAY_MODE = "Play mode", 
	PLAY_MODE_TOOLTIP = "Lock and activate bars", 

	-- Appearance panel
	APPEARANCE = "Appearance", 
	BAR_APPEARANCE = "Bar appearance", 
	BAR_TEXTURE = "Bar texture", 
	BORDER_COLOR = "Border color", 
	BACKGROUND_COLOR = "Background color", 
	BORDER_SIZE = "Border size", 
	BAR_SPACING = "Bar spacing", 
	FONT = "Font", 
	FONT_OUTLINE = "Font outline", 
	FONT_OUTLINE_NONE = "None", 
	FONT_OUTLINE_THIN = "Thin", 
	FONT_OUTLINE_THICK = "Thick", 
	FONT_SIZE = "Font size", 
	FONT_COLOR = "Font color", 

	-- Profile panel
	PROFILE = "Profile", 
	PROFILE_PANEL_SUBTEXT = "These options let you manage NeedToKnow profiles. Profiles are complete NeedToKnow setups for one specialization.", 
	PROFILES = "Profiles", 
	PROFILE_NAME = "Name", 
	PROFILE_TYPE = "Type", 
	USABLE_BY = "Usable by", 
	ACCOUNT = "Account", 
	CHARACTER = "Character", 
	ACTIVATE = "Activate", 
	ACTIVATE_TOOLTIP = "Activate profile for current specialization", 
	RENAME = "Rename", 
	RENAME_TOOLTIP = "Change profile name", 
	RENAME_PROFILE_DIALOG = "Enter profile name",  
	-- NEW_PROFILE_NAME = "New profile name", 
	COPY = "Copy", 
	COPY_TOOLTIP = "Make new profile from copy", 
	DELETE = "Delete", 
	DELETE_TOOLTIP = "Permanently delete profile", 
	DELETE_PROFILE_DIALOG = "Are you sure you want to delete this profile?\n\n%s", 
	TO_ACCOUNT = "To Account", 
	TO_ACCOUNT_TOOLTIP = "Make profile usable by all characters on this account", 
	TO_CHARACTER = "To Character", 
	TO_CHARACTER_TOOLTIP = "Make profile only usable by this character", 

	-- Slash commands
	SLASH_RESET = "reset", 
	SLASH_PROFILE = "profile", 
}

Localize.deDE = {
	-- Credits: sp00n, Fxfighter EU-Echsenkessel
	BAR_TOOLTIP1 = "NeedToKnow", 
	BAR_TOOLTIP2 = "Rechtsklick auf einen Balken für Einstellungen. Mehr Optionen sind im Blizzard Interface vorhanden. Zum Festsetzen und Aktivieren /needtoknow oder /ntk eingeben.",
	RESIZE_TOOLTIP = "Klicken und ziehen, um die Größe zu ändern",
	ENABLE_BAR = "Leiste aktivieren",
	CHOOSE_SPELL_ITEM_ABILITY = "Buff/Debuff auswählen",
	CHOOSE_UNIT = "Betroffene Einheit",
	UNIT_PLAYER = PLAYER,  -- "Spieler",
	UNIT_TARGET = TARGET,  -- "Ziel",
	UNIT_FOCUS = FOCUS,  -- "Fokus",
	UNIT_PET = PET,  -- "Begleiter (Pet)",
	UNIT_VEHICLE = "Vehicle",
	UNIT_TARGETTARGET = "Ziel des Ziels",
	BARTYPE = "Buff oder Debuff?",
	BARTYPE_HELPFUL = "Buff",
	BARTYPE_HARMFUL = "Debuff",
	ONLY_MINE = "Nur Anzeigen wenn es selbst gezaubert wurde",
	BAR_COLOR = "Farbe des Balken",
	CLEAR_SETTINGS = "Einstellungen löschen",
	DIALOG_HELPFUL = "Name des Buffs/Debuffs für diesen Balken angeben", 
	DIALOG_HARMFUL = "Name des Buffs/Debuffs für diesen Balken angeben", 
	OPTIONS_PANEL_SUBTEXT = "Diese Einstellungen ändern die Anzahl und die Gruppierung der Balken", 
	BAR_GROUP = "Gruppe", 
	ENABLE_GROUP_TOOLTIP = "Diese Gruppierung aktivieren und anzeigen", 
	NUMBER_BARS = "Anzahl der Balken", 
	BAR_TEXTURE = "Balkentextur", 
}
setmetatable(Localize.deDE, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.koKR = {
	-- Credits: metalchoir
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "우?�릭: 메뉴 불러오기\n세부옵션? �기본 ?�터페?�스 설정?�서 가능\n/ntk 명령어로 잠근 후? �애드온 사용가능",
	RESIZE_TOOLTIP = "드래그: ?�기 변경",
	ENABLE_BAR = "바 사용",
	CHOOSE_SPELL_ITEM_ABILITY = "입력: 주문 ?�름",
	BARTYPE = "�선?: �버프/디버프",
	-- BARMENU_SPELLID = "사용 주문 ID",
	BARTYPE_HELPFUL = "버프",
	BARTYPE_HARMFUL = "디버프",
	CHOOSE_UNIT = "유닛 선?",
	UNIT_PLAYER = PLAYER,  -- "�본?",
	UNIT_TARGET = TARGET,  -- "�대?",
	UNIT_FOCUS = FOCUS,  -- "�주시대?",
	UNIT_PET = PET,  -- "�펫",
	UNIT_VEHICLE = "탈것",
	UNIT_TARGETTARGET = "대?�? �대?",
	ONLY_MINE = "?�신? �시전한 것만 보여줌",
	BAR_COLOR = "바 색?",
	CLEAR_SETTINGS = "�설정 초기화",
	DIALOG_HELPFUL = "바? �표시할 버프 ?�는 디버프? �?�름? �입력하세요", 
	DIALOG_HARMFUL = "바? �표시할 버프 ?�는 디버프? �?�름? �입력하세요", 
	BAR_GROUP = "그룹", 
	ENABLE_GROUP_TOOLTIP = "? �그룹? �바를 표시/사용합니다", 
	NUMBER_BARS = "바 갯수", 
	EDIT_MODE = "풀림", 
	PLAY_MODE = "�잠금", 
	BAR_TEXTURE = "바 ?�스처", 
	BACKGROUND_COLOR = "배경 색?", 
	BORDER_SIZE = "배경 ?�기", 
	BAR_SPACING = "바 간격", 
	SLASH_RESET = "초기화", 
 }
setmetatable(Localize.koKR, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.ruRU = {
	-- Credits: Vlakarados
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "Клик правой кнопкой мыши по полосе для настройки. Больше настроек в Интерфейс / Модификации / NeedToKnow меню. Ввести /needtoknow или /ntk для блокировки и включения.",
	RESIZE_TOOLTIP = "Кликнуть и тащить для изменения размера",
	ENABLE_BAR = "Включить полосу",
	CHOOSE_SPELL_ITEM_ABILITY = "Выбрать бафф/дебафф для слежения",
	BARTYPE = "Бафф или дебафф?",
	-- BARMENU_SPELLID = "Используйте удостоверение личности произношения по буквам",
	BARTYPE_HELPFUL = "Бафф",
	BARTYPE_HARMFUL = "Дебафф",
	CHOOSE_UNIT = "Юнит слежения",
	UNIT_PLAYER = PLAYER,  -- "Игрок",
	UNIT_TARGET = TARGET,  -- "Цель",
	UNIT_FOCUS = FOCUS,  -- "Фокус",
	UNIT_PET = PET,  -- "Питомец",
	UNIT_VEHICLE = "Средство передвижения",
	UNIT_TARGETTARGET = "Цель цели",
	ONLY_MINE = "Показывать только наложенные мной",
	BAR_COLOR = "Цвет полосы",
	CLEAR_SETTINGS = "Очистить настройки",
	DIALOG_HELPFUL = "Введите название баффа/дебаффа для слежения", 
	DIALOG_HARMFUL = "Введите название баффа/дебаффа для слежения", 
	BAR_GROUP = "Группа", 
	ENABLE_GROUP_TOOLTIP = "Показать и включить эту группу полос", 
	NUMBER_BARS = "Количество полос", 
	MAX_BAR_TIME = "Максимальное время на полосе", 
	MAX_BAR_TIME_TOOLTIP = "Указать максимальное время пробега полосы в секундах. Оставить пустым для динамического времени для каждой полойы (полное время = длительность баффа/дебаффа).", 
	EDIT_MODE = "Разблокировать", 
	PLAY_MODE = "Заблокировать", 
	BAR_TEXTURE = "Текcтура полоc", 
	BACKGROUND_COLOR = "Цвет фона", 
	BORDER_SIZE = "Уплотнение полоc", 
	BAR_SPACING = "Промежуток полоc", 
	SLASH_RESET = "Сброс", 
}
setmetatable(Localize.ruRU, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.zhCN = {
	-- Credits: wowui.cn
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "右键点击计时条配置. 更多的选项在暴雪界面选项菜单里. 输入 /needtoknow 来锁定并启用.",
	RESIZE_TOOLTIP = "点击和拖动来修改计时条尺寸",
	ENABLE_BAR = "启用计时条",
	CHOOSE_SPELL_ITEM_ABILITY = "选择需要计时的Buff/Debuff",
	BARTYPE = "Buff还是Debuff?",
	BARTYPE_HELPFUL = "Buff",
	BARTYPE_HARMFUL = "Debuff",
	CHOOSE_UNIT = "需要监视的单位",
	UNIT_PLAYER = PLAYER,  -- "玩家",
	UNIT_TARGET = TARGET,  -- "目标",
	UNIT_FOCUS = FOCUS,  -- "焦点",
	UNIT_PET = PET,  -- "宠物",
	UNIT_VEHICLE = "载具",
	UNIT_TARGETTARGET = "目标的目标",
	ONLY_MINE = "仅显示自身施放的",
	BAR_COLOR = "计时条颜色",
	CLEAR_SETTINGS = "清除设置",
	DIALOG_HELPFUL = "输入在这个计时条内计时的Buff或Debuff的精确名字", 
	DIALOG_HARMFUL = "输入在这个计时条内计时的Buff或Debuff的精确名字", 
	BAR_GROUP = "分组", 
	ENABLE_GROUP_TOOLTIP = "显示并启用这个分组的计时条", 
	NUMBER_BARS = "计时条数量", 
	MAX_BAR_TIME = "计时条最大持续时间", 
	MAX_BAR_TIME_TOOLTIP = "设置这个分组计时条的最大长度 (按秒数).  留空为每个计时条设置不同的数值.", 
	EDIT_MODE = "解锁", 
	PLAY_MODE = "锁定", 
	BAR_TEXTURE = "计时条材质", 
	BACKGROUND_COLOR = "背景颜色", 
	BORDER_SIZE = "计时条间距", 
	BAR_SPACING = "计时条空距",
	SLASH_RESET = "重置", 
}
setmetatable(Localize.zhCN, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.zhTW = {
	-- Credits: wowui.cn
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "右鍵點擊計時條配置. 更多的選項在暴雪介面選項菜單裏. 輸入 /needtoknow 來鎖定並啟用.",
	RESIZE_TOOLTIP = "點擊和拖動來修改計時條尺寸",
	ENABLE_BAR = "啟用計時條",
	CHOOSE_SPELL_ITEM_ABILITY = "選擇需要計時的Buff/Debuff",
	BARTYPE = "Buff還是Debuff?",
	BARTYPE_HELPFUL = "Buff",
	BARTYPE_HARMFUL = "Debuff",
	CHOOSE_UNIT = "需要監視的單位",
	UNIT_PLAYER = PLAYER,  -- "玩家",
	UNIT_TARGET = TARGET,  -- "目標",
	UNIT_FOCUS = FOCUS,  -- "焦點",
	UNIT_PET = PET,  -- "寵物",
	UNIT_VEHICLE = "載具",
	UNIT_TARGETTARGET = "目標的目標",
	ONLY_MINE = "僅顯示自身施放的",
	BAR_COLOR = "計時條顏色",
	CLEAR_SETTINGS = "清除設置",
	DIALOG_HELPFUL = "輸入在這個計時條內計時的Buff或Debuff的精確名字", 
	DIALOG_HARMFUL = "輸入在這個計時條內計時的Buff或Debuff的精確名字", 
	BAR_GROUP = "分組", 
	ENABLE_GROUP_TOOLTIP = "顯示並啟用這個分組的計時條", 
	NUMBER_BARS = "計時條數量", 
	MAX_BAR_TIME = "計時條最大持續時間", 
	MAX_BAR_TIME_TOOLTIP = "設置這個分組計時條的最大長度 (按秒數).  留空為每個計時條設置不同的數值.", 
	EDIT_MODE = "解鎖", 
	PLAY_MODE = "鎖定", 
	BAR_TEXTURE = "計時條材質", 
	BACKGROUND_COLOR = "背景顏色", 
	BORDER_SIZE = "計時條間距", 
	BAR_SPACING = "計時條空距",
	SLASH_RESET = "重置", 
}
setmetatable(Localize.zhTW, {__index = Localize.enUS})  -- Take missing strings from enUS

-- Localization["esMX"] = {} 
-- Localization["esES"] = {} 
-- Localization["frFR"] = {} 

do
	NeedToKnow.String = Localize[GetLocale()] or Localize["enUS"]
	-- NeedToKnow.String = Localize["zhTW"]  -- For testing
end

NeedToKnow.String.ITEM_NAMES = {
	-- Also used in BarMenu.lua
	-- Seems like this should already exist somewhere
	HEADSLOT,
	NECKSLOT,
	SHOULDERSLOT,
	SHIRTSLOT,
	CHESTSLOT,
	WAISTSLOT,
	LEGSSLOT,
	FEETSLOT,
	WRISTSLOT,
	HANDSSLOT,
	FINGER0SLOT_UNIQUE,
	FINGER1SLOT_UNIQUE,
	TRINKET0SLOT_UNIQUE,
	TRINKET1SLOT_UNIQUE,
	BACKSLOT,
	MAINHANDSLOT,
	SECONDARYHANDSLOT,
	RANGEDSLOT.."/"..RELICSLOT,
	TABARDSLOT
}
