local addon_name, private = ...
local addon = {}
Mixin(addon, private.Mixins.AddonMixin, private.Mixins.ColorMixin)
_G[addon_name] = addon
