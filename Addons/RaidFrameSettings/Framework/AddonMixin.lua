local addon_name, private = ...
private.Mixins.AddonMixin = {}
local addon_mixin = private.Mixins.AddonMixin

local modules = {}

function addon_mixin:CreateModule(name)
  local module = {}
  module.name = name
  Mixin(module, private.Mixins.HookRegistryMixin, private.Mixins.ModuleMixin, private.Mixins.EventRegistry)
  modules[name] = module
  return module
end

function addon_mixin:GetModule(name)
  return modules[name]
end

function addon_mixin:EnableModule(name)
  self:GetModule(name):Enable()
end

function addon_mixin:DisableModule(name)
  self:GetModule(name):Disable()
end

function addon_mixin:ReloadModule(name)
  local module = self:GetModule(name)
  if module:IsEnabled() then
    module:Disable()
  end
  if self.db.profile.module_status[module:GetName()] then
    module:Enable()
  end
end

function addon_mixin:IterateModules()
  return pairs(modules)
end

function addon_mixin:ReloadAllModules()
  for _, module in self:IterateModules() do
    self:ReloadModule(module:GetName())
  end
end

function addon_mixin:Print(msg)
  print(WrapTextInColorCode(addon_name, "FFFFA600") .. ": " .. msg)
end
