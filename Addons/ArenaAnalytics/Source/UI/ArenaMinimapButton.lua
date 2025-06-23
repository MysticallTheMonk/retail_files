local _, ArenaAnalytics = ...; -- Addon Namespace
ArenaAnalytics.MinimapButton = {};
local MinimapButton = ArenaAnalytics.MinimapButton;

-- Local module aliases
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

local function GetOption(setting)
    assert(setting);
    return ArenaAnalyticsSharedSettingsDB[setting];
end

local function OnClick(button)
    if(button == "RightButton") then
        -- Open ArenaAnalytics Options
        ArenaAnalytics:OpenOptions();
    elseif(button == "MiddleButton") then
        if(GetOption("surrenderByMiddleMouseClick")) then
            ArenaAnalytics.API:TrySurrenderArena();
        end
    else
        ArenaAnalytics:Toggle();
    end
end

local function OnEnter(frame)
    ArenaAnalytics.Tooltips:DrawMinimapTooltip(frame);
end

local function OnLeave(frame)
    GameTooltip:Hide();
end

-------------------------------------------------------------------------

local minimapButton = nil;

-- ArenaAnalytics Compartment object
local compartmentObject = {
    text = "Arena|cff00ccffAnalytics|r",
    icon = "Interface\\Icons\\achievement_arena_3v3_7",
    notCheckable = true,
    func = function(_, clickInfo, entry)
        OnClick(clickInfo.buttonName);
    end,
    funcOnEnter = OnEnter,
    funcOnLeave = OnLeave,
};

local function SetMinimapIconPosition(angle)
	if(not minimapButton) then
		return;
	end

	minimapButton:ClearAllPoints();
	local radius = (Minimap:GetWidth() / 2) + 5
	local xOffset = radius * cos(angle);
	local yOffset = radius * sin(angle);
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset);
end

-- Control movement
local function UpdateMinimapButtonPosition()
	local cursorX, cursorY = GetCursorPosition();
	local scale = UIParent:GetEffectiveScale() or 1;
	cursorX = cursorX / scale;
	cursorY = cursorY / scale;

	local centerX, centerY = Minimap:GetCenter();
	local angle = math.atan2(cursorY - centerY, cursorX - centerX);
	ArenaAnalyticsMapIconPos = math.deg(angle);

	SetMinimapIconPosition(ArenaAnalyticsMapIconPos);
end

function MinimapButton:Create()
	-- Create minimap button -- Credit to Leatrix
	minimapButton = CreateFrame("Button", "ArenaAnalyticsMinimapButton", Minimap);
	minimapButton:SetParent(Minimap);
	minimapButton:SetFrameStrata("HIGH");
	minimapButton:SetFrameLevel(0);
	minimapButton:SetSize(25,25);
	minimapButton:SetMovable(true);
	minimapButton:SetNormalTexture("Interface\\AddOns\\ArenaAnalytics\\icon\\mmicon");
	minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");

	local size = 50;
	minimapButton.Border = CreateFrame("Frame", nil, minimapButton);
	minimapButton.Border:SetSize(size,size);
	minimapButton.Border:SetPoint("CENTER", minimapButton, "CENTER");

	minimapButton.Border.texture = minimapButton.Border:CreateTexture();
	minimapButton.Border.texture:SetSize(size,size);
	minimapButton.Border.texture:SetPoint("TOPLEFT", 9.5, -9.5);
	minimapButton.Border.texture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");

	minimapButton:SetScript("OnEnter", OnEnter);
	minimapButton:SetScript("OnLeave", OnLeave);

	ArenaAnalyticsMapIconPos = ArenaAnalyticsMapIconPos or 0;

	-- Set position
	SetMinimapIconPosition(ArenaAnalyticsMapIconPos);

	minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");
	minimapButton:RegisterForDrag("LeftButton");

	minimapButton:SetScript("OnDragStart", function()
		minimapButton:StartMoving();
		minimapButton:SetScript("OnUpdate", UpdateMinimapButtonPosition);
	end);

	minimapButton:SetScript("OnDragStop", function()
		minimapButton:StopMovingOrSizing();
		minimapButton:SetScript("OnUpdate", nil)
		SetMinimapIconPosition(ArenaAnalyticsMapIconPos);
	end);

	-- Control clicks
	minimapButton:SetScript("OnClick", function(self, button)
		OnClick(button);
	end);
end

-- Check whether the minimap button should 
function MinimapButton:Update()
	-- Addon compartment
    if(AddonCompartmentFrame) then
        if(GetOption("hideFromCompartment")) then
            MinimapButton:RemoveFromCompartment();
        else
            MinimapButton:AddToCompartment();
        end
    end

    if(GetOption("hideMinimapButton")) then
        if(minimapButton) then
            minimapButton:Hide();
            minimapButton = nil;
        end
    elseif(not minimapButton) then
        MinimapButton:Create();
    end

	SetMinimapIconPosition(ArenaAnalyticsMapIconPos);
end

function MinimapButton:GetCompartmentIndex()
    if(AddonCompartmentFrame and AddonCompartmentFrame.registeredAddons) then
        for i=1, #AddonCompartmentFrame.registeredAddons do
            local entry = AddonCompartmentFrame.registeredAddons[i];
            if(entry == compartmentObject) then
                return i;
            end
        end
    end

    return nil;
end

function MinimapButton:AddToCompartment()
	if(AddonCompartmentFrame) then
        if(not MinimapButton:GetCompartmentIndex()) then
		    AddonCompartmentFrame:RegisterAddon(compartmentObject);
        end
	end
end

function MinimapButton:RemoveFromCompartment()
    if(AddonCompartmentFrame) then
        local existingIndex = MinimapButton:GetCompartmentIndex();
        if(existingIndex) then
            table.remove(AddonCompartmentFrame.registeredAddons, existingIndex);
            AddonCompartmentFrame:UpdateDisplay();
        end
    end
end