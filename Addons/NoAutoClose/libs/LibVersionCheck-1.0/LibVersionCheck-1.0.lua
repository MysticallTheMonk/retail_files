--- This library can be freely redistributed and used in addon code for "World of Warcraft".
--- You probably wouldn't want to though, it's not particularly useful, and pretty bad..
--- It's designed for 1 single purpose, and that is to sate my curiosity. So there's no real documentation or whatever.
--- It's designed as a drop-in lib, and has the required dependencies embedded in itself, cause I'm lazy ;-)
--- Oh, and I'd say it's in alpha, for what it's worth.

local embedAddonName = ...;

local MAJOR, MINOR = "LibVersionCheck-1.0", 3;

--- @class LibVersionCheck-1.0
local LibVersionCheck = LibStub:NewLibrary(MAJOR, MINOR);

RunNextFrame(function() LibStub(MAJOR):AutoRegister(embedAddonName); end);

if not LibVersionCheck then return; end
local CTL = ChatThrottleLib;

local player = UnitName("player") .. "-" .. GetRealmName();
local prefix = "LibVCheck-1.0";
local broadcastMsgFormat = "BV1_%s\030%s"; -- broadcast version 1
local broadcastMsgCapture = "^" .. broadcastMsgFormat:format("(.+)", "(.+)") .. "$";
local whisperMsgFormat = "DV1_%s\030%s"; -- direct version 1
local whisperMsgCapture = "^" .. whisperMsgFormat:format("(.+)", "(.+)") .. "$";

--- @return string?
local function getGroupChannel()
    if IsInInstance() then
        return "INSTANCE_CHAT";
    end
    if IsInRaid() then
        return "RAID";
    end
    if IsInGroup() then
        return "PARTY";
    end

    return nil;
end

do -- setup
    --- @type table<string, boolean> [addonName] = true
    LibVersionCheck.disableAutoRegister = LibVersionCheck.disableAutoRegister or {};

    --- @type table<string, string> [addonName] = version
    LibVersionCheck.addonVersions = LibVersionCheck.addonVersions or {};

    --- @type table<string, table<string, string>> [addonName] = { [playerName] = version }
    LibVersionCheck.playerVersions = LibVersionCheck.playerVersions or {};

    LibVersionCheck.onVersionChangedCallbacks = LibVersionCheck.onVersionChangedCallbacks or {};

    if not LibVersionCheck.prefixRegistered then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix);
        LibVersionCheck.prefixRegistered = true;
    end
end

--- @param addonName string
--- @public
function LibVersionCheck:DisableAutoRegister(addonName)
    self.disableAutoRegister[addonName] = true;
end

--- @param addonName string
--- @param version string
--- @public
function LibVersionCheck:Register(addonName, version)
    self.addonVersions[addonName] = version;
    self.playerVersions[addonName] = self.playerVersions[addonName] or {};

    if self.isInGuild then
        self:SendVersion("GUILD", addonName);
    end
    local channel = getGroupChannel();
    if channel then
        self:SendVersion(channel, addonName);
    end
end

--- @param addonName string
--- @return table<string, string> # [playerName-realmName] = version
--- @public
function LibVersionCheck:GetAddonVersionsForAddon(addonName)
    return self.playerVersions[addonName] or {};
end

--- @param playerName string # playerName-realmName
--- @return table<string, string> # [addonName] = version
--- @public
function LibVersionCheck:GetAddonVersionsForPlayer(playerName)
    local versions = {};
    for addonName, playerVersions in pairs(self.playerVersions) do
        versions[addonName] = playerVersions[playerName];
    end

    return versions;
end

--- @param channel string
--- @param addonName string? # if nil, requests for all registered addons
--- @param target string? # only required for WHISPER channel
--- @public
function LibVersionCheck:RequestVersion(channel, addonName, target)
    self:SendVersion(channel, addonName, target);
end

--- @param addonName string
--- @public
function LibVersionCheck:ResetAddonVersionCache(addonName)
    self.playerVersions[addonName] = {};
end

--- @param callback fun(playerName: string, addonName: string, version: string, previousVersion: string)
---@param addonName string? # optionally filter to a specific addon
function LibVersionCheck:RegisterOnVersionChangedCallback(callback, addonName)
    addonName = addonName or "";
    self.onVersionChangedCallbacks[addonName] = self.onVersionChangedCallbacks[addonName] or {};
    table.insert(self.onVersionChangedCallbacks[addonName], callback);
end

--- @param addonName string
--- @private
function LibVersionCheck:AutoRegister(addonName)
    if self.disableAutoRegister[addonName] then return; end
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version");
    if not version or version == "" then
        version = "Unknown Version";
    end
    self:Register(addonName, version);
end

--- @param channel string
--- @param addonName string? # if nil, requests for all registered addons
--- @param target string? # only required for WHISPER channel
--- @private
function LibVersionCheck:SendVersion(channel, addonName, target)
    if not addonName then
        for addonName, _ in pairs(self.addonVersions) do
            self:SendVersion(channel, addonName);
        end
        return;
    end
    local version = self.addonVersions[addonName];
    if not version then return; end

    local format = target and whisperMsgFormat or broadcastMsgFormat;
    CTL:SendAddonMessage("NORMAL", prefix, format:format(addonName, version), channel, target);
end

--- @param sender string
--- @param addonName string
--- @param version string
--- @param isBroadcast boolean
--- @private
function LibVersionCheck:ReceivedVersion(sender, addonName, version, isBroadcast)
    self.playerVersions[addonName] = self.playerVersions[addonName] or {};
    local previousVersion = self.playerVersions[addonName][sender];
    self.playerVersions[addonName][sender] = version;

    if previousVersion ~= version then
        self:OnVersionChanged(sender, addonName, version, previousVersion);
    end

    if not isBroadcast then return; end

    self:SendVersion("WHISPER", addonName, sender);
end

--- @private
function LibVersionCheck:OnVersionChanged(sender, addonName, version, previousVersion)
    local callbacks = self.onVersionChangedCallbacks[addonName] or {};
    for _, callback in ipairs(callbacks) do
        securecallfunction(callback, sender, addonName, version, previousVersion);
    end
    local globalCallbacks = self.onVersionChangedCallbacks[""] or {};
    for _, callback in ipairs(globalCallbacks) do
        securecallfunction(callback, sender, addonName, version, previousVersion);
    end
end

LibVersionCheck.events = LibVersionCheck.events or CreateFrame("Frame");
LibVersionCheck.events:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...);
end);
local e = LibVersionCheck.events;
e:UnregisterAllEvents(); -- unregister all events from unupgraded lib instances

function e:PLAYER_GUILD_UPDATE(unit)
    if unit ~= "player" then return; end
    RunNextFrame(function()
        LibVersionCheck.isInGuild = IsInGuild();
        if LibVersionCheck.isInGuild then
            local previousGuild = LibVersionCheck.playerGuild;
            local guildName, _, _, guildRealm = GetGuildInfo("player");
            if not guildName then return; end -- can happen during the initial login
            LibVersionCheck.playerGuild = guildName .. "-" .. (guildRealm or '');
            if previousGuild ~= LibVersionCheck.playerGuild then
                LibVersionCheck:SendVersion("GUILD");
            end
        end
    end);
end
e:RegisterEvent("PLAYER_GUILD_UPDATE");

function e:GROUP_JOINED()
    local channel = getGroupChannel();
    if not channel or GetNumGroupMembers() <= 1 then return; end
    LibVersionCheck:SendVersion(channel);
end
e:RegisterEvent("GROUP_JOINED");

function e:CHAT_MSG_ADDON(receivedPrefix, text, channel, sender)
    if receivedPrefix ~= prefix or sender == player then return; end
    local addonName, version;

    addonName, version = text:match(whisperMsgCapture);
    if addonName and version then
        local isBroadcast = false;
        LibVersionCheck:ReceivedVersion(sender, addonName, version, isBroadcast);

        return;
    end

    addonName, version = text:match(broadcastMsgCapture);
    if addonName and version then
        local isBroadcast = true;
        LibVersionCheck:ReceivedVersion(sender, addonName, version, isBroadcast);

        return;
    end
end
e:RegisterEvent("CHAT_MSG_ADDON");


