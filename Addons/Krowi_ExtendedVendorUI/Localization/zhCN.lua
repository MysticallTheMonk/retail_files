local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "zhCN");
if not L then return end
addon.L = L;

addon.Plugins:LoadLocalization(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-extended-vendor-ui/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2025-05-15 18-40-48 ]] --
L["Are you sure you want to hide the options button?"] = "是否确定隐藏按钮？再次显示按钮请到 {gameMenu} > {addOns} > 商人 > {general} > {options}"
L["Author"] = "作者"
L["Build"] = "版本"
L["Checked"] = "启用"
L["Columns"] = "列数"
L["Columns first"] = "先竖后横排列"
L["CurseForge"] = true
L["CurseForge Desc"] = "显示 {addonName} 的 {curseForge} 插件页面链接。"
L["Custom"] = "自定义"
L["Default filters"] = "默认过滤器"
L["Default value"] = "预设值"
L["Deselect All"] = "全部取消"
L["Discord"] = true
L["Discord Desc"] = "显示 {serverName} Discord 服务器的链接。可以留言、评论、报告问题、想法，或其他任何有关的內容。"
L["Filters"] = "过滤器"
L["Hide"] = "隐藏"
L["Hide collected"] = "隐藏已拥有的"
L["Icon Left click"] = "快速版面配置"
L["Icon Right click"] = "设定选项"
L["Left click"] = "左键点击"
L["Mounts"] = "坐骑"
L["Only show"] = "只显示"
L["Options button"] = "选项按钮"
L["Options Desc"] = "打开选项，也可以从商人界面左上方的选项按钮打开选项。"
L["Other"] = "其他"
L["Pets"] = "宠物"
L["Plugins"] = "插件"
L["Right click"] = "右键点击"
L["Rows"] = "行数"
L["Rows first"] = "先横竖后排列"
L["Select All"] = "全部选择"
L["Show minimap icon"] = "显示小地图按钮"
L["Show minimap icon Desc"] = "显示/隐藏小地图按钮"
L["Show options button"] = "显示设置按钮"
L["Show options button Desc"] = "显示/隐藏商人界面的设置按钮"
L["Toys"] = "玩具"
L["Unchecked"] = "停用"
L["Wago"] = true
L["Wago Desc"] = "显示 {addonName} 的 {wago} 插件页面链接"
L["WoWInterface"] = true
L["WoWInterface Desc"] = "显示 {addonName} 的 {woWInterface} 插件页面链接"