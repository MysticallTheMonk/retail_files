--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

if KROWI_LIBMAN then return end

local function SetCurrentIfRequested(self, options, library)
    if options.SetCurrent then
        self.CurrentLibrary = library
    end
end

local function NewLibrary(self, libName, libVersion, options)
    assert(type(libName) == 'string', 'Bad argument #2 to \'InitLibrary\' (string expected)')
    libVersion = assert(tonumber(string.match(libVersion, '%d+')), 'Bad argument #3 to \'InitLibrary\' (version must either be a number or contain a number)')

    options = options or {}

    local lib = LibStub:NewLibrary(libName, libVersion)
    if not lib then -- Library already exists, but we may need to set it as current
        SetCurrentIfRequested(self, options, LibStub(libName))
        return
    end

    lib.Name = libName
    lib.Version = libVersion

    SetCurrentIfRequested(self, options, lib)

    if options.SetUtil then
        lib.Util = self:GetUtil()
    end

    if options.InitLocalization then
        self:GetUtil().LocalizationHelper.InitLocalization(lib)
    end
    return lib
end

local lib = NewLibrary(nil, 'Krowi_LibMan', 0)
if not lib then return end

KROWI_LIBMAN = lib
lib.NewLibrary = NewLibrary

function lib:GetLibrary(libName, silent)
    assert(type(libName) == 'string', 'Bad argument #2 to \'GetLibrary\' (string expected)')
    return LibStub(libName, silent)
end

function lib:GetCurrentLibrary(silent)
    if not self.CurrentLibrary and not silent then
        error('No current library is set.', 2)
    end
    return self.CurrentLibrary
end

function lib:NewSubmodule(subName, subVersion, parentLibrary)
	assert(type(subName) == 'string', 'Bad argument #2 to \'InitSubmodule\' (string expected)')
	subVersion = assert(tonumber(string.match(subVersion, '%d+')), 'Bad argument #3 to \'InitSubmodule\' (version must either be a number or contain a number)')

    if type(parentLibrary) == 'string' then
        parentLibrary = LibStub(parentLibrary)
    elseif not parentLibrary then
        parentLibrary = self.CurrentLibrary
    end

    local submodule = self:NewLibrary(parentLibrary.Name .. '_' .. subName, subVersion)
    if not submodule then return end -- Already loaded and no upgrade needed

    parentLibrary[subName] = submodule

    return submodule, parentLibrary
end

function lib:SetUtil(utilLibrary)
    self.Util = utilLibrary
end

function lib:GetUtil(silent)
    if not self.Util and not silent then
        error('No current library is set.', 2)
    end
    return self.Util
end

function lib:NewAddon(addonName, addon, options)
    self.Addons = self.Addons or {}
    if self.Addons[addonName] then return end

    options = options or {}

    self.Addons[addonName] = self.Addons[addonName] or addon

    if options.SetCurrent then
        self.CurrentAddon = addon
    end

    if options.SetUtil then
        addon.Util = self:GetUtil()
    end

    if options.SetMenuBuilder then
        addon.MenuBuilder = self:GetLibrary('Krowi_Menu_2').MenuBuilder
    end

    if options.SetBroker then
        addon.Broker = self:GetLibrary('Krowi_Brokers_2')
    end

    if options.SetMetaData then
        addon.Metadata = self:GetUtil().Metadata.GetAddOnMetadata(addonName)
    end

    if options.InitLocalization then
        addon.Util.LocalizationHelper.InitLocalization(addon)
    end
end