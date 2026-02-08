local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local L = sArenaMixin.L
local confirmDialog

local function ShowImportConfirmDialog(message, onAccept, data)
    if confirmDialog and confirmDialog:IsShown() then
        return
    end

    if not confirmDialog then
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetSize(320, 160)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(1000)

        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -15)
        frame.title:SetText(L["ImportExport_DialogTitle"])

        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.text:SetPoint("TOP", 0, -45)
        frame.text:SetWidth(270)
        frame.text:SetJustifyH("CENTER")

        frame.yesButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.yesButton:SetSize(100, 22)
        frame.yesButton:SetPoint("BOTTOM", frame, "BOTTOM", -55, 20)
        frame.yesButton:SetText(L["Yes"])

        frame.noButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.noButton:SetSize(100, 22)
        frame.noButton:SetPoint("BOTTOM", frame, "BOTTOM", 55, 20)
        frame.noButton:SetText(L["No"])
        frame.noButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        confirmDialog = frame
    end

    confirmDialog.text:SetText(message)
    confirmDialog.yesButton:SetScript("OnClick", function()
        confirmDialog:Hide()
        if onAccept then
            onAccept(data)
        end
    end)

    confirmDialog:Show()
end

function sArenaMixin:ExportProfile(profileKeySupplied)
    local name, realm = UnitName("player")
    realm = realm or GetRealmName()
    local fullKey = name .. " - " .. realm

    local profileKey = profileKeySupplied or sArena_ReloadedDB.profileKeys[fullKey]
    if not profileKey then
        return nil, L["Message_NoProfileFound"]
    end

    local profileTable = sArena_ReloadedDB.profiles[profileKey]
    if not profileTable then
        return nil, L["Message_ProfileDataNotFound"]
    end

    local exportTable = {
        dataType = "sArenaProfile",
        profileName = profileKey,
        data = profileTable,
    }

    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return "!sArena:" .. encoded .. ":sArena!"
end

function sArenaMixin:ImportProfile(encodedString, customProfileName, externalSource)
    -- Trim leading and trailing whitespace
    encodedString = encodedString:match("^%s*(.-)%s*$")

    if not encodedString:match("^!sArena:.+:sArena!$") then
        return nil, L["Message_InvalidFormat"]
    end

    local encoded = encodedString:match("^!sArena:(.+):sArena!$")
    local compressed = LibDeflate:DecodeForPrint(encoded)
    local serialized, decompressErr = LibDeflate:DecompressDeflate(compressed)

    if not serialized then
        return nil, string.format(L["Message_DecompressionError"], decompressErr or L["Unknown"])
    end

    local success, importTable = LibSerialize:Deserialize(serialized)
    if not success or type(importTable) ~= "table" then
        return nil, L["Message_DeserializationError"]
    end

    if importTable.dataType ~= "sArenaProfile" or type(importTable.data) ~= "table" then
        return nil, L["Message_IncorrectDataType"]
    end

    local newName
    if customProfileName then
        -- Use the provided custom profile name
        newName = customProfileName
    else
        local baseName = importTable.profileName or "Imported"

        -- If profile already exists, strip off old time suffix like "MyProfile 13:37"
        if sArena_ReloadedDB.profiles[baseName] then
            -- Strip " HH:MM" if present at the end of the profile name
            baseName = baseName:gsub(" %d%d:%d%d$", "")
        end

        newName = baseName
        if sArena_ReloadedDB.profiles[newName] then
            local timeString = date("%H:%M")
            newName = baseName .. " " .. timeString
        end
    end

    -- Insert the imported profile
    sArena_ReloadedDB.profiles[newName] = importTable.data

    -- Apply profile to current character
    for nameRealm in pairs(sArena_ReloadedDB.profileKeys) do
        sArena_ReloadedDB.profileKeys[nameRealm] = newName
    end

    if not externalSource then
        sArena_ReloadedDB.reOpenOptions = true
        ReloadUI()
    end
    return true
end

function sArenaMixin:ImportStreamerProfile(streamerName, profileString, displayName, classColor)
    local profileName = streamerName .. " StreamProfile"
    local profileExists = sArena_ReloadedDB.profiles[profileName] ~= nil

    -- Get current profile name
    local name, realm = UnitName("player")
    realm = realm or GetRealmName()
    local fullKey = name .. " - " .. realm
    local currentProfileKey = sArena_ReloadedDB.profileKeys[fullKey]

    local data = {
        profileString = profileString,
        profileName = profileName,
        currentProfileName = currentProfileKey or "Default"
    }

    -- If profile doesn't exist, import directly without asking
    if not profileExists then
        local success, err = sArenaMixin:ImportProfile(data.profileString, data.profileName)
        if not success then
            sArenaMixin:Print(L["Message_ImportFailed"], err)
        end
        return
    end

    -- Profile exists, ask for confirmation to overwrite
    -- Format the name with class color like the button does
    local coloredName = (classColor or "|cffffffff") .. (displayName or streamerName) .. "|r"
    local message = string.format(L["Message_ProfileOverwrite"], coloredName)
    ShowImportConfirmDialog(message, function(d)
        local success, err = sArenaMixin:ImportProfile(d.profileString, d.profileName)
        if not success then
            sArenaMixin:Print(L["Message_ImportFailed"], err)
        end
    end, data)
end