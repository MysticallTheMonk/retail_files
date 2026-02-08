local _, LRP = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

if LRP.isRetail then
	AddonCompartmentFrame:RegisterAddon({
		text = "Timeline Reminders",
		icon = "Interface\\AddOns\\TimelineReminders\\Media\\Textures\\logo_secondary.blp",
		registerForAnyClick = true,
		notCheckable = true,
		func = function()
			LRP.window:SetShown(not LRP.window:IsShown())
		end,
	})
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local addOnName = ...

            if addOnName == "TimelineReminders" then
                SharedMedia:Register("font", "PT Sans Narrow", "Interface\\Addons\\TimelineReminders\\Media\\Fonts\\PTSansNarrow.ttf")

                if not LiquidRemindersSaved then LiquidRemindersSaved = {} end
				if not LiquidRemindersSaved.spellDescriptionCache then LiquidRemindersSaved.spellDescriptionCache = {} end
                if not LiquidRemindersSaved.reminders then LiquidRemindersSaved.reminders = {} end
                if not LiquidRemindersSaved.spellBookData then LiquidRemindersSaved.spellBookData = {} end
                if not LiquidRemindersSaved.deathData then LiquidRemindersSaved.deathData = {} end
                if not LiquidRemindersSaved.nameColorCache then LiquidRemindersSaved.nameColorCache = {} end
                if not LiquidRemindersSaved.specializationInfoCache then LiquidRemindersSaved.specializationInfoCache = {} end
                if not LiquidRemindersSaved.settings then
                    LiquidRemindersSaved.settings = {
                        frames = {}, -- Size and positioning of frames
                        soundChannel = "Master",
                        ttsVolume = 100,
                        timeline = {
                            selectedInstanceType = 1,
                            selectedInstance = 1,
                            selectedEncounter = 1,
                            selectedDifficulty = 2,
                            selectedProfiles = {},
                            showRelevantRemindersOnly = false,
                            publicNoteReminders = true,
                            personalNoteReminders = true,
                            ignoreNoteInDungeon = false,
                            showDeathLine = true,
                            trackVisibility = {}
                        },
                        reminderTypes = {
                            TEXT = {
                                alignment = "CENTER",
                                size = 40,
                                font = LRP.gs.visual.font,
                                grow = "UP"
                            },
                            SPELL = {
                                alignment = "LEFT",
                                size = 60,
                                font = LRP.gs.visual.font,
                                grow = "UP",
                                showAsText = false
                            }
                        },
                        importOptions = {
                            duration = true,
                            color = true,
                            tts = true,
                            sound = true,
                            countdown = true,
                            glow = true
                        }
                    }
                end

                LRP:Modernize()
                LRP:InitializeTextFormatter()
                LRP:InitializeConfirmWindow()
                LRP:InitializeProfileWindow()
                LRP:InitializeTimelineData()
                LRP:InitializeNoteInterpreter()
                LRP:InitializeInterface()
                LRP:InitializeDisplay()
            end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            -- Specialization info is not available on ADDON_LOADED, so role/spec-based reminders don't show when "showRelevantRemindersOnly" is enabled.
            -- As a band-aid fix, rebuild the reminder lines on PLAYER_ENTERING_WORLD (as well as on PLAYER_SPECIALIZATION_CHANGED).

            LRP:BuildReminderLines()
        end
    end
)

SLASH_TIMELINEREMINDERS1 = "/lr"
SLASH_TIMELINEREMINDERS2 = "/tr"
SLASH_TIMELINEREMINDERS3 = "/timelinereminder"
SLASH_TIMELINEREMINDERS4 = "/timelinereminders"

function SlashCmdList.TIMELINEREMINDERS()
    LRP.window:SetShown(not LRP.window:IsShown())
end