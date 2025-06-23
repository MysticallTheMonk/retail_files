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

local lib = LibStub("Krowi_Util-1.0");

if not lib then
	return;
end

lib.Strings = {};
local strings = lib.Strings;

function strings.ReplaceVars(str, vars)
    -- Allow ReplaceVars{str, vars} syntax as well as ReplaceVars(str, {vars})
    if not vars then
        vars = str;
        str = vars[1];
    end
    return (string.gsub(str, "({([^}]+)})", function(whole, i)
        if type(vars) == "table" then
            return vars[i] or whole;
        else
            return vars;
        end
    end));
end
string.K_ReplaceVars = strings.ReplaceVars;

function strings.AddReloadRequired(str)
    return str .. "\n\n" .. lib.L["Requires a reload"];
end
string.K_AddReloadRequired = strings.AddReloadRequired;

function strings.AddDefaultValueText(str, startTbl, valuePath, values)
    local value = startTbl;
    local pathParts = strsplittable(".", valuePath);
    for _, part in next, pathParts do
        part = tonumber(part) and tonumber(part) or part;
        value = value[part];
    end
    if type(value) == "boolean" then
        value = value and lib.L["Checked"] or lib.L["Unchecked"];
    end
    if values then
        value = values[value];
    end
    return str .. "\n\n" .. lib.L["Default value"] .. ": " .. tostring(value);
end
string.K_AddDefaultValueText = strings.AddDefaultValueText;