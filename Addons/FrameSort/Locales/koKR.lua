local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "koKR" then
    return
end

-- # Main Options screen #
L["FrameSort - %s"] = "프레임정렬 - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "프레임정렬이 제대로 작동하지 못하도록 하는 문제가 있습니다."
L["Please go to the Health Check panel to view more details."] = "더 많은 세부정보를 보려면 건강 검사 패널로 이동하십시오."
L["Role/spec"] = "역할/전문화"
L["Group"] = "그룹"
L["Alphabetical"] = "알파벳순"
L["Arena - 2v2"] = "아레나 - 2v2"
L["Arena - 3v3"] = "아레나 - 3v3"
L["Arena - 3v3 & 5v5"] = "아레나 - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "적 아레나 (지원되는 애드온은 애드온 패널을 참조하십시오)"
L["Dungeon (mythics, 5-mans, delves)"] = "던전 (신화, 5인, 탐사)"
L["Raid (battlegrounds, raids)"] = "공격대 (전투 지역, 공략)"
L["World (non-instance groups)"] = "월드 (비인스턴스 그룹)"
L["Player"] = "플레이어"
L["Sort"] = "정렬"
L["Top"] = "상위"
L["Middle"] = "중간"
L["Bottom"] = "하위"
L["Hidden"] = "숨김"
L["Group"] = "그룹"
L["Reverse"] = "역순"

-- # Sorting Method screen #
L["Sorting Method"] = "정렬 방법"
L["Secure"] = "보안"
L["SortingMethod_Secure_Description"] = [[
각 개별 프레임의 위치를 조정하고 UI를 버그/잠금/오염하지 않습니다.
\n
장점:
 - 다른 애드온의 프레임을 정렬할 수 있습니다.
 - 프레임 간격을 적용할 수 있습니다.
 - 오염 없음 (블리자드의 UI 코드에 간섭하는 애드온의 기술 용어).
\n
단점:
 - 블리자드의 복잡한 코드를 우회하기 위한 취약한 카드 집합 상황.
 - WoW 패치와 함께 깨질 수 있으며 개발자를 미치게 만들 수 있습니다.
]]
L["Traditional"] = "전통적인"
L["SortingMethod_Traditional_Description"] = [[
이것은 애드온과 매크로가 10년 이상 사용해온 표준 정렬 모드입니다.
내부 블리자드 정렬 방법을 우리의 것으로 대체합니다.
이는 'SetFlowSortFunction' 스크립트와 동일하지만 프레임정렬 구성이 포함되어 있습니다.
\n
장점:
 - 블리자드의 내부 정렬 방법을 활용하므로 더 안정적이고 신뢰할 수 있습니다.
\n
단점:
 - 블리자드 파티 프레임만 정렬하며 그 외에는 없습니다.
 - Lua 오류를 발생시킬 수 있으며 이는 정상적이며 무시할 수 있습니다.
 - 프레임 간격을 적용할 수 없습니다.
]]
L["Please reload after changing these settings."] = "이 설정을 변경한 후 다시 로드하십시오."
L["Reload"] = "다시 로드"

-- # Ordering screen #
L["Ordering"] = "정렬"
L["Specify the ordering you wish to use when sorting by role."] = "역할에 따라 정렬할 때 사용할 순서를 지정하십시오."
L["Tanks"] = "탱커"
L["Healers"] = "치유사"
L["Casters"] = "시전자"
L["Hunters"] = "사냥꾼"
L["Melee"] = "근접"

-- # Auto Leader screen #
L["Auto Leader"] = "자동 리더"
L["Auto promote healers to leader in solo shuffle."] = "솔로 셔플에서 치유사를 자동으로 리더로 승격합니다."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "왜냐하면 치유사가 대상 마커 아이콘을 구성하고 파티1/2의 순서를 그들의 선호에 맞게 조정할 수 있기 때문입니다."
L["Enabled"] = "활성화"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "대상 지정"
L["Target frame 1 (top frame)"] = "대상 프레임 1 (상위 프레임)"
L["Target frame 2"] = "대상 프레임 2"
L["Target frame 3"] = "대상 프레임 3"
L["Target frame 4"] = "대상 프레임 4"
L["Target frame 5"] = "대상 프레임 5"
L["Target bottom frame"] = "대상 하단 프레임"
L["Target 1 frame above bottom"] = "하단 위 1번째 프레임을 대상"
L["Target 2 frames above bottom"] = "하단 위 2번째 프레임을 대상"
L["Target 3 frames above bottom"] = "하단 위 3번째 프레임을 대상"
L["Target 4 frames above bottom"] = "하단 위 4번째 프레임을 대상"
L["Target frame 1's pet"] = "대상 프레임 1의 애완동물"
L["Target frame 2's pet"] = "대상 프레임 2의 애완동물"
L["Target frame 3's pet"] = "대상 프레임 3의 애완동물"
L["Target frame 4's pet"] = "대상 프레임 4의 애완동물"
L["Target frame 5's pet"] = "대상 프레임 5의 애완동물"
L["Target enemy frame 1"] = "적 프레임 1을 대상 지정"
L["Target enemy frame 2"] = "적 프레임 2를 대상 지정"
L["Target enemy frame 3"] = "적 프레임 3을 대상 지정"
L["Target enemy frame 1's pet"] = "적 프레임 1의 애완동물을 대상 지정"
L["Target enemy frame 2's pet"] = "적 프레임 2의 애완동물을 대상 지정"
L["Target enemy frame 3's pet"] = "적 프레임 3의 애완동물을 대상 지정"
L["Focus enemy frame 1"] = "적 프레임 1에 집중"
L["Focus enemy frame 2"] = "적 프레임 2에 집중"
L["Focus enemy frame 3"] = "적 프레임 3에 집중"
L["Cycle to the next frame"] = "다음 프레임으로 순환"
L["Cycle to the previous frame"] = "이전 프레임으로 순환"
L["Target the next frame"] = "다음 프레임을 대상 지정"
L["Target the previous frame"] = "이전 프레임을 대상 지정"

-- # Keybindings screen #
L["Keybindings"] = "키 바인딩"
L["Keybindings_Description"] = [[
프레임정렬 키 바인딩은 표준 WoW 키 바인딩 영역에서 찾을 수 있습니다.
\n
키 바인딩은 무엇에 유용합니까?
이것은 파티 위치(party1/2/3/etc.)가 아닌 시각적으로 정렬된 표현에 따라 플레이어를 대상으로 하는 데 유용합니다.
\n
예를 들어 역할에 따라 정렬된 5인 던전 그룹을 상상해 보십시오:
  - 탱커, 파티3
  - 치유사, 플레이어
  - DPS, 파티1
  - DPS, 파티4
  - DPS, 파티2
\n
보시다시피, 그들의 시각적 표현은 실제 파티 위치와 다르기 때문에 대상 지정이 혼란스럽습니다.
만약 /target party1을 입력하면, 타겟은 3위의 DPS 플레이어가 아닌 탱커가 됩니다.
\n
프레임정렬 키 바인딩은 파티 번호가 아닌 시각적 프레임 위치에 따라 대상을 지정합니다.
따라서 '프레임 1'은 탱커를, '프레임 2'는 치유사를, '프레임 3'은 3위의 DPS를 대상으로 합니다.
]]

-- # Macros screen # --
L["Macros"] = "매크로"
L["FrameSort has found %d |4macro:macros; to manage."] = "프레임정렬이 관리할 %d |4macro:매크로;을(를) 발견했습니다."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = "프레임정렬은 '#FrameSort' 헤더를 포함하는 매크로 내에서 변수를 동적으로 업데이트합니다."
L["Below are some examples on how to use this."] = "이를 사용하는 방법에 대한 몇 가지 예입니다."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] 성역의 축복]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] 해제]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] 그림자 걸음;
/cast [@placeholder] 차단;]]

L["Example %d"] = "예제 %d"
L["Supported variables:"] = "지원되는 변수:"
L["The first DPS that's not you."] = "당신이 아닌 첫 번째 DPS."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "번호를 추가하여 N번째 대상을 선택합니다. 예: DPS2는 2번째 DPS를 선택합니다."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "변수는 대소문자를 구분하지 않으므로 'fRaMe1', 'Dps', 'enemyhealer' 등이 모두 작동합니다."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "매크로 문자 수를 줄여야 할까요? 약어를 사용하여 줄이십시오:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = '"X"를 사용하여 프레임정렬에게 @unit 선택기를 무시하라고 지시하십시오.'

L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] 주문;]]

-- # Spacing screen #
L["Spacing"] = "간격"
L["Add some spacing between party, raid, and arena frames."] = "파티/공격대 프레임 간의 간격을 추가합니다."
L["This only applies to Blizzard frames."] = "이것은 블리자드 프레임에만 적용됩니다."
L["Party"] = "파티"
L["Raid"] = "공격대"
L["Group"] = "그룹"
L["Horizontal"] = "수평"
L["Vertical"] = "수직"

-- # Addons screen #
L["Addons"] = "애드온"
L["Addons_Supported_Description"] = [[
프레임정렬은 다음을 지원합니다:
\n
블리자드
 - 파티: 예
 - 공격대: 예
 - 아레나: 예
\n
ElvUI
 - 파티: 예
 - 공격대: 아니오
 - 아레나: 아니오
\n
sArena
 - 아레나: 예
\n
Gladius
 - 아레나: 예
 - Bicmex 버전: 예
\n
GladiusEx
 - 파티: 예
 - 아레나: 예
\n
Cell
 - 파티: 예
 - 공격대: 예, 복합 그룹을 사용할 때만.
\n
Shadowed Unit Frames
 - 파티: 예
 - 아레나: 예
\n
Grid2
 - 파티/공격대: 예
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "프레임정렬을 애드온, 스크립트 및 약한 오라에 통합하시겠습니까?"
L["Here are some examples."] = "다음은 몇 가지 예입니다."
L["Retrieved an ordered array of party/raid unit tokens."] = "파티/공격대 유닛 토큰의 정렬된 배열을 가져왔습니다."
L["Retrieved an ordered array of arena unit tokens."] = "아레나 유닛 토큰의 정렬된 배열을 가져왔습니다."
L["Register a callback function to run after FrameSort sorts frames."] = "프레임정렬이 프레임을 정렬한 후 실행할 콜백 함수를 등록합니다."
L["Retrieve an ordered array of party frames."] = "파티 프레임의 정렬된 배열을 가져옵니다."
L["Change a FrameSort setting."] = "프레임정렬 설정을 변경합니다."
L["View a full listing of all API methods on GitHub."] = "GitHub에서 모든 API 메서드의 전체 목록을 확인합니다."

-- # Help screen #
L["Help"] = "도움"
L["Discord"] = "디스코드"
L["Need help with something?"] = "무언가 도움이 필요하십니까?"
L["Talk directly with the developer on Discord."] = "디스코드에서 개발자와 직접 이야기하십시오."

-- # Health Check screen -- #
L["Health Check"] = "건강 검사"
L["Try this"] = "다음을 시도해 보십시오"
L["Any known issues with configuration or conflicting addons will be shown below."] = "구성 또는 충돌하는 애드온과 관련된 알려진 문제는 아래에 표시됩니다."
L["N/A"] = "해당 없음"
L["Passed!"] = "통과!"
L["Failed"] = "실패"
L["(unknown)"] = "(알 수 없음)"
L["(user macro)"] = "(사용자 매크로)"
L["Using grouped layout for Cell raid frames"] = "Cell 공격대 프레임에 대해 그룹 레이아웃을 사용합니다."
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Cell -> 레이아웃에서 '결합 그룹 (공격대)' 옵션을 확인하십시오."
L["Can detect frames"] = "프레임을 감지할 수 있습니다."
L["FrameSort currently supports frames from these addons: %s"] = "프레임정렬은 현재 다음 애드온의 프레임을 지원합니다: %s"
L["Using Raid-Style Party Frames"] = "공격대 스타일 파티 프레임 사용"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "블리자드 설정에서 '공격대 스타일 파티 프레임 사용'을 활성화하십시오."
L["Keep Groups Together setting disabled"] = "그룹 유지 설정이 비활성화되었습니다."
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "편집 모드를 통해 공격대 표시 모드를 '결합 그룹' 옵션 중 하나로 변경하십시오."
L["Disable the 'Keep Groups Together' raid profile setting."] = "'그룹 유지' 공격대 프로필 설정을 비활성화합니다."
L["Only using Blizzard frames with Traditional mode"] = "전통 모드에서 블리자드 프레임만 사용하고 있습니다."
L["Traditional mode can't sort your other frame addons: '%s'"] = "전통 모드는 당신의 다른 프레임 애드온을 정렬할 수 없습니다: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "간격이 사용될 때 보안 정렬 모드를 사용하고 있습니다."
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "전통 모드는 간격을 적용할 수 없으므로 간격을 제거하거나 보안 정렬 방법을 사용하는 것을 고려하십시오."
L["Blizzard sorting functions not tampered with"] = "블리자드 정렬 함수가 손상되지 않았습니다."
L['"%s" may cause conflicts, consider disabling it'] = '"%s"가 충돌을 일으킬 수 있으므로 비활성화하는 것을 고려하십시오.'
L["No conflicting addons"] = "충돌하는 애드온 없음"
L["Main tank and assist setting disabled"] = "주탱과 보조 설정이 비활성화되었습니다."
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "옵션 -> 인터페이스 -> 공격대 프레임에서 '주탱과 보조 표시' 옵션을 비활성화하십시오."
