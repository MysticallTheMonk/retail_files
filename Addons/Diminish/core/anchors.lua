local _, NS = ...

-- Third-party addon's unitframe anchors.
-- Blizzard frame should always be last.
NS.anchors = {
    player = {
        "SUFUnitplayer",
        "XPerl_PlayerportraitFrame",
        "ElvUF_Player",
        "oUF_TukuiPlayer",
        "bplayerUnitFrame",
        "DUF_PlayerFrame",
        "GwPlayerHealthGlobe",
        "PitBull4_Frames_Player",
        "oUF_Player",
        "SUI_playerFrame",
        "gUI4_UnitPlayer",
        "oUF_Adirelle_Player",
        "Stuf.units.player",
        "oUF_AftermathhPlayer",
        "LUFUnitplayer",
        "oUF_LumenPlayer",
        "PlayerFrame",
    },

    target = {
        "SUFUnittarget",
        "XPerl_TargetportraitFrame",
        "ElvUF_Target",
        "oUF_TukuiTarget",
        "btargetUnitFrame",
        "DUF_TargetFrame",
        "GwTargetUnitFrame",
        "PitBull4_Frames_Target",
        "oUF_Target",
        "SUI_targetFrame",
        "gUI4_UnitTarget",
        "oUF_Adirelle_Target",
        "Stuf.units.target",
        "oUF_AftermathhTarget",
        "LUFUnittarget",
        "oUF_LumenTarget",
        "TukuiTargetFrame",
        "CG_UnitFrame_2",
        "TargetFrame",
    },

    party = {
        "SUFHeaderpartyUnitButton%d",
        "XPerl_party%d",
        "ElvUF_PartyGroup1UnitButton%d",
        "TukuiPartyUnitButton%d",
        "DUF_PartyFrame%d",
        "PitBull4_Groups_PartyUnitButton%d",
        "oUF_Raid%d",
        "GwPartyFrame%d",
        "gUI4_GroupFramesGroup5UnitButton%d",
        "Stuf.units.party%d",
        "Aftermathh_Party%d",
        "Grid2LayoutHeader1UnitButton%d",
        "oUF_LumenParty%d",
        "PartyMemberFrame%d",
    },
}

if not NS.IS_CLASSIC then
    NS.anchors.focus = {
        "SUFUnitfocus",
        "XPerl_Focushighlight",
        "ElvUF_Focus",
        "oUF_TukuiFocus",
        "bfocusUnitFrame",
        "DUF_FocusFrame",
        "GwFocusUnitFrame",
        "PitBull4_Frames_Focus",
        "oUF_Focus",
        "SUI_focusFrame",
        "gUI4_UnitFocus",
        "oUF_Adirelle_Focus",
        "Stuf.units.focus",
        "oUF_AftermathhFocus",
        "LUFUnitfocus",
        "oUF_LumenFocus",
        "FocusFrame",
    }
end

if not NS.IS_CLASSIC then
    NS.anchors.arena = {
        "ElvUF_Arena%d",
        "oUF_TukuiArena%d",
        "barena%dUnitFrame",
        "oUF_Arena%d",
        "oUF_Adirelle_Arena%d",
        "Stuf.units.arena%d",
        "sArenaEnemyFrame%d",
        "GladiusButtonFramearena%d",
        "oUF_LumenArena%d",
        "CompactArenaFrameMember%d",
        "ArenaEnemyFrame%d",
        "ArenaEnemyMatchFrame%d",
    }
end
