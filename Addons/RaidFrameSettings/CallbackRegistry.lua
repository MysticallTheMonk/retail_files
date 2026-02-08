local private = select(2, ...)
private.CallbackRegistry = {}
local CR = private.CallbackRegistry

local next = next

local callbacks = {}

local counter = 0
local function get_id()
  counter = counter + 1
  return counter
end


function CR.RegisterCallback(event, callback)
  callbacks[event] =  callbacks[event] or {}
  local id = get_id()
  callbacks[event][id] = callback
  return id
end

function CR.UnregisterCallback(event, id)
  if not callbacks[event] then
    return
  end
  callbacks[event][id] = nil
end

function CR.Fire(event, ...)
  if not callbacks[event] then
    return
  end
  for _, callback in next, callbacks[event] do
    callback(...)
  end
end
