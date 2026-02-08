function sArenaMixin:GetSpecNameFromSpell(spellID)
    local spec = self.specCasts[spellID] or self.specBuffs[spellID]
    return spec
end

function sArenaFrameMixin:CheckForSpecSpell(spellID)
    if self.specName then return end
    if not self.class then return end

    local detectedSpec = sArenaMixin:GetSpecNameFromSpell(spellID)
    if not detectedSpec then return end

    local classSpecs = sArenaMixin.specIconTextures[self.class]
    if not classSpecs or not classSpecs[detectedSpec] then
        return false
    end

    self.specName = detectedSpec
    self.isHealer = sArenaMixin.healerSpecNames[detectedSpec] or false
    self.specTexture = classSpecs[detectedSpec]

    self.SpecNameText:SetText(detectedSpec)
    local db = self.parent.db
    if db then
        self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
    end

    self:UpdateSpecIcon()
    self:UpdateClassIcon(true)
    self:UpdateFrameColors()
    sArenaMixin:UpdateTextures()

    return true
end
