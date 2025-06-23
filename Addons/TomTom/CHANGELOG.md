# TomTom

## [v4.0.11-release](https://github.com/jnwhiteh/TomTom/tree/v4.0.11-release) (2025-06-19)
[Full Changelog](https://github.com/jnwhiteh/TomTom/commits/v4.0.11-release) [Previous Releases](https://github.com/jnwhiteh/TomTom/releases)

- Fix an issue with release  
- Update for 11.0.7  
- Update TOC for 11.0.5  
- Update TOC for 11.1  
- Update TOC for 11.0.7  
- Update TOC for classic and cata  
- Update for 11.0.5  
- Update TOC for Classic  
- Respect the set closest waypoint setting  
- Fix auto quest tracking  
- Stupid vscode  
- Update HereBeDragons embedded library  
- Update for 11.x codebranch  
- Better defaults for distance units  
     - Default to yards in the US  
     - Default to km/m elsewhere  
     - Provide options for yards/meters only  
- Declare UnitGUID global  
- Add units for waypoint arrow (metric, imperial)  
- Update TOC for 10.2.7  
- Update TOC for Cataclysm Classic  
- Support 11.0 by removing some broken functionality  
- Update TOC for 10.2.6  
- Update toc for 10.2.5 and 1.15.0  
- Update TOC for 10.2.0  
- Update TOC for 3.4.3  
- Update TOC for 10.1.7  
- Fix issue with SetPassThroughButtons  
- Update Ace3 and HereBeDragons  
- Fix luacheckrc  
- Add Addon IconTexture  
- Make objective tracker integration work on retail  
- Add higher resolution arrow images  
- Fix quest poi integration for 10.1.5  
    In this version the QuestPOIButton\_OnClick is replaced with a  
    Mixin that provider similar functionality, so hook the container  
    and ensure we're registered.  
- Fix an issue with fallback coords  
- Add some resilience to player coordinates  
    With the new C\_Map API we have a way to check where the game  
    thinks the player is, this can be combined with HBD to return  
    more accurate results without major sacrifice, so let's try that.  
- Add a /tomtom help command for getting more info  
    This returns a basic usage text that describes the most commonly  
    used slash commands and options  
- Config line-endings by default  
- Update build workflows to support beta  
- Update TOC for 10.1.0  
- Fix for 10.1.0 PTR with removal of GetAddOnMetadata (#7)  
- Update TOC for 10.0.7  
- Fix frame strata for dropdowns  
- Update TOC for 10.0.5 and 3.4.1  
- Update TOC for 10.0.2  
- Remove throttle for click-grabber enable/disable  
- Reduce the throttle timer  
- Don't package .vscode or .github  
- Add an OnUpdate to catch issues with the new world map integration  
- Update AddonCore  
- Fix taint issue relating to the WorldMapFrame  
- Fix frame strata of world map elements  
- Fix world map dropdown  
- Update LibDropdown  
- Fix an issue with duplicate waypoint registration  
- Replace UIDropdown with LibDropdown  
- Include LibDropDown  
- Update libraries  
- Fix stray global, sorry!  
- Fix issues with config registration  
- Update TOC for 10.x  
- Update embedded Ace libraries  
- Add TOC support for Wrath at 30400  
- Update TOC for 9.2.7  
- Fix DB initialization for paste pages, and show when loading a page  
- Merge pull request #6 from jnwhiteh/update-globals  
    Declare additional global usage  
- Update enUS locale defaults  
- Declare additional global usage  
- Add new API function TomTom:ClearCrazyArrowPoint  
    This method takes a single parameter 'remove'. When true, this will  
    cause the waypoint to be removed from the current set of waypoints.  
    When false, this will only clear the waypoint from the active crazy  
    arrow  
- Add a /ttpaste command, enabling the pasting of multiple commands  
    Using /ttpaste will open the window, where multiple lines of commands  
    can be pasted. The "Paste" button will send those as multiple chat commands  
    enabling the setting of multiple waypoints.  
    * The contents of the window can be saved with /ttpaste save [name]  
    * Previously saved contents can be loaded with /ttpaste load [name]  
    * A page can be removed with /ttpaste remove [name]  
    * You can list the names of saved pages using /ttpaste list  
- Update HereBeDragons  
- Update TOC  
- Don't package branches  
- Fix packaging for Curseforge  
- Update packager for v2  
- Update TOC for 9.2, retail, TBCC  
- Merge pull request #5 from jnwhiteh/jnwhiteh-9.1.5-toc-update  
    Update TOC for 9.1.5  
- Update TOC for 9.1.5  
- Merge branch 'main' of github.com:jnwhiteh/TomTom into main  
- Update Interface for Retail to 90100  
- Merge pull request #3 from jnwhiteh/issue-2  
    Clean up WOW version detection  
- Clean up WOW client version detection  
- Add interface versions for all three game versions  
- Merge pull request #1 from jnwhiteh/update-authors  
    Update author list  
- Declare and fix issues with global usage  
- Update to latest version of AddonCore  
- Update author list  
- Add actions for release to Curseforge/WowI/Wago  
- Minor toc tweaks.  
- Update to Ace3  Revision r1252 (May 17th, 2021)  
- Add new .toc files for BC and Classic.  
- Call EnableDisablePOIIntegration() only in retail.  
- Update HBD to 2.06-release v16  
- Update Retail interface to 90005  
- Add a .pkgmeta to control releases.  
- Add .release and .env to .gitignore  
- Add Curse and WoWI project IDs to .toc  
- README..md tweak to prod the packager.  
- Add help text for /wayb  
- Added my name to .toc for push to curse  
- Set Retail Interface  
- Set Classic Interface  
- Allow larger ranges for playeroffset and cursoroffset.  
- Make RemoveWaypoint return on nil, because race conditions.  
- Override MapType for Lunarfall/Frostwall so it can be named.  
- Accept World or Cosmic map parents for Shadowlands.  
- Update  TOC for 9.0.2  
- HBD's GetPlayerZonePosition() seems laggy. Roll our own for now.  
- Update reference from GetQuestLogIndexByID to C\_QuestLog.GetLogIndexForQuestID  
- Set default modifer from Control to Alt.  
- Improved  QuestPOI integration for retail.  
- Call EnableDisablePOIIntegration() and ReloadWaypoints after PLAYER\_LOGIN.  
- Set Retail Interface  
- Set Classic Interface  
- Update HereBeDragons to 2.04  
- Update ACE3 to r1241  
- Update zhTW localixation.  
- Update zhCN localixation.  
- Retail Interface update.  
- Set Classic Interface  
- Add placeholder ptBR Localization  
- Use 'Unnamed Map' if the map has no known name.  
- Update enUS locaization  
- Updated deDE localization by Dathwada  
- Add new L strings.  
- Gethe: WoW 9.0 needs BackdropTemplate for TomTomBlock  
- Add L lookups for Icon names.  
- Add deDE notes to .toc file.  Thanks Dathwada.  
- Add L lookups for Player: and Cursor: on map.  
- Retail Interface update.  
- Update classic interface to 11305  
- Ananhaid: Localization.zhCN.lua update  
- Disable BlockDo not attempt Block hiding during Pet battles in Classic.  
- Hide coord block as well during pet battles.  
- Set Classic Interface  
- Update to HereBeDragons 2.03  
- If HBD does not know where we are, do not crash in /way list.  
- Use HereBeDragons-2.02-release-10-gd4da4b5 till next release.  
- Retail Interface update.  
- Updated RU translations.  
- Use HereBeDragons-2.02-release-6-g3a585ad for 8.3 until next update.  
- Set Retail Interface  
- Set Classic Interface  
- Add Purple Ring for Icon.  
- KaiBo: Wayward reference to TomTom:AddZWaypoint() that had the extra Z.  
- Cluey: Bad reference to self in poi\_OnClick().  
- Retail Cut.  
- Classic Cut.  
- Record the source of the waypoint.  
- Update Localization.enUS.lua  
- #115: Add '/way reset away' and '/way reset not <zone>'.  
- #79: Mention /cway in usage text.  
- #75: Lock/Unlock the arrow from the context menu.  
- #35:  Add control of sound channel to play ping through.  
- re-enable otherzone flags.  
- Rerun Babelfish to update Localization.enUS.lua  
- #472: Disable POI Integration code on Classic.  
- #472: Do not config POI on classic.  
- #472:  Dont call EnableDisablePOIIntegration() on classic  
- #477: If no coordinates, do not try to set waypoint from coord block.  
- #478: 'Send waypoint to' on arrow.  
- Update interface to 8.2.5  
- Add Interface for Classic.  
- Make sure that arrow and block positions are always valid and reset properly.  
- First draft of README  
- Update to ACE r1227  
- Fixed typo in (Save this waypoint between sessions)  
- Removed debug print in (Save this waypoint between sessions)  
- Fixed Map dropdown menu option (Save this waypoint between sessions)  
- Official r1225 fix forAceConfigDialog-3.0.lua  
- Temp ACE3 classic patch.  
- Update to ACE3 Release r1224  
- Save window positions in profile and do not use layout-local.txt  
- Update to ACE3 r1214 (probably 3 days before the next update).  
- Update to HereBeDragons 2.02-release  
- One last update for .TGA files.  
- Update .gitignore for png files  
- CF#448: Protect RemoveWaypoint() from non-table inputs.  
- Update .pkgmeta to exlude unneeded files.  
- CF#329: New colored dots.  
- Fix potential crash in 'Save this waypoint between sessions'  
- DebugListAllWaypoints() was not printing the worldmap\_icon.  
- Add default\_iconsize controls for world and mini map.  
- DFortun81: Patch for TomTom:SetWaypoint() \_displayID  
- Fix bugs in SetWaypoint() and add \_displayID support. CF#422.  
- CreateFontString arguments in wrong order, CF#212  
- Duplicate call to InterfaceOptionsFrame\_OpenToCategory in case BlizzBugsSuck not installed.  
- Set TomTomBlock statum to MEDIUM to avoid it hiding behind everything.  
- Make CrazyArrow stratum be settable to HIGH/MEDIUM.  
- Announce [Could not find a closest waypoint] message only if /cway was used.  
- Document /way arrow and block.  
- Enforce conditions on arrivaldistance and cleardistance if user has set arrow.enablePing.  
- Allow precise placement of coord text on world map.  
- Update to compensate for Outland and Draenor being demoted from Worlds.  
- Fix bogus references to opts.silent  
- Update Interface to 80200  
- Make comparison only using lowercase letters and no spaces (UTF-8 safety)  
- Bug #441:  Allow UIMapType.Continent for zones.  
- Accept only maps that exist in a world for names.  
- Bug #447: hbd:GetZoneDistance() may return nil  
- Add silencing to some errant AddMessage calls.  
- Update to HereBeDragons 2.01-release-5-gcd7e0dd  
- Update to HereBeDragons 2.0.9 aka gcd7e0dd  
- Do not register for QUEST\_POI\_UPDATE or QUEST\_LOG\_UPDATE in Classic.  
- Make sure C\_PetBattles exists before checking IsInBattle()  
- Add Classic detection and dont register PET\_BATTLE\_ events.  
- Fix crash when printing coordinates with no coordinates availible.  
- Add code to allow TomTom specific overrides of HDB data.  
- Protect against orphan maps, which the latest HBD now discovers.  
- Add a backup zone name of #mapID  
- Assume that the lowest numbered mapId is the primary.  Blizzard, yiu drive me crazy.  
- Restrict mapTypes to Zone and Micro.  
- Update CrazyArrow on ZONE\_CHANGED as well.  
- Add missing argument to SetClampedToScreen().  
- Add /tway arrow to print arrow status.  
- Add zone/continent/world to '/tway list'. Resolves #3.  
- Protect against empty \_icon properties in DebugListAllWaypoints().  Resolves #2.  
- Correct GetCZWFromMapID() and GetClosestWaypoint(). Resolves #1.  
- Update HereBeDragons to 2.01-release, resolves #6  
- Merge branch 'master' of github.com:Ludovicus-Maior/TomTom  
- Update ACE to r1200, resolves #5  
- Create README.md  
- Update interface to 80100  
- Add code to DebugListAllWaypoints() to list more info.  
- Add code to support custom waypoint icons and sizes.  
- Add the floatOnEdge back to minimap.  Display Pins on WORLDMAP on WORLD  
- If a profile.arrow.alpha < 0.1 is seen, reset to 1.0 .  No invisible arrows!  
- Do not allow the waypoint arrow alpha to go below 0.1 .  
- Correct the POI Integration to use the RIGHT button, as per the control panel.  
- RainbowMagicMarker Issue #381: /cway not working and very quiet.  
- sigprof issue #357: Death in the Ritual of Doom.  
- Fix Saroana #374 issue with profile reference at load time.  
- Fix JonasJSK26849 #383 Issue with SendWaypoint  
- If the WorldMap is open, use the map's MapID, else guess the current players' map for a QuestPOI.  
- Enable POI integration using QuestPOIButton\_OnClick  
- Fix TomTom:AddWaypointToCurrentZone() to use AddWaypoint()  
- Uncomment call to EnableDisablePOIIntegration()  
- Update for BFA  
- Merged Commit from BFA branch.  
- Correct typo found  by arith in  TomTom:ResetWaypointOptions()  
- Add new code for zone names.  
- Update to HereBeDragons-1.92-beta  
- Update to Ace-r1177-alpha  
- First BFA Port of TomTom\_POIIntegration.lua: Convert to new APIs. Missing Button integration.  
- First BFA Port of TomTom\_Waypoints.lua: Convert to new APIs.  
- First BFA Port of TomTom\_Corpse.lua: Convert to new APIs.  
- First BFA Port of TomTom.toc: Use HereBeDragons 2.0  
- First BFA port of TomTom.lua: missing nameToMapId translation.  
- Update to ACE r1175-alpha  
- Update HereBeDragons to 1.91-beta-1-gaf699f6-alpha  
- Update POI Integration to use new C\_TaskQuest API  
- Update to Ace3 Release - Revision r1166 (August 29th, 2017)  
- Update for 7.3  
- Update TOC for 7.2  
- Fix an issue with POI integration  
- Update for 70100  
- Fix issue with non-titled waypoints  
    Thanks to AnrDaemon for the patch, this makes it possible to distinguish  
    between waypoints set by TomTom without a title and those set by another  
    addon.  
- Enable /wayb to take a name/title as an argument  
    If one is not provided, just use the existing behaviour.  
- Update AceGUI  
- Add a fix for poi\_OnClick  
    Thanks to Jackalo for providing the fix!  
- Updated embedded HereBeDragons  
- Update TOC for 7.0.3  
- Update HereBeDragons to version 1.08-release  
- Replace the unmaintained Astrolabe with HereBeDragons-1.0  
- Replace (unmaintained) LibMapData-1.0 with HereBeDragons-1.0  
- Update TOC for 6.2.0  
- Update TOC for 6.1.x  
- Add explicit function for adding waypoint to current zone  
- Fix an issue with corpse waypoints  
- Properly fork Astrolabe to prevent conflicts  
- De-duplicate zone names to fix fuzzy searching  
- Update Astrolabe  
    This is a forked version that fixes an issue with zone mappings but will  
    be overridden by a new version of Astrolabe if made available.  
- Attempted fix for issue in TomTom\_POIIntegration  
    There may still be an issue with floors, please provide clear and direct  
    bug reports if you're able to reproduce a Lua error.  
- Fix setting waypoints on world map  
- Fix coordinate placement on world map  
- Fix an issue with automatic quest POIs  
    The GetQuestLogTitle() had two returns removed and another added, so the  
    questID return has been moved.  
- Update LibMapData-1.0  
- Update Ace3  
- Update Astrolabe  
- Some updates for 6.0.2  
     - Remove frame registrations for removed frames  
     - Thanks for LudovicusMajor for these changes  
- Update for 5.4  
- Fix zone searching in commandlines  
- Add updated zhCN localisation from ananhaid  
- Add french localisation to .TOC  
- Update TOC for 4.3, update libraries  
- Add frFR locale  
- Bumping?  
- Updating Astrolabe and bumping ToC  
- Don't use magic constants  
- Reduce the chance of tainting  
- Added frFR localization, courtesy of ckeurk  
- Update libmapdata  
- Updated TOC for 5.1  
- Fix an error with feed frame  
- Don't allow waypoint placement on the cosmic map  
- Throttle the coordinate calls on the world map  
- Hide the crazy arrow feed frame when no waypoint  
    This prevents excessive calls when there is no waypoint being displayed.  
- Add cleardistance/arrivaldistance to reset button  
- Add an option to reset options on waypoints  
    If you change the minimap display or world display options, they will  
    not take affect for any waypoints that are already set. This button  
    under 'General Options' will re-set these options on all of the  
    currently set waypoints.  
- Fix a bug with distance callbacks  
    If the player is within the distance callback circle when the waypoint  
    is first set, the last parameter of the callback should be nil. This  
    enables the callbacks to ignore the initial trigger of the callback.  
    Practically, this stops /wayb from being immediately cleared.  
- Updated zhTW locale thanks to BNSSNB  
- Fix an issue with saved variables/callbacks  
- 1 Add an option to make the corpse arrow sticky  
    Other addons that attempt to set waypoints on the crazy arrow when  
    you are dead will silently fail, if this option is enabled.  
- Fix callback bug, clean up leaked globals  
- Update localization  
- Automatically hide the crazy arrow during pet battles  
    There is an option to disable this feature, under 'Crazy Arrow'.  
- Add a method to get a table of default callbacks  
    This makes it possible for an add-on to create a waypoint with custom callbacks without losing the tooltip/onclick functionality that currently exists in TomTom. Usage is something like this:  
    local opts = {} -- any options for your waypoint, such as title, etc.  
    opts.callbacks = TomTom:DefaultCallbacks()  
    opts.callbacks.distance[15] = function(event, uid, range, distance, lastdistance)  
      -- this function will be called when the player moves from  
      -- outside 15 yards to within, or vide-versa and passed  
      -- several parameters  
      --  
      -- event: "distance"  
      -- uid: the UID of the waypoint  
      -- range: the callback range being triggered (15 in this case)  
      -- distance: the current distance to the waypoint  
      --           this MAY be less than 15, if you move really fast  
      -- lastdistance: the previous distance to the waypoint. This  
      --               can be used to determine whether or not you are  
      --               leaving the circle or entering it.  
      if not lastdistance or lastdistance and lastdistance > dist then  
        -- entering circle   
      else  
        -- exiting circle  
      end      
    end  
- Register the TomTom addon prefix for waypoint comm  
    Fixes 47  
- Updated zhTW localization thanks to BNSSNB  
- Update Astrolabe to r155  
    This includes the change to remove the clicking noise when in a zone.  
- Add exact coloring (when 98% on target) to feed  
- Add a function to fetch coordinates safely  
    For the coordinate feed and coordinate block. this function can be used  
    instead of the heavier player position function to get the current  
    player's coordinates. This means that depending on the current map zoom,  
    the 'coordinates' will display the position on that map, which is what  
    we'd expect.  
    The arrow and rest of the addon continues to function correctly.  
    This fixes an issue in the deeprun tram and other zones with no  
    coordinates.  
- Fix map flipping race condition  
- Prevent integer overflow for crazy arrow  
- Update libraries  
- Fix integer overflow issue  
- Update LibMapData to 0.23-release  
- Update TOC for 5.x  
- Update coordinate positioning on non-fullscreen map  
- Add an 'exactcolor' option for the waypoint arrow  
    This will be used when you are moving within 98% accuracy of the  
    intended direction and can be useful for distinguishing between the  
    shades of 'good' and some value of 'exact'.  
- Update .gitignore  
- Use stored options when reloading waypoints  
- Don't bail out immediately without floor information  
- Remove an extraneous print  
- Avoid IEEE-754 precision issues  
- Update TOC for 4.3  
- Update LibMapData to 0.20  
- Merge branch 'master' of git.wowinterface.com:TomTom-11  
- Added an option to hide the 'distance' portion of the waypoint arrow.  
    This option is disabled by default.  
- Add an option to use waypoints outside zone to find closest  
    It will still restrict the search to the current continent, but will now lead you outside the zone, if that waypoint is closer. This option is disabled by default.  
- Update LibMapData to fix span/firelands  
- Update TOC for 4.2  
- Updating to the latest Ace3  
- Possible fix for 21, receiving waypoints  
- Add a /way list command to list waypoints in zone  
    This is a simple debug command that may be useful, but is not expected  
    to be useful to the average user.  
- Fix handling of floors (fixes 28)  
- Move to AddonCore and add version to About box  
    Fixes 22  
- Ensure the waypoint table doesn't get dirty  
- Fix title display when AddMFWaypoint is used  
    Fixes 25  
- Fix fuzzy zone matching  
    This ensures that 'Icecrown' will match 'Icecrown', whereas 'Icec' will  
    match both 'Icecrown' and 'Icecrown Citadel'. In short, an exact match  
    will automatically be accepted.  
- Update LibMapData to 0.16  
- Fail gracefully when coordinate information can't be found  
- Update TOC for 4.1  
- Fix indentation on recently edited files  
- Fix corpse generation module  
- Fork Astrolabe  
- Don't flip map to display coordinates  
- Disable automatic quest tracking by default  
- Fix a bug when sharing waypoints  
- Fix proximity and POI integration  
- Fixes issue 14  
- Fix descriptions in /way command  
- Fix an issue that was causing a WORLD\_MAP\_UPDATE race condition  
- Better handle zone names with spaces and special  
    The comparison of user input to zone name is made more relaxed by this  
    commit which forces both strings to be forced to lowercase, and have all  
    non-alphanumeric characters removed. In short, it should work much  
    better now.  
- Allow user to set POI arrival distance  
    This works for both the ping and the crazy arrow, and will apply to  
    auto-set waypoints as well as those set by clicking on the POI icon.  
- Fix an error when invalid zone supplied  
- Initial update to POI integration plugin  
    Currently, most of the old features should work properly, only there is  
    now a limitation that it will only work with objective waypoints that  
    are in your current zone, in particular with the ones on the watch  
    frame. I will likely change it so that the ones on the world map work  
    properly, but this will be in a separate commit.  
- Add a function to indicate if the crazy arrow is empty  
- Add a tag to make it easier to find core logic  
- Fix non-zone slash command  
- Updated based locale file  
- Fixed slash commands for /way reset and /way  
- Fix feedback from slash command and zone search  
    The feedback being provided by these functions was not correct, and the  
    fuzzy search was not functioning properly. This should resolve those  
    issues, particularly with two-token zone names.  
- Don't strip spaces from zone name in slash cmd  
    Previously the fuzzy matching was using a gsub on %L to "", which  
    removed all of the spaces from the user's input. This no longer works  
    with two word zone names.  
- Fix the /way command so it works in instances  
- Clarify that license is in fact All Rights Reserved, as it has always been  
- Fix the zone search on slash commands  
- Fix the positioning of the world frame coordinates  
    These positions will not be good for all, but should work with the  
    default user interface.  
- Fix the /wayb command for 'wayback' points  
- Fix clicking on coordinate block to set waypoint  
- Remove some debug messages  
- Fix key uid generation  
- Disable POI integration by default  
- Initial revamp for 4.X mapping system  
    There are many things still broken and not quite working, but I am  
    trying to test them as much and as quickly as possible.  
- Add more robust coordinate parsing support, thanks to Phanx  
- Updated Astrolabe to r121  
- Update to Astrolabe-r122  
- Fix an issue with coords and another with Orgrimar  
- Update to Astrolabe r121  
- Update Astrolabe to rev 118  
- Fix an error when navigating the world map  
- Merge branch 'master' of git.curseforge.net:wow/tomtom/mainline  
- Fix issues with mapfile <-> c,z <-> name lookups  
- Fixing some whitespace issues  
- Fix issues with mapfile <-> c,z <-> name lookups  
- Fixing some whitespace issues  
- Update (and compat) for Astrolabe-1.0 with Cataclysm  
- Update (and compat) for Astrolabe-1.0 with Cataclysm  
- Added Astrolabe as a tool-used  
- Added Astrolabe as a tool-used  
- Added a .staticIcon for LDB displays that don't use the dynamic icon  
- Added a .staticIcon for LDB displays that don't use the dynamic icon  
- Make checked out version sane  
- Make checked out version sane  
- Added koKR localization.  
- Fix a bug with updating the coord feed throttle  
- Added koKR localization.  
- Fix a bug with updating the coord feed throttle  
- Update .pkgmeta file  
- Updated .TOC  
- Updated .TOC  
- Update .pkgmeta file  
- Add base versions of required libraries  
- Convert svn:ignore properties to .gitignore.  
- Remove objective POIs before adding a new one  
- Fix an error that can occur due to a bad copy/pasta from WatchFrame  
- A number of enhancements and minor bug fixes  
      * Added a 'ping' sound that can be played when you've arrived at your destination.  The sound will be played when you're within the 'arrival distance', as set under the "Waypoint Arrow" configuration.  This is also where the option can be found.  
      * Enabled dual positioning for world map coordinates, hopefully the placement now works properly.  
      * Added a function TomTom:WaypointExists(c, z, x, y, desc) which returns true or false  
      * Fixed POI integration (from what I tested)  
      * Added an 'automatic objectives waypoint' setting that will automatically set waypoints to your closest quest objective.  I'm not sure how useful this will be, it's disabled by default.  
- Fix POI integration with scaled POIs  
- Fix parenting of waypoint buttons on the world map  
- Properly calculate the effective scale, so POI integration works when the world map is scaled down  
- Added quest objective intergration (Control-right-click to set a waypoint)  
- Fix world map coord positions, update .toc  
- Added the ability to right-click on the coordinate block to set a waypoint at the current location  
- Trying to fix curseforge fingerprinting  
- Updated .toc and Astrolabe version  
- Fix some texture/fontstring definitions  
- Localize additional strings  
- * Add the description to the "waypoint added" message, if it is set  
- Added zhTW localization  
- Fix a bug in TomTom:SetCrazyArrowTitle()  
- Show the waypoint arrow when hijacked  
- Added comments and (hopefully) example usage for hijacking the crazy arrow  
- Added an API to hijack the TomTom arrow for your own purposes  
- Update .pkgmeta file to re-enable no-libs creation on Curse  
- Place all TomTom waypoints on an overlay attached to the world map, to nudge them higher  
- * Fix for world map issues with points of interest, etc.  
- Don't external CBH from Ace3, use the project instead  
- Don't create -nolib versions  
- Updated paths in .pkgmeta  
- Adding .pkgmeta file for packaging purposes  
- Fixing an issue with creating waypoints via the world map  
- Updating TomTom for 3.1 including new Astrolabe  
- * When handling a multi-word zone in /way, make sure to set the description correctly  
- * Fix an error when calling /wayb in a non-zoned area  
    * Add uid = TomTom:GetClosestWaypoint()  
    * Altered the behavior of "Clear Waypoint" when interacting with "Automatically set closest waypoint".  When you clear a waypoint, if the 'closest' waypoint is the waypoint you cleared it will not be set  
- * Fixed an error that caused the battlemap to flip back and forth when using the corpse arrow in a battleground (which does not work)  
- * Only try to set the corpse waypoint when c,z,x,y are positive numbers  
- * Added a Corpse arrow that can be configured on the general options screen.  When enabled, a non-persistent waypoint arrow will be set directing you towards your corpse.  It will be removed when you resurrect.  
- * Added a slash command to set a waypoint at the current location /wayb, /wayback (contributed by Lamalas)  
    * Added a slash command to set the crazy arrow to the closet waypoint in the current zone /cway, /closestway (contributed by Lamalas)  
    * Added an option that will automatically set the crazy arrow destination to the closest waypoint in your current zone  
    * Added TomTom:IsValidWaypoint(uid) to test if a given UID is currently valid   
- * Updated to the latest version of Astrolabe, should hopefully fix the issues people are seeing when setting a waypoint and not having the crazy arrow appear  
- * Add an option to control the accuracy of the coordinate LDB feed  
- * Add options to throttle updates of the two data feeds  
    * Enable right-clicking of the arrow feed to bring up the dropdown menu  
- * Added LDB data feed for coordinates  
    * Added LDB data feed for crazy arrow, requires iconR, iconG, iconB, and iconCoords support  
    * Added options to enable/disable the above feeds within TomTom  
    * Updated Astrolabe to get rid of an error that can occur when logging in  
- * Fix the "Disable Waypoint Arrow" mouse input passthrough  
- * Add an option to reset the position of the coordinate block  
- * Fix the bug where position was not properly saved  
    * Actually added the ability to scale/alpha the title text  
- * Updating Astrolabe to fix the "first-waypoint-wrong" bug  
- * Added a /tomtomway command to get around Cartographer clobbering everything I set  
    * Changed the global I use for slash commands, the previous one was ill-advised  
- Stop the SetScale error from being thrown temporarily  
- * Updated deDE localization courtesy of Elto@Kil'jaeden  
    * Localized the crazy arrow's distance indication  
- Fix an error that could occur when right-clicking a waypoint after setting it, without ReloadWaypoints having been called  
- * Added an option to "disable clicks" on the crazy taxi arrow entirely, so you can have clicks pass through  
    * Added an option to change the scale of the crazy arrow title text  
    * Added an option to change the alpha of the crazy arrow title text  
- * Instead of displaying nothing and erroring OnUpdate, just display "Unknown Distance"  
- Don't display distance on the tooltip when we can't calculate it  
- * Fixed an issue that prevented Modifier-RightClicking on the world map from setting a new waypoint  
- * Don't automatically open the TomTom dialog when opening the Interface Options frame  
    * Add ruRU localization, thanks to Swix  
- * Removed Wrath compatibility code  
    * TomTom options will now be created automatically when the interface options frame is opened  
- Fixed the moved AceConfig externals, and fix the /tomtom slash command  
- * Updated version of Astrolabe to fix resize issue with EP/SW  
    * Updated interface version number  
    * Moved LibStub from an external to a static file (no user impact)  
- Don't hide icons that are disabled, so they still get callbacks  
- Fixes an issue that prevented the "Reset waypoints" command from working  
- Updated to a beta-compatible version of Astrolabe  
- Altered the configuration options to always use the Blizz UI panel  
- Reverting to prior version of Astrolabe  
- Fixed some of the bugs that exist, while breaking new features.  
      * The option to disable waypoints from other zones on the world and minimap is disabled, since it's broken in pieces right now  
- Fixed a number of massive bugs in TomTom's zoning code  
- Fixed a bug that cause new waypoints to not respect the Enable World and Enable Minimap options  
- Fixing TomTom in wrath, using IsWrathBuild()  
- Added /tway as a slash command for TomTom's waypoint command, to avoid conflicts with Cartographer  
- Fixed an issue with the graphics on the waypoint arrow, thanks Krill3 for the report.  
- Added zhCN localization thanks to Onlyfly and fixed some non-native line endings  
- Added an option to reset the waypoint arrow location, and a toggle for waypoints announcements  
- Don't clear waypoints when you are on a taxi  
- Added an option to change the world-map click modifier  
- Fixed a bug with the /way slash command, when used without arguments  
- Alter TomTom to use Astrolabe trunk  
- Added an option to change the title height/width of the crazy arrow  
- Added an option to change the scale/opacity of the waypoint arrow  
- Added options for the following:  
    * Enable the right-click menu for minimap waypoints  
    * Enable the right-click menu for worldmap waypoints  
    * Ask for confirmation when removing all waypoints  
- Added an option to disable the right-click menu on the crazy-arrow  
- Added an option to clear a waypoint from the crazy arrow, shown on the crazy arrow context menu  
- * Added a public API to allow for custom callbacks that work with the frontend  
- * Bugfixes for certain reported bugs  
    * Callbacks will now properly be fired when the minimap icon isn't enabled  
- * Changed code for GetCursorPosition() thanks to ckknight  
- Guard for an odd error when a waypoint's angle can't be determined  
- Removed old property  
- * Next time, make the change in PerfectRaid, not TomTom  
- Set wowi-dirname so zips are generated properly  
- * Added an arrow model courtesy of Guillotine to possibly be used later  
- * Removed bad comment  
- * Added a guard when removing waypoints to catch an error  
    * Simplified the distance callbacks a bit so the outer distance makes more sense  
    * Moved the arrow rotation function out of the OnUpdate  
    * Use the arrow rotation function rather than the OnUpdate function to ensure things are displayd correctly on options change  
    * Make the distance list local to the point, instead of the callbacks table  
    * Release the callbacks table when the waypoint is cleared  
- * Updated localization  
- * Updated enUS localization file  
- * Added deDE localization, courtesy of Elto  
- * Fixed a bug that caused the crazy arrow to appear on zoning/death/etc  
- * Expose TomTom:InitializeDropdown(uid) that can be used to init the dropdown  
    * Fix a bug where checkboxes could be put in the wrong place on dropdown menus  
- * Guarded the ColorGradient() function against specific odd cases  
- * Added a comment clarifying that TomTom\_Waypoints API is private  
    * When a duplicate waypoint is set, return the original uid  
- * Stop duplicate waypoints from being set  
- * Fix a bug where players were receiving their own messages  
- * Fixed an issue where waypoint would appear out of nowhere when zoning  
    * Fixed the slash command handler so it properly accepts multi word zone names  
- * Reverted to a different version of Astrolabe for testing purposes  
    * Added a "Send Waypoint" option, needs testing  
    * Fixed an issue with the waypoint arrow when using minimap rotation  
    * Added the waypoint removal (all, zone) options to the crazy arrow right-click  
- * Added alpha for border  
- * Fix a bug where the "Enable" checkbox wasn't working for minimap or worldmap waypoints  
- * Added a right-click option to clear the current waypoint on the arrow  
- * Fixing an issue where crazy arrow would appear even when disabled  
    * Updated externals to fix config issue  
- * Fixed waypoints not automatically clearing when that option is set  
- Removed Dongle from scm control  
- * Added version information to TomTom  
- * Added version number to .toc  
- * Make sure to return the uid from AddZWaypoints  
- * Fixed the parenting of the options panel  
- * Added property so zips are generated properly  
- * Removed Dongle from .toc  
    * Updated externals  
    * Updated localization file  
- Fixed an issue  
- Fixed the parsing of the description part of the slash comman  
- * Fixed the loading of arrows from storage, and enabled right-click to set as crazy arrow  
- Lots of changes, including a working slash command  
- Major update to TomTom, everything except CrazyTaxi queuing "works"  
- * Made changes to allow for better operations with 2.4  
- Moving over to AceDB and removing dependecy on Dongle  
    * Reconfigured options screens  
- Removed override of GetBuildInfo.  
- * Fixed the size of the tooltip.. thanks Kergoth  
- * Fixed a bug that could occur when zoning into instances  
- * Merging all changes from 2.4 branch  
    * Configuration dialog should work on 2.3 and 2.4  
- * Updating externals  
- * Re-generated the localiztion file  
- I changed things  
- * Added an option to clear waypoints (set the distance > 0)  
    * Altered the callback system to allow for arbitrary distance callbacks  
- * Re-working the internals of TomTom yet again.  Tooltips for minimap nodes should work  
- * Uhh.. return  
- * Fixed the error upon login  
    * Added a middle color, which is used for proper shading between good and bad  
    * Fixed the coloring of the crazy arrow so it properly turns green when you're "Arrived"  
- * Updated Astrolabe externals  
- * Reworking of the Waypoints API... callbacks are broken as a result  
- * Enable a /way command, fix a bunch of things, control-right click works  
- * Remove inline groups, which hopefully will motivate me to not let this look stupid  
