local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,

    -- Import / Export errors
    ["EXPORT"] = "Export",
    ["EXPORT_BAR"] = "Export This Bar",
    ["IMPORT"] = "Import",
    ["IMPORT_BAR"] = "Import This Bar",
    ["EXPORT_FAILED"] = "Export failed.",
    ["IMPORT_FAILED_WITH_ERROR"] = "Import failed with the following error: ",
    ["IMPORT_STRING_NOT_SUITABLE"] = "This import string is not suitable for",
    ["IMPORT_STRING_OLDER_VERSION"] = "This import string is meant for an older version of",
    ["IMPORT_STRING_INVALID"] = "Invalid import string",
    ["IMPORT_DECODE_FAILED"] = "Decode failed",
    ["IMPORT_DECOMPRESSION_FAILED"] = "Decompression failed",
    ["IMPORT_DESERIALIZATION_FAILED"] = "Deserialization failed",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "Power Colors",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "Health Color",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "Import / Export",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "Export strings generated here encompass all bars of your current Edit Mode Layout.\nIf you wish to only export one bar in particular, please check the Export button in the Bar Settings panel in\nEdit Mode.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "The Import button below supports global and individual bar export strings. The one in each Bar Settings in\nEdit Mode is restricted to this particular bar.\nFor example, if you exported all your bars but wish to only import the Primary Resource Bar, then use the\nImport button of the Primary Resource bar in Edit Mode.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "Export Only Power Colors",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "Export With Power Colors",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "Export Without Power Colors",
    ["SETTINGS_BUTTON_IMPORT"] = "Import",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "Settings will open after leaving Edit Mode",
    
    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"]= POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "Whirlwind",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "Tip of the Spear",
    ["ENERGY"] = POWER_TYPE_ENERGY,
    ["RUNIC_POWER"] = POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"] = POWER_TYPE_LUNAR_POWER,
    ["MAELSTROM"] = POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "Maelstrom Weapon",
    ["INSANITY"] = POWER_TYPE_INSANITY,
    ["FURY"] = POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"] = COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"] = COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"] = COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "Overcharged Combo Points",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "Low Stagger",
    ["STAGGER_MEDIUM"] ="Medium Stagger",
    ["STAGGER_HIGH"] = "High Stagger",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["SOUL_FRAGMENTS_VENGEANCE"] = "Vengeance Soul Fragments",
    ["SOUL_FRAGMENTS_DDH"] = "Devorer Soul Fragments",
    ["SOUL_FRAGMENTS_VOID_META"] = "Devorer Soul Fragments Void Meta.",
    ["ESSENCE"]= POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "Ebon Might",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "Health Bar",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "Primary Resource Bar",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "Secondary Resource Bar",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "Ebon Might Bar",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "Bar Visibility",
    ["BAR_VISIBLE"] = "Bar Visible",
    ["BAR_STRATA"] = "Bar Strata",
    ["BAR_STRATA_TOOLTIP"] = "The layer the bar is rendered on",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "Hide While Mounted Or In Vehicule",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "Includes Druid Travel Form",
    ["HIDE_MANA_ON_ROLE"] = "Hide Mana On Role",
    ["HIDE_HEALTH_ON_ROLE"] = "Hide On Role",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "Not effective on Arcane Mage",
    ["HIDE_BLIZZARD_UI"] = "Hide Blizzard UI",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "Hides the default Blizzard Player Frame UI",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "Hides the default Blizzard secondary resource UI (e.g. Rune Frame for Death Knights)",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "Clickable Health Bar",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "Enable default Player Frame click behavior on the Health Bar.",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "Position & Size",
    ["POSITION"] = "Position",
    ["X_POSITION"] = "X Position",
    ["Y_POSITION"] = "Y Position",
    ["RELATIVE_FRAME"] = "Relative Frame",
    ["RELATIVE_FRAME_TOOLTIP"] = "Due to limitations, you may not drag the frame if anchored to another frame than UIParent. Use the X/Y sliders",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "Cannot change Relative Frame as the selected Frame is already relative to this Frame.",
    ["ANCHOR_POINT"] = "Anchor Point",
    ["RELATIVE_POINT"] = "Relative Point",
    ["BAR_SIZE"] = "Bar Size",
    ["WIDTH_MODE"] = "Width Mode",
    ["WIDTH"] = "Width",
    ["MINIMUM_WIDTH"] = "Minimum Width",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0 to disable. Only active if synced to the Cooldown Manager",
    ["HEIGHT"] = "Height",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "Bar Settings",
    ["FILL_DIRECTION"] = "Fill Direction",
    ["FASTER_UPDATES"] = "Faster Updates (Higher CPU Usage)",
    ["SMOOTH_PROGRESS"] = "Smooth Progress",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "Show Ticks When Available",
    ["TICK_THICKNESS"] = "Tick Thickness",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "Bar Style",
    ["USE_CLASS_COLOR"] = "Use Class Color",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "Use Resource Texture And Color",
    ["BAR_TEXTURE"] = "Bar Texture",
    ["BACKGROUND"] = "Background",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "Use Bar Color For Background Color",
    ["BORDER"] = "Border",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "Text Settings",
    ["SHOW_RESOURCE_NUMBER"] = "Show Resource Number",
    ["RESOURCE_NUMBER_FORMAT"] = "Format",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "Some resources do no support the percent format",
    ["RESOURCE_NUMBER_PRECISION"] = "Precision",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "Alignment",
    ["SHOW_MANA_AS_PERCENT"] = "Show Mana As Percent",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "Force the Percent format on Mana",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "Show Resource Charge Timer (e.g. Runes)",
    ["CHARGE_TIMER_PRECISION"] = "Charge Timer Precision",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "Font",
    ["FONT"] = "Font",
    ["FONT_SIZE"] = "Size",
    ["FONT_OUTLINE"] = "Outline",
    
    -- Other
    ["POWER_COLOR_SETTINGS"] = "Power Color Settings",
}

addonTable:RegisterLocale("enUS", baseLocale)
