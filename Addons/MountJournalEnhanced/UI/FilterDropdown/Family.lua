local _, ADDON = ...

local function CheckSetting(settings)
    local hasTrue, hasFalse = false, false
    for _, v in pairs(settings) do
        if v == true then
            hasTrue = true
        elseif v == false then
            hasFalse = true
        end
        if hasTrue and hasFalse then
            break
        end
    end

    return hasTrue, hasFalse
end

local function GetIcon(family, subfamily)
    local sourceDb = subfamily and ADDON.DB.Family[family][subfamily] or ADDON.DB.Family[family]
    local mountId = TableUtil.FindMin(GetKeysArray(sourceDb), function(v) return v end)
    local _, _, icon = C_MountJournal.GetMountInfoByID(mountId)
    return icon
end

function ADDON.UI.FDD:AddFamilyMenu(root)

    root:SetScrollMode(GetScreenHeight() - 10)

    local L = ADDON.L
    local tInsert = table.insert

    local settings = ADDON.settings.filter.family
    local sortedFamilies, hasSubFamilies = {}, {}

    for family, mainConfig in pairs(ADDON.DB.Family) do
        hasSubFamilies[family] = false
        for _, subConfig in pairs(mainConfig) do
            if type(subConfig) == "table" then
                hasSubFamilies[family] = true
            else
                break
            end
        end
        tInsert(sortedFamilies, family)
    end
    table.sort(sortedFamilies, function(a, b)
        return (L[a] or a) < (L[b] or b)
    end)

    for _, family in pairs(sortedFamilies) do
        if hasSubFamilies[family] then
            local subMenu = ADDON.UI.FDD:CreateFilterSubmenu(root, L[family] or family, GetIcon(family, next(ADDON.DB.Family[family])), settings[family])
            local sortedSubFamilies = {}
            for subfamily, _ in pairs(ADDON.DB.Family[family]) do
                tInsert(sortedSubFamilies, subfamily)
            end
            table.sort(sortedSubFamilies, function(a, b)
                return (L[a] or a) < (L[b] or b)
            end)
            for _, subfamily in pairs(sortedSubFamilies) do
                ADDON.UI.FDD:AddIcon(ADDON.UI.FDD:CreateFilter(subMenu, L[subfamily] or subfamily, subfamily, settings[family], settings), GetIcon(family, subfamily))
            end

        else
            ADDON.UI.FDD:AddIcon(ADDON.UI.FDD:CreateFilter(root, L[family] or family, family, settings, true), GetIcon(family))
        end
    end
end