SimpleTesting = {}
SimpleTesting.__index = SimpleTesting

local format = format or string.format
local debugprofilestop = debugprofilestop or os.clock

function SimpleTesting:New(addonName, gameExpansion)
    assert(type(addonName) == "string")
    assert(type(gameExpansion) == "string")

    local acnt = {}
    setmetatable(acnt, SimpleTesting)
    acnt.addonName = addonName
    acnt.gameExpansion = gameExpansion
    acnt.tests = {}
    acnt.testsIngame = {}

    return acnt
end

function SimpleTesting:It(funcName, testFunc, ingameOnly)
    assert(type(funcName) == "string")
    assert(type(testFunc) == "function")

    if (not ingameOnly and self.tests[funcName]) or (ingameOnly and self.testsIngame[funcName]) then
        print("INFO: overwriting existing test:", funcName) -- luacheck: ignore
    end

    if not ingameOnly then
        self.tests[funcName] = testFunc
    else
        self.testsIngame[funcName] = testFunc
    end
end

function SimpleTesting:TriggerTest(testFunc, funcName)
    local status, err = pcall(testFunc)
    if status then
        self.completedTests = self.completedTests + 1
    else
        table.insert(self.errors, {
            status = status,
            text = (err or "nil"):match([[\tests\(.+)]]) or err, -- remove folder path from error text if it exists
            funcName = funcName,
        })
    end

    self.totalTests = self.totalTests + 1
    return status, err
end

function SimpleTesting:Reset()
    self.errors = {}
    self.totalTests = 0
    self.completedTests = 0
end

function SimpleTesting:IsInGame()
    return not _G.loadfile
end

function SimpleTesting:RunAll()
    local beginTime = debugprofilestop()
    self:Reset()

    for funcName, testFunc in pairs(self.tests) do
        if self.BeforeEach then
            self:BeforeEach()
        end
        self:TriggerTest(testFunc, funcName)
    end

    if self:IsInGame() then
        for funcName, testFunc in pairs(self.testsIngame) do
            if self.BeforeEach then
                self:BeforeEach()
            end
            self:TriggerTest(testFunc, funcName)
        end
    end

    self:PrintResults(beginTime)
end

function SimpleTesting:PrintResults(beginTime)
    local timeUsed = debugprofilestop() - beginTime
    print(format("[%s (%s)] Completed %d/%d tests in %.2f seconds.", self.addonName, self.gameExpansion, self.completedTests, self.totalTests, timeUsed)) -- luacheck: ignore

    for i = 1, #self.errors do
        local err = self.errors[i]
        if self:IsInGame() then
            print(format("|CFF7EBFF1[%s]:|r |cFFFF0000%s|r", err.funcName, err.text)) -- luacheck: ignore
        else
            print(format("[%s]: %s", err.funcName, err.text)) -- luacheck: ignore
        end
    end

    if next(self.errors) and not self:IsInGame() then
        os.exit(1)
    end
end
