local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture

function sArenaFrameMixin:FindTrinket()
    local trinket = self.Trinket
    trinket.Cooldown:SetCooldown(GetTime(), 120);
end

function sArenaFrameMixin:GetFactionTrinketIcon()
    local faction, _ = UnitFactionGroup(self.unit)
    if (faction == "Alliance") then
        return 133452
    else
        return 133453
    end
end

-- Helper function to check if we should force trinket display for humans in MoP
function sArenaFrameMixin:ShouldForceHumanTrinket()
    return not isRetail and self.race == "Human" and self.parent.db.profile.forceShowTrinketOnHuman
end

function sArenaFrameMixin:UpdateTrinketIcon(available)
    if available then
        if self.parent.db.profile.colorTrinket then
            self.Trinket.Texture:SetColorTexture(0,1,0)
        else
            self.Trinket.Texture:SetDesaturated(false)
        end
    else
        if self.parent.db.profile.colorTrinket then
            if not self.Trinket.spellID then
                self.Trinket.Texture:SetTexture(nil)
            else
                self.Trinket.Texture:SetColorTexture(1,0,0)
            end
        else
            local desaturate
            if self.updateRacialOnTrinketSlot then
                desaturate = false
            else
                desaturate = self.parent.db.profile.desaturateTrinketCD
            end
            self.Trinket.Texture:SetDesaturated(desaturate)
        end
    end
end

local function GetArenaCCInfo(unit)
    if isRetail then
        local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
        return spellID, startTime, duration
    else
        local spellID, itemID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
        return spellID, startTime, duration
    end
end

function sArenaFrameMixin:UpdateTrinket()
    local spellID, startTime, duration = GetArenaCCInfo(self.unit)

    if (spellID) then
        if (spellID ~= self.Trinket.spellID) then
            local _, spellTextureNoOverride = GetSpellTexture(spellID)

            -- Check if we had racial on trinket slot before
            local wasRacialOnTrinketSlot = self.updateRacialOnTrinketSlot

            self.Trinket.spellID = spellID

            -- Determine if we should put racial on trinket slot
            local swapEnabled = self.parent.db.profile.swapRacialTrinket or self.parent.db.profile.swapHumanTrinket
            local shouldPutRacialOnTrinket = swapEnabled and self.race and not spellTextureNoOverride

            -- Set the trinket texture AFTER determining racial placement but BEFORE updating racial
            local trinketTexture
            if spellTextureNoOverride then
                if isRetail then
                    trinketTexture = spellTextureNoOverride
                else
                    trinketTexture = self:GetFactionTrinketIcon()
                end
            else
                -- Handle MoP-specific Human trinket logic
                if not isRetail and self.race == "Human" and self.parent.db.profile.forceShowTrinketOnHuman then
                    trinketTexture = self:GetFactionTrinketIcon()  -- Show Alliance trinket even if not equipped
                else
                    trinketTexture = sArenaMixin.noTrinketTexture     -- Surrender flag if no trinket
                end
            end

            -- Handle racial updates based on trinket state
            if spellTextureNoOverride and wasRacialOnTrinketSlot then
                -- We found a real trinket and had racial on trinket slot, restore racial to its proper place
                self.updateRacialOnTrinketSlot = nil
                self.Trinket.Texture:SetTexture(trinketTexture)
                self:UpdateRacial()
            elseif shouldPutRacialOnTrinket then
                -- We should put racial on trinket slot (no real trinket found)
                self.updateRacialOnTrinketSlot = true
                -- Don't set trinket texture yet - let UpdateRacial handle it for racial display
                self:UpdateRacial()
            else
                -- Normal case: set trinket texture and clear racial from trinket slot
                self.updateRacialOnTrinketSlot = nil
                self.Trinket.Texture:SetTexture(trinketTexture)
                -- Update racial to ensure it shows in racial slot if needed
                if wasRacialOnTrinketSlot then
                    self:UpdateRacial()
                end
            end

            self:UpdateTrinketIcon(true)
        end
        if isMidnight then
            -- if (self.Trinket.spellID) and not self.Trinket.Cooldown:IsShown() then
            --     if self.Trinket.spellID and (self.Trinket.Texture:GetTexture() ~= sArenaMixin.noTrinketTexture)then
            --         if self.updateRacialOnTrinketSlot then
            --             local racialDuration = self:GetRacialDuration()
            --             self.Trinket.Cooldown:SetCooldown(startTime, racialDuration * 1000)
            --         else
            --             self.Trinket.Cooldown:SetCooldown(startTime, duration)
            --         end
            --     end
            --     if self.parent.db.profile.colorTrinket then
            --         self.Trinket.Texture:SetColorTexture(1,0,0)
            --     else
            --         if not self.updateRacialOnTrinketSlot then
            --             self.Trinket.Texture:SetDesaturated(self.parent.db.profile.desaturateTrinketCD)
            --         end
            --     end
            -- else
            --     self.Trinket.Cooldown:Clear()
            --     if self.parent.db.profile.colorTrinket then
            --         self.Trinket.Texture:SetColorTexture(0,1,0)
            --     else
            --         self.Trinket.Texture:SetDesaturated(false)
            --     end
            -- end
        else
            if (startTime ~= 0 and duration ~= 0 and self.Trinket.spellID) then
                if self.Trinket.spellID and (self.Trinket.Texture:GetTexture() ~= sArenaMixin.noTrinketTexture)then
                    if self.updateRacialOnTrinketSlot then
                        local racialDuration = self:GetRacialDuration()
                        self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, racialDuration)
                    else
                        self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, duration / 1000.0)
                    end
                end
                if self.parent.db.profile.colorTrinket then
                    self.Trinket.Texture:SetColorTexture(1,0,0)
                else
                    if not self.updateRacialOnTrinketSlot then
                        self.Trinket.Texture:SetDesaturated(self.parent.db.profile.desaturateTrinketCD)
                    end
                end
            else
                self.Trinket.Cooldown:Clear()
                if self.parent.db.profile.colorTrinket then
                    self.Trinket.Texture:SetColorTexture(0,1,0)
                else
                    self.Trinket.Texture:SetDesaturated(false)
                end
            end
        end
    end
end

function sArenaFrameMixin:ResetTrinket()
    -- If racial was on trinket slot, move it back to racial slot
    if self.updateRacialOnTrinketSlot then
        self.updateRacialOnTrinketSlot = nil
        self:UpdateRacial()
    end

    self.Trinket.spellID = nil
    self.Trinket.Texture:SetTexture(nil)
    self.Trinket.Cooldown:Clear()
    self.Trinket.Texture:SetDesaturated(false)
end
