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

local ldbIcon = LibStub("LibDBIcon-1.0");

local addonName, addon = ...;
addon.Icon = {};
local icon = addon.Icon;
local ldbName = addonName .. "LDB";

function icon:SetTooltipContent(tooltip)
    tooltip:ClearLines();
    tooltip:AddDoubleLine(addon.Metadata.Title, addon.Metadata.BuildVersion);
    GameTooltip_AddBlankLineToTooltip(tooltip);
    self.SetMoreTooltipContent(tooltip);
end

function icon:OnClick(button)
    if button == "LeftButton" and self.OnLeftClick then
        self.OnLeftClick();
    elseif button == "RightButton" and self.OnRightClick then
        self.OnRightClick();
    end
end

function icon:CreateIcon()
    self.LdbObject = LibStub("LibDataBroker-1.1"):NewDataObject(ldbName, {
        type = "launcher",
        label = addon.Metadata.Title,
        icon = addon.Metadata.Icon,
        OnClick = function(_, button) self:OnClick(button); end,
        OnTooltipShow = function(tooltip) self:SetTooltipContent(tooltip); end
    });
end

function icon:Load()
    self:CreateIcon();

    local db = addon.Options.db.profile;
    db.Minimap.hide = not db.ShowMinimapIcon;
    ldbIcon:Register(ldbName, self.LdbObject, db.Minimap);
end

function icon:Show()
    ldbIcon:Show(ldbName);
end

function icon:Hide()
    ldbIcon:Hide(ldbName);
end

function icon:OnAddonCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_NONE");
    GameTooltip:SetPoint("TOPRIGHT", menuButtonFrame, "BOTTOMRIGHT", 0, 0);
    self:SetTooltipContent(GameTooltip);
    GameTooltip:Show();
end
_G[addon.Metadata.Prefix .. "_OnAddonCompartmentEnter"] = function(...) icon:OnAddonCompartmentEnter(...); end

function icon:OnAddonCompartmentLeave()
    GameTooltip:Hide();
end
_G[addon.Metadata.Prefix .. "_OnAddonCompartmentLeave"] = function(...) icon:OnAddonCompartmentLeave(...); end

function icon:OnAddonCompartmentClick(_, button)
    self:OnClick(button)
end
_G[addon.Metadata.Prefix .. "_OnAddonCompartmentClick"] = function(...) icon:OnAddonCompartmentClick(...); end