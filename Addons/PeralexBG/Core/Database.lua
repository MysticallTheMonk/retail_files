-- ============================================================================
-- Peralex BG - Database.lua
-- SavedVariables management
-- ============================================================================

local PE = _G.PeralexBG

-- Default settings
local defaults = {
    position = {
        point = "RIGHT",
        relativePoint = "RIGHT",
        x = -100,
        y = 0,
    },
    
    frames = {
        width = 200,
        height = 40,
        spacing = 5,
        growDirection = "DOWN",
        maxFrames = 15,
        enableEpicBGFrames = false,
    },
    
    epicBG = {
        groupMode = "all", -- "all" = 1 group (40), "ten" = 4 groups (10 each), "twenty" = 2 groups (20 each)
        
        -- All 40 in single column mode
        allMode = {
            scale = 0.8,
            width = 180,
            height = 32,
            spacing = 2,
            position = { point = "RIGHT", relativePoint = "RIGHT", x = -50, y = 0 },
        },
        
        -- 10 per group (4 groups) mode
        tenMode = {
            groups = {
                [1] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -100, y = 200 },
                },
                [2] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -100, y = -200 },
                },
                [3] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -350, y = 200 },
                },
                [4] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -350, y = -200 },
                },
            },
        },
        
        -- 20 per group (2 groups) mode
        twentyMode = {
            groups = {
                [1] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -100, y = 0 },
                },
                [2] = {
                    scale = 1.0,
                    width = 200,
                    height = 40,
                    spacing = 3,
                    position = { point = "RIGHT", relativePoint = "RIGHT", x = -350, y = 0 },
                },
            },
        },
    },
    
    appearance = {
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        resourceBarTexture = "Interface\\Buttons\\WHITE8x8",
        showPlayerNames = true,
        showStatusText = true,
        statusTextType = "damage", -- "damage", "healing", "kills"
        healthTextFormat = "percent",
        useClassColors = true, -- Class colors on health bar
        useClassColorNames = true, -- Class colors on player name text
        sortMethod = "damage", -- "standard", "damage", "kills", "healing"
        prioritizeFlagCarrier = true,
        showEnemyCount = true,
        showAnchor = false, -- Show anchor bar in BGs
    },
    
    trinkets = {
        enabled = true,
        showCooldown = true,
        size = 24,
    },
    classIcons = {
        theme = "default", -- "default" or "coldclasses"
    },
    specIcons = {
        enabled = true,
        size = 20,
        xOffset = -2,
        yOffset = 0,
    },
    flags = {
        size = 24,
        xOffset = 2,
    },
    
    healers = {
        enabled = true,
        size = 16,
        xOffset = 2,
    },
    
    targeting = {
        focusBehavior = "both", -- "both" = focus + target, "restore" = focus + restore last target
    },
    
    minimap = {
        hide = false,
        angle = 225, -- Position around minimap (degrees)
    },
    
    skinMods = {
        capping = {
            enabled = true,
            theme = "modern", -- "none", "modern"
            useCustomFont = true, -- Use PeralexBG custom font (true) or Capping's font (false)
        },
    },
    
    debug = false,
    
    lastSeenVersion = nil, -- Track last version user saw changelog for
}

-- ============================================================================
-- DATABASE INITIALIZATION
-- ============================================================================

function PE:InitializeDatabase()
    if not PeralexBGDB then
        PeralexBGDB = {}
    end
    
    self.DB = PeralexBGDB
    
    -- Apply defaults for missing keys
    self:ApplyDefaults(self.DB, defaults)
end

function PE:ApplyDefaults(db, defaultTable)
    for key, value in pairs(defaultTable) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = {}
                self:ApplyDefaults(db[key], value)
            else
                db[key] = value
            end
        elseif type(value) == "table" and type(db[key]) == "table" then
            self:ApplyDefaults(db[key], value)
        end
    end
end

-- ============================================================================
-- SETTINGS ACCESSORS
-- ============================================================================

function PE:GetSetting(...)
    local path = {...}
    local current = self.DB
    
    for i, key in ipairs(path) do
        if current[key] == nil then
            return nil
        end
        current = current[key]
    end
    
    return current
end

function PE:SetSetting(value, ...)
    local path = {...}
    local current = self.DB
    
    for i = 1, #path - 1 do
        local key = path[i]
        if current[key] == nil then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[path[#path]] = value
end

-- ============================================================================
-- TEXTURE LIST
-- ============================================================================

PE.TextureList = {
    {name = "Smooth (Flat)", path = "Interface\\Buttons\\WHITE8x8"},
    {name = "Texture 1", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture1.tga"},
    {name = "Texture 2", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture2.tga"},
    {name = "Texture 3", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture3.tga"},
    {name = "Texture 4", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture4.tga"},
    {name = "Texture 5", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture5.tga"},
    {name = "Texture 6", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture6.tga"},
    {name = "Texture 7", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture7.tga"},
    {name = "Texture 8", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture8.tga"},
    {name = "Texture 9", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture9.tga"},
    {name = "Texture 10", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture10.tga"},
    {name = "Texture 11", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture11.tga"},
    {name = "Texture 12", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture12.tga"},
    {name = "Texture 13", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture13.tga"},
    {name = "Texture 14", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture14.tga"},
    {name = "Texture 15", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture15.tga"},
    {name = "Texture 16", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture16.tga"},
    {name = "Texture 17", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture17.tga"},
    {name = "Texture 18", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture18.tga"},
    {name = "Texture 19", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture19.tga"},
    {name = "Texture 20", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture20.tga"},
    {name = "Texture 21", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture21.tga"},
    {name = "Texture 22", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture22.tga"},
    {name = "Texture 23", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture23.tga"},
    {name = "Texture 24", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture24.tga"},
    {name = "Texture 25", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture25.tga"},
    {name = "Texture 26", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture26.tga"},
    {name = "Texture 27", path = "Interface\\AddOns\\PeralexBG\\Media\\Textures\\texture27.tga"},
}

function PE:GetTextureByName(name)
    for _, tex in ipairs(self.TextureList) do
        if tex.name == name then
            return tex.path
        end
    end
    return self.TextureList[1].path
end
