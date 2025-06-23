local _, ADDON = ...

local hooked
local LibMountsRarity

local function RestoreOriginalColor(collected, button)
    if collected then
        button.name:SetTextColor(1.0, 0.82, 0) -- reset original colors
        button.name:SetFontObject("GameFontNormal") -- reset for hooked elvui
    else
        button.name:SetTextColor(0.5, 0.5, 0.5)
        button.name:SetFontObject("GameFontDisable")
    end
end

local function DetermineQuality(rarity)
    if rarity < 2.0 then
        return Enum.ItemQuality.Legendary
    end
    if rarity < 10.0 then
        return Enum.ItemQuality.Epic
    end
    if rarity < 20.0 then
        return Enum.ItemQuality.Rare
    end
    if rarity < 50.0 then
        return Enum.ItemQuality.Uncommon
    end
    return Enum.ItemQuality.Common
end

local function ColorNames(button, elementData)
    if ADDON.settings.ui.colorizeNameByRarity then

        local mountID = elementData.mountID
        local collected = select(11, C_MountJournal.GetMountInfoByID(mountID))

        LibMountsRarity = LibMountsRarity or LibStub("MountsRarity-2.0")
        local rarity = LibMountsRarity:GetRarityByID(mountID)
        if rarity ~= nil then
            local quality = DetermineQuality(rarity)
            local r, g, b = C_Item.GetItemQualityColor(quality)
            local a = collected and 1.0 or 0.75
            button.name:SetTextColor(r, g, b, a)
        else
            RestoreOriginalColor(collected, button)
        end
    end
end

ADDON:RegisterUISetting('colorizeNameByRarity', true, ADDON.L.SETTING_COLOR_NAMES, function(flag)
    if ADDON.initialized then
        if flag then
            MountJournal.ScrollBox:ForEachFrame(function(button, elementData)
                ColorNames(button, elementData)
            end)
            if not hooked then
                hooksecurefunc("MountJournal_InitMountButton", ColorNames)
                hooked = true
            end
        else
            MountJournal.ScrollBox:ForEachFrame(function(button, elementData)
                local collected = select(11, C_MountJournal.GetMountInfoByID(elementData.mountID))
                RestoreOriginalColor(collected, button)
            end)
        end
    end
end)

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON:ApplySetting('colorizeNameByRarity', ADDON.settings.ui.colorizeNameByRarity)
end, "rarity_names")