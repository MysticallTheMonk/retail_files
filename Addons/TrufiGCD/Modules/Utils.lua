---@type string, Namespace
local _, ns = ...

---@class Utils
local utils = {}
ns.utils = utils

utils.uuid = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---@param collection table
---@return number
utils.size = function(collection)
    local size = 0

    for _, _ in pairs(collection) do
        size = size + 1
    end

    return size
end

---@return string
utils.defaultProfileName = function()
    return UnitName("player") .. " - " .. GetRealmName()
end

---@param spellId number | string
---@return string | nil, nil, number | nil, number | nil, number | nil, number | nil, number | nil, number | nil
utils.getSpellInfo = function(spellId)
    if GetSpellInfo then
        return GetSpellInfo(spellId)
    end

    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
end

---@param spellId string | number
---@return string
utils.getSpellLink = function(spellId)
    if GetSpellLink then
        return GetSpellLink(spellId)
    else
        return C_Spell.GetSpellLink(spellId)
    end

end

utils.interfaceOptions_AddCategory = function(frame)
    -- cancel is no longer a default option. May add menu extension for this.
    frame.OnCommit = frame.okay;
    frame.OnDefault = frame.default;
    frame.OnRefresh = frame.refresh;

    if frame.parent then
        local category = Settings.GetCategory(frame.parent);
        local subcategory = Settings.RegisterCanvasLayoutSubcategory(category, frame, frame.name, frame.name);
        subcategory.ID = frame.name;
        return subcategory, category;
    else
        local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name, frame.name);
        category.ID = frame.name;
        Settings.RegisterAddOnCategory(category);
        return category;
    end
end
