local _, addonTable = ...
addonTable.events["GRID_UPDATE"] = false
local CR = addonTable.callbackRegistry

local frames = {
    QuickKeybindFrame,
    SpellBookFrame
}

local function gridUpdate(show)
    local show_grid 
    if show then
        show_grid = true
    else
        local canHide = true
        for i=1, #frames do
            local f = frames[i]
            if f:IsShown() then
                canHide = false
                break
            end
            if canHide then
                show_grid = false
            end
        end
    end
    CR:Fire("GRID_UPDATE", show_grid)
    addonTable.events["GRID_UPDATE"] = show_grid
end

local function OnEvent(self, event)
    if event == "ACTIONBAR_SHOWGRID" then
        gridUpdate(true)
    else
        gridUpdate(false)
    end
end

local function OnShow()
    gridUpdate(true)
end

local function OnHide()
    gridUpdate(false)
end

local frame = nil

local grid_status = {}
Mixin(grid_status, addonTable.hooks)

function grid_status:Start()
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent)
    end
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")
    for i=1, #frames do
        local f = frames[i]
        self:HookScript(f, "OnShow", OnShow)
        self:HookScript(f, "OnHide", OnHide)
    end
end

function grid_status:Stop()
    if not frame then
        return
    end
    frame:UnregisterAllEvents()
    self:DisableHooks()
end

CR:RegisterStatusEvent("GRID_UPDATE", grid_status)