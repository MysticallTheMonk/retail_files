-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local emptyTable = {};

local MAX_LOAD_TRIES    = 10;
local TEAM_ICON_PATH    = "Interface\\Addons\\"..addonName.."\\textures\\";
local BATTLE_PET_PSEUDO = "BattlePet-0-P%011X"
local NEW_TEAM_ICON = "Interface\\Addons\\Niggles-PetTeams\\textures\\NewTeam";
local PET_BATTLE_ICON = "Interface\\ICONS\\PetJournalPortrait";

-- Info for opponents
local opponentQuality =
{
  RARE_BLUE_COLOR,
  EPIC_PURPLE_COLOR,
  LEGENDARY_ORANGE_COLOR,
};

-- Info for opponents
local opponentInfo =
{
  {id = 0, name = L["Any Opponent"], mId = 0, petId = {}},
  {id = 1, name = L["PvP Opponents"], mId = 0, petId = {}},
  {id = 63194, name = L["Steven Lisbane"], mId = 50, petId = {885, 884, 883}},
  {id = 64330, name = L["Julia Stevens"], mId = 37, petId = {873, 872}},
  {id = 65648, name = L["Old MacDonald"], mId = 52, petId = {876, 875, 874}},
  {id = 65651, name = L["Lindsay"], mId = 49, petId = {879, 878, 877}},
  {id = 65655, name = L["Eric Davidson"], mId = 47, petId = {882, 881, 880}},
  {id = 65656, name = L["Bill Buckler"], mId = 210, petId = {888, 887, 886}},
  {id = 66126, name = L["Zunta"], mId = 1, petId = {890, 889}},
  {id = 66135, name = L["Dagra the Fierce"], mId = 10, petId = {893, 892, 891}},
  {id = 66136, name = L["Analynn"], mId = 63, petId = {896, 895, 894}},
  {id = 66137, name = L["Zonya the Sadist"], mId = 65, petId = {899, 898, 897}},
  {id = 66352, name = L["Traitor Gluk"], mId = 69, petId = {906, 905, 904}},
  {id = 66372, name = L["Merda Stronghoof"], mId = 66, petId = {902, 901, 900}},
  {id = 66412, name = L["Elena Flutterfly"], mId = 80, petId = {926, 925, 924}},
  {id = 66422, name = L["Cassandra Kaboom"], mId = 199, petId = {909, 908, 907}},
  {id = 66436, name = L["Grazzle the Great"], mId = 70, petId = {913, 912, 911}},
  {id = 66442, name = L["Zoltan"], mId = 77, petId = {923, 922, 921}},
  {id = 66452, name = L["Kela Grimtotem"], mId = 64, petId = {917, 916, 915}},
  {id = 66466, name = L["Stone Cold Trixxy"], mId = 83, petId = {929, 928, 927}},
  {id = 66478, name = L["David Kosse"], mId = 26, petId = {933, 932, 931}},
  {id = 66512, name = L["Deiza Plaguehorn"], mId = 23, petId = {936, 935, 934}},
  {id = 66515, name = L["Kortas Darkhammer"], mId = 32, petId = {939, 938, 937}},
  {id = 66518, name = L["Everessa"], mId = 51, petId = {943, 942, 941}},
  {id = 66520, name = L["Durin Darkhammer"], mId = 36, petId = {946, 945, 944}},
  {id = 66522, name = L["Lydia Accoste"], mId = 42, petId = {949, 948, 947}},
  {id = 66550, name = L["Nicki Tinytech"], mId = 100, petId = {952, 951, 950}},
  {id = 66551, name = L["Ras'an"], mId = 102, petId = {955, 954, 953}},
  {id = 66552, name = L["Narrok"], mId = 107, petId = {958, 957, 956}},
  {id = 66553, name = L["Morulu The Elder"], mId = 111, petId = {961, 960, 959}},
  {id = 66557, name = L["Bloodknight Antari"], mId = 104, petId = {964, 963, 962}},
  {id = 66635, name = L["Beegle Blastfuse"], mId = 117, petId = {967, 966, 965}},
  {id = 66636, name = L["Nearly Headless Jacob"], mId = 127, petId = {970, 969, 968}},
  {id = 66638, name = L["Okrut Dragonwaste"], mId = 115, petId = {973, 972, 971}},
  {id = 66639, name = L["Gutretch"], mId = 121, petId = {976, 975, 974}},
  {id = 66675, name = L["Major Payne"], mId = 118, petId = {979, 978, 977}},
  {id = 66730, name = L["Hyuna of the Shrines"], mId = 371, petId = {994, 993, 992}},
  {id = 66733, name = L["Mo'ruk"], mId = 418, petId = {998, 1000, 999}},
  {id = 66734, name = L["Farmer Nishi"], mId = 376, petId = {997, 996, 995}},
  {id = 66738, name = L["Courageous Yon"], mId = 379, petId = {1003, 1002, 1001}},
  {id = 66739, name = L["Wastewalker Shu"], mId = 422, petId = {1009, 1008, 1007}},
  {id = 66741, name = L["Aki the Chosen"], mId = 390, petId = {1012, 1011, 1010}},
  {id = 66815, name = L["Bordin Steadyfist"], mId = 207, petId = {985, 984, 983}},
  {id = 66819, name = L["Brok"], mId = 198, petId = {982, 981, 980}},
  {id = 66822, name = L["Goz Banefury"], mId = 241, petId = {988, 987, 986}},
  {id = 66824, name = L["Obalis"], mId = 249, petId = {991, 990, 989}},
  {id = 66918, name = L["Seeker Zusshi"], mId = 388, petId = {1006, 1005, 1004}},
  {id = 67370, name = L["Jeremy Feasel"], mId = 407, petId = {1065, 1067, 1066}},
  {id = 68462, name = L["Flowing Pandaren Spirit"], mId = 422, petId = {1132, 1133, 1138}},
  {id = 68463, name = L["Burning Pandaren Spirit"], mId = 388, petId = {1130, 1139, 1131}},
  {id = 68464, name = L["Whispering Pandaren Spirit"], mId = 371, petId = {1135, 1136, 1140}},
  {id = 68465, name = L["Thundering Pandaren Spirit"], mId = 379, petId = {1141, 1134, 1137}},
  {id = 68555, flags = 3, mId = 371, petId = {1129}},
  {id = 68558, flags = 3, mId = 422, petId = {1187}},
  {id = 68559, flags = 3, mId = 390, petId = {1188}},
  {id = 68560, flags = 3, mId = 376, petId = {1189}},
  {id = 68561, flags = 3, mId = 376, petId = {1190}},
  {id = 68562, flags = 3, mId = 388, petId = {1191}},
  {id = 68563, flags = 3, mId = 379, petId = {1192}},
  {id = 68564, flags = 3, mId = 379, petId = {1193}},
  {id = 68565, flags = 3, mId = 371, petId = {1194}},
  {id = 68566, flags = 3, mId = 418, petId = {1195}},
  {id = 71924, name = L["Wrathion"], mId = 571, petId = {1299, 1301, 1300}},
  {id = 71926, name = L["Lorewalker Cho"], mId = 571, petId = {1285, 1284, 1283}},
  {id = 71927, name = L["Chen Stormstout"], mId = 571, petId = {1282, 1281, 1280}},
  {id = 71929, name = L["Sully \"The Pickle\" McLeary"], mId = 571, petId = {1291, 1289, 1290}},
  {id = 71930, name = L["Shademaster Kiryn"], mId = 571, petId = {1288, 1287, 1286}},
  {id = 71931, name = L["Taran Zhu"], mId = 571, petId = {1295, 1293, 1292}},
  {id = 71932, name = L["Wise Mari"], mId = 571, petId = {1296, 1298, 1297}},
  {id = 71933, name = L["Blingtron 4000"], mId = 571, petId = {1278, 1279, 1277}},
  {id = 71934, name = L["Dr. Ion Goldbloom"], mId = 571, petId = {1269, 1271, 1268}},
  {id = 72009, flags = 3, mId = 571, petId = {1267}},
  {id = 72285, flags = 3, mId = 571, petId = {1311}},
  {id = 72290, flags = 3, mId = 571, petId = {1319}},
  {id = 72291, flags = 3, mId = 571, petId = {1317}},
  {id = 73626, name = L["Little Tommy Newcomer"], mId = 554, petId = {1339}},
  {id = 79179, name = L["Squirt"], mId = 582, petId = {1400, 1401, 1402}},
  {id = 79751, flags = 3, mId = 582, petId = {1409}},
  {id = 83837, name = L["Cymre Brightblade"], mId = 543, petId = {1443, 1444, 1424}},
  {id = 85519, name = L["Christoph VonFeasel"], mId = 407, petId = {1477, 1476, 1475}},
  {id = 85561, flags = 3, mId = 582, petId = {1479, 1482}},
  {id = 85650, flags = 3, mId = 582, petId = {1480}},
  {id = 85656, flags = 3, mId = 582, petId = {1483, 1484, 1485}},
  {id = 85659, flags = 3, mId = 582, petId = {1486}},
  {id = 85660, flags = 3, mId = 582, petId = {1488, 1487}},
  {id = 85662, flags = 3, mId = 582, petId = {1489, 1490}},
  {id = 85664, flags = 3, mId = 582, petId = {1492, 1494, 1493}},
  {id = 85674, flags = 3, mId = 582, petId = {1496, 1497, 1498}},
  {id = 85677, flags = 3, mId = 582, petId = {1500, 1499}},
  {id = 85679, flags = 3, mId = 582, petId = {1501, 1502, 1503}},
  {id = 85682, flags = 3, mId = 582, petId = {1504, 1505, 1506}},
  {id = 85685, flags = 3, mId = 582, petId = {1507}},
  {id = 85686, flags = 3, mId = 582, petId = {1508, 1509, 1510}},
  {id = 87110, name = L["Tarr the Terrible"], mId = 550, petId = {1555, 1554, 1556}},
  {id = 87122, name = L["Gargra"], mId = 525, petId = {1550, 1552, 1553}},
  {id = 87123, name = L["Vesharr"], mId = 542, petId = {1558, 1559, 1557}},
  {id = 87124, name = L["Ashlei"], mId = 539, petId = {1547, 1548, 1549}},
  {id = 87125, name = L["Taralune"], mId = 535, petId = {1560, 1561, 1562}},
  {id = 90675, name = L["Erris the Collector"], mId = 582, petId = {1640, 1641, 1642}},
  {id = 91014, name = L["Erris the Collector"], mId = 582, petId = {1637, 1643, 1644}},
  {id = 91015, name = L["Erris the Collector"], mId = 582, petId = {1646, 1645, 1647}},
  {id = 91016, name = L["Erris the Collector"], mId = 582, petId = {1648, 1651, 1649}},
  {id = 91017, name = L["Erris the Collector"], mId = 582, petId = {1654, 1653, 1652}},
  {id = 94601, flags = 3, mId = 534, petId = {1671}},
  {id = 94637, flags = 3, mId = 534, petId = {1673}},
  {id = 94638, flags = 3, mId = 534, petId = {1674}},
  {id = 94639, flags = 3, mId = 534, petId = {1675}},
  {id = 94640, flags = 3, mId = 534, petId = {1676}},
  {id = 94641, flags = 3, mId = 534, petId = {1677}},
  {id = 94642, flags = 3, mId = 534, petId = {1678}},
  {id = 94643, flags = 3, mId = 534, petId = {1679}},
  {id = 94644, flags = 3, mId = 534, petId = {1680}},
  {id = 94645, flags = 3, mId = 534, petId = {1681}},
  {id = 94646, flags = 3, mId = 534, petId = {1682}},
  {id = 94647, flags = 3, mId = 534, petId = {1683}},
  {id = 94648, flags = 3, mId = 534, petId = {1684}},
  {id = 94649, flags = 3, mId = 534, petId = {1685}},
  {id = 94650, flags = 3, mId = 534, petId = {1686}},
  {id = 97709, flags = 3, mId = 680, petId = {1742}},
  {id = 97804, name = L["Tiffany Nelson"], mId = 630, petId = {1748, 1746, 1745}},
  {id = 98270, name = L["Robert Craig"], mId = 634, petId = {1770, 1772, 1771}},
  {id = 98572, flags = 3, mId = 650, petId = {1811}},
  {id = 99035, name = L["Durian Strongfruit"], mId = 641, petId = {1789, 1787, 1788}},
  {id = 99077, name = L["Bredda Tenderhide"], mId = 650, petId = {1790, 1791, 1792}},
  {id = 99150, name = L["Grixis Tinypop"], mId = 650, petId = {1798, 1793, 1794}},
  {id = 99182, name = L["Sir Galveston"], mId = 630, petId = {1795, 1796, 1797}},
  {id = 99210, name = L["Bodhi Sunwayver"], mId = 630, petId = {1800, 1801, 1799}},
  {id = 99742, flags = 3, mId = 630, petId = {1815}},
  {id = 99878, name = L["Ominitron Defense System"], mId = 634, petId = {1816, 1817, 1818}},
  {id = 104553, name = L["Odrogg"], mId = 650, petId = {1842, 1841, 1840}},
  {id = 104782, flags = 3, mId = 650, petId = {1843}},
  {id = 104970, name = L["Xorvasc"], mId = 641, petId = {1847, 1846, 1848}},
  {id = 104992, flags = 3, mId = 641, petId = {1849}},
  {id = 105009, flags = 3, mId = 641, petId = {1850}},
  {id = 105093, name = L["Fragment of Fire"], mId = 641, petId = {1851, 1852, 1853}},
  {id = 105241, flags = 3, mId = 630, petId = {1855}},
  {id = 105250, name = L["Aulier"], mId = 680, petId = {1857, 1858, 1859}},
  {id = 105323, name = L["Ancient Catacomb Eggs"], mId = 680, petId = {1860, 1861, 1862}},
  {id = 105352, name = L["Surging Mana Crystal"], mId = 680, petId = {1863, 1864, 1865}},
  {id = 105386, name = L["Rydyr"], mId = 634, petId = {1866}},
  {id = 105387, name = L["Andurs"], mId = 634, petId = {1867}},
  {id = 105455, name = L["Trapper Jarrun"], mId = 634, petId = {1868, 1869, 1870}},
  {id = 105512, name = L["Envoy of the Hunt"], mId = 634, petId = {1871, 1872}},
  {id = 105674, name = L["Varenne"], mId = 680, petId = {1873, 1874, 1875}},
  {id = 105779, name = L["Felsoul Seer"], mId = 680, petId = {1877, 1878, 1879}},
  {id = 105840, flags = 3, mId = 630, petId = {1880}},
  {id = 105841, flags = 3, mId = 650, petId = {1881}},
  {id = 105842, flags = 3, mId = 634, petId = {1882}},
  {id = 105898, flags = 3, mId = 630, petId = {1883}},
  {id = 106417, flags = 3, mId = 630, petId = {1891}},
  {id = 106476, name = L["Beguiling Orb"], mId = 630, petId = {1893, 1894, 1892}},
  {id = 106525, flags = 3, mId = 630, petId = {1895, 1896}},
  {id = 106552, name = L["Nightwatcher Merayl"], mId = 630, petId = {1897, 1898, 1899}},
  {id = 107489, name = L["Amalia"], mId = 630, petId = {1905, 1904, 1906}},
  {id = 115286, name = L["Crysa"], mId = 10, petId = {1983, 1981, 1982}},
  {id = 115307, name = L["Algalon the Observer"], mId = 120, petId = {1971, 1972, 1973}},
  {id = 116786, flags = 3, mId = 825, petId = {1989}},
  {id = 116787, flags = 3, mId = 825, petId = {1987}},
  {id = 116788, flags = 3, mId = 825, petId = {1988}},
  {id = 116789, flags = 3, mId = 825, petId = {1990}},
  {id = 116790, flags = 3, mId = 825, petId = {1991}},
  {id = 116791, flags = 3, mId = 825, petId = {1992}},
  {id = 116792, flags = 3, mId = 825, petId = {1993}},
  {id = 116793, flags = 3, mId = 825, petId = {1994}},
  {id = 116794, flags = 3, mId = 825, petId = {1995}},
  {id = 116795, flags = 3, mId = 825, petId = {1996}},
  {id = 117934, name = L["Sissix"], mId = 646, petId = {2014, 2015, 2016}},
  {id = 117950, name = L["Madam Viciosa"], mId = 646, petId = {2011, 2012, 2013}},
  {id = 117951, name = L["Nameless Mystic"], mId = 646, petId = {2008, 2009, 2010}},
  {id = 119341, flags = 3, mId = 836, petId = {2028}},
  {id = 119342, flags = 3, mId = 836, petId = {2027}},
  {id = 119343, flags = 3, mId = 836, petId = {2026}},
  {id = 119344, flags = 3, mId = 836, petId = {2025}},
  {id = 119345, flags = 3, mId = 836, petId = {2024}},
  {id = 119346, flags = 3, mId = 836, petId = {2023}},
  {id = 119407, flags = 3, mId = 836, petId = {2032}},
  {id = 119408, flags = 3, mId = 836, petId = {2033}},
  {id = 119409, flags = 3, mId = 836, petId = {2031}},
  {id = 124617, name = L["Environeer Bert"], mId = 30, petId = {2068, 2067, 2066}},
  {id = 128007, flags = 3, mId = 830, petId = {2095}},
  {id = 128008, flags = 3, mId = 830, petId = {2096}},
  {id = 128009, flags = 3, mId = 830, petId = {2097}},
  {id = 128010, flags = 3, mId = 830, petId = {2098}},
  {id = 128011, flags = 3, mId = 830, petId = {2099}},
  {id = 128012, flags = 3, mId = 830, petId = {2100}},
  {id = 128013, flags = 3, mId = 882, petId = {2101}},
  {id = 128014, flags = 3, mId = 882, petId = {2102}},
  {id = 128015, flags = 3, mId = 882, petId = {2103}},
  {id = 128016, flags = 3, mId = 882, petId = {2104}},
  {id = 128017, flags = 3, mId = 882, petId = {2105}},
  {id = 128018, flags = 3, mId = 882, petId = {2106}},
  {id = 128019, flags = 3, mId = 885, petId = {2107}},
  {id = 128020, flags = 3, mId = 885, petId = {2108}},
  {id = 128021, flags = 3, mId = 885, petId = {2109}},
  {id = 128022, flags = 3, mId = 885, petId = {2112}},
  {id = 128023, flags = 3, mId = 885, petId = {2111}},
  {id = 128024, flags = 3, mId = 885, petId = {2110}},
  {id = 139489, name = L["Captain Hermes"], mId = 896, petId = {2193, 2194, 2195}},
  {id = 139987, flags = 3, mId = 942, petId = {2200}},
  {id = 140315, name = L["Eddie Fixit"], mId = 942, petId = {2205, 2203, 2204}},
  {id = 140461, name = L["Dilbert McClint"], mId = 896, petId = {2209, 2206, 2208}},
  {id = 140813, name = L["Fizzie Sparkwhistle"], mId = 896, petId = {2210, 2211, 2212}},
  {id = 140880, name = L["Michael Skarn"], mId = 896, petId = {2213, 2214, 2215}},
  {id = 141002, name = L["Ellie Vern"], mId = 942, petId = {2220, 2221, 2222}},
  {id = 141046, name = L["Leana Darkwind"], mId = 942, petId = {2223, 2225, 2226}},
  {id = 141077, name = L["Kwint"], mId = 895, petId = {2229, 2228, 2227}},
  {id = 141215, flags = 3, mId = 895, petId = {2230}},
  {id = 141292, name = L["Delia Hanako"], mId = 895, petId = {2233, 2232, 2231}},
  {id = 141479, name = L["Burly"], mId = 895, petId = {2330, 2332, 2333}},
  {id = 141529, name = L["Lozu"], mId = 863, petId = {2334, 2335, 2336}},
  {id = 141588, flags = 3, mId = 863, petId = {2337}},
  {id = 141799, name = L["Grady Prett"], mId = 863, petId = {2338, 2339, 2340}},
  {id = 141814, name = L["Korval Darkbeard"], mId = 863, petId = {2341, 2343, 2344}},
  {id = 141879, name = L["Keeyo"], mId = 864, petId = {2345, 2346, 2347}},
  {id = 141945, name = L["Sizzik"], mId = 864, petId = {2355, 2354, 2353}},
  {id = 141969, flags = 3, mId = 864, petId = {2356}},
  {id = 142054, name = L["Kusa"], mId = 864, petId = {2359, 2357, 2358}},
  {id = 142096, name = L["Karaga"], mId = 862, petId = {2360, 2361, 2363}},
  {id = 142114, name = L["Talia Sparkbrow"], mId = 862, petId = {2364, 2365, 2366}},
  {id = 142151, flags = 3, mId = 862, petId = {2367}},
  {id = 142234, name = L["Zujai"], mId = 862, petId = {2368, 2370, 2371}},
  {id = 145968, flags = 3, mId = 842, petId = {2485}},
  {id = 145971, flags = 3, mId = 842, petId = {2486}},
  {id = 145988, flags = 3, mId = 842, petId = {2488}},
  {id = 146001, flags = 3, mId = 840, petId = {2501}},
  {id = 146002, flags = 3, mId = 842, petId = {2492}},
  {id = 146003, flags = 3, mId = 842, petId = {2493}},
  {id = 146004, flags = 3, mId = 842, petId = {2494}},
  {id = 146005, flags = 3, mId = 842, petId = {2495}},
  {id = 146181, flags = 3, mId = 841, petId = {2504}},
  {id = 146182, flags = 3, mId = 841, petId = {2503}},
  {id = 146183, flags = 3, mId = 841, petId = {2502}},
  {id = 146932, name = L["Door Control Console"], mId = 841, petId = {2497, 2498, 2499}},
  {id = 150858, flags = 3, mId = 1505, petId = {2592}},
  {id = 150911, flags = 3, mId = 1505, petId = {2597}},
  {id = 150914, flags = 3, mId = 1505, petId = {2600}},
  {id = 150917, flags = 3, mId = 1505, petId = {2602}},
  {id = 150918, flags = 3, mId = 1505, petId = {2603}},
  {id = 150922, flags = 3, mId = 1505, petId = {2608}},
  {id = 150923, flags = 3, mId = 1505, petId = {2609}},
  {id = 150925, flags = 3, mId = 1505, petId = {2612}},
  {id = 150929, flags = 3, mId = 1505, petId = {2613}},
  {id = 154783, flags = 3, mId = 1462, petId = {2669, 2673, 2676}},
  {id = 154910, flags = 3, mId = 1355, petId = {2723}},
  {id = 154911, flags = 3, mId = 1355, petId = {2724}},
  {id = 154912, flags = 3, mId = 1355, petId = {2725}},
  {id = 154913, flags = 3, mId = 1355, petId = {2726}},
  {id = 154914, flags = 3, mId = 1355, petId = {2727}},
  {id = 154915, flags = 3, mId = 1355, petId = {2728}},
  {id = 154916, flags = 3, mId = 1355, petId = {2729}},
  {id = 154917, flags = 3, mId = 1355, petId = {2730}},
  {id = 154918, flags = 3, mId = 1355, petId = {2731}},
  {id = 154919, flags = 3, mId = 1355, petId = {2732}},
  {id = 154920, flags = 3, mId = 1355, petId = {2733}},
  {id = 154921, flags = 3, mId = 1355, petId = {2734}},
  {id = 154922, flags = 3, mId = 1462, petId = {2735}},
  {id = 154923, flags = 3, mId = 1462, petId = {2736}},
  {id = 154924, flags = 3, mId = 1462, petId = {2737}},
  {id = 154925, flags = 3, mId = 1462, petId = {2738}},
  {id = 154926, flags = 3, mId = 1462, petId = {2739}},
  {id = 154927, flags = 3, mId = 1462, petId = {2740}},
  {id = 154928, flags = 3, mId = 1462, petId = {2741}},
  {id = 154929, flags = 3, mId = 1462, petId = {2742}},
  {id = 155145, name = L["Plagued Critters"], mId = 1505, petId = {2595}},
  {id = 155267, flags = 3, mId = 1505, petId = {2751}},
  {id = 155413, name = L["Postmaster Malown"], mId = 1505, petId = {2774, 2771, 2772}},
  {id = 155414, name = L["Fras Siabi"], mId = 1505, petId = {2768, 2769, 2770}},
  {id = 160205, name = L["Pixy Wizzle"], mId = 1578, petId = {2814}},
  {id = 160206, name = L["Alran Heartshade"], mId = 1578, petId = {2804, 2805, 2806}},
  {id = 160207, name = L["Therin Skysong"], mId = 1578, petId = {2802, 2803}},
  {id = 160208, name = L["Zuna Skullcrush"], mId = 1578, petId = {2807, 2808, 2809}},
  {id = 160209, name = L["Horu Cloudwatcher"], mId = 1578, petId = {2801, 2800, 2799}},
  {id = 160210, name = L["Tasha Riley"], mId = 1578, petId = {2810, 2811, 2812}},
  {id = 161649, flags = 3, mId = 1578, petId = {2815}},
  {id = 161650, flags = 3, mId = 1578, petId = {2816}},
  {id = 161651, flags = 3, mId = 1578, petId = {2817}},
  {id = 161656, flags = 3, mId = 1578, petId = {2818}},
  {id = 161657, flags = 3, mId = 1578, petId = {2819}},
  {id = 161658, flags = 3, mId = 1578, petId = {2820}},
  {id = 161661, flags = 3, mId = 1578, petId = {2821}},
  {id = 161662, flags = 3, mId = 1578, petId = {2822}},
  {id = 161663, flags = 3, mId = 1578, petId = {2823}},
  {id = 162458, flags = 3, mId = 1527, petId = {2854}},
  {id = 162461, flags = 3, mId = 1527, petId = {2855}},
  {id = 162465, flags = 3, mId = 1527, petId = {2856}},
  {id = 162466, flags = 3, mId = 1527, petId = {2857}},
  {id = 162468, flags = 3, mId = 1530, petId = {2858}},
  {id = 162469, flags = 3, mId = 1530, petId = {2859}},
  {id = 162470, flags = 3, mId = 1530, petId = {2860}},
  {id = 162471, flags = 3, mId = 1530, petId = {2861}},
  {id = 173129, name = L["Thenia"], mId = 1533, petId = {2969, 2970, 2971}},
  {id = 173130, name = L["Zolla"], mId = 1533, petId = {2975, 2976, 2977}},
  {id = 173131, name = L["Stratios"], mId = 1533, petId = {2972, 2973, 2974}},
  {id = 173133, flags = 3, mId = 1533, petId = {2968}},
  {id = 173257, name = L["Caregiver Maximillian"], mId = 1536, petId = {2980, 2981, 2982}},
  {id = 173263, name = L["Rotgut"], mId = 1536, petId = {2983, 2984, 2985}},
  {id = 173267, name = L["Dundley Stickyfingers"], mId = 1536, petId = {2986, 2987, 2988}},
  {id = 173274, flags = 3, mId = 1536, petId = {2978}},
  {id = 173303, flags = 3, mId = 1525, petId = {2979}},
  {id = 173315, name = L["Sylla"], mId = 1525, petId = {2989, 2990, 2991}},
  {id = 173324, name = L["Eyegor"], mId = 1525, petId = {2992, 2993, 2994}},
  {id = 173331, name = L["Addius the Tormentor"], mId = 1525, petId = {2996}},
  {id = 173372, name = L["Glitterdust"], mId = 1565, petId = {3000, 3001, 3002}},
  {id = 173376, flags = 3, mId = 1565, petId = {2998}},
  {id = 173377, name = L["Faryl"], mId = 1565, petId = {3003, 3004, 3005}},
  {id = 173381, flags = 3, mId = 1565, petId = {2999}},
  {id = 175777, flags = 3, mId = 1533, petId = {3068}},
  {id = 175778, flags = 3, mId = 1565, petId = {3070}},
  {id = 175779, flags = 3, mId = 1565, petId = {3071}},
  {id = 175780, flags = 3, mId = 1565, petId = {3072}},
  {id = 175781, flags = 3, mId = 1525, petId = {3073}},
  {id = 175782, flags = 3, mId = 1525, petId = {3074}},
  {id = 175783, flags = 3, mId = 1533, petId = {3075}},
  {id = 175784, flags = 3, mId = 1536, petId = {3076}},
  {id = 175785, flags = 3, mId = 1533, petId = {3077}},
  {id = 175786, flags = 3, mId = 1536, petId = {3078}},
  {id = 176655, name = L["Anthea"], mId = 379, petId = {3089, 3090, 3091}},
  {id = 189376, flags = 3, mId = 2022, petId = {3268}},
  {id = 196069, name = L["Patchu"], mId = 2024, petId = {3393, 3394, 3395}},
  {id = 196264, name = L["Haniko"], mId = 2022, petId = {3387, 3386, 3388}},
  {id = 197102, name = L["Bakhushek"], mId = 2023, petId = {3392, 3391}},
  {id = 197336, flags = 3, mId = 2025, petId = {3396}},
  {id = 197350, name = L["Setimothes"], mId = 2025, petId = {3397, 3398, 3400}},
  {id = 197417, flags = 3, mId = 2024, petId = {3401}},
  {id = 197447, flags = 3, mId = 2023, petId = {3402}},
  {id = 200682, flags = 11, mId = 2151, petId = {3433}},
  {id = 200684, flags = 15, mId = 2151, petId = {3429}},
  {id = 200685, flags = 7, mId = 2151, petId = {3437}},
  {id = 200686, flags = 11, mId = 2151, petId = {3435}},
  {id = 200688, flags = 15, mId = 2151, petId = {3431}},
  {id = 200689, flags = 7, mId = 2151, petId = {3439}},
  {id = 200690, flags = 11, mId = 2151, petId = {3434}},
  {id = 200692, flags = 15, mId = 2151, petId = {3430}},
  {id = 200693, flags = 7, mId = 2151, petId = {3438}},
  {id = 200694, flags = 11, mId = 2151, petId = {3436}},
  {id = 200696, flags = 15, mId = 2151, petId = {3432}},
  {id = 200697, flags = 7, mId = 2151, petId = {3440}},
  {id = 201004, name = L["Explorer Bezzert"], mId = 2133, petId = {3560, 3559, 3558}},
  {id = 201802, name = L["Excavator Morgrum Emberflint"], mId = 2022, petId = {3452, 3451, 3450}},
  {id = 201849, flags = 3, mId = 2022, petId = {3453}},
  {id = 201858, flags = 3, mId = 2023, petId = {3454}},
  {id = 201878, name = L["Vikshi Thunderpaw"], mId = 2023, petId = {3457, 3456, 3455}},
  {id = 201899, name = L["Izal Whitemoon"], mId = 2024, petId = {3460, 3459, 3458}},
  {id = 202440, flags = 3, mId = 2024, petId = {3465}},
  {id = 202452, flags = 3, mId = 2025, petId = {3466}},
  {id = 202458, name = L["Stargazer Zenoth"], mId = 2025, petId = {3474, 3473, 3472}},
  {id = 204792, name = L["Shinmura"], mId = 2133, petId = {3565, 3566, 3567}},
  {id = 204926, name = L["Delver Mardei"], mId = 2133, petId = {3570, 3569, 3568}},
  {id = 204934, name = L["Trainer Orlogg"], mId = 2133, petId = {3572, 3571, 3573}},
  {id = 222535, flags = 3, mId = 2214, petId = {4488}},
  {id = 223406, flags = 3, mId = 2255, petId = {4560}},
  {id = 223407, flags = 3, mId = 2248, petId = {4561}},
  {id = 223409, flags = 3, mId = 2215, petId = {4562}},
  {id = 223442, name = L["Kyrie"], mId = 2215, petId = {4559, 4555, 4552}},
  {id = 223443, name = L["Ziriak"], mId = 2216, petId = {4556, 4558, 4557}},
  {id = 223444, name = L["Friendhaver Grem"], mId = 2214, petId = {4564, 4553, 4554}},
  {id = 223446, name = L["Collector Dyna"], mId = 2248, petId = {4551, 4550, 4549}},
  {id = 237701, flags = 3, mId = 2346, petId = {4737}},
  {id = 237703, name = L["Baxx the Purveyor"], mId = 2346, petId = {4740, 4739, 4738}},
  {id = 237712, name = L["Prezly Wavecutter"], mId = 2346, petId = {4742, 4743, 4741}},
  {id = 237718, name = L["Creech"], mId = 2346, petId = {4746, 4744, 4745}},
};

-- Mapping from opponent ID to info
local opponentById =
{
  [85655]=85561,
  [85657]=85656,
  [85658]=85656,
  [85661]=85660,
  [85663]=85662,
  [85665]=85664,
  [85666]=85664,
  [85675]=85674,
  [85676]=85674,
  [85678]=85677,
  [85680]=85679,
  [85681]=85679,
  [85683]=85682,
  [85684]=85682,
  [85687]=85686,
  [85688]=85686,
  [106535]=106525,
};

local opponentCustomIcons =
{
  [ 68462] =   1138, -- Flowing Pandaren Spirit
  [ 68463] =   1139, -- Burning Pandaren Spirit
  [ 68464] =   1140, -- Whispering Pandaren Spirit
  [ 68465] =   1141, -- Thundering Pandaren Spirit
  [ 90675] =  90675, -- Erris the Collector
  [ 91014] =  90675, -- Erris the Collector
  [ 91015] =  90675, -- Erris the Collector
  [ 91016] =  90675, -- Erris the Collector
  [ 91017] =  90675, -- Erris the Collector
  [ 94601] =  94601, -- Felsworn Sentry
  [ 94637] =  94637, -- Corrupted Thundertail
  [ 94638] =  94638, -- Chaos Pup
  [ 94639] =  94639, -- Cursed Spirit
  [ 94640] =  94640, -- Felfly
  [ 94641] =  94641, -- Tainted Maulclaw
  [ 94642] =  94642, -- Direflame
  [ 94643] =  94643, -- Mirecroak
  [ 94644] =  94644, -- Dark Gazer
  [ 94645] =  94645, -- Bleakclaw
  [ 94646] =  94646, -- Vile Blood of Draenor
  [ 94647] =  94647, -- Dreadwalker
  [ 94648] =  94648, -- Netherfist
  [ 94649] =  94649, -- Skrillix
  [ 94650] =  94650, -- Defiled Earth
  [119408] = 119408, -- "Captain" Klutz
  [128007] = 128007, -- Ruinhoof
  [128008] = 128008, -- Foulclaw
  [128009] = 128009, -- Baneglow
  [128010] = 128010, -- Retch
  [128011] = 128011, -- Deathscreech
  [128012] = 128012, -- Gnasher
  [128013] = 128013, -- Bucky
  [128014] = 128014, -- Snozz
  [128015] = 128015, -- Gloamwing
  [128016] = 128016, -- Shadeflicker
  [128017] = 128017, -- Corrupted Blood of Argus
  [128018] = 128018, -- Mar'cuus
  [128019] = 128019, -- Watcher
  [128020] = 128020, -- Bloat
  [128021] = 128021, -- Earseeker
  [128022] = 128022, -- Pilfer
  [128023] = 128023, -- Minixis
  [128024] = 128024, -- One-of-Many
  [150925] = 150925, -- Liz the Tormentor
  [150929] = 150929, -- Nefarious Terry
  [155145] = 155145, -- Plagued Critters
  [173257] = 173257, -- Jawbone,
  [173274] = 173274, -- Gorgemouth,
  [173303] = 173303, -- Scorch,
  [173376] = 173376, -- Nightfang,
  [175777] = 175777, -- Crystalsnap,
  [175778] = 175778, -- Briarpaw,
  [175779] = 175779, -- Chittermaw
  [175780] = 175780, -- Mistwing
  [175781] = 175781, -- Sewer Creeper
  [175782] = 175782, -- The Countess
  [175783] = 175783, -- Digallo
  [175784] = 175784, -- Gelatinous
  [175785] = 175785, -- Kostos
  [175786] = 175786, -- Glurp
};

-- Mapping from Alliance opponents to Horde opponents
-- NOTE: The mappings are for those opponents that have direct replacements and
--       identical pet teams, such as Erris the Collector/Kura Thunderhoof.
local opponentFactionMapping =
{
  [90675] =
  {
    id = 91026, name = L["Kura Thunderhoof"], mId = 590, iconId = 91026
  },
  [91014] =
  {
    id = 91361, name = L["Kura Thunderhoof"], mId = 590, iconId = 91026
  },
  [91015] =
  {
    id = 91362, name = L["Kura Thunderhoof"], mId = 590, iconId = 91026
  },
  [91016] =
  {
    id = 91363, name = L["Kura Thunderhoof"], mId = 590, iconId = 91026
  },
  [91017] =
  {
    id = 91364, name = L["Kura Thunderhoof"], mId = 590, iconId = 91026
  },
};

-- Remapping for renamed opponents
-- TODO: Remove when not likely to be needed any more
local opponentRemapping =
{
  [105353] = 105352, -- Surging Mana Crystal
  [106422] = 106476, -- Beguiling Orb
};

local loadOutPlaceholders = {{}, {}, {}};
local loadOutInfo = {};

local teamLoadInfo =
{
  pets     = {},
  numTries = 0
};

local lastOpponentId = nil;

-------------------------------------------------------------------------------
--                 A  D  D  O  N     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-- Automatically caches the info for each species interrogated
L.petSpecies = setmetatable({},
{
  __index = function(table, key)
    table[key] = {};
    table[key].name, table[key].icon, table[key].type =
      C_PetJournal.GetPetInfoBySpeciesID(key);
    table[key].id, table[key].level =
      C_PetJournal.GetPetAbilityList(key);

    return table[key];
  end
});

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function hooked into 'C_PetJournal.SetPetLoadOutInfo". It keeps track of
-- the GUID of the pets in each slots and hides placeholder frames when
-- appropriate.
--
local function petLoadOutOnChange(slotIdx, petGuid)
  -- Local Variables
  local petGuid;

  -- Update the info for each slot
  for idx = 1, L.MAX_ACTIVE_PETS do
    -- Get the GUID of the pet in the slot
    petGuid = C_PetJournal.GetPetLoadOutInfo(idx);

    -- Hide the placeholder frame, if the pet has changed
    if ((loadOutInfo[idx].placeholder ~= nil) and
        (loadOutInfo[idx].placeholder:IsShown()) and
        ((idx == slotIdx) or
         (loadOutInfo[idx].placeholder.guid ~= petGuid))) then
      loadOutInfo[idx].placeholder:Hide();
      loadOutInfo[idx].placeholder.guid = nil;
    end

    -- Save the pet's GUID
    loadOutInfo[idx].guid = petGuid;
  end

  -- Update the Pet Teams list 
  NigglesPetTeams.list.update(NigglesPetTeams.list);

  return;
end

--
-- Function to compare two pet teams for use with 'table.sort'
--
local function petTeamsCompare(first, second)
  -- Local Variables
  local namesCompared;
  local firstName;
  local secondName;

  -- Work out which name to use
  if ((first.opponentId == 0) or (first.opponentId == second.opponentId)) then
    firstName = first.name;
  else
    firstName = (opponentById[first.opponentId].name or "");
  end
  if ((second.opponentId == 0) or (first.opponentId == second.opponentId)) then
    secondName = second.name;
  else
    secondName = (opponentById[second.opponentId].name or "");
  end

  -- Check if either name is blank
  if ((firstName ~= "") and (secondName == "")) then
    return true;
  elseif ((firstName == "") and (secondName ~= "")) then
    return false;
  end 

  -- Compare the names
  namesCompared = strcmputf8i(firstName, secondName);
  if (namesCompared ~= 0) then
    return (namesCompared < 0);
  end

  return (first.editTime > second.editTime);
end

--
-- Function to load a pet team. This function is called by the addon function
-- 'L.petTeamLoad'. It will try several times to load the pets in a team, with
-- a short delay between each try. This is required because the Blizzard
-- function 'C_PetJournal.SetPetLoadOutInfo' isn't reliable.
--
local function teamLoad()
  -- Local Variables
  local cpj = C_PetJournal;
  local numFailed = 0;
  local speciesId;
  local speciesInfo;

  -- Load each pet in the team into the correct slot
  for slotIdx, petInfo in ipairs(teamLoadInfo.pets) do
    -- Check if a pet should be loaded into the slot
    if (petInfo.guid ~= nil) then
      -- Put the pet in the slot
      cpj.SetPetLoadOutInfo(slotIdx, petInfo.guid);
      if (cpj.GetPetLoadOutInfo(slotIdx) == petInfo.guid) then
        -- Check if the pet's abilities should be set
        speciesId   = L.petGetInfo(petInfo.guid);
        speciesInfo = (speciesId ~= nil and L.petSpecies[speciesId] or nil);
        if ((petInfo.abilityId ~= nil) and (speciesInfo ~= nil)) then
          -- Set the pet's abilities
          for abilityIdx, abilityId in ipairs(petInfo.abilityId) do
            if ((speciesInfo.id[abilityIdx                       ] ==
                  abilityId) or
                (speciesInfo.id[abilityIdx+L.NUM_ACTIVE_ABILITIES] ==
                  abilityId)) then
              cpj.SetAbility(slotIdx, abilityIdx, abilityId);
            end
          end
        end
      else
        numFailed = numFailed+1;
      end
    end

    -- Create the placeholder frame, if required
    if ((petInfo.isPlaceholder) and
        (loadOutInfo[slotIdx].placeholder == nil) and
        (_G["PetJournalLoadoutPet"..slotIdx] ~= nil)) then
      loadOutInfo[slotIdx].placeholder = CreateFrame("Frame", nil,
        _G["PetJournalLoadoutPet"..slotIdx],
        "NigglesPetTeamsPlaceholderTemplate");
      loadOutInfo[slotIdx].placeholder.label:SetText(L["Placeholder"]);
    end

    -- Show/hide the placeholder frame
    if (loadOutInfo[slotIdx].placeholder ~= nil) then
      loadOutInfo[slotIdx].placeholder:SetShown(petInfo.isPlaceholder);
      loadOutInfo[slotIdx].placeholder.guid = cpj.GetPetLoadOutInfo(slotIdx);
    end
  end

  -- Update the pet journal's load out
  PetJournal_UpdatePetLoadOut();

  -- Check if another attempt is required to load the pet team
  if ((numFailed > 0) and (teamLoadInfo.numTries < MAX_LOAD_TRIES)) then
    teamLoadInfo.numTries = teamLoadInfo.numTries+1;
    C_Timer.After(0.1, teamLoad);
  end

  return;
end

--
-- Function to find the index of a value within a table
--
local function tIndex(table, value)
  -- Local Variables
  local index = nil;

  -- Search the table for the specified value
  for tableIdx, tableValue in ipairs(table) do
    if (tableValue == value) then
      index = tableIdx;
      break;
    end
  end

  return index;
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to get the path for an opponent's icon
--
L.opponentGetIconPath = function(id)
  -- Check an opponent with the specified NPC ID is known
  if (opponentById[id] ~= nil) then
    return TEAM_ICON_PATH..(opponentCustomIcons[id] or id);
  else
    return nil;
  end
end

--
-- Function called when the player's target changes. If the target is an
-- opponent, its ID is saved.
--
L.opponentOnTarget = function()
  -- Local Variables
  local targetGUID = UnitGUID("target");
  local targetID;

  -- Check there is a target
  if (targetGUID ~= nil) then
    -- Extract the target's ID
    _, _, targetId = string.find(targetGUID, "-(%d*)-%x*$");
    targetId = tonumber(targetId);
    if (opponentById[targetId] ~= nil) then
      lastOpponentId = targetId;
    end
  end
  
  return;
end

--
-- Function to get info about a pet from its GUID. The function first checks
-- if the info is available from the Pet Journal. If it isn't it then checks
-- the 'pets' table from the addon's saved variables. This allows info for
-- missing pets to be displayed.
--
L.petGetInfo = function(petGuid)
  -- Local Variables
  local health;
  local iterator;
  local level;
  local maxHealth;
  local power;
  local quality;
  local speciesId;
  local speed;
  local isAvailable = false;
  local customName;

  -- Check a pet GUID has been specified
  if (type(petGuid) == "string") then
    -- Try to get the pet's info from the Pet Journal
    speciesId, customName, level = C_PetJournal.GetPetInfoByPetID(petGuid);
    if (speciesId ~= nil) then
      health, maxHealth, power, speed, quality =
        C_PetJournal.GetPetStats(petGuid);
      isAvailable = true;
    elseif (NglPtDB.pets[petGuid] ~= nil) then
      iterator  = string.gmatch(NglPtDB.pets[petGuid], "[^|]+");
      speciesId = tonumber(iterator());
      level     = tonumber(iterator());
      maxHealth = tonumber(iterator());
      health    = maxHealth;
      power     = tonumber(iterator());
      speed     = tonumber(iterator());
      quality   = tonumber(iterator());
    end
  end

  return speciesId, customName, level, health, maxHealth, power, speed,
    quality, isAvailable;
end

--
-- Function to save the info for a pet to the 'pets' table in the addon's
-- saved variables. This info can then be used to display details of the pet
-- even if it is no longer in the Pet Journal, to aid in finding a replacement.
--
L.petSaveInfo = function(petGuid)
  -- Get the info to be saved for the pet
  local speciesId, _, level = C_PetJournal.GetPetInfoByPetID(petGuid);
  local _, maxHealth, power, speed, quality =
    C_PetJournal.GetPetStats(petGuid);

  -- Add the pet's info to the 'pets' table
  if ((type(level) == "number") and (type(quality) == "number")) then
    NglPtDB.pets[petGuid] = speciesId.."|"..level.."|"..maxHealth.."|"..
      power.."|"..speed.."|"..quality;
  end

  return;
end

--
-- Function to save info for a pet that doesn't exist in the player's pet
-- journal in a way that can't conflict with any new pets the player obtains.
--
L.petSavePseudoInfo = function(speciesId, level, maxHealth, power, speed, quality)
  -- Local Variables
  local petGuid;
  local pets = NglPtDB.pets;

  -- Search for a free pseudo GUID
  for idx = 1, 0xFFFF do
    petGuid = format(BATTLE_PET_PSEUDO, idx);
    if (pets[petGuid] == nil) then
      break;
    end
  end

  -- Check a free pseudo GUID was found
  if (pets[petGuid] == nil) then
    -- Add the pet's info to the 'pets' table
    pets[petGuid] = speciesId.."|"..level.."|"..maxHealth.."|"..
      power.."|"..speed.."|"..quality;
  end

  return petGuid;
end

--
-- Function to update the info in the 'pets' table
--
L.petsUpdateInfo = function()
  -- Local Variables
  local isUsed = {};
  local petGuid;

  -- Create a list of all the pets used in pet teams
  for _, petTeam in ipairs(NglPtDB.petTeams) do
    for _, petInfo in ipairs(petTeam.pets) do
      if (petInfo.guid ~= nil) then
        isUsed[petInfo.guid] = true;
      end
    end
  end

  -- Remove any unused pets from the list
  for petGuid, _ in pairs(NglPtDB.pets) do
    if (not isUsed[petGuid]) then
      NglPtDB.pets[petGuid] = nil;
    end
  end

  -- Update the info for the pets in the list
  for petGuid, _ in pairs(isUsed) do
    L.petSaveInfo(petGuid);
  end

  return;
end

--
-- Function to find the FIRST team that matches the current opponent and
-- load out.
--
function L.petTeamByCurrentBattle()
  -- Local Variables
  local current;
  local isMatch;
  local loadOutPets = {{abilityId = {}}, {abilityId = {}}, {abilityId = {}}};
  local opponentId;
  local teamInfo;

  -- Try to work out the current opponent
  opponentId = L.petTeamOpponentByPetSpecies(
    C_PetBattles.GetPetSpeciesID(2, 1),
    C_PetBattles.GetPetSpeciesID(2, 2),
    C_PetBattles.GetPetSpeciesID(2, 3));
  if (opponentId == nil) then
    opponentId = lastOpponentId;
  end

  -- Check the current opponent could be identified
  if (opponentId ~= nil) then
    -- Get info for the current pets
    for petIdx = 1, L.MAX_ACTIVE_PETS do
      current = loadOutPets[petIdx];
      current.guid, current.abilityId[1], current.abilityId[2],
        current.abilityId[3] = C_PetJournal.GetPetLoadOutInfo(petIdx);
    end

    -- Check each pet team against the current opponent and load out
    for teamIdx = 1, #NglPtDB.petTeams do
      -- Check the team's opponent matches the current opponent
      current = NglPtDB.petTeams[teamIdx];
      if (current.opponentId == opponentId) then
        -- Check each pet in the pet team matches the load out
        isMatch = true;
        for petIdx = 1, L.MAX_ACTIVE_PETS do
          if (current.pets[petIdx].guid ~= nil) then
            -- Check if the GUID match
            if (current.pets[petIdx].guid ~= loadOutPets[petIdx].guid) then
              isMatch = false;
              break;
            end

            -- Check if the abilities in each slot match
            for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
              if (current.pets[petIdx].abilityId[abilityIdx] ~=
                  loadOutPets[petIdx].abilityId[abilityIdx]) then
                isMatch = false;
                break;
              end
            end
          end
        end

        -- Check if the pet team is a match
        if (isMatch) then
          teamInfo = current;
          break;
        end
      end
    end
  end

  return teamInfo;
end

--
-- Function to copy the info for a pet team from one table to another
--
L.petTeamCopy = function(src, dest)
  -- Initialise the source and destination tables for the pet team
  src  = (src or emptyTable);
  dest = (dest or {});

  -- Copy the pet team info from the source to destination table
  dest.name       = (src.name       or ""   );
  dest.opponentId = (src.opponentId or 0    );
  dest.iconPathId = (src.iconPathId or 0    );
  dest.category   = (src.category   or 0    );
  dest.strategy   = (src.strategy   or ""   );
  dest.isHtml     = (src.isHtml     or false);
  dest.editTime   = (src.editTime   or 0    );
  dest.editPatch  = (src.editPatch  or ""   );
  dest.pets       = (dest.pets      or {}   );
  for idx = 1, L.MAX_ACTIVE_PETS do
    dest.pets[idx] = L.petTeamPetCopy(
      (src.pets ~= nil and src.pets[idx] or nil), dest.pets[idx]);
  end

  -- Make sure all string values are valid lengths
  if (strlenutf8(dest.name) > L.MAX_TEAM_NAME_LEN) then
    dest.name = L.utf8ncpy(dest.name, L.MAX_TEAM_NAME_LEN);
  end
  if (strlenutf8(dest.strategy) > L.MAX_TEAM_STRAT_LEN) then
    dest.strategy = L.utf8ncpy(dest.strategy, L.MAX_TEAM_STRAT_LEN);
  end

  return dest;
end

--
-- Function to delete a pet team
--
function L.petTeamDelete(teamInfo)
  -- Delete the pet team from the list
  tDeleteItem(NglPtDB.petTeams, teamInfo);

  return;
end

-- 
-- Function to check if a pet team is loaded
--
function L.petTeamIsLoaded(teamInfo)
  -- Local Variables
  local pets = (teamInfo ~= nil and teamInfo.pets or nil);

  -- Check if the specified team is loaded
  return ((pets ~= nil) and
          ((pets[1].guid == nil) or (pets[1].guid == loadOutInfo[1].guid)) and
          ((pets[2].guid == nil) or (pets[2].guid == loadOutInfo[2].guid)) and
          ((pets[3].guid == nil) or (pets[3].guid == loadOutInfo[3].guid)));
end

--
-- Function to load a pet team
--
function L.petTeamLoad(teamInfo)
  -- Local Variables
  local _;
  local cpj = C_PetJournal;
  local loadInfoPet;
  local lvlIdx = 1;
  local lvlPets = {};
  local numLvlPets = 0;
  local petGuid;
  local petLevel;

  -- Get the GUID of any levelling pets currently in the load out
  for slotIdx, petInfo in ipairs(teamInfo.pets) do
    petGuid = cpj.GetPetLoadOutInfo(slotIdx);
    if (petGuid ~= nil) then
      _, _, petLevel = C_PetJournal.GetPetInfoByPetID(petGuid);
      if ((petLevel ~= nil) and (petLevel < L.MAX_PET_LEVEL)) then
        numLvlPets = numLvlPets+1;
        lvlPets[numLvlPets] = {guid = petGuid, level = petLevel};
      end
    end
  end

  -- Sort the levelling pets by level
  if (numLvlPets > 1) then
    table.sort(lvlPets,
      function(first, second)
        return first.level < second.level;
      end);
  end

  -- Work out which pet to load into each slot
  for slotIdx, teamInfoPet in ipairs(teamInfo.pets) do
    -- Reset the info for the slot's pet
    if (teamLoadInfo.pets[slotIdx] == nil) then
      teamLoadInfo.pets[slotIdx] = {};
    end
    loadInfoPet = teamLoadInfo.pets[slotIdx];
    loadInfoPet.guid          = nil;
    loadInfoPet.isPlaceholder = true;
    loadInfoPet.abilityId     = nil;

    -- Work out which pet should go in the slot
    if ((teamInfoPet.guid ~= nil) and
        (cpj.GetPetInfoByPetID(teamInfoPet.guid) ~= nil)) then
      loadInfoPet.guid          = teamInfoPet.guid;
      loadInfoPet.isPlaceholder = false;
      loadInfoPet.abilityId     = teamInfoPet.abilityId;
    elseif (lvlIdx <= numLvlPets) then
      loadInfoPet.guid = lvlPets[lvlIdx].guid;
      lvlIdx = lvlIdx+1;
    end
  end

  -- Load the pets into the slots
  teamLoadInfo.numTries = 0;
  teamLoad();

  return;
end

--
-- Function to get info for an opponent by NPC ID
--
function L.petTeamOpponentById(id)
  -- Check an opponent with the specified NPC ID is known
  if (opponentById[id] ~= nil) then
    -- NOTE: The ID is returned as the 2nd argument, rather than the first,
    --       because the name is required far more often.
    local current = opponentById[id];
    return current.name, current.id, current.mId;
  else
    return nil;
  end
end

--
-- Function to get info for an opponent by index
--
function L.petTeamOpponentByIndex(idx)
  -- Check if an opponent with the specified NPC ID is known
  if (opponentInfo[idx] ~= nil) then
    local current = opponentInfo[idx];
    return current.id, current.name, current.mId;
  else
    return nil;
  end
end

--
-- Function to get info for an opponent by the species of the specified pets
--
function L.petTeamOpponentByPetSpecies(...)
  -- Local Variables
  local opponentId;
  local opponentPetInfo;
  local petSpecies = {...};
  local numMatches;

  -- Search all the opponents for one with the specified pet species
  for opponentIdx = 1, #opponentInfo do
    -- Check the current opponent isn't 'Any Opponent'
    if ((opponentInfo[opponentIdx].id > 0) and
        (#opponentInfo[opponentIdx].petId > 0)) then
      -- Compare the opponent's pets to the specified list
      opponentPetInfo = opponentInfo[opponentIdx].petId
      numMatches = 0;
      for petIdx = 1, L.MAX_ACTIVE_PETS do
        if ((opponentPetInfo[petIdx] ~= nil) and
            (opponentPetInfo[petIdx] == petSpecies[petIdx])) then
          numMatches = numMatches+1;
        end
      end

      -- Check if all the opponent's pets match the specified list
      if ((numMatches > 0) and (numMatches == #opponentPetInfo)) then
        opponentId = opponentInfo[opponentIdx].id;
        break;
      end
    end
  end

  return opponentId;
end

--
-- Function to get the number of opponents
--
function L.petTeamOpponentCount()
  return #opponentInfo;
end

--
-- Function to get the icons for an opponent.
--
function L.petTeamOpponentIconById(id, idx)
  -- Local Variables
  local iconId = nil;
  local opponent = opponentById[id];

  -- Check the opponent ID is valid
  if (opponent ~= nil) then
    if (idx == 1) then
      -- Check if the opponent has a custom icon
      if (opponentCustomIcons[opponent.id] ~= nil) then
        iconId = opponentCustomIcons[opponent.id];
      elseif (bit.band(opponent.flags or 0, 0x01) ~= 0) then
        -- Use the first pet's icon
        iconId = opponent.petId[1];
      else
        -- Use the opponent's icon
        iconId = opponent.id;
      end
    elseif ((idx >= 2) and (idx <= 4)) then
      iconId = opponent.petId[idx-1];
    end
  end

  return iconId;
end

--
-- Function to copy the info for a pet from one table to another
--
function L.petTeamPetCopy(src, dest)
  -- Initialise the source and destination tables for the pet
  src  = src or emptyTable;
  dest = dest or {};

  -- Copy the pet info from the source to destination table
  dest.guid      = src.guid;
  dest.abilityId = dest.abilityId or {};
  for idx = 1, L.NUM_ACTIVE_ABILITIES do
    dest.abilityId[idx] = (src.abilityId ~= nil and src.abilityId[idx] or nil);
  end

  return dest;
end

--
-- Function to save a pet team
--
function L.petTeamSave(newInfo, newStrategy, teamInfo)
  -- Local Variables
  local petTeams = NglPtDB.petTeams;

  -- Save the pet team
  if (teamInfo == nil) then
    petTeams[#petTeams+1] = {};
    teamInfo = petTeams[#petTeams];
  end
  L.petTeamCopy(newInfo, teamInfo);

  -- Save info for the pet team's pets, for use if the pet is caged/released
  for _, petInfo in ipairs(teamInfo.pets) do
    if (petInfo.guid ~= nil) then
      L.petSaveInfo(petInfo.guid);
    end
  end

  -- Save the team's strategy
  teamInfo.strategy = newStrategy;

  -- Set the edit time and patch
  teamInfo.editTime  = time();
  teamInfo.editPatch = L.buildGetNumber();

  return teamInfo;
end

--
-- Function to save a new strategy for a pet team
--
function L.petTeamSaveStrategy(strategy, isHtml, teamInfo)
  -- Check a team has been specified
  if (teamInfo ~= nil) then
    -- Save the strategy
    teamInfo.strategy = strategy;
    teamInfo.isHtml   = isHtml;

    -- Set the edit time and patch
    teamInfo.editTime  = time();
    teamInfo.editPatch = L.buildGetNumber();
  end

  return;
end

--
-- Function to dismiss any pet summoned by the loading of a pet team
--
L.petTeamsDismissSummonedPet = function()
  -- Local Variables
  local summonedGuid = C_PetJournal.GetSummonedPetGUID();

  -- Check a pet team has been loaded
  if ((teamLoadInfo.pets[1] ~= nil) and 
      (teamLoadInfo.pets[1].guid ~= nil)) then
    -- Check if the summoned pet is from the pet team
    if ((summonedGuid ~= nil) and 
        (summonedGuid == teamLoadInfo.pets[1].guid)) then
      -- Dismiss the pet
      C_PetJournal.SummonPetByGUID(summonedGuid);

      -- Check in a short while that pet was dismissed
      C_Timer.After(0.25, L.petTeamsDismissSummonedPet);
    else
      teamLoadInfo.pets[1].guid = nil;
    end
  end

  return;
end

--
-- Function to check if there is an identical pet team to the specified one,
-- ignoring another team so an existing pet team being edited can be skipped.
--
function L.petTeamsHaveIdentical(teamInfo, ignoreTeam)
  -- Local Variables
  local current;
  local haveIdentical = false;
  local isIdentical;
  local petTeams = NglPtDB.petTeams;

  -- Check each pet team to see if it is identical to the specified team
  for teamIdx = 1, #petTeams do
    -- Set the flag that indicates if the pet teams are identical
    isIdentical = true;

    -- Compare the general info for the teams
    current = petTeams[teamIdx];
    if ((current.name       ~= teamInfo.name      ) or
        (current.opponentId ~= teamInfo.opponentId) or
        (current.strategy   ~= teamInfo.strategy  ) or
        (current.isHtml     ~= teamInfo.isHtml    )) then
      isIdentical = false;
    else
      -- Compare the pets for the teams
      for petIdx = 1, L.MAX_ACTIVE_PETS do
        if (current.pets[petIdx].guid ~= teamInfo.pets[petIdx].guid)  then
          isIdentical = false;
        elseif (current.pets[petIdx].guid ~= nil)  then
          -- Compare the abilities for the pets
          for abilityIdx = 1, L.NUM_ACTIVE_ABILITIES do
            if (current.pets[petIdx].abilityId[abilityIdx] ~=
                 teamInfo.pets[petIdx].abilityId[abilityIdx]) then
              isIdentical = false;
              break;
            end
          end
        end
      end
    end

    -- Check if the current pet team is a match for the specified pet team
    if ((isIdentical) and (current ~= ignoreTeam)) then
      haveIdentical = true;
      break;
    end
  end

  return haveIdentical;
end

--
-- Function to initialise the pet team software
--
L.petTeamsInit = function()
  -- Local Variables
  local _;
  local abilityIdx;
  local categories = NglPtDB.settings.categories;
  local currentPatch = L.buildGetNumber();
  local currentTime = time();
  local getSpeciesInfo = C_PetJournal.GetPetInfoBySpeciesID;
  local index;
  local numPets;
  local numValid;
  local opponent;
  local petInfo;
  local petLevel;
  local petSpeciesId;
  local speciesInfo;
  local validAbilities = {};

  -- Create a list of all opponent IDs
  for _, opponent in pairs(opponentInfo) do
    opponentById[opponent.id] = opponent;
  end

  -- Assign the correct opponent info to those opponents without a pet tamer
  for opponentId, opponentInfo in pairs(opponentById) do
    if (type(opponentInfo) == "number") then
      opponentById[opponentId] = opponentById[opponentInfo];
    end
  end

  -- Check if the player is Horde
  if (UnitFactionGroup("player") == "Horde") then
    -- Map Alliance opponents to their Horde equivalents with identical teams
    for allianceId, hordeInfo in pairs(opponentFactionMapping) do
      -- Add the opponent to the list of IDs
      opponent = opponentById[allianceId];
      opponentById[hordeInfo.id] = opponent;

      -- Update the opponent's info with the Horde details
      opponent.name = hordeInfo.name;
      opponent.mId  = hordeInfo.mId;

      -- Update the opponent's icon with the one for the Horde NPC
      opponentCustomIcons[allianceId] = hordeInfo.iconId;
    end
  end

  -- Initialise the names of the opponents
  for _, opponent in pairs(opponentInfo) do
    -- Create the opponent's name, if derived from the pets
    if (bit.band(opponent.flags or 0, 0x02) ~= 0) then
      numPets = #opponent.petId;
      opponent.name = format("%s%s%s%s%s%s%s",
        (opponent.name or ""),
        (opponent.name ~= nil and ": " or ""),
        (numPets >= 1 and getSpeciesInfo(opponent.petId[1]) or ""),
        ((numPets == 3) and ", " or ((numPets == 2) and " & " or "")),
        (numPets >= 2 and getSpeciesInfo(opponent.petId[2]) or ""),
        ((numPets == 3) and " & " or ""),
        (numPets >= 3 and getSpeciesInfo(opponent.petId[3]) or ""));
    end
  end

  -- Sort the opponents by name
  table.sort(opponentInfo,
    function(first, second)
      if ((first.id <= 1) or (second.id <= 1)) then
        return (first.id < second.id);
      elseif (first.name == second.name) then
        return (bit.band(first.flags or 0, 0x0C) <
          bit.band(second.flags or 0, 0x0C));
      else
        return (first.name < second.name);
      end
    end);

  -- Colour the opponent's name, if specified
  for _, opponent in pairs(opponentInfo) do
    if (bit.band(opponent.flags or 0, 0x0C) ~= 0) then
      opponent.name = opponentQuality[bit.band(bit.rshift(
        opponent.flags, 2), 0x03)]:WrapTextInColorCode(opponent.name);
    end
  end

  -- Update the info stored for pets used in teams
  L.petsUpdateInfo();

  -- Validate the info for each team
  for _, teamInfo in ipairs(NglPtDB.petTeams) do
    -- Validate the opponent ID
    if (opponentById[teamInfo.opponentId] == nil) then
      if (opponentRemapping[teamInfo.opponentId] ~= nil) then
        teamInfo.opponentId = opponentRemapping[teamInfo.opponentId];
      else
        teamInfo.opponentId = 0;
        teamInfo.name       = L["UnknownOpponent"];
      end
    end

    -- Validate the team name
    teamInfo.name = (teamInfo.name or
      ((teamInfo.opponentId == 0) and L["Unnamed Team"] or ""));
    if (strlenutf8(teamInfo.name) > L.MAX_TEAM_NAME_LEN) then
      teamInfo.name = L.utf8ncpy(teamInfo.name, L.MAX_TEAM_NAME_LEN);
    end

    -- Validate the strategy
    teamInfo.isHtml = (teamInfo.isHtml or false);
    if (teamInfo.strategy == nil) then
      teamInfo.strategy = "";
    elseif (strlenutf8(teamInfo.strategy) > L.MAX_TEAM_STRAT_LEN) then
      teamInfo.strategy = L.utf8ncpy(teamInfo.strategy, L.MAX_TEAM_STRAT_LEN);
    end

    -- Validate the edit time
    if ((teamInfo.editTime == nil) or
        (teamInfo.editTime > currentTime)) then
      teamInfo.editTime  = currentTime;
      teamInfo.editPatch = currentPatch;
    elseif (type(teamInfo.editPatch) == "string") then
      -- TODO: Remove when not likely to be needed any more
      teamInfo.editPatch = L.buildGetNumber(teamInfo.editPatch);
    end

    -- Validate the category
    if ((type(teamInfo.category) ~= "number") or
        (categories[teamInfo.category] == nil)) then
      teamInfo.category = 0;
    end

    -- Validate the pets
    for petIdx = 1, L.MAX_ACTIVE_PETS do
      -- Check the pet's entry is the correct type
      if (type(teamInfo.pets[petIdx]) ~= "table") then
        teamInfo.pets[petIdx] = L.petTeamPetCopy(nil);
      end

      -- Get info about the pet and its species
      petInfo = teamInfo.pets[petIdx];
      if (petInfo.guid ~= nil) then
        petSpeciesId, _, petLevel = L.petGetInfo(petInfo.guid);
        speciesInfo = (petSpeciesId ~= nil and
          L.petSpecies[petSpeciesId] or nil);
      end

      -- Check the pet's info could be obtained
      if ((petInfo.guid ~= nil) and (speciesInfo  ~= nil)) then
        -- NOTE: The following code is to handle pet abilities being moved
        --       by Blizzard, which has happened in the past, or a pet being
        --       de-levelled by it's quality being upgraded.

        -- Check which selected abilities are valid, based on species and level
        numValid = 0;
        for slotIdx = 1, L.NUM_ACTIVE_ABILITIES do
          index = tIndex(speciesInfo.id, petInfo.abilityId[slotIdx]);
          if ((index ~= nil) and (speciesInfo.level[index] <= petLevel)) then
            numValid = numValid+1;
            validAbilities[numValid] = petInfo.abilityId[slotIdx];
          end
        end

        -- Re-initialise selected abilities in their current slot
        abilityIdx = L.NUM_ACTIVE_ABILITIES+1;
        for slotIdx = 1, L.NUM_ACTIVE_ABILITIES do
          index = tIndex(validAbilities, speciesInfo.id[abilityIdx]);
          if ((index ~= nil) and (index <= numValid)) then
            petInfo.abilityId[slotIdx] = speciesInfo.id[abilityIdx];
          else
            petInfo.abilityId[slotIdx] = speciesInfo.id[slotIdx];
          end
          abilityIdx = abilityIdx+1;
        end
      else
        -- Remove the invalid pet
        teamInfo.pets[petIdx] = L.petTeamPetCopy(nil);
      end
    end
  end

  -- Sort the pet teams
  L.petTeamsSort();

  -- Initialise the load out info
  for slotIdx = 1, L.MAX_ACTIVE_PETS do
    loadOutInfo[slotIdx] = {};
  end

  -- Hook the function used to change the load out
  hooksecurefunc(C_PetJournal, "SetPetLoadOutInfo", petLoadOutOnChange);

  return;
end

--
-- Function to sort the pet teams by name and opponent
--
L.petTeamsSort = function()
  -- Sort the pet teams
  table.sort(NglPtDB.petTeams, petTeamsCompare);
  return;
end

--
-- Function to initialise the load out info
--
function L.petLoadOutInit()
  -- Get the GUID of the pet in each slot
  for slotIdx = 1, L.MAX_ACTIVE_PETS do
    loadOutInfo[slotIdx].guid = C_PetJournal.GetPetLoadOutInfo(slotIdx);
  end

  return;
end

--
-- Function to set a button used to display pet teams
--
function L.petTeamButtonSet(button, teamInfo, isComplete)
  -- Local Variables
  local coordX;
  local coordY;
  local textColor;
  local teamName;
  local teamSubName;
  local teamIcon;

  -- Set the button's team info
  button.teamInfo = teamInfo;

  -- Check a team has been specified
  if (teamInfo ~= nil) then
    -- Get the team's info
    teamName, teamSubName = L.petTeamGetNames(teamInfo)
    teamIcon = L.petTeamIconGetTexture(teamInfo.iconPathId);
  else
    teamName = L["NewTeam"];
    teamIcon = NEW_TEAM_ICON;
  end

  -- Set the button's icon
  button.icon:SetTexture(teamIcon);

  -- Set the button's name
  button.name:SetShown(teamName ~= nil);
  if (teamName ~= nil) then
    textColor = (isComplete and NORMAL_FONT_COLOR or RED_FONT_COLOR);
    button.name:SetText(teamName);
    button.name:SetTextColor(textColor.r, textColor.g, textColor.b);
    button.name:SetHeight(teamSubName ~= nil and 12 or 30);
    button.name:SetWordWrap(teamSubName == nil);
  end

  -- Set the button's sub-name
  button.subName:SetShown(teamSubName ~= nil);
  if (teamSubName ~= nil) then
    textColor = (isComplete and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR);
    button.subName:SetText(teamSubName);
    button.subName:SetTextColor(textColor.r, textColor.g, textColor.b);
  end
 
  -- Set the button's category
  if ((teamInfo ~= nil) and (teamInfo.category > 0)) then
    coordX = ((teamInfo.category-1)%4)*0.25;
    coordY = math.floor((teamInfo.category-1)/4)*0.25;
    button.category:SetTexCoord(coordX, coordX+0.25, coordY, coordY+0.25);
    button.category:Show();
  else
    button.category:Hide();
  end
  
  -- Show/Hide the button's highlight texture
  button.highlight:SetShown(L.petTeamIsLoaded(teamInfo));

  return;
end

--
-- Function to get the name and sub-name of a pet team
--
function L.petTeamGetNames(teamInfo)
  -- Local Variables
  local name;
  local subName;

  -- Check a team has been specified
  if (teamInfo ~= nil) then
    -- Work out the team's name and sub-name
    if (teamInfo.opponentId > 0) then
      name    = opponentById[teamInfo.opponentId].name;
      subName = (teamInfo.name ~= "" and teamInfo.name or nil);
    else
      name    = (teamInfo.name ~= "" and teamInfo.name or nil);
    end
  end

  return name, subName;
end
