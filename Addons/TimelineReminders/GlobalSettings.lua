local _, LRP = ...

local interfaceVersion = select(4, GetBuildInfo())

LRP.gs = {
    season = interfaceVersion < 110100 and 13 or 14,
    debug = false, -- Debug mode adds some additional features
    visual = {
        font = "Interface\\Addons\\TimelineReminders\\Media\\Fonts\\PTSansNarrow.ttf",
        fontFlags = "",
        borderColor = {r = 0.3, g = 0.3, b = 0.3}
    }
}
