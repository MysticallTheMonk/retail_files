local _, ArenaAnalytics = ...; -- Addon Namespace
local Dropdown = ArenaAnalytics.Dropdown;

-- Setup local subclass
local List = Dropdown.List;
List.__index = List;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local TablePool = ArenaAnalytics.TablePool;
local Options = ArenaAnalytics.Options;

-------------------------------------------------------------------------

List.verticalPadding = 5;
List.horizontalPadding = 3;
List.maxVisibleEntries = 10;

function List:Create(parent, level, listInfo)
    assert(listInfo ~= nil, "Assertion failed: Invalid list info.");

    local self = setmetatable({}, List);

    self.name = (parent.name .. "List");
    self.parent = parent;
    self.level = level;

    -- nil width calculates desired width dynamically
    self.explicitWidth = listInfo.width or nil; 

    self.entryHeight = listInfo.entryHeight or listInfo.height or 20;

    local maxVisibleEntries = (listInfo.maxVisibleEntries or List.maxVisibleEntries);
    self.maxHeight = 10 + self.entryHeight * maxVisibleEntries + List.verticalPadding * 2;

    self.listInfo = listInfo;

    self.backdrop = Helpers:CreateDoubleBackdrop(parent:GetOwner(), self.name, "DIALOG");

    -- Setup scroll frame, in case we got too many entries to show
    self.scrollFrame = CreateFrame("scrollFrame", self.name .. "_ScrollFrame", self.backdrop, "UIPanelScrollFrameTemplate");
    self.scrollFrame:SetPoint("TOP", self.backdrop, "TOP", 0, -5);
    self.scrollFrame:SetSize(1, 1);
    self.scrollFrame:SetClipsChildren(true);
    self.scrollFrame.scrollBarHideable = true;

    -- Content frame
    self.scrollFrame.content = CreateFrame("Frame", self.name .. "_Content", self.scrollFrame);
    self.scrollFrame.content:SetPoint("TOP", self.scrollFrame);
    self.scrollFrame.content:SetSize(1, 1);

    -- Assign the scroll child
    self.scrollFrame:SetScrollChild(self.scrollFrame.content);

    self.scrollFrame:SetScript("OnScrollRangeChanged", function(scrollFrame)
        self:UpdateScrollbarMinMax();
    end);

    self.backdrop:SetScript("OnEnter", function()   end); -- Catch mouseover

    self.entryFrames = {}
    self:Refresh();

    self:Hide();

    return self;
end

function List:Refresh()
    -- Get most recent entries list, in case of a dynamic function
    local entries = Dropdown:RetrieveValue(self.listInfo, self);
    assert(entries, "Assert failed: Nil entries for type: " .. type(self.entries) .. " on dropdown list: " .. self:GetName());

    -- Clear old entries
    for i=#self.entryFrames, 1, -1 do
        if(self.entryFrames[i]) then
            self.entryFrames[i]:Hide();
            self.entryFrames[i] = nil;
        end
    end
    
    self.entryFrames = TablePool:Acquire();

    -- Add new entries
    self:AddEntries(entries);
    
    Dropdown:AddActiveDropdown(self.level, self);
    
    self:SetupScrollbar();
    self.scrollFrame:UpdateScrollChildRect(); -- Ensure the scroll child rect is updated
end

function List:AddEntries(entries)
    assert(entries, "Assert failed: Nil entries.");

    local width = self.explicitWidth or self:GetWidth();

    local accumulatedHeight = List.verticalPadding * 2;
    local longestEntryWidth = width; -- Cannot be smaller than explicit width
    local lastFrame = nil;

    for i, entry in ipairs(entries) do 
        local entryFrame = Dropdown.EntryFrame:Create(self, i, self.explicitWidth, self.entryHeight, entry);

        if(not lastFrame) then
            entryFrame:SetPoint("TOP", self.scrollFrame.content, "TOP", 0, -List.verticalPadding);
        else
            entryFrame:SetPoint("TOP", lastFrame, "BOTTOM");
        end

        if(longestEntryWidth < entryFrame:GetWidth()) then
            longestEntryWidth = entryFrame:GetWidth();
        end

        accumulatedHeight = Round(accumulatedHeight + entryFrame:GetHeight());
        
        lastFrame = entryFrame:GetFrame();
        table.insert(self.entryFrames, entryFrame);
    end

    local desiredBuffer = (self.explicitWidth ~= nil) and 0 or 15;
    local desiredWidth = ceil(max(width, longestEntryWidth)) + desiredBuffer;

    for _,entry in ipairs(self.entryFrames) do
        entry:SetWidth(desiredWidth);
    end

    self.scrollFrame.content:SetHeight(accumulatedHeight);

    self:SetSize(desiredWidth, accumulatedHeight + 10);
end

function List:SetupScrollbar()
    local scrollbar = self.scrollFrame.ScrollBar;
    scrollbar:ClearAllPoints();
    scrollbar:SetPoint("TOPLEFT", self.scrollFrame, "TOPRIGHT", -3, 3);
    scrollbar:SetPoint("BOTTOMLEFT", self.scrollFrame, "BOTTOMRIGHT", -3, -4);
    scrollbar.scrollStep = self.entryHeight * (Options:Get("dropdownScrollStep") or 1);

    local viewHeight = self.scrollFrame:GetHeight()
    local contentHeight = self.scrollFrame.content:GetHeight();
    
    -- Workaround for scrollbar not hiding automatically
    if ((viewHeight + 0.01) < contentHeight) then
        scrollbar:SetAlpha(1);
    else
        scrollbar:SetAlpha(0);
    end

    -- Hide the scroll up and down buttons
    if scrollbar.ScrollUpButton then
        scrollbar.ScrollUpButton:Hide();
        scrollbar.ScrollUpButton:SetAlpha(0);
    end
    if scrollbar.ScrollDownButton then
        scrollbar.ScrollDownButton:Hide();
        scrollbar.ScrollDownButton:SetAlpha(0);
    end

    self:UpdateScrollbarMinMax();
end

function List:UpdateScrollbarMinMax()
    local viewHeight = self.scrollFrame:GetHeight();
    local contentHeight = self.scrollFrame.content:GetHeight();
    local maxScroll = math.max(contentHeight - viewHeight, 0);
    
    self.scrollFrame:UpdateScrollChildRect();
    self.scrollFrame.ScrollBar:SetMinMaxValues(0, maxScroll);
end

function List:SetBackdropAlpha(alpha)
    local bgColor = self.backdrop.backdropColor or TOOLTIP_DEFAULT_BACKGROUND_COLOR;
	local bgR, bgG, bgB = bgColor:GetRGB();
	
    alpha = alpha or 1;
	self.backdrop:SetBackdropColor(bgR, bgG, bgB, alpha);
end

---------------------------------
-- Simple getters
---------------------------------

function List:GetOwner()
    return self.parent:GetOwner();
end

function List:GetSelectedFrame()
    return self.parent:GetSelectedFrame();
end

function List:GetFrame()
    return self.scrollFrame.content;
end

function List:GetName()
    return self.name;
end

function List:GetDropdownType()
    return self.parent:GetDropdownType();
end

---------------------------------
-- Points
---------------------------------

function List:GetPoint()
    local point, parent, relativePoint, x, y = self.backdrop:GetPoint();
    if(parent ~= nil) then
        parent = parent:GetName();
    end
    return point, parent, relativePoint, x, y;
end

function List:SetPoint(...)
    return self.backdrop:SetPoint(...);
end

function List:GetSize()
    return self.backdrop:GetSize();
end

function List:SetSize(width, height)
    self.backdrop:SetSize(width+5, min(height, self.maxHeight));
    self.scrollFrame:SetSize(self.backdrop:GetWidth() - List.horizontalPadding*2, self.backdrop:GetHeight()-10);
    self.scrollFrame.content:SetWidth(self.scrollFrame:GetWidth());
end

function List:GetWidth()
    return self.backdrop:GetWidth();
end

---------------------------------
-- Visibility
---------------------------------

function List:IsShown()
    return self.backdrop:IsShown();
end

function List:Toggle()
    if(self:IsShown()) then
        self:Hide();
    else
        self:Show();
    end
end

function List:Show()
    Dropdown:HideActiveDropdownsFromLevel(self.level+1, true);
    self.backdrop:Show();
end

function List:Hide()
    Dropdown:HideActiveDropdownsFromLevel(self.level+1, true);
    self.backdrop:Hide();
    self = nil;
end

-- TODO: Test this.
function List:IsMouseOver()
    return self.backdrop:IsMouseOver(5,-5,-5,5);
end
