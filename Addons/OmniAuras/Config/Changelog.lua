local _, NS = ...

local changelog = [=[
### v1.0.2
-   Update for Patch 11.1
-   Auto-adjust last-inner-big-debuff size to fit the available space instead of clipping
-   Add Center layout for Nameplate
-   Add dispellable NPC debuff slider
-   Protect against atypial arena frame scaling (#55)
-   Remove temporary embeded features (i.e., Arena nameplate, Party castbars)

### v1.0.1
-   undo comment out

### v1.0.0
-   Initial commit
]=]

if NS and NS[1] then
	local found
	NS[1].changelog = "|cff99cdff" .. changelog:gsub("#+%s+", "", 5):gsub("\n+###.*", ""):gsub("v[%d%.]+", function(ver)
		if not found and ver ~= NS[1].Version then
			found = true
			return "|cff808080" .. ver
		end
	end)
	return
end

if arg and arg[1] then
	if arg[1] == "latest" then
		local latestChangelog = changelog:gsub("\n+###%sv%d.*", "")
		print(latestChangelog)
	else
		print(changelog)
	end
end
