local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = "确定",
    ["CLOSE"] = "关闭",
    ["CANCEL"] = "取消",

    -- Import / Export errors
    ["EXPORT"] = "导出",
    ["EXPORT_BAR"] = "导出此条形",
    ["IMPORT"] = "导入",
    ["IMPORT_BAR"] = "导入此条形",
    ["EXPORT_FAILED"] = "导出失败。",
    ["IMPORT_FAILED_WITH_ERROR"] = "导入失败，错误如下：",
    ["IMPORT_STRING_NOT_SUITABLE"] = "此导入字符串不适用于",
    ["IMPORT_STRING_OLDER_VERSION"] = "此导入字符串适用于旧版本的",
    ["IMPORT_STRING_INVALID"] = "无效的导入字符串",
    ["IMPORT_DECODE_FAILED"] = "解码失败",
    ["IMPORT_DECOMPRESSION_FAILED"] = "解压失败",
    ["IMPORT_DESERIALIZATION_FAILED"] = "反序列化失败",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "能量颜色",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "生命值颜色",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "导入 / 导出",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "此处生成的导出字符串包含当前编辑模式布局的所有条形。\n如果您只想导出某个特定条形，请检查编辑模式中该条形设置面板中的导出按钮。",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "下方的导入按钮支持全局和单个条形导出字符串。编辑模式中每个条形设置中的导入按钮仅限于该特定条形。\n例如，如果您导出了所有条形，但只想导入主要资源条，请使用编辑模式中主要资源条的导入按钮。",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "仅导出能量颜色",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "导出（包含能量颜色）",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "导出（不含能量颜色）",
    ["SETTINGS_BUTTON_IMPORT"] = "导入",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "退出编辑模式后将打开设置",
    
    -- Power
    ["HEALTH"] = "生命值",
    ["MANA"] = "法力值",
    ["RAGE"] = "怒气",
    ["FOCUS"] = "集中值",
    ["TIP_OF_THE_SPEAR"] = "利矛之刃",
    ["ENERGY"] = "能量",
    ["RUNIC_POWER"] = "符文能量",
    ["LUNAR_POWER"] = "月能",
    ["MAELSTROM"]= "漩涡",
    ["MAELSTROM_WEAPON"] = "漩涡武器",
    ["INSANITY"] = "狂乱",
    ["FURY"]= "恶魔之怒",
    ["BLOOD_RUNE"] = "鲜血符文",
    ["FROST_RUNE"] = "冰霜符文",
    ["UNHOLY_RUNE"] = "邪恶符文",
    ["COMBO_POINTS"] = "连击点",
    ["OVERCHARGED_COMBO_POINTS"] = "充能连击点",
    ["SOUL_SHARDS"] = "灵魂碎片",
    ["HOLY_POWER"] = "神圣能量",
    ["CHI"] = "真气",
    ["STAGGER_LOW"] = "轻度醉拳",
    ["STAGGER_MEDIUM"] ="中度醉拳",
    ["STAGGER_HIGH"] = "重度醉拳",
    ["ARCANE_CHARGES"] = "奥术充能",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "复仇灵魂残片",
    ["SOUL_FRAGMENTS_DDH"] = "吞噬者灵魂残片",
    ["SOUL_FRAGMENTS_VOID_META"] = "吞噬者灵魂残片（虚空形态）",
    ["ESSENCE"]= "精华",
    ["EBON_MIGHT"] = "黑檀之力",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "生命条",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "主要资源条",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "次要资源条",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "黑檀之力条",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "条形可见性",
    ["BAR_VISIBLE"] = "显示条形",
    ["BAR_STRATA"] = "条形层级",
    ["BAR_STRATA_TOOLTIP"] = "条形渲染的层级",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "在坐骑或载具中隐藏",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "包括德鲁伊旅行形态",
    ["HIDE_MANA_ON_ROLE"] = "在特定职责下隐藏法力值",
    ["HIDE_HEALTH_ON_ROLE"] = "在特定职责下隐藏",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "对奥术法师无效",
    ["HIDE_BLIZZARD_UI"] = "隐藏暴雪自带界面",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "隐藏暴雪自带的玩家框架界面",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "隐藏暴雪自带的次要资源界面（例如死亡骑士的符文条）",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "可点击生命条",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "在生命条上启用玩家框体的默认点击行为。",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "位置与大小",
    ["POSITION"] = "位置",
    ["X_POSITION"] = "X 坐标",
    ["Y_POSITION"] = "Y 坐标",
    ["RELATIVE_FRAME"] = "相对框架",
    ["RELATIVE_FRAME_TOOLTIP"] = "由于限制，如果锚定到 UIParent 以外的框架，您可能无法拖动该框架。请使用 X/Y 滑块",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "无法更改相对框架，因为所选框架已经相对于此框架。",
    ["ANCHOR_POINT"] = "锚点",
    ["RELATIVE_POINT"] = "相对点",
    ["BAR_SIZE"] = "条形大小",
    ["WIDTH_MODE"] = "宽度模式",
    ["WIDTH"] = "宽度",
    ["MINIMUM_WIDTH"] = "最小宽度",
    ["MINIMUM_WIDTH_TOOLTIP"] = "设为0禁用。仅在同步到冷却管理器时有效",
    ["HEIGHT"] = "高度",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "条形设置",
    ["FILL_DIRECTION"] = "填充方向",
    ["FASTER_UPDATES"] = "快速更新 (较高CPU占用)",
    ["SMOOTH_PROGRESS"] = "平滑进度",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "显示刻度（如果可用）",
    ["TICK_THICKNESS"] = "刻度粗细",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "条形风格",
    ["USE_CLASS_COLOR"] = "使用职业颜色",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "使用资源纹理和颜色",
    ["BAR_TEXTURE"] = "条形纹理",
    ["BACKGROUND"] = "背景",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "使用条形颜色作为背景颜色",
    ["BORDER"] = "边框",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "文本设置",
    ["SHOW_RESOURCE_NUMBER"] = "显示资源数值",
    ["RESOURCE_NUMBER_FORMAT"] = "格式",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "某些资源不支持百分比格式",
    ["RESOURCE_NUMBER_PRECISION"] = "精度",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "对齐",
    ["SHOW_MANA_AS_PERCENT"] = "以百分比显示法力值",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "强制法力值使用百分比格式",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "显示资源充能计时器（例如符文）",
    ["CHARGE_TIMER_PRECISION"] = "充能计时器精度",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "字体",
    ["FONT"] = "字体",
    ["FONT_SIZE"] = "大小",
    ["FONT_OUTLINE"] = "描边",
    
    -- Other
    ["POWER_COLOR_SETTINGS"] = "能量颜色设置",
}

addonTable:RegisterLocale("zhCN", baseLocale)
