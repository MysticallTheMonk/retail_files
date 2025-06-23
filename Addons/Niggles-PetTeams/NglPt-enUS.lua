-------------------------------------------------------------------------------
--                L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

--
-- English is the default and fall-back locale and therefore the current
-- locale is not tested in this file. This file should appear before any
-- other locale files in the toc file.
--
L["AddonName"]            = "Niggles: Pet Teams";
L["DeleteTooltip"]        = "Delete Pet Team";
L["EditTooltip"]          = "Edit Pet Team";
L["Load"]                 = "Load";
L["NewTeam"]              = GREEN_FONT_COLOR_CODE.."New Team|r";
L["ConfirmPetTeamDelete"] =
  "Are you sure you want to delete the pet team '%s'?";
L["ConfirmPetTeamSave"] =
  "You already have an identical pet team.\nAre you sure you want to save "..
  "this pet team?";
L["PetTeamCreate"]        = "Create Pet Team";
L["PetTeamEdit"]          = "Edit Pet Team";
L["PetTeamStrategy"]      = "Pet Team Strategy";
L["PetTeamStrategyEdit"]  = "Edit Pet Team Strategy";
L["Any Opponent"]         = "Any Opponent";
L["Unnamed Team"]         = "Unnamed Team";
L["UnknownOpponent"]      = "<Unknown Opponent>";
L["FilteredShownHidden"]  = "Filtered: %d shown, %d hidden";
L["PetMissing"]           =
  "|cFFFFFFFFMissing Pet|r\nClick to attempt to find a\nreplacement.";
L["Any"]                  = "Any";
L["Team"]                 = "Team:";
L["Opponent"]             = "Opponent";
L["Opponents"]            = "Opponents";
L["Name"]                 = "Name";
L["Specific"]             = "Specific";
L["Select"]               = "Select...";
L["EditStrategy"]         = "Edit Strategy";
L["Unnamed"]              = "Unnamed";
L["PetReplacements"]      = "Replacement Pets";
L["PetInfoUnavailable"]   = "The pet's information can't be obtained.";
L["PetGenusUnknown"]      = "The pet's genus can't be obtained.";
L["PetNoReplacement"]     =
  "No suitable replacement can be found for the battle pet.";
L["PetTeamNotAvailable"]  = "That pet team is no longer available.";

L["PetTeamEditTutorial1"] =
  "Click here to select an icon for the team.\n\nPets, items and spells can "..
  "be dropped here and their icon will be used.\n\nThe default icon is a "..
  "portrait of the selected opponent.";
L["PetTeamEditTutorial2"] =
  "An opponent can be selected for a pet team. When the Pet Journal is "..
  "opened with that opponent targeted, the list of pet teams will be "..
  "automatically filtered to show the teams for just that opponent. \n\n"..
  "If an opponent isn't selected, a name for the pet team must be entered.";
L["PetTeamEditTutorial3"] =
  "Enter the strategy here for defeating the opponent using the current "..
  "team.\n\nThe strategy can either be in plain text or HTML, using a "..
  "limited subset of standard tags.";
L["PetTeamEditTutorial4"] =
  "Drag pets to the battle slots to build the pet team.\n\n"..
  "Battle pet slots can be left empty for levelling pets. The pets in those "..
  "slots will be marked as placeholders when the pet team is loaded.";
L["PetTeamsTutorial1"] = "Click here to display the list of pet teams.";
L["PetTeamsTutorial2"] =
  "Click 'New Team' or Ctrl-click any existing team to add a team.\n\n"..
  "Double-click a team to load it into the battle pet slots.\n\n"..
  "Shift-click a team to edit it.\n\n"..
  "Alt-click a team to delete it.\n\n"..
  "Right-click a team to display other options.";
L["PetBattleTutorial"] =
  "Click here to toggle the Pet Team Strategy panel.";
L["HtmlErrFormat"]          = "Error at line %d, column %d: %s";
L["HtmlErrMissingEnd"]      = "Missing end tag.";
L["HtmlErrUnknownTag"]      = "Unknown tag.";
L["HtmlErrUnexpectedText"]  = "Unexpected text.";
L["HtmlErrMalformedTag"]    = "Malformed tag.";
L["HtmlErrWrongEndTag"]     = "Wrong end tag.";
L["HtmlErrAttrsInEndTag"]   = "Attributes are not permitted in end tags.";
L["HtmlErrInvalidVoidTag"]  = "Invalid void tag.";
L["HtmlErrTagNotPermitted"] = "Tag not permitted here.";
L["HtmlErrVoidTag"]         = "Tag is a void tag";
L["Line:"]                  = "Line:";
L["Col:"]                   = "Col:";
L["HTML"]                   = "HTML";
L["Import"]                 = "Import";
L["Export"]                 = "Export";
L["Send To..."]             = "Send To...";
L["Placeholder"]            = "Placeholder";
L["Details"]                = "Details";
L["Strategy"]               = "Strategy";
L["PetTeamImport"]          = "Import Pet Team";
L["PetTeamExport"]          = "Export Pet Team";
L["PetTeamSend"]            = "Send Pet Team";
L["EncodedPetTeam"]         = "Encoded Pet Team:";
L["ImportInstructions"]     = 
  "Paste text previously exported from Niggles: Pet Teams or Rematch "..
  "and click 'Import'.";
L["LastEdited"]             = "Last Edited";
L["LastEditedFormat"]       =
  "<p style='color: #575757; font-family: SystemFont_Tiny'>"..
  "Last edited: %s (Patch %s)</p>";
L["PetTeamImportTutorial"]  =
  "Paste text here for an encoded pet team, and click 'Import'.\n\n"..
  "The text can be from an exported pet team you or another player saved.";
L["PetTeamExportTutorial"]  =
  "Copy the text here and paste is where you want to save your pet "..
  "team.\n\nThe text can be given to other players to share the pets, "..
  "abilities and strategy of your pet team.";
L["PetTeamErrorHeader"]     = "The pet team's header is corrupted.";
L["PetTeamErrorEnd"]        = "The end of the pet team is missing.";
L["PetTeamErrorLength"]     =
  "The length of the data for the pet team is invalid.";
L["PetTeamErrorChecksum"]   =
  "The data for the pet team doesn't match its checksum.";
L["PetTeamErrorVersion"]    =
  "The version of the data for the pet team is unsupported.";
L["PetTeamErrorCorrupt"]    = "The pet team's data is corrupted.";
L["PetTeamErrorExport"]     =
  "The pet team's data can't be encoded for some unknown reason."
L["PetTeamErrorMissingPet"] =
  "The pet team can't be exported because at least one of its pets is missing.";
L["PetTeamWarningOpponent"] = "The pet team's opponent is unknown.";
L["PetTeamErrorSpecies"]    = "The species of one of pets is invalid.";
L["PetTeamErrorPetMatch"]   =
  "No suitable match can be found for one of the pets.";
L["PetTeamWarningExported"] =
  "%d pet |4team:teams; successfully exported.\n"..
  "%d pet |4team:teams; can't be exported\ndue to missing pets.";
L["PetTeamInfoExported"]    = "%d pet |4team:teams; successfully exported.";
L["Erris the Collector"]    = "Erris the Collector";
L["Kura Thunderhoof"]       = "Kura Thunderhoof";
L["Categories"]             = "Categories";
L["Other"]                  = "Other";

-- Settings
L["generalSubText"]               =
  "These options control general features."
L["generalAutoShowStrat"]         = "Auto-Show Strategy";
L["generalAutoShowStratTooltip"]  = 
  "If enabled, the strategy for a pet team will be shown when a "..
  "pet battle starts.";
L["generalDismissPet"]            = "Dismiss Pet";
L["generalDismissPetTooltip"]     = 
  "If enabled, any pet automatically summoned when a pet team is loaded "..
  "will be dismissed.";
L["generalShowTutorials"]         = "Show Tutorials";
L["generalShowTutorialsTooltip"]  = 
  "If enabled, tutorials will be displayed which introduce "..
  "you to "..L["AddonName"];
L["generalPetBreeds"]             = "Pet Breeds";
L["generalPetBreedsTooltip"]      =
  "If enabled, the breed of pets in a pet team will be displayed.";
L["generalTargetTeamName"]        = "Target Team Name";
L["generalTargetTeamNameTooltip"] =
  "If enabled, the name of a new team will default to the current target's "..
  "name if they aren't a known pet tamer.";
L["categoriesSubText"]            =
  "These options control the names of the pet team categories.";
L["StatusConnecting"]             = "Connecting...";
L["StatusSending"]                = "Sending data (%d/%d)...";
L["StatusConfirmation"]           = "Awaiting confirmation...";
L["StatusEncodeFailed"]           = "Can't encode the pet team.";
L["StatusIncompatible"]           = "Incompatible versions.";
L["StatusDecodeFailed"]           = "Can't decode the pet team.";
L["StatusNoConfirmation"]         = "No Confirmation received.";
L["StatusNoResponse"]             = "No response.";
L["StatusCancelled"]              = "Cancelled.";
L["StatusDone"]                   = "Done.";
L["StatusBusy"]                   = "%s is busy.";
L["StatusNotify"]                 = "%s has sent a pet team: %s";
