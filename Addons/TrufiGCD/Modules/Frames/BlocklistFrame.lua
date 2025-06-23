---@type string, Namespace
local _, ns = ...

---@class BlocklistFrame
local blocklistFrame = {}
ns.blocklistFrame = blocklistFrame

local frame = CreateFrame("Frame", nil, UIParent)
frame:Hide()
frame.name = "Blocklist"
frame.parent = "TrufiGCD"
ns.utils.interfaceOptions_AddCategory(frame)

local listBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
listBorder:SetPoint("TOPLEFT", 10, -25)
listBorder:SetWidth(200)
listBorder:SetHeight(501)
listBorder:SetBackdrop({
    bgFile = nil,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
})
listBorder:SetBackdropBorderColor(0.4, 0.4, 0.4)

local listContainer = CreateFrame("ScrollFrame", nil, frame)
listContainer:SetPoint("TOPLEFT",10, -30)
listContainer:SetWidth(200)
listContainer:SetHeight(488)

local listScrollBar = CreateFrame("Slider", "TrGCDBLScroll", listContainer, "UIPanelScrollBarTemplate")
listScrollBar:SetPoint("TOPLEFT", listContainer, "TOPRIGHT", 1, -16)
listScrollBar:SetPoint("BOTTOMLEFT", listContainer, "BOTTOMRIGHT", 1, 16)
listScrollBar:SetMinMaxValues(1, 470)
listScrollBar:SetValueStep(1)
listScrollBar:SetValue(0)
listScrollBar:SetScript("OnValueChanged", function(self, value)
    self:GetParent():SetVerticalScroll(value)
end)

local listScrollBarBackground = listScrollBar:CreateTexture(nil, "BACKGROUND")
listScrollBarBackground:SetAllPoints(listScrollBar)
listScrollBarBackground:SetColorTexture(0, 0, 0, 0.4)


local list = CreateFrame("Frame", nil, listContainer)
list:SetWidth(200)
list:SetHeight(958)

local listText = list:CreateFontString(nil, "BACKGROUND")
listText:SetFont(STANDARD_TEXT_FONT, 12)
listText:SetText("Blocklist")
listText:SetPoint("TOPLEFT", 15, 15)

local selectedItemText = frame:CreateFontString(nil, "BACKGROUND")
selectedItemText:SetFont(STANDARD_TEXT_FONT, 12)
selectedItemText:SetText("Select spell to delete")

---@class Item
---@field index integer
---@field button any
---@field texture any
---@field text any

---@type Item | nil
local selectedItem = nil

---@type Item[]
local items = {}

for i = 1, 60 do
    local button = CreateFrame("Button", nil, list)
    button:SetWidth(192)
    button:SetHeight(15)
    button:SetPoint("TOP", 0, -(i - 1) * 16)
    button:Disable()

    local text = button:CreateFontString(nil, "BACKGROUND")
    text:SetFont(STANDARD_TEXT_FONT, 11)
    text:SetText(" ")
    text:SetPoint("TOP", 0, 10)
    text:SetAllPoints(button)

    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(button)
    texture:SetColorTexture(255, 210, 0)
    texture:SetAlpha(0)

    ---@type Item
    local item = {
        index = i,
        button = button,
        text = text,
        texture = texture,
    }
    items[i] = item

    button:SetScript("OnEnter", function()
        if selectedItem ~= item then
            texture:SetAlpha(0.3)
        end
    end)

    button:SetScript("OnLeave", function()
        if selectedItem ~= item then
            texture:SetAlpha(0)
        end
    end)

    button:SetScript("OnClick", function()
        if selectedItem ~= nil then
            selectedItem.texture:SetAlpha(0)
        end
        selectedItem = item
        texture:SetAlpha(0.6)
        selectedItemText:SetText(text:GetText())
    end)
end

local addOnIconClickCheckbox = ns.frameUtils.createCheckButton({
    frame = frame,
    text = "Add by Ctrl+Alt+Click on icon",
    position = "TOPLEFT",
    x = 260,
    y = -280,
    name = "TrGCDCheckiconClickAddsSpellToBlocklist",
    checked = ns.settings.activeProfile.iconClickAddsSpellToBlocklist,
    tooltip = "Add a spell to blocklist by Ctrl+Alt+Click on the spell icon",
    onClick = function()
        ns.settings.activeProfile.iconClickAddsSpellToBlocklist = not ns.settings.activeProfile.iconClickAddsSpellToBlocklist
        ns.settings:Save()
    end
})

blocklistFrame.syncWithSettings = function()
	for i = 1, 60 do
        local spellId = ns.settings.activeProfile.blocklist[i]
        local item = items[i]
        if spellId ~= nil then
            item.button:Enable()

            local name = ns.utils.getSpellInfo(spellId)
            if name then
                item.text:SetText(spellId .. " - " .. name)
            else
                item.text:SetText(spellId)
            end

        else
            item.button:Disable()
            item.text:SetText(nil)
            item.texture:SetAlpha(0)
        end
    end

    addOnIconClickCheckbox:SetChecked(ns.settings.activeProfile.iconClickAddsSpellToBlocklist)
end
blocklistFrame.syncWithSettings()

local buttonDelete = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
buttonDelete:SetWidth(100)
buttonDelete:SetHeight(22)
buttonDelete:SetPoint("TOPLEFT", 260, -130)
buttonDelete:SetText("Delete")
buttonDelete:SetScript("OnClick", function()
    if selectedItem then
        table.remove(ns.settings.activeProfile.blocklist, selectedItem.index)
        selectedItemText:SetText("Select spell to delete")
        ns.settings:Save()
        blocklistFrame.syncWithSettings()
    end
end)
selectedItemText:SetPoint("TOPLEFT", buttonDelete, "TOPLEFT", 5, 15)

listContainer:SetScrollChild(list)

local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
input:SetWidth(200)
input:SetHeight(20)
input:SetPoint("TOPLEFT", 265, -200)
input:SetAutoFocus(false)
input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local function addItem()
    if #ns.settings.activeProfile.blocklist >= 60 then
        print("[TrufiGCD]: blocklist has exceeded its limit of 60 items")
        return
    end

    ---@type string
    local inputValue = input:GetText()
    if not inputValue then
        return
    end

    local inputSpellId = tonumber(inputValue)

    if inputSpellId ~= nil then
        table.insert(ns.settings.activeProfile.blocklist, inputSpellId)
    else
        local spellName = inputValue

        ---@type number | nil
        local spellId = select(7, ns.utils.getSpellInfo(spellName))

        if not spellId then
            print("[TrufiGCD]: can't find a spell ID for the name \"" .. spellName .. "\". Please, provide the exact spell ID.")
            return
        end

        table.insert(ns.settings.activeProfile.blocklist, spellId)
        print("[TrufiGCD]: converted \"" .. spellName .. "\" to spell ID \"" .. spellId .. "\". If this is not the desired spell ID, provide the exact ID of the spell you wish to block as multiple ones with this name may exist.")
    end

    ns.settings:Save()
    blocklistFrame.syncWithSettings()
    input:SetText("")
    input:ClearFocus()
end
input:SetScript("OnEnterPressed", addItem)

local buttonAdd = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
buttonAdd:SetWidth(100)
buttonAdd:SetHeight(22)
buttonAdd:SetPoint("TOPLEFT", 260, -225)
buttonAdd:SetText("Add")
buttonAdd:SetScript("OnClick", addItem)

local buttonAddText = buttonAdd:CreateFontString(nil, "BACKGROUND")
buttonAddText:SetFont(STANDARD_TEXT_FONT, 12)
buttonAddText:SetText("Enter spell ID or name")
buttonAddText:SetPoint("TOPLEFT", 5, 40)
