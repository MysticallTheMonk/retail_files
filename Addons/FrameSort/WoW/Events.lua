---@type string, Addon
local _, addon = ...

---@class WowEvents
addon.WoW.Events = {
    -- Fired after ending combat, as regen rates return to normal.
    -- Useful for determining when a player has left combat.
    -- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
    -- It seems Blizzard do an update layout after combat ends, so even for the experimental mode we also need to re-sort.
    PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED",

    -- Fired whenever you enter combat, as normal regen rates are disabled during combat.
    -- This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).
    PLAYER_REGEN_DISABLED = "PLAYER_REGEN_DISABLED",

    -- Fires when the player logs in, /reloads the UI or zones between map instances.
    -- Basically whenever the loading screen appears.
    PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",

    -- Fired whenever a group or raid is formed or disbanded, players are leaving or joining the group or raid.
    GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",

    -- Fired when people within the raid group change their tank/healer/dps role.
    PLAYER_ROLES_ASSIGNED = "PLAYER_ROLES_ASSIGNED",

    -- Fired when a pet is created/destroyed which performs a frame layout.
    UNIT_PET = "UNIT_PET",

    -- Retail only even that's fired at the start of each arena match/round when the opponent specs have been loaded.
    ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS",

    -- Fires whenever an arena opponent is seen/unseen/killed/removed
    ARENA_OPPONENT_UPDATE = "ARENA_OPPONENT_UPDATE",

    -- Special event that's fired when the user closes edit mode.
    -- Can only be used directly on EventRegistry and not via RegisterScript()
    EditModeExit = "EditMode.Exit",

    -- Fires when changing console variables with an optional argument to C_CVar.SetCVar().
    CVAR_UPDATE = "CVAR_UPDATE",

    -- Fired when switching to a different layout from edit mode.
    EDIT_MODE_LAYOUTS_UPDATED = "EDIT_MODE_LAYOUTS_UPDATED",

    -- Fired when a unit's name updates (both ally and enemy units)
    UNIT_NAME_UPDATE = "UNIT_NAME_UPDATE",

    -- fired when some sort of timer starts, e.g. time until arena/bg gates open
    START_TIMER = "START_TIMER",

    -- fired when a macro is created/deleted/updated
    UPDATE_MACROS = "UPDATE_MACROS",

    -- fires at start/end of an arena match/round
    PVP_MATCH_STATE_CHANGED = "PVP_MATCH_STATE_CHANGED",

    -- fired when the results of NotifyInspect are ready
    INSPECT_READY = "INSPECT_READY",

    -- fires multiple times when someone changes their spec
    PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED",

    -- Fires when a protected function is being called from tainted code, e.g. taint from an addon.
    ADDON_ACTION_BLOCKED = "ADDON_ACTION_BLOCKED",

    -- Fires when an AddOn tries use actions that are always forbidden (movement, targeting, etc.).
    ADDON_ACTION_FORBIDDEN = "ADDON_ACTION_FORBIDDEN",

    -- Fires when a nameplate is to be added. The event may sometimes fire before a nameplate is actually added.
    NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED",
}
