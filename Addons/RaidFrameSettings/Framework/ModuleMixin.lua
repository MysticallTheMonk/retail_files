--[[Created by Slothpala]]--
local _, private = ...
private.Mixins.ModuleMixin = {}
local module_mixin = private.Mixins.ModuleMixin

function module_mixin:Enable()
  if self:IsEnabled() then
    return
  end
  self.enabled = true
  self:OnEnable()
end

function module_mixin:OnEnable()
  -- Overwritten by module.
end

function module_mixin:IsEnabled()
  return self.enabled
end

function module_mixin:Disable()
  self.enabled = false
  self:DisableHooks()
  self:UnregisterFromAllEvents()
  self:OnDisable()
end

function module_mixin:OnDisable()
  -- Overwritten by module.
end

function module_mixin:GetName()
  return self.name
end
