-- luacheck: no max line length
-- luacheck: globals DEFAULT_CHAT_FRAME StaticPopupDialogs StaticPopup_Show OKAY YES NO CreateFrame debugprofilestop C_Spell

local _, addonTable = ...;
local string_format, GetSpellTexture, GetSpellInfo, select, tostring, type, pairs, setmetatable, getmetatable, debugprofilestop =
    string.format, C_Spell.GetSpellTexture, C_Spell.GetSpellInfo, select, tostring, type, pairs, setmetatable, getmetatable, debugprofilestop;

function addonTable.Print(...)
    local text = "";
    for i = 1, select("#", ...) do
        text = text..tostring(select(i, ...)).." "
    end
    DEFAULT_CHAT_FRAME:AddMessage(string_format("NameplateCooldowns: %s", text), 0, 128, 128);
end

function addonTable.deepcopy(object)
	local lookup_table = {}
	local function _copy(another_object)
		if type(another_object) ~= "table" then
			return another_object;
		elseif lookup_table[another_object] then
			return lookup_table[another_object];
		end
		local new_table = { };
		lookup_table[another_object] = new_table;
		for index, value in pairs(another_object) do
			new_table[_copy(index)] = _copy(value);
		end
		return setmetatable(new_table, getmetatable(another_object));
	end
	return _copy(object);
end

function addonTable.colorize_text(text, r, g, b)
    return string_format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text);
end

function addonTable.table_count(t)
    local count = 0;
    for _ in pairs(t) do
        count = count + 1;
    end
    return count;
end

function addonTable.msg(text)
    local name = "NCOOLDOWNS_MSG";
    if (StaticPopupDialogs[name] == nil) then
        StaticPopupDialogs[name] = {
            text = name,
            button1 = OKAY,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        };
    end
    StaticPopupDialogs[name].text = text;
    StaticPopup_Show(name);
end

function addonTable.msgWithQuestion(text, funcOnAccept, funcOnCancel)
    local frameName = "NameplateCooldowns_msgWithQuestion";
    if (StaticPopupDialogs[frameName] == nil) then
        StaticPopupDialogs[frameName] = {
            button1 = YES,
            button2 = NO,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        };
    end
    StaticPopupDialogs[frameName].text = text;
    StaticPopupDialogs[frameName].OnAccept = funcOnAccept;
    StaticPopupDialogs[frameName].OnCancel = funcOnCancel;
    StaticPopup_Show(frameName);
end

addonTable.SpellTextureByID = setmetatable({
	[addonTable.SPELL_PVPTRINKET] =	1322720,
    [42292] =                       1322720,
	[200166] =				        1247262,
}, {
	__index = function(t, key)
		local texture = GetSpellTexture(key);
		t[key] = texture;
		return texture;
	end
});

addonTable.SpellNameByID = setmetatable({}, {
	__index = function(t, key)
		local spellInfo = GetSpellInfo(key);
		local name = spellInfo ~= nil and spellInfo.name or nil;

		t[key] = name;
		return name;
	end
});

-- // CoroutineProcessor
do
    local CoroutineProcessor = {};
    CoroutineProcessor.frame = CreateFrame("frame");
    CoroutineProcessor.update = {};
    CoroutineProcessor.size = 0;

    function addonTable.coroutine_queue(name, func)
        if (not name) then
            name = string_format("NIL%d", CoroutineProcessor.size + 1);
        end
        if (not CoroutineProcessor.update[name]) then
            CoroutineProcessor.update[name] = func;
            CoroutineProcessor.size = CoroutineProcessor.size + 1;
            CoroutineProcessor.frame:Show();
        end
    end

    function addonTable.coroutine_delete(name)
        if (CoroutineProcessor.update[name]) then
            CoroutineProcessor.update[name] = nil;
            CoroutineProcessor.size = CoroutineProcessor.size - 1;
            if (CoroutineProcessor.size == 0) then
                CoroutineProcessor.frame:Hide();
            end
        end
    end

    CoroutineProcessor.frame:Hide();
    CoroutineProcessor.frame:SetScript("OnUpdate", function()
        local start = debugprofilestop();
        local hasData = true;
        while (debugprofilestop() - start < 16 and hasData) do
            hasData = false;
            for name, func in pairs(CoroutineProcessor.update) do
                hasData = true;
                if (coroutine.status(func) ~= "dead") then
                    assert(coroutine.resume(func));
                else
                    addonTable.coroutine_delete(name);
                end
            end
        end
    end);
end

