--[[
    Copyright (c) 2023 Krowi

    All Rights Reserved unless otherwise explicitly stated.

    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

---@diagnostic disable: undefined-global

local _, addon = ...
addon.Options = {}
local options = addon.Options
local name = addon.Metadata.Title

options.OptionsTables = {}
options.WidthMultiplier = addon.Util.IsMainline and 200 / 170 or 1 -- 170 comes from AceConfigDialog-3.0.lua, 200 fits better on the screen in DF

options.OptionsTable = {
    name = name,
    type = 'group',
    childGroups = 'tab',
    args = {}
}

local onProfileChangedFunctions = {}
function options.OnProfileChanged(db, newProfile)
    for _, func in next, onProfileChangedFunctions do
        func(db, newProfile)
    end
end

local onProfileCopiedFunctions = {}
function options.OnProfileCopied(db, sourceProfile)
    for _, func in next, onProfileCopiedFunctions do
        func(db, sourceProfile)
    end
end

local onProfileResetFunctions = {}
function options.OnProfileReset(db)
    for _, func in next, onProfileResetFunctions do
        func(db)
    end
end

function options:Load(manualProfilesTable)
    self.db = LibStub('AceDB-3.0'):New(addon.Metadata.Prefix .. '_Options', self.Defaults, true)
    self.db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
    self.db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileCopied')
    self.db.RegisterCallback(self, 'OnProfileReset', 'OnProfileReset')
    if not manualProfilesTable then
        self.OptionsTable.args.Profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    end

    for _, optionsTable in next, self.OptionsTables do
        if type(optionsTable.RegisterOptionsTable) == 'function' then
            optionsTable.RegisterOptionsTable()
        end
        if type(optionsTable.PostLoad) == 'function' then
            optionsTable.PostLoad()
        end
        if type(optionsTable.OnProfileChanged) == 'function' then
            tinsert(onProfileChangedFunctions, optionsTable.OnProfileChanged)
        end
        if type(optionsTable.OnProfileCopied) == 'function' then
            tinsert(onProfileCopiedFunctions, optionsTable.OnProfileCopied)
        end
        if type(optionsTable.OnProfileReset) == 'function' then
            tinsert(onProfileResetFunctions, optionsTable.OnProfileReset)
        end
    end
end


function options:Open()
    if addon.Util.IsWrathClassic then
        InterfaceAddOnsList_Update() -- This way the correct category will be shown when calling InterfaceOptionsFrame_OpenToCategory
        InterfaceOptionsFrame_OpenToCategory(name)
        for _, button in next, InterfaceOptionsFrameAddOns.buttons do
            if button.element and button.element.name == name and button.element.collapsed then
                OptionsListButtonToggle_OnClick(button.toggle)
                break
            end
        end
        return
    end

    local categoryId = LibStub("AceConfigDialog-3.0").BlizOptionsIDMap[name]
    Settings.OpenToCategory(categoryId, name)
end

string[addon.Metadata.Acronym .. '_InjectAddonName'] = function(str)
    return str:K_ReplaceVars{addonName = addon.Metadata.Title}
end

string[addon.Metadata.Acronym .. '_AddDefaultValueText'] = function(str, valuePath, values)
    return str:K_AddDefaultValueText(options.Defaults.profile, valuePath, values)
end