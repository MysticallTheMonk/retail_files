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

local lib = LibStub:NewLibrary("Krowi_Util-1.0", 12);

if not lib then
	return;
end

local version = (GetBuildInfo());
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)");
lib.IsWrathClassic = major == "3";
lib.IsCataClassic = major == "4";
lib.IsClassicWithAchievements = lib.IsWrathClassic or lib.IsCataClassic;
lib.IsDragonflight = major == "10";
lib.IsTheWarWithin = major == "11";
lib.IsMainline = lib.IsDragonflight or lib.IsTheWarWithin;

function lib.ConcatTables(t1, t2)
    if t2 then
        for _, e in next, t2 do
            tinsert(t1, e);
        end
    end
    return t1;
end

function lib.InjectMetatable(tbl, meta)
    return setmetatable(tbl, setmetatable(meta, getmetatable(tbl)));
end

function lib.DeepCopyTable(src, dest)
	for index, value in pairs(src) do
		if type(value) == "table" then
			dest[index] = {};
			lib.DeepCopyTable(value, dest[index]);
		else
			dest[index] = value;
		end
	end
end

function lib.ReadNestedKeys(tbl, keys)
    for _, k in ipairs(keys) do
       tbl = tbl[k];
       if tbl == nil then
          break;
       end
    end
    return tbl;
 end

function lib.WriteNestedKeys(tbl, keys, value)
    local prev_tbl, last_k;
    for _, k in ipairs(keys) do
       last_k, prev_tbl, tbl = k, tbl, tbl[k];
       if tbl == nil then
          tbl = {};
          prev_tbl[k] = tbl;
       end
    end
    prev_tbl[last_k] = value;
 end

function lib.Enum(table)
    for i, element in next, table do
        local tmp = element;
        table[tmp] = i;
    end
    return table;
end

function lib.Enum2(table)
    local tbl = {};
    for i, element in next, table do
        local tmp = element;
        tbl[tmp] = i;
    end
    return tbl;
end

function lib.StringSplitTable(delimiter, str)
    local chunks = {};
    for s in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        tinsert(chunks, s);
    end
    return chunks;
end

lib.DelayObjects = {};
function lib.DelayFunction(delayObjectName, delayTime, func, ...)
    if lib.DelayObjects[delayObjectName] ~= nil then
        return;
    end
    local args = {...};
    lib.DelayObjects[delayObjectName] = C_Timer.NewTimer(delayTime, function()
        func(unpack(args));
        lib.DelayObjects[delayObjectName] = nil;
    end);
end

function lib.TableRemoveByValue(table, value)
    for key, _value in pairs(table) do
        if _value == value then
            tremove(table, key);
            return true;
        end
    end
    return false;
end

function lib.TableFindKeyByValue(table, value)
    for key, _value in next, table do
        if _value == value then
            return key;
        end
    end
end

function lib.SafeGet(source, path)
    local current = source;
    for _, key in next, path do
        current = current[key];
        if current == nil then
            return nil;
        end
    end
    return current;
end

function lib.IsType(value, _type)
    return type(value) == _type;
end

function lib.IsNil(value)
    return lib.IsType(value, "nil");
end

function lib.IsNumber(value)
    return lib.IsType(value, "number");
end

function lib.IsString(value)
    return lib.IsType(value, "string");
end

function lib.IsBoolean(value)
    return lib.IsType(value, "boolean");
end

function lib.IsTable(value)
    return lib.IsType(value, "table");
end

function lib.IsFunction(value)
    return lib.IsType(value, "function");
end

function lib.IsThread(value)
    return lib.IsType(value, "thread");
end

function lib.IsUserData(value)
    return lib.IsType(value, "userdata");
end