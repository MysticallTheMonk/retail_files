--[[
    Copyright (c) 2023 Krowi

    All Rights Reserved unless otherwise explicitly stated.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local lib = LibStub("Krowi_Util-1.0");

if not lib then
	return;
end

lib.Metadata = {};
local metadata = lib.Metadata;

function metadata.GetAddOnMetadata(addonName)
    local getAddOnMetadata = C_AddOns.GetAddOnMetadata;
    local title = getAddOnMetadata(addonName, "Title");
    local prefix = getAddOnMetadata(addonName, "X-Prefix");
    local acronym = getAddOnMetadata(addonName, "X-Acronym");
    local build = GetBuildInfo();
    local version = getAddOnMetadata(addonName, "Version");
    local author = getAddOnMetadata(addonName, "Author");
    local icon = getAddOnMetadata(addonName, "IconTexture");
    local discordInviteLink = getAddOnMetadata(addonName, "X-Discord-Invite-Link");
    local discordServerName = getAddOnMetadata(addonName, "X-Discord-Server-Name");
    local curseForge = getAddOnMetadata(addonName, "X-CurseForge");
    local wago = getAddOnMetadata(addonName, "X-Wago");
    local woWInterface = getAddOnMetadata(addonName, "X-WoWInterface");

    return {
        AddonName = addonName,
        Title = title,
        Prefix = prefix,
        Acronym = acronym,
        Build = build,
        Version = version,
        BuildVersion = build .. "." .. version,
        Author = author,
        Icon = icon,
        DiscordInviteLink = discordInviteLink,
        DiscordServerName = discordServerName,
        CurseForge = curseForge,
        Wago = wago,
        WoWInterface = woWInterface
    };
end