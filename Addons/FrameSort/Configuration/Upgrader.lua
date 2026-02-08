---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsLog = addon.Logging.Log
local fsConfig = addon.Configuration
---@class OptionsUpgrader
local M = {}

addon.Configuration.Upgrader = M

---Removes any erronous values from the options table.
---@param target table the target table to clean
---@param template table what the table should look like
---@param cleanValues any whether or not to clean non-table values, e.g. numbers and strings
---@param recurse any whether to recursively clean the table
local function CleanTable(target, template, cleanValues, recurse)
    -- remove values that aren't ours
    if type(target) ~= "table" or type(template) ~= "table" then
        return
    end

    for key, value in pairs(target) do
        local templateValue = template[key]

        -- only clean non-table values if told to do so
        if cleanValues and templateValue == nil then
            target[key] = nil
            fsLog:Warning("Removed erroneous db value %s", key)
        end

        if recurse then
            if type(value) == "table" and type(templateValue) == "table" then
                CleanTable(value, templateValue, cleanValues, recurse)
            elseif type(value) == "table" and type(templateValue) ~= "table" then
                -- type mismatch: reset this key to default
                target[key] = templateValue
                fsLog:Warning("Replaced existing key %s with defaults.", key)
            end
        end
    end
end

---Recursively adds any missing keys to the target.
---@param target table the target table to clean
---@param template table what the table should look like
local function AddMissing(target, template)
    if type(target) ~= "table" or type(template) ~= "table" then
        return
    end

    for key, value in pairs(template) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = wow.CopyTable(value)
            else
                target[key] = value
            end

            fsLog:Warning("Added missing key %s to options table.", key)
        elseif type(value) == "table" and type(target[key]) == "table" then
            AddMissing(target[key], value)
        elseif type(value) == "table" and type(target[key]) ~= "table" then
            target[key] = wow.CopyTable(value)
            fsLog:Warning("Replaced existing key %s with defaults.", key)
        end
    end
end

---Returns true if the target has the same set of keys as the template.
---However the target may also have more keys than template.
local function HasSameKeys(target, template)
    for key, value in pairs(template) do
        if target[key] == nil then
            return false
        end

        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                return false
            end

            if not HasSameKeys(target[key], value) then
                return false
            end
        end
    end

    return true
end

function M:UpgradeToVersion2(options)
    if options.Version ~= nil and options.Version ~= 1 then
        return false
    end

    options.ArenaEnabled = options.PartySortEnabled
    options.ArenaPlayerSortMode = options.PlayerSortMode
    options.ArenaSortMode = options.PartySortMode

    options.DungeonEnabled = options.PartySortEnabled
    options.DungeonPlayerSortMode = options.PlayerSortMode
    options.DungeonSortMode = options.PartySortMode

    options.WorldEnabled = options.PartySortEnabled
    options.WorldPlayerSortMode = options.PlayerSortMode
    options.WorldSortMode = options.PartySortMode

    options.RaidEnabled = options.RaidSortEnabled
    options.RaidPlayerSortMode = options.PlayerSortMode

    options.DebugEnabled = false

    options.PartySortEnabled = nil
    options.PartySortMode = nil
    options.PlayerSortMode = nil
    options.RaidSortEnabled = nil
    options.Version = 2

    return true
end

function M:UpgradeToVersion3(options)
    if options.Version ~= 2 then
        return false
    end

    options.ExperimentalEnabled = false
    options.Version = 3

    return true
end

function M:UpgradeToVersion4(options)
    if options.Version ~= 3 then
        return false
    end

    options.SortingMethod = {
        TaintlessEnabled = true,
        TraditionalEnabled = false,
    }

    options.Version = 4

    return true
end

function M:UpgradeToVersion5(options)
    if options.Version ~= 4 then
        return false
    end

    options.Debug = {
        Enabled = options.DebugEnabled,
    }

    options.Arena = {
        Enabled = options.ArenaEnabled,
        PlayerSortMode = options.ArenaPlayerSortMode,
        GroupSortMode = options.ArenaSortMode,
    }

    options.Dungeon = {
        Enabled = options.DungeonEnabled,
        PlayerSortMode = options.DungeonPlayerSortMode,
        GroupSortMode = options.DungeonSortMode,
    }

    options.Raid = {
        Enabled = options.RaidEnabled,
        PlayerSortMode = options.RaidPlayerSortMode,
        GroupSortMode = options.RaidSortMode,
    }

    options.World = {
        Enabled = options.WorldEnabled,
        PlayerSortMode = options.WorldPlayerSortMode,
        GroupSortMode = options.WorldSortMode,
    }

    options.DebugEnabled = nil

    options.ArenaEnabled = nil
    options.ArenaPlayerSortMode = nil
    options.ArenaSortMode = nil

    options.DungeonEnabled = nil
    options.DungeonPlayerSortMode = nil
    options.DungeonSortMode = nil

    options.RaidEnabled = nil
    options.RaidPlayerSortMode = nil
    options.RaidSortMode = nil

    options.WorldEnabled = nil
    options.WorldPlayerSortMode = nil
    options.WorldSortMode = nil

    -- forgot to remove this in version 4
    options.ExperimentalEnabled = nil

    options.Version = 5

    return true
end

function M:UpgradeToVersion6(options)
    if options.Version ~= 5 then
        return false
    end

    options.Appearance = {
        Party = {
            Spacing = {
                Horizontal = 0,
                Vertical = 0,
            },
        },
        Raid = {
            Spacing = {
                Horizontal = 0,
                Vertical = 0,
            },
        },
    }

    options.Version = 6

    return true
end

function M:UpgradeToVersion7(options)
    if options.Version ~= 6 then
        return false
    end

    if not options.Debug then
        options.Debug = {}
    end

    options.Debug.Enabled = false
    options.Version = 7

    return true
end

function M:UpgradeToVersion8(options)
    if options.Version ~= 7 then
        return false
    end

    if not options.Arena or not options.Dungeon or not options.Raid or not options.World then
        return false
    end

    options.Arena.Reverse = false
    options.Dungeon.Reverse = false
    options.Raid.Reverse = false
    options.World.Reverse = false
    options.Version = 8

    return true
end

function M:UpgradeToVersion9(options)
    if options.Version ~= 8 then
        return false
    end

    options.Debug = nil
    options.Logging = {
        Enabled = false,
    }
    options.Version = 9

    return true
end

function M:UpgradeToVersion10(options)
    if options.Version ~= 9 then
        return false
    end

    -- encountered a clash with Ability Team Tracker also using the "Options" global variable
    -- so clean up our saved variable for anyone affected
    local v10Defaults = {
        Version = 10,
        Logging = {
            Enabled = false,
        },
        Arena = {
            Enabled = true,
            PlayerSortMode = "Top",
            GroupSortMode = "Group",
            Reverse = false,
        },
        Dungeon = {
            Enabled = true,
            PlayerSortMode = "Top",
            GroupSortMode = "Role",
            Reverse = false,
        },
        World = {
            Enabled = true,
            PlayerSortMode = "Top",
            GroupSortMode = "Group",
            Reverse = false,
        },
        Raid = {
            Enabled = false,
            PlayerSortMode = "Top",
            GroupSortMode = "Role",
            Reverse = false,
        },
        SortingMethod = {
            TaintlessEnabled = true,
            TraditionalEnabled = false,
        },
        Appearance = {
            Party = {
                Spacing = {
                    Horizontal = 0,
                    Vertical = 0,
                },
            },
            Raid = {
                Spacing = {
                    Horizontal = 0,
                    Vertical = 0,
                },
            },
        },
    }

    -- remove clashing values
    CleanTable(options, v10Defaults, true)

    -- add any missing values back
    AddMissing(options, v10Defaults)

    options.Version = 10

    return true
end

function M:UpgradeToVersion11(options)
    if options.Version ~= 10 then
        return false
    end

    if not options.Appearance then
        return false
    end

    options.Appearance.EnemyArena = {
        Spacing = {
            Horizontal = 0,
            Vertical = 0,
        },
    }

    options.Version = 11

    return true
end

function M:UpgradeToVersion12(options)
    if options.Version ~= 11 then
        return false
    end

    options.EnemyArena = {
        Enabled = false,
        GroupSortMode = "Group",
        Reverse = false,
    }

    options.Version = 12

    return true
end

function M:UpgradeToVersion13(options)
    if options.Version ~= 12 then
        return false
    end

    if not options.SortingMethod then
        return false
    end

    local methods = {
        Secure = 1,
        Taintless = 2,
        Traditional = 3,
    }

    ---@diagnostic disable-next-line: undefined-field
    if options.SortingMethod.TaintlessEnabled then
        options.SortingMethod = methods.Taintless
    else
        options.SortingMethod = methods.Traditional
    end

    options.Version = 13

    return true
end

function M:UpgradeToVersion14(options)
    if options.Version ~= 13 then
        return false
    end

    if not options.SortingMethod then
        return false
    end

    local methods = {
        Secure = 1,
        Taintless = 2,
        Traditional = 3,
    }

    -- move people to using Secure instead of Taintless
    if options.SortingMethod == methods.Taintless then
        options.SortingMethod = methods.Secure
    end

    options.Version = 14

    return true
end

function M:UpgradeToVersion15(options)
    if options.Version ~= 14 then
        return false
    end

    if not options.SortingMethod then
        return false
    end

    local methods = {
        Secure = 1,
        Taintless = 2,
        Traditional = 3,
    }

    if options.SortingMethod == methods.Traditional then
        options.SortingMethod = "Traditional"
    else
        options.SortingMethod = "Secure"
    end

    options.Version = 15

    return true
end

function M:UpgradeToVersion16(options)
    if options.Version ~= 15 then
        return false
    end

    options.Sorting = {
        RoleOrdering = 1,
    }

    options.Version = 16

    return true
end

function M:UpgradeToVersion17(options)
    if options.Version ~= 16 then
        return false
    end

    if not options.Sorting then
        return false
    end

    if not options.Appearance or not options.Appearance.Party or not options.Appearance.Raid or not options.Appearance.EnemyArena then
        return false
    end

    options.Sorting.Method = options.SortingMethod
    options.Sorting.Arena = options.Arena
    options.Sorting.EnemyArena = options.EnemyArena
    options.Sorting.Dungeon = options.Dungeon
    options.Sorting.Raid = options.Raid
    options.Sorting.World = options.World

    options.SortingMethod = nil
    options.Arena = nil
    options.EnemyArena = nil
    options.Dungeon = nil
    options.Raid = nil
    options.World = nil

    options.Spacing = {
        Party = options.Appearance.Party.Spacing,
        Raid = options.Appearance.Raid.Spacing,
        EnemyArena = options.Appearance.EnemyArena.Spacing,
    }

    options.Appearance = nil
    options.Version = 17

    return true
end

function M:UpgradeToVersion18(options)
    if options.Version ~= 17 then
        return false
    end

    -- missed some areas that were still referencing this instead of Sorting.Method
    -- so clear it again
    options.SortingMethod = nil
    options.Version = 18

    return true
end

function M:UpgradeToVersion19(options)
    if options.Version ~= 18 then
        return false
    end

    if not options.Sorting or not options.Sorting.Arena then
        return false
    end

    local arena = wow.CopyTable(options.Sorting.Arena)

    options.Sorting.Arena.Twos = wow.CopyTable(arena)
    options.Sorting.Arena.Default = wow.CopyTable(arena)

    options.Sorting.Arena.Enabled = nil
    options.Sorting.Arena.PlayerSortMode = nil
    options.Sorting.Arena.GroupSortMode = nil
    options.Sorting.Arena.Reverse = nil

    options.Version = 19

    return true
end

function M:UpgradeToVersion20(options)
    if options.Version ~= 19 then
        return false
    end

    options.AutoLeader = {
        Enabled = true,
    }

    options.Version = 20

    return true
end

function M:UpgradeToVersion21(options)
    if options.Version ~= 20 then
        return false
    end

    if not options.Sorting then
        return false
    end

    -- Tank -> Healer - > Dps
    if options.Sorting.RoleOrdering == 1 or not options.Sorting.RoleOrdering then
        options.Sorting.Ordering = {
            Tanks = 1,
            Healers = 2,
            Casters = 3,
            Hunters = 4,
            Melee = 5,
        }
        -- Healer -> Tank - > Dps
    elseif options.Sorting.RoleOrdering == 2 then
        options.Sorting.Ordering = {
            Healers = 1,
            Tanks = 2,
            Casters = 3,
            Hunters = 4,
            Melee = 5,
        }
        -- Healer -> Dps - > Tank
    elseif options.Sorting.RoleOrdering == 3 then
        options.Sorting.Ordering = {
            Healers = 1,
            Casters = 2,
            Hunters = 3,
            Melee = 4,
            Tanks = 5,
        }
    end

    options.Sorting.RoleOrdering = nil
    options.Version = 21

    return true
end

function M:UpgradeToVersion22(options)
    if options.Version ~= 21 then
        return false
    end

    options.Logging = nil
    options.Version = 22

    return true
end

function M:UpgradeToVersion23(options)
    if options.Version ~= 22 then
        return false
    end

    options.Nameplates = {
        FriendlyEnabled = false,
        EnemyEnabled = false,
        FriendlyFormat = "$framenumber",
        EnemyFormat = "$framenumber",
    }
    options.Version = 23

    return true
end

function M:UpgradeToVersion24(options)
    if options.Version ~= 23 then
        return false
    end

    options.Sorting.Miscellaneous = {
        PlayerRoleSort = "None",
    }
    options.Version = 24

    return true
end

function M:UpgradeToVersion25(options)
    if options.Version ~= 24 then
        return false
    end

    options.Locale = ""
    options.Version = 25

    return true
end

---Upgrades saved variables database to the current version.
function M:UpgradeDb(db)
    local options = db.Options

    if options.Version and options.Version > fsConfig.DbDefaults.Options.Version then
        -- they are running a version ahead of us
        return false
    end

    local isCorrupt = false

    while (options.Version or 1) < fsConfig.DbDefaults.Options.Version do
        local currentVersion = options.Version or 1
        local nextVersion = currentVersion + 1
        local next = M["UpgradeToVersion" .. nextVersion]

        isCorrupt = next == nil

        if isCorrupt then
            break
        end

        fsLog:Debug("Upgrading options to version %s.", nextVersion)

        if not next(M, options) then
            isCorrupt = true
            break
        end
    end

    if isCorrupt then
        return false
    end

    -- clean any unknown values from our db
    CleanTable(db, fsConfig.DbDefaults, true, false)

    -- add any missing defaults
    AddMissing(db, fsConfig.DbDefaults)

    -- make sure the tables match in terms of their keys
    isCorrupt = not HasSameKeys(options, fsConfig.DbDefaults.Options)

    return not isCorrupt
end
