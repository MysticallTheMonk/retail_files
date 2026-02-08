local _, LRP = ...

local instanceType = 2
local instance = 7
local encounter = 2

local phases = {}

local events = {

}

if LRP.gs.season == 14 then
    LRP.timelineData[instanceType][instance].encounters[encounter][2].events = events
    LRP.timelineData[instanceType][instance].encounters[encounter][2].phases = phases
end