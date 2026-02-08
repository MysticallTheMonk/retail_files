local addonName, addon = ...

KROWI_LIBMAN:NewAddon(addonName, addon, {
    SetCurrent = true,
    SetUtil = true,
    SetMenuBuilder = true,
    SetMetaData = true,
    InitLocalization = true,
})
addon.CurrencyLib = KROWI_LIBMAN:GetLibrary('Krowi_Currency_2')