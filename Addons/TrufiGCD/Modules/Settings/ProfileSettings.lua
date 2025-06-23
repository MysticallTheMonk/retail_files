---@type string, Namespace
local _, ns = ...

---@class ProfileSettings
local ProfileSettings = {}
ProfileSettings.__index = ProfileSettings
ns.ProfileSettings = ProfileSettings

---@param savedVariables ProfileVariablesV1 | ProfileVariablesV2
function ProfileSettings:New(savedVariables)
    ---@class ProfileSettings
    local obj = setmetatable({}, ProfileSettings)

    obj.id = ns.utils.uuid()
    obj.name = ns.utils.defaultProfileName()

    obj.enabledIn = {
        enabled = true,
        party = true,
        arena = true,
        battleground = true,
        world = true,
        raid = true,
        combatOnly = false,
    }

    obj.iconsScroll = true
    obj.tooltipEnabled = true
    obj.tooltipPrintSpellId = false
    obj.tooltipStopScroll = true
    obj.iconClickAddsSpellToBlocklist = false

    ---@type number[]
    obj.blocklist = {
        6603, --Attack
        75, --Auto Shot
        7384, --Overpower
    }

    ---@type {[UnitType]: UnitSettings}
    obj.unitSettings = {}
    for _, unitType in ipairs(ns.constants.unitTypes) do
        obj.unitSettings[unitType] = ns.UnitSettings:New(unitType)
    end

    ---@type {[LayoutType]: LayoutSettings}
    obj.layoutSettings = {}
    for _, layoutType in ipairs(ns.constants.layoutTypes) do
        obj.layoutSettings[layoutType] = ns.LayoutSettings:New()
    end

    --By default enable only player frame - not many people use anything else
    obj.layoutSettings.player.enable = true

    obj:SetFromSavedVariables(savedVariables)

    return obj
end

---@private
---@param savedVariables ProfileVariablesV1 | ProfileVariablesV2
function ProfileSettings:SetFromSavedVariables(savedVariables)
    if type(savedVariables.id) == "string" then
        self.id = savedVariables.id
    else
        self.id = ns.utils.uuid()
    end

    if type(savedVariables.name) == "string" then
        self.name = savedVariables.name
    else
        self.name = ns.utils.defaultProfileName()
    end

    if type(savedVariables.EnableIn) == "table" then
        if type(savedVariables.EnableIn.Enable) == "boolean" then
            self.enabledIn.enabled = savedVariables.EnableIn.Enable
        end
        if type(savedVariables.EnableIn.PvE) == "boolean" then
            self.enabledIn.party = savedVariables.EnableIn.PvE
        end
        if type(savedVariables.EnableIn.Arena) == "boolean" then
            self.enabledIn.arena = savedVariables.EnableIn.Arena
        end
        if type(savedVariables.EnableIn.Bg) == "boolean" then
            self.enabledIn.battleground = savedVariables.EnableIn.Bg
        end
        if type(savedVariables.EnableIn.World) == "boolean" then
            self.enabledIn.world = savedVariables.EnableIn.World
        end
        if type(savedVariables.EnableIn.Raid) == "boolean" then
            self.enabledIn.raid = savedVariables.EnableIn.Raid
        end
        if type(savedVariables.EnableIn["Combat only"]) == "boolean" then
            self.enabledIn.combatOnly = savedVariables.EnableIn["Combat only"]
        end
    end

    if type(savedVariables.ModScroll) == "boolean" then
        self.iconsScroll = savedVariables.ModScroll
    end
    if type(savedVariables.TooltipEnable) == "boolean" then
        self.tooltipEnabled = savedVariables.TooltipEnable
    end
    if type(savedVariables.TooltipSpellID) == "boolean" then
        self.tooltipPrintSpellId = savedVariables.TooltipSpellID
    end
    if type(savedVariables.TooltipStopMove) == "boolean" then
        self.tooltipStopScroll = savedVariables.TooltipStopMove
    end
    if type(savedVariables.iconClickAddsSpellToBlocklist) == "boolean" then
        self.iconClickAddsSpellToBlocklist = savedVariables.iconClickAddsSpellToBlocklist
    end

    -- Support for V1
    if type(savedVariables.TrGCDQueueFr) == "table" then
        for unitIndex = 1, 12 do
            local unitSaves = savedVariables.TrGCDQueueFr[unitIndex]
            local unitType = ns.constants.unitTypes[unitIndex]
            local unitSettings = self.unitSettings[unitType]

            if type(unitSaves) == "table" and unitSettings then
                unitSettings:SetFromSavedVariables(unitSaves)
            end
        end

        ---@type {[LayoutType]: number}
        local v1UnitSavesMapping = {
            player = 1,
            party = 2,
            arena = 6,
            target = 11,
            focus = 12,
        }
        for layoutType, layoutSettings in pairs(self.layoutSettings) do
            local unitIndex = v1UnitSavesMapping[layoutType]
            local unitSaves = savedVariables.TrGCDQueueFr[unitIndex]
            if type(unitSaves) == "table" then
                layoutSettings:SetFromSavedVariables(unitSaves)
            end
        end
    else
        if type(savedVariables.layouts) == "table" then
            for layoutType, layoutSaves in pairs(savedVariables.layouts) do
                if type(layoutSaves) == "table" and self.layoutSettings[layoutType] then
                    self.layoutSettings[layoutType]:SetFromSavedVariables(layoutSaves)
                end
            end
        end
        if type(savedVariables.units) == "table" then
            for unitType, unitSaves in pairs(savedVariables.units) do
                if type(unitSaves) == "table" and self.unitSettings[unitType] then
                    self.unitSettings[unitType]:SetFromSavedVariables(unitSaves)
                end
            end
        end
    end

    self.blocklist = {}
    if type(savedVariables.TrGCDBL) == "table" then
        for i, v in ipairs(savedVariables.TrGCDBL) do
            if type(v) == "number" then
                self.blocklist[i] = v
            end
        end
    end
end

function ProfileSettings:GetSavedVariables()
    ---@type ProfileVariablesV2
    local savedVariables = {}

    savedVariables.id = self.id
    savedVariables.name = self.name
    savedVariables.EnableIn = {}
    savedVariables.EnableIn.Enable = self.enabledIn.enabled
    savedVariables.EnableIn.PvE = self.enabledIn.party
    savedVariables.EnableIn.Arena = self.enabledIn.arena
    savedVariables.EnableIn.Bg = self.enabledIn.battleground
    savedVariables.EnableIn.World = self.enabledIn.world
    savedVariables.EnableIn.Raid = self.enabledIn.raid
    savedVariables.EnableIn["Combat only"] = self.enabledIn.combatOnly
    savedVariables.ModScroll = self.iconsScroll
    savedVariables.TooltipEnable = self.tooltipEnabled
    savedVariables.TooltipSpellID = self.tooltipPrintSpellId
    savedVariables.TooltipStopMove = self.tooltipStopScroll
    savedVariables.iconClickAddsSpellToBlocklist = self.iconClickAddsSpellToBlocklist

    savedVariables.layouts = {}
    for layoutType, layoutSettings in pairs(self.layoutSettings) do
        savedVariables.layouts[layoutType] = layoutSettings:GetSavedVariables()
    end

    savedVariables.units = {}
    for unitType, unitSettings in pairs(self.unitSettings) do
        savedVariables.units[unitType] = unitSettings:GetSavedVariables()
    end

    savedVariables.TrGCDBL = {}
    for _, v in ipairs(self.blocklist) do
        table.insert(savedVariables.TrGCDBL, v)
    end

    return savedVariables
end
