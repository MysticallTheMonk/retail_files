---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsRun = addon.Modules
local fsConfig = addon.Configuration
local fsSpecs = addon.Configuration.Specs
local fsLog = addon.Logging.Log
local fsCompare = addon.Modules.Sorting.Comparer
local L = addon.Locale.Current

local M = {}
fsConfig.Panels.SpecPriority = M

local rowGap = 2
local rowHeight = 26
local rowTopPadding = 6

local types = {
    fsSpecs.Type.Tank,
    fsSpecs.Type.Healer,
    fsSpecs.Type.Hunter,
    fsSpecs.Type.Caster,
    fsSpecs.Type.Melee,
}

local listFrame

local dragIndex = nil
local dropIndex = nil

local rows = {}
local dragGhost = nil
local insertLine = nil

local selectedType = fsSpecs.Type.Tank

local function ClassColorForSpec(specId)
    if not wow.GetSpecializationInfoByID then
        return 0.9, 0.9, 0.9
    end

    local _, _, _, _, _, classFile = wow.GetSpecializationInfoByID(specId)

    if classFile and wow.RAID_CLASS_COLORS and wow.RAID_CLASS_COLORS[classFile] then
        local c = wow.RAID_CLASS_COLORS[classFile]
        return c.r, c.g, c.b
    end

    return 0.9, 0.9, 0.9
end

local function SpecName(specId)
    if wow.GetSpecializationInfoByID then
        local _, name, _, _, _, _, class = wow.GetSpecializationInfoByID(specId)

        if name and class then
            return string.format("%s - %s", class, name)
        end
    end

    return string.format("Spec Id %d", specId)
end

local function HasSpec(specId)
    if not wow.GetSpecializationInfoByID then
        -- might as well just show spec ids
        return true
    end

    -- we might be in an older expansion that doesn't have all the specs
    local _, name, _, _, _, _, class = wow.GetSpecializationInfoByID(specId)

    return name ~= nil and class ~= nil
end

local function Move(tbl, from, to)
    if from == to or to < 1 or to > (#tbl + 1) or from < 1 or from > #tbl then
        return
    end

    local tmp = tbl[from]
    table.remove(tbl, from)

    -- If we remove an earlier element and insert later, the target index shifts down by 1.
    if to > from then
        to = to - 1
    end

    table.insert(tbl, to, tmp)
end

local function EnsureDbOrder(specType)
    local key = fsSpecs:SpecTypeKey(specType)

    if not key then
        return
    end

    addon.DB.Options.Sorting.SpecPriority = addon.DB.Options.Sorting.SpecPriority or {}
    addon.DB.Options.Sorting.SpecPriority[key] = addon.DB.Options.Sorting.SpecPriority[key] or {}

    local priority = addon.DB.Options.Sorting.SpecPriority[key]

    if #priority > 0 then
        return priority
    end

    for _, info in ipairs(fsSpecs.Specs) do
        if info.Type == specType and info.SpecId and HasSpec(info.SpecId) then
            priority[#priority + 1] = info.SpecId
        end
    end

    return priority
end

local function ResetDbOrder(specType)
    local key = fsSpecs:SpecTypeKey(specType)

    if not key then
        return
    end

    addon.DB.Options.Sorting.SpecPriority = addon.DB.Options.Sorting.SpecPriority or {}
    addon.DB.Options.Sorting.SpecPriority[key] = {}

    EnsureDbOrder(specType)
end

local function SpecTypeLabel(specType)
    if specType == fsSpecs.Type.Tank then
        return L["Tank"]
    end
    if specType == fsSpecs.Type.Healer then
        return L["Healer"]
    end
    if specType == fsSpecs.Type.Hunter then
        return L["Hunter"]
    end
    if specType == fsSpecs.Type.Caster then
        return L["Caster"]
    end
    if specType == fsSpecs.Type.Melee then
        return L["Melee"]
    end

    fsLog:Bug("Unknown spec type %d", specType)
    return tostring(specType)
end

local function AddHoverAnimation(row, isDragging)
    local function ApplyBase(self)
        local r = self.ClassR or 0.9
        local g = self.ClassG or 0.9
        local b = self.ClassB or 0.9

        self.Text:SetTextColor(r, g, b)
    end

    local function Clear(self)
        self.Highlight:SetAlpha(0)
        ApplyBase(self)
    end

    row:SetScript("OnEnter", function(self)
        if isDragging and isDragging() then
            Clear(self)
            return
        end

        self.Highlight:SetAlpha(1)

        -- brighten the color slightly on hover
        local r = self.ClassR or 0.9
        local g = self.ClassG or 0.9
        local b = self.ClassB or 0.9

        self.Text:SetTextColor(math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.15))
    end)

    row:SetScript("OnLeave", function(self)
        Clear(self)
    end)

    row.ClearHover = Clear
end

local function GetDropIndex(order)
    if #order == 0 then
        return nil
    end

    local scale = wow.UIParent:GetEffectiveScale()
    local _, y = wow.GetCursorPosition()

    y = y / scale

    local top, bottom = listFrame:GetTop(), listFrame:GetBottom()

    if not top or not bottom then
        return nil
    end

    y = math.min(top, math.max(bottom, y))

    local yFromTop = (top - y) - rowTopPadding

    if yFromTop < 0 then
        yFromTop = 0
    end

    local stride = rowHeight + rowGap
    local slot = math.floor((yFromTop / stride) + 0.5) + 1

    return math.min(#order + 1, math.max(1, slot))
end

local function UpdateDragVisuals()
    if not dragIndex then
        return
    end

    assert(dragGhost)
    assert(insertLine)

    local scale = wow.UIParent:GetEffectiveScale()
    local x, y = wow.GetCursorPosition()
    x, y = x / scale, y / scale

    dragGhost:ClearAllPoints()
    dragGhost:SetPoint("CENTER", wow.UIParent, "BOTTOMLEFT", x + 30, y)

    local order = EnsureDbOrder(selectedType)
    dropIndex = GetDropIndex(order)

    if not dropIndex then
        insertLine:Hide()
        return
    end

    -- insert at end (after the last item)
    if dropIndex == (#order + 1) then
        local lastRow = rows[#order]

        if lastRow and lastRow:IsShown() then
            insertLine:ClearAllPoints()
            insertLine:SetPoint("BOTTOMLEFT", lastRow, "BOTTOMLEFT", 0, -1)
            insertLine:SetPoint("BOTTOMRIGHT", lastRow, "BOTTOMRIGHT", 0, -1)
            insertLine:Show()
        else
            insertLine:Hide()
        end

        return
    end

    -- insert before the hovered row
    local row = rows[dropIndex]
    if row and row:IsShown() then
        insertLine:ClearAllPoints()
        insertLine:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 1)
        insertLine:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 1)
        insertLine:Show()
    else
        insertLine:Hide()
    end
end

local function Refresh()
    local order = EnsureDbOrder(selectedType)

    if not order then
        return
    end

    -- clean up the db if we have existing unknown specs
    for i = #order, 1, -1 do
        if not HasSpec(order[i]) then
            table.remove(order, i)
        end
    end

    for i = 1, #order do
        local row = rows[i]
        local specId = order[i]
        local specName = SpecName(specId)
        local text = string.format("%d. %s", i, specName)

        row.SpecIndex = i
        row.SpecId = specId
        row.Text:SetText(text)

        local r, g, b = ClassColorForSpec(specId)
        row.ClassR, row.ClassG, row.ClassB = r, g, b
        row.Text:SetTextColor(r, g, b)

        if dragIndex then
            row:ClearHover()
        end

        row:Show()
    end

    -- Hide any extra rows (e.g. switching to a type with fewer specs)
    for i = #order + 1, #rows do
        local row = rows[i]
        row.SpecId = nil
        row.SpecIndex = nil

        row:Hide()
        row:ClearHover()

        row.BaseR, row.BaseG, row.BaseB = nil, nil, nil
    end
end

local function CreateRow(index, list)
    local row = wow.CreateFrame("Button", nil, list)
    row:EnableMouse(true)
    row:SetHeight(rowHeight)
    row:SetPoint("LEFT", 0, 0)
    row:SetPoint("RIGHT", 0, 0)

    if index == 1 then
        row:SetPoint("TOP", list, "TOP", 0, -rowTopPadding)
    else
        row:SetPoint("TOP", rows[index - 1], "BOTTOM", 0, -rowGap)
    end

    -- Highlight background (fills row)
    row.Highlight = row:CreateTexture(nil, "BACKGROUND")
    row.Highlight:SetAllPoints(true)
    row.Highlight:SetColorTexture(1, 1, 1, 0.08) -- subtle white highlight
    row.Highlight:SetAlpha(0)

    row.Text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.Text:SetPoint("LEFT", 6, 0)
    row.Text:SetTextColor(0.9, 0.9, 0.9)

    AddHoverAnimation(row, function()
        return dragIndex ~= nil
    end)

    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function()
        if not row.SpecId then
            return
        end

        assert(dragGhost)

        dragIndex = row.SpecIndex
        dropIndex = row.SpecIndex

        row:ClearHover()

        local r, g, b = ClassColorForSpec(row.SpecId)

        dragGhost.Text:SetTextColor(r, g, b)
        dragGhost.Text:SetText(SpecName(row.SpecId))
        dragGhost:Show()

        UpdateDragVisuals()
    end)

    row:SetScript("OnDragStop", function()
        if not dragIndex then
            return
        end

        assert(dragGhost)
        assert(insertLine)

        dragGhost:Hide()
        insertLine:Hide()

        local order = EnsureDbOrder(selectedType)
        if dropIndex and dropIndex ~= dragIndex then
            -- swap the items
            Move(order, dragIndex, dropIndex)

            -- reset the spec order cache
            fsCompare:InvalidateCache()

            -- notify subscribers config has changed
            fsConfig:NotifyChanged()

            -- run modules
            fsRun:Run()
        end

        dragIndex = nil
        dropIndex = nil
        Refresh()
    end)

    return row
end

local function EnsureRows(count)
    -- create missing rows
    for i = (#rows + 1), count do
        rows[i] = CreateRow(i, listFrame)
    end

    -- hide extras
    for i = count + 1, #rows do
        rows[i]:Hide()
    end
end

function M:Build(parent)
    local panel = wow.CreateFrame("Frame", nil, parent)
    panel.name = L["Spec Priority"]
    panel.parent = parent.name

    local width, _ = fsConfig:SettingsSize()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", fsConfig.VerticalSpacing, -fsConfig.VerticalSpacing)
    title:SetText(L["Spec Priority"])

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -fsConfig.VerticalSpacing)
    description:SetText(L["Choose a spec type, then drag and drop to control priority."])

    local note = fsConfig:MultilineTextBlock(L["Spec query note"], panel, description)

    local ddLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ddLabel:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -fsConfig.VerticalSpacing * 2)
    ddLabel:SetText(L["Spec Type"])

    listFrame = wow.CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", ddLabel, "BOTTOMLEFT", 0, -fsConfig.VerticalSpacing * 2)
    listFrame:SetSize(width - 50, 380)

    listFrame:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8x8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    -- subtle dark background
    listFrame:SetBackdropColor(0, 0, 0, 0.35)

    -- soft grey border
    listFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)

    dragGhost = wow.CreateFrame("Frame", nil, panel)
    dragGhost:SetFrameStrata("TOOLTIP")
    dragGhost:SetSize(260, 22)
    dragGhost:Hide()

    dragGhost.Text = dragGhost:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dragGhost.Text:SetPoint("LEFT", 8, 0)

    insertLine = wow.CreateFrame("Frame", nil, listFrame)
    insertLine:SetHeight(2)
    insertLine:SetPoint("LEFT", 6, 0)
    insertLine:SetPoint("RIGHT", -6, 0)
    insertLine:Hide()

    insertLine.Text = insertLine:CreateTexture(nil, "OVERLAY")
    insertLine.Text:SetAllPoints(true)
    insertLine.Text:SetColorTexture(1, 1, 1, 0.9)

    panel:SetScript("OnUpdate", function()
        if dragIndex then
            UpdateDragVisuals()
        end
    end)

    local ddType = fsConfig:Dropdown(panel, types, function()
        return selectedType
    end, function(value)
        selectedType = value
        local order = EnsureDbOrder(selectedType)
        EnsureRows(#order)
        Refresh()
    end, function(value)
        return SpecTypeLabel(value)
    end)

    ddType:SetPoint("LEFT", ddLabel, "RIGHT", 20, -2)

    local reset = wow.CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(200, 22)
    reset:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -fsConfig.VerticalSpacing)
    reset:SetText(L["Reset this type"])
    reset:SetScript("OnClick", function()
        -- reset to default  order
        ResetDbOrder(selectedType)

        -- refresh the rows
        Refresh()

        -- reset the spec order cache
        fsCompare:InvalidateCache()

        -- notify subscribers config has changed
        fsConfig:NotifyChanged()

        -- run modules
        fsRun:Run()
    end)

    local order = EnsureDbOrder(selectedType)
    EnsureRows(#order)
    Refresh()
    return panel
end
