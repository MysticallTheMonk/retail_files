--
-- Masque Blizzard Bars
--
-- Locales\Locales.lua -- Defines a basic localization lookup method
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local _, Shared = ...

local L = {}
setmetatable(L, {
        __index = function(_, k)
                return k
        end
})
Shared.Locale = L

