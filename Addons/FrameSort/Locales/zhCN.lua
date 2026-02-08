local _, addon = ...
local L = addon.Locale.zhCN

-- # Main Options screen #
-- used in FrameSort - 1.2.3 version header, %s is the version number
L["FrameSort - %s"] = "FrameSort - %s"
L["There are some issues that may prevent FrameSort from working correctly."] = "存在一些问题可能会阻止 FrameSort 正常工作。"
L["Please go to the Health Check panel to view more details."] = "请前往“健康检查”面板查看详细信息。"
L["Role"] = "职责"
L["Spec"] = "专精"
L["Group"] = "小组"
L["Alphabetical"] = "按字母顺序"
L["Arena - 2v2"] = "竞技场 - 2v2"
L["Arena - 3v3"] = "竞技场 - 3v3"
L["Arena - 3v3 & 5v5"] = "竞技场 - 3v3 与 5v5"
L["Enemy Arena (see addons panel for supported addons)"] = "敌方竞技场（支持的插件请见“插件”面板）"
L["Dungeon (mythics, 5-mans, delves)"] = "地下城（大秘境、5 人本、深潜）"
L["Raid (battlegrounds, raids)"] = "团队（战场、团队）"
L["World (non-instance groups)"] = "野外（非副本队伍）"
L["Player"] = "玩家"
L["Sort"] = "排序"
L["Top"] = "顶部"
L["Middle"] = "中间"
L["Bottom"] = "底部"
L["Hidden"] = "隐藏"
L["Group"] = "小组"
L["Reverse"] = "反转"

-- # Sorting Method screen #
L["Sorting Method"] = "排序方式"
L["Secure"] = "安全"
L["SortingMethod_Secure_Description"] = [[
调整每个独立框体的位置，不会让界面出错/锁死/污染。
\n
优点：
 - 可对其他插件的框体进行排序。
 - 可应用框体间距。
 - 无污染（指插件干扰暴雪 UI 代码的技术术语）。
\n
缺点：
 - 为绕过暴雪意大利面条式代码而搭建的脆弱纸牌屋方案。
 - 可能会在魔兽补丁后失效，让开发者发疯。
]]
L["Traditional"] = "传统"
L["SortingMethod_Traditional_Description"] = [[
这是插件和宏使用了 10 多年的标准排序模式。
它会用我们自己的方法替换暴雪内部的排序方法。
这与 'SetFlowSortFunction' 脚本相同，但带有 FrameSort 的配置。
\n
优点：
 - 更加稳定/可靠，因为它利用了暴雪的内部排序方法。
\n
缺点：
 - 只能排序暴雪的小队框体，无法作用于其它框体。
 - 会导致 Lua 错误，这是正常的，可以忽略。
 - 无法应用框体间距。
]]
L["Please reload after changing these settings."] = "更改这些设置后请重新加载。"
L["Reload"] = "重新加载"

-- # Ordering screen #
L["Ordering"] = "排序"
L["Specify the ordering you wish to use when sorting by spec."] = "指定按专精排序时要使用的顺序。"
L["Tanks"] = "坦克"
L["Healers"] = "治疗"
L["Casters"] = "施法者"
L["Hunters"] = "猎人"
L["Melee"] = "近战"

-- # Spec Priority screen # --
L["Spec Priority"] = "专精优先级"
L["Spec Type"] = "专精类型"
L["Choose a spec type, then drag and drop to control priority."] = "选择一个专精类型，然后通过拖拽来调整优先级。"
L["Tank"] = "坦克"
L["Healer"] = "治疗"
L["Caster"] = "远程法系"
L["Hunter"] = "猎人"
L["Melee"] = "近战"
L["Reset this type"] = "重置此类型"
L["Spec query note"] = [[
请注意，专精信息需要从服务器查询，每名玩家大约需要 1–2 秒。
\n
这意味着在我们能够准确排序之前，可能需要等待一小段时间。
]]

-- # Auto Leader screen #
L["Auto Leader"] = "自动队长"
L["Auto promote healers to leader in solo shuffle."] = "在单人乱斗中自动将治疗提升为队长。"
L["Why? So healers can configure target marker icons and re-order party1/2 to their preference."] =
    "为什么？这样治疗可以设置目标标记图标，并按自己的喜好重新排列 party1/2。"
L["Enabled"] = "启用"

-- # Blizzard Keybindings screen (FrameSort's section) #
L["Targeting"] = "目标选择"
L["Target frame 1 (top frame)"] = "选中框体 1（最上方框体）"
L["Target frame 2"] = "选中框体 2"
L["Target frame 3"] = "选中框体 3"
L["Target frame 4"] = "选中框体 4"
L["Target frame 5"] = "选中框体 5"
L["Target bottom frame"] = "选中最底部的框体"
L["Target 1 frame above bottom"] = "选中倒数第 2 个框体"
L["Target 2 frames above bottom"] = "选中倒数第 3 个框体"
L["Target 3 frames above bottom"] = "选中倒数第 4 个框体"
L["Target 4 frames above bottom"] = "选中倒数第 5 个框体"
L["Target frame 1's pet"] = "选中框体 1 的宠物"
L["Target frame 2's pet"] = "选中框体 2 的宠物"
L["Target frame 3's pet"] = "选中框体 3 的宠物"
L["Target frame 4's pet"] = "选中框体 4 的宠物"
L["Target frame 5's pet"] = "选中框体 5 的宠物"
L["Target enemy frame 1"] = "选中敌方框体 1"
L["Target enemy frame 2"] = "选中敌方框体 2"
L["Target enemy frame 3"] = "选中敌方框体 3"
L["Target enemy frame 1's pet"] = "选中敌方框体 1 的宠物"
L["Target enemy frame 2's pet"] = "选中敌方框体 2 的宠物"
L["Target enemy frame 3's pet"] = "选中敌方框体 3 的宠物"
L["Focus enemy frame 1"] = "将敌方框体 1 设为焦点"
L["Focus enemy frame 2"] = "将敌方框体 2 设为焦点"
L["Focus enemy frame 3"] = "将敌方框体 3 设为焦点"
L["Target the next frame"] = "选中下一个框体"
L["Target the previous frame"] = "选中上一个框体"
L["Cycle to the next frame"] = "循环到下一个框体"
L["Cycle to the previous frame"] = "循环到上一个框体"
L["Cycle to the next dps"] = "切换到下一个输出"
L["Cycle to the previous dps"] = "切换到上一个输出"

-- # Keybindings screen #
L["Keybindings"] = "按键绑定"
L["Keybindings_Description"] = [[
你可以在标准的魔兽按键绑定界面找到 FrameSort 的按键绑定。
\n
按键绑定有什么用？
它们可以让你按屏幕上显示的顺序来选择玩家，而不是按
队伍位置（party1/2/3/等）。
\n
例如，假设一个按职责排序的 5 人地下城队伍如下：
  - 坦克，party3
  - 治疗，player
  - DPS，party1
  - DPS，party4
  - DPS，party2
\n
如你所见，他们的可视顺序与实际队伍位置不同，
这会让目标选择变得混乱。
如果你 /target party1，它会选中位于第 3 位的 DPS，而不是坦克。
\n
FrameSort 的按键绑定会基于可视框体位置而不是队伍编号来选中目标。
因此，选择“框体 1”会选中坦克，“框体 2”会选中治疗，“框体 3”会选中第 3 位的 DPS，依此类推。
]]

-- # Macros screen # --
L["Macros"] = "宏"
-- "|4macro:macros;" is a special command to pluralise the word "macro" to "macros" when %d is greater than 1
L["FrameSort has found %d |4macro:macros; to manage."] = "FrameSort 已找到 %d 个可管理的 |4宏:宏;。"
L['FrameSort will dynamically update variables within macros that contain the "#FrameSort" header.'] = 'FrameSort 会动态更新包含 "#FrameSort" 头部的宏中的变量。'
L["Below are some examples on how to use this."] = "以下是一些使用示例。"

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
L["Example %d"] = "示例 %d"
L["Discord Bot Blurb"] = [[
需要帮助来创建宏吗？
\n
前往 FrameSort 的 Discord 服务器，使用我们的 AI 宏机器人！
\n
只需在 #macro-bot-channel 中 '@Macro Bot' 提问即可。
]]

-- # Macro Variables screen # --
L["Macro Variables"] = "宏变量"
L["The first DPS that's not you."] = "第一个不是你的 DPS。"
L["Add a number to choose the Nth target, e.g., DPS2 selects the 2nd DPS."] = "添加数字以选择第 N 个目标，例如，DPS2 选择第 2 个 DPS。"
L["Variables are case-insensitive so 'fRaMe1', 'Dps', 'enemyhealer', etc., will all work."] = "变量不区分大小写，因此 'fRaMe1'、'Dps'、'enemyhealer' 等都可使用。"
L["Need to save on macro characters? Use abbreviations to shorten them:"] = "宏字符不够用？使用缩写来简化："
L['Use "X" to tell FrameSort to ignore an @unit selector:'] = '使用 "X" 告知 FrameSort 忽略一个 @unit 选择器：'
L["Skip_Example"] = [[
#FS X X EnemyHealer
/cast [mod:shift,@focus][@mouseover,harm][@enemyhealer,exists][] Spell;]]

-- # Spacing screen #
L["Spacing"] = "间距"
L["Add some spacing between party, raid, and arena frames."] = "在小队、团队和竞技场框体之间添加一些间距。"
L["This only applies to Blizzard frames."] = "这仅适用于暴雪框体。"
L["Party"] = "小队"
L["Raid"] = "团队"
L["Group"] = "小组"
L["Horizontal"] = "水平"
L["Vertical"] = "垂直"

-- # Addons screen #
L["Addons"] = "插件"
L["Addons_Supported_Description"] = [[
FrameSort 支持以下内容：
\n
  - 暴雪：小队、团队、竞技场。
\n
  - ElvUI：小队。
\n
  - sArena：竞技场。
\n
  - Gladius：竞技场。
\n
  - GladiusEx：小队、竞技场。
\n
  - Cell：小队、团队（仅在使用合并小队时）。
\n
  - Shadowed Unit Frames：小队、竞技场。
\n
  - Grid2：小队、团队。
\n
  - BattleGroundEnemies：小队、竞技场。
\n
  - Gladdy：竞技场。
\n
  - Arena Core: 0.9.1.7+.
\n
]]

-- # Api screen #
L["Api"] = "API"
L["Want to integrate FrameSort into your addons, scripts, and Weak Auras?"] = "想将 FrameSort 集成到你的插件、脚本和 WeakAuras 中吗？"
L["Here are some examples."] = "以下是一些示例。"
L["Retrieved an ordered array of party/raid unit tokens."] = "获取按顺序排列的小队/团队单位标识（unit token）数组。"
L["Retrieved an ordered array of arena unit tokens."] = "获取按顺序排列的竞技场单位标识（unit token）数组。"
L["Register a callback function to run after FrameSort sorts frames."] = "注册回调函数，在 FrameSort 排序框体后运行。"
L["Retrieve an ordered array of party frames."] = "获取按顺序排列的小队框体数组。"
L["Change a FrameSort setting."] = "更改一个 FrameSort 设置。"
L["Get the frame number of a unit."] = "获取单位的框体编号。"
L["View a full listing of all API methods on GitHub."] = "在 GitHub 上查看完整的 API 方法列表。"

-- # Discord screen #
L["Discord"] = "Discord"
L["Need help with something?"] = "需要帮助吗？"
L["Talk directly with the developer on Discord."] = "在 Discord 上直接与开发者交流。"

-- # Health Check screen -- #
L["Health Check"] = "健康检查"
L["Try this"] = "试试这个"
L["Any known issues with configuration or conflicting addons will be shown below."] = "任何已知的配置问题或插件冲突都会显示在下方。"
L["N/A"] = "不适用"
L["Passed!"] = "通过！"
L["Failed"] = "失败"
L["(unknown)"] = "(未知)"
L["(user macro)"] = "(用户宏)"
L["Using grouped layout for Cell raid frames"] = "Cell 团队框体使用分组布局"
L["Please check the 'Combined Groups (Raid)' option in Cell -> Layouts"] = "请在 Cell -> 布局 中勾选“合并小队（团队）”选项"
L["Can detect frames"] = "可检测到框体"
L["FrameSort currently supports frames from these addons: %s"] = "FrameSort 目前支持以下插件的框体：%s"
L["Using Raid-Style Party Frames"] = "正在使用团队风格的小队框体"
L["Please enable 'Use Raid-Style Party Frames' in the Blizzard settings"] = "请在暴雪设置中启用“使用团队风格的小队框体”"
L["Keep Groups Together setting disabled"] = "已禁用“保持小队在一起”设置"
L["Change the raid display mode to one of the 'Combined Groups' options via Edit Mode"] = "请通过“编辑模式”将团队显示模式更改为“合并小队”选项之一"
L["Disable the 'Keep Groups Together' raid profile setting."] = "请禁用团队档案中的“保持小队在一起”设置。"
L["Only using Blizzard frames with Traditional mode"] = "仅在传统模式下使用暴雪框体"
L["Traditional mode can't sort your other frame addons: '%s'"] = "传统模式无法对你的其他框体插件进行排序：'%s'"
L["Using Secure sorting mode when spacing is being used"] = "使用了间距时采用了安全排序模式"
L["Traditional mode can't apply spacing, consider removing spacing or using the Secure sorting method"] = "传统模式无法应用间距，建议移除间距或改用安全排序方式"
L["Blizzard sorting functions not tampered with"] = "暴雪排序函数未被篡改"
L['"%s" may cause conflicts, consider disabling it'] = "“%s”可能导致冲突，建议将其禁用"
L["No conflicting addons"] = "没有冲突的插件"

-- # Log Screen -- #
L["Log"] = "日志"
L["FrameSort log to help with diagnosing issues."] = "FrameSort 日志，用于帮助诊断问题。"
L["Copy Log"] = "复制日志"

-- # Notifications -- #
L["Can't do that during combat."] = "战斗中无法执行该操作。"

-- # Nameplates screen #
L["Nameplates"] = "姓名板"
L["Friendly Nameplates"] = "友方姓名板"
L["Enemy Nameplates"] = "敌方姓名板"
L["NameplatesBlurb"] = [[
将 Blizzard 和 Platynator 的姓名板文本替换为 FrameSort 变量。
\n
支持的变量：
  - $framenumber
  - $name
  - $unit
  - $spec
\n
示例：
  - 框架 - $framenumber
  - $framenumber - $spec
  - $name - $spec
]]

-- # Miscellaneous screen #
L["Miscellaneous"] = "杂项"
L["Various tweaks you can apply."] = "你可以应用的各种调整。"
L["Player top of role"] = "玩家置于角色顶部"
L["Places you at the top of your corresponding role (healer/tank/dps)."] = "将你置于对应角色（治疗/坦克/DPS）的最前位置。"

-- # Language screen #
L["Language"] = "语言"
L["Specify the language we use."] = "指定要使用的语言。"
