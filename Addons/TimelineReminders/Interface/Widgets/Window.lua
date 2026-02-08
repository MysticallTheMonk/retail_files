local _, LRP = ...

local buttonSize = 18
local buttonMarginX = 4
local buttonMarginY = 2
local moverFrameHeight = buttonSize + 2 * buttonMarginY

-- Name is used to save position/size of the window (if set)
function LRP:CreateWindow(name, exitable, movable, resizable)
    local window = CreateFrame("Frame", nil, UIParent)

    -- Background
    window.upperTexture = window:CreateTexture(nil, "OVERLAY")
    window.upperTexture:SetPoint("TOPLEFT", window, "TOPLEFT")
    window.upperTexture:SetPoint("BOTTOMRIGHT", window, "RIGHT")
    window.upperTexture:SetTexture("Interface/Buttons/WHITE8x8")
    window.upperTexture:SetGradient("VERTICAL", CreateColor(0/255, 21/255, 56/255, 1), CreateColor(17/255, 62/255, 127/255, 1))
    
    window.lowerTexture = window:CreateTexture(nil, "OVERLAY")
    window.lowerTexture:SetPoint("TOPLEFT", window, "LEFT")
    window.lowerTexture:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
    window.lowerTexture:SetColorTexture(0/255, 21/255, 56/255)

    -- Border
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(window, 1, 1, 1)
    window:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    window.buttons = {}

    window:EnableMouse(true)

    function window:AddButton(texture, tooltip, onClick)
        local button = CreateFrame("Button", nil, window)

        button:SetSize(buttonSize, buttonSize)
        button:SetFrameLevel(window:GetFrameLevel() + 3)

        -- If this is the rightmost button, position it relative to the upperright corner of the window
        -- If it's not, position it relative to the rest of the buttons
        if #window.buttons == 0 then
            -- The button background serves to stop mouseovering of the mover frame between buttons
            window.buttonBackground = CreateFrame("Button", nil, window)
            window.buttonBackground:SetFrameLevel(window:GetFrameLevel() + 2)
            window.buttonBackground:SetPoint("TOPRIGHT", window)

            button:SetPoint("TOPRIGHT", window, "TOPRIGHT", -buttonMarginY, -buttonMarginY) -- Use buttonMarginY for the X so the rightmost button is equally far from the right edge as the top edge
        else
            button:SetPoint("TOPRIGHT", window.buttons[#window.buttons], "TOPLEFT", -buttonMarginX, 0)
        end

        window.buttonBackground:SetSize((#window.buttons + 1) * (buttonSize + buttonMarginX), moverFrameHeight)
        
        button.tex = button:CreateTexture(nil, "OVERLAY")
        button.tex:SetTexture(texture)
        button.tex:SetVertexColor(0.5, 0.5, 0.5)
        button.tex:SetAllPoints(button)

        button:SetScript(
            "OnEnter",
            function()
                button.tex:SetVertexColor(0.85, 0.85, 0.85)
            end
        )
        
        button:SetScript(
            "OnLeave",
            function()
                button.tex:SetVertexColor(0.5, 0.5, 0.5)
            end
        )
        
        button:SetScript(
            "OnClick",
            onClick
        )

        if tooltip then
            LRP:AddTooltip(button, tooltip)
        end

        table.insert(window.buttons, button)
    end
    
    -- Mover frame
    if movable then
        window:SetMovable(true)

        window.moverFrame = CreateFrame("Frame", nil, window)
        window.moverFrame:SetPoint("TOPLEFT", window)
        window.moverFrame:SetPoint("TOPRIGHT", window)
        window.moverFrame:SetHeight(moverFrameHeight)
        window.moverFrame:SetFrameLevel(window:GetFrameLevel() + 1)

        window.moverFrame.tex = window.moverFrame:CreateTexture(nil, "BACKGROUND")
        window.moverFrame.tex:SetPoint("TOPLEFT", window)
        window.moverFrame.tex:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", 0, -moverFrameHeight)
        window.moverFrame.tex:SetColorTexture(0/255, 15/255, 41/255)

        window.moverFrame:SetScript(
            "OnEnter",
            function()
                window.moverFrame.tex:SetColorTexture(0/255, 21/255, 56/255)
            end
        )

        window.moverFrame:SetScript(
            "OnLeave",
            function()
                window.moverFrame.tex:SetColorTexture(0/255, 15/255, 41/255)
            end
        )

        window.moverFrame:SetScript(
            "OnMouseDown",
            function(_, button)
                if button == "LeftButton" then
                    window:StartMoving()
                end
            end
        )

        window.moverFrame:SetScript(
            "OnMouseUp",
            function(_, button)
                if button == "LeftButton" then
                    window:StopMovingOrSizing()

                    LRP:SavePosition(window, name)
                end
            end
        )
    end

    -- Exit cross
    if exitable then
        window:AddButton(
            "Interface\\Addons\\TimelineReminders\\Media\\Textures\\ExitCross.tga",
            nil,
            function()
                window:Hide()
            end
        )
    end

    -- Resize frame
    if resizable then
        window:SetResizable(true)

        window.resizeFrame = CreateFrame("Frame", nil, window)
        window.resizeFrame:SetSize(24, 24)
        window.resizeFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")

        window.resizeFrame.tex = window.resizeFrame:CreateTexture(nil, "OVERLAY")
        window.resizeFrame.tex:SetTexture("Interface\\Addons\\TimelineReminders\\Media\\Textures\\ResizeTriangle.tga")
        window.resizeFrame.tex:SetVertexColor(0.5, 0.5, 0.5)
        window.resizeFrame.tex:SetAllPoints(window.resizeFrame)
        
        window.resizeFrame:SetScript(
            "OnEnter",
            function()
                window.resizeFrame.tex:SetVertexColor(0.85, 0.85, 0.85)
            end
        )
        
        window.resizeFrame:SetScript(
            "OnLeave",
            function()
                window.resizeFrame.tex:SetVertexColor(0.5, 0.5, 0.5)
            end
        )
        
        window.resizeFrame:SetScript(
            "OnMouseDown",
            function(_, button)
                if button == "LeftButton" then
                    window:StartSizing()
                end
            end
        )
        
        window.resizeFrame:SetScript(
            "OnMouseUp",
            function(_, button)
                if button == "LeftButton" then
                    window:StopMovingOrSizing()

                    LRP:SaveSize(window, name)
                end
            end
        )
    end

    LRP:RestoreSize(window, name)
    --LRP:RestorePosition(window, name)

    return window
end