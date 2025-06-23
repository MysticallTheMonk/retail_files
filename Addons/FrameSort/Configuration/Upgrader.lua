---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsLog = addon.Logging.Log
local fsConfig = addon.Configuration
---@class OptionsUpgrader
local M = {}

addon.Configuration.Upgrader = M

function M:UpgradeToVersion2(options)
    assert(options.Version == nil or options.Version == 1)

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
end

function M:UpgradeToVersion3(options)
    assert(options.Version == 2)

    options.ExperimentalEnabled = false
    options.Version = 3
end

function M:UpgradeToVersion4(options)
    assert(options.Version == 3)

    options.SortingMethod = {
        TaintlessEnabled = true,
        TraditionalEnabled = false,
    }

    options.Version = 4
end

function M:UpgradeToVersion5(options)
    assert(options.Version == 4)

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
end

function M:UpgradeToVersion6(options)
    assert(options.Version == 5)

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
end

function M:UpgradeToVersion7(options)
    assert(options.Version == 6)

    options.Debug.Enabled = false
    options.Version = 7
end

function M:UpgradeToVersion8(options)
    assert(options.Version == 7)

    options.Arena.Reverse = false
    options.Dungeon.Reverse = false
    options.Raid.Reverse = false
    options.World.Reverse = false
    options.Version = 8
end

function M:UpgradeToVersion9(options)
    assert(options.Version == 8)

    options.Debug = nil
    options.Logging = {
        Enabled = false,
    }
    options.Version = 9
end

local function CleanTable(options, defaults)
    -- remove values that aren't ours
    for k, v in pairs(options) do
        if defaults[k] == nil then
            options[k] = nil
        elseif v ~= nil and type(v) == "table" then
            CleanTable(options[k], defaults[k])
        end
    end
end

local function AddMissing(options, defaults)
    -- add defaults for any missing values
    for k, v in pairs(defaults) do
        if options[k] == nil then
            options[k] = v
        elseif type(v) == "table" then
            AddMissing(options[k], defaults[k])
        end
    end
end

function M:UpgradeToVersion10(options)
    assert(options.Version == 9)

    -- encountered a clash with Ability Team Tracker also using the "Options" global variable
    -- so clean up our saved variable for anyone affected
    local v10Defaults = {
        Version = 10,
        Logging = {
            Enabled = false,
        },
        Arena = {
            Enabled = true,
            PlayerSortMode = fsConfig.PlayerSortMode.Top,
            GroupSortMode = fsConfig.GroupSortMode.Group,
            Reverse = false,
        },
        Dungeon = {
            Enabled = true,
            PlayerSortMode = fsConfig.PlayerSortMode.Top,
            GroupSortMode = fsConfig.GroupSortMode.Role,
            Reverse = false,
        },
        World = {
            Enabled = true,
            PlayerSortMode = fsConfig.PlayerSortMode.Top,
            GroupSortMode = fsConfig.GroupSortMode.Group,
            Reverse = false,
        },
        Raid = {
            Enabled = false,
            PlayerSortMode = fsConfig.PlayerSortMode.Top,
            GroupSortMode = fsConfig.GroupSortMode.Role,
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
    CleanTable(options, v10Defaults)

    -- add any missing values back
    AddMissing(options, v10Defaults)

    options.Version = 10
end

function M:UpgradeToVersion11(options)
    assert(options.Version == 10)

    options.Appearance.EnemyArena = {
        Spacing = {
            Horizontal = 0,
            Vertical = 0,
        },
    }

    options.Version = 11
end

function M:UpgradeToVersion12(options)
    assert(options.Version == 11)

    options.EnemyArena = {
        Enabled = false,
        GroupSortMode = fsConfig.GroupSortMode.Group,
        Reverse = false,
    }

    options.Version = 12
end

function M:UpgradeToVersion13(options)
    assert(options.Version == 12)

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
end

function M:UpgradeToVersion14(options)
    assert(options.Version == 13)

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
end

function M:UpgradeToVersion15(options)
    assert(options.Version == 14)

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
end

function M:UpgradeToVersion16(options)
    assert(options.Version == 15)

    options.Sorting = {
        RoleOrdering = 1,
    }

    options.Version = 16
end

function M:UpgradeToVersion17(options)
    assert(options.Version == 16)

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
end

function M:UpgradeToVersion18(options)
    assert(options.Version == 17)

    -- missed some areas that were still referencing this instead of Sorting.Method
    -- so clear it again
    options.SortingMethod = nil

    options.Version = 18
end

function M:UpgradeToVersion19(options)
    assert(options.Version == 18)

    local arena = wow.CopyTable(options.Sorting.Arena)

    options.Sorting.Arena.Twos = wow.CopyTable(arena)
    options.Sorting.Arena.Default = wow.CopyTable(arena)

    options.Sorting.Arena.Enabled = nil
    options.Sorting.Arena.PlayerSortMode = nil
    options.Sorting.Arena.GroupSortMode = nil
    options.Sorting.Arena.Reverse = nil

    options.Version = 19
end

function M:UpgradeToVersion20(options)
    assert(options.Version == 19)

    options.AutoLeader = {
        Enabled = true,
    }

    options.Version = 20
end

function M:UpgradeToVersion21(options)
    assert(options.Version == 20)

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
end

---Upgrades saved options to the current version.
function M:UpgradeOptions(options)
    while (options.Version or 1) < fsConfig.Defaults.Version do
        local currentVersion = options.Version or 1
        local nextVersion = currentVersion + 1
        local next = M["UpgradeToVersion" .. nextVersion]

        assert(next ~= nil)

        fsLog:Debug("Upgrading options to version " .. nextVersion .. ".")
        next(M, options)
    end
end
