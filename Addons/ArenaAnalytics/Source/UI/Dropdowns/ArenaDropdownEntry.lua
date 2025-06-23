local _, ArenaAnalytics = ...; -- Addon Namespace
local Dropdown = ArenaAnalytics.Dropdown;

-- Setup local subclass
local EntryFrame = Dropdown.EntryFrame;
EntryFrame.__index = EntryFrame;

-- Local module aliases
local Display = ArenaAnalytics.Dropdown.Display;

-------------------------------------------------------------------------

---------------------------------
-- Entry Button Core
---------------------------------

local function ValidateConfig(config)
    assert(config);
    assert(config.nested == nil or (type(config.nested) == "table" or type(config.nested) == "function"), "Invalid nested value in config."); -- nil, table or function
    assert(not config.onClick or type(config.onClick) == "function");
end

function EntryFrame:Create(parent, index, width, height, config)
    ValidateConfig(config);
    
    local self = setmetatable({}, EntryFrame);
    self.parent = parent;

    self.name = (parent:GetName() .. "Entry") .. (index and index or "");

    -- Temp for nested list
    self.width = max(1, max(width or 0, parent:GetWidth()) - 5);

    self.height = height;

    -- Config
    self:SetConfig(config);

    -- Initiate display
    self.displayFunc = config.displayFunc;
    self.display = Display:Create(self, self.displayFunc);

    -- Setup button
    self.btn = CreateFrame("Button", self.name, parent:GetFrame());

    -- Font Objects
    self.btn:SetNormalFontObject("GameFontHighlight");
    self.btn:SetHighlightFontObject("GameFontHighlight");
    self.btn:SetDisabledFontObject("GameFontDisableSmall");
    self.btn:SetSize(self.width, height);
    self.btn:SetText("");
    

    -- Create the highlight texture
    self.highlight = self.btn:CreateTexture(nil, "HIGHLIGHT");
    self.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
    self.highlight:SetBlendMode("ADD");
    self.highlight:SetAllPoints(self.btn);
    self.highlight:Hide();
    
    local entryFrame = self;

    self.btn:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    self.btn:SetScript("OnClick", function(frame, button)
        if(self.onClick) then
            self.onClick(self, button);            
        end

        self.parent:Refresh();

        local selectedFrame = self:GetSelectedFrame();
        if(selectedFrame and selectedFrame.Refresh) then
            selectedFrame:Refresh();
        end
    end);

    -- Hover Background
    self.btn:SetScript("OnEnter", function()
        self.highlight:Show();
        self:CreateNestedList();
    end);

    self.btn:SetScript("OnLeave", function()
        self.highlight:Hide();
    end);
    
    self:Refresh();

    return self;
end

function EntryFrame:SetConfig(config)
    self.isTitle = config.isTitle;

    self.label = config.label;
    self.key = config.key;
    self.value = config.value or config.label;
    self.nested = config.nested;
    
    self.disabled = config.disabled;
    self.disabledText = config.disabledText;
    self.disabledColor = config.disabledColor;
    self.disabledSize = config.disabledSize;
    
    self.onClick = config.onClick;
    
    self.checked = config.checked;

    self.alignment = config.alignment;
    self.offsetX = config.offsetX;
    
    self.width = config.width or self.width;
    self.height = config.height or self.height;
    self.fontSize = config.fontSize;
    self.fontColor = config.fontColor;
end

function EntryFrame:CreateNestedList()
    if(self.nested ~= nil) then
        local parent = self.parent;

        local listInfo = Dropdown:RetrieveValue(self.nested, self);
        local newDropdown = Dropdown.List:Create(self, parent.level + 1, listInfo);
        newDropdown:SetPoint("TOPLEFT", self:GetFrame(), "TOPRIGHT", -2.5, 5 + Dropdown.List.verticalPadding);
        newDropdown:Show();
    end
end

function EntryFrame:Refresh()
    if(self:IsDisabled() or self.isTitle) then
        self.btn:Disable();
    else
        self.btn:Enable();
    end

    self:UpdateCheckbox();
    self:UpdateNestedArrow();

    self.display:Refresh();

    local desiredWidth = max(self.width, self:ComputeMinimumWidth());
    self:SetWidth(desiredWidth);
end

function EntryFrame:UpdateCheckbox()
    if(self.checked ~= nil) then
        if(not self.checkbox) then
            self.checkbox = self.btn:CreateTexture(nil, "OVERLAY");
            self.checkbox:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
            self.checkbox:SetPoint("LEFT", self.btn, "LEFT", 5, 0);
            self.checkbox:SetSize(16, 16);
            self.checkbox:Show();
        end

        local isChecked = Dropdown:RetrieveValue(self.checked, self);
        if(isChecked) then
            self.checkbox:SetTexCoord(0, 0.5, 0.5, 1.0);
        else
            self.checkbox:SetTexCoord(0.5, 1.0, 0.5, 1.0);
        end
    else
        self.checkbox = nil;
    end
end

function EntryFrame:UpdateNestedArrow()
    if(self.nested ~= nil) then
        self.arrow = self.btn:CreateTexture(nil, "OVERLAY");
        self.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow");
        self.arrow:SetPoint("RIGHT", self.btn, "RIGHT", -4, 0);
        self.arrow:SetSize(16, 16);
        self.arrow:Show();
    else
        self.arrow = nil;
    end
end

function EntryFrame:ComputeMinimumWidth()
    local minimumWidth = self:GetCheckboxWidth() + self:GetArrowWidth() + 0;

    -- Display Width
    if(self.display) then
        minimumWidth = minimumWidth + self.display:GetWidth();
    end

    minimumWidth = ceil(minimumWidth);

    return minimumWidth;
end

---------------------------------
-- Simple getters
---------------------------------

function EntryFrame:GetOwner()
    return self.parent:GetOwner();
end

function EntryFrame:GetSelectedFrame()
    return self.parent:GetSelectedFrame();
end

function EntryFrame:GetFrame()
    return self.btn;
end

function EntryFrame:GetName()
    return self.name;
end

function EntryFrame:GetDropdownType()
    return self.parent:GetDropdownType();
end

function EntryFrame:IsDisabled()
    if(self.disabled ~= nil) then
        return Dropdown:RetrieveValue(self.disabled, self);
    end
    return false;
end

function EntryFrame:GetDisabledText()
    if(self.disabledText ~= nil) then
        return Dropdown:RetrieveValue(self.disabledText, self);
    end
    return "Disabled";
end    

function EntryFrame:GetCheckboxWidth()
    if(self.checkbox) then
        local offsetX = select(4, self.checkbox:GetPoint());
        return self.checkbox:GetWidth() + abs(offsetX);
    end
    return 0;
end

function EntryFrame:GetArrowWidth()
    if(self.arrow) then        
        local offsetX = select(4, self.arrow:GetPoint());
        return self.arrow:GetWidth() + abs(offsetX);
    end
    return 0;
end

---------------------------------
-- Points
---------------------------------

function EntryFrame:SetPoint(...)
    self.btn:SetPoint(...);
end

function EntryFrame:GetSize()
    return self.btn:GetSize();
end

function EntryFrame:SetSize(width, height)
    self.btn:SetSize(width, height);
end

-- Width
function EntryFrame:GetWidth()
    return self.btn:GetWidth();
end

function EntryFrame:SetWidth(width)
    self.btn:SetWidth(width);
end

-- Height
function EntryFrame:GetHeight()
    return self.btn:GetHeight();
end

function EntryFrame:SetHeight(height)
    self.btn:SetHeight(height);
end

---------------------------------
-- Visibility
---------------------------------

function EntryFrame:IsShown()
    return self.btn:IsShown();
end

function EntryFrame:Show()
    self.btn:Show();
end

function EntryFrame:Hide()
    self.btn:Hide();
end