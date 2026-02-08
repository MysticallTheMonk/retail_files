-- Korean localization for sArena Reloaded
-- sArena Reloaded 한국어 현지화
-- Korean translation by: 007bb from Korea Mate Guild

local locale = GetLocale()
if locale ~= "koKR" then return end

local L = sArenaMixin.L

---------------------------------------
-- Common Terms
---------------------------------------

L["Yes"] = "예"
L["No"] = "아니오"
L["Enable"] = "활성화"
L["Disable"] = "비활성화"
L["Reset"] = "초기화"
L["Scale"] = "크기"
L["Size"] = "크기"
L["Width"] = "너비"
L["Height"] = "높이"
L["Horizontal"] = "가로"
L["Vertical"] = "세로"
L["Spacing"] = "간격"
L["Positioning"] = "위치"
L["Sizing"] = "크기 조정"
L["Options"] = "옵션"
L["BorderSize"] = "테두리 크기"
L["GrowthDirection"] = "성장 방향"
L["AnchorPoint"] = "고정점"

---------------------------------------
-- Directions
---------------------------------------

L["Direction_Down"] = "아래"
L["Direction_Up"] = "위"
L["Direction_Right"] = "오른쪽"
L["Direction_Left"] = "왼쪽"
L["Direction_Center"] = "중앙"
L["Direction_TopLeft"] = "왼쪽 위"
L["Direction_Top"] = "위"
L["Direction_TopRight"] = "오른쪽 위"
L["Direction_BottomLeft"] = "왼쪽 아래"
L["Direction_Bottom"] = "아래"
L["Direction_BottomRight"] = "오른쪽 아래"

---------------------------------------
-- Font Outlines
---------------------------------------

L["Outline_None"] = "외곽선 없음"
L["Outline_Normal"] = "외곽선"
L["Outline_Thick"] = "두꺼운 외곽선"

---------------------------------------
-- Messages
---------------------------------------

L["Message_MustLeaveCombat"] = "먼저 전투에서 벗어나야 합니다."

---------------------------------------
-- Diminishing Returns Categories
---------------------------------------

L["DR_Stun"] = "기절"
L["DR_Incapacitate"] = "무력화"
L["DR_Disorient"] = "혼란"
L["DR_Silence"] = "침묵"
L["DR_Root"] = "뿌리 묶기"
L["DR_Knock"] = "넉백"
L["DR_Disarm"] = "무장 해제"
L["DR_Fear"] = "공포"
L["DR_Horror"] = "공포"
L["DR_Cyclone"] = "회오리바람"
L["DR_MindControl"] = "정신 지배"
L["DR_RandomStun"] = "무작위 기절"
L["DR_RandomRoot"] = "무작위 뿌리 묶기"
L["DR_Charge"] = "돌진"

---------------------------------------
-- Race Names
---------------------------------------

L["Race_Human"] = "인간"
L["Race_Scourge"] = "언데드"
L["Race_Dwarf"] = "드워프"
L["Race_NightElf"] = "나이트 엘프"
L["Race_Gnome"] = "노움"
L["Race_Draenei"] = "드레나이"
L["Race_Worgen"] = "늑대인간"
L["Race_Pandaren"] = "판다렌"
L["Race_Orc"] = "오크"
L["Race_Tauren"] = "타우렌"
L["Race_Troll"] = "트롤"
L["Race_BloodElf"] = "블러드 엘프"
L["Race_Goblin"] = "고블린"
L["Race_LightforgedDraenei"] = "빛벼림 드레나이"
L["Race_HighmountainTauren"] = "높은산 타우렌"
L["Race_Nightborne"] = "나이트본"
L["Race_MagharOrc"] = "마그하르 오크"
L["Race_DarkIronDwarf"] = "검은무쇠 드워프"
L["Race_ZandalariTroll"] = "잔달라 트롤"
L["Race_VoidElf"] = "공허 엘프"
L["Race_KulTiran"] = "쿨 티란"
L["Race_Mechagnome"] = "기계노움"
L["Race_Vulpera"] = "불페라"
L["Race_Dracthyr"] = "드랙티르"
L["Race_EarthenDwarf"] = "토석인"
L["Race_Harronir"] = "하라니르"

---------------------------------------
-- Main Categories
---------------------------------------

L["Category_ArenaFrames"] = "투기장 프레임"
L["Category_SpecIcons"] = "특성 아이콘"
L["Category_Trinkets"] = "장신구"
L["Category_Racials"] = "종족 특성"
L["Category_Dispels"] = "해제"
L["Category_CastBars"] = "시전바"
L["Category_DiminishingReturns"] = "점감 효과"
L["Category_Widgets"] = "위젯"
L["Category_TextSettings"] = "텍스트 설정"
L["Category_ClassIcon"] = "직업 아이콘"

---------------------------------------
-- Textures
---------------------------------------

L["Textures"] = "텍스처"
L["Texture_General"] = "일반 텍스처"
L["Texture_General_Desc"] = "팁: 기본 WoW 텍스처를 사용자 정의 텍스처로 교체했고 그것을 원한다면 \"Blizzard Raid Bar\"를 선택하세요."
L["Texture_Healer"] = "힐러 텍스처"
L["Texture_Healer_Desc"] = "팁: 기본적으로 같은 직업이 여러 명일 때만 작동합니다. 항상 텍스처를 변경하려면 \"직업 중복 시에만\" 옵션을 꺼주세요."
L["Texture_ClassStackingOnly"] = "직업 중복 시에만"
L["Texture_ClassStackingOnly_Desc"] = "같은 직업이 여러 명일 때만 힐러 텍스처를 변경합니다.\n\n예를 들어 적 팀에 회복 드루이드와 야성 드루이드가 모두 있을 때입니다."
L["Texture_Background"] = "배경 텍스처"
L["Texture_Background_Desc"] = "체력/자원 바 하단의 텍스처입니다."
L["Texture_BackgroundColor"] = "배경 색상"
L["Texture_BackgroundColor_Desc"] = "체력/자원 바 하단의 색상입니다."

---------------------------------------
-- Arena Frames Options
---------------------------------------

L["Option_ReplaceClassIcon"] = "직업 아이콘 교체"
L["Option_ReplaceClassIcon_Desc"] = "직업 아이콘을 특성 아이콘으로 교체하고 작은 \"특성 아이콘 버튼\"을 숨깁니다."
L["Option_GrowthDirection"] = "성장 방향"
L["Option_SpacingBetweenFrames"] = "각 투기장 프레임 사이의 간격"
L["Option_SpacingBetweenFrames_Desc"] = "각 투기장 프레임 사이의 간격"
L["Option_ClassIconCDFontSize"] = "직업 아이콘 재사용 대기시간 글꼴 크기"
L["Option_ClassIconCDFontSize_Desc"] = "블리자드 재사용 대기시간 카운트에서만 작동합니다 (OmniCC 제외)"
L["Option_FontSize"] = "글꼴 크기"
L["Option_FontSize_Desc"] = "블리자드 재사용 대기시간 카운트에서만 작동합니다 (OmniCC 제외)"
L["Option_MirroredFrames"] = "미러링된 프레임"
L["Option_PowerBarHeight"] = "자원바 높이"
L["Option_SpecTextOnManabar"] = "자원바에 특성 텍스트"
L["Option_CropIcons"] = "아이콘 자르기"
L["Option_PixelBorderSize"] = "픽셀 테두리 크기"
L["Option_PixelBorderOffset"] = "픽셀 테두리 오프셋"
L["Option_DRPixelBorderSize"] = "점감 효과 픽셀 테두리 크기"
L["Option_HideNameBackground"] = "이름 배경 숨기기"
L["Option_BigHealthbar"] = "큰 체력바"
L["Option_TrinketCircleBorder"] = "장신구 원형 테두리"
L["Option_TrinketCircleBorder_Desc"] = "장신구 아이콘에 원형 테두리 활성화"
L["Option_DisableOvershields"] = "초과 보호막 비활성화"
L["Option_DisableOvershields_Desc"] = "보호막이 최대 체력을 초과할 때 체력바에 역방향으로 표시되는 것을 비활성화합니다"

---------------------------------------
-- Cast Bars
---------------------------------------

L["Castbar_Look"] = "시전바 모양"
L["Castbar_UseModern"] = "현대적인 시전바 사용"
L["Castbar_UseModern_Desc"] = "새로운 현대적인 리테일 시전바를 사용합니다."
L["Castbar_KeepDefaultModernTextures"] = "기본 현대적인 텍스처 유지"
L["Castbar_KeepDefaultModernTextures_Desc"] = "현대적인 시전바에 새로운 현대적인 텍스처를 유지합니다. 설정된 텍스처를 무시합니다."
L["Castbar_Simple"] = "간단한 시전바"
L["Castbar_Simple_Desc"] = "시전바 텍스트 배경을 숨기고 시전바 텍스트를 시전바 안으로 이동합니다."
L["Castbar_HideShield"] = "차단 불가 시 방패 숨기기"
L["Castbar_HideShield_Desc"] = "차단 불가 시전 시 주문 아이콘 주변의 방패 텍스처를 숨깁니다."
L["Castbar_HideSpark"] = "시전바 스파크 숨기기"
L["Castbar_HideSpark_Desc"] = "시전바의 뒤따르는 스파크를 숨깁니다."
L["Castbar_HideIcon"] = "시전바 아이콘 숨기기"
L["Castbar_HideIcon_Desc"] = "시전바의 주문 아이콘을 숨깁니다."
L["Castbar_Texture"] = "시전바 텍스처"
L["Castbar_UninterruptibleTexture"] = "차단 불가 텍스처"
L["Castbar_Colors"] = "시전바 색상"
L["Castbar_RecolorCastbar"] = "시전바 색상 변경"
L["Castbar_RecolorCastbar_Desc"] = "사용자 정의 시전바 색상 활성화"
L["Castbar_Cast"] = "시전"
L["Castbar_Channeled"] = "정신 집중"
L["Castbar_Uninterruptible"] = "차단 불가"
L["Castbar_InterruptNotReady"] = "차단 준비 안 됨"
L["Castbar_EnableNoInterruptColor"] = "차단 불가 색상 활성화"
L["Castbar_EnableNoInterruptColor_Desc"] = "차단 준비가 안 되었을 때 시전바를 이 색상으로 칠하도록 활성화합니다."
L["Castbar_InterruptNotReadyColor"] = "차단 준비 안 됨 색상"
L["Castbar_Position"] = "시전바 위치"
L["Castbar_IconPosition"] = "아이콘 위치"
L["Castbar_CastbarSize"] = "시전바 크기"
L["Castbar_IconSize"] = "아이콘 크기"
L["Castbar_IconScale"] = "아이콘 크기"

---------------------------------------
-- Diminishing Returns Options
---------------------------------------

L["DR_BrightBorder"] = "밝은 점감 효과 테두리"
L["DR_BlackBorder"] = "검은 점감 효과 테두리"
L["DR_BlackBorder_Desc"] = "점감 효과 테두리를 검은색으로 만듭니다. 점감 효과 텍스트 표시 설정과 함께 사용하세요."
L["DR_ShowText"] = "점감 효과 텍스트 표시"
L["DR_ShowText_Desc"] = "현재 점감 효과 상태를 표시하는 텍스트를 점감 효과 아이콘에 표시합니다."
L["DR_DisableBorderGlow"] = "점감 효과 테두리 반짝임 비활성화"
L["DR_ThickPixelBorder"] = "두꺼운 픽셀 테두리"
L["DR_ThinPixelBorder"] = "얇은 픽셀 테두리"
L["DR_DisableBorder"] = "점감 효과 테두리 비활성화"
L["DR_DisableBorder_Desc"] = "점감 효과 테두리 프레임을 완전히 숨깁니다."
L["DR_BorderSize"] = "테두리 크기"
L["DR_SpecificSizeAdjustment"] = "점감 효과 특정 크기 조정"

---------------------------------------
-- Widgets
---------------------------------------

L["Widget_CombatIndicator"] = "전투 표시기"
L["Widget_CombatIndicator_Enable"] = "전투 표시기 활성화"
L["Widget_CombatIndicator_Desc"] = "적이 전투 중이 아닐 때 음식 아이콘을 표시합니다."
L["Widget_TargetIndicator"] = "대상 표시기"
L["Widget_TargetIndicator_Enable"] = "대상 표시기 활성화"
L["Widget_TargetIndicator_Desc"] = "현재 대상에 아이콘을 표시합니다."
L["Widget_FocusIndicator"] = "주시 대상 표시기"
L["Widget_FocusIndicator_Enable"] = "주시 대상 표시기 활성화"
L["Widget_FocusIndicator_Desc"] = "현재 주시 대상에 아이콘을 표시합니다."
L["Widget_PartyTargetIndicators"] = "파티 대상 표시기"
L["Widget_PartyTargetIndicators_Enable"] = "파티 대상 표시기 활성화"
L["Widget_PartyTargetIndicators_Desc"] = "파티원이 대상을 지정하는 투기장 프레임에 직업 색상 아이콘을 표시합니다."

---------------------------------------
-- Text Settings
---------------------------------------

L["Text_Fonts"] = "글꼴"
L["Text_ChangeFont"] = "글꼴 변경"
L["Text_ChangeFont_Desc"] = "sArena에서 사용하는 글꼴을 변경합니다."
L["Text_FrameFont"] = "프레임 글꼴"
L["Text_FrameFont_Desc"] = "이름, 체력/자원 값, 시전 텍스트 등과 같은 레이블에 사용됩니다."
L["Text_CooldownFont"] = "재사용 대기시간 글꼴"
L["Text_CooldownFont_Desc"] = "재사용 대기시간 숫자 (장신구, 점감 효과, 종족 특성 등)에 사용됩니다."
L["Text_FontOutline"] = "글꼴 외곽선"
L["Text_FontOutline_Desc"] = "모든 텍스트 요소에 대한 글꼴 외곽선 스타일을 선택합니다."
L["Text_NameText"] = "이름 텍스트"
L["Text_HealthText"] = "체력 텍스트"
L["Text_ManaText"] = "마나 텍스트"
L["Text_SpecNameText"] = "특성 이름 텍스트"
L["Text_CastbarText"] = "시전바 텍스트"
L["Text_DRText"] = "점감 효과 텍스트"
L["Text_AnchorPoint"] = "고정점"

---------------------------------------
-- Status Text
---------------------------------------

L["Status_Health"] = "체력"
L["Status_Power"] = "자원"
L["Status_HealthPercent"] = "체력 퍼센트"
L["Status_PowerPercent"] = "자원 퍼센트"
L["Status_HealthAndPower"] = "체력과 자원"
L["Status_HealthAndPowerPercent"] = "체력과 자원 퍼센트"

---------------------------------------
-- Additional Options and Messages
---------------------------------------

L["Layout_Settings"] = "레이아웃 설정"
L["Layout_Settings_Desc"] = "이 설정은 선택된 레이아웃에만 적용됩니다"
L["Global_Settings"] = "전역 설정"
L["Global_Settings_Desc"] = "이 설정은 모든 레이아웃에 적용됩니다"

L["Text_ShowOnMouseover_Desc"] = "비활성화하면 마우스 오버 시에만 텍스트가 표시됩니다"
L["Text_FormatLargeNumbers_Desc"] = "큰 숫자를 형식화합니다. 18888 K -> 18.88 M"
L["Text_HidePowerText"] = "자원 텍스트 숨기기"
L["Text_HidePowerText_Desc"] = "마나/분노/기력 텍스트 숨기기"

L["DarkMode_Enable"] = "다크 모드 활성화"
L["DarkMode_Enable_Desc"] = "투기장 프레임에 다크 모드를 활성화합니다."
L["DarkMode_Value"] = "다크 모드 값"
L["DarkMode_Value_Desc"] = "다크 모드 프레임의 어두움 값을 설정합니다 (0 = 검정색, 1 = 일반 밝기)."
L["DarkMode_Desaturate_Desc"] = "다크 모드가 적용되는 텍스처에서 모든 색상을 제거합니다.\n\n|cff888888이것은 기본 동작이지만 일부 레이아웃에서는 원래 색상이 약간 나타나는 것을 선호할 수 있습니다.|r"

L["ClassColor_Healthbars"] = "직업 색상 체력바"
L["ClassColor_Healthbars_Desc"] = "비활성화하면 체력바가 녹색이 됩니다"
L["ClassColor_FrameTexture"] = "직업 색상 프레임 텍스처"
L["ClassColor_FrameTexture_Desc"] = "프레임 텍스처(테두리)에 직업 색상 적용"
L["ClassColor_OnlyClassIcon"] = "직업 아이콘만"
L["ClassColor_OnlyClassIcon_Desc"] = "직업 아이콘 테두리에만 직업 색상을 적용하고 다른 프레임 텍스처에는 적용하지 않습니다"
L["ClassColor_HealerGreen"] = "힐러 녹색으로 표시"
L["ClassColor_HealerGreen_Desc"] = "힐러 프레임을 직업 색상 대신 밝은 녹색으로 변경합니다"
L["ClassColor_NameText"] = "직업 색상 이름 텍스트"
L["ClassColor_NameText_Desc"] = "활성화하면 플레이어 이름이 직업 색상으로 표시됩니다"

L["Icon_ReplaceHealerWithHealerIcon"] = "힐러를 힐러 아이콘으로 교체"
L["Icon_ReplaceHealerWithHealerIcon_Desc"] = "힐러의 직업/특성 아이콘을 힐러 아이콘으로 교체합니다."
L["Healthbar_ReverseFill"] = "체력바 채우기 반전"
L["Healthbar_ReverseFill_Desc"] = "체력과 자원바를 왼쪽에서 오른쪽 대신 오른쪽에서 왼쪽으로 채웁니다"
L["ClassIcon_HideAndShowOnlyAuras"] = "직업 아이콘 숨기기, 오라만 표시"
L["ClassIcon_HideAndShowOnlyAuras_Desc"] = "직업 아이콘을 숨기고 활성화될 때만 오라를 표시합니다."
L["ClassIcon_DontShowAuras"] = "직업 아이콘에 오라 표시 안 함"
L["ClassIcon_DontShowAuras_Desc"] = "직업 아이콘에 오라를 표시하지 않고 항상 직업/특성 아이콘을 표시합니다."

L["Trinket_MinimalistDesign"] = "미니멀리스트 장신구 디자인"
L["Trinket_MinimalistDesign_Desc"] = "장신구 텍스처를 사용 가능하면 녹색, 재사용 대기시간이면 빨간색으로 교체합니다."
L["MysteryPlayer_GrayBars"] = "미확인 플레이어 회색 표시"
L["MysteryPlayer_GrayBars_Desc"] = "미확인(은신 또는 시작 전) 플레이어를 직업 색상 대신 회색으로 표시합니다"

L["Cooldown_ShowDecimalsThreshold_Desc"] = "남은 시간이 이 임계값 이하일 때 소수점을 표시합니다. 기본값은 6초입니다."
L["Cooldown_DisableBrightEdge"] = "재사용 대기시간 나선형 밝은 테두리 비활성화"
L["Cooldown_DisableBrightEdge_Desc"] = "모든 아이콘의 재사용 대기시간 나선형 밝은 테두리를 비활성화합니다."
L["Cooldown_DisableClassIconSwipe"] = "직업 아이콘 회전 비활성화"
L["Cooldown_DisableClassIconSwipe_Desc"] = "직업 아이콘의 나선형 재사용 대기시간 회전 애니메이션을 비활성화합니다."
L["Cooldown_DisableDRSwipe"] = "점감 효과 회전 비활성화"
L["Cooldown_DisableDRSwipe_Desc"] = "점감 효과 아이콘의 나선형 재사용 대기시간 회전을 비활성화합니다."
L["Cooldown_DisableTrinketRacialSwipe"] = "장신구와 종족 특성 회전 비활성화"
L["Cooldown_DisableTrinketRacialSwipe_Desc"] = "장신구와 종족 특성 아이콘의 나선형 재사용 대기시간 회전 애니메이션을 비활성화합니다."
L["Cooldown_ReverseClassIcon"] = "직업 아이콘 재사용 대기시간 반전"
L["Cooldown_ReverseClassIcon_Desc"] = "직업 아이콘 재사용 대기시간의 회전 방향을 반전합니다. 비어있는 상태에서 채워지거나 가득 찬 상태에서 비워지는 것을 변경합니다."
L["Cooldown_ReverseDR"] = "점감 효과 재사용 대기시간 반전"
L["Cooldown_ReverseDR_Desc"] = "점감 효과 재사용 대기시간 회전 방향을 반전합니다."
L["Cooldown_ReverseTrinketRacial"] = "장신구와 종족 특성 재사용 대기시간 반전"
L["Cooldown_ReverseTrinketRacial_Desc"] = "장신구와 종족 특성 재사용 대기시간의 회전 방향을 반전합니다. 비어있는 상태에서 채워지거나 가득 찬 상태에서 비워지는 것을 변경합니다."

L["Masque_Support"] = "Masque 지원 활성화"
L["Masque_Support_Desc"] = "클릭하여 Masque 지원을 활성화하여 아이콘 테두리를 다시 스킨합니다.\n\n현재 이것은 적절한 모양을 위해 Masque 설정에서 배경을 비활성화해야 합니다. 많은 것들을 다시 작업해야 하기 때문에 이것을 개선할 시간을 낼지 확실하지 않습니다."
L["Trinket_HideWhenNoTrinket"] = "장신구 장착하지 않았을 때 숨기기"
L["Trinket_HideWhenNoTrinket_Desc"] = "장신구 슬롯에 흰색 깃발 텍스처를 숨깁니다(장신구가 장착되지 않았음을 나타냄). 대신 텍스처가 전혀 표시되지 않습니다."
L["Trinket_DesaturateOnCD"] = "재사용 대기시간 시 장신구 채도 낮추기"
L["Trinket_DesaturateOnCD_Desc"] = "재사용 대기시간일 때 장신구 아이콘의 채도를 낮춥니다."
L["Dispel_DesaturateOnCD"] = "재사용 대기시간 시 해제 채도 낮추기"
L["Dispel_DesaturateOnCD_Desc"] = "재사용 대기시간일 때 해제 아이콘의 채도를 낮춥니다."

L["DR_ClassSpecific"] = "직업별 점감 효과 카테고리"
L["DR_ClassSpecific_Desc"] = "활성화하면 아래 점감 효과 카테고리가 현재 직업에 대한 직업별이 됩니다.\n\n|cff888888모든 기본 카테고리가 여전히 포함되므로 즉시 변경 사항을 볼 수 없으며 사용자 정의하려는 카테고리를 수동으로 변경해야 합니다.|r"
L["DR_SpecSpecific"] = "특성별 점감 효과 카테고리"
L["DR_SpecSpecific_Desc"] = "활성화하면 아래 점감 효과 카테고리가 현재 특성에 대한 특성별이 됩니다.\n\n|cff888888모든 기본 카테고리가 여전히 포함되므로 즉시 변경 사항을 볼 수 없으며 사용자 정의하려는 카테고리를 수동으로 변경해야 합니다.|r"
L["DR_FixedIcons"] = "고정 점감 효과 아이콘"
L["DR_FixedIcons_Desc"] = "점감 효과 아이콘은 각 점감 효과 카테고리에 대해 항상 특정 아이콘을 사용합니다."
L["DR_ClassSpecificIcons"] = "직업별 점감 효과 아이콘"
L["DR_ClassSpecificIcons_Desc"] = "활성화하면 아래 아이콘이 현재 직업에 대한 직업별이 됩니다.\n\n|cff888888모든 기본 아이콘이 여전히 포함되므로 즉시 변경 사항을 볼 수 없으며 사용자 정의하려는 아이콘을 수동으로 변경해야 합니다.|r"
L["DR_SpecSpecificIcons"] = "특성별 점감 효과 아이콘"
L["DR_SpecSpecificIcons_Desc"] = "활성화하면 아래 아이콘이 현재 특성에 대한 특성별이 됩니다.\n\n|cff888888모든 기본 아이콘이 여전히 포함되므로 즉시 변경 사항을 볼 수 없으며 사용자 정의하려는 아이콘을 수동으로 변경해야 합니다.|r"

L["Racial_ShowInTrinketSlot"] = "장신구 없을 때 장신구 슬롯에 종족 특성 표시"
L["Racial_ShowInTrinketSlot_Desc"] = "적이 장신구를 장착하지 않았으면 간격을 제거하고 장신구 자리에 종족 특성을 표시합니다."
L["Human_AlwaysShowTrinket"] = "인간에게 항상 얼라이언스 장신구 표시"
L["Human_AlwaysShowTrinket_Desc"] = "인간 플레이어가 장신구를 장착하지 않았어도 항상 얼라이언스 장신구 텍스처를 표시합니다."

L["Drag_Hint"] = "Ctrl+Shift+클릭하여 드래그"

---------------------------------------
-- Dispel Classes/Specs
---------------------------------------

L["DispelClass_DiscHolyPriest"] = "수양/신성 사제"
L["DispelClass_ShadowPriest"] = "암흑 사제"
L["DispelClass_HolyPaladin"] = "신성 성기사"
L["DispelClass_ProtRetPaladin"] = "보호/징벌 성기사"
L["DispelClass_RestoShaman"] = "복원 주술사"
L["DispelClass_EnhEleShaman"] = "고양/정기 주술사"
L["DispelClass_RestoDruid"] = "회복 드루이드"
L["DispelClass_BalFeralGuardianDruid"] = "조화/야성/수호 드루이드"
L["DispelClass_Mage"] = "마법사"
L["DispelClass_Monk"] = "수도사"
L["DispelClass_MistweaverMonk"] = "운무 수도사"
L["DispelClass_Evoker"] = "기원사"
L["DispelClass_DevEvoker"] = "황폐 기원사"
L["DispelClass_WarlockPet"] = "흑마법사 소환수"
L["DispelClass_WarlockGrimoire"] = "흑마법사 (마법서)"
L["DispelClass_SurvivalHunter"] = "생존 사냥꾼"
L["DispelClass_Priest"] = "사제"
L["DispelClass_Druid"] = "드루이드"

L["Dispel_ShowsAfterUse"] = "한 번 사용된 후에만 표시됩니다"

L["Option_AddonConflict"] = "애드온 충돌"
L["Option_Layout"] = "레이아웃"
L["Option_Test"] = "테스트"
L["Option_Hide"] = "숨기기"
L["Option_ArenaFrames"] = "투기장 프레임"
L["Option_StatusText"] = "상태 텍스트"
L["Option_AlwaysShow"] = "항상 표시"
L["Option_UsePercentage"] = "백분율 사용"
L["Option_FormatNumbers"] = "숫자 서식"
L["Option_DarkMode"] = "다크 모드"
L["Option_Desaturate"] = "채도 낮추기"
L["Option_ClassColorNames"] = "직업 색상 이름"
L["Option_ReplaceHealerIcon"] = "힐러 아이콘 교체"
L["Option_ShowNames"] = "이름 표시"
L["Option_ShowArenaNumber"] = "투기장 번호 표시"
L["Option_ReverseBarsFill"] = "바 채우기 반전"
L["Option_HideClassIconShowAurasOnly"] = "직업 아이콘 숨기기 (오라만 표시)"
L["Option_DisableAurasOnClassIcon"] = "직업 아이콘에 오라 비활성화"
L["Option_ShadowsightTimer"] = "어둠의 시야 타이머 활성화"
L["Option_ShadowsightTimer_Desc"] = "투기장에서 어둠의 시야 버프가 생성될 때 화면 상단에 타이머를 표시합니다"
L["Shadowsight_Ready"] = "어둠의 시야 준비됨"
L["Shadowsight_SpawnsIn"] = "어둠의 시야 생성까지 %d초"
L["Option_ColorTrinket"] = "장신구 색상"
L["Option_ColorNonVisibleFramesGray"] = "비표시 프레임 회색으로 표시"
L["Option_ShowDecimalsOnClassIcon"] = "직업 아이콘에 소수점 표시"
L["Option_DecimalThreshold"] = "소수점 임계값"
L["Option_SwipeAnimations"] = "회전 애니메이션"
L["Option_DisableCooldownSwipeEdge"] = "재사용 대기시간 회전 테두리 비활성화"
L["Option_DisableClassIconSwipe"] = "직업 아이콘 회전 비활성화"
L["Option_DisableDRSwipeAnimation"] = "점감 효과 회전 애니메이션 비활성화"
L["Option_DisableTrinketRacialSwipe"] = "장신구 및 종족 특성 회전 비활성화"
L["Option_ReverseClassIconSwipe"] = "직업 아이콘 회전 반전"
L["Option_ReverseDRSwipeAnimation"] = "점감 효과 회전 애니메이션 반전"
L["Option_ReverseTrinketRacialSwipe"] = "장신구 및 종족 특성 회전 반전"
L["Option_Miscellaneous"] = "기타"
L["Option_EnableMasqueSupport"] = "Masque 지원 활성화"
L["Option_RemoveUnEquippedTrinketTexture"] = "장착하지 않은 장신구 텍스처 제거"
L["Option_DesaturateTrinketCD"] = "장신구 재사용 대기시간 채도 낮추기"
L["Option_DesaturateDispelCD"] = "해제 재사용 대기시간 채도 낮추기"
L["Option_DRResetTime"] = "점감 효과 초기화 시간"
L["Option_ShowDecimalsOnDRs"] = "점감 효과에 소수점 표시"
L["Option_ColorDRCooldownText"] = "점감 효과 쿨다운 텍스트 심각도별 색상"
L["Option_ColorDRCooldownText_Desc"] = "점감 효과 쿨다운 카운트다운 텍스트를 점감 효과 심각도에 따라 색상으로 표시합니다.\n\n|cff00ff00녹색|r: ½ 감소\n|cffffff00노란색|r: ¼ 감소\n|cffff0000빨간색|r: 면역"
L["Option_ColorDRCooldownText_Desc_Midnight"] = "점감 효과 쿨다운 카운트다운 텍스트를 점감 효과 심각도에 따라 색상으로 표시합니다.\n\n|cff00ff00녹색|r: ½ 감소\n|cffff0000빨간색|r: 면역"
L["Option_DRCategories"] = "점감 효과 카테고리"
L["Option_PerClass"] = "직업별"
L["Option_PerSpec"] = "특성별"
L["Option_DRIcons"] = "점감 효과 아이콘"
L["Option_EnableStaticIcons"] = "고정 아이콘 활성화"
L["Option_Categories"] = "카테고리"
L["Option_SwapMissingTrinketWithRacial"] = "장신구 없을 때 종족 특성으로 교체"
L["Option_ForceShowTrinketOnHuman"] = "인간에게 장신구 강제 표시"
L["Option_ReplaceHumanRacialWithTrinket"] = "인간 종족 특성을 장신구로 교체"
L["Option_ShowDispels"] = "해제 표시"
L["Option_HealerDispels"] = "힐러 해제"
L["Option_DPSDispels"] = "딜러 해제"
L["Option_OthersArena"] = "다른 sArena"
L["Option_ImportSettings"] = "설정 가져오기"
L["Option_ShareProfile"] = "프로필 공유"
L["Option_ExportCurrentProfile"] = "현재 프로필 내보내기"
L["Option_ExportString"] = "내보내기 문자열"
L["Option_PasteProfileString"] = "프로필 문자열 붙여넣기"
L["Option_ImportDescription"] = "다른 sArena 설정을 새로운 sArena |cffff8000Reloaded|r |T135884:13:13|t 버전으로 가져옵니다.\n\n두 애드온이 모두 활성화되어 있는지 확인한 후 아래 버튼을 클릭하세요."
L["Message_NoLayoutSettings"] = "선택한 레이아웃에 설정이 없는 것 같습니다."
L["Option_ReplaceHumanRacialWithTrinket_Desc"] = "종족 슬롯에서 인간 종족 특성을 얼라이언스 장신구 텍스처로 교체합니다."
L["Option_ShowDispels_Desc"] = "투기장 프레임에 해제 재사용 대기시간을 표시하려면 활성화하세요."
L["Option_OthersArena_Desc"] = "다른 sArena에서 설정 가져오기"
L["Option_ImportSettings_Desc"] = "다른 sArena 버전에서 설정을 가져옵니다."
L["Option_MidnightPlans_Desc"] = "월드 오브 워크래프트: 한밤 계획"
L["Option_ShareProfile_Desc"] = "sArena 프로필 내보내기 또는 가져오기"
L["Option_ExportString_Desc"] = "|cff32f795Ctrl+A|r로 모두 선택, |cff32f795Ctrl+C|r로 복사"
L["Option_PasteProfileString_Desc"] = "|cff32f795Ctrl+V|r로 복사한 프로필 문자열 붙여넣기"
L["Option_TrinketCircleBorder_Desc"] = "장신구 아이콘에 원형 테두리 활성화"
L["Option_DefaultIcon_Desc"] = "기본 아이콘: %s |T%s:24|t"
L["Option_ImportProfile_Desc"] = "%s의 프로필 설정을 가져옵니다.\n\n%swww.twitch.tv/%s|r"
L["Option_DPSDispelsNote"] = "|cFFFFFF00참고:|r 딜러 해제는 한 번 사용된 후에만 표시됩니다."
L["Option_DispelsBetaNotice"] = "\n|cFF808080해제 기능은 베타 버전입니다.\n특히 판다리아의 안개에서 일부 주문 ID를 확인해야 합니다.\nPTR을 기다리는 동안 더 많은 테스트가 필요하며 변경될 수 있습니다.\n정보/피드백/주문 ID를 제공하고 싶으시다면 언제든지 제공해주세요!|r"
L["Option_ExportProfileHeader"] = "|cffffff00프로필 내보내기:|r"
L["Option_ImportProfileHeader"] = "|cffffff00프로필 가져오기:|r"
L["Option_StreamerProfilesHeader"] = "|cffffff00스트리머 프로필:|r"

L["Message_InvalidFormat"] = "잘못된 형식입니다."
L["Message_DecompressionError"] = "압축 해제 오류: %s"
L["Message_DeserializationError"] = "역직렬화 오류 또는 잘못된 형식입니다."
L["Message_ImportFailed"] = "|cffff4040가져오기 실패:|r"
L["Message_ExportFailed"] = "내보내기 실패:"
L["Message_NoProfileFound"] = "현재 캐릭터의 프로필을 찾을 수 없습니다."
L["Message_ProfileDataNotFound"] = "프로필 데이터를 찾을 수 없습니다."
L["Message_IncorrectDataType"] = "잘못된 데이터 유형입니다."
L["Message_ProfileOverwrite"] = "%s의 프로필이 이미 있습니다. 다시 가져오면 이 프로필의 모든 설정을 덮어씁니다. 계속하시겠습니까?"
L["ImportExport_DialogTitle"] = "sArena 가져오기 확인"
L["Message_MidnightWarningTitle"] = "|cffa020f0한밤 베타 경고|r"
L["Message_MidnightWarningText"] = "한밤은 베타 버전이며 편집 모드로 인해\n새 점감 효과에서 오류가 발생합니다.\n\n|cffFFFF00UI 새로고침으로 수정하세요.|r\n\n이 경고는 블리자드가 편집 모드와\n점감 효과를 수정하는 즉시 제거됩니다."
L["Button_ReloadUI"] = "UI 새로고침"
L["DR_CategoriesPerSpec"] = "카테고리 (특성별: %s)"
L["DR_CategoriesPerClass"] = "카테고리 (직업별: %s)"
L["DR_CategoriesGlobal"] = "카테고리 (전역)"
L["DR_IconsPerSpec"] = "점감 효과 아이콘 설정 (특성별: %s)"
L["DR_IconsPerClass"] = "점감 효과 아이콘 설정 (직업별: %s)"
L["DR_IconsGlobal"] = "점감 효과 아이콘 설정 (전역)"
L["Option_ShowDecimalsOnClassIcon_Desc"] = "지속 시간이 6초 미만일 때 직업 아이콘에 소수점을 표시합니다.\n\nOmniCC 미사용자 전용입니다."
L["Option_ShowDecimalsOnDRs_Desc"] = "지속 시간이 6초 미만일 때 점감 효과에 소수점을 표시합니다.\n\nOmniCC 미사용자 전용입니다."
L["Option_StreamerProfiles_Desc"] = "인기 스트리머의 사전 구성된 프로필을 가져옵니다.\n현재 활성 프로필 \"|cff00ff00%s|r\"을 포함하여 모든 현재 프로필을 유지합니다.\n다시 프로필을 변경하려면 프로필 탭으로 이동하세요."
L["Unknown"] = "알 수 없음"
L["Unknown_Spell"] = "알 수 없는 주문"
L["Cooldown_Seconds"] = "재사용 대기시간: %d초"
L["SelectAll"] = "모두 선택"

---------------------------------------
-- Data Collection
---------------------------------------

L["DataCollection_NotEnabled"] = "데이터 수집이 활성화되어 있지 않습니다. 먼저 db.collectData = true로 설정하세요."
L["DataCollection_NoDataYet"] = "아직 수집된 주문 데이터가 없습니다."
L["DataCollection_ExportTitle"] = "sArena 수집된 주문 데이터"
L["DataCollection_ExportComplete"] = "총 %d개의 항목을 수집했습니다. 데이터가 내보내기 창에 표시됩니다."

L["Print_CurrentVersion"] = "현재 버전: %s"
L["Print_MultipleVersionsLoaded"] = "두 개의 다른 sArena 버전이 로드되었습니다. /sarena를 입력하여 계속할 방법을 선택하세요."

L["Conflict_MultipleVersions"] = "여러 sArena 버전 감지됨"
L["Conflict_Warning"] = "|A:services-icon-warning:20:20|a |cffff4444두 개의 다른 sArena 버전이 활성화되어 있습니다|r |A:services-icon-warning:20:20|a"
L["Conflict_Explanation"] = "|cffffffff두 개의 다른 sArena 버전은 제대로 작동할 수 없습니다.\n하나만 사용해야 합니다. 3가지 옵션이 있습니다:|r"
L["Conflict_UseOther"] = "|cffffffff다른 sArena 사용|r"
L["Conflict_UseOther_Desc"] = "이것은 |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t를 비활성화하고 대신 다른 sArena를 사용하고 UI를 다시 로드합니다."
L["Conflict_UseOther_Confirm"] = "이것은 |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t를 비활성화하고 대신 다른 sArena를 사용하고 UI를 다시 로드합니다.\n\n계속하시겠습니까?"
L["Conflict_UseReloaded_Import"] = "|cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t 사용: 다른 설정 가져오기"
L["Conflict_UseReloaded_Import_Desc"] = "이것은 다른 sArena에서 현재 프로필과 기존 설정을 복사하고 호환성을 위해 다른 sArena를 비활성화하고 UI를 다시 로드하여 sArena |cffff8000Reloaded|r |T135884:13:13|t 사용을 시작할 수 있게 합니다"
L["Conflict_UseReloaded_Import_Confirm"] = "이것은 다른 sArena에서 현재 프로필과 기존 설정을 복사하고 호환성을 위해 다른 sArena를 비활성화하고 UI를 다시 로드하여 sArena |cffff8000Reloaded|r |T135884:13:13|t 사용을 시작할 수 있게 합니다\n\n계속하시겠습니까?"
L["Conflict_UseReloaded_NoImport"] = "|cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t 사용: 다른 설정 가져오지 않기"
L["Conflict_UseReloaded_NoImport_Desc"] = "이것은 호환성을 위해 다른 sArena를 비활성화하고 UI를 다시 로드하여 다른 설정 없이 sArena |cffff8000Reloaded|r |T135884:13:13|t 사용을 시작할 수 있게 합니다."
L["Conflict_UseReloaded_NoImport_Confirm"] = "이것은 호환성을 위해 다른 sArena를 비활성화하고 UI를 다시 로드하여 다른 설정 없이 sArena |cffff8000Reloaded|r |T135884:13:13|t 사용을 시작할 수 있게 합니다.\n\n계속하시겠습니까?"
L["Midnight_UpdateInfo"] = "|cff00ff00업데이트: 이제 한밤에서 사용 가능합니다.|r\n\n한밤용 |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t 개발을 계속할 계획입니다.\n\n일부 기능은 조정되거나 제거될 수 있지만 애드온은 계속 유지될 것입니다.\n한밤은 아직 초기 알파 단계이며 준비를 시작하지 않았지만 (10월 14일), 곧 시작할 것입니다.\n\n계획은 변경될 수 있지만 |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t와 제 다른 애드온들\n|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames & |A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rPlates가 한밤에서도 계속 유지될 것이라고 확신합니다 (변경/제거 포함).\n\n앞으로 많은 작업이 있으며, 모든 지원에 감사드립니다. (|cff00c0ff@bodify|r)\n몇 주/개월 후 더 자세한 정보를 알게 되면 이 섹션을 업데이트하겠습니다."
L["Midnight_BetaInfo"] = "한밤에 오신 것을 환영합니다! 제 다른 애드온들 |A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames & |A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rPlates도 작업 중입니다.\n\n새로운 API가 제공됨에 따라 개발이 빠르게 변경될 것입니다.\n이 한밤 베타는 아직 미완성이며 게임에 많은 것들이 누락되어 있습니다.\n한밤 출시까지 많은 것들을 실험할 것입니다.\n\n현재 변경된 사항:\n1) 점감 효과는 이제 블리자드에서 처리하며, sArena는 허용된 만큼만 조정합니다.\n 1.1) 간격 설정이 사라졌습니다.\n 1.2) 개별 크기 조정이 사라졌습니다.\n 1.3) 위/아래 성장이 사라졌습니다.\n 1.4) 아이콘은 이제 블리자드의 이상한 아이콘이므로 해당 설정이 사라졌습니다.\n2) 비-CC 오라는 더 이상 표시되지 않으며, 블리자드가 허용하는 CC만 표시됩니다.\n3) 프레임의 피해 흡수가 사라졌습니다.\n4) 종족 특성 재사용 대기시간을 추적할 수 없지만 종족 특성은 여전히 표시됩니다.\n5) 해제가 사라졌습니다..\n\n모든 것이 완전히 확정된 것은 아니며 새로운 것들이 나타날 수 있지만 지켜볼 것입니다. 여기에서 계속 업데이트하겠습니다."
