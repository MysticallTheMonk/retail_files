-- ===================================================================
-- ArcUI_CDMGroupsOptions.lua
-- Options panel for CDM Icon Groups
-- Integrated from CDMGroups addon
-- ===================================================================

local ADDON_NAME, ns = ...

-- Reference to shared module (for CDM styling toggle)
local Shared = ns.CDMShared

-- Forward declarations
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Remap alignment when grid shape changes so user's intent is preserved
local function RemapAlignmentForShape(oldShape, newShape, currentAlignment)
    if oldShape == newShape then return nil end
    
    local mapped
    if oldShape == "horizontal" and newShape == "multi" then
        local map = { center = "center_h", left = "left", right = "right" }
        mapped = map[currentAlignment]
    elseif oldShape == "vertical" and newShape == "multi" then
        local map = { center = "center_v", top = "top", bottom = "bottom" }
        mapped = map[currentAlignment]
    elseif newShape == "horizontal" then
        local map = { center_h = "center", center_v = "center", left = "left", right = "right", top = "left", bottom = "right", center = "center" }
        mapped = map[currentAlignment]
    elseif newShape == "vertical" then
        local map = { center_h = "center", center_v = "center", top = "top", bottom = "bottom", left = "top", right = "bottom", center = "center" }
        mapped = map[currentAlignment]
    end
    
    return mapped
end

-- Remap and save alignment BEFORE SetGridSize so Layout() uses the correct value
-- Does NOT call Layout - SetGridSize already does that internally
local function RemapAlignmentBeforeResize(g, oldRows, oldCols, newRows, newCols)
    local DetectGridShape = ns.CDMGroups.DetectGridShape
    local GetDefaultAlignment = ns.CDMGroups.GetDefaultAlignment
    if not DetectGridShape or not GetDefaultAlignment then return end
    
    local oldShape = DetectGridShape(oldRows, oldCols)
    local newShape = DetectGridShape(newRows, newCols)
    if oldShape == newShape then return end
    
    local old = g.layout.alignment or GetDefaultAlignment(oldShape)
    local mapped = RemapAlignmentForShape(oldShape, newShape, old)
    local newAlignment = mapped or GetDefaultAlignment(newShape)
    
    g.layout.alignment = newAlignment
    local db = g.getDB and g.getDB()
    if db then db.alignment = newAlignment end
end

-- CRITICAL: Use the exported GetSpecData from main module (reads from char storage)
-- DO NOT use ns.db.profile.cdmGroups - that's the OLD account-wide storage!
local function GetSpecData(specIndex)
    -- Use the canonical GetSpecData from CDMGroups module which reads from ns.db.char
    if ns.CDMGroups and ns.CDMGroups.GetSpecData then
        return ns.CDMGroups.GetSpecData(specIndex)
    end
    return nil
end

local function ClearPositionFromSpec(cdID)
    -- Use the canonical ClearPositionFromSpec from CDMGroups module
    if ns.CDMGroups and ns.CDMGroups.ClearPositionFromSpec then
        ns.CDMGroups.ClearPositionFromSpec(cdID)
    end
end

local function PrintMsg(msg)
    print("|cff00ccffArcUI|r: " .. msg)
end

-- Default group template
local DEFAULT_GROUPS = {
    Buffs = {
        enabled = true,
        position = { x = -200, y = 150 },
        showBorder = false,
        showBackground = false,
        autoReflow = true,  -- Default true for new groups
        lockGridSize = false,
        containerPadding = 0,
        borderColor = { r = 0.3, g = 0.8, b = 0.3, a = 1 },
        bgColor = { r = 0, g = 0, b = 0, a = 0.6 },
        layout = {
            direction = "HORIZONTAL",
            spacing = 2,
            iconSize = 36,
            perRow = 4,
            gridRows = 2,
            gridCols = 4,
            horizontalGrowth = "RIGHT",  -- RIGHT or LEFT
            verticalGrowth = "DOWN",     -- DOWN or UP
        },
    },
}

-- UI STATE FOR OPTIONS (ns.CDMGroups.selectedGroup stored globally)

local collapsedSections = {
    groupLayouts = false,  -- Start expanded - primary feature
    glLoadLayout = true,   -- Load Layout subsection
    glSaveLayout = true,   -- Save Layout subsection
    glDefaultNewSpecs = true, -- Default for new specs
    glLinkTemplate = true,  -- Link Template (Auto-Save)
    globalOptions = true,
    grid = false,
    layout = false,
    position = true,
    appearance = true,
    tools = true,
}

-- OPTIONS TABLE

local function GetOptionsTable()
    -- Helper to get selected group object
    local function GetSelectedGroup()
        return ns.CDMGroups.groups[ns.CDMGroups.selectedGroup]
    end
    
    -- Check if selected group exists in DB but NOT at runtime (broken/orphaned)
    local function IsSelectedGroupBroken()
        if not ns.CDMGroups.selectedGroup or ns.CDMGroups.selectedGroup == "" then
            return false
        end
        -- Check profile.groupLayouts for existence
        local specData = GetSpecData()
        local profile = nil
        if specData and specData.layoutProfiles then
            local profileName = specData.activeProfile or "Default"
            profile = specData.layoutProfiles[profileName]
        end
        local existsInProfile = profile and profile.groupLayouts and profile.groupLayouts[ns.CDMGroups.selectedGroup]
        local existsAtRuntime = ns.CDMGroups.groups[ns.CDMGroups.selectedGroup]
        return existsInProfile and not existsAtRuntime
    end
    
    -- Helper to check if section should be hidden
    local function HideIfNoGroup()
        return not GetSelectedGroup()
    end
    
    -- Helper for fine tuning mode
    local function IsFineTuning()
        local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
        return db and db.fineTuningLayout
    end
    
    -- Build group dropdown values (from runtime groups primarily)
    local function GetGroupValues()
        local values = {}
        
        -- Primary: Use runtime groups (authoritative for active session)
        for groupName, _ in pairs(ns.CDMGroups.groups or {}) do
            values[groupName] = groupName
        end
        
        -- Secondary: Check profile.groupLayouts for groups not yet loaded
        local specData = GetSpecData()
        local profile = nil
        if specData and specData.layoutProfiles then
            local profileName = specData.activeProfile or "Default"
            profile = specData.layoutProfiles[profileName]
        end
        
        if profile and profile.groupLayouts then
            for groupName, _ in pairs(profile.groupLayouts) do
                if not values[groupName] then
                    -- Group exists in profile but not at runtime
                    if ns.CDMGroups.initialLoadInProgress then
                        values[groupName] = "|cff888888" .. groupName .. " (loading)|r"
                    else
                        values[groupName] = "|cffff6666" .. groupName .. " (broken)|r"
                    end
                end
            end
        end
        
        return values
    end
    
    -- Create a new group with default settings (in current spec)
    local function CreateNewGroup(groupName)
        if not groupName or groupName == "" then return false end
        
        -- Check if group already exists in runtime
        if ns.CDMGroups.groups and ns.CDMGroups.groups[groupName] then
            return false -- Already exists
        end
        
        -- CreateGroup handles everything:
        -- 1. Reads from profile.groupLayouts (or creates defaults)
        -- 2. Saves new group to profile.groupLayouts
        -- 3. Creates runtime group object
        local group = ns.CDMGroups.CreateGroup(groupName)
        if not group then return false end
        
        -- Select the new group
        ns.CDMGroups.selectedGroup = groupName
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
        
        return true
    end
    
    -- Rename a group (in current spec)
    local function RenameGroup(oldName, newName)
        if not oldName or not newName or oldName == "" or newName == "" then return false end
        if oldName == newName then return false end
        
        -- Check runtime groups first (authoritative for existence check)
        if not ns.CDMGroups.groups[oldName] then return false end -- Old group doesn't exist
        if ns.CDMGroups.groups[newName] then return false end -- New name already exists
        
        -- Get profile for updating groupLayouts
        local specData = GetSpecData()
        local profile = nil
        if specData and specData.layoutProfiles then
            local profileName = specData.activeProfile or "Default"
            profile = specData.layoutProfiles[profileName]
        end
        
        -- Update profile.groupLayouts (single source of truth)
        if profile and profile.groupLayouts and profile.groupLayouts[oldName] then
            profile.groupLayouts[newName] = profile.groupLayouts[oldName]
            profile.groupLayouts[oldName] = nil
        end
        
        -- Update savedPositions references (ns.CDMGroups.savedPositions IS profile.savedPositions)
        for cdID, saved in pairs(ns.CDMGroups.savedPositions) do
            if saved.type == "group" and saved.target == oldName then
                saved.target = newName
            end
        end
        
        -- Update the actual runtime group object
        local group = ns.CDMGroups.groups[oldName]
        group.name = newName
        ns.CDMGroups.groups[newName] = group
        ns.CDMGroups.groups[oldName] = nil
        
        -- Update specGroups reference
        if ns.CDMGroups.currentSpec and ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec] then
            ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec][newName] = group
            ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec][oldName] = nil
        end
        
        -- Also clean up legacy specData.groups if it exists
        if specData and specData.groups then
            if specData.groups[oldName] then
                specData.groups[newName] = specData.groups[oldName]
                specData.groups[oldName] = nil
            end
        end
        
        -- Update title with proper color
        if group.container and group.container.title then
            local color = group.borderColor or { r = 0.5, g = 0.5, b = 0.5 }
            local hex = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
            group.container.title:SetText(hex .. newName .. "|r")
        end
        
        -- Update dragBar label
        if group.dragBar then
            for i = 1, group.dragBar:GetNumRegions() do
                local region = select(i, group.dragBar:GetRegions())
                if region and region:GetObjectType() == "FontString" then
                    region:SetText("|cffffffffDrag Group|r")
                    break
                end
            end
        end
        
        -- Update member entries
        for cdID, member in pairs(group.members) do
            if member.entry then
                member.entry.group = group
            end
        end
        
        -- Update selection
        ns.CDMGroups.selectedGroup = newName
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
        
        return true
    end
    
    -- Delete a group (from current spec)
    local function DeleteGroup(groupName)
        if not groupName or groupName == "" then return false end
        
        -- Check runtime groups (authoritative)
        if not ns.CDMGroups.groups[groupName] then return false end
        
        local group = ns.CDMGroups.groups[groupName]
        
        -- Collect all member cdIDs and place them as free icons in a row
        local toRelease = {}
        for cdID, member in pairs(group.members or {}) do
            table.insert(toRelease, { cdID = cdID, frame = member.frame })
        end
        
        -- Place icons as free icons in a horizontal row at center of screen
        local startX = -((#toRelease - 1) * 40) / 2  -- Center the row
        for i, info in ipairs(toRelease) do
            local cdID = info.cdID
            local xPos = startX + (i - 1) * 40
            local yPos = 0
            
            -- Clear from group without returning to CDM
            if group.members[cdID] then
                local member = group.members[cdID]
                if member.entry then
                    member.entry.manipulated = false
                    member.entry.group = nil
                end
                group.members[cdID] = nil
            end
            
            -- Clear from grid
            for row, cols in pairs(group.grid or {}) do
                for col, id in pairs(cols) do
                    if id == cdID then
                        cols[col] = nil
                    end
                end
            end
            
            -- Clear saved position
            ns.CDMGroups.savedPositions[cdID] = nil
            ClearPositionFromSpec(cdID)
            
            -- Track as free icon
            ns.CDMGroups.TrackFreeIcon(cdID, xPos, yPos, 36)
        end
        
        -- Hide and clean up the container
        if group.container then
            group.container:Hide()
            group.container:SetParent(nil)
        end
        if group.dragBar then
            group.dragBar:Hide()
            group.dragBar:SetParent(nil)
        end
        if group.selectionHighlight then
            group.selectionHighlight:Hide()
        end
        
        -- Hide edge arrows (the +/- buttons)
        if group.edgeArrows then
            for _, arrow in pairs(group.edgeArrows) do
                if arrow then
                    arrow:Hide()
                    arrow:SetParent(nil)
                end
            end
        end
        
        -- Remove from runtime
        ns.CDMGroups.groups[groupName] = nil
        if ns.CDMGroups.currentSpec and ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec] then
            ns.CDMGroups.specGroups[ns.CDMGroups.currentSpec][groupName] = nil
        end
        
        -- Remove from profile.groupLayouts (single source of truth)
        local specData = GetSpecData()
        if specData and specData.layoutProfiles then
            local profileName = specData.activeProfile or "Default"
            local profile = specData.layoutProfiles[profileName]
            if profile and profile.groupLayouts then
                profile.groupLayouts[groupName] = nil
            end
        end
        
        -- Also clean up legacy specData.groups if it exists
        if specData and specData.groups then
            specData.groups[groupName] = nil
        end
        
        -- Clear selection if this was selected
        if ns.CDMGroups.selectedGroup == groupName then
            -- Select another runtime group
            local newSelection = ""
            for name, _ in pairs(ns.CDMGroups.groups) do
                newSelection = name
                break
            end
            ns.CDMGroups.selectedGroup = newSelection
        end
        
        -- Trigger auto-save to linked template
        if ns.CDMGroups.TriggerTemplateAutoSave then
            ns.CDMGroups.TriggerTemplateAutoSave()
        end
        
        return true
    end
    
    local options = {
        type = "group",
        name = function()
            local specName = ns.CDMGroups.currentSpec
            if GetSpecializationInfo then
                local _, name = GetSpecializationInfo(ns.CDMGroups.currentSpec)
                if name then specName = name end
            end
            return "CDM Groups |cff888888(" .. specName .. ")|r"
        end,
        args = {
            -- EDIT MODE (enables icon dragging - auto-enables when panel opens)
            editModeToggle = {
                type = "toggle",
                name = "|cff00ff00Edit Mode|r",
                desc = "Enable dragging individual icons within groups.\n\nAuto-enables when options panel opens.",
                order = 0,
                width = 0.55,
                get = function() return ns.CDMGroups.dragModeEnabled end,
                set = function(_, val) 
                    -- Disable auto-enable when manually toggling off
                    if not val then
                        ns.CDMGroups._userDisabledEditMode = true
                    else
                        ns.CDMGroups._userDisabledEditMode = false
                    end
                    ns.CDMGroups.SetDragMode(val) 
                end,
            },
            -- DRAG GROUPS (shows overlays for dragging group containers)
            dragGroupsToggle = {
                type = "toggle",
                name = "|cff00ccffDrag Groups|r",
                desc = "Show drag overlays on groups to reposition them.\n\nDoes NOT auto-enable when panel opens.",
                order = 0.05,
                width = 0.7,
                get = function() 
                    return ns.EditModeContainers and ns.EditModeContainers.IsOverlaysEnabled and ns.EditModeContainers.IsOverlaysEnabled()
                end,
                set = function(_, val) 
                    if ns.EditModeContainers and ns.EditModeContainers.SetOverlaysEnabled then
                        ns.EditModeContainers.SetOverlaysEnabled(val)
                    end
                end,
            },
            -- MASTER ENABLE TOGGLE (uses Shared.IsCDMStylingEnabled)
            masterEnable = {
                type = "toggle",
                name = "|cff00ff00Enable CDM Styling|r",
                desc = "Master toggle to enable/disable all CDM icon styling and group management.\n\n|cffffaa00Reload recommended after changing.|r\n\nWhen disabled, icons stay under default CDM control.",
                order = 0.1,
                width = 1.0,
                get = function() 
                    -- Use centralized function from CDM_Shared
                    local S = ns.CDMShared
                    if S and S.IsCDMStylingEnabled then
                        return S.IsCDMStylingEnabled()
                    end
                    return true
                end,
                set = function(_, val) 
                    -- Use centralized function from CDM_Shared
                    local S = ns.CDMShared
                    if S and S.SetCDMStylingEnabled then
                        S.SetCDMStylingEnabled(val)
                    end
                end,
            },
            masterSpacer = {
                type = "description",
                name = "",
                order = 0.5,
                width = "full",
            },
            addDefaultGroupsBtn = {
                type = "execute",
                name = "|cff88ff88+ Default Groups|r",
                desc = "Create the 3 default groups (Buffs, Essential, Utility) if they don't exist.\n\nThis does NOT delete any existing groups or positions.",
                order = 22.5,
                width = 0.85,
                func = function()
                    if InCombatLockdown() then
                        PrintMsg("|cffff0000Cannot create groups in combat|r")
                        return
                    end
                    
                    local created = 0
                    local defaults = { "Buffs", "Essential", "Utility" }
                    
                    for _, name in ipairs(defaults) do
                        if not ns.CDMGroups.groups[name] then
                            if ns.CDMGroups.CreateGroup then
                                ns.CDMGroups.CreateGroup(name)
                                created = created + 1
                            end
                        end
                    end
                    
                    if created > 0 then
                        PrintMsg("Created " .. created .. " default group(s)")
                        ns.CDMGroups.UpdateGroupSelectionVisuals()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                    else
                        PrintMsg("All default groups already exist")
                    end
                end,
            },
            showBorderInEditMode = {
                type = "toggle",
                name = "Show Borders",
                desc = "Show group borders and backgrounds when in edit mode. Disable to see true layout without borders.",
                order = 1.5,
                width = 0.7,
                get = function()
                    -- Use shared DB accessor (reads from char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return true end  -- Default to showing
                    local val = db.showBorderInEditMode
                    if val == nil then return true end
                    return val
                end,
                set = function(_, val)
                    -- Use shared DB accessor (writes to char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return end
                    db.showBorderInEditMode = val
                    -- Update all groups
                    for _, group in pairs(ns.CDMGroups.groups or {}) do
                        if group.UpdateAppearance then
                            group.UpdateAppearance()
                        end
                    end
                    ns.CDMGroups.UpdateGroupSelectionVisuals()
                end,
            },
            showControlButtons = {
                type = "toggle",
                name = "Show Layout Arrows",
                desc = "Show the row/column add/remove arrow buttons on group edges when in edit mode.",
                order = 1.6,
                width = 0.9,
                get = function()
                    -- Use shared DB accessor (reads from char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return true end  -- Default to showing
                    local val = db.showControlButtons
                    if val == nil then return true end
                    return val
                end,
                set = function(_, val)
                    -- Use shared DB accessor (writes to char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return end
                    db.showControlButtons = val
                    ns.CDMGroups.UpdateGroupSelectionVisuals()
                end,
            },
            showDragHandle = {
                type = "toggle",
                name = "Show Drag Handle",
                desc = "Show the drag handle icon on groups when in edit mode. You can still move groups via the Edit Mode overlay even with this hidden.",
                order = 1.65,
                width = 0.9,
                get = function()
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return true end
                    local val = db.showDragHandle
                    if val == nil then return true end
                    return val
                end,
                set = function(_, val)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return end
                    db.showDragHandle = val
                    -- Immediately show/hide drag handles on all groups
                    for _, group in pairs(ns.CDMGroups.groups or {}) do
                        if group.container and group.container.dragToggleBtn then
                            if val and ns.CDMGroups.dragModeEnabled then
                                group.container.dragToggleBtn:Show()
                            else
                                group.container.dragToggleBtn:Hide()
                            end
                        end
                    end
                end,
            },
            showPlaceholders = {
                type = "toggle",
                name = "Show Placeholders",
                desc = "Show placeholder icons for saved positions that don't have an active cooldown. Disabled by default.",
                order = 1.7,
                width = 0.9,
                get = function()
                    -- Return actual editing mode state
                    if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.IsEditingMode then
                        return ns.CDMGroups.Placeholders.IsEditingMode()
                    end
                    return false
                end,
                set = function(_, val)
                    if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.SetEditingMode then
                        ns.CDMGroups.Placeholders.SetEditingMode(val)
                    end
                end,
            },
            scanBtn = {
                type = "execute",
                name = "Scan & Assign",
                desc = "Clean invalid positions and re-assign icons. Icons pointing to deleted groups get reassigned to defaults.",
                order = 2,
                width = 0.65,
                func = function()
                    -- First ensure default groups exist
                    local defaults = { "Buffs", "Essential", "Utility" }
                    for _, name in ipairs(defaults) do
                        if not ns.CDMGroups.groups[name] then
                            if ns.CDMGroups.CreateGroup then
                                ns.CDMGroups.CreateGroup(name)
                            end
                        end
                    end
                    
                    -- CRITICAL: Clean savedPositions pointing to non-existent groups
                    -- This makes Reconcile treat them as new icons and assign to defaults
                    local cleanedCount = 0
                    local savedPositions = ns.CDMGroups.savedPositions
                    if savedPositions then
                        local toRemove = {}
                        for cdID, saved in pairs(savedPositions) do
                            if saved.type == "group" and saved.target then
                                if not ns.CDMGroups.groups[saved.target] then
                                    table.insert(toRemove, cdID)
                                end
                            end
                        end
                        for _, cdID in ipairs(toRemove) do
                            savedPositions[cdID] = nil
                            cleanedCount = cleanedCount + 1
                        end
                    end
                    
                    if cleanedCount > 0 then
                        PrintMsg("|cffff8800Cleaned|r " .. cleanedCount .. " invalid positions")
                    end
                    
                    -- Run Reconcile
                    if ns.FrameController and ns.FrameController.Reconcile then
                        ns.FrameController.Reconcile()
                        PrintMsg("|cff00ff00Done|r - icons assigned to saved or default positions")
                    else
                        local count = ns.CDMGroups.ScanAllViewers and ns.CDMGroups.ScanAllViewers() or 0
                        local assigned = ns.CDMGroups.AutoAssignNewIcons and ns.CDMGroups.AutoAssignNewIcons() or 0
                        PrintMsg("Found " .. count .. " icons, assigned " .. assigned .. " new")
                    end
                    
                    -- Refresh drag handlers if drag mode is on
                    if ns.CDMGroups.dragModeEnabled and ns.FrameController and ns.FrameController.RefreshDragHandlers then
                        C_Timer.After(0.2, function()
                            ns.FrameController.RefreshDragHandlers()
                        end)
                    end
                    
                    -- Refresh
                    ns.CDMGroups.UpdateGroupSelectionVisuals()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            emergencyRescueBtn = {
                type = "execute",
                name = "|cffff8800Emergency Rescue|r",
                desc = "EMERGENCY: Find ALL frames with cooldownID that aren't being tracked and create them as FREE ICONS. Use this if icons are stuck/missing. Rescued icons appear on screen and can be dragged.",
                order = 2.1,
                width = 0.85,
                func = function()
                    if ns.CDMGroups.EmergencyRescue then
                        local rescued, tracked, errors = ns.CDMGroups.EmergencyRescue()
                        -- Refresh UI
                        ns.CDMGroups.UpdateGroupSelectionVisuals()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                    else
                        PrintMsg("|cffff0000EmergencyRescue function not available!|r")
                    end
                end,
            },
            addPlaceholderBtn = {
                type = "execute",
                name = "Placeholder Catalog",
                desc = "Open the cooldown catalog to add a placeholder for an ability you don't currently have.",
                order = 2.5,
                width = 0.95,
                func = function()
                    -- NOTE: We no longer auto-enable placeholder mode here
                    -- User must manually toggle "Show Placeholders" if they want to see them
                    -- Open the catalog picker (it's called ShowCooldownPicker in Placeholders module)
                    if ns.CDMGroups.Placeholders and ns.CDMGroups.Placeholders.ShowCooldownPicker then
                        ns.CDMGroups.Placeholders.ShowCooldownPicker()
                    else
                        PrintMsg("Placeholder picker not available. Use /arcuiph picker")
                    end
                end,
            },
            openCDM = {
                type = "execute",
                name = "Open CD Manager",
                desc = "Open the Cooldown Manager settings panel",
                order = 2.7,
                width = 0.95,
                func = function()
                    local frame = _G["CooldownViewerSettings"]
                    if frame and frame.Show then
                        frame:Show()
                        frame:Raise()
                    end
                end,
            },
            helpText = {
                type = "description",
                name = "|cffaaaaaa" ..
                    "Tip: If an icon is stuck in CDM's original location, click |cff00ff00Scan|r to grab it.\n" ..
                    "Use |cff00ff00Placeholder Catalog|r to reserve a slot for abilities you don't currently have.|r",
                order = 2.9,
                width = "full",
                fontSize = "small",
            },
            spacer1 = {
                type = "description",
                name = "",
                order = 3,
                width = "full",
            },
            
            -- ════════════════════════════════════════════════════════════════
            -- GROUP LAYOUTS SECTION (account-wide templates)
            -- ════════════════════════════════════════════════════════════════
            groupLayoutsToggle = {
                type = "toggle",
                name = "Group Layouts",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 5,
                width = "full",
                get = function() return not collapsedSections.groupLayouts end,
                set = function(_, v) collapsedSections.groupLayouts = not v end,
            },
            groupLayoutsDesc = {
                type = "description",
                name = "|cffaaaaaaSave and load group layouts. Layouts are account-wide and contain group structure (positions, sizes, colors). Icons auto-assign after loading.|r",
                order = 5.1,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.groupLayouts end,
            },
            
            -- Current Layout Info
            currentLayoutInfo = {
                type = "description",
                name = function()
                    local groupNames = {}
                    if ns.CDMGroups and ns.CDMGroups.groups then
                        for gName in pairs(ns.CDMGroups.groups) do
                            table.insert(groupNames, gName)
                        end
                    end
                    table.sort(groupNames)
                    
                    if #groupNames == 0 then
                        return "|cffffd100Current Layout:|r  |cff666666No groups loaded|r"
                    end
                    
                    local groupList = table.concat(groupNames, ", ")
                    
                    -- Check for loaded/linked template
                    local IE = ns.CDMImportExport
                    local loadedName = IE and IE.GetLoadedTemplateName and IE.GetLoadedTemplateName()
                    local linkedName = IE and IE.GetLinkedTemplateName and IE.GetLinkedTemplateName()
                    
                    -- Build display - template name is primary when available
                    if linkedName then
                        -- Linked: show template name prominently with linked indicator
                        return "|cffffd100Current Layout:|r |cff00ccff" .. linkedName .. "|r |cff00ff00[Linked]|r  |cff888888(" .. #groupNames .. " groups: " .. groupList .. ")|r"
                    elseif loadedName then
                        -- Based on template but not linked
                        return "|cffffd100Current Layout:|r |cffffffff" .. loadedName .. "|r  |cff888888(" .. #groupNames .. " groups: " .. groupList .. ")|r"
                    else
                        -- No template
                        return "|cffffd100Current Layout:|r  |cff00ff00" .. #groupNames .. " groups|r  |cff888888(" .. groupList .. ")|r"
                    end
                end,
                order = 5.15,
                width = "full",
                fontSize = "medium",
                hidden = function() return collapsedSections.groupLayouts end,
            },
            
            -- Unlink button (shown when linked)
            unlinkTemplateBtn = {
                type = "execute",
                name = "|cffff8888Unlink|r",
                desc = "Stop auto-saving changes to the linked template",
                order = 5.16,
                width = 0.5,
                hidden = function()
                    if collapsedSections.groupLayouts then return true end
                    local IE = ns.CDMImportExport
                    local linkedName = IE and IE.GetLinkedTemplateName and IE.GetLinkedTemplateName()
                    return not linkedName
                end,
                func = function()
                    local IE = ns.CDMImportExport
                    if IE and IE.UnlinkTemplate then
                        IE.UnlinkTemplate()
                        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                        if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                    end
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- SUBSECTION: Load Group Layout
            -- ═══════════════════════════════════════════════════════════════════
            glLoadLayoutToggle = {
                type = "toggle",
                name = "    Load Group Layout",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 5.2,
                width = "full",
                hidden = function() return collapsedSections.groupLayouts end,
                get = function() return not collapsedSections.glLoadLayout end,
                set = function(_, v) collapsedSections.glLoadLayout = not v end,
            },
            glLoadLayoutDesc = {
                type = "description",
                name = "|cff888888Select a saved layout or profile to load.|r",
                order = 5.21,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.groupLayouts or collapsedSections.glLoadLayout end,
            },
            
            -- === GROUP LAYOUTS DROPDOWN === (UNDER CONSTRUCTION)
            glLayoutsLabel = {
                type = "description",
                name = "|cffffd100Group Layouts|r |cffff6666[Under Construction]|r\n|cff888888This feature is being reworked to integrate better with Arc Manager Profiles.\nUse 'Arc Manager Profiles' below to import layouts.|r",
                order = 5.215,
                width = "full",
                fontSize = "medium",
                hidden = function() return collapsedSections.groupLayouts or collapsedSections.glLoadLayout end,
            },
            glLayoutSelect = {
                type = "select",
                name = "",
                desc = "Select a Group Layout to load",
                order = 5.22,
                width = 1.4,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                values = function()
                    local vals = { [""] = "|cff666666Select a layout...|r" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetGroupTemplates then
                        local templates = IE.GetGroupTemplates()
                        for _, t in ipairs(templates) do
                            local groupInfo = t.groupCount > 0 and (" |cff888888(" .. t.groupCount .. " groups)|r") or ""
                            vals[t.name] = "|cff00ccff" .. t.displayName .. "|r" .. groupInfo
                        end
                    end
                    return vals
                end,
                sorting = function()
                    local order = { "" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetGroupTemplates then
                        local templates = IE.GetGroupTemplates()
                        for _, t in ipairs(templates) do
                            order[#order + 1] = t.name
                        end
                    end
                    return order
                end,
                get = function() return ns.CDMGroupsOptions_selectedLayout or "" end,
                set = function(_, val) ns.CDMGroupsOptions_selectedLayout = val ~= "" and val or nil end,
            },
            glLoadBtn = {
                type = "execute",
                name = "|cff00ff00Load|r",
                desc = "Load selected layout",
                order = 5.23,
                width = 0.4,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                disabled = function() return not ns.CDMGroupsOptions_selectedLayout or ns.CDMGroupsOptions_selectedLayout == "" end,
                func = function()
                    if not ns.CDMGroupsOptions_selectedLayout then return end
                    StaticPopupDialogs["ARCUI_GROUPS_LOAD_LAYOUT"] = {
                        text = "Load Group Layout '" .. ns.CDMGroupsOptions_selectedLayout .. "'?\n\nThis will REPLACE your current group layout.\nIcons will be auto-assigned.",
                        button1 = "Load",
                        button2 = "Cancel",
                        OnAccept = function()
                            local IE = ns.CDMImportExport
                            if IE and IE.LoadGroupTemplate then
                                IE.LoadGroupTemplate(ns.CDMGroupsOptions_selectedLayout)
                            end
                            ns.CDMGroupsOptions_selectedLayout = nil
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                        end,
                        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_GROUPS_LOAD_LAYOUT")
                end,
            },
            glDeleteBtn = {
                type = "execute",
                name = "|cffff6666Delete|r",
                desc = "Delete selected layout",
                order = 5.24,
                width = 0.45,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                disabled = function() return not ns.CDMGroupsOptions_selectedLayout or ns.CDMGroupsOptions_selectedLayout == "" end,
                func = function()
                    if not ns.CDMGroupsOptions_selectedLayout then return end
                    StaticPopupDialogs["ARCUI_GROUPS_DELETE_LAYOUT"] = {
                        text = "Delete Group Layout '" .. ns.CDMGroupsOptions_selectedLayout .. "'?\n\nThis cannot be undone.",
                        button1 = "Delete",
                        button2 = "Cancel",
                        OnAccept = function()
                            local IE = ns.CDMImportExport
                            if IE and IE.DeleteGroupTemplate then
                                IE.DeleteGroupTemplate(ns.CDMGroupsOptions_selectedLayout)
                            end
                            ns.CDMGroupsOptions_selectedLayout = nil
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                        end,
                        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_GROUPS_DELETE_LAYOUT")
                end,
            },
            glNoLayoutsNote = {
                type = "description",
                name = "|cff666666No layouts saved yet. Use 'Save Current Layout' below.|r",
                order = 5.25,
                width = "full",
                fontSize = "small",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            
            -- === ARC MANAGER PROFILES DROPDOWN ===
            glProfilesLabel = {
                type = "description",
                name = "\n|cffffd100Arc Manager Profiles|r |cff888888(from any character/spec)|r",
                order = 5.30,
                width = "full",
                fontSize = "medium",
                hidden = function() return collapsedSections.groupLayouts or collapsedSections.glLoadLayout end,
            },
            glProfilesNote = {
                type = "description",
                name = function()
                    local activeProfile = (ns.CDMGroups and ns.CDMGroups.GetActiveProfileName) and ns.CDMGroups.GetActiveProfileName() or "Default"
                    return "|cff666666Current profile '|cff00ff00" .. activeProfile .. "|cff666666' not shown.|r"
                end,
                order = 5.31,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.groupLayouts or collapsedSections.glLoadLayout end,
            },
            glProfilesSelect = {
                type = "select",
                name = "",
                desc = "Select an Arc Manager Profile to load",
                order = 5.32,
                width = 1.4,
                hidden = function()
                    if collapsedSections.groupLayouts or collapsedSections.glLoadLayout then return true end
                    local IE = ns.CDMImportExport
                    if not IE or not IE.GetAvailableProfiles then return true end
                    local profiles = IE.GetAvailableProfiles()
                    return #profiles == 0
                end,
                values = function()
                    local vals = { [""] = "|cff666666Select a profile...|r" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetAvailableProfiles then
                        local profiles = IE.GetAvailableProfiles()
                        for _, p in ipairs(profiles) do
                            vals[p.key] = p.displayName
                        end
                    end
                    return vals
                end,
                sorting = function()
                    local order = { "" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetAvailableProfiles then
                        local profiles = IE.GetAvailableProfiles()
                        for _, p in ipairs(profiles) do
                            order[#order + 1] = p.key
                        end
                    end
                    return order
                end,
                get = function() return ns.CDMGroupsOptions_selectedProfile or "" end,
                set = function(_, val) ns.CDMGroupsOptions_selectedProfile = val ~= "" and val or nil end,
            },
            glProfilesLoadBtn = {
                type = "execute",
                name = "|cff00ff00Load|r",
                desc = "Load selected profile",
                order = 5.33,
                width = 0.4,
                hidden = function()
                    if collapsedSections.groupLayouts or collapsedSections.glLoadLayout then return true end
                    local IE = ns.CDMImportExport
                    if not IE or not IE.GetAvailableProfiles then return true end
                    local profiles = IE.GetAvailableProfiles()
                    return #profiles == 0
                end,
                disabled = function() return not ns.CDMGroupsOptions_selectedProfile or ns.CDMGroupsOptions_selectedProfile == "" end,
                func = function()
                    local sel = ns.CDMGroupsOptions_selectedProfile
                    if not sel or sel == "" then return end
                    
                    local IE = ns.CDMImportExport
                    if not IE or not IE.GetAvailableProfiles then return end
                    
                    -- Find profile info
                    local profiles = IE.GetAvailableProfiles()
                    local info = nil
                    for _, p in ipairs(profiles) do
                        if p.key == sel then
                            info = p
                            break
                        end
                    end
                    if not info then return end
                    
                    local confirmText = info.profileName .. " (" .. info.charName .. " - " .. info.specName .. ")"
                    
                    StaticPopupDialogs["ARCUI_GROUPS_LOAD_PROFILE"] = {
                        text = "Load profile '" .. confirmText .. "'?\n\nThis will REPLACE your current group layout.\n|cffffaa00Requires a UI reload to complete.|r",
                        button1 = "Load",
                        button2 = "Cancel",
                        OnAccept = function()
                            if IE.ImportLayoutFromAccount then
                                IE.ImportLayoutFromAccount(info.key)
                            end
                            ns.CDMGroupsOptions_selectedProfile = nil
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                            
                            -- Show reload prompt after layout import
                            C_Timer.After(0.1, function()
                                StaticPopupDialogs["ARCUI_GROUPS_RELOAD_AFTER_LAYOUT"] = {
                                    text = "Group layout imported successfully!\n\nPlease reload your UI to apply the changes.",
                                    button1 = "Reload Now",
                                    button2 = "Later",
                                    OnAccept = function()
                                        ReloadUI()
                                    end,
                                    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
                                }
                                StaticPopup_Show("ARCUI_GROUPS_RELOAD_AFTER_LAYOUT")
                            end)
                        end,
                        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
                    }
                    StaticPopup_Show("ARCUI_GROUPS_LOAD_PROFILE")
                end,
            },
            glProfilesNoData = {
                type = "description",
                name = "|cff666666No other profiles available.\n• Create profiles in Import/Export → Arc Manager Profiles\n• Play other specs to generate layouts|r",
                order = 5.34,
                width = "full",
                fontSize = "small",
                hidden = function()
                    if collapsedSections.groupLayouts or collapsedSections.glLoadLayout then return true end
                    local IE = ns.CDMImportExport
                    if not IE or not IE.GetAvailableProfiles then return false end
                    local profiles = IE.GetAvailableProfiles()
                    return #profiles > 0
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- SUBSECTION: Save Current Layout (UNDER CONSTRUCTION)
            -- ═══════════════════════════════════════════════════════════════════
            glSaveLayoutToggle = {
                type = "toggle",
                name = "    Save Current Layout |cffff6666[Under Construction]|r",
                desc = "This feature is being reworked",
                dialogControl = "CollapsibleHeader",
                order = 6.0,
                width = "full",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                get = function() return not collapsedSections.glSaveLayout end,
                set = function(_, v) collapsedSections.glSaveLayout = not v end,
            },
            glSaveLayoutDesc = {
                type = "description",
                name = "|cff888888Save your current group layout as a new template.|r",
                order = 6.01,
                width = "full",
                fontSize = "small",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            glSaveName = {
                type = "input",
                name = "Layout Name",
                desc = "Name for the new layout",
                order = 6.02,
                width = 1.0,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                get = function() return ns.CDMGroupsOptions_newLayoutName or "" end,
                set = function(_, val) ns.CDMGroupsOptions_newLayoutName = val end,
            },
            glSaveBtn = {
                type = "execute",
                name = "|cff00ff00Save|r",
                desc = "Save current groups as a new layout",
                order = 6.03,
                width = 0.4,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                disabled = function() return not ns.CDMGroupsOptions_newLayoutName or ns.CDMGroupsOptions_newLayoutName == "" end,
                func = function()
                    local name = ns.CDMGroupsOptions_newLayoutName
                    if not name or name == "" then return end
                    
                    local IE = ns.CDMImportExport
                    local Shared = ns.CDMShared
                    
                    -- Check for existing
                    local templates = Shared and Shared.GetGroupTemplatesDB()
                    if templates and templates[name] then
                        StaticPopupDialogs["ARCUI_GROUPS_OVERWRITE_LAYOUT"] = {
                            text = "Layout '" .. name .. "' already exists.\n\nOverwrite it?",
                            button1 = "Overwrite",
                            button2 = "Cancel",
                            OnAccept = function()
                                if IE and IE.SaveGroupTemplate then
                                    IE.SaveGroupTemplate(name)
                                end
                                ns.CDMGroupsOptions_newLayoutName = ""
                                local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                            end,
                            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
                        }
                        StaticPopup_Show("ARCUI_GROUPS_OVERWRITE_LAYOUT")
                    else
                        if IE and IE.SaveGroupTemplate then
                            IE.SaveGroupTemplate(name)
                        end
                        ns.CDMGroupsOptions_newLayoutName = ""
                        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                        if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                    end
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- SUBSECTION: Default for New Specs (UNDER CONSTRUCTION)
            -- ═══════════════════════════════════════════════════════════════════
            glDefaultToggle = {
                type = "toggle",
                name = "    Default for New Specs |cffff6666[Under Construction]|r",
                desc = "This feature is being reworked",
                dialogControl = "CollapsibleHeader",
                order = 6.5,
                width = "full",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                get = function() return not collapsedSections.glDefaultNewSpecs end,
                set = function(_, v) collapsedSections.glDefaultNewSpecs = not v end,
            },
            glDefaultDesc = {
                type = "description",
                name = "|cff888888When you switch to a spec for the first time, it will use this layout.|r",
                order = 6.51,
                width = "full",
                fontSize = "small",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            glDefaultSelect = {
                type = "select",
                name = "Default Layout",
                desc = "Layout to use when initializing a new spec",
                order = 6.52,
                width = 1.3,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                values = function()
                    local vals = { ["_BUILTIN_"] = "|cff666666None|r |cff888888- use built-in 3-group layout|r" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetGroupTemplates then
                        local templates = IE.GetGroupTemplates()
                        for _, t in ipairs(templates) do
                            local groupInfo = t.groupCount > 0 and (" |cff888888(" .. t.groupCount .. " groups)|r") or ""
                            vals[t.name] = "|cff00ccff" .. t.displayName .. "|r" .. groupInfo
                        end
                    end
                    return vals
                end,
                get = function()
                    local Shared = ns.CDMShared
                    if Shared then
                        local name = Shared.GetDefaultTemplateName()
                        return name or "_BUILTIN_"
                    end
                    return "_BUILTIN_"
                end,
                set = function(_, val)
                    local Shared = ns.CDMShared
                    if Shared then
                        local newVal = (val ~= "_BUILTIN_") and val or nil
                        Shared.SetDefaultTemplateName(newVal)
                        PrintMsg(newVal and ("New specs will use '" .. newVal .. "' layout") or "New specs will use built-in default layout")
                    end
                end,
            },
            
            -- ═══════════════════════════════════════════════════════════════════
            -- SUBSECTION: Link Template (Auto-Save) (UNDER CONSTRUCTION)
            -- ═══════════════════════════════════════════════════════════════════
            glLinkToggle = {
                type = "toggle",
                name = "    Link Template (Auto-Save) |cffff6666[Under Construction]|r",
                desc = "This feature is being reworked",
                dialogControl = "CollapsibleHeader",
                order = 6.7,
                width = "full",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                get = function() return not collapsedSections.glLinkTemplate end,
                set = function(_, v) collapsedSections.glLinkTemplate = not v end,
            },
            glLinkDesc = {
                type = "description",
                name = "|cff888888Link to a template to automatically save changes as you make them.|r",
                order = 6.71,
                width = "full",
                fontSize = "small",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            glLinkCurrentStatus = {
                type = "description",
                name = function()
                    local IE = ns.CDMImportExport
                    local linkedName = IE and IE.GetLinkedTemplateName and IE.GetLinkedTemplateName()
                    if linkedName then
                        return "|cff00ff00Currently linked to:|r |cffffffff" .. linkedName .. "|r"
                    end
                    return "|cff888888Not currently linked to any template.|r"
                end,
                order = 6.72,
                width = "full",
                fontSize = "medium",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            glLinkSelect = {
                type = "select",
                name = "Link To",
                desc = "Select a template to link to. Changes will be auto-saved to this template.",
                order = 6.73,
                width = 1.3,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                values = function()
                    local vals = { [""] = "|cff666666Select a template to link...|r" }
                    local IE = ns.CDMImportExport
                    if IE and IE.GetGroupTemplates then
                        local templates = IE.GetGroupTemplates()
                        for _, t in ipairs(templates) do
                            vals[t.name] = "|cff00ccff" .. t.displayName .. "|r"
                        end
                    end
                    return vals
                end,
                get = function() return ns.CDMGroupsOptions_linkTemplate or "" end,
                set = function(_, val) ns.CDMGroupsOptions_linkTemplate = val ~= "" and val or nil end,
            },
            glLinkBtn = {
                type = "execute",
                name = "|cff00ccffLink|r",
                desc = "Link to the selected template",
                order = 6.74,
                width = 0.5,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                disabled = function() return not ns.CDMGroupsOptions_linkTemplate or ns.CDMGroupsOptions_linkTemplate == "" end,
                func = function()
                    local name = ns.CDMGroupsOptions_linkTemplate
                    if not name or name == "" then return end
                    
                    local IE = ns.CDMImportExport
                    if IE and IE.SetLinkedTemplateName then
                        IE.SetLinkedTemplateName(name)
                        -- Also save current state to the template immediately
                        if IE.SaveGroupTemplate then
                            IE.SaveGroupTemplate(name, nil, true)
                        end
                        ns.CDMGroupsOptions_linkTemplate = nil
                        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                        if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                    end
                end,
            },
            glUnlinkBtn = {
                type = "execute",
                name = "|cffff8888Unlink|r",
                desc = "Stop auto-saving changes to the linked template",
                order = 6.75,
                width = 0.5,
                hidden = function() return true end,  -- UNDER CONSTRUCTION
                func = function()
                    local IE = ns.CDMImportExport
                    if IE and IE.UnlinkTemplate then
                        IE.UnlinkTemplate()
                        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                        if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                    end
                end,
            },
            glLinkNote = {
                type = "description",
                name = "|cff666666When linked, any changes to group positions, sizes, colors, or settings will automatically save to the linked template after a short delay.|r",
                order = 6.76,
                width = "full",
                fontSize = "small",
                hidden = function() return true end,  -- UNDER CONSTRUCTION
            },
            
            glAdvancedNote = {
                type = "description",
                name = "\n|cffff6666Note: Group Layout Templates are being reworked.\nUse 'Arc Manager Profiles' above to import group layouts from other specs/characters.|r",
                order = 7,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.groupLayouts end,
            },
            
            -- ════════════════════════════════════════════════════════════════
            -- GLOBAL OPTIONS SECTION (collapsible)
            -- ════════════════════════════════════════════════════════════════
            globalOptionsToggle = {
                type = "toggle",
                name = "Global Options",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 16,
                width = "full",
                get = function() return not collapsedSections.globalOptions end,
                set = function(_, v) collapsedSections.globalOptions = not v end,
            },
            globalOptionsDesc = {
                type = "description",
                name = "|cffaaaaaaGlobal settings that apply to all icons managed by ArcUI.|r",
                order = 16.1,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.globalOptions end,
            },
            clickThrough = {
                type = "toggle",
                name = "Click-Through",
                desc = "When enabled, icons cannot be clicked - mouse clicks pass through to whatever is behind them.\n\nThis also disables tooltips since mouse events don't register.\n\nUseful if icons overlap clickable UI elements.",
                order = 16.2,
                width = 0.7,
                hidden = function() return collapsedSections.globalOptions end,
                get = function()
                    -- Use shared DB accessor (reads from char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return false end  -- Default: clickable
                    return db.clickThrough == true
                end,
                set = function(_, val)
                    -- Use shared DB accessor (writes to char.cdmGroups)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if not db then return end
                    db.clickThrough = val
                    -- Refresh cache
                    if ns.CDMGroups and ns.CDMGroups.RefreshCachedLayoutSettings then
                        ns.CDMGroups.RefreshCachedLayoutSettings()
                    end
                    -- FORCE apply click-through immediately to all frames
                    if ns.CDMGroups and ns.CDMGroups.ForceApplyClickThrough then
                        ns.CDMGroups.ForceApplyClickThrough(val)
                    end
                end,
            },
            containerSyncHeader = {
                type = "description",
                name = "\n|cff88ffffContainer Sync|r - Sync CDM viewers to ArcUI group positions",
                order = 16.4,
                width = "full",
                fontSize = "medium",
                hidden = function() return collapsedSections.globalOptions end,
            },
            containerSyncDesc = {
                type = "description",
                name = "|cffaaaaaaContainer sync is currently disabled. This feature will return in a future update.|r",
                order = 16.41,
                width = "full",
                fontSize = "small",
                hidden = function() return collapsedSections.globalOptions end,
            },
            syncBuffs = {
                type = "toggle",
                name = "Sync Buffs",
                desc = "Sync the BuffIcon CDM viewer to the Buffs group position. (Currently disabled)",
                order = 16.5,
                width = 0.6,
                disabled = true,
                hidden = function() return collapsedSections.globalOptions end,
                get = function()
                    return false
                end,
                set = function(_, val)
                    -- Disabled for now
                end,
            },
            syncEssential = {
                type = "toggle",
                name = "Sync Essential",
                desc = "Sync the Essential CDM viewer to the Essential group position. (Currently disabled)",
                order = 16.6,
                width = 0.7,
                disabled = true,
                hidden = function() return collapsedSections.globalOptions end,
                get = function()
                    return false
                end,
                set = function(_, val)
                    -- Disabled for now
                end,
            },
            syncUtility = {
                type = "toggle",
                name = "Sync Utility",
                desc = "Sync the Utility CDM viewer to the Utility group position. (Currently disabled)",
                order = 16.7,
                width = 0.6,
                disabled = true,
                hidden = function() return collapsedSections.globalOptions end,
                get = function()
                    return false
                end,
                set = function(_, val)
                    -- Disabled for now
                end,
            },
            globalOptionsSpacer = {
                type = "description",
                name = " ",
                order = 16.9,
                width = "full",
                hidden = function() return collapsedSections.globalOptions end,
            },
            
            -- GROUP MANAGEMENT
            groupManageHeader = {
                type = "header",
                name = function()
                    local g = GetSelectedGroup()
                    if g then
                        local color = g.borderColor or { r = 0.5, g = 0.5, b = 0.5 }
                        local hex = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
                        local memberCount = 0
                        for _ in pairs(g.members) do memberCount = memberCount + 1 end
                        local slots = g.layout.gridRows * g.layout.gridCols
                        return "Group Editing: " .. hex .. g.name .. "|r |cff888888[" .. memberCount .. "/" .. slots .. "]|r"
                    end
                    return "Group Editing: |cff888888Select a Group|r"
                end,
                order = 20,
            },
            groupSelect = {
                type = "select",
                name = "",
                desc = "Choose group to edit. Or click a group in-game!",
                order = 21,
                width = 1.0,
                values = GetGroupValues,
                get = function() return ns.CDMGroups.selectedGroup end,
                set = function(_, val) 
                    ns.CDMGroups.selectedGroup = val 
                    ns.CDMGroups.UpdateGroupSelectionVisuals()
                end,
            },
            newGroupBtn = {
                type = "execute",
                name = "|cff88ff88+ New Group|r",
                desc = "Create a new group",
                order = 22,
                width = 0.65,
                func = function()
                    -- Generate unique name (check runtime groups, authoritative for existence)
                    local baseName = "Group"
                    local num = 1
                    local groups = ns.CDMGroups.groups or {}
                    while groups[baseName .. num] do
                        num = num + 1
                    end
                    local newName = baseName .. num
                    if CreateNewGroup(newName) then
                        PrintMsg("Created '" .. newName .. "'")
                        ns.CDMGroups.UpdateGroupSelectionVisuals()
                    end
                end,
            },
            renameGroupInput = {
                type = "input",
                name = "Rename",
                desc = "New name for selected group",
                order = 23,
                width = 0.55,
                hidden = HideIfNoGroup,
                get = function() return "" end,
                set = function(_, val)
                    if val and val ~= "" and ns.CDMGroups.selectedGroup then
                        local oldName = ns.CDMGroups.selectedGroup
                        if RenameGroup(oldName, val) then
                            PrintMsg("Renamed to '" .. val .. "'")
                            ns.CDMGroups.UpdateGroupSelectionVisuals()
                            -- Refresh options panel to show new name
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                        else
                            print("|cffff0000CDMGroups|r: Name exists or invalid")
                        end
                    end
                end,
            },
            deleteGroupBtn = {
                type = "execute",
                name = "|cffff6666X|r",
                desc = "Delete selected group",
                order = 24,
                width = 0.25,
                hidden = function()
                    -- Show delete for both valid AND broken groups
                    return not GetSelectedGroup() and not IsSelectedGroupBroken()
                end,
                confirm = function() 
                    if IsSelectedGroupBroken() then
                        return "Delete broken group '" .. (ns.CDMGroups.selectedGroup or "") .. "'?\n\nThis will remove the corrupted entry."
                    end
                    return "Delete '" .. (ns.CDMGroups.selectedGroup or "") .. "'?\nIcons become free." 
                end,
                func = function()
                    if ns.CDMGroups.selectedGroup then
                        local name = ns.CDMGroups.selectedGroup
                        if DeleteGroup(name) then
                            PrintMsg("Deleted '" .. name .. "'")
                            ns.CDMGroups.UpdateGroupSelectionVisuals()
                        end
                    end
                end,
            },
            repairGroupBtn = {
                type = "execute",
                name = "|cffffaa00Repair|r",
                desc = "Attempt to recreate this broken group",
                order = 24.5,
                width = 0.45,
                hidden = function()
                    -- Only show for broken groups
                    return not IsSelectedGroupBroken()
                end,
                func = function()
                    if ns.CDMGroups.selectedGroup and IsSelectedGroupBroken() then
                        local name = ns.CDMGroups.selectedGroup
                        -- Try to recreate the group
                        local group = ns.CDMGroups.CreateGroup(name)
                        if group then
                            PrintMsg("Repaired group '" .. name .. "'")
                            ns.CDMGroups.UpdateGroupSelectionVisuals()
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                        else
                            PrintMsg("|cffff0000Failed to repair|r '" .. name .. "' - try deleting and recreating")
                        end
                    end
                end,
            },
            
            -- WARNING: Broken group message
            brokenGroupWarning = {
                type = "description",
                name = "|cffff6666⚠ This group is broken!|r\n\n" ..
                       "|cffaaaaaaThe group exists in saved data but failed to load properly.\n" ..
                       "This can happen after a Lua error or addon update.\n\n" ..
                       "Try |cffffaa00Repair|r to recreate it, or |cffff6666X|r to delete it.|r",
                order = 25,
                fontSize = "medium",
                width = "full",
                hidden = function()
                    return not IsSelectedGroupBroken()
                end,
            },
            
            -- GRID SETTINGS SECTION
            gridHeader = {
                type = "toggle",
                name = "Grid Settings",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 30,
                width = "full",
                get = function() return not collapsedSections.grid end,
                set = function(_, v) collapsedSections.grid = not v end,
            },
            gridRows = {
                type = "range",
                name = "Rows",
                desc = "Number of rows in the grid. Grid will auto-expand when icons are added.",
                order = 31,
                min = 1, max = 20, step = 1,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.gridRows or 2
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        local oldRows = g.layout.gridRows or 1
                        local oldCols = g.layout.gridCols or 1
                        -- Remap alignment BEFORE SetGridSize (which calls Layout internally)
                        RemapAlignmentBeforeResize(g, oldRows, oldCols, val, oldCols)
                        g:SetGridSize(val, oldCols)
                    end
                end,
            },
            gridCols = {
                type = "range",
                name = "Columns",
                desc = "Number of columns in the grid",
                order = 32,
                min = 1, max = 20, step = 1,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.gridCols or 4
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        local oldRows = g.layout.gridRows or 1
                        local oldCols = g.layout.gridCols or 1
                        -- Remap alignment BEFORE SetGridSize (which calls Layout internally)
                        RemapAlignmentBeforeResize(g, oldRows, oldCols, oldRows, val)
                        g:SetGridSize(oldRows, val)
                    end
                end,
            },
            horizontalGrowth = {
                type = "select",
                name = "Col Growth",
                desc = "Column growth direction - where new columns are added when grid expands",
                order = 33,
                width = 0.55,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                values = { RIGHT = "Right", LEFT = "Left" },
                get = function()
                    local g = GetSelectedGroup()
                    if not g then return "RIGHT" end
                    return g.layout.horizontalGrowth or "RIGHT"
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        g.layout.horizontalGrowth = val
                        -- Save to DB (flat structure - db.horizontalGrowth, NOT db.layout.horizontalGrowth)
                        local db = g.getDB and g.getDB()
                        if db then
                            db.horizontalGrowth = val
                        end
                        -- Trigger layout refresh
                        if g.Layout then g:Layout() end
                        -- Trigger auto-save to linked template
                        if ns.CDMGroups.TriggerTemplateAutoSave then
                            ns.CDMGroups.TriggerTemplateAutoSave()
                        end
                    end
                end,
            },
            verticalGrowth = {
                type = "select",
                name = "Row Growth",
                desc = "Row growth direction - where new rows are added when grid expands",
                order = 33.5,
                width = 0.6,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                values = { DOWN = "Down", UP = "Up" },
                get = function()
                    local g = GetSelectedGroup()
                    if not g then return "DOWN" end
                    return g.layout.verticalGrowth or "DOWN"
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        g.layout.verticalGrowth = val
                        -- Save to DB (flat structure - db.verticalGrowth, NOT db.layout.verticalGrowth)
                        local db = g.getDB and g.getDB()
                        if db then
                            db.verticalGrowth = val
                        end
                        -- Trigger layout refresh
                        if g.Layout then g:Layout() end
                        -- Trigger auto-save to linked template
                        if ns.CDMGroups.TriggerTemplateAutoSave then
                            ns.CDMGroups.TriggerTemplateAutoSave()
                        end
                    end
                end,
            },
            lockGridSize = {
                type = "toggle",
                name = "Lock Grid Size",
                desc = "Prevent grid expansion when dragging icons in this group (prevents accidental row/column creation)",
                order = 34,
                width = 0.8,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                get = function() 
                    local g = GetSelectedGroup()
                    return g and g.lockGridSize
                end,
                set = function(_, val) 
                    local g = GetSelectedGroup()
                    if g then g:SetLockGridSize(val) end
                end,
            },
            gridRowBreak1 = {
                type = "description",
                name = "",
                order = 34.9,
                width = "full",
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
            },
            containerPadding = {
                type = "range",
                name = "Container Padding",
                desc = "Space around icons inside the container. 0 = icons touch border, 4 = compact, 8 = classic with border room.",
                order = 35,
                width = 1.0,
                min = 0,
                max = 12,
                step = 1,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                get = function()
                    local g = GetSelectedGroup()
                    -- Internal -4 displays as 0, internal 0 displays as 4, etc.
                    return g and (g.containerPadding or 0) + 4 or 4
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    -- Slider 0 stores as -4, slider 4 stores as 0, etc.
                    if g then g:SetContainerPadding(val - 4) end
                end,
            },
            layoutSpacer = {
                type = "description",
                name = "",
                order = 35.9,
                width = "full",
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
            },
            autoReflow = {
                type = "toggle",
                name = "Dynamic Layout",
                desc = "Automatically compacts icons together with no gaps. Uses alignment setting to control positioning direction. When disabled, icons stay at their assigned grid positions.",
                order = 36,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.grid end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.autoReflow
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then 
                        -- When enabling, ensure alignment is saved
                        if val and not g.layout.alignment then
                            local rows = g.layout.gridRows or 1
                            local cols = g.layout.gridCols or 1
                            local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "horizontal"
                            local defaultAlignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "center"
                            g.layout.alignment = defaultAlignment
                            local db = g.getDB and g.getDB()
                            if db then
                                db.alignment = defaultAlignment
                            end
                        end
                        g:SetAutoReflow(val) 
                    end
                end,
            },
            alignmentAnchor = {
                type = "select",
                name = "Alignment",
                desc = "Where icons align within the group when Dynamic Layout is enabled.",
                order = 36.5,
                width = 0.8,
                hidden = function() 
                    local g = GetSelectedGroup()
                    return HideIfNoGroup() or collapsedSections.grid or not (g and g.autoReflow)
                end,
                values = function()
                    local g = GetSelectedGroup()
                    if not g then return {} end
                    
                    local rows = g.layout.gridRows or 1
                    local cols = g.layout.gridCols or 1
                    local gridShape = ns.CDMGroups.DetectGridShape(rows, cols)
                    
                    if gridShape == "horizontal" then
                        return { left = "Left", center = "Center", right = "Right" }
                    elseif gridShape == "vertical" then
                        return { top = "Top", center = "Center", bottom = "Bottom" }
                    else -- multi
                        return { top = "Top", bottom = "Bottom", left = "Left", right = "Right", center_h = "Center Horizontal", center_v = "Center Vertical" }
                    end
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if not g then return "center" end
                    
                    local rows = g.layout.gridRows or 1
                    local cols = g.layout.gridCols or 1
                    local gridShape = ns.CDMGroups.DetectGridShape(rows, cols)
                    
                    local alignment = g.layout.alignment
                    if not alignment then
                        return ns.CDMGroups.GetDefaultAlignment(gridShape)
                    end
                    
                    -- Validate: check if stored value is valid for current shape
                    local validValues
                    if gridShape == "horizontal" then
                        validValues = { left = true, center = true, right = true }
                    elseif gridShape == "vertical" then
                        validValues = { top = true, center = true, bottom = true }
                    else
                        validValues = { top = true, bottom = true, left = true, right = true, center_h = true, center_v = true }
                    end
                    
                    if validValues[alignment] then
                        return alignment
                    end
                    
                    -- Stale value - infer old shape from the alignment value
                    local horizOnly = { left = true, right = true }
                    local vertOnly  = { top = true, bottom = true }
                    local multiOnly = { center_h = true, center_v = true }
                    local oldShape
                    if multiOnly[alignment] then oldShape = "multi"
                    elseif vertOnly[alignment] then oldShape = "vertical"
                    else oldShape = "horizontal"
                    end
                    
                    local mapped = RemapAlignmentForShape(oldShape, gridShape, alignment)
                    local newAlignment = mapped or ns.CDMGroups.GetDefaultAlignment(gridShape)
                    
                    g.layout.alignment = newAlignment
                    local db = g.getDB and g.getDB()
                    if db then db.alignment = newAlignment end
                    
                    return newAlignment
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        g.layout.alignment = val
                        -- Save to DB (flat structure - db.alignment, NOT db.layout.alignment)
                        local db = g.getDB and g.getDB()
                        if db then
                            db.alignment = val
                        end
                        -- Trigger layout to reposition icons with new alignment
                        if g.autoReflow and g.ReflowIcons then 
                            g:ReflowIcons() 
                        elseif g.Layout then 
                            g:Layout() 
                        end
                        -- Trigger auto-save to linked template
                        if ns.CDMGroups.TriggerTemplateAutoSave then
                            ns.CDMGroups.TriggerTemplateAutoSave()
                        end
                    end
                end,
            },
            dynamicLayout = {
                type = "toggle",
                name = "Dynamic Auras",
                desc = "When enabled, aura icons without an active buff/debuff/totem don't occupy space in the group. The remaining icons (cooldowns + active auras) compact together. Only affects aura icons - cooldowns always take space. Requires Dynamic Layout enabled.",
                order = 36.7,
                width = 0.7,
                hidden = function() 
                    local g = GetSelectedGroup()
                    return HideIfNoGroup() or collapsedSections.grid or not (g and g.autoReflow)
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if not g then return false end
                    return g.dynamicLayout == true
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        -- Helper to actually enable/disable Dynamic Auras
                        local function ApplyDynamicAuras(enabled)
                            -- CRITICAL FIX: When enabling Dynamic Auras, ensure alignment is saved
                            if enabled and not g.layout.alignment then
                                local rows = g.layout.gridRows or 1
                                local cols = g.layout.gridCols or 1
                                local gridShape = ns.CDMGroups.DetectGridShape and ns.CDMGroups.DetectGridShape(rows, cols) or "horizontal"
                                local defaultAlignment = ns.CDMGroups.GetDefaultAlignment and ns.CDMGroups.GetDefaultAlignment(gridShape) or "center"
                                g.layout.alignment = defaultAlignment
                                local db = g.getDB and g.getDB()
                                if db then
                                    db.alignment = defaultAlignment
                                end
                            end
                            
                            -- Use DynamicLayout module to set (handles tracking state)
                            if ns.CDMGroups.DynamicLayout and ns.CDMGroups.DynamicLayout.SetEnabled then
                                ns.CDMGroups.DynamicLayout.SetEnabled(g, enabled)
                            else
                                g.dynamicLayout = enabled
                            end
                            -- Save to DB
                            local db = g.getDB and g.getDB()
                            if db then
                                db.dynamicLayout = enabled
                            end
                            
                            -- Trigger auto-save to linked template
                            if ns.CDMGroups.TriggerTemplateAutoSave then
                                ns.CDMGroups.TriggerTemplateAutoSave()
                            end
                            
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then AceConfigRegistry:NotifyChange("ArcUI") end
                        end
                        
                        if val then
                            -- Enabling: Check if global aura "missing" alpha is > 0
                            local auraCfg = ns.CDMEnhance and ns.CDMEnhance.GetGlobalSettings and ns.CDMEnhance.GetGlobalSettings("aura")
                            local currentAlpha = 1.0
                            if auraCfg and auraCfg.cooldownStateVisuals and auraCfg.cooldownStateVisuals.cooldownState then
                                currentAlpha = auraCfg.cooldownStateVisuals.cooldownState.alpha or 1.0
                            end
                            
                            if currentAlpha > 0 then
                                -- Show confirmation popup
                                StaticPopupDialogs["ARCUI_DYNAMIC_AURAS_ALPHA"] = {
                                    text = "Dynamic Auras works best when inactive aura icons are fully hidden.\n\nSet global |cff00ff00Aura Missing Alpha|r to |cffff80000|r?\n\n(You can change this later in CDM Enhancement > Aura Defaults > Aura Missing)",
                                    button1 = "Yes, Set to 0",
                                    button2 = "No, Keep Current",
                                    OnAccept = function()
                                        -- Set global aura missing alpha to 0
                                        if auraCfg then
                                            if not auraCfg.cooldownStateVisuals then auraCfg.cooldownStateVisuals = {} end
                                            if not auraCfg.cooldownStateVisuals.cooldownState then auraCfg.cooldownStateVisuals.cooldownState = {} end
                                            auraCfg.cooldownStateVisuals.cooldownState.alpha = 0
                                            -- Refresh all aura icons
                                            if ns.CDMEnhance and ns.CDMEnhance.RefreshIconType then
                                                ns.CDMEnhance.RefreshIconType("aura")
                                            end
                                        end
                                        ApplyDynamicAuras(true)
                                    end,
                                    OnCancel = function()
                                        -- Enable Dynamic Auras without changing alpha
                                        ApplyDynamicAuras(true)
                                    end,
                                    timeout = 0, whileDead = true, hideOnEscape = false, preferredIndex = 3,
                                }
                                StaticPopup_Show("ARCUI_DYNAMIC_AURAS_ALPHA")
                            else
                                -- Alpha already 0, just enable
                                ApplyDynamicAuras(true)
                            end
                        else
                            -- Disabling: just turn it off
                            ApplyDynamicAuras(false)
                        end
                    end
                end,
            },
            
            -- LAYOUT SETTINGS SECTION
            layoutHeader = {
                type = "toggle",
                name = "Layout Settings",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 40,
                width = "full",
                get = function() return not collapsedSections.layout end,
                set = function(_, v) collapsedSections.layout = not v end,
            },
            fineTuningLayout = {
                type = "toggle",
                name = "Fine Tuning",
                desc = "Switch to direct input boxes for pixel-precise width, height, and spacing values.",
                order = 40.5,
                width = 0.75,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout end,
                get = function()
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    return db and db.fineTuningLayout
                end,
                set = function(_, val)
                    local db = ns.CDMShared and ns.CDMShared.GetCDMGroupsDB and ns.CDMShared.GetCDMGroupsDB()
                    if db then db.fineTuningLayout = val end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("ArcUI")
                end,
            },
            iconSize = {
                type = "range",
                name = "Scale",
                desc = "Scale factor for icons (36 = 100%)",
                order = 41,
                min = 16, max = 128, step = 1,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.iconSize or 36
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetIconSize(val) end
                end,
            },
            iconSizeInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "Scale",
                desc = "Scale factor for icons (type exact value)",
                order = 41,
                width = 0.4,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return tostring(g and g.layout.iconSize or 36)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetIconSize(num) end
                end,
            },
            iconWidth = {
                type = "range",
                name = "Width",
                desc = "Base icon width in pixels (before scaling)",
                order = 41.1,
                min = 8, max = 128, step = 1,
                width = 0.55,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.iconWidth or 36
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetIconWidth(val) end
                end,
            },
            iconWidthInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "Width",
                desc = "Base icon width in pixels (type exact value)",
                order = 41.1,
                width = 0.4,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return tostring(g and g.layout.iconWidth or 36)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetIconWidth(num) end
                end,
            },
            iconHeight = {
                type = "range",
                name = "Height",
                desc = "Base icon height in pixels (before scaling)",
                order = 41.2,
                min = 8, max = 128, step = 1,
                width = 0.55,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.iconHeight or 36
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetIconHeight(val) end
                end,
            },
            iconHeightInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "Height",
                desc = "Base icon height in pixels (type exact value)",
                order = 41.2,
                width = 0.4,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() end,
                get = function()
                    local g = GetSelectedGroup()
                    return tostring(g and g.layout.iconHeight or 36)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetIconHeight(num) end
                end,
            },
            spacing = {
                type = "range",
                name = "Spacing",
                desc = "Space between icons (both X and Y)",
                order = 42,
                min = -20, max = 50, step = 0.5,
                width = 0.8,
                hidden = function() 
                    if HideIfNoGroup() or collapsedSections.layout or IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return g and g.layout.separateSpacing
                end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.spacing or 2
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetSpacing(val) end
                end,
            },
            spacingInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "Spacing",
                desc = "Space between icons (type exact value)",
                order = 42,
                width = 0.4,
                hidden = function()
                    if HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return g and g.layout.separateSpacing
                end,
                get = function()
                    local g = GetSelectedGroup()
                    return tostring(g and g.layout.spacing or 2)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetSpacing(num) end
                end,
            },
            separateSpacing = {
                type = "toggle",
                name = "X/Y",
                desc = "Enable separate X and Y spacing controls",
                order = 42.1,
                width = 0.35,
                hidden = function() return HideIfNoGroup() or collapsedSections.layout end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.layout.separateSpacing
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        g.layout.separateSpacing = val
                        -- Save to profile.groupLayouts (single source of truth)
                        if ns.CDMGroups.SaveGroupLayoutToProfile then
                            ns.CDMGroups.SaveGroupLayoutToProfile(g.name, g)
                        end
                        -- If enabling, initialize X/Y from current spacing
                        if val and not g.layout.spacingX then
                            g:SetSpacingX(g.layout.spacing or 2)
                            g:SetSpacingY(g.layout.spacing or 2)
                        end
                    end
                end,
            },
            spacingX = {
                type = "range",
                name = "X Spacing",
                desc = "Horizontal space between columns",
                order = 42.5,
                min = -20, max = 50, step = 0.5,
                width = 0.7,
                hidden = function() 
                    if HideIfNoGroup() or collapsedSections.layout or IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return not (g and g.layout.separateSpacing)
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.layout.spacingX then
                        return g.layout.spacingX
                    end
                    return g and g.layout.spacing or 2
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetSpacingX(val) end
                end,
            },
            spacingXInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "X Spacing",
                desc = "Horizontal space between columns (type exact value)",
                order = 42.5,
                width = 0.4,
                hidden = function()
                    if HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return not (g and g.layout.separateSpacing)
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.layout.spacingX then
                        return tostring(g.layout.spacingX)
                    end
                    return tostring(g and g.layout.spacing or 2)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetSpacingX(num) end
                end,
            },
            spacingY = {
                type = "range",
                name = "Y Spacing",
                desc = "Vertical space between rows",
                order = 42.6,
                min = -20, max = 50, step = 0.5,
                width = 0.7,
                hidden = function() 
                    if HideIfNoGroup() or collapsedSections.layout or IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return not (g and g.layout.separateSpacing)
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.layout.spacingY then
                        return g.layout.spacingY
                    end
                    return g and g.layout.spacing or 2
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetSpacingY(val) end
                end,
            },
            spacingYInput = {
                type = "input",
                dialogControl = "ArcUI_EditBox",
                name = "Y Spacing",
                desc = "Vertical space between rows (type exact value)",
                order = 42.6,
                width = 0.4,
                hidden = function()
                    if HideIfNoGroup() or collapsedSections.layout or not IsFineTuning() then return true end
                    local g = GetSelectedGroup()
                    return not (g and g.layout.separateSpacing)
                end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.layout.spacingY then
                        return tostring(g.layout.spacingY)
                    end
                    return tostring(g and g.layout.spacing or 2)
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    local num = tonumber(val)
                    if g and num then g:SetSpacingY(num) end
                end,
            },
            
            -- POSITION SETTINGS SECTION
            positionHeader = {
                type = "toggle",
                name = "Position",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 50,
                width = "full",
                get = function() return not collapsedSections.position end,
                set = function(_, v) collapsedSections.position = not v end,
            },
            posX = {
                type = "input",
                name = "X Offset",
                desc = "Horizontal position from screen center",
                dialogControl = "ArcUI_EditBox",
                order = 51,
                width = 0.6,
                hidden = function() return HideIfNoGroup() or collapsedSections.position end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and tostring(g.position.x) or "0"
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then 
                        local num = tonumber(val)
                        if num then
                            g:SetPosition(num, g.position.y) 
                        end
                    end
                end,
            },
            posY = {
                type = "input",
                name = "Y Offset",
                desc = "Vertical position from screen center",
                dialogControl = "ArcUI_EditBox",
                order = 52,
                width = 0.6,
                hidden = function() return HideIfNoGroup() or collapsedSections.position end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and tostring(g.position.y) or "0"
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then 
                        local num = tonumber(val)
                        if num then
                            g:SetPosition(g.position.x, num) 
                        end
                    end
                end,
            },
            dragToggleAnchor = {
                type = "select",
                name = "Drag Handle",
                desc = "Position of the drag handle button relative to the group",
                order = 53,
                width = 0.9,
                hidden = function() return HideIfNoGroup() or collapsedSections.position end,
                values = {
                    ["TOPLEFT"] = "Top Left",
                    ["TOPRIGHT"] = "Top Right",
                    ["BOTTOMLEFT"] = "Bottom Left",
                    ["BOTTOMRIGHT"] = "Bottom Right",
                },
                get = function()
                    local g = GetSelectedGroup()
                    if g then
                        local db = ns.CDMGroups.GetGroupDB and ns.CDMGroups.GetGroupDB(g.name)
                        return db and db.dragToggleAnchor or "TOPLEFT"
                    end
                    return "TOPLEFT"
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then
                        local db = ns.CDMGroups.GetGroupDB and ns.CDMGroups.GetGroupDB(g.name)
                        if db then db.dragToggleAnchor = val end
                        -- Update the drag toggle position
                        if g.UpdateDragToggleAnchor then
                            g:UpdateDragToggleAnchor(val)
                        end
                    end
                end,
            },
            
            -- APPEARANCE SETTINGS SECTION
            appearanceHeader = {
                type = "toggle",
                name = "Appearance",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 60,
                width = "full",
                get = function() return not collapsedSections.appearance end,
                set = function(_, v) collapsedSections.appearance = not v end,
            },
            showBorder = {
                type = "toggle",
                name = "Border",
                desc = "Show container border (always visible in edit mode)",
                order = 61,
                width = 0.5,
                hidden = function() return HideIfNoGroup() or collapsedSections.appearance end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.showBorder
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetShowBorder(val) end
                end,
            },
            showBackground = {
                type = "toggle",
                name = "Background",
                desc = "Show container background (always visible in edit mode)",
                order = 62,
                width = 0.6,
                hidden = function() return HideIfNoGroup() or collapsedSections.appearance end,
                get = function()
                    local g = GetSelectedGroup()
                    return g and g.showBackground
                end,
                set = function(_, val)
                    local g = GetSelectedGroup()
                    if g then g:SetShowBackground(val) end
                end,
            },
            borderColor = {
                type = "color",
                name = "Border Color",
                desc = "Color of the container border and title",
                order = 63,
                hasAlpha = true,
                width = 0.6,
                hidden = function() return HideIfNoGroup() or collapsedSections.appearance end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.borderColor then
                        return g.borderColor.r, g.borderColor.g, g.borderColor.b, g.borderColor.a or 1
                    end
                    return 0.5, 0.5, 0.5, 1
                end,
                set = function(_, r, g, b, a)
                    local grp = GetSelectedGroup()
                    if grp then grp:SetBorderColor(r, g, b, a) end
                end,
            },
            bgColor = {
                type = "color",
                name = "BG Color",
                desc = "Color of the container background",
                order = 64,
                hasAlpha = true,
                width = 0.55,
                hidden = function() return HideIfNoGroup() or collapsedSections.appearance end,
                get = function()
                    local g = GetSelectedGroup()
                    if g and g.bgColor then
                        return g.bgColor.r, g.bgColor.g, g.bgColor.b, g.bgColor.a or 0.6
                    end
                    return 0, 0, 0, 0.6
                end,
                set = function(_, r, g, b, a)
                    local grp = GetSelectedGroup()
                    if grp then grp:SetBgColor(r, g, b, a) end
                end,
            },
            visibility = {
                type = "multiselect",
                name = "Hide When...",
                desc = "Select conditions that will HIDE this group.\nIf none selected, group is always visible.\nNote: Groups are always shown when editing or options panel is open.",
                order = 65,
                width = "full",
                hidden = function() return HideIfNoGroup() or collapsedSections.appearance end,
                values = {
                    ["hideOOC"] = "Out of Combat",
                    ["hideInCombat"] = "In Combat",
                    ["hideMounted"] = "Mounted",
                    ["hideAlways"] = "Always (Disabled)",
                },
                get = function(_, key)
                    local g = GetSelectedGroup()
                    if not g then return false end
                    
                    -- Handle backwards compatibility with old string format
                    local vis = g.visibility
                    if type(vis) == "string" then
                        -- Convert old format to new for display purposes
                        if vis == "combat" then
                            return key == "hideOOC"  -- "In Combat Only" = hide when OOC
                        elseif vis == "ooc" then
                            return key == "hideInCombat"  -- "Out of Combat Only" = hide when in combat
                        elseif vis == "never" then
                            return key == "hideAlways"
                        else
                            return false  -- "always" = nothing selected
                        end
                    elseif type(vis) == "table" then
                        return vis[key] or false
                    end
                    return false
                end,
                set = function(_, key, val)
                    local g = GetSelectedGroup()
                    if g then
                        -- Convert to table format if still using old string
                        if type(g.visibility) ~= "table" then
                            local oldVis = g.visibility
                            g.visibility = {}
                            -- Migrate old value
                            if oldVis == "combat" then
                                g.visibility.hideOOC = true
                            elseif oldVis == "ooc" then
                                g.visibility.hideInCombat = true
                            elseif oldVis == "never" then
                                g.visibility.hideAlways = true
                            end
                        end
                        
                        -- Set the new value
                        g.visibility[key] = val or nil  -- Use nil instead of false to keep table clean
                        
                        -- If hideAlways is set, clear other options (they're redundant)
                        if key == "hideAlways" and val then
                            g.visibility.hideOOC = nil
                            g.visibility.hideInCombat = nil
                            g.visibility.hideMounted = nil
                        elseif val and g.visibility.hideAlways then
                            -- If setting another option, clear hideAlways
                            g.visibility.hideAlways = nil
                        end
                        
                        -- Save to profile.groupLayouts (single source of truth)
                        if ns.CDMGroups.SaveGroupLayoutToProfile then
                            ns.CDMGroups.SaveGroupLayoutToProfile(g.name, g)
                        end
                        -- Update visibility immediately
                        if ns.CDMGroups.UpdateGroupVisibility then
                            ns.CDMGroups.UpdateGroupVisibility()
                        end
                        -- Trigger auto-save to linked template
                        if ns.CDMGroups.TriggerTemplateAutoSave then
                            ns.CDMGroups.TriggerTemplateAutoSave()
                        end
                    end
                end,
            },
            
            -- TOOLS SECTION
            toolsHeader = {
                type = "toggle",
                name = "Tools",
                desc = "Click to expand/collapse",
                dialogControl = "CollapsibleHeader",
                order = 70,
                width = "full",
                get = function() return not collapsedSections.tools end,
                set = function(_, v) collapsedSections.tools = not v end,
            },
            reflowBtn = {
                type = "execute",
                name = "Reflow Icons",
                desc = "Redistribute icons to fill grid sequentially (removes gaps)",
                order = 71,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.tools end,
                func = function()
                    local g = GetSelectedGroup()
                    if g then g:ReflowIcons() end
                end,
            },
            cleanupBtn = {
                type = "execute",
                name = "Cleanup Empty",
                desc = "Remove empty trailing rows and columns",
                order = 72,
                width = 0.7,
                hidden = function() return HideIfNoGroup() or collapsedSections.tools end,
                func = function()
                    local g = GetSelectedGroup()
                    if g then
                        g:CleanupEmptyRowsCols()
                        g:Layout()
                    end
                end,
            },
        },
    }
    
    return options
end


-- ===================================================================
-- EXPORT FOR ARCUI OPTIONS
-- ===================================================================
function ns.GetCDMGroupsOptionsTable()
    return GetOptionsTable()
end

-- ===================================================================
-- END OF ArcUI_CDMGroupsOptions.lua
-- ===================================================================