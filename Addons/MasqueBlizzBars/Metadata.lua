--
-- Masque Blizzard Bars
-- Enables Masque to skin the built-in WoW action bars
--
-- Copyright 2022 - 2024 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local _, Shared = ...

-- From Locales/Locales.lua
local L = Shared.Locale

-- Push us into shared object
local Metadata = {}
Shared.Metadata = Metadata

Metadata.FriendlyName = "Masque Blizzard Bars"
Metadata.MasqueFriendlyName = "Blizzard Action Bars"

-- Title will be used for the group name shown in Masque
-- Delayed indicates this group will be deferred to a hook or event
-- Init is a function that will be run at load time for this group
-- Notes will be displayed (if provided) in the Masque settings UI
-- Versions specifies which WoW clients this group supports:
--  To match it must be >= low and < high.
--  High number is the first interface unsupported
-- Buttons should contain a list of frame names with an integer value
--  If -2, assume to be a function that returns a table of buttons
--  If -1, assume to be a singular button with that name
--  If  0, this is a dynamic frame to be skinned later
--  If >0, attempt to loop through frames with the name prefix suffixed with
--  the integer range
-- ButtonPools should reference parent frames containing an itemButtonPool
-- State can be used for storing information about special buttons
Metadata.Groups = {
	ActionBar = {
		Title = "Action Bar 1",
		Buttons = {
			ActionButton = NUM_ACTIONBAR_BUTTONS
		}
	},
	MultiBarBottomLeft = {
		Title = "Action Bar 2",
		Versions = { 10300, nil },
		Buttons = {
			MultiBarBottomLeftButton = NUM_MULTIBAR_BUTTONS
		}
	},
	MultiBarBottomRight = {
		Title = "Action Bar 3",
		Versions = { 10300, nil },
		Buttons = {
			MultiBarBottomRightButton = NUM_MULTIBAR_BUTTONS
		}
	},
	MultiBarLeft = {
		Title = "Action Bar 4",
		Versions = { 10300, nil },
		Buttons = {
			MultiBarLeftButton = NUM_MULTIBAR_BUTTONS
		}
	},
	MultiBarRight = {
		Title = "Action Bar 5",
		Versions = { 10300, nil },
		Buttons = {
			MultiBarRightButton = NUM_MULTIBAR_BUTTONS
		}
	},
	-- Three new bars for 10.0.0
	MultiBar5 = {
		Title = "Action Bar 6",
		Versions = { 100000, nil },
		Buttons = {
			MultiBar5Button = NUM_MULTIBAR_BUTTONS
		}
	},
	MultiBar6 = {
		Title = "Action Bar 7",
		Versions = { 100000, nil },
		Buttons = {
			MultiBar6Button = NUM_MULTIBAR_BUTTONS
		}
	},
	MultiBar7 = {
		Title = "Action Bar 8",
		Versions = { 100000, nil },
		Buttons = {
			MultiBar7Button = NUM_MULTIBAR_BUTTONS
		}
	},
	PetBar = {
		Title = "Pet Bar",
		Buttons = {
			PetActionButton = NUM_PET_ACTION_SLOTS
		}
	},
	PossessBar = {
		Title = "Possess Bar",
		Buttons = {
			PossessButton = NUM_POSSESS_SLOTS
		}
	},
	StanceBar = {
		Title = "Stance Bar",
		Buttons = {
			-- Static value in game code is not a global
			StanceButton = 10
		}
	},
	SpellFlyout = {
		Title = "Spell Flyouts",
		Notes = L["NOTES_SPELL_FLYOUTS"],
		Versions = { 70003, nil },
		Buttons = {
			SpellFlyoutPopupButton = 0
		}
	},
	OverrideActionBar = {
		Title = "Vehicle Bar",
		Notes = L["NOTES_VEHICLE_BAR"],
		Versions = { 30002, nil },
		Buttons = {
			-- Static value in game code is not a global
			OverrideActionBarButton = 6

			-- Exit Button loses its icon if skinned, so
			-- it's not included here
		}
	},
	ExtraAbilityContainer = {
		Title = "Extra Ability Buttons",
		Notes = L["NOTES_EXTRA_ABILITY_BUTTONS"],
		Versions = { 40402, nil },

		-- Keep track of the frames that have been processed
		State = {
			ExtraActionButton = false,
			ZoneAbilityButton = {}
		},
		Buttons = {
			-- These buttons don't exist until the first time
			-- they're used so we'll pick them up later
		}
	},
	PetBattleFrame = {
		Title = "Pet Battle Bar",
		Versions = { 50004, nil },
		State = {
			PetBattleButton = {}
		},
		Buttons = {
			-- These buttons are all children of
			-- PetBattleFrame.BottomFrame but some don't
			-- exist or have defined names until the first
			-- battle
		}
	},
	CooldownViewer = {
		Title = "Cooldown Manager",
		Versions = { 110105, nil },
		-- These are populated after the UI loads when the RefreshLayout
		-- function is called
		Delayed = true,
		Buttons = {
			BuffIconCooldownViewer = {
				GetItemFrames = -2
			},
			EssentialCooldownViewer = {
				GetItemFrames = -2
			},
			UtilityCooldownViewer = {
				GetItemFrames = -2
			}
		}
	}
}

-- Specify Button Types and Regions for Buttons that need them
local CooldownViewerMap = {
	Icon = "Icon",
	Cooldown = "Cooldown",
	Count = "ChargeCount.Current",
	Mask = "Mask"
}

Metadata.Types = {
	-- This will be passed for all buttons unless it's otherwise overridden
	DEFAULT = { type = "Action" },
	BuffIconCooldownViewerGetItemFrames = { type = "Action", map = CooldownViewerMap },
	EssentialCooldownViewerGetItemFrames = { type = "Action", map = CooldownViewerMap },
	UtilityCooldownViewerGetItemFrames = { type = "Action", map = CooldownViewerMap }
}

-- A table indicating the defaults for Options by key.
-- Only populate options where the default isn't false
Metadata.Defaults = {
}

-- A table of function callbacks to call upon setting certain options.
-- This has to be populated by the Addon during its init process, since
-- the functions won't exist by this point, so this should remain empty
-- here.
Metadata.OptionCallbacks = {}

-- AceConfig Options table used to display a panel.
Metadata.Options = {
}

