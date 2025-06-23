local _, ArenaAnalytics = ...; -- Addon Namespace
local Dropdown = ArenaAnalytics.Dropdown;

-- Setup local subclass
local Display = Dropdown.Display;
Display.__index = Display

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local ArenaIcon = ArenaAnalytics.ArenaIcon;
local TablePool = ArenaAnalytics.TablePool;
local GroupSorter = ArenaAnalytics.GroupSorter;

-------------------------------------------------------------------------

function Display:Create(parent, displayFunc)
    assert(parent);
    assert(parent.GetCheckboxWidth, "Dropdown Display parent must include GetCheckboxWidth()!");
    assert(parent.GetArrowWidth, "Dropdown Display parent must include GetArrowWidth()!");
    assert(not displayFunc or type(displayFunc) == "function");
    
    local self = setmetatable({}, Display);

    self.parent = parent;
    self.name = parent:GetName() .. "_Display";
    
    self.displayFunc = displayFunc;
    self.frames = {}

    self.padding = 0;
    
    return self;
end

function Display:Refresh()
    self:Reset();

    if(self.parent:IsDisabled()) then
        Display.SetDisabledText(self.parent, self)
    elseif(self.displayFunc) then
        self.displayFunc(self.parent, self);
    else
        Display.SetText(self.parent, self)
    end
end

function Display:SetDisplayFunc(displayFunc, skipRefresh)
    self.displayFunc = displayFunc;

    if(not skipRefresh) then
        self:Refresh();
    end
end

function Display:AddFrame(frame, alignment, offsetX)
    if(self.frames == nil) then
        self.frames = {};
    end

    assert(frame);

    alignment = alignment or self.parent.alignment or "CENTER";
    offsetX = tonumber(offsetX) or 0;

    if(alignment == "LEFT") then
        offsetX = offsetX + self.parent:GetCheckboxWidth();
    elseif(Alignment == "RIGHT") then
        offsetX = offsetX - self.parent:GetArrowWidth()
    end

    frame:SetParent(self.parent:GetFrame());
    frame:SetPoint(alignment, self.parent:GetFrame(), offsetX, -1);
    frame:Show();

    tinsert(self.frames, frame);
end

function Display:Reset()
    if(self.frames) then
        for i=#self.frames, 1, -1 do
            local frame = self.frames[i];
            if(frame) then
                frame:Hide();
                self.frames[i] = nil;
            end
        end
    end
    self.frames = {};
end

function Display:SetPadding(padding)
    self.padding = padding;
end

function Display:GetName()
    return self.name;
end

function Display:GetWidth()
    local width = self.padding;

    for _,frame in ipairs(self.frames) do
        width = width + frame:GetWidth();
    end

    return width;
end

-------------------------------------------------------------------------
-- Helpers

local function CreateText(parent, text, size, color)
    color = color or "ffffff";
    size = size or 12;
    text = text or "";

    local fontString = parent:CreateFontString(nil, "OVERLAY");
    fontString:SetFont("Fonts\\FRIZQT__.TTF", size, "");
    fontString:SetText("|cff" .. color .. text .. "|r");
    return fontString;
end


-------------------------------------------------------------------------
-- Disabled Text Display

function Display.SetDisabledText(dropdownContext, display)
    assert(dropdownContext and display);
    display:Reset();

    local label = Dropdown:RetrieveValue(dropdownContext.disabledText, dropdownContext);
    local fontSize = dropdownContext.disabledSize or dropdownContext.fontSize or 10;
    local fontColor = dropdownContext.disabledColor or "888888";

    local fontString = CreateText(dropdownContext:GetFrame(), label, fontSize, fontColor);

    local offsetX = dropdownContext.offsetX or 0;
    display:AddFrame(fontString, dropdownContext.alignment, offsetX);
end


-------------------------------------------------------------------------
-- Simple Text Display

function Display.SetText(dropdownContext, display)
    assert(dropdownContext and display);
    display:Reset();

    local label = Dropdown:RetrieveValue(dropdownContext.label, dropdownContext);
    local fontSize = dropdownContext.fontSize or 12;
    local fontColor = dropdownContext.fontColor or "ffffff";

    local fontString = CreateText(dropdownContext:GetFrame(), label, fontSize, fontColor);

    local alignment = dropdownContext.alignment or "CENTER";
    local offsetX = dropdownContext.offsetX or 0;

    display:AddFrame(fontString, dropdownContext.alignment, offsetX);
end


-------------------------------------------------------------------------
-- Comp Display Function

function Display.SetComp(dropdownContext, display)
    assert(dropdownContext and display);
    display:Reset();

    local comp = Dropdown:RetrieveValue(dropdownContext.label, dropdownContext);
    local fontSize = dropdownContext.fontSize or 12;
    local fontColor = dropdownContext.disabledColor or "ffffff";

    local padding = 1;

    -- Create container
    local containerFrame = CreateFrame("Frame", display:GetName() .. "CompContainer", dropdownContext:GetFrame());
    containerFrame:SetSize(10, 27);

    local totalWidth = 0;
    local offsetX = dropdownContext.offsetX or 0;

    local compData = ArenaAnalytics:GetCurrentCompData(dropdownContext.key, comp) or {}

    -- Construct the container contents
    if(comp == "All") then
        containerFrame.text = CreateText(containerFrame, comp, fontSize, fontColor);
        containerFrame.text:SetPoint("LEFT", 0, 0);
        
        local width = containerFrame.text:GetWidth();
        totalWidth = totalWidth + width;
    else
        -- Get data
        local played = tonumber(compData.played);
        local winrate = tonumber(compData.winrate);

        if(played and played > 9999) then
            fontSize = min(fontSize, 10);
        end

        local lastFrame = nil

        -- Add played text
        local playedPrefix = played and (played .. " ") or "|cffff0000" .. "0  " .. "|r";
        containerFrame.played = CreateText(containerFrame, playedPrefix, fontSize, fontColor);
        containerFrame.played:SetPoint("LEFT", padding, 0);

        lastFrame = containerFrame.played;
        totalWidth = totalWidth + containerFrame.played:GetWidth() + padding;

        local specs = TablePool:Acquire();

        -- Add each player spec icon
        for spec_id in comp:gmatch("([^|]+)") do
            if(tonumber(spec_id)) then
                tinsert(specs, tonumber(spec_id));
            end
        end

        local playerInfo = ArenaAnalytics:GetLocalPlayerInfo();
        GroupSorter:SortSpecs(specs, playerInfo);

        -- Display specs
        for i,spec_id in ipairs(specs) do
            local iconFrame = ArenaIcon:Create(containerFrame, 25, true);
            iconFrame:SetPoint("LEFT", lastFrame, "RIGHT", padding, 0);
            iconFrame:SetSpec(spec_id);

            lastFrame = iconFrame;
            totalWidth = totalWidth + iconFrame:GetWidth() + padding;
        end

        -- Add winrate text
        local winrateSuffix = winrate and (" " .. winrate .. "%") or "|cffff0000" .. "  0%" .. "|r";
        containerFrame.winrate = CreateText(containerFrame, winrateSuffix, fontSize, fontColor);
        containerFrame.winrate:SetPoint("LEFT", lastFrame, "RIGHT", padding, 0);

        lastFrame = containerFrame.winrate;
        totalWidth = totalWidth + containerFrame.winrate:GetWidth() + padding;
        
        -- Calculate alignment offset
        local prefixWidth = containerFrame.played:GetWidth();
        local suffixWidth = containerFrame.winrate:GetWidth();
        offsetX = offsetX + (suffixWidth - prefixWidth) / 2;
    end

    -- Average MMR
    if(Options:Get("compDisplayAverageMmr")) then        
        local mmr = tonumber(compData.mmr);
        if(mmr) then
            --local mmrText = ArenaAnalyticsCreateText(dropdownContext:GetFrame(), "RIGHT", dropdownContext:GetFrame(), "RIGHT", -5, 0, averageMMR, 8);
            local mmrText = CreateText(dropdownContext:GetFrame(), mmr, 8, "cccccc");
            display:AddFrame(mmrText, "RIGHT", -7);
        end

        -- Move off center to make room for mmr
        totalWidth = totalWidth + 5;
    end

    containerFrame:SetWidth(totalWidth);

    display:AddFrame(containerFrame, "CENTER", offsetX);
end