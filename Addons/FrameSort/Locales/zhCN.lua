local _, addon = ...
local L = addon.Locale
local wow = addon.WoW.Api

if wow.GetLocale() ~= "zhCN" then
    return
end

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issuse that may prevent FrameSort from working correctly."] = "可能存在一些问题，导致FrameSort无法正常工作。"
L["Please go to the Health Check panel to view more details."] = "请前往健康检查面板查看更多详情。"
L["Role/spec"] = "角色/专精"
L["Group"] = "团队"
L["Alphabetical"] = "字母顺序"
L["Arena - 2v2"] = "竞技场 - 2v2"
L["Arena - 3v3"] = "竞技场 - 3v3"
L["Arena - 3v3 & 5v5"] = "竞技场 - 3v3 & 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "竞技场敌人（请查看插件面板了解支持的插件）"
L["Dungeon (mythics, 5-mans, delves)"] = "地下城（大米、5人组、地下堡）"
L["Raid (battlegrounds, raids)"] = "团队（战场、团本）"
L["World (non-instance groups)"] = "世界（非副本团队）"
L["Player"] = "玩家"
L["Sort"] = "排序"
L["Top"] = "顶部"
L["Middle"] = "中间"
L["Bottom"] = "底部"
L["Hidden"] = "隐藏"
L["Group"] = "组"
L["Reverse"] = "反向"

-- # Sorting Method screen #
L["Sorting Method"] = "排序方式"
L["Secure"] = "安全"
L["SortingMethod_Secure_Description"] = [[
分别挪动各角色的框架。这种方式可以避免锁定或污染用户界面，或导致界面出错。
\n
优点：
 - 可以对其他插件绘制的框架进行排序。
 - 可以在框架之间加入间距。
 - 无需污染界面。（污染：术语，指插件干扰暴雪的用户界面代码）
\n
缺点：
 - 需要一些较为脆弱的逻辑以应对暴雪代码中杂乱的细节。
 - 魔兽世界更新后可能会失效（开发者会抓狂）。
]]
L["Traditional"] = "传统"
L["SortingMethod_Traditional_Description"] = [[
将暴雪原生的排序算法替换为我们自己的排序算法。
这是各插件和宏使用了十多年的标准排序模式，
与“SetFlowSortFunction”脚本类似，但使用FrameSort进行配置。
\n
优点：
 - 更稳定可靠，因为利用的是暴雪官方提供的排序渠道。
\n
缺点：
 - 仅能处理暴雪原生的框体，无法处理其他插件绘制的框体。
 - 会产生Lua错误，这是正常的，可以忽略。
 - 无法在各角色的框架之间加入间距。
]]
L["Please reload after changing these settings."] = "更改本设置后需重新加载。"
L["Reload"] = "重新加载"

-- # Ordering screen #
L["Ordering"] = "排序"
L["Specify the ordering you wish to use when sorting by role."] = "指定按角色排序时的顺序。"
L["Tanks"] = "坦克"
L["Healers"] = "治疗"
L["Casters"] = "施法者"
L["Hunters"] = "猎人"
L["Melee"] = "近战"

-- # Auto Leader screen #
L["Auto Leader"] = "自动队长"
L["Auto promote healers to leader in solo shuffle."] = "在3v3竞技场中自动把队长给治疗。"
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] = "目的：这样能让治疗来根据其需要设置队伍标记图标以及排序队伍1/2。"
L["Enabled"] = "启用"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "目标选择"
L["Target frame 1 (top frame)"] = "选中队友1（已排序）"
L["Target frame 2"] = "选中队友2（已排序）"
L["Target frame 3"] = "选中队友3（已排序）"
L["Target frame 4"] = "选中队友4（已排序）"
L["Target frame 5"] = "选中队友5（已排序）"
L["Target bottom frame"] = "选中最后一个队友（已排序）"
L["Target 1 frame above bottom"] = "选中底部上方第1个框体"
L["Target 2 frames above bottom"] = "选中底部上方第2个框体"
L["Target 3 frames above bottom"] = "选中底部上方第3个框体"
L["Target 4 frames above bottom"] = "选中底部上方第4个框体"
L["Target frame 1's pet"] = "选中队友1的的宠物（已排序）"
L["Target frame 2's pet"] = "选中队友2的的宠物（已排序）"
L["Target frame 3's pet"] = "选中队友3的的宠物（已排序）"
L["Target frame 4's pet"] = "选中队友4的的宠物（已排序）"
L["Target frame 5's pet"] = "选中队友5的的宠物（已排序）"
L["Target enemy frame 1"] = "选中敌人1（已排序）"
L["Target enemy frame 2"] = "选中敌人2（已排序）"
L["Target enemy frame 3"] = "选中敌人3（已排序）"
L["Target enemy frame 1's pet"] = "选中敌人1的宠物（已排序）"
L["Target enemy frame 2's pet"] = "选中敌人2的宠物（已排序）"
L["Target enemy frame 3's pet"] = "选中敌人3的宠物（已排序）"
L["Focus enemy frame 1"] = "将敌人1设为焦点（已排序）"
L["Focus enemy frame 2"] = "将敌人2设为焦点（已排序）"
L["Focus enemy frame 3"] = "将敌人3设为焦点（已排序）"
L["Cycle to the next frame"] = "选中下一个队友并循环（已排序）"
L["Cycle to the previous frame"] = "选中上一个队友并循环（已排序）"
L["Target the next frame"] = "选中下一个队友（已排序）"
L["Target the previous frame"] = "选中上一个队友（已排序）"

-- # Keybindings screen #
L["Keybindings"] = "快捷键设置"
L["Keybindings_Description"] = [[
你可以在魔兽世界原生的快捷键设置页面找到 FrameSort 的快捷键。
\n
FrameSort 的快捷键有什么用？
你可以根据视觉排序来选择玩家，而不是队伍内编号（例如“party1/2/3”等）。
\n
例如，某5人地下城小队在按角色排序后，各成员及其宏代号如下：
  - 坦克，party3
  - 治疗，player
  - DPS，party1
  - DPS，party4
  - DPS，party2
\n
可以看到，视觉排序与其实际的队伍位置不同，这使得选择目标混乱：
使用“/target party1”无法选到坦克，而是会选到3号位的DPS玩家。
\n
FrameSort的快捷键绑定能让你根据视觉排序而不是队伍位置选择目标。
用“Frame1”作为对象就能选到坦克，“Frame2”选择治疗，“Frame3”选择位置3的DPS，依此类推。
]]

-- # Macros screen # --
L["Macros"] = "宏"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "当前共有 %d |4个宏:个宏;由 FrameSort 进行管理。"
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = 'FrameSort将动态更新包含"#FrameSort"头的宏中的变量。'
L["Below are some examples on how to use this."] = "以下是一些使用示例。"

L["Macro_Example1"] = [[#showtooltip
#FrameSort Mouseover, Target, Healer
/cast [@mouseover,help][@target,help][@healer,exists] 庇护祝福]]

L["Macro_Example2"] = [[#showtooltip
#FrameSort Frame1, Frame2, Player
/cast [mod:ctrl,@frame1][mod:shift,@frame2][mod:alt,@player][] 驱散]]

L["Macro_Example3"] = [[#FrameSort EnemyHealer, EnemyHealer
/cast [@doesntmatter] 影遁;
/cast [@placeholder] 断脚；]]

-- %d is the number for example 1/2/3
L["Example %d"] = "示例 %d"
L["Supported variables:"] = "支持的变量："
L["The first DPS that's not you."] = "第一个不是你的DPS。"
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "添加一个数字以选择第N个目标，例如，DPS2选择第二个DPS。"
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "变量不区分大小写，所以“fRaMe1”“Dps”“enemyhealer”等均有效。"
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "若要节省宏字数，可以使用缩写："
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = '用“X”告诉FrameSort忽略一个@unit选择器：'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] 法术;]]

-- # Spacing screen #
L["Spacing"] = "间距"
L["Add some spacing between party, raid, and arena frames."] = "在小队/团队/竞技场框体的各角色框架之间添加间距。"
L["This only applies to Blizzard frames."] = "仅适用于暴雪原生框体。"
L["Party"] = "小队"
L["Raid"] = "团队"
L["Group"] = "组队"
L["Enemy Arena"] = "竞技场敌人"
L["Horizontal"] = "水平"
L["Vertical"] = "垂直"

-- # Addons screen #
L["Addons"] = "插件"
L["Addons_Supported_Description"] = [[
FrameSort支持以下内容：
\n
暴雪
 - 小队：是
 - 团队：是
 - 竞技场：是
\n
ElvUI
 - 小队：是
 - 团队：否
 - 竞技场：否
\n
sArena
 - 竞技场：是
\n
Gladius
 - 竞技场：是
 - Bicmex版本：是
\n
GladiusEx
 - 小队：是
 - 竞技场：是
\n
Cell
 - 小队：是
 - 团队：是，仅在使用“合并队伍”选项时。
\n
Shadowed Unit Frames
 - 小队：是
 - 竞技场：是
\n
Grid2
 - 小队/团队：是
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "想将FrameSort集成到你的插件、脚本和WeakAura中吗？"
L["Here are some examples."] = "以下是一些示例。"
L["Retrieved an ordered array of party/raid unit tokens."] = "获取当前队伍/团队在排序后的单位token列表。"
L["Retrieved an ordered array of arena unit tokens."] = "获取当前竞技场在排序后的单位token数组。"
L["Register a callback function to run after FrameSort sorts frames."] = "注册一个回调函数，在FrameSort为框架排序后运行。"
L["Retrieve an ordered array of party frames."] = "获取当前小队在排序后的框架列表。"
L["Change a FrameSort setting."] = "更改FrameSort的设置。"
L["View a full listing of all API methods on GitHub."] = "在GitHub上查看所有API方法的完整列表。"

-- # Help screen #
L["Help"] = "帮助"
L["Discord"] = "Discord"
L["Need help with something?"] = "需要帮助吗？"
L["Talk directly with the developer on Discord."] = "在Discord上直接与开发人员交谈。"

-- # Health Check screen -- #
L["Health Check"] = "健康检查"
L["Try this"] = "尝试此项"
L["Any known issues with configuration or conflicting addons will be shown below."] = "任何已知的配置或冲突插件的问题将在下面显示。"
L["N/A"] = "不适用"
L["Passed!"] = "通过！"
L["Failed"] = "失败"
L["(unknown)"] = "（未知）"
L["(user macro)"] = "（用户宏）"
L["Using grouped layout for Cell raid frames"] = "使用组合布局的Cell团队框体"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "请检查Cell -> 布局中的“合并队伍（团队）”选项"
L["Can detect frames"] = "检测到了框体"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort 当前支持来自这些插件的框体：%s"
L["Using Raid-Style Party Frames"] = "使用团队风格的小队框体"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "请在暴雪设置中启用“使用团队风格的小队框体”"
L["Keep Groups Together setting disabled"] = "“保持小队相连”设置已禁用"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "通过编辑模式将团队显示模式更改为任意“合并队伍”选项"
L["Disable the 'Keep Groups Together' raid profile setting."] = "禁用“保持小队相连”团队配置设置。"
L["Only using Blizzard frames with Traditional mode"] = "传统模式仅支持暴雪原生框体"
L["Traditional mode can't sort your other frame addons: '%s'"] = "传统模式无法对其他插件绘制的框体进行排序：'%s'"
L["Using Secure sorting mode when spacing is being used"] = "在启用间距时使用安全排序模式"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "传统模式无法应用间距，考虑去除间距或使用安全排序模式"
L["Blizzard sorting functions not tampered with"] = "暴雪排序功能未被干扰"
L['"%s" may cause conflicts, consider disabling it'] = '"%s" 可能会导致冲突，请考虑禁用'
L["No conflicting addons"] = "没有冲突插件"
L["Main tank and assist setting disabled"] = "“主坦克和主助理”设置已禁用"
L["Please disable the 'Display Main Tank and Assist' option in Options -> Interface -> Raid Frames"] = "请在选项 -> 界面 -> 团队框体中禁用“显示主坦克和助理”选项"
