local _, ArenaAnalytics = ... -- Addon Namespace
local Search = ArenaAnalytics.Search;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local Helpers = ArenaAnalytics.Helpers;
local ArenaMatch = ArenaAnalytics.ArenaMatch;

-------------------------------------------------------------------------
-- Search Lookup Tables

local function CalculateMatchScore(searchInput, matchedValue, startIndex)
    if(searchInput == matchedValue) then
        return 1000;
    end

    local maxPartialSearchDiff = 5;

    local matchedCountScore = (#searchInput / #matchedValue);
    local differenceScore = 1 - ((#matchedValue - #searchInput) / maxPartialSearchDiff)
    local startIndexScore = 1 - ((startIndex * startIndex) / (#matchedValue * #matchedValue));

    -- Return weighted score
    return (matchedCountScore * 0.5) + (differenceScore * 0.3) + (startIndexScore * 0.2);
end

---------------------------------
-- Prefix Data
---------------------------------

-- Assume short form as first alias index!
local PrefixTable = {
    ["name"] = { NoSpaces = true, Aliases = { "n", "name" }},
    ["class"] = { NoSpaces = false, Aliases = { "c", "class" }},
    ["spec"] = { NoSpaces = false, Aliases = { "s", "spec" }},
    ["hero"] = { NoSpaces = false, Aliases = { "h", "hero", "herospec" }},
    ["role"] = {NoSpaces = true, Aliases = { "role" }},
    ["race"] = { NoSpaces = false, Aliases = { "r", "race" }},
    ["faction"] = { NoSpaces = true, Aliases = { "f", "faction" }},
    ["alts"] = { NoSpaces = true, Aliases = { "a", "alts" }},
    ["team"] = { NoSpaces = true, Aliases = { "t", "team" }},
};

-- Find the prefix key from the given token
function Search:GetTokenPrefixKey(text)
    local prefix, value = text:match("([^:]+):(.+)");
    if prefix then
        for key,data in pairs(PrefixTable) do
            assert(data.Aliases and #data.Aliases > 0);

            for _,alias in ipairs(data.Aliases) do
                if(prefix == alias) then
                    return key, value, data.NoSpaces;
                end
            end
        end
    end
    return nil, (value or text), true;
end

function Search:GetShortPrefix(prefix)
    assert(prefix);
    for key,data in pairs(PrefixTable) do
        assert(data.Aliases and #data.Aliases > 0);
        for _,alias in ipairs(data.Aliases) do
            if(prefix == alias) then
                return data.Aliases[1];
            end
        end
    end
    return prefix;
end

---------------------------------
-- Search Type Data tables
---------------------------------

local neutralRaceRedirects = {
    [14] = 13,
    [16] = 15,
    [24] = 23,
};

function Search:GetNormalizedRace(race_id)
    return race_id and neutralRaceRedirects[race_id] or race_id;
end

local ambiguousSpecMappings = {
    [-1] = { 32, 51 },
    [-2] = { 1, 21 },
    [-3] = { 11, 92 },
    [-4] = { 12, 81 },
};

-- Get a shared id for ambiguous
function Search:CheckSpecMatch(searchSpec, player)
    playerSpec = ArenaMatch:GetPlayerSpec(player);
    searchSpec = tonumber(searchSpec);

    if(not searchSpec or not playerSpec) then
        return false;
    end

    if(searchSpec == playerSpec) then
        return true;
    end

    if(Helpers:IsClassID(searchSpec)) then
        return searchSpec == Helpers:GetClassID(playerSpec);
    end

    local values = ambiguousSpecMappings[searchSpec];
    if(type(values) ~= "table") then
        return false;
    end

    for _,value in ipairs(values) do
        if(playerSpec == value) then
            return true;
        end
    end

    return false;
end

local SearchTokenTypeTable = {
    ["class"] = {
        noSpace = false,
        values = {
            [0] = { "druid" },
            [10] = { "paladin", "pala" },
            [20] = { "shaman", "sham" },
            [30] = { "death knight", "deathknight", "dk" },
            [40] = { "hunter", "hunt", "huntard" },
            [50] = { "mage" },
            [60] = { "rogue", "rog" },
            [70] = { "warlock", "lock", "wlock" },
            [80] = { "warrior" },
            [90] = { "priest" },
            [100] = { "monk" },
            [110] = { "demon hunter", "demonhunter", "dh" },
            [120] = { "evoker" },
        },
    },
    ["spec"] = {
        noSpace = false,
        values = {
            -- Ambiguous
            [-1] = { "frost" },                 -- frost (mage or DK)
            [-2] = { "restoration", "resto" },  -- (Shaman or Druid)
            [-3] = { "holy" },                  -- (Pala or Priest)
            [-4] = { "protection", "prot" },    -- (Pala or Warrior)

            -- Druid
            [1] = { "restoration druid", "resto druid", "rdruid", "rd" },
            [2] = { "feral", "fdruid" },
            [3] = { "balance", "bdruid", "moonkin", "boomkin", "boomy" },

            -- Paladin
            [11] = { "holy paladin", "holy pala", "holy pal", "hpal", "hpala", "hpaladin", "holypaladin", "holypala" },
            [12] = { "protection paladin", "prot paladin", "protection pala", "prot pala" },
            [13] = { "preg" },
            [14] = { "retribution", "ret", "rpala" },

            -- Shaman
            [21] = { "restoration shaman", "restoration sham", "resto shaman", "resto sham", "rshaman", "rsham" },
            [22] = { "elemental", "ele" },
            [23] = { "enhancement", "enh" },

            -- Death Knight
            [31] = { "unholy", "uhdk", "udk", "uh" },
            [32] = { "frost death knight", "frost deathknight", "frost dk", "fdk" },
            [33] = { "bdk", "blood" },

            -- Hunter
            [41] = { "beast mastery", "beastmastery", "bm", "bmhunter", "bmhunt" },
            [42] = { "marksmanship", "marksman", "mm", "mmhunter", "mmhunt" },
            [43] = { "survival", "surv", "shunter", "shunt", "sh" },

            -- Mage
            [51] = { "frost mage" },
            [52] = { "fire" },
            [53] = { "arcane", "amage" },

            -- Rogue
            [61] = { "subtlety", "sub", "srogue", "srog" },
            [62] = { "assassination", "assa", "arogue" },
            [63] = { "combat", "crogue" },
            [64] = { "outlaw", "orogue" },

            -- Warlock
            [71] = { "affliction", "affli", "awarlock", "alock" },
            [72] = { "destruction", "destro" },
            [73] = { "demonology", "demo" },

            -- Warrior
            [81] = { "protection warrior", "protection warr", "prot warrior", "prot warr", "protection war", "prot war", "pwarrior", "pwarr" },
            [82] = { "arms", "awarrior", "awarr" },
            [83] = { "fury", "fwarrior", "fwarr", "fwar" },

            -- Priest
            [91] = { "discipline", "disc", "dpriest", "dp" },
            [92] = { "holy priest", "hpriest" },
            [93] = { "shadow", "spriest", "sp" },

            -- Monk
            [101] = { "mistweaver", "mwmonk", "mw" },
            [102] = { "brewmaster", "bmmonk" },
            [103] = { "windwalker", "wwmonk", "ww" },

            -- Demon Hunter
            [111] = { "havoc", "hdh" },
            [112] = { "vengeance", "vdh" },

            -- Evoker
            [121] = { "preservation", "prevoker", "pres" },
            [122] = { "augmentation", "augvoker", "aug" },
            [123] = { "devastation", "devoker", "dev" },
        },
    },
    ["race"] = {
        noSpace = false,
        values = {
            [1]  = { "human" },
            [2]  = { "orc" },
            [3]  = { "dwarf" },
            [4]  = { "undead" },
            [5]  = { "night elf", "nightelf", "nelf" },
            [6]  = { "tauren" },
            [7]  = { "gnome" },
            [8]  = { "troll" },
            [9]  = { "draenei" },
            [10] = { "blood elf", "bloodelf", "belf" },
            [11] = { "worgen" },
            [12] = { "goblin" },
            [13] = { "pandaren" }, -- Also matches 14, by neutralRaceRedirects table
            [15] = { "dracthyr" }, -- Also matches 16, by neutralRaceRedirects table
            [17] = { "void elf", "voidelf", "velf" },
            [18] = { "nightborne" },
            [19] = { "lightforged draenei", "lightforgeddraenei", "ldraenei" },
            [20] = { "highmountain tauren", "highmountaintauren", "htauren" },
            [21] = { "dark iron dwarf", "darkirondwarf", "didwarf", "ddwarf" },
            [22] = { "mag'har orc", "magharorc", "morc" },
            [23] = { "earthen" }, -- Also matches 24, by neutralRaceRedirects table
            [25] = { "kul tiran", "kultiran" },
            [26] = { "zandalari troll", "zandalaritroll", "ztroll" },
            [27] = { "mechagnome", "mgnome" },
            [28] = { "vulpera" },
        }
    },
    ["faction"] = {
        noSpace = true,
        values = {
            [0] = { "horde" },
            [1] = { "alliance" },
        },
    },
    ["role"] = {
        noSpace = false,
        values = { -- Bitmap indexes
            [1] = { "tank" },
            [2] = { "damage dealer", "damage", "dps" },
            [3] = { "healer" },
            [4] = { "caster" },
            [5] = { "ranged" },
            [6] = { "melee" },
        },
    },
    ["team"] = {
        requireExact = true,
        noSpace = true,
        values = {
            ["team"] = { "team", "friend", "help", "partner" },
            ["enemy"] = { "enemy", "foe", "harm", "hostile" },
        },
    },
    ["logical"] = {
        requireExact = true,
        values = {
            ["not"] = { "not", "no", "inverse" },
            ["self"] = { "self", "me" },
        },
    },
};

function Search:GetShortValueName(typeKey, valueKey)
    if(not typeKey or not valueKey) then
        ArenaAnalytics:Log("GetShortValueName called with invalid params:", typeKey, valueKey);
        return nil;
    end

    local typeTable = SearchTokenTypeTable[typeKey];
    if(not typeTable or not typeTable.values) then
        ArenaAnalytics:Log("GetShortValueName missing typeTable for params:", typeKey, valueKey);
        return nil;
    end

    local valueTable = typeTable.values[valueKey];
    if(not valueTable) then
        ArenaAnalytics:Log("GetShortValueName missing valueTable for params:", typeKey, valueKey);
        return nil;
    end

    local bestIndex, shortestLength = nil,nil;
    for key,value in pairs(valueTable) do
        if(not bestIndex or #value < shortestLength) then
            bestIndex = key;
            shortestLength = #value;
        end
    end

    return bestIndex and valueTable[bestIndex];
end

-- Find typeKey, valueKey, noSpace from SearchTokenTypeTable
function Search:FindSearchValueDataForToken(token)
    assert(token);

    if(token.value == nil or type(token.value) == "string" and #token.value < 2) then
        return;
    end

    local lowerCaseValue = Helpers:ToSafeLower(token.value);

    -- Cached info about the best match
    local bestMatch = nil;
    local function SetBestMatch(score, typeKey, valueKey, noSpace, isExactMatch)
        bestMatch = {
            ["score"] = score,
            ["typeKey"] = typeKey,
            ["valueKey"] = valueKey,
            ["noSpace"] = noSpace,
            ["isExactMatch"] = isExactMatch,
        };
    end

    local function TryUpdateBestMatch(matchedValue, typeKey, valueKey, noSpace, startIndex)
        local score = CalculateMatchScore(token.value, matchedValue, startIndex);
        if(not bestMatch or (not bestMatch.isExactMatch and score > bestMatch.score)) then
            SetBestMatch(score, typeKey, valueKey, noSpace);
        end
    end

    local function FindTokenValueKey(valueTable, searchType)
        assert(valueTable and valueTable.values);

        for valueKey, values in pairs(valueTable.values) do
            if(token.value == valueKey) then
                SetBestMatch(nil, searchType, valueKey, valueTable.noSpace, true);
                return true;
            elseif(type(token.value) == "string") then
                for _, value in ipairs(values) do
                    assert(value);
                    if(token.value == value) then
                        SetBestMatch(nil, searchType, valueKey, valueTable.noSpace, true);
                        return true;
                    elseif(not token.exact and not valueTable.requireExact) then
                        local foundStartIndex = value:find(token.value, 1, true);
                        if(foundStartIndex ~= nil) then
                            TryUpdateBestMatch(value, searchType, valueKey, valueTable.noSpace, foundStartIndex);
                        end
                    end
                end
            end
        end
    end

    -- Look through the values for the explicit key
    if token.explicitType then
        local valueTable = SearchTokenTypeTable[token.explicitType];
        if valueTable then
            local isExactMatch = FindTokenValueKey(valueTable, token.explicitType);
        end
    else -- Look through all keys
        for typeKey, valueTable in pairs(SearchTokenTypeTable) do
            local isExactMatch = FindTokenValueKey(valueTable, typeKey)
            if(isExactMatch) then
                break;
            end
        end
    end

    -- Evaluate best match so far, if any.
    if(bestMatch) then
        local shortName = Search:GetShortValueName(bestMatch.typeKey, bestMatch.valueKey);
        ArenaAnalytics:Log("Search best match:", bestMatch.typeKey, bestMatch.valueKey, bestMatch.noSpace, shortName);

        return bestMatch.typeKey, bestMatch.valueKey, bestMatch.noSpace, shortName;
    end
end
