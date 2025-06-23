local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "zhTW" then
    return
end

-- # Main Options screen #
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "有一些問題可能會妨礙 FrameSort 正常工作。"
L["Please go to the Health Check panel to view more details."] = "請前往健康檢查面板以查看更多詳情。"
L["Role/spec"] = "角色/專精"
L["Group"] = "小隊"
L["Alphabetical"] = "字母順序"
L["Arena - 2v2"] = "競技場 - 2v2"
L["Arena - 3v3"] = "競技場 - 3v3"
L["Arena - 3v3 & 5v5"] = "競技場 - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "敵方競技場 (請參閱插件面板以了解支援的插件)"
L["Dungeon (mythics, 5-mans, delves)"] = "地城 (神話、5人、深潛)"
L["Raid (battlegrounds, raids)"] = "團隊 (戰場、團隊)"
L["World (non-instance groups)"] = "世界 (非副本小隊)"
L["Player"] = "玩家"
L["Sort"] = "排序"
L["Top"] = "上方"
L["Middle"] = "中間"
L["Bottom"] = "下方"
L["Hidden"] = "隱藏"
L["Group"] = "小隊"
L["Reverse"] = "反向"

-- # Sorting Method screen #
L["Sorting Method"] = "排序方式"
L["Secure"] = "安全"
L["SortingMethod_Secure_Description"] = [[
調整每個單獨框架的位置，並不會干擾/鎖定/污染UI。
\n
優點：
 - 可以對其他插件的框架進行排序。
 - 可以應用框架間距。
 - 無污染（技術術語，指插件干擾暴雪的UI代碼）。
\n
缺點：
 - 這是一種脆弱的解決方案，以規避暴雪的連接。
 - 可能會隨著魔獸世界的補丁而損壞，讓開發者瘋狂。
]]
L["Traditional"] = "傳統"
L["SortingMethod_Traditional_Description"] = [[
這是插件和宏使用超過10年的標準排序模式。
它用我們自己的排序方法取代了內部的暴雪排序方式。
這與'設置流排序功能'腳本相同，但有 FrameSort 配置。
\n
優點：
 - 更穩定/可靠，因為它利用了暴雪的內部排序方法。
\n
缺點：
 - 只能排序暴雪的隊伍框架，無法排序其他。
 - 會導致 Lua 錯誤，這是正常的，可以忽略。
 - 無法應用框架間距。
]]
L["Please reload after changing these settings."] = "更改這些設置後請重新載入。"
L["Reload"] = "重新載入"

-- # Ordering screen #
L["Ordering"] = "排序"
L["Specify the ordering you wish to use when sorting by role."] = "指定您希望在按角色排序時使用的順序。"
L["Tanks"] = "坦克"
L["Healers"] = "治療"
L["Casters"] = "施法者"
L["Hunters"] = "獵人"
L["Melee"] = "近戰"

-- # Auto Leader screen #
L["Auto Leader"] = "自動隊長"
L["Auto promote healers to leader in solo shuffle."] = "在單獨洗牌中自動將治療者提升為隊長。"
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "為什麼？這樣治療者就可以配置目標標記圖標並根據自己的喜好重新排序隊伍1/2。"
L["Enabled"] = "已啟用"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "目標選擇"
L["Target frame 1 (top frame)"] = "目標框架1（上方框架）"
L["Target frame 2"] = "目標框架2"
L["Target frame 3"] = "目標框架3"
L["Target frame 4"] = "目標框架4"
L["Target frame 5"] = "目標框架5"
L["Target bottom frame"] = "目標下方框架"
L["Target 1 frame above bottom"] = "選取底部上方第1個框架"
L["Target 2 frames above bottom"] = "選取底部上方第2個框架"
L["Target 3 frames above bottom"] = "選取底部上方第3個框架"
L["Target 4 frames above bottom"] = "選取底部上方第4個框架"
L["Target frame 1's pet"] = "目標框架1的寵物"
L["Target frame 2's pet"] = "目標框架2的寵物"
L["Target frame 3's pet"] = "目標框架3的寵物"
L["Target frame 4's pet"] = "目標框架4的寵物"
L["Target frame 5's pet"] = "目標框架5的寵物"
L["Target enemy frame 1"] = "目標敵方框架1"
L["Target enemy frame 2"] = "目標敵方框架2"
L["Target enemy frame 3"] = "目標敵方框架3"
L["Target enemy frame 1's pet"] = "目標敵方框架1的寵物"
L["Target enemy frame 2's pet"] = "目標敵方框架2的寵物"
L["Target enemy frame 3's pet"] = "目標敵方框架3的寵物"
L["Focus enemy frame 1"] = "專注敵方框架1"
L["Focus enemy frame 2"] = "專注敵方框架2"
L["Focus enemy frame 3"] = "專注敵方框架3"
L["Cycle to the next frame"] = "循環到下一框架"
L["Cycle to the previous frame"] = "循環到上一框架"
L["Target the next frame"] = "目標下一框架"
L["Target the previous frame"] = "目標上一框架"

-- # Keybindings screen #
L["Keybindings"] = "快捷鍵"
L["Keybindings_Description"] = [[
您可以在標準的魔獸世界快捷鍵區域找到 FrameSort 的快捷鍵。
\n
快捷鍵的用途是什麼？
它們有助於根據玩家的視覺排序表示而不是他們的隊伍位置 (party1/2/3等) 選擇目標。
\n
例如，想像一個依角色排序的五人副本小隊，如下所示：
  - 坦克，隊伍3
  - 治療，玩家
  - DPS，隊伍1
  - DPS，隊伍4
  - DPS，隊伍2
\n
如您所見，他們的視覺表示與他們的實際隊伍位置不同，這使得目標選擇令人困惑。
如果您要 /target party1，它會選擇位置3的DPS玩家，而不是坦克。
\n
FrameSort的快捷鍵將基於其視覺框架位置而非隊伍編號進行選擇。
所以，選擇'框架1'將選擇坦克，'框架2'選擇治療者，'框架3'選擇位置3的DPS，以此類推。
]]

-- # Macros screen # --
L["Macros"] = "宏"
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort 找到了 %d |4宏:宏; 需要管理。"
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = "FrameSort 將動態更新包含'#FrameSort'標題的宏內變數。"
L["Below are some examples on how to use this."] = "下面是一些使用示例。"

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] 神聖保護

]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] 驅散
]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] 隱身;
/cast [@placeholder] 攻擊;
]]

L["Example %d"] = "範例 %d"
L["Supported variables:"] = "支援的變數："
L["The first DPS that's not you."] = "第一個不是您的DPS。"
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "添加一個數字以選擇第N個目標，例如，DPS2選擇第二個DPS。"
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "變數不區分大小寫，因此'fRaMe1'，'Dps'，'enemyhealer'等都可以使用。"
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "需要在宏字符上保存？請使用縮寫來縮短它們："
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = '使用 "X" 讓 FrameSort 忽略 @unit 選擇器：'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] 法術;
]]

-- # Spacing screen #
L["Spacing"] = "間距"
L["Add some spacing between party, raid, and arena frames."] = "在小隊/團隊框架之間添加一些間距。"
L["This only applies to Blizzard frames."] = "這僅適用於暴雪框架。"
L["Party"] = "小隊"
L["Raid"] = "團隊"
L["Group"] = "小隊"
L["Horizontal"] = "水平"
L["Vertical"] = "垂直"

-- # Addons screen #
L["Addons"] = "插件"
L["Addons_Supported_Description"] = [[
FrameSort 支援以下內容：
\n
暴雪
 - 小隊：是
 - 團隊：是
 - 競技場：是
\n
ElvUI
 - 小隊：是
 - 團隊：否
 - 競技場：否
\n
sArena
 - 競技場：是
\n
Gladius
 - 競技場：是
 - Bicmex 版本：是
\n
GladiusEx
 - 小隊：是
 - 競技場：是
\n
Cell
 - 小隊：是
 - 團隊：是，僅在使用合併小組時。
\n
Shadowed Unit Frames
 - 小隊：是
 - 競技場：是
\n
Grid2
 - 小隊/團隊：是
\n
]]

-- # Api screen #
L["Api"] = "Api"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "想將 FrameSort 集成到您的插件、腳本和弱光環中嗎？"
L["Here are some examples."] = "這裡有一些示例。"
L["Retrieved an ordered array of party/raid unit tokens."] = "檢索到一個有序的派對/團隊單位標記數組。"
L["Retrieved an ordered array of arena unit tokens."] = "檢索到一個有序的競技場單位標記數組。"
L["Register a callback function to run after FrameSort sorts frames."] = "註冊一個回調函數，在 FrameSort 排序框架後運行。"
L["Retrieve an ordered array of party frames."] = "檢索一個有序的小隊框架數組。"
L["Change a FrameSort setting."] = "更改 FrameSort 設置。"
L["View a full listing of all API methods on GitHub."] = "查看 GitHub 上所有 API 方法的完整列表。"

-- # Help screen #
L["Help"] = "幫助"
L["Discord"] = "Discord"
L["Need help with something?"] = "需要幫助嗎？"
L["Talk directly with the developer on Discord."] = "在 Discord 上與開發者直接對話。"

-- # Health Check screen -- #
L["Health Check"] = "健康檢查"
L["Try this"] = "試試這個"
L["Any known issues with configuration or conflicting addons will be shown below."] = "任何已知的配置問題或衝突插件將顯示在下面。"
L["N/A"] = "不適用"
L["Passed!"] = "通過！"
L["Failed"] = "失敗"
L["(unknown)"] = "(未知)"
L["(user macro)"] = "(用戶宏)"
L["Using grouped layout for Cell raid frames"] = "使用 Cell 團隊框架的分組佈局"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "請在 Cell -> 佈局中檢查 '合併小組 (Raid)' 選項"
L["Can detect frames"] = "可以檢測框架"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort 目前支持來自這些插件的框架：%s"
L["Using Raid-Style Party Frames"] = "使用團隊風格的小隊框架"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "請在暴雪設置中啟用 '使用團隊風格的小隊框架'"
L["Keep Groups Together setting disabled"] = "保持小組一起的設置已禁用"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "通過編輯模式將團隊顯示模式更改為 '合併小組' 選項之一"
L["Disable the 'Keep Groups Together' raid profile setting."] = "禁用 '保持小組一起' 的團隊配置設定。"
L["Only using Blizzard frames with Traditional mode"] = "僅使用暴雪框架的傳統模式"
L["Traditional mode can't sort your other frame addons: '%s'"] = "傳統模式無法對其他框架插件進行排序：'%s'"
L["Using Secure sorting mode when spacing is being used"] = "在使用間距時使用安全排序模式。"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "傳統模式無法應用間距，考慮移除間距或使用安全排序方法"
L["Blizzard sorting functions not tampered with"] = "暴雪排序功能未被篡改"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" 可能會引起衝突，考慮禁用它'
L["No conflicting addons"] = "沒有衝突的插件"
L["Main tank and assist setting disabled"] = "主坦克和助攻設定已禁用"
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "請在選項 -> 介面 -> 團隊框架中禁用 '顯示主坦克和助攻' 選項"
