local _, addon = ...
local L = addon.Locale.koKR

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "FrameSort가 제대로 작동하지 못하게 할 수 있는 몇 가지 문제가 있습니다."
L["Please go to the Health Check panel to view more details."] = "자세한 내용은 상태 점검 패널에서 확인하세요."
L["Role"] = "역할"
L["Spec"] = "전문화"
L["Group"] = "그룹"
L["Alphabetical"] = "알파벳순"
L["Arena - 2v2"] = "투기장 - 2대2"
L["Arena - 3v3"] = "투기장 - 3대3"
L["Arena - 3v3 & 5v5"] = "투기장 - 3대3 & 5대5"
L["Enemy Arena (see addons panel for supported addons)"] = "적 투기장(지원 애드온은 애드온 패널 참조)"
L["Dungeon (mythics, 5-mans, delves)"] = "던전(신화, 5인, Delves)"
L["Raid (battlegrounds, raids)"] = "공격대(전장, 공격대)"
L["World (non-instance groups)"] = "야외(비인스턴스 파티)"
L["Player"] = "플레이어"
L["Sort"] = "정렬"
L["Top"] = "위쪽"
L["Middle"] = "가운데"
L["Bottom"] = "아래쪽"
L["Hidden"] = "숨김"
L["Group"] = "그룹"
L["Reverse"] = "역순"

-- # Sorting Method screen #
L["Sorting Method"] = "정렬 방식"
L["Secure"] = "보안"
L["SortingMethod_Secure_Description"] = [[
각 개별 프레임의 위치를 조정하며 UI에 버그/잠김/오염(taint)이 발생하지 않습니다.
\n
장점:
 - 다른 애드온의 프레임도 정렬할 수 있습니다.
 - 프레임 간 간격을 적용할 수 있습니다.
 - 오염(블리자드의 UI 코드에 애드온이 간섭하는 현상을 뜻하는 기술 용어)이 없습니다.
\n
단점:
 - 블리자드의 스파게티 같은 구조를 우회하기 위한 위태로운 카드 탑과 같은 방식입니다.
 - WoW 패치로 깨질 수 있으며 개발자를 미치게 만들 수 있습니다.
]]
L["Traditional"] = "전통적"
L["SortingMethod_Traditional_Description"] = [[
이는 10년 이상 애드온과 매크로에서 사용해 온 표준 정렬 모드입니다.
블리자드의 내부 정렬 방식을 우리의 방식으로 교체합니다.
FrameSort 설정이 추가된 'SetFlowSortFunction' 스크립트와 동일합니다.
\n
장점:
 - 블리자드의 내부 정렬 방식을 활용하므로 더 안정적이고 신뢰할 수 있습니다.
\n
단점:
 - 블리자드 파티 프레임만 정렬하며, 그 외는 불가합니다.
 - Lua 오류가 발생할 수 있으며, 정상적인 현상이므로 무시해도 됩니다.
 - 프레임 간 간격을 적용할 수 없습니다.
]]
L["Please reload after changing these settings."] = "이 설정을 변경한 후에는 UI를 다시 불러오세요."
L["Reload"] = "리로드"

-- # Ordering screen #
L["Ordering"] = "정렬"
L["Specify the ordering you wish to use when sorting by spec."] = "전문화 기준으로 정렬할 때 사용할 순서를 지정하세요."
L["Tanks"] = "탱커"
L["Healers"] = "힐러"
L["Casters"] = "원거리 캐스터"
L["Hunters"] = "사냥꾼"
L["Melee"] = "근접"

-- # Spec Priority screen # --
L["Spec Priority"] = "전문화 우선순위"
L["Spec Type"] = "전문화 유형"
L["Choose a spec type, then drag and drop to control priority."] = "전문화 유형을 선택한 후 드래그 앤 드롭으로 우선순위를 조정하세요."
L["Tank"] = "방어 전담"
L["Healer"] = "치유 전담"
L["Caster"] = "원거리 주문"
L["Hunter"] = "사냥꾼"
L["Melee"] = "근접 전투"
L["Reset this type"] = "이 유형 초기화"
L["Spec query note"] = [[
전문화 정보는 서버에서 조회되며, 플레이어 한 명당 1~2초가 소요됩니다.
\n
이로 인해 정확한 정렬이 가능해지기까지 잠시 시간이 걸릴 수 있습니다.
]]

-- # Auto Leader screen #
L["Auto Leader"] = "자동 파티장"
L["Auto promote healers to leader in solo shuffle."] = "솔로 셔플에서 힐러를 자동으로 파티장으로 승급합니다."
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "이유: 힐러가 대상 징표 아이콘을 설정하고 party1/2 순서를 원하는 대로 재정렬할 수 있도록 하기 위함입니다."
L["Enabled"] = "사용"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "대상 지정"
L["Target frame 1 (top frame)"] = "프레임 1 대상 지정(맨 위 프레임)"
L["Target frame 2"] = "프레임 2 대상 지정"
L["Target frame 3"] = "프레임 3 대상 지정"
L["Target frame 4"] = "프레임 4 대상 지정"
L["Target frame 5"] = "프레임 5 대상 지정"
L["Target bottom frame"] = "맨 아래 프레임 대상 지정"
L["Target 1 frame above bottom"] = "아래에서 1칸 위 프레임 대상 지정"
L["Target 2 frames above bottom"] = "아래에서 2칸 위 프레임 대상 지정"
L["Target 3 frames above bottom"] = "아래에서 3칸 위 프레임 대상 지정"
L["Target 4 frames above bottom"] = "아래에서 4칸 위 프레임 대상 지정"
L["Target frame 1's pet"] = "프레임 1의 소환수 대상 지정"
L["Target frame 2's pet"] = "프레임 2의 소환수 대상 지정"
L["Target frame 3's pet"] = "프레임 3의 소환수 대상 지정"
L["Target frame 4's pet"] = "프레임 4의 소환수 대상 지정"
L["Target frame 5's pet"] = "프레임 5의 소환수 대상 지정"
L["Target enemy frame 1"] = "적 프레임 1 대상 지정"
L["Target enemy frame 2"] = "적 프레임 2 대상 지정"
L["Target enemy frame 3"] = "적 프레임 3 대상 지정"
L["Target enemy frame 1's pet"] = "적 프레임 1의 소환수 대상 지정"
L["Target enemy frame 2's pet"] = "적 프레임 2의 소환수 대상 지정"
L["Target enemy frame 3's pet"] = "적 프레임 3의 소환수 대상 지정"
L["Focus enemy frame 1"] = "적 프레임 1 주시"
L["Focus enemy frame 2"] = "적 프레임 2 주시"
L["Focus enemy frame 3"] = "적 프레임 3 주시"
L["Target the next frame"] = "다음 프레임 대상 지정"
L["Target the previous frame"] = "이전 프레임 대상 지정"
L["Cycle to the next frame"] = "다음 프레임으로 순환"
L["Cycle to the previous frame"] = "이전 프레임으로 순환"
L["Cycle to the next dps"] = "다음 딜러로 전환"
L["Cycle to the previous dps"] = "이전 딜러로 전환"

-- # Keybindings screen #
L["Keybindings"] = "단축키"
L["Keybindings_Description"] = [[
FrameSort 단축키는 기본 WoW 단축키 설정에서 찾을 수 있습니다.
\n
단축키는 무엇에 유용한가요?
파티 위치(party1/2/3 등)가 아니라 화면상 정렬된 표시 순서를 기준으로
플레이어를 대상으로 지정할 수 있어 유용합니다.
\n
예를 들어, 역할 기준으로 정렬된 5인 던전 파티가 다음과 같다고 가정해 봅시다:
  - 탱커, party3
  - 힐러, player
  - DPS, party1
  - DPS, party4
  - DPS, party2
\n
보시다시피 화면상의 순서가 실제 파티 위치와 달라
타게팅이 혼란스러울 수 있습니다.
/target party1을 사용하면 탱커가 아니라 3번째 위치의 DPS를 대상으로 하게 됩니다.
\n
FrameSort 단축키는 파티 번호가 아니라 화면상의 프레임 위치를 기준으로 대상 지정합니다.
따라서 '프레임 1'은 탱커, '프레임 2'는 힐러, '프레임 3'은 3번째 위치의 DPS를 대상으로 지정하는 식입니다.
]]

-- # Macros screen # --
L["Macros"] = "매크로"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort가 관리할 매크로 %d개를 찾았습니다."
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] =
    '"#FrameSort" 헤더가 포함된 매크로의 변수는 FrameSort가 동적으로 업데이트합니다.'
L["Below are some examples on how to use this."] = "사용 예시는 아래와 같습니다."

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] Blessing of Sanctuary]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] Dispel]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] Shadowstep;
/cast [@placeholder] Kick;]]

-- %d is the number for example 1/2/3
L["Example %d"] = "예제 %d"
L["Discord Bot Blurb"] = [[
매크로를 만드는 데 도움이 필요하신가요?
\n
FrameSort 디스코드 서버로 오셔서 AI 기반 매크로 봇을 이용해 보세요!
\n
#macro-bot-channel에서 '@Macro Bot'을 멘션해 질문을 남기면 됩니다.
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "매크로 변수"
L["The first DPS that's not you."] = "자신이 아닌 첫 번째 DPS."
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "숫자를 붙여 N번째 대상을 선택할 수 있습니다. 예: DPS2는 두 번째 DPS를 선택합니다."
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] =
    "변수는 대소문자를 구분하지 않으므로 'fRaMe1', 'Dps', 'enemyhealer' 등도 모두 동작합니다."
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "매크로 글자 수를 아끼고 싶다면 약어를 사용해 줄이세요:"
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = '"X"를 사용하면 FrameSort가 @unit 선택자를 무시하도록 할 수 있습니다:'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "간격"
L["Add some spacing between party, raid, and arena frames."] = "파티, 공격대, 투기장 프레임 사이에 간격을 추가합니다."
L["This only applies to Blizzard frames."] = "블리자드 프레임에만 적용됩니다."
L["Party"] = "파티"
L["Raid"] = "공격대"
L["Group"] = "그룹"
L["Horizontal"] = "가로"
L["Vertical"] = "세로"

-- # Addons screen #
L["Addons"] = "애드온"
L["Addons_Supported_Description"] = [[
FrameSort는 다음을 지원합니다:
\n
  - Blizzard: 파티, 공격대, 투기장.
\n
  - ElvUI: 파티.
\n
  - sArena: 투기장.
\n
  - Gladius: 투기장.
\n
  - GladiusEx: 파티, 투기장.
\n
  - Cell: 파티, 공격대(통합 그룹을 사용할 때만).
\n
  - Shadowed Unit Frames: 파티, 투기장.
\n
  - Grid2: 파티, 공격대.
\n
  - BattleGroundEnemies: 파티, 투기장.
\n
  - Gladdy: 투기장.
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "FrameSort를 애드온, 스크립트, WeakAuras에 연동하고 싶으신가요?"
L["Here are some examples."] = "예시는 다음과 같습니다."
L["Retrieved an ordered array of party/raid unit tokens."] = "파티/공격대 유닛 토큰의 정렬된 배열을 가져옵니다."
L["Retrieved an ordered array of arena unit tokens."] = "투기장 유닛 토큰의 정렬된 배열을 가져옵니다."
L["Register a callback function to run after FrameSort sorts frames."] = "FrameSort가 프레임을 정렬한 뒤 실행할 콜백 함수를 등록합니다."
L["Retrieve an ordered array of party frames."] = "파티 프레임의 정렬된 배열을 가져옵니다."
L["Change a FrameSort setting."] = "FrameSort 설정을 변경합니다."
L["Get the frame number of a unit."] = "유닛의 프레임 번호를 가져옵니다."
L["View a full listing of all API methods on GitHub."] = "모든 API 메서드 목록은 GitHub에서 확인하세요."

-- # Discord screen #
L["Discord"] = "디스코드"
L["Need help with something?"] = "도움이 필요하신가요?"
L["Talk directly with the developer on Discord."] = "디스코드에서 개발자와 직접 대화하세요."

-- # Health Check screen -- #
L["Health Check"] = "상태 점검"
L["Try this"] = "이렇게 해보세요"
L["Any known issues with configuration or conflicting addons will be shown below."] = "설정 문제나 충돌하는 애드온이 있으면 아래에 표시됩니다."
L["N/A"] = "해당 없음"
L["Passed!"] = "통과!"
L["Failed"] = "실패"
L["(unknown)"] = "(알 수 없음)"
L["(user macro)"] = "(사용자 매크로)"
L["Using grouped layout for Cell raid frames"] = "Cell 공격대 프레임에 그룹 통합 레이아웃 사용 중"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "Cell -> Layouts에서 'Combined Groups (Raid)' 옵션을 체크하세요"
L["Can detect frames"] = "프레임 감지 가능"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort는 현재 다음 애드온의 프레임을 지원합니다: %s"
L["Using Raid-Style Party Frames"] = "공격대 형식의 파티 프레임 사용 중"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "블리자드 설정에서 'Use Raid-Style Party Frames'를 활성화하세요"
L["Keep Groups Together setting disabled"] = "'Keep Groups Together' 설정이 비활성화됨"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "편집 모드에서 공격대 표시 모드를 'Combined Groups' 옵션 중 하나로 변경하세요"
L["Disable the 'Keep Groups Together' raid profile setting."] = "공격대 프로필의 'Keep Groups Together' 설정을 비활성화하세요."
L["Only using Blizzard frames with Traditional mode"] = "전통적 모드에서는 블리자드 프레임만 사용 중"
L["Traditional mode can't sort your other frame addons: '%s'"] = "전통적 모드는 다른 프레임 애드온을 정렬할 수 없습니다: '%s'"
L["Using Secure sorting mode when spacing is being used"] = "간격 사용 시 보안 정렬 모드 사용"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] =
    "전통적 모드는 간격을 적용할 수 없습니다. 간격을 제거하거나 보안 정렬 방식을 사용하세요."
L["Blizzard sorting functions not tampered with"] = "블리자드 정렬 함수가 변경되지 않음"
L['"%s" may cause conflicts, consider disabling it'] = '"%s"는 충돌을 일으킬 수 있으니 비활성화를 고려하세요'
L["No conflicting addons"] = "충돌하는 애드온 없음"

-- # Log Screen -- #
L["Log"] = "로그"
L["FrameSort log to help with diagnosing issues."] = "문제 진단을 돕는 FrameSort 로그."
L["Copy Log"] = "로그 복사"

-- # Notifications -- #
L["Can't do that during combat."] = "전투 중에는 할 수 없습니다."

-- # Nameplates screen #
L["Nameplates"] = "이름표"
L["Friendly Nameplates"] = "아군 이름표"
L["Enemy Nameplates"] = "적 이름표"
L["NameplatesBlurb"] = [[
Blizzard 및 Platynator 이름표 텍스트를 FrameSort 변수로 대체합니다.
\n
지원되는 변수:
  - $framenumber
  - $name
  - $unit
  - $spec
\n
예시:
  - 프레임 - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "기타"
L["Various tweaks you can apply."] = "적용할 수 있는 다양한 조정입니다."
L["Player top of role"] = "역할 상단에 플레이어 배치"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "해당 역할(힐러/탱커/DPS)의 최상단에 플레이어를 배치합니다."

-- # Language screen #
L["Language"] = "언어"
L["Specify the language we use."] = "사용할 언어를 지정합니다."
