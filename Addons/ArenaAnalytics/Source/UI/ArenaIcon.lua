local _, ArenaAnalytics = ...; -- Addon Namespace
local ArenaIcon = ArenaAnalytics.ArenaIcon;
ArenaIcon.__index = ArenaIcon

-- Local module aliases
local Constants = ArenaAnalytics.Constants;
local Internal = ArenaAnalytics.Internal;
local Helpers = ArenaAnalytics.Helpers;
local API = ArenaAnalytics.API;
local Options = ArenaAnalytics.Options;

-------------------------------------------------------------------------

function ArenaIcon:Create(parent, size, skipDeath)
    local name = "ArenaIcon_"..(spec_id or "???");
    local newFrame = CreateFrame("Frame", name, parent);
    newFrame:SetPoint("CENTER");    
    newFrame:SetSize(size, size);

    local baseFrameLevel = newFrame:GetFrameLevel();

    newFrame.classTexture = newFrame:CreateTexture();
    newFrame.classTexture:SetPoint("CENTER");
    newFrame.classTexture:SetAllPoints(newFrame);
    newFrame.classTexture:SetTexture(134400);

    if(not skipDeath) then
        newFrame.deathOverlay = CreateFrame("Frame", nil, newFrame);
        newFrame.deathOverlay:SetAllPoints(newFrame.classTexture);
        newFrame.deathOverlay:SetFrameLevel(baseFrameLevel + 1);

        newFrame.deathOverlay.texture = newFrame.deathOverlay:CreateTexture();
        newFrame.deathOverlay.texture:SetAllPoints(newFrame.deathOverlay);
        newFrame.deathOverlay.texture:SetColorTexture(1, 0, 0, 0.31);
    end

    local halfSize = floor(size/2);
    newFrame.specOverlay = CreateFrame("Frame", nil, newFrame);
    newFrame.specOverlay:SetPoint("BOTTOMRIGHT", newFrame.classTexture, -1.6, 1.6);
    newFrame.specOverlay:SetSize(halfSize, halfSize);
    newFrame.specOverlay:SetFrameLevel(baseFrameLevel + 2);

    newFrame.specOverlay.texture = newFrame.specOverlay:CreateTexture();
    newFrame.specOverlay.texture:SetAllPoints(newFrame.specOverlay);

    -- Functions
    function newFrame:SetSpecVisibility(visible) 
        if(self.specOverlay and self.specOverlay.texture) then
            if(visible) then
                self.specOverlay:Show();
            else
                self.specOverlay:Hide();
            end
        end
    end

    function newFrame:SetDeathVisibility(visible)
        if(self.deathOverlay and self.deathOverlay.texture) then
            if(visible and self.isFirstDeath) then
                self.deathOverlay:Show();
            else
                self.deathOverlay:Hide();
            end
        end
    end

    function newFrame:SetSpec(spec_id, hideInvalid)
        local isSpec = Helpers:IsSpecID(spec_id);

        local classIcon, specIcon;
        if(Options:Get("fullSizeSpecIcons")) then
            classIcon = isSpec and API:GetSpecIcon(spec_id) or Internal:GetClassIcon(spec_id);
            specIcon = ""; -- Hide spec icon
        else
            classIcon = Internal:GetClassIcon(spec_id);
            specIcon = API:GetSpecIcon(spec_id);
        end

        -- Class icon (Fallback to red question mark)
        if(not classIcon and hideInvalid) then
            classIcon = "";
        end

        -- Set class icon
        newFrame.classTexture:SetTexture(classIcon or 134400);

        -- Set spec icon
        if(isSpec) then
            newFrame.specOverlay.texture:SetTexture(specIcon or "");
        else
            newFrame.specOverlay.texture:SetTexture("");
        end
    end

    function newFrame:SetIsFirstDeath(value, alwaysShown)
        if(skipDeath) then
            return;
        end

        self.isFirstDeath = value and true or nil;

        if(not self.isFirstDeath or not alwaysShown) then
            self.deathOverlay:Hide();
        else
            self.deathOverlay:Show();
        end
    end

    return newFrame;
end