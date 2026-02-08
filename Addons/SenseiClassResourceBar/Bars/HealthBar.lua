local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local HealthBarMixin = Mixin({}, addonTable.BarMixin)

function HealthBarMixin:GetBarColor()
    local playerClass = select(2, UnitClass("player"))

    local data = self:GetData()

    local color = addonTable:GetOverrideHealthBarColor()

    if data and data.useClassColor == true then
        local r, g, b = GetClassColor(playerClass)
        return { r = r, g = g, b = b, a = color.a }
    else
        return color
    end
end

function HealthBarMixin:GetResource()
    return "HEALTH"
end

function HealthBarMixin:GetResourceValue()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")
    if max <= 0 then return nil, nil end

    return max, current
end

function HealthBarMixin:GetTagValues(_, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    -- Pre-compute values instead of creating closures for better performance
    local currentStr = string.format("%s", AbbreviateNumbers(current))
    local percentStr = string.format(pFormat, UnitHealthPercent("player", true, CurveConstants.ScaleTo100))
    local maxStr = string.format("%s", AbbreviateNumbers(max))

    return {
        ["[current]"] = function() return currentStr end,
        ["[percent]"] = function() return percentStr end,
        ["[max]"] = function() return maxStr end,
    }
end

function HealthBarMixin:ApplyMouseSettings()
    local data = self:GetData()
    local shouldEnable = data and data.enableHealthBarMouseInteraction

    if InCombatLockdown() then
        self._mouseUpdatePending = true
        return -- defer until PLAYER_REGEN_ENABLED
    end

    -- Apply
    self.Frame:EnableMouse(shouldEnable)
    if shouldEnable then
        self.Frame:RegisterForClicks("AnyUp")
    else
        self.Frame:RegisterForClicks()
    end
    self._mouseUpdatePending = false
end

function HealthBarMixin:OnLayoutChange()
    self:ApplyMouseSettings()
end

function HealthBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self.Frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self.Frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.Frame:RegisterEvent("PET_BATTLE_OPENING_START")
    self.Frame:RegisterEvent("PET_BATTLE_CLOSE")

    self:RegisterSecureVisibility()
    self:ApplyMouseSettings()
    self._mouseUpdatePending = false
    self.Frame:SetAttribute("unit", "player")
    self.Frame:SetAttribute("*type1", "target")
    self.Frame:SetAttribute("*type2", "togglemenu")
    self.Frame.menu = function(frame)
        UnitPopup_ShowMenu(frame, "PLAYER", "player")
    end

    if not self._registerFrameOnShowAndHide then
        self.Frame:HookScript("OnShow", function()
            self:OnShow()
        end)

        self.Frame:HookScript("OnHide", function()
            self:OnHide()
        end)
        self._registerFrameOnShowAndHide = true
    end
end

function HealthBarMixin:OnEvent(event, ...)
    local unit = ...
    self._curEvent = event

    if event == "PLAYER_ENTERING_WORLD"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        self:ApplyVisibilitySettings()
        self:ApplyLayout(nil, true)
        self:UpdateDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then

            self:ApplyVisibilitySettings()
            self:ApplyLayout(nil, true)
            self:UpdateDisplay()

    end

    if event == "PLAYER_ENTERING_WORLD" then
        self:ApplyMouseSettings()
    elseif event == "PLAYER_REGEN_ENABLED" and self._mouseUpdatePending then
        self:ApplyMouseSettings()
    end
end

function HealthBarMixin:RegisterSecureVisibility()
    -- Don't hide in Edit Mode, unless config disables it
    if LEM:IsInEditMode() then
        local conditional = "show"
        if type(self.config.allowEditPredicate) == "function" and self.config.allowEditPredicate() == false then
            conditional = "hide"
        end
        RegisterAttributeDriver(self.Frame, "state-visibility", conditional)
        return
    end

    local data = self:GetData()
    local conditions = { "[petbattle] hide" } -- Always hide in Pet Battles

    -- Hide based on role
    local spec = C_SpecializationInfo.GetSpecialization()
    local role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))
    if data.hideHealthOnRole and data.hideHealthOnRole[role] then
        table.insert(conditions, "hide")
    end

    -- Hide while mounted or in vehicle
    if data.hideWhileMountedOrVehicule then
        table.insert(conditions, "[mounted][vehicleui][possessbar][overridebar][flying] hide")
    end

    local setting = data.barVisible
    if setting == "Always Visible" then table.insert(conditions, "show")
    elseif setting == "Hidden" then table.insert(conditions, "hide")
    elseif setting == "In Combat" then table.insert(conditions, "[combat] show; hide")
    elseif setting == "Has Target Selected" then table.insert(conditions, "[@target, exists] show; hide")
    elseif setting == "Has Target Selected OR In Combat" then table.insert(conditions, "[combat][@target, exists] show; hide")
    else table.insert(conditions, "show") end

    RegisterAttributeDriver(self.Frame, "state-visibility", table.concat(conditions, "; "))
end

function HealthBarMixin:ApplyVisibilitySettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    self:HideBlizzardPlayerContainer(layoutName, data)

    if not InCombatLockdown() then
        self:RegisterSecureVisibility()
    end

    self:ApplyTextVisibilitySettings(layoutName, data)
end

function HealthBarMixin:HideBlizzardPlayerContainer(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    -- Blizzard Frames are protected in combat
    if data.hideBlizzardPlayerContainerUi == nil or InCombatLockdown() then return end

    if PlayerFrame then
        if data.hideBlizzardPlayerContainerUi == true then
            if LEM:IsInEditMode() then
                PlayerFrame:Show()
            else
                PlayerFrame:Hide()
            end
        else
            PlayerFrame:Show()
        end
    end
end

addonTable.HealthBarMixin = HealthBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.HealthBar = {
    mixin = addonTable.HealthBarMixin,
    dbName = "healthBarDB",
    editModeName = L["HEALTH_BAR_EDIT_MODE_NAME"],
    frameType = "Button",
    frameTemplate = "SecureUnitButtonTemplate,PingableUnitFrameTemplate",
    frameName = "HealthBar",
    frameLevel = 0,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 40,
        barVisible = "Hidden",
        hideHealthOnRole = {},
        hideBlizzardPlayerContainerUi = false,
        useClassColor = true,
        enableHealthBarMouseInteraction = false,
    },
    lemSettings = function(bar, defaults)
        local config = bar:GetConfig()
        local dbName = config.dbName

        return {
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 103,
                name = L["HIDE_HEALTH_ON_ROLE"],
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideHealthOnRole,
                values = addonTable.availableRoleOptions,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole) or defaults.hideHealthOnRole
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole = value
                    bar:RegisterSecureVisibility()
                end,
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 105,
                name = L["HIDE_BLIZZARD_UI"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardPlayerContainerUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardPlayerContainerUi ~= nil then
                        return data.hideBlizzardPlayerContainerUi
                    else
                        return defaults.hideBlizzardPlayerContainerUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardPlayerContainerUi = value
                    bar:HideBlizzardPlayerContainer(layoutName)
                end,
                tooltip = L["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 106,
                name = L["ENABLE_HP_BAR_MOUSE_INTERACTION"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.enableHealthBarMouseInteraction,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.enableHealthBarMouseInteraction ~= nil then
                        return data.enableHealthBarMouseInteraction
                    else
                        return defaults.enableHealthBarMouseInteraction
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].enableHealthBarMouseInteraction = value
                    bar:RegisterSecureVisibility()
                    bar:ApplyMouseSettings()
                end,
                tooltip = L["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_BAR_STYLE"],
                order = 401,
                name = L["USE_CLASS_COLOR"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.useClassColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useClassColor ~= nil then
                        return data.useClassColor
                    else
                        return defaults.useClassColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useClassColor = value
                    bar:ApplyLayout(layoutName)
                end,
            },
        }
    end,
}