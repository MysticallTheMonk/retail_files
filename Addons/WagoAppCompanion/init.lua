-- file generated automatically
local loadedFrame = CreateFrame("FRAME")
loadedFrame:RegisterEvent("ADDON_LOADED")
loadedFrame:SetScript("OnEvent", function(_, _, addonName)
  if addonName == "WagoAppCompanion" then
    if WeakAuras and WeakAuras.AddCompanionData and WagoAppCompanionData then
      WeakAuras.AddCompanionData(WagoAppCompanionData)
    end
  end
end)
