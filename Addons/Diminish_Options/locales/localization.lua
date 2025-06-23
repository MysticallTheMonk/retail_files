local _, NS = ...
local L = {}
NS.L = L

-- https://wow.curseforge.com/projects/diminish/localization/

L["ANCHORDRAG"] = [=[%s
Grows: %s]=]
L["ANCHORUIPARENT"] = "Anchor to UIParent"
L["ANCHORUIPARENT_TOOLTIP"] = "Deattaches the icons from the unitframe(s) and anchors them directly to the screen (UIParent) instead. Requires re-positioning after enabling."
L["ARENA"] = "Arena"
L["ATTACH_PERSONAL_NAMEPLATE"] = "Anchor To Personal Nameplate"
L["ATTACH_PERSONAL_NAMEPLATE_TOOLTIP"] = "Attaches DR icons to your own personal resource display nameplate instead of the player frame."
L["CATEGORIES_TOOLTIP"] = "Toggle category for tracking. Right-click to manually set an icon used for the category."
L["COLORBLIND"] = "Display DR Indicator Numbers"
L["COLORBLIND_TOOLTIP"] = [=[Show DR indicator numbers next to icons. 1 = first DR, 2 = second DR, 3 = last DR. May not work with some Masque skins.
(Color Blind Mode)]=]
L["COMBATLOCKDOWN_ERROR"] = "Must leave combat or battleground before doing that."
L["COMPACTFRAMES_ERROR"] = "Unable to test raid frames while not in a group."
L["COPY"] = "Copy"
L["COPY_TOOLTIP"] = "Copies settings from one existing profile into the currently active profile."
L["CURRENT_PROFILE"] = "Current Profile: |cffFFEB00%s|r"
L["DEFAULT"] = "Default"
L["DELETE"] = "Delete"
L["DELETE_TOOLTIP"] = "Delete an existing profile. Deletes and resets to default if the profile chosen is the currently active one."
L["DISPLAYMODE"] = "Start Cooldown on Aura Removed"
L["DISPLAYMODE_TOOLTIP"] = "Start timers on aura removed or refresh instead of applied. Leave unchecked to see timer immediately. (Timers will be 18sec + aura duration.)"
L["ENABLED"] = "Enabled"
L["ENABLED_TOOLTIP"] = "Toggle diminishing returns tracking for this specific unit frame."
L["FOCUS"] = "Focus"
L["GROW_BOTTOM"] = "Down"
L["GROW_LEFT"] = "Left"
L["GROW_RIGHT"] = "Right"
L["GROW_TOP"] = "Up"
L["GROWDIRECTION"] = "Grow Direction"
L["GROWDIRECTION_TOOLTIP"] = "Select which direction the icons will grow from the anchor."
L["HEADER_CATEGORIES"] = "Enabled Categories"
L["HEADER_COOLDOWN"] = "Cooldown"
L["HEADER_ICONS"] = "Icons"
L["HEADER_MISC"] = "Misc"
L["HEADER_PROFILES"] = "Create and set configuration profiles so you can have different settings for every character. Creating new profiles will consume more memory so try to reuse profiles whenever possible. See tooltips for detailed info."
L["HEADER_UNITFRAME"] = "Configuration for %s frame tracking."
L["HEADER_ZONE"] = "Enable in Zone"
L["ICONPADDING"] = "Frame Padding"
L["ICONPADDING_TOOLTIP"] = "Set the padding between all active icons."
L["ICONSIZE"] = "Frame Size"
L["ICONSIZE_TOOLTIP"] = "Set the size of the icons."
L["INVALID_SPELLID"] = "Invalid spell ID."
L["NAMEPLATE"] = "Nameplates"
L["NAMEPLATES"] = "Nameplates"
L["NEWPROFILE"] = "Create New Profile"
L["NEWPROFILE_TOOLTIP"] = "Create a new profile with current active settings as a starting point."
L["PARTY"] = "Party"
L["PLAYER"] = "Player"
L["PROFILEACTIVE"] = "That profile is already active."
L["PROFILEEXISTS"] = "Profile with that name already exists."
L["PROFILES"] = "Profiles"
L["RESET"] = "Reset."
L["RESETPOS"] = "Reset Position"
L["RESETPOS_TOOLTIP"] = "Reset icon positions for this unitframe back to default values."
L["RESETPROFILE"] = "Reset Profile"
L["RESETPROFILE_TOOLTIP"] = "Reset current active profile to default settings."
L["SELECTBORDER"] = "Select Border Style"
L["SELECTBORDER_TOOLTIP"] = "Choose between different border textures for the icons. You may also skin the icons using Masque."
L["SELECTPROFILE"] = "Select Profile"
L["SELECTPROFILE_TOOLTIP"] = "Select a profile to use, copy or delete."
L["SHOWCATEGORYTEXT"] = "Display DR Category Label"
L["SHOWCATEGORYTEXT_TOOLTIP"] = "Show text above a timer that displays what diminishing returns category a timer belongs to."
L["STOP"] = "Stop"
L["TARGET"] = "Target"
L["TARGETTIP"] = "Target/focus yourself to see all frames."
L["TEST"] = "Toggle Test Mode"
L["TEST_TOOLTIP"] = "Test all enabled frames."
L["TEXTURE_BRIGHT"] = "Bright"
L["TEXTURE_GLOW"] = "Default, with glow"
L["TEXTURE_NONE"] = "None"
L["TEXTURECHANGE"] = "Manually set icon texture used for %s. This will affect all unit frames. Enter spell ID for ability, or leave blank to reset:"
L["TEXTURECHANGE_NOTE"] = "|cFF00FF00Right-Click a checkbox to manually select spell texture.|r"
L["TIMERCOLORS"] = "Show Indicator Color on Countdown"
L["TIMERCOLORS_TOOLTIP"] = "Toggles diminishing returns indicator coloring of the countdown text."
L["TIMEREDGE"] = "Show Edge Effect on Swipe"
L["TIMEREDGE_TOOLTIP"] = "Sets whether a bright line should be drawn on the moving edge of the cooldown animation effect."
L["TIMEROUTLINE"] = "Font Outline"
L["TIMEROUTLINE_TOOLTIP"] = "Set the font outline for the cooldown countdown text."
L["TIMERSWIPE"] = "Show Swipe for Cooldowns"
L["TIMERSWIPE_TOOLTIP"] = "Toggles the cooldown swipe animation for all frames."
L["TIMERTEXT"] = "Show Countdown for Cooldowns"
L["TIMERTEXT_TOOLTIP"] = [=[Toggles the cooldown countdown text for all timers.

(Esc -> Interface -> ActionBars -> Show Numbers for Cooldowns)]=]
L["TIMERTEXTSIZE"] = "Countdown Size"
L["TIMERTEXTSIZE_TOOLTIP"] = "Set the font size of the timer countdown text."
L["TRACKNPCS"] = "Enable Tracking for PvE"
L["TRACKNPCS_TOOLTIP"] = [=[Enable diminishing returns tracking for mobs and player pets. (Target/Focus/Nameplates)

Enabling this may drastically increase memory usage in large battlefields.]=]
L["UNLOCK"] = "Toggle Moving Frames"
L["UNLOCK_TOOLTIP"] = "Toggle enabled frames for moving. Drag the red boxes to move icon spawn points."
L["USEPROFILE"] = "Use"
L["USEPROFILE_TOOLTIP"] = [=[Set an existing profile to use for this character.

Any modifications to the profile will affect all characters using the profile.]=]
L["WATCHFRIENDLY"] = "Show Friendly DRs"
L["WATCHFRIENDLY_TOOLTIP"] = [=[Toggle diminishing returns tracking for friendly players. (Cast by enemy onto friendly)

Enabling this may drastically increase memory usage in large Battlegrounds.]=]
L["ZONE_ARENA"] = "Arena"
L["ZONE_BATTLEGROUNDS"] = "Battlegrounds & Brawls"
L["ZONE_DUNGEONS"] = "Dungeons"
L["ZONE_OUTDOORS"] = "World"
L["ZONE_SCENARIO"] = "Scenario"
L["ZONE_RAIDS"] = "Raids"
L["ZONES_TOOLTIP"] = "Enable tracking for this zone."
