local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

local function ConvertOldWhitelist(oldWhitelist)
    local optimizedWhitelist = {}
    for _, aura in ipairs(oldWhitelist) do
        local key = aura["id"] or string.lower(aura["name"])
        local flags = aura["flags"] or {}
        local entryColors = aura["entryColors"] or {}
        local textColors = entryColors["text"] or {}

        optimizedWhitelist[key] = {
            name = aura["name"] or nil,
            id = aura["id"] or nil,
            important = flags["important"] or nil,
            pandemic = flags["pandemic"] or nil,
            enlarged = flags["enlarged"] or nil,
            compacted = flags["compacted"] or nil,
            color = {textColors["r"] or 0, textColors["g"] or 1, textColors["b"] or 0, textColors["a"] or 1}
        }
    end
    return optimizedWhitelist
end

local function ConvertOldBlacklist(oldBlacklist)
    local optimizedBlacklist = {}
    for _, aura in ipairs(oldBlacklist) do
        local key = aura["id"] or string.lower(aura["name"])

        optimizedBlacklist[key] = {
            name = aura["name"] or nil,
            id = aura["id"] or nil,
            showMine = aura["showMine"] or nil,
        }
    end
    return optimizedBlacklist
end

function BBF.DeepMergeTables(destination, source)
    for k, v in pairs(source) do
        if destination[k] == nil then
            if type(v) == "table" then
                destination[k] = {}
                BBF.DeepMergeTables(destination[k], v)
            else
                destination[k] = v
            end
        end
    end
end

function BBF.ExportProfile(profileTable, dataType)
    local wowVersion = GetBuildInfo()
    BetterBlizzFramesDB.exportVersion = "BBF: "..BBF.VersionNumber.." WoW: "..wowVersion

    local arenaOptiSaved = BetterBlizzFramesDB.arenaOptimizerSavedCVars
    local arenaOptiNoPrint = BetterBlizzFramesDB.arenaOptimizerDisablePrint

    BetterBlizzFramesDB.arenaOptimizerSavedCVars = nil
    BetterBlizzFramesDB.arenaOptimizerDisablePrint = nil
    BetterBlizzFramesDB.skipUpdateMsg = true

    local exportTable = {
        dataType = dataType,
        data = profileTable
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    BetterBlizzFramesDB.arenaOptimizerSavedCVars = arenaOptiSaved
    BetterBlizzFramesDB.arenaOptimizerDisablePrint = arenaOptiNoPrint
    BetterBlizzFramesDB.skipUpdateMsg = nil

    return "!BBF" .. encoded .. "!BBF"
end

function BBF.OldImportProfile(encodedString, expectedDataType)
    -- Check if the string starts and ends with !BBF
    if encodedString:sub(1, 4) == "!BBF" and encodedString:sub(-4) == "!BBF" then
        encodedString = encodedString:sub(5, -5)
    elseif encodedString:sub(1, 4) == "!BBP" and encodedString:sub(-4) == "!BBP" then
        return nil, L["Error_Wrong_Addon"]
    else
        return nil, L["Error_Invalid_Format"]
    end

    -- Decode and decompress the data
    local compressed = LibDeflate:DecodeForPrint(encodedString)
    local serialized, decompressMsg = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return nil, L["Error_Decompressing"] .. tostring(decompressMsg)
    end

    -- Deserialize the data
    local success, importTable = LibSerialize:Deserialize(serialized)
    if not success then
        return nil, "Error deserializing the data."
    end

    local function IsNewFormat(auraList)
        local consecutiveIndex = 1
        for key, _ in pairs(auraList) do
            if type(key) == "number" then
                if key ~= consecutiveIndex then
                    return true
                end
                consecutiveIndex = consecutiveIndex + 1
            elseif type(key) == "string" then
                return true
            end
        end
        return false
    end

    -- Convert old format to the new format if necessary
    local function ConvertIfNeeded(subTable, expectedType)
        if expectedType == "auraBlacklist" and not IsNewFormat(subTable) then
            return ConvertOldBlacklist(subTable)
        elseif expectedType == "auraWhitelist" and not IsNewFormat(subTable) then
            return ConvertOldWhitelist(subTable)
        end
        return subTable
    end

    -- Handling full profile import by checking and converting the relevant portion if needed
    if importTable.dataType == "fullProfile" then
        if importTable.data[expectedDataType] then
            -- Check the subtable and convert if necessary
            importTable.data[expectedDataType] = ConvertIfNeeded(importTable.data[expectedDataType], expectedDataType)
            return importTable.data[expectedDataType], nil
        else
            return importTable.data, nil
        end
    elseif importTable.dataType ~= expectedDataType then
        return nil, "Data type mismatch"
    end

    -- For normal imports, check if conversion is needed for auraWhitelist and auraBlacklist
    importTable.data = ConvertIfNeeded(importTable.data, expectedDataType)

    return importTable.data, nil
end

function BBF.ImportProfile(encodedString)
    local expectedDataType = "fullProfile"

    local profileData, errorMessage = BBF.OldImportProfile(encodedString, expectedDataType)
    if errorMessage then
        return false, errorMessage
    end

    BBF.DeepMergeTables(BetterBlizzFramesDB, profileData)

    return true
end