--[[Created by Slothpala]]--
local addon_name, private = ...
local addon = _G[addon_name]
private.UnitCache = {}
local UnitCache = private.UnitCache

------------------------
--- Speed references ---
------------------------

-- Lua

-- WoW Api
local UnitGUID = UnitGUID
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local UnitName = UnitName
local issecretvalue = issecretvalue

-------------
--- Cache ---
-------------

local unit_cache = {}

local fallback_cache_entry = {
  name = "Missing data",
  nickname = "Missing data",
  name_and_realm_name = "Missing data",
  realm = "Missing data",
  class = "PRIEST",
}

local nicknames = {}

function addon:UpdateNicknames()
  nicknames = CopyTable(self.db.profile.Nicknames)
  for _, cached_unit in next, unit_cache do
    if nicknames[cached_unit.name_and_realm_name] or nicknames[cached_unit.name] then
      cached_unit.nickname = nicknames[cached_unit.name_and_realm_name] or nicknames[cached_unit.name]
    end
  end
end

--- For cases were GetPlayerInfoByGUID doesn't work
---@param guid string The units GUID
local function get_unit_token_from_guid(guid)
  local unit_token
  if guid == UnitGUID("player") then
    return "player"
  end
  for i=1, 4 do
    unit_token = "party" .. i
    if guid == UnitGUID(unit_token) then
      return unit_token
    end
  end
  for i=1, 40 do
    unit_token = "raid" .. i
    if guid == UnitGUID(unit_token) then
      return unit_token
    end
  end
  return false
end

local function validate_cache(cache)
  local is_valid_name = type(cache.name) == "string"
  local is_valid_nickname = type(cache.nickname) == "string"
  local is_valid_realm = type(cache.realm) == "string"
  local is_valid_class = ( type(cache.class) == "string" ) and ( RAID_CLASS_COLORS[cache.class] ~= nil )
  return is_valid_name and is_valid_nickname and is_valid_realm and is_valid_class
end

local my_realm_name = GetRealmName():gsub("[%s%-]", "")

---@param guid string the GUID of the unit.
---@return table unit_cache the new unit cache entry or fallback.
local function new_unit_cache(guid)
  -- This data appears to be cached by the game and may not always be immediately available.
  local _, english_class, _, _, _, name, realm_name = GetPlayerInfoByGUID(guid)
  -- If the data isn't available jet find the designated unit token and use this.
  if not english_class then
    local unit_token = get_unit_token_from_guid(guid)
    if not unit_token then
      return fallback_cache_entry
    else
      english_class = select(2, UnitClass(unit_token))
      name, realm_name = UnitName(unit_token)
    end
  end
  -- realm_name is an empty string if the player is from the same realm.
  local realm_name = ( realm_name and #realm_name > 0 ) and realm_name or my_realm_name
  local name_and_realm_name = name .. "-" .. realm_name
  local cached_unit = {
    name = name,
    nickname = nicknames[name_and_realm_name] or nicknames[name] or name,
    name_and_realm_name = name_and_realm_name,
    realm = realm_name,
    class = english_class,
  }
  local is_valid = validate_cache(cached_unit)
  if not is_valid then
    return fallback_cache_entry
  end
  unit_cache[guid] = cached_unit
  return cached_unit
end

--- Get a units cache by GUID or build one if not existing.
---@param guid string The GUID of the unit.
---@return table unit_cache The cached data for the unit
function UnitCache.Get(guid)
  if not guid or issecretvalue(guid) then
    return fallback_cache_entry
  end
  return unit_cache[guid] or new_unit_cache(guid)
end

--- Dump the cache
function UnitCache.Dump()
  unit_cache = {}
end

------------------------
--- Update Functions ---
------------------------

local update_frame = CreateFrame("Frame")
update_frame:SetScript("OnEvent", function(self, event, ...)
  if event == "UNIT_NAME_UPDATE" then
    local unit_token = ...
    local guid = UnitGUID(unit_token)
    if not guid or issecretvalue(guid) then
      return
    end
    if unit_cache[guid] then
      local new_name, new_realm_name = UnitName(unit_token)
      if not new_realm_name then
        new_realm_name = my_realm_name
      end
      local new_name_and_realm_name = new_name .. "-" .. new_realm_name
      unit_cache[guid].name = new_name or ""
      unit_cache[guid].nickname = nicknames[new_name_and_realm_name] or nicknames[new_name] or new_name or ""
      unit_cache[guid].realm_name = new_realm_name or ""
      unit_cache[guid].realm = new_realm_name or ""
    end
  end
end)

-- Check for name updates
update_frame:RegisterEvent("UNIT_NAME_UPDATE")
