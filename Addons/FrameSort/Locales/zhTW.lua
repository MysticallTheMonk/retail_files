local _, addon = ...
local L = addon.Locale.zhTW

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "有一些問題可能會導致 FrameSort 無法正常運作。"
L["Please go to the Health Check panel to view more details."] = "請前往「健康檢查」面板查看詳細資訊。"
L["Role"] = "職責"
L["Spec"] = "專精"
L["Group"] = "隊伍"
L["Alphabetical"] = "字母順序"
L["Arena - 2v2"] = "競技場 - 2v2"
L["Arena - 3v3"] = "競技場 - 3v3"
L["Arena - 3v3 & 5v5"] = "競技場 - 3v3 與 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "敵方競技場（請參見插件面板以了解支援的插件）"
L["Dungeon (mythics, 5-mans, delves)"] = "地城（傳奇、5 人、深潛）"
L["Raid (battlegrounds, raids)"] = "團隊（戰場、團隊副本）"
L["World (non-instance groups)"] = "野外（非副本隊伍）"
L["Player"] = "玩家"
L["Sort"] = "排序"
L["Top"] = "頂部"
L["Middle"] = "中間"
L["Bottom"] = "底部"
L["Hidden"] = "隱藏"
L["Group"] = "隊伍"
L["Reverse"] = "反向"

-- # Sorting Method screen #
L["Sorting Method"] = "排序方式"
L["Secure"] = "安全"
L["SortingMethod_Secure_Description"] = [[
調整每個個別框架的位置，且不會造成 UI 出錯/鎖死/汙染。
\n
優點：
 - 可排序其他插件的框架。
 - 可套用框架間距。
 - 無汙染（技術術語，指插件干擾暴雪的 UI 程式碼）。
\n
缺點：
 - 為了繞過暴雪的「義大利麵」程式而搭出的紙牌屋，十分脆弱。
 - 可能會在 WoW 更新後壞掉，讓開發者抓狂。
]]
L["Traditional"] = "傳統"
L["SortingMethod_Traditional_Description"] = [[
這是外掛與巨集使用超過 10 年的標準排序模式。
它以我們的方式取代暴雪內部的排序方法。
這等同於 'SetFlowSortFunction' 指令碼，但加入了 FrameSort 的設定。
\n
優點：
 - 更穩定可靠，因為利用了暴雪的內建排序方法。
\n
缺點：
 - 只能排序暴雪的小隊框架，無法處理其他。
 - 會產生 Lua 錯誤，這是正常的，可忽略。
 - 無法套用框架間距。
]]
L["Please reload after changing these settings."] = "變更這些設定後請重新載入。"
L["Reload"] = "重新載入"

-- # Ordering screen #
L["Ordering"] = "排序"
L["Specify the ordering you wish to use when sorting by spec."] = "指定依專精排序時要使用的順序。"
L["Tanks"] = "坦克"
L["Healers"] = "治療"
L["Casters"] = "施法者"
L["Hunters"] = "獵人"
L["Melee"] = "近戰"

-- # Spec Priority screen # --
L["Spec Priority"] = "專精優先順序"
L["Spec Type"] = "專精類型"
L["Choose a spec type, then drag and drop to control priority."] = "選擇一個專精類型，然後使用拖曳方式調整優先順序。"
L["Tank"] = "坦克"
L["Healer"] = "治療"
L["Caster"] = "遠程法系"
L["Hunter"] = "獵人"
L["Melee"] = "近戰"
L["Reset this type"] = "重置此類型"
L["Spec query note"] = [[
請注意，專精資訊需從伺服器查詢，每位玩家約需 1–2 秒。
\n
這表示在我們能夠準確排序之前，可能需要稍等片刻。
]]

-- # Auto Leader screen #
L["Auto Leader"] = "自動隊長"
L["Auto promote healers to leader in solo shuffle."] = "在單排亂鬥中自動將治療升為隊長。"
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "為什麼？讓治療可以設定目標標記圖示，並依喜好調整 party1/2 的順序。"
L["Enabled"] = "啟用"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "選取目標"
L["Target frame 1 (top frame)"] = "選取框架 1（最上方）"
L["Target frame 2"] = "選取框架 2"
L["Target frame 3"] = "選取框架 3"
L["Target frame 4"] = "選取框架 4"
L["Target frame 5"] = "選取框架 5"
L["Target bottom frame"] = "選取最下方框架"
L["Target 1 frame above bottom"] = "選取距底部向上第 1 個框架"
L["Target 2 frames above bottom"] = "選取距底部向上第 2 個框架"
L["Target 3 frames above bottom"] = "選取距底部向上第 3 個框架"
L["Target 4 frames above bottom"] = "選取距底部向上第 4 個框架"
L["Target frame 1's pet"] = "選取框架 1 的寵物"
L["Target frame 2's pet"] = "選取框架 2 的寵物"
L["Target frame 3's pet"] = "選取框架 3 的寵物"
L["Target frame 4's pet"] = "選取框架 4 的寵物"
L["Target frame 5's pet"] = "選取框架 5 的寵物"
L["Target enemy frame 1"] = "選取敵方框架 1"
L["Target enemy frame 2"] = "選取敵方框架 2"
L["Target enemy frame 3"] = "選取敵方框架 3"
L["Target enemy frame 1's pet"] = "選取敵方框架 1 的寵物"
L["Target enemy frame 2's pet"] = "選取敵方框架 2 的寵物"
L["Target enemy frame 3's pet"] = "選取敵方框架 3 的寵物"
L["Focus enemy frame 1"] = "專注敵方框架 1"
L["Focus enemy frame 2"] = "專注敵方框架 2"
L["Focus enemy frame 3"] = "專注敵方框架 3"
L["Target the next frame"] = "選取下一個框架"
L["Target the previous frame"] = "選取上一個框架"
L["Cycle to the next frame"] = "循環到下一個框架"
L["Cycle to the previous frame"] = "循環到上一個框架"
L["Cycle to the next dps"] = "切換到下一個輸出"
L["Cycle to the previous dps"] = "切換到上一個輸出"

-- # Keybindings screen #
L["Keybindings"] = "按鍵綁定"
L["Keybindings_Description"] = [[
您可在 WoW 標準按鍵綁定區找到 FrameSort 的綁定。
\n
按鍵綁定有什麼用？
它讓你依據畫面上的排序來選取玩家，而不是依隊伍位置（party1/2/3/等）。
\n
例如，想像 5 人地城小隊依職責排序，看起來如下：
  - 坦克，party3
  - 治療，player
  - DPS，party1
  - DPS，party4
  - DPS，party2
\n
如你所見，畫面順序與實際隊伍位置不同，導致選取容易混淆。
如果你輸入 /target party1，會選到位於第 3 位的 DPS，而不是坦克。
\n
FrameSort 的按鍵綁定會依視覺框架位置而非隊伍編號來選取。
因此選取「框架 1」會選到坦克，「框架 2」是治療，「框架 3」則是位於第 3 位的 DPS，依此類推。
]]

-- # Macros screen # --
L["Macros"] = "巨集"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort 找到 %d 個要管理的巨集。"
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = "包含「#FrameSort」標頭的巨集，其內的變數會由 FrameSort 動態更新。"
L["Below are some examples on how to use this."] = "以下是一些使用範例。"

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
L["Example %d"] = "範例 %d"
L["Discord Bot Blurb"] = [[
需要建立巨集的協助嗎？
\n
前往 FrameSort 的 Discord 伺服器，使用我們的 AI 巨集機器人！
\n
只要在 #macro-bot-channel 頻道中 @Macro Bot 並提出你的問題即可。
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "巨集變數"
L["The first DPS that's not you."] = "不是你自己的第一位 DPS。"
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "可加上數字來選擇第 N 個目標，例如：DPS2 會選到第 2 位 DPS。"
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "變數不分大小寫，因此「fRaMe1」、「Dps」、「enemyhealer」等都能使用。"
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "想節省巨集字數嗎？可使用縮寫來簡化："
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = "使用「X」告訴 FrameSort 忽略一個 @單位 的選擇器："
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "間距"
L["Add some spacing between party, raid, and arena frames."] = "在隊伍、團隊與競技場框架之間加入一些間距。"
L["This only applies to Blizzard frames."] = "僅適用於暴雪框架。"
L["Party"] = "隊伍"
L["Raid"] = "團隊"
L["Group"] = "隊伍"
L["Horizontal"] = "水平"
L["Vertical"] = "垂直"

-- # Addons screen #
L["Addons"] = "插件"
L["Addons_Supported_Description"] = [[
FrameSort 支援下列項目：
\n
  - 暴雪：隊伍、團隊、競技場。
\n
  - ElvUI：隊伍。
\n
  - sArena：競技場。
\n
  - Gladius：競技場。
\n
  - GladiusEx：隊伍、競技場。
\n
  - Cell：隊伍、團隊（僅在使用合併群組時）。
\n
  - Shadowed Unit Frames：隊伍、競技場。
\n
  - Grid2：隊伍、團隊。
\n
  - BattleGroundEnemies：隊伍、競技場。
\n
  - Gladdy：競技場。
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "想把 FrameSort 整合到你的插件、指令碼與 WeakAuras 嗎？"
L["Here are some examples."] = "以下是一些範例。"
L["Retrieved an ordered array of party/raid unit tokens."] = "取得已排序的隊伍/團隊單位代碼陣列。"
L["Retrieved an ordered array of arena unit tokens."] = "取得已排序的競技場單位代碼陣列。"
L["Register a callback function to run after FrameSort sorts frames."] = "註冊回呼函式，在 FrameSort 排序框架之後執行。"
L["Retrieve an ordered array of party frames."] = "取得已排序的隊伍框架陣列。"
L["Change a FrameSort setting."] = "變更一項 FrameSort 設定。"
L["Get the frame number of a unit."] = "取得單位的框架編號。"
L["View a full listing of all API methods on GitHub."] = "在 GitHub 檢視所有 API 方法的完整清單。"

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "需要幫忙嗎？"
L["Talk directly with the developer on Discord."] = "在 Discord 上直接與開發者對話。"

-- # Health Check screen -- #
L["Health Check"] = "健康檢查"
L["Try this"] = "試試看"
L["Any known issues with configuration or conflicting addons will be shown below."] = "任何已知的設定問題或插件衝突都會顯示在下方。"
L["N/A"] = "不適用"
L["Passed!"] = "通過！"
L["Failed"] = "失敗"
L["(unknown)"] = "（未知）"
L["(user macro)"] = "（使用者巨集）"
L["Using grouped layout for Cell raid frames"] = "Cell 團隊框架使用群組化版面配置"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "請在 Cell -> 版面配置 中勾選「合併群組（團隊）」選項"
L["Can detect frames"] = "可偵測到框架"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort 目前支援來自以下插件的框架：%s"
L["Using Raid-Style Party Frames"] = "使用團隊風格隊伍框架"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "請在暴雪設定中啟用「使用團隊風格的隊伍框架」"
L["Keep Groups Together setting disabled"] = "已停用「保持群組一起」設定"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "請透過編輯模式將團隊顯示模式改為「合併群組」的其中一種選項"
L["Disable the 'Keep Groups Together' raid profile setting."] = "請停用團隊設定檔中的「保持群組一起」選項。"
L["Only using Blizzard frames with Traditional mode"] = "僅在傳統模式中使用暴雪框架"
L["Traditional mode can't sort your other frame addons: '%s'"] = "傳統模式無法排序你的其他框架插件：「%s」"
L["Using Secure sorting mode when spacing is being used"] = "在使用間距時已使用安全排序模式"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "傳統模式無法套用間距，請考慮移除間距或改用安全排序方式"
L["Blizzard sorting functions not tampered with"] = "暴雪的排序函式未被更動"
L['"%s" may cause conflicts, consider disabling it'] = "「%s」可能導致衝突，建議停用"
L["No conflicting addons"] = "沒有衝突的插件"

-- # Log Screen -- #
L["Log"] = "日誌"
L["FrameSort log to help with diagnosing issues."] = "FrameSort 日誌，用於協助診斷問題。"
L["Copy Log"] = "複製日誌"

-- # Notifications -- #
L["Can't do that during combat."] = "戰鬥中無法執行此操作。"

-- # Nameplates screen #
L["Nameplates"] = "名條"
L["Friendly Nameplates"] = "友方名條"
L["Enemy Nameplates"] = "敵方名條"
L["NameplatesBlurb"] = [[
將 Blizzard 和 Platynator 的名條文字替換為 FrameSort 變數。
\n
支援的變數：
  - $framenumber
  - $name
  - $unit
  - $spec
\n
範例：
  - 框架 - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "雜項"
L["Various tweaks you can apply."] = "你可以套用的各種調整。"
L["Player top of role"] = "玩家置於角色頂端"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "將你置於對應角色（治療/坦克/DPS）的最前位置。"

-- # Language screen #
L["Language"] = "語言"
L["Specify the language we use."] = "指定要使用的語言。"
