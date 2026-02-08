local _, LRP = ...

local windowWidth = 240
local spacing = 16
local window, confirmButton, cancelButton, title, textWrapper

local function UpdateWindowSize()
    C_Timer.After(
        0,
        function()
            window:SetHeight(title:GetHeight() + 2 * spacing + 32 + 10)
        end
    )
end

function LRP:ShowConfirmWindow(parent, text, onConfirm)
    if window:IsShown() then
        window:Hide()
    end

    window:Show()
    window:SetParent(parent)
    window:SetPoint("CENTER", parent, "CENTER")
    window:SetFrameLevel(parent:GetFrameLevel() + 10)

    parent:SetAlpha(0.5)

    title:SetText(text)
    confirmButton:SetScript(
        "OnClick",
        function()
            onConfirm()

            window:Hide()
        end
    )

    window:SetScript(
        "OnHide",
        function()
            parent:SetAlpha(1)
        end
    )

    UpdateWindowSize()
end

function LRP:InitializeConfirmWindow()
    window = LRP:CreateWindow(nil)
    LRP.confirmWindow = window

    window:SetWidth(windowWidth)
    window:SetIgnoreParentAlpha(true)
    window:SetFrameStrata("DIALOG")
    window:Hide()

    confirmButton = LRP:CreateButton(window, "|cff00ff00Confirm|r", function() end)
    confirmButton:SetPoint("BOTTOMRIGHT", window, "BOTTOM", -4, 10)

    cancelButton = LRP:CreateButton(window, "|cffff0000Cancel|r", function() window:Hide() end)
    cancelButton:SetPoint("BOTTOMLEFT", window, "BOTTOM", 4, 10)

    title = window:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(LRFont16)
    title:SetPoint("TOP", window, "TOP", 0, -spacing)
    title:SetWordWrap(true)
    title:SetWidth(windowWidth - 2 * spacing)

    textWrapper = CreateFrame("Frame")
    textWrapper:SetAllPoints(title)
    textWrapper:SetScript("OnSizeChanged", UpdateWindowSize)
end

-- When the user clicks outside the confirm window, hide it
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
eventFrame:SetScript(
    "OnEvent",
    function()
        if window:IsShown() then
            local frame = GetMouseFoci()[1]
            
            for _ = 1, 5 do
                if not frame then break end
                if frame:IsForbidden() then break end
                if frame == window then return end
                
                frame = frame.GetParent and frame:GetParent()
            end

            window:Hide()
        end
    end
)