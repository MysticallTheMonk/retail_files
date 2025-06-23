-- luacheck: no max line length
-- luacheck: globals wipe

local _, addonTable = ...;

local next, SpellNameByID, math_ceil = next, addonTable.SpellNameByID, math.ceil;

local migrations = {
    [0] = function() end,
    [1] = function() end,
    [2] = function() end,
    [3] = function() end,
    [4] = function() end,
    [5] = function()
        local db = addonTable.db;
        db.UnwantedDefaultSpells = nil;
        db.CDsTable = nil;
        for spellName, spellInfo in pairs(db.SpellCDs) do
            if (spellName == SpellNameByID[336126]) then
                if (spellInfo.spellIDs ~= nil and not spellInfo.spellIDs[336126]) then
                    spellInfo.spellIDs[336126] = true;
                end
            end
        end
    end,
    [6] = function()
        local db = addonTable.db;
        local tempTable = { };
        for _, spellInfo in pairs(db.SpellCDs) do
            if (spellInfo.spellIDs ~= nil and next(spellInfo.spellIDs) ~= nil) then
                local spellID = next(spellInfo.spellIDs);
                tempTable[spellID] = { ["enabled"] = spellInfo.enabled, ["glow"] = spellInfo.glow };
            end
        end
        addonTable.db.SpellCDs = addonTable.deepcopy(tempTable);
        if (db.TimerTextSize == nil) then
			db.TimerTextSize = math_ceil(db.IconSize - db.IconSize/2);
		end
    end,
    [7] = function()
        local db = addonTable.db;
        if (db.EnabledZoneTypes[addonTable.INSTANCE_TYPE_PVP]) then
            db.EnabledZoneTypes[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = true;
        end
    end,
};

function addonTable.MigrateDB()
    for i = addonTable.db.MigrationVersion, (addonTable.table_count(migrations)-1) do
        migrations[i]();
        addonTable.Print("Converting DB up to version", i);
    end
    addonTable.db.MigrationVersion = addonTable.table_count(migrations);
end

function addonTable.ImportNewSpells()

end
