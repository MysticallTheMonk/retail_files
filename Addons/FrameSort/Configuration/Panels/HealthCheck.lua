---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsHealth = addon.Health.HealthCheck
local fsConfig = addon.Configuration
local L = addon.Locale
local lines = {}
local M = {}
fsConfig.Panels.Health = M

function M:Build(parent)
    local verticalSpacing = fsConfig.VerticalSpacing
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Health Check"]
    panel.parent = parent.name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText(L["Health Check"])

    local healthDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    healthDescription:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -verticalSpacing)
    healthDescription:SetText(L["Any known issues with configuration or conflicting addons will be shown below."])

    local helpTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    helpTitle:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    helpTitle:SetText(L["Try this"])

    panel:HookScript("OnShow", function()
        local healthy, results = fsHealth:IsHealthy()

        while #lines < #results do
            local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
            local result = panel:CreateFontString(nil, "ARTWORK", "GameFontRed")
            local help = fsConfig:TextLine("", panel)

            result:SetPoint("TOPLEFT", description, "TOPRIGHT", 4, 0)

            lines[#lines + 1] = {
                Description = description,
                Result = result,
                Help = help,
            }
        end

        local anchor = healthDescription
        for i, result in ipairs(results) do
            local line = lines[i]

            line.Description:SetText(result.Description .. "...")
            line.Description:SetPoint("TOPLEFT", anchor, 0, -verticalSpacing * 2)

            if result.Applicable then
                line.Result:SetText(result.Passed and L["Passed!"] or L["Failed"])
                line.Result:SetFontObject(result.Passed and "GameFontGreen" or "GameFontRed")
            else
                line.Result:SetText(L["N/A"])
                line.Result:SetFontObject("GameFontGreen")
            end

            anchor = line.Description
        end

        helpTitle:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing * 2)
        helpTitle:SetShown(not healthy)
        anchor = helpTitle

        for i, result in ipairs(results) do
            local line = lines[i]
            line.Help:SetText(result.Help and (" - " .. result.Help .. ".") or "")
            line.Help:SetShown(result.Applicable and not result.Passed)

            if result.Applicable and not result.Passed then
                line.Help:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)
                anchor = line.Help
            end
        end
    end)

    return panel
end
