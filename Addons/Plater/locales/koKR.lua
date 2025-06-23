do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "koKR")
    local L = languageTable

------------------------------------------------------------
L["A /reload may be required to take effect."] = "적용하려면 /reload가 필요할 수 있습니다."
L["CVar, saved within Plater profile and restored when loading the profile."] = "Plater 프로필에 저장된 CVar는 프로필을 로드할 때 복원됩니다."
L["EXPORT"] = "내보내기"
L["EXPORT_CAST_COLORS"] = "시전바 색상 내보내기"
L["EXPORT_CAST_SOUNDS"] = "시전바 소리 내보내기"
L["HIGHLIGHT_HOVEROVER"] = "마우스오버 강조"
L["HIGHLIGHT_HOVEROVER_ALPHA"] = "마우스오버 강조 투명도"
L["HIGHLIGHT_HOVEROVER_DESC"] = "마우스를 이름표에 올렸을 때 하이라이트 효과를 적용합니다."
L["Hold Shift to change the sound of all casts with the audio %s to %s"] = "오디오 %s를 %s로 변경하려면 Shift 키를 누르고 모든 시전 사운드를 변경하세요."
L["IMPORT"] = "가져오기"
L["IMPORT_CAST_COLORS"] = "시전바 색상 가져오기"
L["IMPORT_CAST_SOUNDS"] = "시전바 소리 가져오기"
L["OPTIONS_ALPHA"] = "투명도"
L["OPTIONS_ALPHABYFRAME_ALPHAMULTIPLIER"] = "투명도 중복"
L["OPTIONS_ALPHABYFRAME_DEFAULT"] = "투명도 기본값"
L["OPTIONS_ALPHABYFRAME_DEFAULT_DESC"] = "단일 이름표의 모든 구성 요소에 적용되는 투명도입니다."
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES"] = "적에게 적용"
L["OPTIONS_ALPHABYFRAME_ENABLE_ENEMIES_DESC"] = "적으로 인식되는 유닛에 투명도를 적용합니다."
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY"] = "아군 적용"
L["OPTIONS_ALPHABYFRAME_ENABLE_FRIENDLY_DESC"] = "아군 유닛에 투명도를 적용합니다."
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE"] = "대상/범위 안 투명도"
L["OPTIONS_ALPHABYFRAME_TARGET_INRANGE_DESC"] = "대상 또는 스킬 범위 안의 유닛 투명도"
L["OPTIONS_ALPHABYFRAME_TITLE_ENEMIES"] = "프레임 별 투명도 설정 (적)"
L["OPTIONS_ALPHABYFRAME_TITLE_FRIENDLY"] = "프레임 별 투명도 설정 (아군)"
L["OPTIONS_AMOUNT"] = "값"
L["OPTIONS_ANCHOR"] = "위치"
L["OPTIONS_ANCHOR_BOTTOM"] = "아래"
L["OPTIONS_ANCHOR_BOTTOMLEFT"] = "왼쪽 아래"
L["OPTIONS_ANCHOR_BOTTOMRIGHT"] = "오른쪽 아래"
L["OPTIONS_ANCHOR_CENTER"] = "가운데"
L["OPTIONS_ANCHOR_INNERBOTTOM"] = "내부 아래"
L["OPTIONS_ANCHOR_INNERLEFT"] = "내부 왼쪽"
L["OPTIONS_ANCHOR_INNERRIGHT"] = "내부 오른쪽"
L["OPTIONS_ANCHOR_INNERTOP"] = "내부 위"
L["OPTIONS_ANCHOR_LEFT"] = "왼쪽"
L["OPTIONS_ANCHOR_RIGHT"] = "오른쪽"
L["OPTIONS_ANCHOR_TARGET_SIDE"] = "이 위젯을 붙일 위치"
L["OPTIONS_ANCHOR_TOP"] = "위"
L["OPTIONS_ANCHOR_TOPLEFT"] = "왼쪽 위"
L["OPTIONS_ANCHOR_TOPRIGHT"] = "오른쪽 위"
L["OPTIONS_AUDIOCUE_COOLDOWN"] = "오디오 재사용 대기시간"
L["OPTIONS_AUDIOCUE_COOLDOWN_DESC"] = "동일한 오디오를 다시 재생하기 전에 대기하는 시간(밀리초)입니다. 두 개 이상의 시전이 동시에 진행될 때 큰 소리가 재생되는 것을 방지합니다. 이 기능을 비활성화하려면 0으로 설정하세요."
L["OPTIONS_AURA_DEBUFF_HEIGHT"] = "디버프 아이콘 세로값."
L["OPTIONS_AURA_DEBUFF_WITH"] = "디버프 아이콘 가로."
L["OPTIONS_AURA_HEIGHT"] = "디버프 아이콘 세로값"
L["OPTIONS_AURA_SHOW_BUFFS"] = "버프 표시"
L["OPTIONS_AURA_SHOW_BUFFS_DESC"] = "개인바에 버프 표시"
L["OPTIONS_AURA_SHOW_DEBUFFS"] = "디버프 표시"
L["OPTIONS_AURA_SHOW_DEBUFFS_DESC"] = "개인바에 디버프 표시"
L["OPTIONS_AURA_WIDTH"] = "디버프 아이콘 너비"
L["OPTIONS_AURAS_ENABLETEST"] = "설정할 때 보이는 테스트 오라를 숨기려면 체크하세요."
L["OPTIONS_AURAS_SORT"] = "오라 정렬"
L["OPTIONS_AURAS_SORT_DESC"] = "오라를 남은 시간(기본값) 기준으로 정렬합니다."
L["OPTIONS_BACKGROUND_ALWAYSSHOW"] = "배경 항상 보기"
L["OPTIONS_BACKGROUND_ALWAYSSHOW_DESC"] = "클릭 가능한 오라 영역을 보여주는 배경을 보여줍니다."
L["OPTIONS_BORDER_COLOR"] = "테두리 색상"
L["OPTIONS_BORDER_THICKNESS"] = "테두리 두께"
L["OPTIONS_BUFFFRAMES"] = "버프 프레임"
L["OPTIONS_CANCEL"] = "취소"
L["OPTIONS_CAST_COLOR_CHANNELING"] = "채널링"
L["OPTIONS_CAST_COLOR_INTERRUPTED"] = "차단됨"
L["OPTIONS_CAST_COLOR_REGULAR"] = "일반"
L["OPTIONS_CAST_COLOR_SUCCESS"] = "성공"
L["OPTIONS_CAST_COLOR_UNINTERRUPTIBLE"] = "차단 불가능"
L["OPTIONS_CAST_SHOW_TARGETNAME"] = "대상 이름 보기"
L["OPTIONS_CAST_SHOW_TARGETNAME_DESC"] = "대상이 존재한다면, 현재 시전의 대상 이름을 표시합니다."
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK"] = "[탱커] 내 이름을 표시하지 않음"
L["OPTIONS_CAST_SHOW_TARGETNAME_TANK_DESC"] = "만일 당신이 탱커라면, 시전 대상이 자신일 때 이름을 표시하지 않습니다."
L["OPTIONS_CASTBAR_APPEARANCE"] = "시전바 외형"
L["OPTIONS_CASTBAR_BLIZZCASTBAR"] = "블리자드 시전바"
L["OPTIONS_CASTBAR_COLORS"] = "시전바 색상"
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED"] = "숨김 애니메이션 활성화"
L["OPTIONS_CASTBAR_FADE_ANIM_ENABLED_DESC"] = "시전 시작과 끝에 애니메이션 효과를 적용합니다."
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END"] = "시전 끝"
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_END_DESC"] = "시전이 끝나면 시전바가 보이지 않게 되는 데 걸리는 시간입니다."
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START"] = "시전 시작"
L["OPTIONS_CASTBAR_FADE_ANIM_TIME_START_DESC"] = "시전이 시작될 때 시전바가 투명도 0에서 완전 불투명으로 전환되는 데 걸리는 시간입니다."
L["OPTIONS_CASTBAR_HEIGHT"] = "시전바의 높이값"
L["OPTIONS_CASTBAR_HIDE_ENEMY"] = "적 시전바 숨김"
L["OPTIONS_CASTBAR_HIDE_FRIENDLY"] = "아군 시전바 숨김"
L["OPTIONS_CASTBAR_HIDEBLIZZARD"] = "블리자드 시전바 숨김"
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE"] = "커스텀 아이콘 사용"
L["OPTIONS_CASTBAR_ICON_CUSTOM_ENABLE_DESC"] = "이 옵션이 해제되면, 스크립트에 의한 커스텀이 적용되지 않습니다."
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT"] = "주문 이름 축약하지 않기"
L["OPTIONS_CASTBAR_NO_SPELLNAME_LIMIT_DESC"] = "주문이름을 시전바 너비에 맞춰 줄이지 않습니다."
L["OPTIONS_CASTBAR_QUICKHIDE"] = "시전바 빠른 숨김"
L["OPTIONS_CASTBAR_QUICKHIDE_DESC"] = "시전이 끝난 후 시전바를 즉시 숨깁니다"
L["OPTIONS_CASTBAR_SPARK_HALF"] = "섬광 텍스쳐 축소"
L["OPTIONS_CASTBAR_SPARK_HALF_DESC"] = "섬광 텍스쳐를 절반만 표시"
L["OPTIONS_CASTBAR_SPARK_HIDE_INTERRUPT"] = "차단 시 섬광 숨김"
L["OPTIONS_CASTBAR_SPARK_SETTINGS"] = "섬광 설정"
L["OPTIONS_CASTBAR_SPELLICON"] = "주문 아이콘"
L["OPTIONS_CASTBAR_TOGGLE_TEST"] = "테스트용 시전바 켜기"
L["OPTIONS_CASTBAR_TOGGLE_TEST_DESC"] = "시전바 테스트 시작, 한번 더 누르면 중지됩니다."
L["OPTIONS_CASTBAR_WIDTH"] = "시전바 너비"
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS"] = "모든 소리 제거"
L["OPTIONS_CASTCOLORS_DISABLE_SOUNDS_CONFIRM"] = "구성된 시전 사운드를 모두 제거하시겠습니까?"
L["OPTIONS_CASTCOLORS_DISABLECOLORS"] = "모든 색상 해제"
L["OPTIONS_CASTCOLORS_DISABLECOLORS_CONFIRM"] = "모든 시전 색상을 비활성화하시겠습니까?"
L["OPTIONS_CLICK_SPACE_HEIGHT"] = "대상을 선택하기 위한 마우스 클릭 영역의 높이값"
L["OPTIONS_CLICK_SPACE_WIDTH"] = "대상을 선택하기 위한 마우스 클릭 영역의 너비값"
L["OPTIONS_COLOR"] = "색상"
L["OPTIONS_COLOR_BACKGROUND"] = "배경 색상"
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR"] = "개인 이름표 표시|cFFFF7700*|r"
L["OPTIONS_CVAR_ENABLE_PERSONAL_BAR_DESC"] = [=[당신의 캐릭터 하단에 작은 체력바와 마나바를 표시합니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW"] = "항상 이름표 표시|cFFFF7700*|r"
L["OPTIONS_CVAR_NAMEPLATES_ALWAYSSHOW_DESC"] = [=[주변의 모든 유닛의 이름표를 표시합니다. 체크해제하면 전투중일 때 관련 유닛만 표시됩니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["OPTIONS_ENABLED"] = "활성화"
L["OPTIONS_ERROR_CVARMODIFY"] = "CVAR 수정"
L["OPTIONS_ERROR_EXPORTSTRINGERROR"] = "내보내기 실패"
L["OPTIONS_EXECUTERANGE"] = "Execute Range"
L["OPTIONS_EXECUTERANGE_DESC"] = [=[Show an indicator when the target unit is in 'execute' range.

패치 후 작동하지 않는다면 Discord에 알려주세요.]=]
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH"] = "Execute Range (high heal)"
L["OPTIONS_EXECUTERANGE_HIGH_HEALTH_DESC"] = [=[Show the execute indicator for the high portion of the health.

패치 후 작동하지 않는다면 Discord에 알려주세요.]=]
L["OPTIONS_FONT"] = "글꼴"
L["OPTIONS_FORMAT_NUMBER"] = "숫자 형식"
L["OPTIONS_FRIENDLY"] = "아군"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_ANCHOR_TITLE"] = "생명력바 모양"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGCOLOR"] = "생명력바 배경 색상/투명도"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_BGTEXTURE"] = "생명력바 배경 텍스쳐"
L["OPTIONS_GENERALSETTINGS_HEALTHBAR_TEXTURE"] = "생명력바 텍스쳐"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_ANCHOR_TITLE"] = "투명도 설정"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK"] = "스킬 범위"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_ALPHA"] = "거리에 따른 투명도"
L["OPTIONS_GENERALSETTINGS_TRANSPARENCY_RANGECHECK_SPEC_DESC"] = "해당 전문화에서 거리를 확인하는 기준이 되는 주문"
L["OPTIONS_HEALTHBAR"] = "이름표"
L["OPTIONS_HEALTHBAR_HEIGHT"] = "이름표 높이값"
L["OPTIONS_HEALTHBAR_SIZE_GLOBAL_DESC"] = [=[전투 중일때와 비전투 중일 때 적과 아군 이름표를 변경합니다.

각 옵션은 적 NPC, 적 플레이어 탭에서 개별적으로 변경할 수 있습니다.]=]
L["OPTIONS_HEALTHBAR_WIDTH"] = "이름표 너비"
L["OPTIONS_HEIGHT"] = "높이"
L["OPTIONS_HOSTILE"] = "적"
L["OPTIONS_ICON_ELITE"] = "정예 아이콘"
L["OPTIONS_ICON_ENEMYCLASS"] = "적 직업 아이콘"
L["OPTIONS_ICON_ENEMYFACTION"] = "적 진영 아이콘"
L["OPTIONS_ICON_ENEMYSPEC"] = "적 전문화 아이콘"
L["OPTIONS_ICON_FRIENDLY_SPEC"] = "아군 전문화 아이콘"
L["OPTIONS_ICON_FRIENDLYCLASS"] = "아군 직업 아이콘"
L["OPTIONS_ICON_FRIENDLYFACTION"] = "아군 진영 아이콘"
L["OPTIONS_ICON_PET"] = "펫 아이콘"
L["OPTIONS_ICON_QUEST"] = "퀘스트 아이콘"
L["OPTIONS_ICON_RARE"] = "레어 아이콘"
L["OPTIONS_ICON_SHOW"] = "아이콘 보기"
L["OPTIONS_ICON_SIDE"] = "Show Side"
L["OPTIONS_ICON_SIZE"] = "크기 보기"
L["OPTIONS_ICON_WORLDBOSS"] = "월드 보스 아이콘"
L["OPTIONS_ICONROWSPACING"] = "아이콘 줄 간격"
L["OPTIONS_ICONSPACING"] = "아이콘 간격"
L["OPTIONS_INDICATORS"] = "Indicators"
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR"] = "게임 객체 이름 색상"
L["OPTIONS_INTERACT_OBJECT_NAME_COLOR_DESC"] = "객체의 이름에 이 색이 적용됩니다."
L["OPTIONS_INTERRUPT_FILLBAR"] = "차단 시 시전바 채우기"
L["OPTIONS_INTERRUPT_SHOW_ANIM"] = "차단 애니메이션 재생"
L["OPTIONS_INTERRUPT_SHOW_AUTHOR"] = "시전 차단한 유저 표시"
L["OPTIONS_MINOR_SCALE_DESC"] = "마이너 유닛의 이름표를 설정합니다. (이 유닛들은 기본 이름표보다 더 작습니다.)"
L["OPTIONS_MINOR_SCALE_HEIGHT"] = "마이너 유닛 세로 비율"
L["OPTIONS_MINOR_SCALE_WIDTH"] = "마이너 유닛 가로 비율"
L["OPTIONS_MOVE_HORIZONTAL"] = "수평 이동"
L["OPTIONS_MOVE_VERTICAL"] = "수직 이동"
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH"] = "블리자드 이름표 숨김|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_HIDE_FRIENDLY_HEALTH_DESC"] = [=[던전이나 레이드에서, 아군 이름표가 켜져있다면 플레이어 이름을 보여줍니다.
Plater 모듈이 해제되면 이름표에도 영향을 줍니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r

|cFFFF2200[*]|r |cFFa0a0a0명령어 /rl을 입력해야 적용됩니다.|r]=]
L["OPTIONS_NAMEPLATE_OFFSET"] = "이름표 설정"
L["OPTIONS_NAMEPLATE_SHOW_ENEMY"] = "적 이름표 보기|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_SHOW_ENEMY_DESC"] = [=[적과 중립 유닛의 이름표를 표시합니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY"] = "아군 이름표 보기|cFFFF7700*|r"
L["OPTIONS_NAMEPLATE_SHOW_FRIENDLY_DESC"] = [=[아군 이름표 표시.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["OPTIONS_NAMEPLATES_OVERLAP"] = "이름표 중첩 (수직)|cFFFF7700*|r"
L["OPTIONS_NAMEPLATES_OVERLAP_DESC"] = [=[중첩 옵션을 사용할 때 수직 간격 값입니다.

|cFFFFFFFF기본값: 1.10|r

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r

|cFFFFFF00Important |r: 이 설정에서 문제가 발생하면 아래 명령어 사용:
|cFFFFFFFF/run SetCVar ('nameplateOverlapV', '1.6')|r]=]
L["OPTIONS_NAMEPLATES_STACKING"] = "이름표 중첩|cFFFF7700*|r"
L["OPTIONS_NAMEPLATES_STACKING_DESC"] = [=[체크하면 이름표가 겹치지 않습니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r

|cFFFFFF00중요 |r: 여러 이름표 사이의 공간을 설정하려면 아래 '|cFFFFFFFF이름표 수직 간격|r'옵션을 확인하세요.
이 옵션의 자동 전환을 설정하려면 자동 탭 설정을 확인하십시오.]=]
L["OPTIONS_NEUTRAL"] = "중립"
L["OPTIONS_NOCOMBATALPHA_AMOUNT_DESC"] = "'비전투 투명도'의 전체 투명도 값"
L["OPTIONS_NOCOMBATALPHA_ENABLED"] = "비전투 투명도 적용"
L["OPTIONS_NOCOMBATALPHA_ENABLED_DESC"] = [=[당신이 전투중일 때, 전투중이 아닌 유닛에 투명도를 적용합니다.

|cFFFFFF00 중요 |r:만일 유닛이 전투중이 아니라면, 범위 설정에 따라 투명도가 적용됩니다.]=]
L["OPTIONS_NOESSENTIAL_DESC"] = [=[일반적으로 Plater를 업데이트할 때 스크립트도 업데이트됩니다. 프로필 제작자가 만든 설정이 기존 설정을 덮어쓸 수도 있습니다.
아래 옵션은 업데이트를 받을 때 기존 스크립트를 수정하지 않도록 합니다.

참고: 주요 패치 및 버그 수정으로 Plater 스크립트는 계속 업데이트 될 수 있습니다.]=]
L["OPTIONS_NOESSENTIAL_NAME"] = "Plater 버전 업그레이드 중에 필수가 아닌 스크립트는 업데이트하지 않도록 설정합니다."
L["OPTIONS_NOESSENTIAL_SKIP_ALERT"] = "필수가 아닌 패치 무시:"
L["OPTIONS_NOESSENTIAL_TITLE"] = "필수가 아닌 패치 무시"
L["OPTIONS_NOTHING_TO_EXPORT"] = "내보내기 할 데이터가 없습니다."
L["OPTIONS_OKAY"] = "확인"
L["OPTIONS_OUTLINE"] = "외곽선"
L["OPTIONS_PERSONAL_HEALTHBAR_HEIGHT"] = "이름표의 세로값"
L["OPTIONS_PERSONAL_HEALTHBAR_WIDTH"] = "이름표의 가로값"
L["OPTIONS_PERSONAL_SHOW_HEALTHBAR"] = "이름표 표시"
L["OPTIONS_PET_SCALE_DESC"] = "펫 이름표에 대한 설정"
L["OPTIONS_PET_SCALE_HEIGHT"] = "펫 이름표 세로 비율"
L["OPTIONS_PET_SCALE_WIDTH"] = "펫 이름표 가로 비율"
L["OPTIONS_PLEASEWAIT"] = "잠시 기다려주세요"
L["OPTIONS_POWERBAR"] = "자원바"
L["OPTIONS_POWERBAR_HEIGHT"] = "자원바의 높이"
L["OPTIONS_POWERBAR_WIDTH"] = "자원바의 너비"
L["OPTIONS_PROFILE_CONFIG_EXPORTINGTASK"] = "현재 프로필을 내보내는 중입니다."
L["OPTIONS_PROFILE_CONFIG_EXPORTPROFILE"] = "프로필 내보내기"
L["OPTIONS_PROFILE_CONFIG_IMPORTPROFILE"] = "프로필 가져오기"
L["OPTIONS_PROFILE_CONFIG_MOREPROFILES"] = "Wago.io에서 더 많은 프로필들을 만나보세요."
L["OPTIONS_PROFILE_CONFIG_OPENSETTINGS"] = "프로필 설정 열기"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME"] = "새 프로필명"
L["OPTIONS_PROFILE_CONFIG_PROFILENAME_DESC"] = "새 프로필을 가져온 문자열로 만듭니다. 이미 존재하는 프로필 이름을 입력하면 덮어씁니다."
L["OPTIONS_PROFILE_ERROR_PROFILENAME"] = "부적합한 프로필명입니다."
L["OPTIONS_PROFILE_ERROR_STRINGINVALID"] = "부적합한 프로필 문자열입니다."
L["OPTIONS_PROFILE_ERROR_WRONGTAB"] = "잘못된 프로필입니다. 스크립트나 모드 탭에서 가져오세요."
L["OPTIONS_PROFILE_IMPORT_OVERWRITE"] = "'%s' 프로필은 이미 존재합니다. 덮어쓰시겠습니까?"
L["OPTIONS_RANGECHECK_NONE"] = "설정 안함"
L["OPTIONS_RANGECHECK_NONE_DESC"] = "투명도를 설정하지 않습니다."
L["OPTIONS_RANGECHECK_NOTMYTARGET"] = "대상이 아닌 유닛"
L["OPTIONS_RANGECHECK_NOTMYTARGET_DESC"] = "현재 대상이 아닌 이름표를 투명하게 합니다."
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE"] = "범위 밖 + 대상이 아닌 유닛"
L["OPTIONS_RANGECHECK_NOTMYTARGETOUTOFRANGE_DESC"] = [=[대상이 아닌 유닛의 투명도 감소.
범위 밖일 때 더 투명해집니다.]=]
L["OPTIONS_RANGECHECK_OUTOFRANGE"] = "거리가 먼 유닛"
L["OPTIONS_RANGECHECK_OUTOFRANGE_DESC"] = "범위 밖일 때 투명도를 적용합니다."
L["OPTIONS_RESOURCES_TARGET"] = "대상에 자원 표시"
L["OPTIONS_RESOURCES_TARGET_DESC"] = [=[현재 대상 위에 콤보 포인트같은 자신의 리소스를 표시합니다.
자원은 Plater 설정이 아닌 블리자드 기본값을 사용합니다.

Character specific setting!]=]
L["OPTIONS_SCALE"] = "창 크기"
L["OPTIONS_SCRIPTING_ADDOPTION"] = "추가할 옵션 선택"
L["OPTIONS_SCRIPTING_REAPPLY"] = "기본값 다시 적용"
L["OPTIONS_SETTINGS_COPIED"] = "설정이 복사되었습니다."
L["OPTIONS_SETTINGS_FAIL_COPIED"] = "현재 선택된 탭의 설정을 가져오지 못했습니다."
L["OPTIONS_SHADOWCOLOR"] = "그림자 색상"
L["OPTIONS_SHIELD_BAR"] = "보호막 표시"
L["OPTIONS_SHOW_CASTBAR"] = "시전바 표시"
L["OPTIONS_SHOW_POWERBAR"] = "자원바 표시"
L["OPTIONS_SHOWOPTIONS"] = "옵션 보기"
L["OPTIONS_SHOWSCRIPTS"] = "스크립트 보기"
L["OPTIONS_SHOWTOOLTIP"] = "툴팁 표시"
L["OPTIONS_SHOWTOOLTIP_DESC"] = "오라 아이콘에 마우스 올릴 때 툴팁 보기"
L["OPTIONS_SIZE"] = "크기"
L["OPTIONS_STACK_AURATIME"] = "중첩된 오라의 가장 짧은 시간 표시"
L["OPTIONS_STACK_AURATIME_DESC"] = "중첩된 오라의 가장 짧은 시간을 표시합니다. 비활성화하면 가장 긴 시간을 표시합니다."
L["OPTIONS_STACK_SIMILAR_AURAS"] = "유사한 오라 중첩"
L["OPTIONS_STACK_SIMILAR_AURAS_DESC"] = "이름이 같은 오라가 중첩됩니다. (예를들면 흑마의 불안정한 고통)"
L["OPTIONS_STATUSBAR_TEXT"] = "이제 |cFFFFAA00http://wago.io|r에서 프로필, 모드, 스크립트, 애니메이션 및 색상표를 가져올 수 있습니다."
L["OPTIONS_TABNAME_ADVANCED"] = "상세"
L["OPTIONS_TABNAME_ANIMATIONS"] = "애니메이션"
L["OPTIONS_TABNAME_AUTO"] = "자동"
L["OPTIONS_TABNAME_BUFF_LIST"] = "효과 목록"
L["OPTIONS_TABNAME_BUFF_SETTINGS"] = "효과 설정"
L["OPTIONS_TABNAME_BUFF_SPECIAL"] = "효과 특수"
L["OPTIONS_TABNAME_BUFF_TRACKING"] = "효과 추적"
L["OPTIONS_TABNAME_CASTBAR"] = "시전바"
L["OPTIONS_TABNAME_CASTCOLORS"] = "시전 색상 및 이름"
L["OPTIONS_TABNAME_COMBOPOINTS"] = "연계 점수"
L["OPTIONS_TABNAME_GENERALSETTINGS"] = "일반"
L["OPTIONS_TABNAME_MODDING"] = "모드"
L["OPTIONS_TABNAME_NPC_COLORNAME"] = "NPC 색상 및 이름"
L["OPTIONS_TABNAME_NPCENEMY"] = "적 NPC"
L["OPTIONS_TABNAME_NPCFRIENDLY"] = "아군 NPC"
L["OPTIONS_TABNAME_PERSONAL"] = "개인 자원 바"
L["OPTIONS_TABNAME_PLAYERENEMY"] = "적 플레이어"
L["OPTIONS_TABNAME_PLAYERFRIENDLY"] = "아군 플레이어 "
L["OPTIONS_TABNAME_PROFILES"] = "프로필"
L["OPTIONS_TABNAME_SCRIPTING"] = "스크립트"
L["OPTIONS_TABNAME_SEARCH"] = "검색"
L["OPTIONS_TABNAME_STRATA"] = "프레임 우선순위"
L["OPTIONS_TABNAME_TARGET"] = "대상"
L["OPTIONS_TABNAME_THREAT"] = "위협 수준 / 어그로"
L["OPTIONS_TEXT_COLOR"] = "색상"
L["OPTIONS_TEXT_FONT"] = "폰트"
L["OPTIONS_TEXT_SIZE"] = "크기"
L["OPTIONS_TEXTURE"] = "텍스쳐"
L["OPTIONS_TEXTURE_BACKGROUND"] = "배경 텍스쳐"
L["OPTIONS_THREAT_AGGROSTATE_ANOTHERTANK"] = "다른 탱커에 어그로"
L["OPTIONS_THREAT_AGGROSTATE_HIGHTHREAT"] = "위협 수준 높음"
L["OPTIONS_THREAT_AGGROSTATE_NOAGGRO"] = "위협 수준 없음"
L["OPTIONS_THREAT_AGGROSTATE_NOTANK"] = "탱커 어그로 없음"
L["OPTIONS_THREAT_AGGROSTATE_NOTINCOMBAT"] = "전투 중이지 않은 유닛"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO"] = "낮은 위협 수준"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_LOWAGGRO_DESC"] = "당신이 어그로를 갖고 있지만, 다른 대상에게 위협 수준이 전이 중인 유닛"
L["OPTIONS_THREAT_AGGROSTATE_ONYOU_SOLID"] = "당신에게 어그로"
L["OPTIONS_THREAT_AGGROSTATE_TAPPED"] = "선점된 유닛"
L["OPTIONS_THREAT_CLASSIC_USE_TANK_COLORS"] = "Use Tank Threat Colors"
L["OPTIONS_THREAT_COLOR_DPS_ANCHOR_TITLE"] = "딜러나 힐러를 플레이할 시의 위협 수준 색상"
L["OPTIONS_THREAT_COLOR_DPS_HIGHTHREAT_DESC"] = "곧 당신을 공격하게 될 유닛 "
L["OPTIONS_THREAT_COLOR_DPS_NOAGGRO_DESC"] = "당신을 공격하지 않고 있는 유닛"
L["OPTIONS_THREAT_COLOR_DPS_NOTANK_DESC"] = "당신이나 탱커를 공격하고 있지 않지만, 다른 파티원을 공격중인 유닛"
L["OPTIONS_THREAT_COLOR_DPS_ONYOU_SOLID_DESC"] = "당신을 공격하고 있는 유닛"
L["OPTIONS_THREAT_COLOR_OVERRIDE_ANCHOR_TITLE"] = "기존 색상 덮어씀"
L["OPTIONS_THREAT_COLOR_OVERRIDE_DESC"] = "게임 내의 중립, 적대적 그리고 우호적 유닛의 색상을 설정합니다. 전투 중에는, 위협 수준 색상으로 덮어씌워집니다."
L["OPTIONS_THREAT_COLOR_TANK_ANCHOR_TITLE"] = "탱커로 플레이할 시의 위협 수준 색상"
L["OPTIONS_THREAT_COLOR_TANK_ANOTHERTANK_DESC"] = "다른 탱커에 의해서 탱킹되고 있는 유닛"
L["OPTIONS_THREAT_COLOR_TANK_NOAGGRO_DESC"] = "당신에게 어그로가 없는 유닛"
L["OPTIONS_THREAT_COLOR_TANK_NOTINCOMBAT_DESC"] = "전투 중이지 않은 유닛"
L["OPTIONS_THREAT_COLOR_TANK_ONYOU_SOLID_DESC"] = "당신이 탱킹하고 있으며 당신을 공격하고 있는 유닛"
L["OPTIONS_THREAT_COLOR_TAPPED_DESC"] = "다른 사람에 의해 선점된 유닛(유닛으로부터 루팅이나 경험치를 얻지 못함)"
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK"] = "탱커에 위협 수준 없을 시 색상"
L["OPTIONS_THREAT_DPS_CANCHECKNOTANK_DESC"] = "당신이 딜러/힐러를 플레이할 때, 탱커에 어그로가 있지만 탱커가 아닌 다른 대상을 공격하는 유닛"
L["OPTIONS_THREAT_MODIFIERS_ANCHOR_TITLE"] = "위협 수준이 다음을 변경"
L["OPTIONS_THREAT_MODIFIERS_BORDERCOLOR"] = "테두리 색상"
L["OPTIONS_THREAT_MODIFIERS_HEALTHBARCOLOR"] = "생명력바 색상"
L["OPTIONS_THREAT_MODIFIERS_NAMECOLOR"] = "이름 색상"
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK"] = "다른 탱커가 풀링할 때"
L["OPTIONS_THREAT_PULL_FROM_ANOTHER_TANK_TANK"] = "다른 탱커가 위협을 가지고 있을 때"
L["OPTIONS_THREAT_USE_AGGRO_FLASH"] = "어그로 효과(flash) 적용"
L["OPTIONS_THREAT_USE_AGGRO_FLASH_DESC"] = "딜러 역할로 위협을 생성했을 때 Flash 효과를 표시합니다."
L["OPTIONS_THREAT_USE_AGGRO_GLOW"] = "어그로 효과(glow) 적용"
L["OPTIONS_THREAT_USE_AGGRO_GLOW_DESC"] = "딜러 역할로 위협을 생성하거나 탱커 역할로 위협을 잃어버렸을 때 Glow 효과를 표시합니다."
L["OPTIONS_THREAT_USE_SOLO_COLOR"] = "솔플일 때 색상"
L["OPTIONS_THREAT_USE_SOLO_COLOR_DESC"] = "파티가 아닐 때 솔플 색상을 사용합니다."
L["OPTIONS_THREAT_USE_SOLO_COLOR_ENABLE"] = "'솔플' 색상 사용"
L["OPTIONS_TOGGLE_TO_CHANGE"] = "|cFFFFFF00 중요 |r: 차이점을 보려면 이름표를 껐다가 다시 켜보세요."
L["OPTIONS_WIDTH"] = "너비"
L["OPTIONS_XOFFSET"] = "X 좌표"
L["OPTIONS_XOFFSET_DESC"] = [=[X 축 값을 설정합니다.

*우클릭으로 값을 입력할 수 있습니다.]=]
L["OPTIONS_YOFFSET"] = "Y 좌표"
L["OPTIONS_YOFFSET_DESC"] = [=[Y 축 값을 설정합니다.

*우클릭으로 값을 입력할 수 있습니다.]=]
L[ [=[Show nameplate for friendly npcs.

|cFFFFFF00 Important |r: This option is dependent on the client`s nameplate state (on/off).

|cFFFFFF00 Important |r: when disabled but enabled on the client through (%s), the healthbar isn't visible but the nameplate is still clickable.]=] ] = "아군 NPC의 이름표를 표시합니다. |cFFFFFF00 중요 |r: 이 옵션은 클라이언트의 이름표 상태(켜짐/꺼짐)에 따라 달라집니다. |cFFFFFF00 중요 |r: 비활성화되어 있지만 클라이언트에서 (%s)를 통해 활성화된 경우, 체력바는 보이지 않지만 이름표는 여전히 클릭할 수 있습니다."
L["TARGET_CVAR_ALWAYSONSCREEN"] = "대상을 항상 화면안에 표시|cFFFF7700*|r"
L["TARGET_CVAR_ALWAYSONSCREEN_DESC"] = [=[체크하면 대상이 화면밖일 때에도 이름표가 항상 화면안에 보이도록 합니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["TARGET_CVAR_LOCKTOSCREEN"] = "화면안에 잠금(화면 상단)|cFFFF7700*|r"
L["TARGET_CVAR_LOCKTOSCREEN_DESC"] = [=[이름표와 화면 상단의 최소 공간. 이름표의 일부가 화면밖으로 나간다면 이 값을 늘리세요.

|cFFFFFFFFDefault: 0.065|r

|cFFFFFF00 중요 |r: 문제가 생긴다면 아래 매크로를 직접 사용하세요:
/run SetCVar ('nameplateOtherTopInset', '0.065')
/run SetCVar ('nameplateLargeTopInset', '0.065')

|cFFFFFF00 Important |r: 설정값이 0일때는 설정이 적용되지 않습니다.

|cFFFF7700[*]|r |cFFa0a0a0CVar는 Plater 프로필에 저장되었다가 프로필을 불러올때 복원됩니다.|r]=]
L["TARGET_HIGHLIGHT"] = "대상 하이라이트"
L["TARGET_HIGHLIGHT_ALPHA"] = "대상 하이라이트 투명도"
L["TARGET_HIGHLIGHT_COLOR"] = "대상 하이라이트 색상"
L["TARGET_HIGHLIGHT_DESC"] = "현재 대상의 이름표에 하이라이트 효과를 적용합니다."
L["TARGET_HIGHLIGHT_SIZE"] = "대상 하이라이트 크기"
L["TARGET_HIGHLIGHT_TEXTURE"] = "대상 하이라이트 텍스쳐"
L["TARGET_OVERLAY_ALPHA"] = "대상 오버레이 투명도"
L["TARGET_OVERLAY_TEXTURE"] = "대상 오버레이 텍스쳐"
L["TARGET_OVERLAY_TEXTURE_DESC"] = "현재 대상의 이름표에 마우스를 올렸을 때 사용되는 효과입니다."

end