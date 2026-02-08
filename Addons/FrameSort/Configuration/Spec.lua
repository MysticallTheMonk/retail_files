---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
---@class Specs
local M = {}

addon.Configuration.Specs = M

---@class SpecType
M.Type = {
    Tank = 1,
    Healer = 2,
    Hunter = 3,
    Caster = 4,
    Melee = 5,
}

---@type SpecInfo[]
M.Specs = {
    -- prot pally
    { ClassId = 2, SpecId = 66, Type = M.Type.Tank },
    -- prot warrior
    { ClassId = 1, SpecId = 73, Type = M.Type.Tank },
    -- guardian druid
    { ClassId = 11, SpecId = 104, Type = M.Type.Tank },
    -- blood dk
    { ClassId = 6, SpecId = 250, Type = M.Type.Tank },
    -- brewmaster
    { ClassId = 10, SpecId = 268, Type = M.Type.Tank },
    -- vengeance
    { ClassId = 12, SpecId = 581, Type = M.Type.Tank },

    -- hpal
    { ClassId = 2, SpecId = 65, Type = M.Type.Healer },
    -- rdruid
    { ClassId = 11, SpecId = 105, Type = M.Type.Healer },
    -- disc priest
    { ClassId = 5, SpecId = 256, Type = M.Type.Healer },
    -- holy priest
    { ClassId = 5, SpecId = 257, Type = M.Type.Healer },
    -- resto shaman
    { ClassId = 7, SpecId = 264, Type = M.Type.Healer },
    -- mistweaver
    { ClassId = 10, SpecId = 270, Type = M.Type.Healer },
    -- preservation
    { ClassId = 13, SpecId = 1468, Type = M.Type.Healer },

    -- arcane mage
    { ClassId = 8, SpecId = 62, Type = M.Type.Caster },
    -- fire mage
    { ClassId = 8, SpecId = 63, Type = M.Type.Caster },
    -- frost mage
    { ClassId = 8, SpecId = 64, Type = M.Type.Caster },
    -- boomkin
    { ClassId = 11, SpecId = 102, Type = M.Type.Caster },
    -- shadow priest
    { ClassId = 5, SpecId = 258, Type = M.Type.Caster },
    -- ele sham
    { ClassId = 7, SpecId = 262, Type = M.Type.Caster },
    -- affi lock
    { ClassId = 9, SpecId = 265, Type = M.Type.Caster },
    -- demo lock
    { ClassId = 9, SpecId = 266, Type = M.Type.Caster },
    -- destro lock
    { ClassId = 9, SpecId = 267, Type = M.Type.Caster },
    -- devastation
    { ClassId = 13, SpecId = 1467, Type = M.Type.Caster },
    -- aug voker
    { ClassId = 13, SpecId = 1473, Type = M.Type.Caster },

    -- bm hunter
    { ClassId = 3, SpecId = 253, Type = M.Type.Hunter },
    -- mm hunter
    { ClassId = 3, SpecId = 254, Type = M.Type.Hunter },
    -- survival hunter
    { ClassId = 3, SpecId = 255, Type = M.Type.Hunter },

    -- ret pally
    { ClassId = 2, SpecId = 70, Type = M.Type.Melee },
    -- arms warr
    { ClassId = 1, SpecId = 71, Type = M.Type.Melee },
    -- fury warr
    { ClassId = 1, SpecId = 72, Type = M.Type.Melee },
    -- feral
    { ClassId = 11, SpecId = 103, Type = M.Type.Melee },
    -- frost dk
    { ClassId = 6, SpecId = 251, Type = M.Type.Melee },
    -- unholy dk
    { ClassId = 6, SpecId = 252, Type = M.Type.Melee },
    -- assa rogue
    { ClassId = 4, SpecId = 259, Type = M.Type.Melee },
    -- outlaw rogue
    { ClassId = 4, SpecId = 260, Type = M.Type.Melee },
    -- sub rogue
    { ClassId = 4, SpecId = 261, Type = M.Type.Melee },
    -- enhance shaman
    { ClassId = 7, SpecId = 263, Type = M.Type.Melee },
    -- ww monk
    { ClassId = 10, SpecId = 269, Type = M.Type.Melee },
    -- havoc dh
    { ClassId = 12, SpecId = 577, Type = M.Type.Melee },
    -- devourer dh
    { ClassId = 12, SpecId = 1480, Type = M.Type.Melee },
}

-- reverse lookup of a spec's name to it's id
-- this is because annoyingly GetBattlefieldScore returns the spec name and not the id
M.SpecNameLookup = {}

M.TooltipLookup = {}

---@type { [number]: SpecInfo }
M.SpecIdLookup = fsEnumerable:From(M.Specs):ToDictionary(function(item)
    return item.SpecId
end, function(item)
    return item
end)

---Returns the spec id for a given class id and spec name combination
---@param classToken string
---@param specName string
---@return number|nil
function M:SpecIdFromName(classToken, specName)
    local classLookup = M.SpecNameLookup[classToken]

    if not classLookup then
        return nil
    end

    return classLookup[specName]
end

---Returns the spec id for a given tooltip text class/spec combination.
---@param tooltipText string
---@return number|nil
function M:SpecIdFromTooltip(tooltipText)
    return M.TooltipLookup[tooltipText]
end

---@return SpecInfo|nil
function M:GetSpecInfo(specId)
    return M.SpecIdLookup[specId]
end

---@return string|nil
function M:SpecTypeKey(specType)
    if specType == M.Type.Tank then
        return "Tanks"
    end
    if specType == M.Type.Healer then
        return "Healers"
    end
    if specType == M.Type.Hunter then
        return "Hunters"
    end
    if specType == M.Type.Caster then
        return "Casters"
    end
    if specType == M.Type.Melee then
        return "Melee"
    end

    fsLog:Bug("Unknown spec type %d", specType)
    return nil
end

function M:Init()
    if not wow.GetClassInfo or not wow.GetSpecializationInfoForClassID then
        -- can happen in older wow clients and unit tests
        return
    end

    -- the reason we build this at runtime instead of pre-computing is because GetSpecializationInfoForClassID returns localised spec names
    -- and so does GetBattlefieldScore() so we need the localised spec name for lookup

    -- currently evokers
    local maxClass = 13

    for classID = 1, maxClass do
        local className, classToken = wow.GetClassInfo(classID)

        if classToken then
            M.SpecNameLookup[classToken] = M.SpecNameLookup[classToken] or {}

            -- GetNumSpecializationsForClassIDdoesn't exist in TBC, so just use 5 as a fallback
            local numSpecs = wow.GetNumSpecializationsForClassID and wow.GetNumSpecializationsForClassID(classID) or 5

            for index = 1, numSpecs do
                local specId, specName = wow.GetSpecializationInfoForClassID(classID, index)

                if specId and specName and specName ~= "" then
                    M.SpecNameLookup[classToken][specName] = specId
                    M.TooltipLookup[specName .. " " .. className] = specId
                end
            end
        end
    end
end
