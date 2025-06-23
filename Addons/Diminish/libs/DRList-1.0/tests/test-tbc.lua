-- Running tests from command line: (Make sure you run from root/main folder)
-- > lua DRList-1.0/tests/test-tbc.lua
--
-- Running tests ingame:
-- /drlist

if loadfile then
    assert(loadfile("DRList-1.0/tests/engine.lua"))()
end

local Tests = SimpleTesting:New("DRList-1.0", "TBC")
if not Tests:IsInGame() then
    WOW_PROJECT_ID = 5 -- set tbc

    assert(loadfile("DRList-1.0/tests/wow-stubs.lua"))()
    assert(loadfile("DRList-1.0/libs/LibStub/LibStub.lua"))()
    assert(loadfile("DRList-1.0/DRList-1.0.lua"))()
    assert(loadfile("DRList-1.0/Spells.lua"))()
end

local DRList = LibStub("DRList-1.0")

function Tests:BeforeEach()
    DRList.gameExpansion = "tbc"
end

Tests:It("Loads lib", function()
    assert(LibStub("DRList-1.0"))
    assert(type(LibStub("DRList-1.0").spellList) == "table")
    assert(LibStub("DRList-1.0").gameExpansion == "tbc")
end)

Tests:It("GetsSpellList", function()
    assert(next(DRList.spellList))
    assert(DRList:GetSpells()[853] == "stun")
    assert(DRList:GetSpells()[339] == "root")
    assert(DRList:GetSpells()[53537] == nil)
end)

Tests:It("GetsResetTimes", function()
    assert(DRList:GetResetTime() == 20)
    assert(DRList:GetResetTime("stun") == 20)
    assert(DRList:GetResetTime(123) == 20)
    assert(DRList:GetResetTime(true) == 20)
    assert(DRList:GetResetTime({}) == 20)
    assert(DRList:GetResetTime("npc") == 20)
end)

Tests:It("GetsCategoryNames", function()
    assert(type(DRList.categoryNames[DRList.gameExpansion].stun) == "string")
    assert(type(DRList:GetCategories().root) == "string")
    assert(DRList:GetCategories().knockback == nil)
end)

Tests:It("GetsCategoryNamesPvE", function()
    assert(type(DRList:GetPvECategories().stun) == "string")
    assert(type(DRList:GetPvECategories().kidney_shot) == "string")
    assert(type(DRList:GetPvECategories().random_stun) == "string")
    assert(DRList:GetPvECategories().opener_stun == nil)
    assert(DRList:GetPvECategories().taunt == nil)
    assert(DRList:GetPvECategories().disorient == nil)
end)

Tests:It("GetsCategoryFromSpell", function()
    assert(DRList:GetCategoryBySpellID(853) == "stun")
    assert(DRList:GetCategoryBySpellID(339) == "root")
    assert(DRList:GetCategoryBySpellID(1776) == "incapacitate")
    assert(select(2, DRList:GetCategoryBySpellID(853)) == nil)

    assert(DRList:GetCategoryBySpellID(123) == nil)
    assert(DRList:GetCategoryBySpellID("123") == nil)
    assert(DRList:GetCategoryBySpellID(true) == nil)
    assert(DRList:GetCategoryBySpellID({}) == nil)
    assert(DRList:GetCategoryBySpellID() == nil)
end)

Tests:It("GetsLocalizations", function()
    assert(next(DRList.categoryNames))
    assert(DRList:GetCategoryLocalization("abc") == nil)
    assert(DRList:GetCategoryLocalization(123) == nil)
    assert(DRList:GetCategoryLocalization(true) == nil)
    assert(DRList:GetCategoryLocalization({}) == nil)
    assert(DRList:GetCategoryLocalization() == nil)

    local low = string.lower
    assert(low(DRList.categoryNames[DRList.gameExpansion]["stun"]) == low(DRList.L.STUNS))
    assert(low(DRList:GetCategoryLocalization("root")) == low(DRList.L.ROOTS))
    assert(low(DRList:GetCategoryLocalization("random_root")) == low(DRList.L.RANDOM_ROOTS))
end)

Tests:It("ChecksCategoriesPvE", function()
    assert(next(DRList.categoriesPvE))
    assert(DRList:IsPvECategory("stun") == true)
    --assert(DRList:IsPvECategory("taunt") == false)
    assert(DRList:IsPvECategory("disorient") == false)

    assert(DRList:IsPvECategory() == false)
    assert(DRList:IsPvECategory({}) == false)
    assert(DRList:IsPvECategory("") == false)
    assert(DRList:IsPvECategory(853) == false)
    assert(DRList:IsPvECategory(true) == false)
end)

Tests:It("GetsNextDR", function()
    assert(DRList:GetNextDR(1, "stun") == 0.50)
    assert(DRList:GetNextDR(2, "stun") == 0.25)
    assert(DRList:GetNextDR(3, "stun") == 0)
    assert(DRList:GetNextDR(10, "stun") == 0)

    assert(DRList:GetNextDR(1, "abc") == 0)
    assert(DRList:GetNextDR(1, 123) == 0)
    assert(DRList:GetNextDR(1, true) == 0)
    assert(DRList:GetNextDR("1", "stun") == 0)
    assert(DRList:GetNextDR(true, "stun") == 0)
    assert(DRList:GetNextDR({}, "stun") == 0)
    assert(DRList:GetNextDR(true) == 0)
    assert(DRList:GetNextDR() == 0)
    assert(DRList:GetNextDR(-1, {}) == 0)
    assert(DRList:GetNextDR(1, "random_stun") == 0.50)

    assert(DRList:GetNextDR(1, "disorient") == 0.50)
    assert(DRList:GetNextDR(2, "disorient") == 0.25)

    assert(DRList:GetNextDR(0, "knockback") == 0)
    assert(DRList:GetNextDR(1, "knockback") == 0)
end)

Tests:It("NextDR", function()
    assert(DRList:NextDR(1, "stun") == 0.50)
    assert(DRList:NextDR(0.5, "stun") == 0.25)
    assert(DRList:NextDR(0.25, "stun") == 0)

    local diminished = DRList:NextDR(1)
    assert(diminished == 0.50)
    diminished = DRList:NextDR(diminished)
    assert(diminished == 0.25)
    diminished = DRList:NextDR(diminished)
    assert(diminished == 0)

    assert(DRList:NextDR(1, "asdf") == 0.50)
    assert(DRList:NextDR(0.5, "asdf") == 0.25)
    assert(DRList:NextDR(0.25, {}) == 0)
    assert(DRList:NextDR(0.25, true) == 0)
    assert(DRList:NextDR(0.25, -1) == 0)
    assert(DRList:NextDR(0.25, 1) == 0)
end)

Tests:It("IterateSpellsByCategory", function()
    local ran = false
    for spellID, category in DRList:IterateSpellsByCategory("root") do
        assert(type(spellID) == "number")
        assert(category == "root")
        ran = true
    end
    assert(ran)

    ran = false
    for spellID, category in DRList:IterateSpellsByCategory("asdasdasdf") do
        ran = true
    end
    assert(ran == false)

    ran = false
    for spellID, category in DRList:IterateSpellsByCategory(nil) do
        assert(type(spellID) == "number")
        assert(type(category) == "string" or type(category) == "table")
        ran = true
    end
    assert(ran)

    ran = false
    for category, localizedCategory in pairs(DRList:GetPvECategories()) do
        for spellID, cat in DRList:IterateSpellsByCategory(category) do -- luacheck: ignore
            assert(type(spellID) == "number")
            assert(category == cat)
            ran = true
            break
        end
    end
    assert(ran)
end)

Tests:It("Verifies spell list", function()
    local success = true
    local err = ""

    local GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo

    for spellID, category in pairs(DRList.spellList) do
        if type(spellID) ~= "number" or not GetSpellName(spellID) then
            success = false
            err = err .. "|cFFFF0000Invalid spell:|r " .. spellID .. "\n"
        end

        if type(category) == "table" then
            for i = 1, #category do
                if type(category[i]) ~= "string" or not DRList.categoryNames[DRList.gameExpansion][category[i]] then
                    success = false
                    err = err .. "|cFFFF0000Invalid category:|r " .. category[i] .. "\n"
                end
            end
        else
            if type(category) ~= "string" or not DRList.categoryNames[DRList.gameExpansion][category] then
                success = false
                err = err .. "|cFFFF0000Invalid category:|r " .. category .. "\n"
            end
        end
    end

    if not success then
        return error(err)
    end

    return success
end)

if Tests:IsInGame() then
    if WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        SLASH_DRLIST1 = "/drlist"
        SlashCmdList["DRLIST"] = function()
            Tests:RunAll()
        end
    end
else
    Tests:RunAll()
end
