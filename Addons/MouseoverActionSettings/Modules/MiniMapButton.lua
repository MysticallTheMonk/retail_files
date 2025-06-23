local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local Icon = nil
local IconObj = nil

local module = addon:NewModule("MiniMapButton")

function module:OnEnable()
    if not Icon then
        Icon = LibStub("LibDBIcon-1.0")
    end
    if not IconObj then
        IconObj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
            type = "launcher",
            label = addonName,
            icon = addonTable.texturePaths.MinimapIcon,
            OnClick = function(self, button) 
                if button == "LeftButton" then
                    addon:SlashCommand() 
                elseif button == "RightButton" then                  
                    if addon:IsEnabled() then
                        addon:Disable()           
                        addon:HideOptionsFrame() --the options do not work as intended while the addon is disabled
                        addon:EnableModule("MiniMapButton")
                    else
                        addon:Enable()                      
                        addon:UpdateTrigger()
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Mouseover Action Settings")
                tooltip:AddLine("\124cFF7FFFD4" .. L["left_click"] .. " \124r" .. L["text_after_left_click"]) 
                tooltip:AddLine("\124cFF7FFFD4" .. L["right_click"] .. " \124r" .. L["text_after_right_click"])
            end,
        })
        Icon:Register(addonName, IconObj, addon.db.profile.MiniMapButton)
    end
    Icon:Show(addonName)
end

function module:OnDisable()
    if Icon and IconObj then
        Icon:Hide(addonName)
    end
end
