--[[
	Krowi's Menu License
        Copyright ©2020 The contents of this library, excluding third-party resources, are
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

local lib = LibStub:NewLibrary("Krowi_MenuItem-1.0", 4);

if not lib then
	return;
end

local popupDialog = LibStub("Krowi_PopopDialog-1.0");

lib.__index = lib;
function lib:New(info, hideOnClick)
    local instance = setmetatable({}, lib);
    if type(info) == "string" then
        info = {
            Text = info,
            KeepShownOnClick = not hideOnClick
        };
    end
    for k, v in next, info do
        instance[k] = v;
    end
    return instance;
end

function lib:NewExtLink(text, externalLink)
    return self:New({
        Text = text,
        Func = function()
            popupDialog.ShowExternalLink(externalLink);
        end
    });
end

function lib:Add(item)
    if self.Children == nil then
        self.Children = {}; -- By creating the children table here we reduce memory usage because not every category has children
    end
    tinsert(self.Children, item);
    return item;
end

function lib:AddFull(info)
    return self:Add(self:New(info));
end

function lib:AddTitle(text)
    self:AddFull({
		Text = text,
		IsTitle = true
	});
end

function lib:AddSeparator()
    return self:AddFull({IsSeparator = true});
end

function lib:AddExtLinkFull(text, externalLink)
    return self:Add(self:NewExtLink(text, externalLink));
end