2.3.4b
- Fix DR Text always being active regardless of settings.
- Fix lua errors from now new restrictions from Blizzard related to castbar types (uninterruptible status).
    This means currently not possible to color/texture an uninterruptible cast without some sort of wonky workaround maybe.
    Disabled for now and will just color depending on cast/channel, this may be confusing on uninterruptible casts.
    Consider Modern Castbars setting which uses default colored textures for now until a fix may arrive.

2.3.4
- Update Mes profile

2.3.3e
- Add test global to skip DR Warning/Reload for testing. Macro: /run sArenaSkipDrWarning = true
- Fix Prepatch/Midnight trying to use functions from Dispel Module (which is disabled on Prepatch/Midnight) causing error and test mode to bug.
- Locale fixes and tweaks from 007bb. Thank you!

2.3.3d
- Add Interface Version 120000 to toc file, wouldnt load on prepatch with just 120001.

2.3.3c
- Fix interrupt checker for Midnight
- Restructure and cleanup a few things behind the scenes.

2.3.3b
- Midnight: Fix party target feature due to new Beta changes.
- Midnight: Headsup: Currently if you reload UI in an arena that has started (gates opened) the Blizzard UI shits the bed, which also causes sArena to shit the bed. Blizzard needs to fix this.

2.3.3
- TBC: Warrior stances now show up as auras on sArena like normal (workaround required for TBC since they not *real* auras)
- Localization added. Currently supports English and Korean. Thank you to 007bb for contributing.

2.3.2b
- Remove shared CD from Will of the Forsaken in TBC
- Remove Thorns from aura list in TBC

2.3.2
- TBC aura list cleanup and added a few things.

2.3.1e
- Fix alpha issue on stealth units.

2.3.1d
- Fix interrupts on channel spells not showing due to workaround for non-working Blizzard API being set up slightly wrong in some refactoring.

2.3.1c
- Add temporary icon for missing trinket texture (will get the retail texture eventualy)

2.3.1b
- Fixup TBC stuff.
- Add a guard for potential DR error, will print error msg, please report back.

2.3.1
- Add Wrath support

2.3.0
- New Shadowsight Timer setting (Global). Enabled by default on TBC, off on others.
- New "Color DR Cooldown Text by Severity" setting (Global -> DR) (Does not work with OmniCC).
- Lots of tweaks to fix minor things. Class Icon texture appearing above borders (after rework) for example.
- Midnight: Fix a couple of DR related things.
- Midnight: Fix test DR frames to show the correct new Midnight icons (these are still not possible to change, and honestly probably wont be cuz Blizzard)

2.2.9b
- Fix "blocked action" error due to a whoops.
- Rework Class Icon stuff behind the scenes, fixes some minor issues too.
- Fix Spec Text disappearing on unit death and not showing again on shuffle round change because I forgot about shuffle for the millionth time.
- Fix TBC clickable frames in arena.

2.2.9
- Add health/mana background texture & color settings.
- Fix Pixelated layout's ClassIconCooldown not showing.
- Fix DR BorderFrame's FrameLevel to also be increased after the main DR Frame's FrameLevel increase.

2.2.8
- A lot of work done towards TBC, it should now be in a decent state. Will probably require a decent bit of tweaks and spells etc. Any support is appreciated.
- Midnight: Tweak DR Borders with new available API so can actually hide the previous border instead of just overlapping it.
- Raise DR Frames' FrameLevel a bit.

2.2.7
- Fix health percent causing lua errors on Midnight due to new changes.
- Fix DR swipe color not being set on the new Midnight DR Frames.
- Minor tweak to DR swipe color, making it a little bit more transparent by default.

2.2.6c
- Minor tweaks

2.2.6b
- Midnight: Fix a new "secret" error.
- Midnight: Fix cooldown numbers on CC.
- Midnight: Fix red DR Text being out of position.

2.2.6
- New "DR Text" size and position settings in the Layout: Text Settings section. (The DR amount text, not the cooldown text)
- "Spec Names on Manabar" setting now available in Layout settings for all layouts and not just a few of them.
- New "Disable Overshields" setting (Global -> Misc)
- Fix DR Icons unintentionally staying cropped when DR Border was disabled (and Cropped Icons was not enabled)
- Fix spam errors (every frame) due to decimals no longer being available on Midnight due to restrictions. (Potentially theres a different method later on, will look into it)
- Fix Gladiuish layout's Trinket, Racial & Dispel default size from 41 to 40. You might have to retweak size/position. Apologies for the inconvenience. Boring info: They were larger than the frames height because the default icons (when not cropped) have an ugly and inconsistent border around them and it was done to make them at least appear visually the same. However this just caues headache with both the cooldown spiral on top and also when crop borders is enabled. Should now be pixel perfect even though it may not look like it without cropped icons setting, feel free to tweak that with size if you want

2.2.5b
- Fix health & mana number formatting having some leftover code from Midnight work.

2.2.5
- Add Mes Profile (www.twitch.tv/notmes)
- Fix some potential click issues if reload during arena, like spec icon button eating clicks.

2.2.4b
- Midnight: Fix health & mana percent setting causing lua errors due to secrets. Use new Midnight API to fix.
- Midnight: Make the Reload UI warning not moveable because some people (Raiku) just kept dragging it off screen. This Reload is needed for DR's to function due to Blizzard Beta Edit Mode bugs.

2.2.4
- Midnight: Some more tweaks to try ensure DR frame does not bug out. However since the DR Frames is from Blizzard now any taint in the game has a high potential of just breaking them. It's awesome stuff really.

2.2.3c
- Retail & MoP: Fix Feign Death sometimes resetting all DRs on the Hunter. In some cases the Feign Death aura does not get registered, causing DRs to reset before this version. Cool stuff.

2.2.3b
- Midnight: Fix DR Frames not showing after leaving smth in the wrong state after testing.

2.2.3
- Fix Target & Focus & Party Target Widgets not working after an efficiency change a while ago and forgetting to change the function call.
- Midnight: Also fixed the targeting Widgets on Midnight.

2.2.2f
- Midnight: Hide the DR Frames sticking out in when in Edit Mode.

2.2.2e
- Midnight: Force reload on first arena as well. (Waiting for Blizzard to fix DRs & Edit Mode)

2.2.2d
- Few more fixes for Midnight.
- Root cause for DR frames failing on Midnight found: Edit Mode. Welcome back Dragonflight. I've added a *strongly encouraged* reload button that pops up when you enter Arena. This is good practice during a Beta anyway.

2.2.2c
- Few more fixes for Midnight.

2.2.2b
- Midnight fixes and workarounds.

2.2.2 Midnight
- Midnight should now work. More details at end of notes.
- New streamer profiles import page in the "Share Profiles" tab. Aeghis, Nahj & Pmake available atm, thank you all <3
- New layout: BlizzRaid
- New Castbar color settings.
- New Castbar "No interrupt ready" color setting. (BBF version is better, this one is currently made with Midnight in mind but might see tweaks in the future. If using BBF just keep using that.)
- New Castbar un-interruptible texture setting.
- New "Reverse Bars Fill" setting that reverses health and power fill direction.
- Target Indicator is now enabled by default on the newer Layouts.It may have turned on for you and if you don't want it turn it off in the Layout settings -> Widgets.
- Revert the hiding of dark mode & frame color settings on layouts where it makes less sense, since they can still be used to color the castbar.


Does NOT work:
- Most auras except for whatever CC Blizzard wants us to see.
- Absorb overlay (potential tweaks for that inc later, or just an absorb number)
- Diminishing Returns settings are wonky and theres a few issues. They will see more work moving forward, heres the current (and maybe permanent) issues:
1. DR: I cannot control each individual DR icons position. You will still be able to move them around and resize them though but more on that in the next three points.
2. DR: Grow up and grow down settings no longer work. Grow left and right does. Up and down will just default to grow left instead for now until I clean things up later down the road towards Midnight release.
3. DR: Gap setting no longer works.
- Maybe other things I've forgot to mention.


2.2.1
- Add option to disable all auras from Class/Spec icon.
- Retail: Add missing Surge of Power root from aura list (existed as DR). Ty Jaime.
- Midnight support should be around the corner but I need to wait for skirmishes to actually test it and make sure first and probably make some tweaks.

2.2.0
- Separate Dark Mode color from BetterBlizzFrames' dark mode so you can change it to a different value than the rest of your UI. Your dark mode value might need re-adjusting because of this if you were using BBF dark mode plus sArena dark mode.
- Add two new options to Class Color FrameTexture: Only color icon borders & Color healer green. This will only show up on layouts supporting it (that have borders on class icon specifically)
- Class Color FrameTexture now also works on Pixelated layout.
- Hide some settings in the Global section for layouts where they dont apply (for example dark mode for Xaryu layout, since there are no borders to dark mode)
- Fix castbar texture change not sticking during arenas on the default castbars.
- Temporary tweak to MoP's BlizzCompact layout with its cooldown edge texture: use circle edge instead to avoid the edge sticking out on the corners. Not sure how to fix this properly yet on MoP.

2.1.9
- Fix potential castbar coloring issues with Modern Castbar + Custom texture instead of the default ones.
- Potential fix for some MoP+Human racial settings. Unable to test cuz no test environment. No PTR, no lvl 90, no skirmishes, gg.

2.1.8
- Add new DR settings and tweak them a bit.
- New DR Thin Pixel Border setting.
- New DR Hide Glow setting.
- Pixelated layout's DR look can now have different looks. Thick Pixel Border is its default but it can now also have Bright DR Border etc.
- Other layouts than Pixelated can now have the Thick Pixel DR Border / Thin Pixel DR Border setting.
- Tweak a few aura priorities.
- Remove Upheaval from Knock DR's.
- Focus Indicator no longer enabled by default for Blizz Compact layout.
- Due to an oversight after combining Retail & MoP version into one version I've had to reset DR Reset Time back to their default value (18.5 on Retail and 20 on MoP). Also fix DR Reset Time description on MoP. It had the Retail description and was inaccurate.

2.1.7
- One new layout: Blizz Compact
- Four new features in layout settings in new Widgets section:
1. Target Indicator: Show icon on your current target
2. Focus Indicator: Show icon on your current focus
3. Party Target Indicator: Show class colored player icons on arena frames indicating who your party members are targeting.
4. Combat Indicator: Show food icon on out of combat arena frames.
- New Hide Castbar Icon setting.
- Dark mode is no longer enabled by default if BetterBlizzFrames' DarkMode or FrameColor is detected.
- DR Text setting moved from global to layout settings next to other similar settings.
- Fix issues with dispel tracker being updated multiple times per one dispell.
- MoP: Potential fix for Human Racial/Trinket issue on MoP.
- Misc minor tweaks in gui and layouts.

2.1.6
- Fix GUI not updating position settings immediately after dragging things around.
- Fix DR Categories not respecting per spec & per class settings due to falling back to global settings like how Static Icons work, oops.

2.1.5
- Priest's Purify now displays a stack number on it if double dispel. At 0 stacks it gets desaturated. At 1 or more stacks it stays colored.
- Add options to disable desaturation on Trinket & Dispel CD (Global -> Arena Frames -> Misc).
- Re-enable manabar text and add settings to show/hide it and position settings etc. Disabled by default.
- Tweak layouts a little: Removed font outline on spec name text for Retail layout. Add font outline to the old Arena & Xaryu layout's health & mana text (as it used to be, this got unintentionally removed with new font settings).
- Fix racials not updating properly between shuffle rounds.

2.1.4
- New "Simple Castbar" setting for Modern Castbars. Removes text background and puts text inside of the castbar.
- Tweak to make sure "Swap Trinket with Human Racial" setting works even when Human racial is turned off.
- Fix unique DR sizes causing first DR icon to not be positioned correctly if it was increased/decreased in size.
- Retail: Reduce Warlock's Malevolence prio below Dark Pact and Unending Resolve.

2.1.3
- Added a new temporary section for Midnight info.
- Fix Font Shadow offset & color. Visible with Outline off.
- Fix Pixelated's layout showing Dispel's Pixel Border when there was no Dispel or Dispel module turned off.
- MoP: Fixed "Force Show Trinket on Human" setting to also display cooldown on Human Racial usage.
- MoP: Tweak some aura priorities
- MoP: Change Mana Tea to show stack count instead of percent.

2.1.2
- Fix test title not going away when hiding test mode.

2.1.1
- Minor tweaks and bugfixes

2.1.0
- Add Dispels module (Beta, needs more testing and verifying spell ids etc. Please report any issues)
- Add "Trinket Circle Border" setting for Blizz Arena layout.
- Add two new MoP settings: Replace Human Texture with Trinket texture & Always show Trinket texture for Humans
- Fix Class Stacking Only Texture Change setting (but for real this time! oopsiewoopsie)
- Fix Masque setting causing lua errors and messing things up.
- Fix color trinket setting not showing Cooldown.
- Tweak BlizzArena layout's class icon crop so it doesnt show texture borders inside of circle.
- Fix BlizzTarget layout's name background not being positioned correctly when "Big Healthbar" was disabled.
- Tweak BlizzTarget layout's FrameTexture to use a higher quality version of the no level texture.
- Color Trinket setting now completely hides Trinket spot when they don't have a Trinket instead of showing a red color (to emphasize they dont have a trinket, instead of it "being on cd").

2.0.9
- New setting: Class Color FrameTexture. Class color the border on frames.
- Dark Mode Color Value is now adjustable and also has a Desaturate toggle. (if BetterBlizzFrames is enabled it still gets its value from there to be consistent)
- Fix class stacking setting changing texture on healer when there was 2 of an unrelated class to healer.
- Minor tweaks around in the GUI

2.0.8
- Mists of Pandaria: Add Monk's Tigereye Brew as offensive prio and Mana Tea as very low prio. Also shows percentage. Feedback on this appreciated.

2.0.7
- Add option to disable White Flag no trinket texture. (Global -> Arena Frames -> Misc at bottom)
- Fix shared racial/trinket cooldown showing on White Flag (no trinket texture) unintentionally.
- Tweak options to display class and spec on the per class/per spec options for better clarity.

2.0.6
- New Format Numbers setting which is on by default. 18888 K -> 18.88 M
- New adjustable decimal threshold, default still 6 seconds. Only for non-OmniCC users, configurate your OmniCC instead if you are using that.
- Added DR Static Icons: Per Spec option
- Added DR Categories Per Class & Per Spec options
- New Swipe Animation setting: Disable Cooldown Swipe Edge
- Fix issues with "Swap Missing Trinket with Racial" setting on MoP

2.0.5
- Change "Swap Human Racial" setting to instead be "Swap Missing Trinket with Racial". This will move all racials over to trinket spot if they don't have a trinket equipped. (This change is currently only uploaded for Retail due to more testing needed on MoP first)
- Tweak hunter feign alpha to be a bit more visible
- Fix wrong unit in class stacking healer func

2.0.4
- Add back missing "Swap human racial with trinket" setting for the MoP version, where it fits.
- Tweak pixel border show/hide, shouldnt show unless theres a texture now.
- Fix icon position not working properly on Pixelated layout.
- Soft cap on text size increased to 200%

2.0.3
- Interrupted castbars no longer instantly hide but instead show who interrupted and fades the castbar out slowly.
- Fix some hide castbar events
- Fix two lua errors due to typos
- Don't show cooldown spiral on trinket if no trinket texture.

2.0.2
- Add new aura stacks indicator in bottom left corner of Class/Aura Icon.
- Add new text settings that lets you move and resize name, health, etc.
- Fix stealthed units transparency and tweak the amount
- Fix Class Icon Swipe going the wrong way by default after introducing new settings for it.
- Fix frames being bugged after reload while in an arena.
- Fix missing library for SharedMedia causing addon not to load for some people.

2.0.1
- Add /sarena test1-5 command.
- Fix Black DR Border not working during test mode for Pixelated layout.
- Change wording related to other sArena's. Reminder that this version is made based on the original one by Stako with their blessing: "Others are free to submit updates or upload their own versions".

2.0.0
- This sArena version has now also launched as a Retail version! Everything below is for both versions (but MoP needs some more data for the non-duration auras)
- New Retail layout
- Add Shields & Overshields to healthbars
- New Texture & Font settings (And removed old classic bars & prototype setting)
- New Dark Mode setting (also follows BetterBlizzFrames if you have that)
- New Modern Castbars look setting.
- New Bright DR Border setting.
- New setting that lets you texture swap healers specifically, optionally only when class stacking.
- New "Replace Healer Icon" setting. Turns Healer Icon into Healer Cross.
- New "Per Class" Static DR Icon setting. Aka show Blind icon on Rogue and Fear icon on Priest etc.
- New swipe animation settings: Disable & Reverse, for DR, Class Icon and Trinket/Racial.
- New Class Color Names setting
- New "Skip Mystery Gray" setting that avoids coloring unseen units gray (pre-gates, stealthed)
- Frames are now class colored by default in spawn and for stealthed units, new setting to keep it like it was originally "Color Non-Visible Frames Gray"
- Castbars now instantly hide on finished casts.
- Interrupt durations now take interrupt reduction auras into consideration.
- Now shows duration on auras that don't have durations implemented by default (Smoke Bomb, Earthen Wall, Barrier, etc)
- Hunter's Feign Death no longer shows up as dead but instead keeps the HP at what it was upon feigning and makes it slightly transparent.
- Title above testing frames can now also be dragged to move the frames.

1.2.1
- Fix typo in hiding default arena frames
- Fix Color Trinket setting sometimes going gray instead of its intended red color.

1.2.0
- Added Import/Export profile sharing system. Shares active profile.
- Added "Static DR Icons" setting to set specicifc icons for specific DRs instead of the dynamic ones.
- Added "Crop Icons" to Xaryu Layout.
- Fixed DR Text setting showing +1 DR
- Fixed crop icons test mode not working 100%
- Fix "Hide" after testing not hiding the Title+Drag Info text above frames

1.1.9
- Fixed some interrupt durations.

1.1.8
- Added some missing interrupts to interrupt list. Thank you to Moonfirebeam for reporting these.

1.1.7
- Added castbar icon position settings and "hide shield texture" setting. (Layout Settings -> Cast Bar)

1.1.6
- New individual DR size adjustment settings (Layout)
- New DR Text setting
- New Hide DR Swipe Animation setting
- Minor aura tweaks

1.1.5
- Add new layout "Pixelated".
- Add "Swap Trinket with Race for Human" setting.
- Add "Color Trinket" setting. Colors Trinket flat green when its available and red when its on cooldown.
- Few more aura tweaks.
- Added Icebound Fortitude glyph detection to raise its priority when they're immune to CC.

1.1.4
- Improve the Masque support and tweak the Frame setting. Also added Castbar and SpecIcon to it.
- Tweaked auras and their priorities.
- New Castbar Icon Scale Slider.
- Fix the Invert DR Cooldown Sweep settings not getting applied on login.

1.1.3
- Fix potential nil error in some cases

1.1.2
- Added Masque support.
- Added many defensives & offensive auras. And a few missing CC ones.
- Added Crop Icons setting.
- Tweaked aura priority a bit (more inc probably)
- Add new "Reverse Cooldown Sweep" in Global DR Settings.
- Add two new settings: Show Decimals on Class Icon & DR's (Shows below 6 seconds)
- Add slider to adjust Dynamic DR duration in Global DR Settings.
- Fix Arena Frames not showing if your arena partner didnt join the arena.
- Fixed DR categories.
- Had a bit more fun with the test mode.

1.1.1
- Add some missing auras

1.1.0
- Remove Decounce put as stun from old cata spell id

1.0.9
- Add more missing auras
- Fix interrupt durations and added Solar Beam
- Interrupts now have lower prio than pure silences and will show after silence ends instead.

1.0.8
- Fix Trinket API call causing Trinkets to not always be accurate.
- Un-interruptible castbars now show as gray color
- Add a few more missing spells.

1.0.7
- Fix trinkets not getting colored again when cd expires

1.0.6
- Fix nelf racial texture missing
- Remove grayed out human trinket, trinkets now grayed out only when on CD.
- Known Issue: Trinket CD not always displaying the cooldown spiral texture. Need more testing.

1.0.5
- Trinkets now show grayed out while on CD and for Humans. Might change the Human part. See how I feel about and feedback I get.
- Added a missing Turn Evil aura ID.
- Known Issue: Trinket CD not always displaying the cooldown spiral texture. Need more testing.

1.0.4
- Fix minor issue with spec icon

1.0.3
- Added more settings.
- Cleaned up a few things.
- Added a converter from old sArena to MoP Classic version.