local PPF_Config = PPF:NewModule("PPF_Config")

function PPF_Config:OnEnable()
    local LSM = LibStub("LibSharedMedia-3.0")

    -- Enable / Disable AddOn functions
    function PPF_EnableAddon()
        PPF_DB.enabled = true
        PPF:OnEvent()
        print("" .. "|cff2f80faPartyPets Fix: |r" .. "Addon enabled.")
    end

    function PPF_DisableAddon()
        PPF_DB.enabled = false
        PPF:OnEvent()
        print("" .. "|cff2f80faPartyPets Fix: |r" .. "Addon disabled.")
    end
    
    function PPF_EnableTest()
        PPF.testmode = true
        PPF_DB.enabled = false
        PPF:OnEvent()

        local anchor = _G["CompactPartyFrameMember" .. GetNumGroupMembers()]
        PPF_Pet:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, PPF_DB.positiony)
        PPF_Pet.name:SetText("TESTFRAME")

        -- Show frames if they got hidden earlier
        PPF_Pet:Show()
        PPF_PetButton:Show()
    end

    function PPF_DisableTest()
        PPF.testmode = false
        PPF_DB.enabled = true

        PPF_Pet:Hide()
        PPF_PetButton:Hide()

        PPF:OnEvent()
    end

    -- Create Menu
    local options = {
        type = 'group',
        args = {
            enable = {
            name = 'Enable',
            desc = 'Enables / disables the AddOn',
            type = 'toggle',
            set = function(_, status)
                if status then
                    PPF_EnableAddon()
                else
                    PPF_DisableAddon()
                end
            end,
            get = function()
                return PPF_DB.enabled
            end
            },
            testmode = {
                name = 'Testmode',
                desc = 'Enables / disable the Testmode',
                type = 'toggle',
                set = function(_, status)
                    if status then
                        PPF_EnableTest()
                    else
                        PPF_DisableTest()
                    end
                end,
                get = function(info)
                    return PPF.testmode
                end
            },
            moreoptions={
                name = 'General',
                type = 'group',
                childGroups = "tab",
                args={
                    generalHeader = {
                        type = 'header',
                        name = 'Width & Position',
                        order = 1
                    },
                    width = {
                        type = 'range',
                        order = 2,
                        name = 'Width',
                        desc = 'Adjust the Frame width',
                        width = 'full',
                        min = 72,
                        max = 300,
                        step = 0.1,
                        set = function(_, val)
                            PPF_Pet:SetWidth(val)
                            PPF_PetButton:SetWidth(val)

                            PPF_P1:SetWidth(val)
                            PPF_P1Button:SetWidth(val)

                            PPF_P2:SetWidth(val)
                            PPF_P2Button:SetWidth(val)

                            PPF_P3:SetWidth(val)
                            PPF_P3Button:SetWidth(val)

                            PPF_P4:SetWidth(val)
                            PPF_P4Button:SetWidth(val)

                            PPF_DB.width = val
                        end,
                        get = function()
                            return PPF_DB.width
                        end
                    },
                    positionx = {
                        type = 'range',
                        order = 3,
                        name = 'X-Position',
                        desc = 'Adjust the Frame X-Position (ONLY WORKS IN TESTMODE!)',
                        width = 'full',
                        min = -500,
                        max = 500,
                        step = 0.1,
                        set = function(_, val)
                            if PPF.testmode then
                                local anchor = _G["CompactPartyFrameMember" .. GetNumGroupMembers()]
                                PPF_Pet:SetPoint("LEFT", anchor, "LEFT", val, PPF_DB.positiony)
                                PPF_DB.positionx = val
                            end
                        end,
                        get = function()
                            return PPF_DB.positionx
                        end
                    },
                    positiony = {
                        type = 'range',
                        order = 3,
                        name = 'Y-Position',
                        desc = 'Adjust the Frame Y-Position (ONLY WORKS IN TESTMODE!)',
                        width = 'full',
                        min = -500,
                        max = 500,
                        step = 0.1,
                        set = function(_, val)
                            if PPF.testmode then
                                local anchor = _G["CompactPartyFrameMember" .. GetNumGroupMembers()]
                                PPF_Pet:SetPoint("LEFT", anchor, "LEFT", PPF_DB.positionx, val)
                                PPF_DB.positiony = val
                            end
                        end,
                        get = function()
                            return PPF_DB.positiony
                        end
                    },
                    miscellaneousHeader = {
                        type = 'header',
                        name = 'Miscellaneous',
                        order = 5
                    },
                    classcolor = {
                        name = 'Pet Classcolor',
                        desc = 'Show Pet HP-Bar in owner\'s Classcolor',
                        type = 'toggle',
                        order = 6,
                        set = function(_, val)
                            PPF_DB.classcolor = val
                        end,
                        get = function(info)
                            return PPF_DB.classcolor
                        end
                    },
                    texture = {
                        type = 'select',
                        order = 7,
                        name = 'Set Texture',
                        desc = 'Change the Pet HP-Bar texture if you want to',
                        width = 1.25,
                        values = LSM:HashTable('statusbar'),
                        dialogControl = 'LSM30_Statusbar',
                        style = 'dropdown',
                        set = function(_, texture)
                            local Texture = LSM:Fetch('statusbar', texture)
                            PPF_Pet:SetStatusBarTexture(Texture)
                            PPF_P1:SetStatusBarTexture(Texture)
                            PPF_P2:SetStatusBarTexture(Texture)
                            PPF_P3:SetStatusBarTexture(Texture)
                            PPF_P4:SetStatusBarTexture(Texture)
                            PPF_DB.texture = texture
                        end,
                        get = function()
                            return PPF_DB.texture
                        end
                    },
                }
            }
        }
    }

    -- Register Menu
    LibStub('AceConfig-3.0'):RegisterOptionsTable('PartyPets Fix', options)
    local PPF_Config = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('PartyPets Fix')

    -- Slash Command Function
    function SlashCommand(msg)
        if msg == '' then
            InterfaceOptionsFrame_OpenToCategory(PPF_Config)
        end

        if msg == 'enable' or msg == 'Enable' or msg == 'ENABLE' then
            PPF_EnableAddon()
        elseif msg == 'e' or msg == 'E' then
            PPF_EnableAddon()
        end

        if msg == 'disable' or msg == 'Disable' or msg == 'DISABLE' then
            PPF_DisableAddon()
        elseif msg == 'd' or msg == 'D' then
            PPF_DisableAddon()
        end
    end

    -- Register Slash Command
    PPF:RegisterChatCommand('PPF', SlashCommand)
end
