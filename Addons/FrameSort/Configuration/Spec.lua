---@type string, Addon
local _, addon = ...
local M = {}

addon.Configuration.SpecIds = M

M.Tanks = {
    66, -- prot pally
    73, -- prot warrior
    104, -- guardian druid
    250, -- blood dk
    268, -- brewmaster
    581, -- vengeance
}

M.Healers = {
    65, -- hpal
    105, -- rdruid
    256, -- disc priest
    257, -- holy priest
    264, -- resto shaman
    270, -- mistweaver
    1468, -- preservation
}

M.Casters = {
    62, -- arcane mage
    63, -- fire mage
    64, -- frost mage
    102, -- boomkin
    258, -- shadow priest
    262, -- ele sham
    265, -- affi lock
    266, -- demo lock
    267, -- destro lock
    1467, -- devastation
    1473, -- aug voker
}

M.Hunters = {
    253, -- bm hunter
    254, -- mm hunter
    255, -- survival hunter
}

M.Melee = {
    70, -- ret pally
    71, -- arms warr
    72, -- fury warr
    103, -- feral
    251, -- frost dk
    252, -- unholy dk
    259, -- assa rogue
    260, -- outlaw rogue
    261, -- sub rogue
    263, -- enhance shaman
    269, -- ww monk
    577, -- havoc dh
}
