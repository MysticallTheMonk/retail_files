
PLATYNATOR_CONFIG = {
["CharacterSpecific"] = {
},
["Version"] = 1,
["Profiles"] = {
["mysticall-midnight"] = {
["stack_region_scale_x"] = 1.2,
["design_all"] = {
},
["closer_to_screen_edges"] = true,
["cast_scale"] = 1.1,
["simplified_nameplates"] = {
["minor"] = true,
["minion"] = true,
["instancesNormal"] = true,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["designs_assigned"] = {
["friend"] = "_name-only",
["enemySimplified"] = "_hare_simplified",
["enemy"] = "_custom",
},
["obscured_alpha"] = 0.4,
["cast_alpha"] = 1,
["simplified_scale"] = 0.4,
["show_friendly_in_instances_1"] = "always",
["current_skin"] = "blizzard",
["target_scale"] = 1.2,
["apply_cvars"] = true,
["not_target_alpha"] = 1,
["click_region_scale_x"] = 1,
["global_scale"] = 1,
["show_nameplates_only_needed"] = false,
["style"] = "_custom",
["click_region_scale_y"] = 1,
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1,
["kind"] = "target",
["anchor"] = {
},
["height"] = 1,
["layer"] = 0,
["asset"] = "slight",
["width"] = 1,
},
{
["anchor"] = {
},
["color"] = {
["a"] = 1,
["r"] = 0.988235354423523,
["g"] = 0.9411765336990356,
["b"] = 1,
},
["kind"] = "mouseover",
["scale"] = 1,
["height"] = 1.2,
["layer"] = 0,
["asset"] = "bold",
["width"] = 1.03,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "bold",
["width"] = 1.01,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882351,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.2627450980392157,
["r"] = 0.0392156862745098,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["height"] = 1.05,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "LEFT",
["scale"] = 2.17,
["showCountdown"] = true,
["filters"] = {
["dispelable"] = false,
["important"] = true,
},
["anchor"] = {
"TOPLEFT",
-126.5,
14,
},
["height"] = 1,
["kind"] = "buffs",
["textScale"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
{
["direction"] = "RIGHT",
["scale"] = 1.42,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["anchor"] = {
"BOTTOMLEFT",
-65.5,
15.5,
},
["height"] = 1,
["kind"] = "crowdControl",
["textScale"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "Roboto Condensed Bold",
},
["version"] = 1,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "wide/blizzard-absorb",
},
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 0.85,
["color"] = {
["a"] = 1,
["r"] = 0.1607843190431595,
["g"] = 0.2431372702121735,
["b"] = 0.2274509966373444,
},
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.8,
},
["transition"] = {
["r"] = 1,
["g"] = 0.6274509803921569,
["b"] = 0,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
},
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["neutral"] = {
["a"] = 1,
["b"] = 0.2901960784313726,
["g"] = 0.9254901960784314,
["r"] = 1,
},
["hostile"] = {
["a"] = 1,
["b"] = 0.3725490272045136,
["g"] = 0.4823529720306397,
["r"] = 1,
},
["friendly"] = {
["a"] = 1,
["r"] = 0.8784313725490196,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["kind"] = "eliteType",
["colors"] = {
["boss"] = {
["a"] = 1,
["b"] = 0.9764706492424012,
["g"] = 1,
["r"] = 0,
},
["melee"] = {
["a"] = 1,
["r"] = 0.9882352941176472,
["g"] = 0.9882352941176472,
["b"] = 0.9882352941176472,
},
["caster"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0.4549019607843137,
["b"] = 0.7372549019607844,
},
["trivial"] = {
["a"] = 1,
["r"] = 0.6980392156862745,
["g"] = 0.5568627450980392,
["b"] = 0.3333333333333333,
},
["miniboss"] = {
["a"] = 1,
["b"] = 0.615686297416687,
["g"] = 0,
["r"] = 0.4745098352432251,
},
},
["instancesOnly"] = true,
},
{
["colors"] = {
},
["kind"] = "classColors",
},
{
["colors"] = {
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["anchor"] = {
},
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "black",
},
["kind"] = "health",
["scale"] = 1,
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 2,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["r"] = 0.1607843190431595,
["g"] = 0.2431372702121735,
["b"] = 0.2274509966373444,
},
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["notReady"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["ready"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.5137254901960784,
["g"] = 0.7529411764705882,
["b"] = 0.7647058823529411,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9882352941176472,
["g"] = 0.5490196078431373,
["b"] = 0,
},
["interrupted"] = {
["r"] = 0.9882352941176472,
["g"] = 0.211764705882353,
["b"] = 0.8784313725490196,
},
["channel"] = {
["a"] = 1,
["b"] = 0.3607843220233917,
["g"] = 0.7764706611633301,
["r"] = 0.5686274766921997,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["anchor"] = {
"TOP",
0,
-9,
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "grey",
},
["kind"] = "cast",
["interruptMarker"] = {
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "none",
},
},
},
["markers"] = {
{
["scale"] = 0.5,
["color"] = {
["r"] = 0.3921568627450981,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["anchor"] = {
"TOPLEFT",
-60,
-11.5,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["layer"] = 3,
},
{
["scale"] = 1,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"BOTTOM",
0,
20,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-78,
-10,
},
["kind"] = "castIcon",
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["widthLimit"] = 0,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["significantFigures"] = 0,
["scale"] = 1.15,
["anchor"] = {
},
["kind"] = "health",
["displayTypes"] = {
"percentage",
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["widthLimit"] = 63,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["colors"] = {
["npc"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
},
["anchor"] = {
"TOPLEFT",
-49,
-12,
},
["kind"] = "castSpellName",
["scale"] = 0.93,
["align"] = "LEFT",
},
{
["widthLimit"] = 45,
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castInterrupter",
["scale"] = 0.89,
["applyClassColors"] = true,
},
{
["widthLimit"] = 45,
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castTarget",
["scale"] = 0.89,
["applyClassColors"] = true,
},
},
},
},
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["stack_region_scale_y"] = 1.1,
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["friendlyPlayer"] = true,
["friendlyNPC"] = false,
["enemyMinion"] = true,
["enemy"] = true,
},
},
["DEFAULT"] = {
["stack_region_scale_y"] = 1.1,
["design_all"] = {
},
["closer_to_screen_edges"] = true,
["cast_scale"] = 1.1,
["simplified_nameplates"] = {
["minor"] = true,
["minion"] = true,
["instancesNormal"] = true,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["designs_assigned"] = {
["friend"] = "_name-only",
["enemySimplified"] = "_hare_simplified",
["enemy"] = "_custom",
},
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["friendlyPlayer"] = true,
["enemy"] = true,
["enemyMinion"] = true,
["friendlyNPC"] = true,
},
["stack_region_scale_x"] = 1.2,
["show_friendly_in_instances_1"] = "never",
["current_skin"] = "blizzard",
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["scale"] = 1,
["height"] = 1,
["layer"] = 0,
["anchor"] = {
},
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "target",
["asset"] = "slight",
["width"] = 1,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.9411765336990356,
["r"] = 0.988235354423523,
},
["height"] = 1.2,
["layer"] = 0,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "mouseover",
["asset"] = "bold",
["width"] = 1.03,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "bold",
["width"] = 1.01,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.09411764705882351,
["b"] = 0.1529411764705883,
},
["channel"] = {
["a"] = 1,
["r"] = 0.0392156862745098,
["g"] = 0.2627450980392157,
["b"] = 1,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["scale"] = 1,
["height"] = 1.05,
},
},
["specialBars"] = {
},
["addon"] = "Platynator",
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["height"] = 1,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["kind"] = "debuffs",
["showPandemic"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["direction"] = "LEFT",
["scale"] = 1.7,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["anchor"] = {
"LEFT",
-115,
0,
},
["kind"] = "buffs",
["height"] = 1,
["filters"] = {
["dispelable"] = false,
["important"] = true,
},
},
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["anchor"] = {
"BOTTOMRIGHT",
54,
23.5,
},
["kind"] = "crowdControl",
["height"] = 1,
["filters"] = {
["fromYou"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "Roboto Condensed Bold",
},
["version"] = 1,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "wide/blizzard-absorb",
},
["scale"] = 1,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 0.2274509966373444,
["g"] = 0.2431372702121735,
["r"] = 0.1607843190431595,
},
["height"] = 1,
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["tapped"] = {
["b"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["r"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["combatOnly"] = true,
["colors"] = {
["offtank"] = {
["b"] = 0.7843137254901961,
["g"] = 0.6666666666666666,
["r"] = 0.05882352941176471,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
["safe"] = {
["b"] = 0.9019607843137256,
["g"] = 0.5882352941176471,
["r"] = 0.05882352941176471,
},
["transition"] = {
["b"] = 0,
["g"] = 0.6274509803921569,
["r"] = 1,
},
},
["kind"] = "threat",
["instancesOnly"] = false,
["useSafeColor"] = false,
},
{
["colors"] = {
["neutral"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9254901960784314,
["b"] = 0.2901960784313726,
},
["hostile"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.4823529720306397,
["b"] = 0.3725490272045136,
},
["friendly"] = {
["a"] = 1,
["b"] = 0,
["g"] = 1,
["r"] = 0.8784313725490196,
},
},
["kind"] = "quest",
},
{
["kind"] = "eliteType",
["colors"] = {
["boss"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.9764706492424012,
},
["melee"] = {
["a"] = 1,
["b"] = 0.9882352941176472,
["g"] = 0.9882352941176472,
["r"] = 0.9882352941176472,
},
["caster"] = {
["a"] = 1,
["b"] = 0.7372549019607844,
["g"] = 0.4549019607843137,
["r"] = 0,
},
["trivial"] = {
["a"] = 1,
["b"] = 0.3333333333333333,
["g"] = 0.5568627450980392,
["r"] = 0.6980392156862745,
},
["miniboss"] = {
["a"] = 1,
["r"] = 0.4745098352432251,
["g"] = 0,
["b"] = 0.615686297416687,
},
},
["instancesOnly"] = true,
},
{
["colors"] = {
},
["kind"] = "classColors",
},
{
["colors"] = {
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["friendly"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
},
["kind"] = "reaction",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["kind"] = "health",
["anchor"] = {
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "grey",
},
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["relativeTo"] = 0,
},
{
["scale"] = 1,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 0.2274509966373444,
["g"] = 0.2431372702121735,
["r"] = 0.1607843190431595,
},
["height"] = 1,
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["notReady"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["ready"] = {
["a"] = 1,
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.7647058823529411,
["g"] = 0.7529411764705882,
["r"] = 0.5137254901960784,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.5490196078431373,
["r"] = 0.9882352941176472,
},
["interrupted"] = {
["b"] = 0.8784313725490196,
["g"] = 0.211764705882353,
["r"] = 0.9882352941176472,
},
["channel"] = {
["a"] = 1,
["r"] = 0.5686274766921997,
["g"] = 0.7764706611633301,
["b"] = 0.3607843220233917,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["kind"] = "cast",
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "grey",
},
["anchor"] = {
"TOP",
0,
-9,
},
["interruptMarker"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "none",
},
},
},
["kind"] = "style",
["markers"] = {
{
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.3921568627450981,
},
["layer"] = 3,
["scale"] = 0.5,
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["anchor"] = {
"TOPLEFT",
-60,
-11.5,
},
},
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["scale"] = 1,
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
20,
},
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-78,
-10,
},
["layer"] = 3,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["scale"] = 1,
},
},
["texts"] = {
{
["widthLimit"] = 0,
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["significantFigures"] = 0,
["align"] = "CENTER",
["anchor"] = {
},
["kind"] = "health",
["displayTypes"] = {
"percentage",
},
["scale"] = 1.15,
},
{
["widthLimit"] = 63,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["colors"] = {
["npc"] = {
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
["tapped"] = {
["b"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["r"] = 0.4313725490196079,
},
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
},
},
["anchor"] = {
"TOPLEFT",
-49,
-12,
},
["kind"] = "castSpellName",
["align"] = "LEFT",
["scale"] = 0.93,
},
{
["widthLimit"] = 45,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castInterrupter",
["scale"] = 0.89,
["applyClassColors"] = true,
},
{
["widthLimit"] = 45,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castTarget",
["scale"] = 0.89,
["applyClassColors"] = true,
},
},
},
},
["apply_cvars"] = true,
["not_target_alpha"] = 1,
["click_region_scale_y"] = 1,
["global_scale"] = 1,
["style"] = "_custom",
["show_nameplates_only_needed"] = false,
["click_region_scale_x"] = 1,
["target_scale"] = 1.2,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["simplified_scale"] = 0.4,
["cast_alpha"] = 1,
},
},
}
