local _, ADDON = ...

local buttonList, enabledGroup = {}, {}

local function renderToolbar()
    local lastButton
    local hasElements = false

    if MountJournal.SummonRandomFavoriteSpellFrame then
        lastButton = MountJournal.SummonRandomFavoriteSpellFrame.Button
    elseif MountJournal.SummonRandomFavoriteButton then -- Todo: remove after 11.1.7
        lastButton = MountJournal.SummonRandomFavoriteButton
    end

    local names = GetKeysArray(buttonList)
    table.sort(names)

    for _, name in ipairs(names) do
        local group = buttonList[name]
        if #group > 0 and enabledGroup[name] then

            group[#group]:ClearAllPoints()

            if lastButton then
                group[#group]:SetPoint("RIGHT", lastButton, "LEFT", -11, 0)
            else
                group[#group]:SetPoint("CENTER", MountJournal, "TOPRIGHT", -24, -42)
            end

            for i = #group-1, 1, -1 do
                group[i]:ClearAllPoints()
                group[i]:SetPoint("RIGHT", group[i+1], "LEFT", -3, 0)
            end

            lastButton = group[1]
            hasElements = true
        end
    end

    if MountJournal.SummonRandomFavoriteSpellFrame then
        MountJournal.SummonRandomFavoriteSpellFrame.Label:SetShown(not hasElements)
    elseif MountJournal.SummonRandomFavoriteButton then -- Todo: remove after 11.1.7
        MountJournal.SummonRandomFavoriteButton.spellname:SetShown(not hasElements)
    end
end

function ADDON.UI:RegisterToolbarGroup(name, ...)
    local group = { ... }

    if #group > 0 then
        buttonList[name] = group
        enabledGroup[name] = true

        if ADDON.initialized then
            renderToolbar()
        end

        return function(enabled)
            enabledGroup[name] = enabled
            if ADDON.initialized then
                renderToolbar()
            end
        end
    end
end

ADDON.Events:RegisterCallback("loadUI", renderToolbar, 'toolbar' )