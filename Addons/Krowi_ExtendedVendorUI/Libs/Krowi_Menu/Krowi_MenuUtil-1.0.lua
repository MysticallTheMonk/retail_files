--[[
	Krowi's Menu License
        Copyright ©2024 The contents of this library, excluding third-party resources, are
        copyrighted to their authors with all rights reserved.

        This library is free to use and the authors hereby grants you the following rights:

        1. 	You may make modifications to this library for private use only, you
            may not publicize any portion of this library. The only exception being you may
            upload to the github website.

        2. 	Do not modify the name of this library, including the library folders.

        3. 	This copyright notice shall be included in all copies or substantial
            portions of the Software.

        All rights not explicitly addressed in this license are reserved by
        the copyright holders.
]]

local lib = LibStub:NewLibrary("Krowi_MenuUtil-1.0", 2);

if not lib then
	return;
end

do -- Modern
    function lib:CreateTitle(menu, text)
        menu:CreateTitle(text);
    end

    function lib:CreateButton(menu, text, func, isEnabled)
        local button = menu:CreateButton(text, func);
        if isEnabled == false then
            button:SetEnabled(false);
        end
        return button;
    end

    function lib:CreateDivider(menu)
        menu:CreateDivider();
    end

    function lib:AddChildMenu(menu, child)

    end

    function lib:CreateButtonAndAdd(menu, text, func, isEnabled)
        return self:CreateButton(menu, text, func, isEnabled);
    end
end

if LibStub("Krowi_Util-1.0").IsTheWarWithin then
    return;
end

do -- Classic
    function lib:CreateTitle(menu, text)
        menu:AddTitle(text);
    end

    function lib:CreateButton(menu, text, func, isEnabled)
        return LibStub("Krowi_MenuItem-1.0"):New({
            Text = text,
            Func = func,
            Disabled = isEnabled == false
        });
    end

    function lib:CreateDivider(menu)
        menu:AddSeparator();
    end

    function lib:AddChildMenu(menu, child)
        if not menu or not child then
            return;
        end
        menu:Add(child);
    end

    function lib:CreateButtonAndAdd(menu, text, func, isEnabled)
        self:AddChildMenu(menu, self:CreateButton(nil, text, func, isEnabled));
    end
end