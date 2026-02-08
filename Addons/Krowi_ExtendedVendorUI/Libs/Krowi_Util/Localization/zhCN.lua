--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then	return end

local L = lib.Localization.NewLocale('zhCN')
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-01-12 19-39-26 ]] --
L['Author'] = '作者'
L['Build'] = '版本'
L['Checked'] = '启用'
L['Credits'] = '鸣谢'
L['CurseForge'] = true
L['CurseForge Desc'] = '显示 {addonName} 的 {curseForge} 插件页面链接。'
L['Default value'] = '预设值'
L['Deselect All'] = '全部取消'
L['Discord'] = true
L['Discord Desc'] = '显示 {serverName} Discord 服务器的链接。可以留言、评论、报告问题、想法，或其他任何有关的內容。'
L['Donations'] = '捐赠'
L['Hide'] = '隐藏'
L['Left click'] = '左键点击'
L['Left-Click'] = '左键点击'
L['Loaded'] = '已加载'
L['Loaded Desc'] = '显示插件相关的插件是否已加载。'
L['Localizations'] = '本地化'
L['Plugins'] = '插件'
L['Profiles'] = '配置文件'
L['Requires a reload'] = '需要重载界面'
L['Right click'] = '右键点击'
L['Right-Click'] = '右键点击'
L['Select All'] = '全部选择'
L['Show minimap icon'] = '显示小地图按钮'
L['Show minimap icon Desc'] = '显示/隐藏小地图按钮'
L['Special thanks'] = '特别感谢'
L['Unchecked'] = '停用'
L['Wago'] = true
L['Wago Desc'] = '显示 {addonName} 的 {wago} 页面链接。'