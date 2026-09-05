-- tab size is 4
-- registrations for media from the client itself belongs in LibSharedMedia-3.0

local LSM = LibStub("LibSharedMedia-3.0")
local koKR, ruRU, zhCN, zhTW, western = LSM.LOCALE_BIT_koKR, LSM.LOCALE_BIT_ruRU, LSM.LOCALE_BIT_zhCN, LSM.LOCALE_BIT_zhTW, LSM.LOCALE_BIT_western

local MediaType_BACKGROUND = LSM.MediaType.BACKGROUND
local MediaType_BORDER = LSM.MediaType.BORDER
local MediaType_FONT = LSM.MediaType.FONT
local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR

-- -----
-- BACKGROUND
-- -----
LSM:Register(MediaType_BACKGROUND, "Moo", [[Interface\Addons\SharedMedia\background\moo.tga]])
LSM:Register(MediaType_BACKGROUND, "Bricks", [[Interface\Addons\SharedMedia\background\bricks.tga]])
LSM:Register(MediaType_BACKGROUND, "Brushed Metal", [[Interface\Addons\SharedMedia\background\brushedmetal.tga]])
LSM:Register(MediaType_BACKGROUND, "Copper", [[Interface\Addons\SharedMedia\background\copper.tga]])
LSM:Register(MediaType_BACKGROUND, "Smoke", [[Interface\Addons\SharedMedia\background\smoke.tga]])

-- -----
--  BORDER
-- ----
LSM:Register(MediaType_BORDER, "RothSquare", [[Interface\Addons\SharedMedia\border\roth.tga]])
LSM:Register(MediaType_BORDER, "SeerahScalloped", [[Interface\Addons\SharedMedia\border\SeerahScalloped.blp]])

-- -----
--   FONT
-- -----
LSM:Register(MediaType_FONT, "Adventure",					[[Interface\Addons\SharedMedia\fonts\adventure\Adventure.ttf]])
LSM:Register(MediaType_FONT, "All Hooked Up",				[[Interface\Addons\SharedMedia\fonts\all_hooked_up\HookedUp.ttf]])
LSM:Register(MediaType_FONT, "Bazooka",						[[Interface\Addons\SharedMedia\fonts\bazooka\Bazooka.ttf]])
LSM:Register(MediaType_FONT, "Black Chancery",				[[Interface\Addons\SharedMedia\fonts\black_chancery\BlackChancery.ttf]])
LSM:Register(MediaType_FONT, "Celestia Medium Redux",		[[Interface\Addons\SharedMedia\fonts\celestia_medium_redux\CelestiaMediumRedux1.55.ttf]])
LSM:Register(MediaType_FONT, "DejaVu Sans",					[[Interface\Addons\SharedMedia\fonts\deja_vu\DejaVuLGCSans.ttf]],							ruRU + western)
LSM:Register(MediaType_FONT, "DejaVu Serif",				[[Interface\Addons\SharedMedia\fonts\deja_vu\DejaVuLGCSerif.ttf]],							ruRU + western)
LSM:Register(MediaType_FONT, "DorisPP",						[[Interface\Addons\SharedMedia\fonts\doris_pp\DorisPP.ttf]])
LSM:Register(MediaType_FONT, "Enigmatic",					[[Interface\Addons\SharedMedia\fonts\enigmatic\EnigmaU_2.ttf]])
LSM:Register(MediaType_FONT, "Fitzgerald",					[[Interface\Addons\SharedMedia\fonts\fitzgerald\Fitzgerald.ttf]])
LSM:Register(MediaType_FONT, "Gentium Plus",				[[Interface\Addons\SharedMedia\fonts\gentium_plus\GentiumPlus-Regular.ttf]],				ruRU + western)
LSM:Register(MediaType_FONT, "Hack",						[[Interface\Addons\SharedMedia\fonts\hack\Hack-Regular.ttf]])
LSM:Register(MediaType_FONT, "Liberation Mono",				[[Interface\Addons\SharedMedia\fonts\liberation\LiberationMono-Regular.ttf]],				ruRU + western)
LSM:Register(MediaType_FONT, "Liberation Sans",				[[Interface\Addons\SharedMedia\fonts\liberation\LiberationSans-Regular.ttf]],				ruRU + western)
LSM:Register(MediaType_FONT, "Liberation Serif",			[[Interface\Addons\SharedMedia\fonts\liberation\LiberationSerif-Regular.ttf]],				ruRU + western)
LSM:Register(MediaType_FONT, "SF Atarian System",			[[Interface\Addons\SharedMedia\fonts\sf_atarian_system\SFAtarianSystem.ttf]])
LSM:Register(MediaType_FONT, "SF Covington",				[[Interface\Addons\SharedMedia\fonts\sf_covington\SFCovington.ttf]])
LSM:Register(MediaType_FONT, "SF Movie Poster",				[[Interface\Addons\SharedMedia\fonts\sf_movie_poster\SFMoviePoster-Bold.ttf]])
LSM:Register(MediaType_FONT, "SF Wonder Comic",				[[Interface\Addons\SharedMedia\fonts\sf_wonder_comic\SFWonderComic.ttf]])
LSM:Register(MediaType_FONT, "swf!t",						[[Interface\Addons\SharedMedia\fonts\swf!t\SWF!T___.ttf]])
LSM:Register(MediaType_FONT, "TeX Gyre Adventor",			[[Interface\Addons\SharedMedia\fonts\tex_gyre_adventor\texgyreadventor-regular.otf]])
LSM:Register(MediaType_FONT, "TeX Gyre Adventor Bold",		[[Interface\Addons\SharedMedia\fonts\tex_gyre_adventor\texgyreadventor-bold.otf]])
LSM:Register(MediaType_FONT, "WenQuanYi Zen Hei",			[[Interface\Addons\SharedMedia\fonts\wen_quan_yi_zen_hei\wqy-zenhei.ttf]],					koKR + ruRU + zhCN + zhTW + western)
LSM:Register(MediaType_FONT, "Yellowjacket",				[[Interface\Addons\SharedMedia\fonts\yellowjacket\yellow.ttf]])

-- -----
--   SOUND
-- -----

-- -----
--   STATUSBAR
-- -----
LSM:Register(MediaType_STATUSBAR, "Aluminium",			[[Interface\Addons\SharedMedia\statusbar\Aluminium]])
LSM:Register(MediaType_STATUSBAR, "Armory",				[[Interface\Addons\SharedMedia\statusbar\Armory]])
LSM:Register(MediaType_STATUSBAR, "BantoBar",			[[Interface\Addons\SharedMedia\statusbar\BantoBar]])
LSM:Register(MediaType_STATUSBAR, "Bars",				[[Interface\Addons\SharedMedia\statusbar\Bars]])
LSM:Register(MediaType_STATUSBAR, "Bumps",				[[Interface\Addons\SharedMedia\statusbar\Bumps]])
LSM:Register(MediaType_STATUSBAR, "Button",				[[Interface\Addons\SharedMedia\statusbar\Button]])
LSM:Register(MediaType_STATUSBAR, "Charcoal",			[[Interface\Addons\SharedMedia\statusbar\Charcoal]])
LSM:Register(MediaType_STATUSBAR, "Cilo",				[[Interface\Addons\SharedMedia\statusbar\Cilo]])
LSM:Register(MediaType_STATUSBAR, "Cloud",				[[Interface\Addons\SharedMedia\statusbar\Cloud]])
LSM:Register(MediaType_STATUSBAR, "Comet",				[[Interface\Addons\SharedMedia\statusbar\Comet]])
LSM:Register(MediaType_STATUSBAR, "Dabs",				[[Interface\Addons\SharedMedia\statusbar\Dabs]])
LSM:Register(MediaType_STATUSBAR, "DarkBottom",			[[Interface\Addons\SharedMedia\statusbar\DarkBottom]])
LSM:Register(MediaType_STATUSBAR, "Diagonal",			[[Interface\Addons\SharedMedia\statusbar\Diagonal]])
LSM:Register(MediaType_STATUSBAR, "Empty",			    [[Interface\Addons\SharedMedia\statusbar\Empty]])
LSM:Register(MediaType_STATUSBAR, "Falumn",				[[Interface\Addons\SharedMedia\statusbar\Falumn]])
LSM:Register(MediaType_STATUSBAR, "Fifths",				[[Interface\Addons\SharedMedia\statusbar\Fifths]])
LSM:Register(MediaType_STATUSBAR, "Flat",				[[Interface\Addons\SharedMedia\statusbar\Flat]])
LSM:Register(MediaType_STATUSBAR, "Fourths",			[[Interface\Addons\SharedMedia\statusbar\Fourths]])
LSM:Register(MediaType_STATUSBAR, "Frost",				[[Interface\Addons\SharedMedia\statusbar\Frost]])
LSM:Register(MediaType_STATUSBAR, "Glamour",			[[Interface\Addons\SharedMedia\statusbar\Glamour]])
LSM:Register(MediaType_STATUSBAR, "Glamour2",			[[Interface\Addons\SharedMedia\statusbar\Glamour2]])
LSM:Register(MediaType_STATUSBAR, "Glamour3",			[[Interface\Addons\SharedMedia\statusbar\Glamour3]])
LSM:Register(MediaType_STATUSBAR, "Glamour4",			[[Interface\Addons\SharedMedia\statusbar\Glamour4]])
LSM:Register(MediaType_STATUSBAR, "Glamour5",			[[Interface\Addons\SharedMedia\statusbar\Glamour5]])
LSM:Register(MediaType_STATUSBAR, "Glamour6",			[[Interface\Addons\SharedMedia\statusbar\Glamour6]])
LSM:Register(MediaType_STATUSBAR, "Glamour7",			[[Interface\Addons\SharedMedia\statusbar\Glamour7]])
LSM:Register(MediaType_STATUSBAR, "Glass",				[[Interface\Addons\SharedMedia\statusbar\Glass]])
LSM:Register(MediaType_STATUSBAR, "Glaze",				[[Interface\Addons\SharedMedia\statusbar\Glaze]])
LSM:Register(MediaType_STATUSBAR, "Glaze v2",			[[Interface\Addons\SharedMedia\statusbar\Glaze2]])
LSM:Register(MediaType_STATUSBAR, "Gloss",				[[Interface\Addons\SharedMedia\statusbar\Gloss]])
LSM:Register(MediaType_STATUSBAR, "Graphite",			[[Interface\Addons\SharedMedia\statusbar\Graphite]])
LSM:Register(MediaType_STATUSBAR, "Grid",				[[Interface\Addons\SharedMedia\statusbar\Grid]])
LSM:Register(MediaType_STATUSBAR, "Hatched",			[[Interface\Addons\SharedMedia\statusbar\Hatched]])
LSM:Register(MediaType_STATUSBAR, "Healbot",			[[Interface\Addons\SharedMedia\statusbar\Healbot]])
LSM:Register(MediaType_STATUSBAR, "Lyfe",				[[Interface\Addons\SharedMedia\statusbar\Lyfe]])
LSM:Register(MediaType_STATUSBAR, "LiteStep",			[[Interface\Addons\SharedMedia\statusbar\LiteStep]])
LSM:Register(MediaType_STATUSBAR, "LiteStepLite",		[[Interface\Addons\SharedMedia\statusbar\LiteStepLite]])
LSM:Register(MediaType_STATUSBAR, "Melli",				[[Interface\Addons\SharedMedia\statusbar\Melli]])
LSM:Register(MediaType_STATUSBAR, "Melli Dark",			[[Interface\Addons\SharedMedia\statusbar\MelliDark]])
LSM:Register(MediaType_STATUSBAR, "Melli Dark Rough",	[[Interface\Addons\SharedMedia\statusbar\MelliDarkRough]])
LSM:Register(MediaType_STATUSBAR, "Minimalist",			[[Interface\Addons\SharedMedia\statusbar\Minimalist]])
LSM:Register(MediaType_STATUSBAR, "Otravi",				[[Interface\Addons\SharedMedia\statusbar\Otravi]])
LSM:Register(MediaType_STATUSBAR, "Outline",			[[Interface\Addons\SharedMedia\statusbar\Outline]])
LSM:Register(MediaType_STATUSBAR, "Perl",				[[Interface\Addons\SharedMedia\statusbar\Perl]])
LSM:Register(MediaType_STATUSBAR, "Perl v2",			[[Interface\Addons\SharedMedia\statusbar\Perl2]])
LSM:Register(MediaType_STATUSBAR, "Pill",				[[Interface\Addons\SharedMedia\statusbar\Pill]])
LSM:Register(MediaType_STATUSBAR, "Rain",				[[Interface\Addons\SharedMedia\statusbar\Rain]])
LSM:Register(MediaType_STATUSBAR, "Rocks",				[[Interface\Addons\SharedMedia\statusbar\Rocks]])
LSM:Register(MediaType_STATUSBAR, "Round",				[[Interface\Addons\SharedMedia\statusbar\Round]])
LSM:Register(MediaType_STATUSBAR, "Ruben",				[[Interface\Addons\SharedMedia\statusbar\Ruben]])
LSM:Register(MediaType_STATUSBAR, "Runes",				[[Interface\Addons\SharedMedia\statusbar\Runes]])
LSM:Register(MediaType_STATUSBAR, "Skewed",				[[Interface\Addons\SharedMedia\statusbar\Skewed]])
LSM:Register(MediaType_STATUSBAR, "Smooth",				[[Interface\Addons\SharedMedia\statusbar\Smooth]])
LSM:Register(MediaType_STATUSBAR, "Smooth v2",			[[Interface\Addons\SharedMedia\statusbar\Smoothv2]])
LSM:Register(MediaType_STATUSBAR, "Smudge",				[[Interface\Addons\SharedMedia\statusbar\Smudge]])
LSM:Register(MediaType_STATUSBAR, "Steel",				[[Interface\Addons\SharedMedia\statusbar\Steel]])
LSM:Register(MediaType_STATUSBAR, "Striped",			[[Interface\Addons\SharedMedia\statusbar\Striped]])
LSM:Register(MediaType_STATUSBAR, "Tube",				[[Interface\Addons\SharedMedia\statusbar\Tube]])
LSM:Register(MediaType_STATUSBAR, "Water",				[[Interface\Addons\SharedMedia\statusbar\Water]])
LSM:Register(MediaType_STATUSBAR, "Wglass",				[[Interface\Addons\SharedMedia\statusbar\Wglass]])
LSM:Register(MediaType_STATUSBAR, "Wisps",				[[Interface\Addons\SharedMedia\statusbar\Wisps]])
LSM:Register(MediaType_STATUSBAR, "Xeon",				[[Interface\Addons\SharedMedia\statusbar\Xeon]])
