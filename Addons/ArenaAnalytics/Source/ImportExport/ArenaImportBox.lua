local _, ArenaAnalytics = ...; -- Addon Namespace
local ImportBox = ArenaAnalytics.ImportBox;
ImportBox.__index = ImportBox;

-- Local module aliases
local Import = ArenaAnalytics.Import;
local Debug = ArenaAnalytics.Debug;
local AAtable = ArenaAnalytics.AAtable;

-------------------------------------------------------------------------
-- Import Box

ImportBox.instances = {};

local function AddFrame(frame)
    if(not frame) then
        return;
    end

    for i = #ImportBox.instances, 1, -1 do
        if(frame == ImportBox.instances[i]) then
            return;
        end
    end

    tinsert(ImportBox.instances, frame);
end

local function RemoveFrame(frame)
    if(not frame) then
        return;
    end

    for i = #ImportBox.instances, 1, -1 do
        if(frame == ImportBox.instances[i]) then
            table.remove(ImportBox.instances, i);
            return;
        end
    end
end

-- Static function to enable all ImportBoxes
function ImportBox.EnableAll()
    for _, instance in ipairs(ImportBox.instances) do
        instance.button:Enable();
        instance.editbox:Enable();
    end
end

function ImportBox.DisableAll()
    for _, instance in ipairs(ImportBox.instances) do
        instance.button:Disable();
        instance.editbox:Disable();
    end
end

function ImportBox.ResetAll()
    for _, instance in ipairs(ImportBox.instances) do
        instance.editbox:SetTextSafe("");
        instance.editbox:Enable();
        instance.button:Disable();
    end
end

function ImportBox.ClearAll()
    for _, instance in ipairs(ImportBox.instances) do
        instance.editbox:SetTextSafe("");
    end
end

local pasteBuffer, index = {}, 0;
local function onCharAdded(editbox, c)
    if(editbox:IsEnabled()) then
        editbox:Disable();
        ImportBox:DisableAll();
        ImportBox:ClearAll();

        pasteBuffer, index = {}, 0;
        C_Timer.After(0, function()
            Import:SetPastedInput(pasteBuffer);

            if(#Import.raw > 0) then
                ImportBox:EnableAll();
            end

            pasteBuffer, index = {}, 0;

            -- Update text:
            editbox:SetTextSafe(Import:GetSourceName() .. " import detected...");
        end);
    end

    index = index + 1;
    pasteBuffer[index] = c;
end

function ImportBox:Create(parent, frameName, width, height)
    assert(parent, "Invalid parent when creating ImportBox.");
    local self = setmetatable({}, ImportBox);

    width = width and max(150, width) or 400;
    height = height or 25;

    self.frame = CreateFrame("Frame", frameName, parent);
    self.frame:SetSize(width, height);
    self.frame.owner = self;

    -- Editbox
    local editbox = CreateFrame("EditBox", nil, self.frame, "InputBoxTemplate");
    editbox:SetSize(width-129, height);
    editbox:SetPoint("LEFT", 5, 0);
    editbox:SetAutoFocus(false);
    editbox:SetMaxBytes(38);
    editbox:SetMultiLine(true);
    editbox.owner = parent;

    editbox:SetScript("OnChar", onCharAdded);

    editbox:SetScript("OnEnterPressed", function(frame)
        frame:ClearFocus();
    end);

    editbox:SetScript("OnEscapePressed", function(frame)
        frame:ClearFocus();
    end);

    editbox:SetScript("OnEditFocusGained", function(frame)
        frame:HighlightText();
    end);

    -- Clear text
    editbox:SetScript("OnHide", function(frame)
        -- Reset import, unless it's currently importing.
        Import:Reset();
    end);

    function editbox:SetTextSafe(text)
        self:SetScript("OnChar", nil);
        self:SetText(text or "");
        self:SetScript("OnChar", onCharAdded);
    end

    -- Button
    local button = AAtable:CreateButton("LEFT", editbox, "RIGHT", 10, 0, "Import");
    button:Disable();
    button:SetSize(115, 25);

    button:SetScript("OnClick", function(frame)
        frame:Disable();
        Import:ParseRawData();
    end);

    self.frame.editbox = editbox;
    self.frame.button = button;

    self.frame:SetScript("OnShow", function(frame)
        AddFrame(self.frame);
    end);

    self.frame:SetScript("OnHide", function(frame)
        RemoveFrame(self.frame);
    end);

    AddFrame(self.frame);
    return self;
end

function ImportBox:Disable()
    assert(self, "Enable called on non-instanced ImportBox.");
    self.frame.editbox:Disable();
    self.frame.button:Disable();
end

function ImportBox:SetPoint(...)
    assert(self, "SetPoint called on non-instanced ImportBox.");
    self.frame:SetPoint(...);
end

function ImportBox:GetHeight()
    assert(self, "GetHeight called on non-instanced ImportBox.");
    return self.frame:GetHeight();
end