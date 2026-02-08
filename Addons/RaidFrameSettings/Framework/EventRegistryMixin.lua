local _, private = ...
-- This mixin allows modules to register/unregister for WoW events using a single frame.

local EventRegistry = {}
private.Mixins["EventRegistry"] = EventRegistry

-- The event handling frame
local eventFrame = CreateFrame("Frame")

-- Stores event callbacks by event name and module.
-- Structure: callbacks[event][module] = { callback1, callback2, ... }
-- For unit events, the callback is stored as a table: { unit = <unit>, callback = <function> }
local callbacks = {}

----------------------------------------------------------------
-- Registers a callback for an event.
-- (Called as module:RegisterForEvent(event, callback))
-- @param event    The event string (e.g., "PLAYER_LOGIN")
-- @param callback The function to call when the event occurs.
----------------------------------------------------------------
function EventRegistry:RegisterForEvent(event, callback)
  if not callbacks[event] then
    callbacks[event] = {}
    eventFrame:RegisterEvent(event)
  end

  if not callbacks[event][self] then
    callbacks[event][self] = {}
  end

  table.insert(callbacks[event][self], callback)
end

----------------------------------------------------------------
-- Registers a callback for a unit-specific event.
-- (Called as module:RegisterForUnitEvent(event, unit, callback))
-- @param event    The event string (e.g., "UNIT_HEALTH")
-- @param unit     The unit id (e.g., "player")
-- @param callback The function to call when the event occurs for the specified unit.
----------------------------------------------------------------
function EventRegistry:RegisterForUnitEvent(event, unit, callback)
  if not callbacks[event] then
    callbacks[event] = {}
    eventFrame:RegisterUnitEvent(event, unit)
  else
    -- Even if the event is already registered, add the new unit.
    eventFrame:RegisterUnitEvent(event, unit)
  end

  if not callbacks[event][self] then
    callbacks[event][self] = {}
  end

  -- Store the unit along with the callback.
  table.insert(callbacks[event][self], { unit = unit, callback = callback })
end

----------------------------------------------------------------
-- Unregisters a callback for an event.
-- (Called as module:UnregisterFromEvent(event, callback [, unit]))
-- @param event    The event string.
-- @param callback The callback function to remove.
-- @param unit     (Optional) If provided, only unregister the callback for this unit.
----------------------------------------------------------------
function EventRegistry:UnregisterFromEvent(event, callback, unit)
  if not callbacks[event] or not callbacks[event][self] then
    return
  end

  local moduleCallbacks = callbacks[event][self]
  for i = #moduleCallbacks, 1, -1 do
    local cb = moduleCallbacks[i]
    if type(cb) == "table" then
      if cb.callback == callback then
        if unit then
          if cb.unit == unit then
            table.remove(moduleCallbacks, i)
          end
        else
          table.remove(moduleCallbacks, i)
        end
      end
    else
      -- For non-unit callbacks, only remove if no unit is specified.
      if cb == callback and not unit then
        table.remove(moduleCallbacks, i)
      end
    end
  end

  if #moduleCallbacks == 0 then
    callbacks[event][self] = nil
  end

  if not next(callbacks[event]) then
    callbacks[event] = nil
    eventFrame:UnregisterEvent(event)
  end
end

----------------------------------------------------------------
-- Unregisters all callbacks for all events for the module.
----------------------------------------------------------------
function EventRegistry:UnregisterFromAllEvents()
  for event, modules in pairs(callbacks) do
    if modules[self] then
      modules[self] = nil
      if not next(modules) then
        callbacks[event] = nil
        eventFrame:UnregisterEvent(event)
      end
    end
  end
end

----------------------------------------------------------------
-- Event dispatcher: calls all registered callbacks when an event fires.
-- We pass the event name and all event parameters to the callbacks.
-- For unit-specific events, the callback is only invoked if the event’s
-- first argument (typically the unit id) matches the registered unit.
-- Each callback is wrapped in pcall so that an error in one
-- does not prevent others from executing.
----------------------------------------------------------------
eventFrame:SetScript("OnEvent", function(self, event, ...)
  if callbacks[event] then
    local arg1 = ...  -- For unit events, this is typically the unit id.
    for module, moduleCallbacks in pairs(callbacks[event]) do
      for _, cb in ipairs(moduleCallbacks) do
        if type(cb) == "table" and cb.callback then
          if arg1 == cb.unit then
            local retOK = pcall(cb.callback, event, ...)
            if not retOK then
              module:Disable()
              private:PrintSkinRuntimeError(module:GetName())
            end
          end
        else
          local retOK = pcall(cb, event, ...)
          if not retOK then
            module:Disable()
            private:PrintSkinRuntimeError(module:GetName())
          end
        end
      end
    end
  end
end)
