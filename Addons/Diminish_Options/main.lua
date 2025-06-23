local ADDON_NAME, NS = ...
local Widgets = NS.Widgets
local TestMode = NS.TestMode
local L = NS.L
_G.DIMINISH_OPTIONS = NS

NS.PLAYER_NAME = UnitName("player") .. "-" .. GetRealmName()

NS.unitFrames = {
    [L.PLAYER] = "player", -- localized, unlocalized unitID
    [L.TARGET] = "target",
    [L.FOCUS] = not DIMINISH_NS.IS_CLASSIC and "focus" or nil,
    [L.ARENA] = not DIMINISH_NS.IS_CLASSIC and "arena" or nil,
    [L.PARTY] = "party",
    [L.NAMEPLATE] = "nameplate",
}

-- Proxy table for diminish savedvariables
-- Was originally used to automatically create a new DB profile on any DB option change,
-- now it's just a lazy way to keep correct db reference to DiminishDB profile
NS.GetDBProxy = function(key1, key2, key3)
    return setmetatable({}, {
        __index = function(self, key)
            if key3 then -- proxy for nested tables
                return DIMINISH_NS.db[key1][key2][key3][key]
            elseif key2 then
                return DIMINISH_NS.db[key1][key2][key]
            elseif key1 then
                return DIMINISH_NS.db[key1][key]
            else
                return DIMINISH_NS.db[key]
            end
        end,

        __newindex = function(self, key, value)
            local tbl
            if key3 then
                tbl = DIMINISH_NS.db[key1][key2][key3]
            elseif key2 then
                tbl = DIMINISH_NS.db[key1][key2]
            elseif key1 then
                tbl = DIMINISH_NS.db[key1]
            else
                tbl = DIMINISH_NS.db
            end
            tbl[key] = value
        end,
    })
end

local Panel = Widgets:CreateMainPanel(ADDON_NAME)
NS.Panel = Panel

function Panel:Setup()
    local Icons = DIMINISH_NS.Icons
    local frames = self.frames
    local db = NS.GetDBProxy()

    --local notes = GetAddOnMetadata(self.name, "Notes-" .. GetLocale()) or GetAddOnMetadata(self.name, "Notes")
    Widgets:CreateHeader(self, gsub(self.name, "_", " "), C_AddOns.GetAddOnMetadata("Diminish", "Version"),
        "\nClick the small red button next to Diminish under the AddOns tab for frame specific options."
        .. "\n|cFFFF0000Note:|r Diminish is generally maintained but not further developed - use at your own risk.")

    local subCooldown = Widgets:CreateSubHeader(self, L.HEADER_COOLDOWN)
    subCooldown:SetPoint("TOPLEFT", 16, -50)


    frames.timerStartAuraEnd = Widgets:CreateCheckbox(self, L.DISPLAYMODE, L.DISPLAYMODE_TOOLTIP, function(cb)
        db.timerStartAuraEnd = not db.timerStartAuraEnd
    end)
    frames.timerStartAuraEnd:SetPoint("LEFT", subCooldown, 10, -70)


    frames.timerSwipe = Widgets:CreateCheckbox(self, L.TIMERSWIPE, L.TIMERSWIPE_TOOLTIP, function()
        db.timerSwipe = not db.timerSwipe
        Icons:OnFrameConfigChanged()
    end)
    frames.timerSwipe:SetPoint("LEFT", frames.timerStartAuraEnd, 0, -40)



    frames.timerEdge = Widgets:CreateCheckbox(self, L.TIMEREDGE, L.TIMEREDGE_TOOLTIP, function()
        db.timerEdge = not db.timerEdge
        Icons:OnFrameConfigChanged()
    end)
    frames.timerEdge:SetPoint("LEFT", frames.timerSwipe, 15, -40)


    frames.timerText = Widgets:CreateCheckbox(self, L.TIMERTEXT, L.TIMERTEXT_TOOLTIP, function()
        Widgets:ToggleState(frames.timerColors, frames.timerText:GetChecked())

        db.timerText = not db.timerText
        Icons:OnFrameConfigChanged()
    end)
    frames.timerText:SetPoint("LEFT", frames.timerSwipe, 0, -80)


    frames.timerColors = Widgets:CreateCheckbox(self, L.TIMERCOLORS, L.TIMERCOLORS_TOOLTIP, function()
        db.timerColors = not db.timerColors
        Icons:OnFrameConfigChanged()
        DIMINISH_NS.Timers:ResetAll()
    end)
    frames.timerColors:SetPoint("LEFT", frames.timerText, 15, -40)


    do
        local fontOutlines = {
            { value = "NONE", text = L.TEXTURE_NONE },
            { value = "OUTLINE", text = "Outline"},
            { value = "MONOCHROME", text = "Monochrome" },
            { value = "MONOCHROMEOUTLINE", text = "Monochrome Outline" },
            { value = "THICKOUTLINE", text = "Thick Outline" },
        }

        frames.timerTextOutline = LibStub("WardzConfigDropdown-1.0").CreateDropdown(self, L.TIMEROUTLINE, L.TIMEROUTLINE_TOOLTIP, fontOutlines)
        frames.timerTextOutline:SetSize(90, 45)
        frames.timerTextOutline:SetPoint("LEFT", frames.timerColors, 0, -45)
        frames.timerTextOutline.OnValueChanged = function(_, value)
            if not value or value == EMPTY then return end
            db.timerTextOutline = value

            DIMINISH_NS.Icons:OnFrameConfigChanged()
        end
    end

    -------------------------------------------------------------------

    local subMisc = Widgets:CreateSubHeader(self, L.HEADER_MISC)
    subMisc:SetPoint("TOPRIGHT", -64, -50)

    frames.announceDRs = Widgets:CreateCheckbox(self, "Announce DR Expirations (TEST ONLY)", "Use built in Text-To-Speech engine to announce player DR expirations by unit names (targeted unitframe ones only).", function()
        db.announceDRs = not db.announceDRs
    end)
    frames.announceDRs:SetPoint("RIGHT", -225, 160)
    frames.announceDRs:SetAlpha(0.5)


    frames.trackNPCs = Widgets:CreateCheckbox(self, L.TRACKNPCS, L.TRACKNPCS_TOOLTIP, function()
        db.trackNPCs = not db.trackNPCs

        for _, unit in pairs({ "target", "focus", "nameplate" }) do
            local cfg = db.unitFrames[unit]
            if DIMINISH_NS.IS_RETAIL then
                cfg.disabledCategories[DIMINISH_NS.CATEGORIES.taunt] = not db.trackNPCs
            end
            cfg.zones.party = db.trackNPCs
            --cfg.zones.scenario = db.trackNPCs
            cfg.zones.raid = db.trackNPCs
        end

        DIMINISH_NS.Diminish:ToggleForZone()
    end)
    frames.trackNPCs:SetPoint("LEFT", frames.announceDRs, 0, -40)


    frames.showCategoryText = Widgets:CreateCheckbox(self, L.SHOWCATEGORYTEXT, L.SHOWCATEGORYTEXT_TOOLTIP, function(cb)
        db.showCategoryText = not db.showCategoryText
        frames.categoryFontSize:SetShown(db.showCategoryText)
        frames.categoryTextMaxLines:SetShown(db.showCategoryText)
        Icons:OnFrameConfigChanged()
    end)
    frames.showCategoryText:SetPoint("LEFT", frames.trackNPCs, 0, -40)


    frames.colorBlind = Widgets:CreateCheckbox(self, L.COLORBLIND, format(L.COLORBLIND_TOOLTIP, L.TIMERTEXT), function()
        db.colorBlind = not db.colorBlind
        Icons:OnFrameConfigChanged()
    end)
    frames.colorBlind:SetPoint("LEFT", frames.showCategoryText, 0, -40)


    do
        local textures = {
            { text = L.DEFAULT, value = {
                edgeFile = "Interface\\BUTTONS\\UI-Quickslot-Depress",
                layer = "BORDER",
                edgeSize = 2.5,
                name = L.DEFAULT, -- keep a reference to text in db so we can set correct dropdown value on login
            }},

            { text = L.TEXTURE_GLOW, value = {
                edgeFile = "Interface\\BUTTONS\\UI-Quickslot-Depress",
                layer = "OVERLAY",
                edgeSize = 1,
                name = L.TEXTURE_GLOW,
            }},

            { text = L.TEXTURE_BRIGHT, value = {
                edgeFile = "Interface\\BUTTONS\\WHITE8X8",
                --isBackdrop = true,
                edgeSize = 1.5,
                layer = "BORDER",
                name = L.TEXTURE_BRIGHT,
            }},

            { text = L.TEXTURE_NONE, value = {
                layer = "BORDER",
                edgeFile = "",
                edgeSize = 0,
                name = L.TEXTURE_NONE,
            }},
        }

        frames.border = LibStub("WardzConfigDropdown-1.0").CreateDropdown(self, L.SELECTBORDER, L.SELECTBORDER_TOOLTIP, textures)
        frames.border:SetPoint("LEFT", frames.colorBlind, 7, -55)
        frames.border:SetWidth(180)

        frames.border.OnValueChanged = function(_, value)
            if not value or value == EMPTY then return end
            db.border = value
            Icons:OnFrameConfigChanged()
        end
    end

    frames.categoryFontSize = Widgets:CreateSlider(self, "Category Label Size", "Adjust font size for DR category labels.", 1, 40, 1, function(_, value)
        db.categoryFont.size = value
        DIMINISH_NS.Icons:OnFrameConfigChanged()
    end)
    frames.categoryFontSize:SetPoint("LEFT", frames.border, 0, -70)

    frames.categoryTextMaxLines = Widgets:CreateSlider(self, "Category Label Max Lines", "Set how many lines the DR category text will grow until it gets abbreviated instead.", 1, 4, 1, function(_, value)
        db.categoryTextMaxLines = value
        DIMINISH_NS.Icons:OnFrameConfigChanged()
    end)
    frames.categoryTextMaxLines:SetPoint("LEFT", frames.categoryFontSize, 0, -50)

    -------------------------------------------------------------------

    local tip = self:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    tip:SetJustifyH("LEFT")
    tip:SetText(L.TARGETTIP)
    tip:SetPoint("CENTER", self, 0, -220)
    tip:Hide()


    -- Show drag anchors
    local unlock = Widgets:CreateButton(self, L.UNLOCK, L.UNLOCK_TOOLTIP, function(btn)
        if InCombatLockdown() then
            return Widgets:ShowError(L.COMBATLOCKDOWN_ERROR)
        end

        if not NS.TestMode:IsAnchoring() then
            local cfg = DIMINISH_NS.db.unitFrames
            if cfg.target.enabled or cfg.focus.enabled or cfg.nameplate.enabled then
                tip:Show()
            end
            TestMode:ShowAnchors()
        else
            TestMode:HideAnchors()
            tip:Hide()
        end
    end)
    unlock:SetPoint("BOTTOMLEFT", self, 15, 15)
    unlock:SetSize(200, 25)

    unlock.glyphIcon = unlock:CreateTexture(nil, "OVERLAY")
    unlock.glyphIcon:SetTexture("Interface\\CURSOR\\UI-Cursor-Move")
    unlock.glyphIcon:SetPoint("LEFT", unlock, 7, 0)
    unlock.glyphIcon:SetSize(19, 19)


    -- Test mode for timers
    local testBtn = Widgets:CreateButton(self, L.TEST, L.TEST_TOOLTIP, function(btn)
        local InActiveBattlefield = _G.InActiveBattlefield or _G.C_PvP.IsActiveBattlefield
        if InCombatLockdown() or InActiveBattlefield() or (IsActiveBattlefieldArena and IsActiveBattlefieldArena()) then
            return Widgets:ShowError(L.COMBATLOCKDOWN_ERROR)
        end

        local cfg = DIMINISH_NS.db.unitFrames
        if cfg.target.enabled or cfg.focus.enabled or cfg.nameplate.enabled or tip:IsShown() then
            tip:SetShown(not NS.TestMode:IsTesting())
        end
        TestMode:Test()
    end)
    testBtn:SetSize(200, 25)
    testBtn:SetPoint("BOTTOMRIGHT", self, -15, 15)
end

function Panel:refresh()
    Widgets:RefreshWidgets(DIMINISH_NS.db, self)
    self.frames.categoryFontSize:SetShown(DIMINISH_NS.db.showCategoryText)
    self.frames.categoryFontSize:SetValue(DIMINISH_NS.db.categoryFont.size)
    self.frames.categoryTextMaxLines:SetShown(DIMINISH_NS.db.showCategoryText)

    -- Disable rest of timer options if timer countdown is not checked
    Widgets:ToggleState(self.frames.timerColors, self.frames.timerText:GetChecked())
end

SLASH_DIMINISH1 = "/diminish"
SlashCmdList.DIMINISH = function()
    Settings.OpenToCategory("Diminish")
	-- InterfaceOptionsFrame_OpenToCategory(Panel)
    -- InterfaceOptionsFrame_OpenToCategory(Panel) -- double to fix blizz bug
end
