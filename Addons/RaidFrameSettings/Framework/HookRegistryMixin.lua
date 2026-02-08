--[[Created by Slothpala]]--
local _, private = ...
private.Mixins.HookRegistryMixin = {}
local HookRegistryMixin = private.Mixins.HookRegistryMixin

------------------------
--- Speed references ---
------------------------

-- Lua
local _G = _G
local tostring = tostring
local next = next
-- WoW Api
local hooksecurefunc = hooksecurefunc

-- local tables storing information about active hooks and their callbacks
local hooked = {}
local callbacks = {}
local registry = {}

local function get_hook_id(module, obj, func_name)
  local id = tostring(module) .. tostring(obj) .. tostring(func_name)
  return id
end

local function prepare_callback_table(obj, func_name)
  if not callbacks[obj] then
    callbacks[obj] = {}
  end
  if not callbacks[obj][func_name] then
    callbacks[obj][func_name] = {}
  end
end

local function is_hooked(obj, func_name)
  return hooked[obj] and hooked[obj][func_name]
end

local function register_hook(obj, func_name)
  if not hooked[obj] then
    hooked[obj] = {}
  end
  hooked[obj][func_name] = true
end

local function register_module_hook(module, id, obj, func_name)
  if not registry[module] then
    registry[module] = {}
  end
  registry[module][id] = {
    ["key1"] = obj,
    ["key2"] = func_name,
  }
end


--------------------------
--- HookScript Wrapper ---
--------------------------


--- Wrapper around the HookScript function https://warcraft.wiki.gg/wiki/API_ScriptObject_HookScript
---@param ScriptObject table abstract widget
---@param scriptTypeName string The name of the script type, e.g. "OnShow", "OnHide" etc.
---@param callback_func function The function that will be called when the script is executed
function HookRegistryMixin:HookScript(ScriptObject, scriptTypeName, callback_func)
  -- Determine the callback func
  local callback = type(callback_func) == "string" and self[callback_func] or callback_func
  -- get a an id
  local id = get_hook_id(self, ScriptObject, scriptTypeName)
  -- Prepare the callback table if needed
  prepare_callback_table(ScriptObject, scriptTypeName)
  callbacks[ScriptObject][scriptTypeName][self] = callback
  if not is_hooked(ScriptObject, scriptTypeName) then
    ScriptObject:HookScript(scriptTypeName, function()
      for _, callback in next, callbacks[ScriptObject][scriptTypeName] do
        callback()
      end
    end)
    register_hook(ScriptObject, scriptTypeName)
  end
  -- Register the hook to  enable unhooking without id
  register_module_hook(self, id, ScriptObject, scriptTypeName)
end


------------------------------
--- hooksecurefunc Wrapper ---
------------------------------
--- CAUTION: A function should either be hooked filtered or unfiltered. That applies addon wide. No check will be done.


--- Wrapper around hooksecurefunc https://warcraft.wiki.gg/wiki/API_hooksecurefunc
---@param arg1 table The table where the function to be hooked into is stored. If omitted, it defaults to _G.
---@param arg2 string Name of the function to be hooked.
---@param arg3 function The function that will be called when the function to be hooked is executed.
function HookRegistryMixin:HookFunc(arg1, arg2, arg3)
  -- Determine the table where the to be hooked function is stored in.
  local obj, func_name, callback_func
  if type(arg1) == "table" then
    obj = arg1
    func_name = arg2
    callback_func = arg3
  else
    obj = _G
    func_name = arg1
    callback_func = arg2
  end
  -- get a an id
  local id = get_hook_id(self, obj, func_name)
  -- Determine the callback func
  local callback = type(callback_func) == "string" and self[callback_func] or callback_func
  -- Prepare the callback table if needed
  prepare_callback_table(obj, func_name)
  callbacks[obj][func_name][self] = callback
  -- Check if the function is already hooked
  if not is_hooked(obj, func_name) then
    hooksecurefunc(obj, func_name, function(...)
      for _, callback in next, callbacks[obj][func_name] do
        callback(...)
      end
    end)
    register_hook(obj, func_name)
  end
  -- Register the hook to  enable unhooking without id
  register_module_hook(self, id, obj, func_name)
end

--- Wrapper around hooksecurefunc https://warcraft.wiki.gg/wiki/API_hooksecurefunc but modified for CompactUnitFrame_ functions that have frame as their first parameter.
--- Unwanted frames will be filtered out.
---@param arg1 table The table where the function to be hooked into is stored. If omitted, it defaults to _G.
---@param arg2 string Name of the function to be hooked.
---@param arg3 function The function that will be called when the function to be hooked is executed.
function HookRegistryMixin:HookFunc_CUF_Filtered(arg1, arg2, arg3)
  -- Determine the table where the to be hooked function is stored in.
  local obj, func_name, callback_func
  if type(arg1) == "table" then
    obj = arg1
    func_name = arg2
    callback_func = arg3
  else
    obj = _G
    func_name = arg1
    callback_func = arg2
  end
  -- get a an id
  local id = get_hook_id(self, obj, func_name)
  -- Determine the callback func
  local callback = type(callback_func) == "string" and self[callback_func] or callback_func
  -- Prepare the callback table if needed
  prepare_callback_table(obj, func_name)
  callbacks[obj][func_name][self] = callback
  -- Check if the function is already hooked
  if not is_hooked(obj, func_name) then
    hooksecurefunc(obj, func_name, function(frame, ...)
      -- TODO Filter frames here
      -- Filter out forbidden frames in this case friendly nameplates in instanced content.
      if not frame or not frame.unit or frame:IsForbidden() then
        return
      end
      -- Filter out all other nameplates. Nameplates are unnamed.
      local name = frame:GetName()
      if not name then
        return
      end
      for _, callback in next, callbacks[obj][func_name] do
        callback(frame, ...)
      end
    end)
    register_hook(obj, func_name)
  end
  -- Register the hook to  enable unhooking without id
  register_module_hook(self, id, obj, func_name)
end


--------------
--- Unhhok ---
--------------


--- Unhook a hooked script or function
---@param arg1 any Either the hooked ScriptObject (table) or the hooked function (string)
---@param arg2 any If arg1 is the ScriptObject then arg2 is the function that is to be unhooked
function HookRegistryMixin:Unhook(arg1, arg2)
  if not registry[self] then
    return
  end
  local obj, func_name
  if type(arg1) == "table" then
    obj = arg1
    func_name = arg2
  else
    obj = _G
    func_name = arg1
  end
  local id = get_hook_id(self, obj, func_name)
  local entry = registry[self][id]
  callbacks[entry.key1][entry.key2][self] = nil
end

--- Disable all hooks for the object
function HookRegistryMixin:DisableHooks()
  if not registry[self] then
    return
  end
  for _, entry in next, registry[self] do
    callbacks[entry.key1][entry.key2][self] = nil
  end
end
