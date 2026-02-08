PPF = LibStub("AceAddon-3.0"):NewAddon("PPF", "AceEvent-3.0", "AceConsole-3.0")

function PPF:OnInitialize()
    -- Database Default profile
    local defaults = {
        profile = {
          width = 72,
          positionx = 0,
          positiony = -55,
          classcolor = false,
          texture = [[Interface\RaidFrame\Raid-Bar-Hp-Fill]],
          enabled = true
        }
    }

    -- Register Database
    self.db = LibStub("AceDB-3.0"):New("PPFDB", defaults, true)

    -- Assign DB to a global variable
    PPF_DB = self.db.profile

    -- Testmode Variable
    PPF.testmode = false
end

function PPF:LSB_Helper(LSBList, LSBHash)
    local list = {}
    for index, name in pairs(LSBList) do
        list[index] = {}
        for k, v in pairs(LSBHash) do
            if (name == k) then
                list[index] = {
                    text = name,
                    value = v
                }
            end
        end
    end
    return list
end