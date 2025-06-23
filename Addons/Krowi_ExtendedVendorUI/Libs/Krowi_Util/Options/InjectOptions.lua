--[[
    Copyright (c) 2023 Krowi

    All Rights Reserved unless otherwise explicitly stated.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local _, addon = ...;
addon.InjectOptions = {};
local injectOptions = addon.InjectOptions;

function injectOptions.AdjustedWidth(number)
    return (number or 1) * (addon.Options.WidthMultiplier or 170); -- Default Ace3
end

local autoOrder = 1;
function injectOptions.AutoOrderPlusPlus(amount)
    local current = autoOrder;
    autoOrder = autoOrder + (1 or amount);
    return current;
end

function injectOptions.PlusPlusAutoOrder(amount)
    autoOrder = autoOrder + (1 or amount);
    return autoOrder;
end

function injectOptions:AddTable(destTablePath, key, table)
    local destTable;
    if type(destTablePath) == "table" then
        destTable = destTablePath;
    elseif type(destTablePath) == "string" then
        destTable = addon.Options.OptionsTable.args;
        local pathParts = strsplittable(".", destTablePath);
        for _, part in next, pathParts do
            destTable = destTable[part];
        end
    end
    destTable[key] = table;
    return destTable[key];
end

function injectOptions:GetTable(destTablePath)
    local destTable = addon.Options.OptionsTable.args;
    local pathParts = strsplittable(".", destTablePath);
    for _, part in next, pathParts do
        destTable = destTable[part];
    end
    return destTable;
end

function injectOptions:TableExists(destTablePath)
    local destTable = addon.Options.OptionsTable.args;
    local pathParts = strsplittable(".", destTablePath);
    for _, part in next, pathParts do
        destTable = destTable[part];
    end
    return destTable and true or false;
end

function injectOptions:AddDefaults(destTablePath, key, table)
    local destTable = addon.Options.Defaults.profile;
    local pathParts = strsplittable(".", destTablePath);
    for _, part in next, pathParts do
        destTable = destTable[part];
    end
    destTable[key] = table;
end

function injectOptions:DefaultsExists(destTablePath)
    local destTable = addon.Options.Defaults.profile;
    local pathParts = strsplittable(".", destTablePath);
    for _, part in next, pathParts do
        destTable = destTable[part];
    end
    return destTable and true or false;
end

function injectOptions:AddPluginTable(pluginName, pluginDisplayName, desc, loadedFunc)
    local OrderPP = self.AutoOrderPlusPlus;
    return self:AddTable("Plugins.args", pluginName, {
        type = "group",
        name = pluginDisplayName,
        args = {
            Loaded = {
                order = OrderPP(), type = "toggle", width = "full",
                name = addon.Util.L["Loaded"],
                desc = addon.Util.L["Loaded Desc"],
                descStyle = "inline",
                get = loadedFunc,
                disabled = true
            },
            Line = {
                order = OrderPP(), type = "header", width = "full",
                name = ""
            },
            Description = {
                order = OrderPP(), type = "description", width = "full",
                name = desc,
                fontSize = "medium"
            }
        }
    }).args;
end