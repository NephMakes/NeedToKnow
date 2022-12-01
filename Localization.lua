-- Must be loaded early in .toc

-- local addonName, addonTable = ...

NeedToKnow.String = {}
local Localize = {}

Localize.enUS = {
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "Right click bars to set up. More options in Blizzard interface options menu. Type /needtoknow to lock and enable.",
	RESIZE_TOOLTIP = "Click and drag to change size",

	-- BarMenu

	CHOOSE_SPELL_ITEM_ABILITY = "Choose spell, item, or ability", 
	BAR_COLOR = "Bar color",
	COLOR = COLOR,  -- "Color"
	ENABLE = ENABLE,  -- "Enable" 
	ENABLE_BAR = "Enable bar",

	BARTYPE = "Bar type",
	BARTYPE_HELPFUL = "Buff",
	BARTYPE_HARMFUL = "Debuff",
	BARTYPE_CASTCD = "Spell or item cooldown",
	BARTYPE_EQUIPSLOT = "Equipped item cooldown",
	BARTYPE_USABLE = "Reactive spell or ability",
	BARTYPE_BUFFCD = "Proc internal cooldown",
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
	SHOW_CHARGE_COOLDOWN = "Show first and last charge cooldown",
	BUFFCD_RESET = "Reset on buff...",  -- Needs review
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
	TIME_MIN_SEC = "Minutes and seconds (01:10)",
	TIME_DECIMAL = "Decimal seconds (12.1)",

	TEXT_OPTIONS = "Text options", 
	SHOW_MYPIP = "Show * if mine",
	SHOW_TIME_ADDED = "Show time added",
	SHOW_TTN1 = "Show 1st tooltip number",
	SHOW_TTN2 = "Show 2nd tooltip number",
	SHOW_TTN3 = "Show 3rd tooltip number",
	REPLACE_BAR_TEXT = "Replace bar text",
	ADD_BAR_TEXT = "Add bar text",
	APPEND_CD = "Append \"CD\"",  -- Deprecated
	APPEND_USABLE = "Append \"usable\"",  -- Deprecated

	CAST_TIME = "Cast timer",
	CAST_TIME_ENABLE = "Show cast time overlay", 
	CAST_TIME_CHOOSE_SPELL = "Choose spell",
	CAST_TIME_ADD_TIME = "Add extra time",

	BLINK_SETTINGS = "Blink options", 
	BLINK_ENABLE = "Blink when missing", 
	BLINK_COLOR = "Color when blinking", 
	BLINK_TEXT = "Replace text when blinking", 
	BLINK_OUT_OF_COMBAT = "Blink out of combat", 
	BLINK_ONLY_BOSS = "Blink only for bosses", 

	-- Dialog
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

}

Localize.deDE = {
	-- by sp00n and Fxfighter EU-Echsenkessel
	BAR_TOOLTIP1 = "NeedToKnow", 
	BAR_TOOLTIP2 = "Rechtsklick auf einen Balken für Einstellungen. Mehr Optionen sind im Blizzard Interface vorhanden. Zum Festsetzen und Aktivieren /needtoknow oder /ntk eingeben.",
	RESIZE_TOOLTIP = "Klicken und ziehen, um die Größe zu ändern",
	BARMENU_ENABLE = "Leiste aktivieren",
	BARMENU_CHOOSENAME = "Buff/Debuff auswählen",
	CHOOSENAME_DIALOG = "Name des Buffs/Debuffs für diesen Balken angeben", 
	BARMENU_CHOOSEUNIT = "Betroffene Einheit",
	BARMENU_PLAYER = "Spieler",
	BARMENU_TARGET = "Ziel",
	BARMENU_FOCUS = "Fokus",
	BARMENU_PET = "Begleiter (Pet)",
	BARMENU_VEHICLE = "Vehicle",
	BARMENU_TARGETTARGET = "Ziel des Ziels",
	BARMENU_BUFFORDEBUFF = "Buff oder Debuff?",
	BARMENU_HELPFUL = "Buff",
	BARMENU_HARMFUL = "Debuff",
	BARMENU_ONLYMINE = "Nur Anzeigen wenn es selbst gezaubert wurde",
	BARMENU_BARCOLOR = "Farbe des Balken",
	BARMENU_CLEARSETTINGS = "Einstellungen löschen",
	UIPANEL_SUBTEXT1 = "Diese Einstellungen ändern die Anzahl und die Gruppierung der Balken.",
	UIPANEL_SUBTEXT2 = "Die Darstellung funktioniert auch bei festgesetzen Balken. Wenn sie freigesetzt sind, können die Gruppierungen verschoben und deren Größe verändert werden. Ein Rechtsklick auf einen Balken zeigt weitere Einstellungsmöglichkeiten an. '/needtoknow' oder '/ntk' kann ebenfalls zum Festsetzen und Freistellen verwendet werden.",
	UIPANEL_BARGROUP = "Gruppe ",
	UIPANEL_NUMBERBARS = "Anzahl der Balken",
	UIPANEL_FIXEDDURATION = "Max bar duration",
	UIPANEL_BARTEXTURE = "Balkentextur",
	UIPANEL_BACKGROUNDCOLOR = "Background color",
	UIPANEL_BARSPACING = "Bar spacing",
	UIPANEL_BARPADDING = "Bar padding",
	UIPANEL_LOCK = "AddOn sperren",
	UIPANEL_UNLOCK = "AddOn entsperren",
	UIPANEL_TOOLTIP_ENABLEGROUP = "Diese Gruppierung aktivieren und anzeigen",
	UIPANEL_TOOLTIP_FIXEDDURATION = "Set the maximum length of bars for this group (in seconds).  Leave empty to set dynamically per bar.",
	UIPANEL_TOOLTIP_BARTEXTURE = "Die Textur für die Balken auswählen",
	CMD_RESET = "reset"
}
setmetatable(Localize.deDE, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.koKR = {
	-- by metalchoir
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "우?�릭: 메뉴 불러오기\n세부옵션? �기본 ?�터페?�스 설정?�서 가능\n/ntk 명령어로 잠근 후? �애드온 사용가능",
	RESIZE_TOOLTIP = "드래그: ?�기 변경",
	BARMENU_ENABLE = "바 사용",
	BARMENU_CHOOSENAME = "입력: 주문 ?�름",
	CHOOSENAME_DIALOG = "바? �표시할 버프 ?�는 디버프? �?�름? �입력하세요", 
	BARMENU_CHOOSEUNIT = "유닛 선?",
	BARMENU_PLAYER = "�본?",
	BARMENU_TARGET = "�대?",
	BARMENU_FOCUS = "�주시대?",
	BARMENU_PET = "�펫",
	BARMENU_VEHICLE = "탈것",
	BARMENU_TARGETTARGET = "대?�? �대?",
	BARMENU_BUFFORDEBUFF = "�선?: �버프/디버프",
	BARMENU_SPELLID = "사용 주문 ID",
	BARMENU_HELPFUL = "버프",
	BARMENU_HARMFUL = "디버프",
	BARMENU_ONLYMINE = "?�신? �시전한 것만 보여줌",
	BARMENU_BARCOLOR = "바 색?",
	BARMENU_CLEARSETTINGS = "�설정 초기화",
	UIPANEL_SUBTEXT1 = "아래? �옵션?�서 타?�머? �그룹과 ? �그룹별 바 갯수를 설정하실 수 있습니다.",
	UIPANEL_SUBTEXT2 = "바는 잠근 후? �작?�합니다. 풀렸? �때 바? �?�?�과 ?�기 조절, 그리고 ?�?�? �바? �우?�릭? �함으로? �설정? �하실 수 있습니다. '/needtoknow' ?�는 '/ntk' 명령어를 통해서? �잠금/품 전환? �가능합니다.",
	UIPANEL_BARGROUP = "그룹 ",
	UIPANEL_NUMBERBARS = "바 갯수",
	UIPANEL_FIXEDDURATION = "Max bar duration",
	UIPANEL_BARTEXTURE = "바 ?�스처",
	UIPANEL_BARSPACING = "바 간격",
	UIPANEL_BARPADDING = "배경 ?�기",
	UIPANEL_BACKGROUNDCOLOR = "배경 색?",
	UIPANEL_LOCK = "�잠금",
	UIPANEL_UNLOCK = "풀림",
	UIPANEL_TOOLTIP_ENABLEGROUP = "? �그룹? �바를 표시/사용합니다.",
	UIPANEL_TOOLTIP_FIXEDDURATION = "Set the maximum length of bars for this group (in seconds).  Leave empty to set dynamically per bar.",
	UIPANEL_TOOLTIP_BARTEXTURE = "바 ?�스처를 선?�하세요",
	CMD_RESET = "초기화"
 }
setmetatable(Localize.koKR, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.ruRU = {
	-- by Vlakarados
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "Клик правой кнопкой мыши по полосе для настройки. Больше настроек в Интерфейс / Модификации / NeedToKnow меню. Ввести /needtoknow или /ntk для блокировки и включения.",
	RESIZE_TOOLTIP = "Кликнуть и тащить для изменения размера",
	BARMENU_ENABLE = "Включить полосу",
	BARMENU_CHOOSENAME = "Выбрать бафф/дебафф для слежения",
	CHOOSENAME_DIALOG = "Введите название баффа/дебаффа для слежения", 
	BARMENU_CHOOSEUNIT = "Юнит слежения",
	BARMENU_PLAYER = "Игрок",
	BARMENU_TARGET = "Цель",
	BARMENU_FOCUS = "Фокус",
	BARMENU_PET = "Питомец",
	BARMENU_VEHICLE = "Средство передвижения",
	BARMENU_TARGETTARGET = "Цель цели",
	BARMENU_BUFFORDEBUFF = "Бафф или дебафф?",
	BARMENU_SPELLID = "Используйте удостоверение личности произношения по буквам",
	BARMENU_HELPFUL = "Бафф",
	BARMENU_HARMFUL = "Дебафф",
	BARMENU_ONLYMINE = "Показывать только наложенные мной",
	BARMENU_BARCOLOR = "Цвет полосы",
	BARMENU_CLEARSETTINGS = "Очистить настройки",
	UIPANEL_SUBTEXT1 = "Эти настройки позволяют настроить бафф/дебафф полосы слежения.",
	UIPANEL_SUBTEXT2 = "Полосы работают только когда заблокированы группы. Можно менять размер и перемещать группы полос и кликнуть правой кнопкой мыши для изменения индивидуальных настроек. Ввести '/needtoknow' или '/ntk' to блокировки/разблокировки.",
	UIPANEL_BARGROUP = "Группа ",
	UIPANEL_NUMBERBARS = "Количество полос",
	UIPANEL_FIXEDDURATION = "Максимальное время на полосе",
	UIPANEL_BARTEXTURE = "Текcтура полоc",
	UIPANEL_BARSPACING = "Промежуток полоc",
	UIPANEL_BARPADDING = "Уплотнение полоc",
	UIPANEL_BACKGROUNDCOLOR = "Цвет фона",
	UIPANEL_LOCK = "Заблокировать",
	UIPANEL_UNLOCK = "Разблокировать",
	UIPANEL_TOOLTIP_ENABLEGROUP = "Показать и включить эту группу полос",
	UIPANEL_TOOLTIP_FIXEDDURATION = "Указать максимальное время пробега полосы в секундах. Оставить пустым для динамического времени для каждой полойы (полное время = длительность баффа/дебаффа).",
	UIPANEL_TOOLTIP_BARTEXTURE = "Выбрать текстуру для полос.",
	CMD_RESET = "Сброс"
}
setmetatable(Localize.ruRU, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.zhCN = {
	-- by wowui.cn
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "右键点击计时条配置. 更多的选项在暴雪界面选项菜单里. 输入 /needtoknow 来锁定并启用.",
	RESIZE_TOOLTIP = "点击和拖动来修改计时条尺寸",
	BARMENU_ENABLE = "启用计时条",
	BARMENU_CHOOSENAME = "选择需要计时的Buff/Debuff",
	CHOOSENAME_DIALOG = "输入在这个计时条内计时的Buff或Debuff的精确名字", 
	BARMENU_CHOOSEUNIT = "需要监视的单位",
	BARMENU_PLAYER = "玩家",
	BARMENU_TARGET = "目标",
	BARMENU_FOCUS = "焦点",
	BARMENU_PET = "宠物",
	BARMENU_VEHICLE = "载具",
	BARMENU_TARGETTARGET = "目标的目标",
	BARMENU_BUFFORDEBUFF = "Buff还是Debuff?",
	BARMENU_BUFF = "Buff",
	BARMENU_DEBUFF = "Debuff",
	BARMENU_ONLYMINE = "仅显示自身施放的",
	BARMENU_BARCOLOR = "计时条颜色",
	BARMENU_CLEARSETTINGS = "清除设置",
	UIPANEL_SUBTEXT1 = "这些选项允许你自定义Buff/Debuff计时条.",
	UIPANEL_SUBTEXT2 = "计时条锁定后才能正常工作. 当解锁时, 你可以移动或修改计时条分组的大小, 右键点击单独的计时条可以进行更多的设置. 你也可以输入 '/needtoknow' 或 '/ntk' 来锁定/解锁.",
	UIPANEL_BARGROUP = "分组 ",
	UIPANEL_NUMBERBARS = "计时条数量",
	UIPANEL_FIXEDDURATION = "计时条最大持续时间",
	UIPANEL_BARTEXTURE = "计时条材质",
	UIPANEL_BARSPACING = "计时条空距",
	UIPANEL_BARPADDING = "计时条间距",
	UIPANEL_BACKGROUNDCOLOR = "背景颜色",
	UIPANEL_LOCK = "锁定",
	UIPANEL_UNLOCK = "解锁",
	UIPANEL_TOOLTIP_ENABLEGROUP = "显示并启用这个分组的计时条",
	UIPANEL_TOOLTIP_FIXEDDURATION = "设置这个分组计时条的最大长度 (按秒数).  留空为每个计时条设置不同的数值.",
	UIPANEL_TOOLTIP_BARTEXTURE = "选择计时条的材质图像.",
	CMD_RESET = "重置"
}
setmetatable(Localize.zhCN, {__index = Localize.enUS})  -- Take missing strings from enUS

Localize.zhTW = {
	-- by wowui.cn
	BAR_TOOLTIP1 = "NeedToKnow",
	BAR_TOOLTIP2 = "右鍵點擊計時條配置. 更多的選項在暴雪介面選項菜單裏. 輸入 /needtoknow 來鎖定並啟用.",
	RESIZE_TOOLTIP = "點擊和拖動來修改計時條尺寸",
	BARMENU_ENABLE = "啟用計時條",
	BARMENU_CHOOSENAME = "選擇需要計時的Buff/Debuff",
	CHOOSENAME_DIALOG = "輸入在這個計時條內計時的Buff或Debuff的精確名字", 
	BARMENU_CHOOSEUNIT = "需要監視的單位",
	BARMENU_PLAYER = "玩家",
	BARMENU_TARGET = "目標",
	BARMENU_FOCUS = "焦點",
	BARMENU_PET = "寵物",
	BARMENU_VEHICLE = "載具",
	BARMENU_TARGETTARGET = "目標的目標",
	BARMENU_BUFFORDEBUFF = "Buff還是Debuff?",
	BARMENU_BUFF = "Buff",
	BARMENU_DEBUFF = "Debuff",
	BARMENU_ONLYMINE = "僅顯示自身施放的",
	BARMENU_BARCOLOR = "計時條顏色",
	BARMENU_CLEARSETTINGS = "清除設置",
	UIPANEL_SUBTEXT1 = "這些選項允許妳自定義Buff/Debuff計時條.",
	UIPANEL_SUBTEXT2 = "計時條鎖定後才能正常工作. 當解鎖時, 妳可以移動或修改計時條分組的大小, 右鍵點擊單獨的計時條可以進行更多的設置. 妳也可以輸入 '/needtoknow' 或 '/ntk' 來鎖定/解鎖.",
	UIPANEL_BARGROUP = "分組 ",
	UIPANEL_NUMBERBARS = "計時條數量",
	UIPANEL_FIXEDDURATION = "計時條最大持續時間",
	UIPANEL_BARTEXTURE = "計時條材質",
	UIPANEL_BARSPACING = "計時條空距",
	UIPANEL_BARPADDING = "計時條間距",
	UIPANEL_BACKGROUNDCOLOR = "背景顏色",
	UIPANEL_LOCK = "鎖定",
	UIPANEL_UNLOCK = "解鎖",
	UIPANEL_TOOLTIP_ENABLEGROUP = "顯示並啟用這個分組的計時條",
	UIPANEL_TOOLTIP_FIXEDDURATION = "設置這個分組計時條的最大長度 (按秒數).  留空為每個計時條設置不同的數值.",
	UIPANEL_TOOLTIP_BARTEXTURE = "選擇計時條的材質圖像.",
	CMD_RESET = "重置"
}
setmetatable(Localize.zhTW, {__index = Localize.enUS})  -- Take missing strings from enUS

--[[
Localization["esES"] = {} 
Localization["esMX"] = {} 
Localization["frFR"] = {} 
]]--

-- function NeedToKnow:LocalizeStrings() end
do
	local locale = GetLocale() 
	if locale == "deDE" then
		NeedToKnow.String = Localize.deDE
	elseif locale == "enUS" then
		NeedToKnow.String = Localize.enUS
	elseif locale == "koKR" then
		NeedToKnow.String = Localize.koKR
	elseif locale == "ruRU" then
		NeedToKnow.String = Localize.ruRU
	elseif locale == "zhCN" then
		NeedToKnow.String = Localize.zhCN
	elseif locale == "zhTW" then
		NeedToKnow.String = Localize.zhTW
	else
		NeedToKnow.String = Localize.enUS
	end
end

NeedToKnow.String.ITEM_NAMES = {
    -- Used by NeedToKnow.lua, NeedToKnow_Options.lua
    -- Seems like this should already exist somewhere
    -- Strings come from the chart on http://www.wowwiki.com/WoW_constants
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



--[[ Old globals (deprecated) ]]-- 

--[[ 

If you want to be super helpful, you can translate this stuff into whatever non-enUS language you happen to know and we'll credit you.  Please post the translations as an issue on CurseForge.com (https://www.curseforge.com/wow/addons/need-to-know/issues) or email them to us (lieandswell@yahoo.com). 

Thanks a bunch!  

--]]



-- NEEDTOKNOW defined in Init.lua

-- Define defaults in enUS
	NEEDTOKNOW.ALTERNATE_POWER = "Alternate Power";
	NEEDTOKNOW.COMBO_POINTS = "Combo Points";
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow";
	NEEDTOKNOW.BAR_TOOLTIP2 = "Right click bars to configure. More options in the Blizzard interface options menu. Type /needtoknow to lock and enable.";

	NEEDTOKNOW.RESIZE_TOOLTIP = "Click and drag to change size";

	NEEDTOKNOW.BARMENU_ENABLE = "Enable bar";
	-- NEEDTOKNOW.BARMENU_CHOOSENAME = "Choose buff/debuff to time...";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "Choose spell or ability...";
	NEEDTOKNOW.BARMENU_CHOOSESLOT = "Choose equipment Slot...";
	-- NEEDTOKNOW.BARMENU_CHOOSEPOWER = "Choose Power Type...";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "Enter the name of the buff or debuff to time with this bar"
	NEEDTOKNOW.IMPORTEXPORT_DIALOG = "The current settings for the bar appear below.  To copy these settings to the clipboard, press Ctrl+C. To paste the last settings you copied (such as from another bar), press Ctrl+V. Clear this text to reset the bar to the defaults.";
	NEEDTOKNOW.CHOOSE_OVERRIDE_TEXT = "Normally, the name of the aura/item/spell that activated the bar is displayed.  By entering text here, you can override that text with something else.  Leave this blank to use the default behavior."
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "Unit to monitor";
	NEEDTOKNOW.BARMENU_PLAYER = "Player";
	NEEDTOKNOW.BARMENU_TARGET = "Target";
	NEEDTOKNOW.BARMENU_FOCUS = "Focus";
	NEEDTOKNOW.BARMENU_PET = "Pet";
	NEEDTOKNOW.BARMENU_VEHICLE = "Vehicle";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "Target of Target";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "Bar Type";
	NEEDTOKNOW.BARMENU_LAST_RAID = "Last Raid Recipient";
	NEEDTOKNOW.BARMENU_SPELLID = "Use SpellID";
	NEEDTOKNOW.BARMENU_HELPFUL = "Buff";
	NEEDTOKNOW.BARMENU_HARMFUL = "Debuff";
	NEEDTOKNOW.BARMENU_ONLYMINE = "Only show if cast by self";
	NEEDTOKNOW.BARMENU_BARCOLOR = "Bar color";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "Clear settings";
	NEEDTOKNOW.BARMENU_POWER_PRIMARY = "Primary";
	NEEDTOKNOW.BARMENU_POWER_STAGGER = "Stagger";
	NEEDTOKNOW.BARMENU_SHOW = "Show";
	NEEDTOKNOW.BARMENU_SHOW_ICON = "Icon";
	NEEDTOKNOW.BARMENU_SHOW_TEXT = "Aura Name";
	NEEDTOKNOW.BARMENU_SHOW_COUNT = "Stack Count";
	NEEDTOKNOW.BARMENU_SHOW_TIME = "Time Remaining";
	NEEDTOKNOW.BARMENU_SHOW_SPARK = "Spark";
	NEEDTOKNOW.BARMENU_SHOW_MYPIP = "Indicator If Mine";
	NEEDTOKNOW.BARMENU_SHOW_TEXT_USER = "Override Aura Name...";
	NEEDTOKNOW.BARMENU_SHOW_TTN1 = "First Tooltip Number";
	NEEDTOKNOW.BARMENU_SHOW_TTN2 = "Second Tooltip Number";
	NEEDTOKNOW.BARMENU_SHOW_TTN3 = "Third Tooltip Number";

	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "These options allow you to customize NeedToKnow's timer bar groups.";
--	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "Bars work when locked. When unlocked, you can move/size bar groups and right click individual bars for more settings. You can also type '/needtoknow' or '/ntk' to lock/unlock.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "Group ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "Number of bars";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "Max bar duration";
	NEEDTOKNOW.UIPANEL_LOCK = "Lock";
	NEEDTOKNOW.UIPANEL_UNLOCK = "Unlock";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "Show and enable this group of bars";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "Set the maximum length of bars for this group (in seconds).  Leave empty to set dynamically per bar.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "Choose the texture graphic for timer bars";
	NEEDTOKNOW.CMD_RESET = "reset";

	NEEDTOKNOW.UIPANEL_CONFIGMODE = "Config mode";
	NEEDTOKNOW.UIPANEL_CONFIGMODE_TOOLTIP = "Unlock timer bars and make them configurable";
	NEEDTOKNOW.UIPANEL_PLAYMODE = "Play mode";
	NEEDTOKNOW.UIPANEL_PLAYMODE_TOOLTIP = "Lock and enable timer bars, making them click-through";

	NEEDTOKNOW.UIPANEL_APPEARANCE_SUBTEXT1 = "These options allow you to customize NeedToKnow's timer bars.";
	NEEDTOKNOW.UIPANEL_APPEARANCE = "Appearance";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "Background color";
	NEEDTOKNOW.UIPANEL_BARSPACING = "Bar spacing";
	NEEDTOKNOW.UIPANEL_BARPADDING = "Bar padding";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "Bar texture";
	NEEDTOKNOW.UIPANEL_BARFONT = "Bar font";
	NEEDTOKNOW.UIPANEL_FONT = "Font";
	NEEDTOKNOW.UIPANEL_FONT_OUTLINE = "Font Outline";

	NEEDTOKNOW.UIPANEL_PROFILES_SUBTEXT1 = "These options allow you to manage profiles.  Each profile is a complete NeedToKnow configuration for one talent spec.\nBy default, profiles are per-character (and have character: in front of their name.) Per-character profiles are only available to this character.  Profiles can be switched between per-character and per-account so that the same profile can be used by multiple characters on the same account.";
	NEEDTOKNOW.UIPANEL_CURRENTPRIMARY = "Current Primary Profile:";
	NEEDTOKNOW.UIPANEL_CURRENTSECONDARY = "Current Secondary Profile:";
	NEEDTOKNOW.UIPANEL_PROFILE = "Profile";
	NEEDTOKNOW.UIPANEL_SWITCHPROFILE_TOOLTIP = "Switch to using the currently selected profile";
	NEEDTOKNOW.UIPANEL_DELETEPROFILE_TOOLTIP = "Permanently delete the currently selected profile";
	NEEDTOKNOW.UIPANEL_COPYPROFILE_TOOLTIP   = "Create a new profile based on the currently selected profile";
	NEEDTOKNOW.UIPANEL_PRIVATEPROFILE_TOOLTIP  = "Make the selected profile accessible only to the current character";
	NEEDTOKNOW.UIPANEL_PUBLICPROFILE_TOOLTIP  = "Make the selected profile accessible to all the characters on the same account";
	NEEDTOKNOW.UIPANEL_RENAMEPROFILE_TOOLTIP  = "Change the name of this profile";
	NEEDTOKNOW.UIPANEL_PROFILE_SWITCHTO = "Switch To";
	NEEDTOKNOW.UIPANEL_PROFILE_DELETE = "Delete";
	NEEDTOKNOW.UIPANEL_PROFILE_DUPLICATE = "Duplicate";
	NEEDTOKNOW.UIPANEL_PROFILE_NAMELABEL = "New profile name:";
	NEEDTOKNOW.UIPANEL_PROFILE_RENAME = "Rename";
	NEEDTOKNOW.UIPANEL_PROFILE_MAKEPUBLIC = "To Account";
	NEEDTOKNOW.UIPANEL_PROFILE_MAKEPRIVATE = "Only This Char";

	NEEDTOKNOW.BARMENU_TOTEM = "Totem";
	NEEDTOKNOW.BARMENU_CASTCD = "Spell or item cooldown";
	NEEDTOKNOW.BARMENU_BUFFCD = "Internal cooldown";
	NEEDTOKNOW.BARMENU_EQUIPSLOT = "Equipment slot cooldown";
	NEEDTOKNOW.BARMENU_USABLE = "Reactive spell/ability";
	-- NEEDTOKNOW.BARMENU_POWER = "Power (experimental)";
	NEEDTOKNOW.CMD_HIDE = "hide";
	NEEDTOKNOW.CMD_PROFILE = "profile";
	NEEDTOKNOW.CMD_SHOW = "show";
	NEEDTOKNOW.BARMENU_TIMEFORMAT = "Time Format"; 
	NEEDTOKNOW.FMT_SINGLEUNIT = "Single unit (2 m)";
	NEEDTOKNOW.FMT_TWOUNITS = "Minutes and seconds (01:10)";
	NEEDTOKNOW.FMT_FLOAT = "Fractional Seconds (70.1)";
	NEEDTOKNOW.BARMENU_VISUALCASTTIME = "Cast time indicator";
	NEEDTOKNOW.BARMENU_VCT_ENABLE = "Enable for this bar";
	NEEDTOKNOW.BARMENU_VCT_COLOR = "Overlay color";
	NEEDTOKNOW.BARMENU_VCT_SPELL = "Choose cast time by spell...";
	NEEDTOKNOW.BARMENU_VCT_EXTRA = "Set additional time...";
	NEEDTOKNOW.CHOOSE_VCT_SPELL_DIALOG = "Enter the name of a spell (in your spellbook) whose cast time will determine the base length of the cast time indicator.  If left blank, the aura name will be used as the spell name.  To force this to be 0, type 0.";
	NEEDTOKNOW.CHOOSE_VCT_EXTRA_DIALOG = "Enter an amount of seconds that will be added to the cast time of the spell.  Ex: 1.5";
	NEEDTOKNOW.CHOOSE_BLINK_TITLE_DIALOG = "Enter the text to display on the bar when it is blinking.";
	NEEDTOKNOW.BUFFCD_DURATION_DIALOG = "Enter the cooldown duration triggered by the buffs watched by this bar.";
	NEEDTOKNOW.BUFFCD_RESET_DIALOG = "Enter the buff (or buffs) to watch for which reset the cooldown to 0.";
	NEEDTOKNOW.USABLE_DURATION_DIALOG = "Enter the useable duration for abilities watched by this bar.";


-- replace with translations, if available

if ( GetLocale() == "deDE" ) then
	-- by sp00n and Fxfighter EU-Echsenkessel
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow"; 
	NEEDTOKNOW.BAR_TOOLTIP2 = "Rechtsklick auf einen Balken für Einstellungen. Mehr Optionen sind im Blizzard Interface vorhanden. Zum Festsetzen und Aktivieren /needtoknow oder /ntk eingeben.";
	NEEDTOKNOW.RESIZE_TOOLTIP = "Klicken und ziehen, um die Größe zu ändern";
	NEEDTOKNOW.BARMENU_ENABLE = "Leiste aktivieren";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "Buff/Debuff auswählen";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "Name des Buffs/Debuffs für diesen Balken angeben"
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "Betroffene Einheit";
	NEEDTOKNOW.BARMENU_PLAYER = "Spieler";
	NEEDTOKNOW.BARMENU_TARGET = "Ziel";
	NEEDTOKNOW.BARMENU_FOCUS = "Fokus";
	NEEDTOKNOW.BARMENU_PET = "Begleiter (Pet)";
	NEEDTOKNOW.BARMENU_VEHICLE = "Vehicle";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "Ziel des Ziels";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "Buff oder Debuff?";
	NEEDTOKNOW.BARMENU_HELPFUL = "Buff";
	NEEDTOKNOW.BARMENU_HARMFUL = "Debuff";
	NEEDTOKNOW.BARMENU_ONLYMINE = "Nur Anzeigen wenn es selbst gezaubert wurde";
	NEEDTOKNOW.BARMENU_BARCOLOR = "Farbe des Balken";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "Einstellungen löschen";
	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "Diese Einstellungen ändern die Anzahl und die Gruppierung der Balken.";
	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "Die Darstellung funktioniert auch bei festgesetzen Balken. Wenn sie freigesetzt sind, können die Gruppierungen verschoben und deren Größe verändert werden. Ein Rechtsklick auf einen Balken zeigt weitere Einstellungsmöglichkeiten an. '/needtoknow' oder '/ntk' kann ebenfalls zum Festsetzen und Freistellen verwendet werden.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "Gruppe ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "Anzahl der Balken";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "Max bar duration";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "Balkentextur";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "Background color";
	NEEDTOKNOW.UIPANEL_BARSPACING = "Bar spacing";
	NEEDTOKNOW.UIPANEL_BARPADDING = "Bar padding";
	NEEDTOKNOW.UIPANEL_LOCK = "AddOn sperren";
	NEEDTOKNOW.UIPANEL_UNLOCK = "AddOn entsperren";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "Diese Gruppierung aktivieren und anzeigen";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "Set the maximum length of bars for this group (in seconds).  Leave empty to set dynamically per bar.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "Die Textur für die Balken auswählen";
	NEEDTOKNOW.CMD_RESET = "reset";
 
elseif ( GetLocale() == "koKR" ) then
	-- by metalchoir
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow";
	NEEDTOKNOW.BAR_TOOLTIP2 = "우?�릭: 메뉴 불러오기\n세부옵션? �기본 ?�터페?�스 설정?�서 가능\n/ntk 명령어로 잠근 후? �애드온 사용가능";
	NEEDTOKNOW.RESIZE_TOOLTIP = "드래그: ?�기 변경";
	NEEDTOKNOW.BARMENU_ENABLE = "바 사용";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "입력: 주문 ?�름";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "바? �표시할 버프 ?�는 디버프? �?�름? �입력하세요"
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "유닛 선?";
	NEEDTOKNOW.BARMENU_PLAYER = "�본?";
	NEEDTOKNOW.BARMENU_TARGET = "�대?";
	NEEDTOKNOW.BARMENU_FOCUS = "�주시대?";
	NEEDTOKNOW.BARMENU_PET = "�펫";
	NEEDTOKNOW.BARMENU_VEHICLE = "탈것";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "대?�? �대?";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "�선?: �버프/디버프";
	NEEDTOKNOW.BARMENU_SPELLID = "사용 주문 ID";
	NEEDTOKNOW.BARMENU_HELPFUL = "버프";
	NEEDTOKNOW.BARMENU_HARMFUL = "디버프";
	NEEDTOKNOW.BARMENU_ONLYMINE = "?�신? �시전한 것만 보여줌";
	NEEDTOKNOW.BARMENU_BARCOLOR = "바 색?";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "�설정 초기화";
	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "아래? �옵션?�서 타?�머? �그룹과 ? �그룹별 바 갯수를 설정하실 수 있습니다.";
	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "바는 잠근 후? �작?�합니다. 풀렸? �때 바? �?�?�과 ?�기 조절, 그리고 ?�?�? �바? �우?�릭? �함으로? �설정? �하실 수 있습니다. '/needtoknow' ?�는 '/ntk' 명령어를 통해서? �잠금/품 전환? �가능합니다.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "그룹 ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "바 갯수";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "Max bar duration";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "바 ?�스처";
	NEEDTOKNOW.UIPANEL_BARSPACING = "바 간격";
	NEEDTOKNOW.UIPANEL_BARPADDING = "배경 ?�기";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "배경 색?";
	NEEDTOKNOW.UIPANEL_LOCK = "�잠금";
	NEEDTOKNOW.UIPANEL_UNLOCK = "풀림";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "? �그룹? �바를 표시/사용합니다.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "Set the maximum length of bars for this group (in seconds).  Leave empty to set dynamically per bar.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "바 ?�스처를 선?�하세요";
	NEEDTOKNOW.CMD_RESET = "초기화";
 
elseif ( GetLocale() == "ruRU" ) then
	-- by Vlakarados
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow";
	NEEDTOKNOW.BAR_TOOLTIP2 = "Клик правой кнопкой мыши по полосе для настройки. Больше настроек в Интерфейс / Модификации / NeedToKnow меню. Ввести /needtoknow или /ntk для блокировки и включения.";
	NEEDTOKNOW.RESIZE_TOOLTIP = "Кликнуть и тащить для изменения размера";
	NEEDTOKNOW.BARMENU_ENABLE = "Включить полосу";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "Выбрать бафф/дебафф для слежения";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "Введите название баффа/дебаффа для слежения"
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "Юнит слежения";
	NEEDTOKNOW.BARMENU_PLAYER = "Игрок";
	NEEDTOKNOW.BARMENU_TARGET = "Цель";
	NEEDTOKNOW.BARMENU_FOCUS = "Фокус";
	NEEDTOKNOW.BARMENU_PET = "Питомец";
	NEEDTOKNOW.BARMENU_VEHICLE = "Средство передвижения";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "Цель цели";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "Бафф или дебафф?";
	NEEDTOKNOW.BARMENU_SPELLID = "Используйте удостоверение личности произношения по буквам";
	NEEDTOKNOW.BARMENU_HELPFUL = "Бафф";
	NEEDTOKNOW.BARMENU_HARMFUL = "Дебафф";
	NEEDTOKNOW.BARMENU_ONLYMINE = "Показывать только наложенные мной";
	NEEDTOKNOW.BARMENU_BARCOLOR = "Цвет полосы";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "Очистить настройки";
	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "Эти настройки позволяют настроить бафф/дебафф полосы слежения.";
	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "Полосы работают только когда заблокированы группы. Можно менять размер и перемещать группы полос и кликнуть правой кнопкой мыши для изменения индивидуальных настроек. Ввести '/needtoknow' или '/ntk' to блокировки/разблокировки.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "Группа ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "Количество полос";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "Максимальное время на полосе";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "Текcтура полоc";
	NEEDTOKNOW.UIPANEL_BARSPACING = "Промежуток полоc";
	NEEDTOKNOW.UIPANEL_BARPADDING = "Уплотнение полоc";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "Цвет фона";
	NEEDTOKNOW.UIPANEL_LOCK = "Заблокировать";
	NEEDTOKNOW.UIPANEL_UNLOCK = "Разблокировать";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "Показать и включить эту группу полос";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "Указать максимальное время пробега полосы в секундах. Оставить пустым для динамического времени для каждой полойы (полное время = длительность баффа/дебаффа).";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "Выбрать текстуру для полос.";
	NEEDTOKNOW.CMD_RESET = "Сброс";

elseif ( GetLocale() == "zhCN" ) then
	-- by wowui.cn
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow";
	NEEDTOKNOW.BAR_TOOLTIP2 = "右键点击计时条配置. 更多的选项在暴雪界面选项菜单里. 输入 /needtoknow 来锁定并启用.";
	NEEDTOKNOW.RESIZE_TOOLTIP = "点击和拖动来修改计时条尺寸";
	NEEDTOKNOW.BARMENU_ENABLE = "启用计时条";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "选择需要计时的Buff/Debuff";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "输入在这个计时条内计时的Buff或Debuff的精确名字"
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "需要监视的单位";
	NEEDTOKNOW.BARMENU_PLAYER = "玩家";
	NEEDTOKNOW.BARMENU_TARGET = "目标";
	NEEDTOKNOW.BARMENU_FOCUS = "焦点";
	NEEDTOKNOW.BARMENU_PET = "宠物";
	NEEDTOKNOW.BARMENU_VEHICLE = "载具";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "目标的目标";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "Buff还是Debuff?";
	NEEDTOKNOW.BARMENU_BUFF = "Buff";
	NEEDTOKNOW.BARMENU_DEBUFF = "Debuff";
	NEEDTOKNOW.BARMENU_ONLYMINE = "仅显示自身施放的";
	NEEDTOKNOW.BARMENU_BARCOLOR = "计时条颜色";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "清除设置";
	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "这些选项允许你自定义Buff/Debuff计时条.";
	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "计时条锁定后才能正常工作. 当解锁时, 你可以移动或修改计时条分组的大小, 右键点击单独的计时条可以进行更多的设置. 你也可以输入 '/needtoknow' 或 '/ntk' 来锁定/解锁.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "分组 ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "计时条数量";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "计时条最大持续时间";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "计时条材质";
	NEEDTOKNOW.UIPANEL_BARSPACING = "计时条空距";
	NEEDTOKNOW.UIPANEL_BARPADDING = "计时条间距";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "背景颜色";
	NEEDTOKNOW.UIPANEL_LOCK = "锁定";
	NEEDTOKNOW.UIPANEL_UNLOCK = "解锁";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "显示并启用这个分组的计时条";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "设置这个分组计时条的最大长度 (按秒数).  留空为每个计时条设置不同的数值.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "选择计时条的材质图像.";
	NEEDTOKNOW.CMD_RESET = "重置";

elseif ( GetLocale() == "zhTW" ) then
	-- by wowui.cn
	NEEDTOKNOW.BAR_TOOLTIP1 = "NeedToKnow";
	NEEDTOKNOW.BAR_TOOLTIP2 = "右鍵點擊計時條配置. 更多的選項在暴雪介面選項菜單裏. 輸入 /needtoknow 來鎖定並啟用.";
	NEEDTOKNOW.RESIZE_TOOLTIP = "點擊和拖動來修改計時條尺寸";
	NEEDTOKNOW.BARMENU_ENABLE = "啟用計時條";
	NEEDTOKNOW.BARMENU_CHOOSENAME = "選擇需要計時的Buff/Debuff";
	NEEDTOKNOW.CHOOSENAME_DIALOG = "輸入在這個計時條內計時的Buff或Debuff的精確名字"
	NEEDTOKNOW.BARMENU_CHOOSEUNIT = "需要監視的單位";
	NEEDTOKNOW.BARMENU_PLAYER = "玩家";
	NEEDTOKNOW.BARMENU_TARGET = "目標";
	NEEDTOKNOW.BARMENU_FOCUS = "焦點";
	NEEDTOKNOW.BARMENU_PET = "寵物";
	NEEDTOKNOW.BARMENU_VEHICLE = "載具";
	NEEDTOKNOW.BARMENU_TARGETTARGET = "目標的目標";
	NEEDTOKNOW.BARMENU_BUFFORDEBUFF = "Buff還是Debuff?";
	NEEDTOKNOW.BARMENU_BUFF = "Buff";
	NEEDTOKNOW.BARMENU_DEBUFF = "Debuff";
	NEEDTOKNOW.BARMENU_ONLYMINE = "僅顯示自身施放的";
	NEEDTOKNOW.BARMENU_BARCOLOR = "計時條顏色";
	NEEDTOKNOW.BARMENU_CLEARSETTINGS = "清除設置";
	NEEDTOKNOW.UIPANEL_SUBTEXT1 = "這些選項允許妳自定義Buff/Debuff計時條.";
	NEEDTOKNOW.UIPANEL_SUBTEXT2 = "計時條鎖定後才能正常工作. 當解鎖時, 妳可以移動或修改計時條分組的大小, 右鍵點擊單獨的計時條可以進行更多的設置. 妳也可以輸入 '/needtoknow' 或 '/ntk' 來鎖定/解鎖.";
	NEEDTOKNOW.UIPANEL_BARGROUP = "分組 ";
	NEEDTOKNOW.UIPANEL_NUMBERBARS = "計時條數量";
	NEEDTOKNOW.UIPANEL_FIXEDDURATION = "計時條最大持續時間";
	NEEDTOKNOW.UIPANEL_BARTEXTURE = "計時條材質";
	NEEDTOKNOW.UIPANEL_BARSPACING = "計時條空距";
	NEEDTOKNOW.UIPANEL_BARPADDING = "計時條間距";
	NEEDTOKNOW.UIPANEL_BACKGROUNDCOLOR = "背景顏色";
	NEEDTOKNOW.UIPANEL_LOCK = "鎖定";
	NEEDTOKNOW.UIPANEL_UNLOCK = "解鎖";
	NEEDTOKNOW.UIPANEL_TOOLTIP_ENABLEGROUP = "顯示並啟用這個分組的計時條";
	NEEDTOKNOW.UIPANEL_TOOLTIP_FIXEDDURATION = "設置這個分組計時條的最大長度 (按秒數).  留空為每個計時條設置不同的數值.";
	NEEDTOKNOW.UIPANEL_TOOLTIP_BARTEXTURE = "選擇計時條的材質圖像.";
	NEEDTOKNOW.CMD_RESET = "重置";

end


