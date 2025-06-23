do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "deDE")
    local L = languageTable

------------------------------------------------------------
--[[Translation missing --]]
L["A /reload may be required to take effect."] = "A /reload may be required to take effect."
--[[Translation missing --]]
L["CVar, saved within Plater profile and restored when loading the profile."] = "CVar, saved within Plater profile and restored when loading the profile."
--[[Translation missing --]]
L["EXPORT"] = "Export"
--[[Translation missing --]]
L["EXPORT_CAST_COLORS"] = "Share Colors"
--[[Translation missing --]]
L["EXPORT_CAST_SOUNDS"] = "Share Sounds"
--[[Translation missing --]]
L["HIGHLIGHT_HOVEROVER"] = "Hover Over Highlight"
--[[Translation missing --]]
L["HIGHLIGHT_HOVEROVER_ALPHA"] = "Hover Over Highlight Alpha"
--[[Translation missing --]]
L["HIGHLIGHT_HOVEROVER_DESC"] = "Highlight effect when the mouse is over the nameplate."
--[[Translation missing --]]
L["Hold Shift to change the sound of all casts with the audio %s to %s"] = "Hold Shift to change the sound of all casts with the audio %s to %s"
--[[Translation missing --]]
L["IMPORT"] = "Import"
--[[Translation missing --]]
L["IMPORT_CAST_COLORS"] = "Import Colors"
--[[Translation missing --]]
L["IMPORT_CAST_SOUNDS"] = "Import Sounds"
L["OPTIONS_ALPHA"] = "Alpha"
L["OPTIONS_ALPHABYFRAME_ALPHAMULTIPLIER"] = "Transparenz-Multiplikator."
L["OPTIONS_ALPHABYFRAME_DEFAULT"] = "Standard-Transparenz"
L["OPTIONS_ALPHABYFRAME_DEFAULT_DESC"] = "Höhe der Transparenz, die auf alle Komponenten eines einzelnen Namensschilds angewendet wird."
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES"] = "Aktivieren für Feinde"
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES_DESC"] = "Transparenz-Einstellungen auf gegnerische Einheiten anwenden."
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY"] = "Für freundliche Ziele Aktivieren"
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY_DESC"] = "Transparenzeinstellungen auf befreundete Einheiten anwenden."
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE"] = "Ziel-Alpha/Reichweite"
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE_DESC"] = "Transparenz für Ziele oder Einheiten in Reichweite."
L["OPTIONS_ALPHABYFRAME_TITLE_ENEMIES"] = "Transparenzbetrag pro Frame (Feinde)"
L["OPTIONS_ALPHABYFRAME_TITLE_FRIENDLY"] = "Transparenzbetrag pro Frame (freundlich)"
L["OPTIONS_AMOUNT"] = "Menge"
L["OPTIONS_ANCHOR"] = "Ankerpunkt"
L["OPTIONS_ANCHOR_BOTTOM"] = "Unten"
L["OPTIONS_ANCHOR_BOTTOMLEFT"] = "Unten links"
L["OPTIONS_ANCHOR_BOTTOMRIGHT"] = "Unten rechts"
L["OPTIONS_ANCHOR_CENTER"] = "Mitte"
L["OPTIONS_ANCHOR_INNERBOTTOM"] = "Innen unten"
L["OPTIONS_ANCHOR_INNERLEFT"] = "Innen links"
L["OPTIONS_ANCHOR_INNERRIGHT"] = "Rechts innen "
L["OPTIONS_ANCHOR_INNERTOP"] = "Innen oben"
L["OPTIONS_ANCHOR_LEFT"] = "Links"
L["OPTIONS_ANCHOR_RIGHT"] = "Rechts"
--[[Translation missing --]]
L["OPTIONS_ANCHOR_TARGET_SIDE"] = "Which side this widget is attach to."
L["OPTIONS_ANCHOR_TOP"] = "Oben"
L["OPTIONS_ANCHOR_TOPLEFT"] = "Oben links"
L["OPTIONS_ANCHOR_TOPRIGHT"] = "Oben rechts"
--[[Translation missing --]]
L["OPTIONS_AUDIOCUE_COOLDOWN"] = "Audio Cooldown"
--[[Translation missing --]]
L["OPTIONS_AUDIOCUE_COOLDOWN_DESC"] = [=[Amount of time in milliseconds to wait before playing the SAME audio again.

Prevents loud sounds from playing when two or more casts are happening at the same time.

Set to 0 to disable this feature.]=]
--[[Translation missing --]]
L["OPTIONS_AURA_DEBUFF_HEIGHT"] = "Debuff's icon height."
--[[Translation missing --]]
L["OPTIONS_AURA_DEBUFF_WITH"] = "Debuff's icon width."
--[[Translation missing --]]
L["OPTIONS_AURA_HEIGHT"] = "Debuff's icon height."
--[[Translation missing --]]
L["OPTIONS_AURA_SHOW_BUFFS"] = "Show Buffs"
--[[Translation missing --]]
L["OPTIONS_AURA_SHOW_BUFFS_DESC"] = "Show buffs on you on the Personal Bar."
--[[Translation missing --]]
L["OPTIONS_AURA_SHOW_DEBUFFS"] = "Show Debuffs"
--[[Translation missing --]]
L["OPTIONS_AURA_SHOW_DEBUFFS_DESC"] = "Show debuffs on you on the Personal Bar."
--[[Translation missing --]]
L["OPTIONS_AURA_WIDTH"] = "Debuff's icon width."
--[[Translation missing --]]
L["OPTIONS_AURAS_ENABLETEST"] = "Enable this to hide test auras shown when configuring."
--[[Translation missing --]]
L["OPTIONS_AURAS_SORT"] = "Sort Auras"
--[[Translation missing --]]
L["OPTIONS_AURAS_SORT_DESC"] = "Auras are sorted by time remaining (default)."
--[[Translation missing --]]
L["OPTIONS_BACKGROUND_ALWAYSSHOW"] = "Always Show Background"
--[[Translation missing --]]
L["OPTIONS_BACKGROUND_ALWAYSSHOW_DESC"] = "Enable a background showing the area of the clickable area."
--[[Translation missing --]]
L["OPTIONS_BORDER_COLOR"] = "Border Color"
--[[Translation missing --]]
L["OPTIONS_BORDER_THICKNESS"] = "Border Thickness"
--[[Translation missing --]]
L["OPTIONS_BUFFFRAMES"] = "Buff Frames"
L["OPTIONS_CANCEL"] = "Abbrechen"
--[[Translation missing --]]
L["OPTIONS_CAST_COLOR_CHANNELING"] = "Channelled"
--[[Translation missing --]]
L["OPTIONS_CAST_COLOR_INTERRUPTED"] = "Interrupted"
--[[Translation missing --]]
L["OPTIONS_CAST_COLOR_REGULAR"] = "Regular"
--[[Translation missing --]]
L["OPTIONS_CAST_COLOR_SUCCESS"] = "Success"
--[[Translation missing --]]
L["OPTIONS_CAST_COLOR_UNINTERRUPTIBLE"] = "Uninterruptible"
--[[Translation missing --]]
L["OPTIONS_CAST_SHOW_TARGETNAME"] = "Show Target Name"
--[[Translation missing --]]
L["OPTIONS_CAST_SHOW_TARGETNAME_DESC"] = "Show who is the target of the current cast (if the target exists)"
--[[Translation missing --]]
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK"] = "[Tank] Don't Show Your Name"
--[[Translation missing --]]
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK_DESC"] = "If you are a tank don't show the target name if the cast is on you."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_APPEARANCE"] = "Cast Bar Appearance"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_BLIZZCASTBAR"] = "Blizzard Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_COLORS"] = "Cast Bar Colors"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED"] = "Enable Fade Animations"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED_DESC"] = "Enable fade animations when the cast starts and stop."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END"] = "On Stop"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END_DESC"] = "When a cast ends, this is the amount of time the cast bar takes to go from 100% transparency to not be visible at all."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START"] = "On Start"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START_DESC"] = "When a cast starts, this is the amount of time the cast bar takes to go from zero transparency to full opaque."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_HEIGHT"] = "Height of the cast bar."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_HIDE_ENEMY"] = "Hide Enemy Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_HIDE_FRIENDLY"] = "Hide Friendly Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_HIDEBLIZZARD"] = "Hide Blizzard Player Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE"] = "Enable Icon Customization"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE_DESC"] = "If this option is disabled, Plater won't modify the spell icon, leaving it for scripts to do."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT"] = "No Spell Name Length Limitation"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT_DESC"] = "Spell name text won't be cut to fit within the cast bar width."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_QUICKHIDE"] = "Quick Hide Cast Bar"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_QUICKHIDE_DESC"] = "After the cast finishes, immediately hide the cast bar."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPARK_HALF"] = "Half Spark"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPARK_HALF_DESC"] = "Show only half of the spark texture."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPARK_HIDE_INTERRUPT"] = "Hide Spark On Interrupt"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPARK_SETTINGS"] = "Spark Settings"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_SPELLICON"] = "Spell Icon"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_TOGGLE_TEST"] = "Toggle Cast Bar Test"
--[[Translation missing --]]
L["OPTIONS_CASTBAR_TOGGLE_TEST_DESC"] = "Start cast bar test, press again to stop."
--[[Translation missing --]]
L["OPTIONS_CASTBAR_WIDTH"] = "Width of the cast bar."
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS"] = "Remove All Sounds"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS_CONFIRM"] = "Are you sure you want to remove all configured cast sounds?"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLECOLORS"] = "Disable All Colors"
--[[Translation missing --]]
L["OPTIONS_CASTCOLORS_DISABLECOLORS_CONFIRM"] = "Confirm disable all cast colors?"
--[[Translation missing --]]
L["OPTIONS_CLICK_SPACE_HEIGHT"] = "The height of the are area which accepts mouse clicks to select the target"
--[[Translation missing --]]
L["OPTIONS_CLICK_SPACE_WIDTH"] = "The width of the are area which accepts mouse clicks to select the target"
L["OPTIONS_COLOR"] = "Farbe"
--[[Translation missing --]]
L["OPTIONS_COLOR_BACKGROUND"] = "Background Color"
--[[Translation missing --]]
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR"] = "Personal Health and Mana Bars|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR_DESC"] = [=[Shows a mini health and mana bars under your character.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
--[[Translation missing --]]
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW"] = "Always Show Nameplates|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW_DESC"] = [=[Show nameplates for all units near you. If disabled only show relevant units when you are in combat.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
L["OPTIONS_ENABLED"] = "Aktiviert"
L["OPTIONS_ERROR_CVARMODIFY"] = "CVars können im Kampf nicht verändert werden."
L["OPTIONS_ERROR_EXPORTSTRINGERROR"] = "Fehler beim Exportieren"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE"] = "Execute Range"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_DESC"] = [=[Show an indicator when the target unit is in 'execute' range.

If the detection does not work after a patch, communicate at Discord.]=]
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH"] = "Execute Range (high heal)"
--[[Translation missing --]]
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH_DESC"] = [=[Show the execute indicator for the high portion of the health.

If the detection does not work after a patch, communicate at Discord.]=]
L["OPTIONS_FONT"] = "Schriftart"
--[[Translation missing --]]
L["OPTIONS_FORMAT_NUMBER"] = "Number Format"
L["OPTIONS_FRIENDLY"] = "Freundlich"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_ANCHOR_TITLE"] = "Lebensbalken-Aussehen"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGCOLOR"] = "Lebensbalken Hintergrundfarbe und -Alpha"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGTEXTURE"] = "Lebensbalken Hintergrundtextur"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_TEXTURE"] = "Lebensbalken-Textur"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_ANCHOR_TITLE"] = "Transparenz-Einstellungen"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK"] = "Entfernungsprüfung"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_ALPHA"] = "Entfernungs-Transparenz"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_SPEC_DESC"] = "Für diese Spezialisierung verwendeter Zauber zur Entfernungsprüfung"
--[[Translation missing --]]
L["OPTIONS_HEALTHBAR"] = "Health Bar"
--[[Translation missing --]]
L["OPTIONS_HEALTHBAR_HEIGHT"] = "Health Bar Height"
--[[Translation missing --]]
L["OPTIONS_HEALTHBAR_SIZE_GLOBAL_DESC"] = [=[Change the size of Enemy and Friendly nameplates for players and npcs in combat and out of combat.

Each one of these options can be changed individually on Enemy Npc, Enemy Player tabs.]=]
--[[Translation missing --]]
L["OPTIONS_HEALTHBAR_WIDTH"] = "Health Bar Width"
--[[Translation missing --]]
L["OPTIONS_HEIGHT"] = "Height"
L["OPTIONS_HOSTILE"] = "Feindlich"
--[[Translation missing --]]
L["OPTIONS_ICON_ELITE"] = "Elite Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_ENEMYCLASS"] = "Enemy Class Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_ENEMYFACTION"] = "Enemy Faction Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_ENEMYSPEC"] = "Enemy Spec Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_FRIENDLY_SPEC"] = "Friendly Spec Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_FRIENDLYCLASS"] = "Friendly Class"
--[[Translation missing --]]
L["OPTIONS_ICON_FRIENDLYFACTION"] = "Friendly Faction Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_PET"] = "Pet Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_QUEST"] = "Quest Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_RARE"] = "Rare Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_SHOW"] = "Show Icon"
--[[Translation missing --]]
L["OPTIONS_ICON_SIDE"] = "Show Side"
--[[Translation missing --]]
L["OPTIONS_ICON_SIZE"] = "Show Size"
--[[Translation missing --]]
L["OPTIONS_ICON_WORLDBOSS"] = "World Boss Icon"
--[[Translation missing --]]
L["OPTIONS_ICONROWSPACING"] = "Icon Row Spacing"
--[[Translation missing --]]
L["OPTIONS_ICONSPACING"] = "Icon Spacing"
--[[Translation missing --]]
L["OPTIONS_INDICATORS"] = "Indicators"
--[[Translation missing --]]
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR"] = "Game object name color"
--[[Translation missing --]]
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR_DESC"] = "Names on objects will get this color."
--[[Translation missing --]]
L["OPTIONS_INTERRUPT_FILLBAR"] = "Fill Cast Bar On Interrupt"
--[[Translation missing --]]
L["OPTIONS_INTERRUPT_SHOW_ANIM"] = "Play Interrupt Animation"
--[[Translation missing --]]
L["OPTIONS_INTERRUPT_SHOW_AUTHOR"] = "Show Interrupt Author"
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_DESC"] = "Slightly adjust the size of nameplates when showing a minor unit (these units has a smaller nameplate by default)."
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_HEIGHT"] = "Minor Unit Height Scale"
--[[Translation missing --]]
L["OPTIONS_MINOR_SCALE_WIDTH"] = "Minor Unit Width Scale"
--[[Translation missing --]]
L["OPTIONS_MOVE_HORIZONTAL"] = "Move horizontally."
--[[Translation missing --]]
L["OPTIONS_MOVE_VERTICAL"] = "Move vertically."
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH"] = "Hide Blizzard Health Bars|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH_DESC"] = [=[While in dungeons or raids, if friendly nameplates are enabled it'll show only the player name.
If any Plater module is disabled, this will affect these nameplates as well.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r

|cFFFF2200[*]|r |cFFa0a0a0A /reload may be required to take effect.|r]=]
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_OFFSET"] = "Slightly adjust the entire nameplate."
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_SHOW_ENEMY"] = "Show Enemy Nameplates|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_SHOW_ENEMY_DESC"] = [=[Show nameplate for enemy and neutral units.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY"] = "Show Friendly Nameplates|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY_DESC"] = [=[Show nameplate for friendly players.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_OVERLAP"] = "Nameplate Overlap (V)|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_OVERLAP_DESC"] = [=[The space between each nameplate vertically when stacking is enabled.

|cFFFFFFFFDefault: 1.10|r

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r

|cFFFFFF00Important |r: if you find issues with this setting, use:
|cFFFFFFFF/run SetCVar ('nameplateOverlapV', '1.6')|r]=]
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_STACKING"] = "Stacking Nameplates|cFFFF7700*|r"
--[[Translation missing --]]
L["OPTIONS_NAMEPLATES_STACKING_DESC"] = [=[If enabled, nameplates won't overlap with each other.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r

|cFFFFFF00Important |r: to set the amount of space between each nameplate see '|cFFFFFFFFNameplate Vertical Padding|r' option below.
Please check the Auto tab settings to setup automatic toggling of this option.]=]
L["OPTIONS_NEUTRAL"] = "Neutral"
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_AMOUNT_DESC"] = "Amount of transparency for 'No Combat Alpha'."
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_ENABLED"] = "Use No Combat Alpha"
--[[Translation missing --]]
L["OPTIONS_NOCOMBATALPHA_ENABLED_DESC"] = [=[Changes the nameplate alpha when you are in combat and the unit isn't.

|cFFFFFF00 Important |r:If the unit isn't in combat, it overrides the alpha from the range check.]=]
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_DESC"] = [=[On updating Plater, it is common for the new version to also update scripts from the scripts tab.
This may sometimes overwrite changes made by the creator of the profile. The option below prevents Plater from modifying scripts when the addon receives an update.

Note: During major patches and bug fixes, Plater may still update scripts.]=]
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_NAME"] = "Disable non-essential script updates during Plater version upgrades."
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_SKIP_ALERT"] = "Skipped non-essential patch:"
--[[Translation missing --]]
L["OPTIONS_NOESSENTIAL_TITLE"] = "Skip Non Essential Script Patches"
--[[Translation missing --]]
L["OPTIONS_NOTHING_TO_EXPORT"] = "There's nothing to export."
L["OPTIONS_OKAY"] = "Okay"
L["OPTIONS_OUTLINE"] = "Umriss"
--[[Translation missing --]]
L["OPTIONS_PERSONAL_HEALTHBAR_HEIGHT"] = "Height of the health bar."
--[[Translation missing --]]
L["OPTIONS_PERSONAL_HEALTHBAR_WIDTH"] = "Width of the health bar."
--[[Translation missing --]]
L["OPTIONS_PERSONAL_SHOW_HEALTHBAR"] = "Show health bar."
--[[Translation missing --]]
L["OPTIONS_PET_SCALE_DESC"] = "Slightly adjust the size of nameplates when showing a pet"
--[[Translation missing --]]
L["OPTIONS_PET_SCALE_HEIGHT"] = "Pet Height Scale"
--[[Translation missing --]]
L["OPTIONS_PET_SCALE_WIDTH"] = "Pet Width Scale"
L["OPTIONS_PLEASEWAIT"] = "Dies kann einige Sekunden dauern"
--[[Translation missing --]]
L["OPTIONS_POWERBAR"] = "Power Bar"
--[[Translation missing --]]
L["OPTIONS_POWERBAR_HEIGHT"] = "Height of the power bar."
--[[Translation missing --]]
L["OPTIONS_POWERBAR_WIDTH"] = "Width of the power bar."
L["OPTIONS_PROFILE_CONFIG_EXPORTINGTASK"] = "Plater exportiert das aktuelle Profil"
L["OPTIONS_PROFILE_CONFIG_EXPORTPROFILE"] = "Profil exportieren"
L["OPTIONS_PROFILE_CONFIG_IMPORTPROFILE"] = "Profil importieren"
L["OPTIONS_PROFILE_CONFIG_MOREPROFILES"] = "Finde weitere Profile auf wago.io"
L["OPTIONS_PROFILE_CONFIG_OPENSETTINGS"] = "Profileinstellungen öffnen"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME"] = "Name des neuen Profils"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME_DESC"] = [=[Mit diesem Import-String wird ein neues Profil erstellt.
Die Angabe des Namens eines existierenden Profils wird dazu führen, dass das existierende Profil überschrieben wird.]=]
L["OPTIONS_PROFILE_ERROR_PROFILENAME"] = "Ungültiger Profilname"
L["OPTIONS_PROFILE_ERROR_STRINGINVALID"] = "Ungültige Profildatei."
L["OPTIONS_PROFILE_ERROR_WRONGTAB"] = "Ungültige Profildatei. Importiere Skripte oder Mods im Skript oder Mods-Tab."
L["OPTIONS_PROFILE_IMPORT_OVERWRITE"] = "Das Profil '%s' existiert bereits. Soll es überschrieben werden?"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NONE"] = "Nothing"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NONE_DESC"] = "No alpha modifications is applyed."
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGET"] = "Units Which Isn't Your Target"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGET_DESC"] = "When a nameplate isn't your current target, alpha is reduced."
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE"] = "Out of Range + Isn't Your Target"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE_DESC"] = [=[Reduces the alpha of units which isn't your target.
Reduces even more if the unit is out of range.]=]
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_OUTOFRANGE"] = "Units Out of Your Range"
--[[Translation missing --]]
L["OPTIONS_RANGECHECK_OUTOFRANGE_DESC"] = "When a nameplate is out of range, alpha is reduced."
--[[Translation missing --]]
L["OPTIONS_RESOURCES_TARGET"] = "Show Resources on Target"
--[[Translation missing --]]
L["OPTIONS_RESOURCES_TARGET_DESC"] = [=[Shows your resource such as combo points above your current target.
Uses Blizzard default resources and disables Platers own resources.

Character specific setting!]=]
--[[Translation missing --]]
L["OPTIONS_SCALE"] = "Scale"
--[[Translation missing --]]
L["OPTIONS_SCRIPTING_ADDOPTION"] = "Select which option to add"
--[[Translation missing --]]
L["OPTIONS_SCRIPTING_REAPPLY"] = "Re-Apply Default Values"
L["OPTIONS_SETTINGS_COPIED"] = "Einstellungen kopiert."
L["OPTIONS_SETTINGS_FAIL_COPIED"] = "Fehler beim kopieren der Einstllungen für den aktuell ausgewählten Reiter."
L["OPTIONS_SHADOWCOLOR"] = "Schatten-Farbe"
--[[Translation missing --]]
L["OPTIONS_SHIELD_BAR"] = "Shield Bar"
--[[Translation missing --]]
L["OPTIONS_SHOW_CASTBAR"] = "Show cast bar"
--[[Translation missing --]]
L["OPTIONS_SHOW_POWERBAR"] = "Show power bar"
--[[Translation missing --]]
L["OPTIONS_SHOWOPTIONS"] = "Show Options"
--[[Translation missing --]]
L["OPTIONS_SHOWSCRIPTS"] = "Show Scripts"
--[[Translation missing --]]
L["OPTIONS_SHOWTOOLTIP"] = "Show Tooltip"
--[[Translation missing --]]
L["OPTIONS_SHOWTOOLTIP_DESC"] = "Show tooltip when hovering over the aura icon."
L["OPTIONS_SIZE"] = "Größe"
--[[Translation missing --]]
L["OPTIONS_STACK_AURATIME"] = "Show shortest time of stacked auras"
--[[Translation missing --]]
L["OPTIONS_STACK_AURATIME_DESC"] = "Show shortest time of stacked auras or the longes time, when disabled."
--[[Translation missing --]]
L["OPTIONS_STACK_SIMILAR_AURAS"] = "Stack Similar Auras"
--[[Translation missing --]]
L["OPTIONS_STACK_SIMILAR_AURAS_DESC"] = "Auras with the same name (e.g. warlock's unstable affliction debuff) get stacked together."
L["OPTIONS_STATUSBAR_TEXT"] = "Profile, Mods, Skripte, Animationen und Farbtabellen können jetzt von |cFFFFAA00http://wago.io|r importiert werden."
L["OPTIONS_TABNAME_ADVANCED"] = "Erweitert"
L["OPTIONS_TABNAME_ANIMATIONS"] = "Zauberfeedback"
L["OPTIONS_TABNAME_AUTO"] = "Automatisierung"
L["OPTIONS_TABNAME_BUFF_LIST"] = "Zauberliste"
L["OPTIONS_TABNAME_BUFF_SETTINGS"] = "Buff Einstellungen"
L["OPTIONS_TABNAME_BUFF_SPECIAL"] = "Spezielle Buffs"
L["OPTIONS_TABNAME_BUFF_TRACKING"] = "Buff-Verfolgung"
L["OPTIONS_TABNAME_CASTBAR"] = "Zauberleiste"
L["OPTIONS_TABNAME_CASTCOLORS"] = "Zauberfarben und Namen"
L["OPTIONS_TABNAME_COMBOPOINTS"] = "Combo Punkte"
L["OPTIONS_TABNAME_GENERALSETTINGS"] = "Allg. Einstellungen"
L["OPTIONS_TABNAME_MODDING"] = "Modding"
L["OPTIONS_TABNAME_NPC_COLORNAME"] = "NPC Farben und Namen"
L["OPTIONS_TABNAME_NPCENEMY"] = "Feindliche NPCs"
L["OPTIONS_TABNAME_NPCFRIENDLY"] = "Freundliche NPCs"
L["OPTIONS_TABNAME_PERSONAL"] = "Pers. Ressourcen"
L["OPTIONS_TABNAME_PLAYERENEMY"] = "Feindliche Spieler"
L["OPTIONS_TABNAME_PLAYERFRIENDLY"] = "Freundliche Spieler"
L["OPTIONS_TABNAME_PROFILES"] = "Profile"
L["OPTIONS_TABNAME_SCRIPTING"] = "Skripte"
L["OPTIONS_TABNAME_SEARCH"] = "Suche"
L["OPTIONS_TABNAME_STRATA"] = "Level & Strata"
L["OPTIONS_TABNAME_TARGET"] = "Ziel"
L["OPTIONS_TABNAME_THREAT"] = "Farben / Aggro"
--[[Translation missing --]]
L["OPTIONS_TEXT_COLOR"] = "The color of the text."
--[[Translation missing --]]
L["OPTIONS_TEXT_FONT"] = "Font of the text."
--[[Translation missing --]]
L["OPTIONS_TEXT_SIZE"] = "Size of the text."
L["OPTIONS_TEXTURE"] = "Textur"
--[[Translation missing --]]
L["OPTIONS_TEXTURE_BACKGROUND"] = "Background Texture"
L["OPTIONS_THREAT_AGGROSTATE_ANOTHERTANK"] = "Greift anderen Tank an"
L["OPTIONS_THREAT_AGGROSTATE_HIGHTHREAT"] = "Hohe Bedrohung"
L["OPTIONS_THREAT_AGGROSTATE_NOAGGRO"] = "Keine Bedrohung"
L["OPTIONS_THREAT_AGGROSTATE_NOTANK"] = "Greift nicht-Tank Spieler an"
L["OPTIONS_THREAT_AGGROSTATE_NOTINCOMBAT"] = "Einheit nicht im Kampf"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO"] = "Greift dich an - niedrige Bedrohung"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO_DESC"] = "Greift dich an - kurz vor Aggro-Verlust"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_SOLID"] = "Greift dich an"
L["OPTIONS_THREAT_AGGROSTATE_TAPPED"] = "Einheit Tapped"
--[[Translation missing --]]
L["OPTIONS_THREAT_CLASSIC_USE_TANK_COLORS"] = "Use Tank Threat Colors"
L["OPTIONS_THREAT_COLOR_DPS_ANCHOR_TITLE"] = "Farbe für DPS oder Heiler Spezialisierung"
L["OPTIONS_THREAT_COLOR_DPS_HIGHTHREAT_DESC"] = "Die Einheit steht kurz davor dich anzugreifen."
L["OPTIONS_THREAT_COLOR_DPS_NOAGGRO_DESC"] = "Die Einheit greift nicht dich an."
L["OPTIONS_THREAT_COLOR_DPS_NOTANK_DESC"] = "Die Einheit greift nicht dich oder den Tank, sondern vermutlich einen Heiler oder DD deiner Gruppe an."
L["OPTIONS_THREAT_COLOR_DPS_ONYOU_SOLID_DESC"] = "Die Einheit greift dich an."
L["OPTIONS_THREAT_COLOR_OVERRIDE_ANCHOR_TITLE"] = "Überschreibe die Default-Farben"
L["OPTIONS_THREAT_COLOR_OVERRIDE_DESC"] = [=[Überschreibe die default-Farben, die das Spiel für neutrale, gegnerische und freundliche Einheiten verwendet.

Im Kampf werden diese Farben durch Bedrohungsfarben überschrieben, sofern dies zur Einfärbung der Lebensbalken aktiviert ist.]=]
L["OPTIONS_THREAT_COLOR_TANK_ANCHOR_TITLE"] = "Farbe für Tank-Spezialiserung"
L["OPTIONS_THREAT_COLOR_TANK_ANOTHERTANK_DESC"] = "Die Einheit wird von einem anderen Tank aus deiner Gruppe getankt."
L["OPTIONS_THREAT_COLOR_TANK_NOAGGRO_DESC"] = "Die Einheit hat keine Aggro auf dich."
L["OPTIONS_THREAT_COLOR_TANK_NOTINCOMBAT_DESC"] = "Die Einheit ist nicht im Kampf."
L["OPTIONS_THREAT_COLOR_TANK_ONYOU_SOLID_DESC"] = "Die Einheit greift dich an und du hast einen hohen Bedrohungsstatus."
L["OPTIONS_THREAT_COLOR_TAPPED_DESC"] = "Andere Spieler haben diese Einheit in Besitz genommen und du erhälst keine Erfahrung oder Beute für das Töten."
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK"] = "Prüfe Aggro von nicht-Tanks"
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK_DESC"] = "Wenn du als DPS oder Heiler keine Aggro hast, dann prüfe ob der Gegner eine andere Einheit, die kein Tank ist, angreift."
L["OPTIONS_THREAT_MODIFIERS_ANCHOR_TITLE"] = "Bedrohungs-Modifizierungen"
L["OPTIONS_THREAT_MODIFIERS_BORDERCOLOR"] = "Rahmenfarbe"
L["OPTIONS_THREAT_MODIFIERS_HEALTHBARCOLOR"] = "Lebensbalkenfarbe"
L["OPTIONS_THREAT_MODIFIERS_NAMECOLOR"] = "Farbe des Namens"
--[[Translation missing --]]
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK"] = "Pulling From Another Tank"
--[[Translation missing --]]
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK_TANK"] = "The unit has aggro on another tank and you're about to pull it."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_FLASH"] = "Enable aggro flash"
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_FLASH_DESC"] = "Enables the -AGGRO- flash animation on the nameplates when gaining aggro as dps."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_GLOW"] = "Enable aggro glow"
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_AGGRO_GLOW_DESC"] = "Enables the healthbar glow on the nameplates when gaining aggro as dps or losing aggro as tank."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_SOLO_COLOR"] = "Solo Color"
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_SOLO_COLOR_DESC"] = "Use the 'Solo' color when not in a group."
--[[Translation missing --]]
L["OPTIONS_THREAT_USE_SOLO_COLOR_ENABLE"] = "Use 'Solo' color"
--[[Translation missing --]]
L["OPTIONS_TOGGLE_TO_CHANGE"] = "|cFFFFFF00 Important |r: hide and show nameplates to see changes."
--[[Translation missing --]]
L["OPTIONS_WIDTH"] = "Width"
L["OPTIONS_XOFFSET"] = "X-Offset"
--[[Translation missing --]]
L["OPTIONS_XOFFSET_DESC"] = [=[Adjust the position on the X axis.

*right click to type the value.]=]
L["OPTIONS_YOFFSET"] = "Y-Offset"
--[[Translation missing --]]
L["OPTIONS_YOFFSET_DESC"] = [=[Adjust the position on the Y axis.

*right click to type the value.]=]
--[[Translation missing --]]
L[ [=[Show nameplate for friendly npcs.

|cFFFFFF00 Important |r: This option is dependent on the client`s nameplate state (on/off).

|cFFFFFF00 Important |r: when disabled but enabled on the client through (%s), the healthbar isn't visible but the nameplate is still clickable.]=] ] = [=[Show nameplate for friendly npcs.

|cFFFFFF00 Important |r: This option is dependent on the client`s nameplate state (on/off).

|cFFFFFF00 Important |r: when disabled but enabled on the client through (%s), the healthbar isn't visible but the nameplate is still clickable.]=]
--[[Translation missing --]]
L["TARGET_CVAR_ALWAYSONSCREEN"] = "Target Always on the Screen|cFFFF7700*|r"
--[[Translation missing --]]
L["TARGET_CVAR_ALWAYSONSCREEN_DESC"] = [=[When enabled, the nameplate of your target is always shown even when the enemy isn't in the screen.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
--[[Translation missing --]]
L["TARGET_CVAR_LOCKTOSCREEN"] = "Lock to Screen (Top Side)|cFFFF7700*|r"
--[[Translation missing --]]
L["TARGET_CVAR_LOCKTOSCREEN_DESC"] = [=[Min space between the nameplate and the top of the screen. Increase this if some part of the nameplate are going out of the screen.

|cFFFFFFFFDefault: 0.065|r

|cFFFFFF00 Important |r: if you're having issue, manually set using these macros:
/run SetCVar ('nameplateOtherTopInset', '0.065')
/run SetCVar ('nameplateLargeTopInset', '0.065')

|cFFFFFF00 Important |r: setting to 0 disables this feature.

|cFFFF7700[*]|r |cFFa0a0a0CVar, saved within Plater profile and restored when loading the profile.|r]=]
--[[Translation missing --]]
L["TARGET_HIGHLIGHT"] = "Target Highlight"
--[[Translation missing --]]
L["TARGET_HIGHLIGHT_ALPHA"] = "Target Highlight Alpha"
--[[Translation missing --]]
L["TARGET_HIGHLIGHT_COLOR"] = "Target Highlight Color"
--[[Translation missing --]]
L["TARGET_HIGHLIGHT_DESC"] = "Highlight effect on the nameplate of your current target."
--[[Translation missing --]]
L["TARGET_HIGHLIGHT_SIZE"] = "Target Highlight Size"
--[[Translation missing --]]
L["TARGET_HIGHLIGHT_TEXTURE"] = "Target Highlight Texture"
--[[Translation missing --]]
L["TARGET_OVERLAY_ALPHA"] = "Target Overlay Alpha"
--[[Translation missing --]]
L["TARGET_OVERLAY_TEXTURE"] = "Target Overlay Texture"
--[[Translation missing --]]
L["TARGET_OVERLAY_TEXTURE_DESC"] = "Used above the health bar when it is the current target."

end