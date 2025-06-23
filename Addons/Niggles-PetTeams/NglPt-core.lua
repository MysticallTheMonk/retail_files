-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

-- Set the function for any undefined keys in the L table
setmetatable(L,
{
  __index = function(table, index)
    return index;
  end
});

local emptyTable = {};

local dropdownShown;

local pointMapping =
{
  ["BL"] = {"BOTTOMLEFT"},
  ["BC"] = {"CENTER", "BOTTOM"},
  ["BR"] = {"BOTTOMRIGHT"},
  ["CL"] = {"CENTER", "LEFT"},
  ["CC"] = {"CENTER"},
  ["CR"] = {"CENTER", "RIGHT"},
  ["TL"] = {"TOPLEFT"},
  ["TC"] = {"CENTER", "TOP"},
  ["TR"] = {"TOPRIGHT"},
};

local tutorialAlert;
local tutorialPoints =
{
  {"LEFT",   "RIGHT",   20,   0},
  {"RIGHT",  "LEFT",   -20,   0},
  {"TOP",    "BOTTOM",   0, -20},
  {"BOTTOM", "TOP",      0,  20},
};

local utf8ValidRange =
{
  [0x00] = {0x80, 0xBF},
  [0xE0] = {0xA0, 0xBF},
  [0xED] = {0x80, 0x9F},
  [0xF0] = {0x90, 0xBF},
  [0xF4] = {0x80, 0x8F},
};

local CATEGORY_ICON_PATH = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcons";

-------------------------------------------------------------------------------
--                 A  D  D  O  N     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

L.ADDON_FOLDER_NAME    = "Niggles-PetTeams";
L.ADDON_MSG_PREFIX     = "NglPetTeams";

L.MAX_PET_LEVEL        = 25;
L.MAX_ACTIVE_PETS      = 3;
L.NUM_ACTIVE_ABILITIES = 3;
L.MAX_TEAM_NAME_LEN    = 32;
L.MAX_TEAM_STRAT_LEN   = 4096;
L.MASK_UNFILTERED      = 0xFFFFFFFF;
L.MAX_CATEGORIES       = 8;

L.MASK_CATEGORY_NONE = 0x8000;

L.ICONFLAG_MASK     = 0xF0000000;
L.ICONFLAG_STANDARD = 0x10000000;

L.TUTORIALSEENFLAG_PETTEAMS      = 0x0001;
L.TUTORIALSEENFLAG_NEWTEAM       = 0x0002;
L.TUTORIALSEENFLAG_TEAMEDIT      = 0x0004;
L.TUTORIALSEENFLAG_STRATEGY      = 0x0008;
L.TUTORIALSEENFLAG_IMPORT        = 0x0010;
L.TUTORIALSEENFLAG_EXPORT        = 0x0020;

L.categoryIcons =
{
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:0:64:0:64|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:64:128:0:63|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:128:192:0:64|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:192:256:0:64|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:0:64:64:128|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:64:128:64:128|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:128:192:64:128|t",
  "|T"..CATEGORY_ICON_PATH..":0:0:0:0:256:256:192:256:64:128|t",
};

--
-- NOTE: The ID for each continent is any (although typically the first) valid
--       map ID for that continent, since each continent can have several map
--       IDs. The ID should NEVER be changed once set.
--
L.continents =
{
  associative = {},
  indexed =
  {
    -- 1: ID
    -- 2: Name
    -- 3: Bit mask
    { 905, nil, 0x00000200}, -- Argus
    { 619, nil, 0x00000100}, -- Broken Isles
    { 572, nil, 0x00000080}, -- Draenor
    {1978, nil, 0x00040000}, -- Dragon Isles
    {  13, nil, 0x00000004}, -- Eastern Kingdoms
    {  12, nil, 0x00000002}, -- Kalimdor
    {2274, nil, 0x00080000}, -- Khaz Algar
    { 876, nil, 0x00000400}, -- Kul Tiras
    { 948, nil, 0x00000020}, -- The Maelstrom
    {1504, nil, 0x00001000}, -- Nazjatar
    { 113, nil, 0x00000010}, -- Northrend
    { 101, nil, 0x00000008}, -- Outland
    { 424, nil, 0x00000040}, -- Pandaria
    {1550, nil, 0x00002000}, -- The Shadowlands
    {1645, nil, 0x00004000}, -- Torghast
    { 875, nil, 0x00000800}, -- Zandalar
    {2046, nil, 0x00008000}, -- Zereth Mortis
    {2055, nil, 0x00010000}, -- Sepulcher of the First Ones
    {2059, nil, 0x00020000}, -- Resonant Peaks
  },
  mapContinent = {}
};
setmetatable(L.continents,
{
  __index = function(table, key)
    return (key == "length" and L.continents.init() or nil);
  end
});

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when the close button is clicked in the tutorial alert
--
local function tutorialAlertCloseOnClick(self, mouseButton)
  -- Check there is a flag associated with the tutorial alert
  if (tutorialAlert.flag ~= nil) then
    -- Set the flag that indicates the tutorial alert has been seen
    NglPtDB.tutorialSeen = bit.bor((NglPtDB.tutorialSeen or 0),
      tutorialAlert.flag);
  end

  -- Hide the tutorial alert
  tutorialAlert:Hide();

  return;
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to convert a build version string into a number. If no build is
-- specified, the current build will be used
--
function L.buildGetNumber(build)
  -- Local Variables
  local _;
  local buildNo = 0;
  local values = {};

  -- Extract the major, minor and sub-patch numbers
  _, _, values[1], values[2], values[3] = string.find(
    (patchStr or GetBuildInfo()), "^(%d+)\.(%d+)\.(%d+)");

  -- Combine the 3 numbers into a single patch number
  if (values[1] ~= nil) then
    buildNo = (values[1]*256*256)+(values[2]*256)+values[3];
  end

  return buildNo;
end

--
-- Function to convert a build version number into a string. If no build is
-- specified, the current build will be used.
--
function L.buildGetString(build)
  -- Check if a valid build version number was specified
  if ((type(build) ~= "number") or (build <= 0)) then
    -- Get the current build version number
    build = L.buildGetNumber(build)
  end

  -- Convert a build version number into a string
  return bit.band(bit.rshift(build, 16), 0xFF).."."..
         bit.band(bit.rshift(build, 8), 0xFF).."."..
         bit.band(build, 0xFF);
end

--
-- Method to get info for a continent by its index
--
function L.continents.byIndex(idx)
  -- Initialise the continent info, if required
  if (next(L.continents.associative) == nil) then
    L.continents.init();
  end

  -- Return the info for the continent with the specified index
  return unpack(L.continents.indexed[idx] or {});
end

--
-- Method to get info for a continent from a map ID
--
function L.continents.byMapId(mapId)
  -- Local Variables
  local mapContinent = L.continents.mapContinent;

  -- Initialise the continent info, if required
  if (next(mapContinent) == nil) then
    L.continents.init();
  end

  -- Return the info for the continent with the specified index
  return unpack(mapContinent[mapId] or {});
end

--
-- Method to get info for the current continent the player is on
--
function L.continents.player()
  -- Get the map info for the continent of the player's current zone
  local mapId = C_Map.GetBestMapForUnit("player");

  -- Return the info for the continent
  return (mapId ~= nil and L.continents.byMapId(mapId) or nil);
end

--
-- Method to initialise the continent info
--
function L.continents.init()
  -- Local Variables
  local associative = L.continents.associative;
  local current;
  local currentIdx;
  local idx;
  local indexed = L.continents.indexed;
  local mapContinent = L.continents.mapContinent
  local mapId;
  local mapInfo;
  local maxMask = 0;
  local other;
  local parentInfo;

  -- Check if the continent info has already been initialised
  if (next(associative) ~= nil) then
    return #indexed;
  end

  -- Initialise an entry for maps with no continent
  other = {0, L["Other"], 0x00000001};

  -- Get the names of the known continents
  for currentIdx, current in ipairs(indexed) do
    mapInfo                 = C_Map.GetMapInfo(current[1]);
    current[2]              = mapInfo.name;
    associative[current[2]] = current;
    maxMask                 = math.max(current[3], maxMask);
  end

  --- Initialise a list of each map's parent
  for idx = 1, 3000 do
    -- Get any map info for the ID
    mapInfo = C_Map.GetMapInfo(idx);
    if (mapInfo ~= nil) then
      -- Process the map's info
      if (mapInfo.mapType == Enum.UIMapType.Continent) then
        -- If the continent is unknown...
        if (associative[mapInfo.name] == nil) then
          -- ...add it to the object
          maxMask = bit.lshift(maxMask, 1);
          table.insert(indexed, {idx, mapInfo.name, maxMask});
          associative[mapInfo.name] = indexed[#indexed];
          mapContinent[idx]         = indexed[#indexed];
        end

        -- Map the ID to a continent
        mapContinent[idx] = associative[mapInfo.name];
      elseif (mapInfo.parentMapID ~= null) then
        -- Save the parent's map ID
        mapContinent[idx] = mapInfo.parentMapID;
      else
        -- Set the map's continent to 'Other'
        mapContinent[idx] = other;
      end
    end
  end

  -- Find the continent for each map
  for mapId, parentInfo in pairs(mapContinent) do
    while (type(parentInfo) == "number") do
      parentInfo = mapContinent[parentInfo];
    end
    mapContinent[mapId] =
      (parentInfo == nil and other or parentInfo);
  end

  -- Sort the indexed table by name
  table.sort(indexed,
    function(first, second) return (first[2] < second[2]); end);
  table.insert(indexed, other);

  return #indexed;
end

--
-- Function to set the colour of all textures in the 'BORDER' layer of a frame
--
function L.frameSetBorderColor(frame, r, g, b, a)
  -- Local Variables
  local _;
  local region;

  -- Iterate over all regions and process any with the 'BORDER' level
  for _, region in ipairs({frame:GetRegions()}) do
    if ((region:GetDrawLayer() == "BORDER") and
        (region:GetObjectType() == "Texture")) then
      region:SetVertexColor(r, g, b, a);
    end
  end

  return;
end

--
-- Function to restore the position and size of a frame, if previously saved
-- using the specified name
--
function L.layoutRestore(name, frame, restoreSize)
  -- Local Variables
  local current;

  -- Check the specified arguments are valid and there is a layout for the name
  if ((type(name) == "string") and
      (name ~= "") and
      (frame ~= nil) and
      (NglPtDB.layout[name] ~= nil)) then
    -- Assign info to more convenient variables
    current = NglPtDB.layout[name];

    -- Set the frame's point(s)
    frame:ClearAllPoints();
    if (pointMapping[current.point] ~= nil) then
      for _, point in ipairs(pointMapping[current.point]) do
        frame:SetPoint(point, UIParent, (current.x or 0), (current.y or 0));
      end
    end

    -- Restore the frame's size, if required
    if (restoreSize) then
      frame:SetSize(math.max(current.width, 1), math.max(current.height, 1));
    end
  end

  return;
end

--
-- Function to save the position and size of a frame under the specified name
--
function L.layoutSave(name, frame, saveSize)
  -- Local Variables
  local botOffset;
  local centreH;
  local centreV;
  local leftOffset;
  local offset;
  local rightOffset;
  local topOffset;
  local uiCentreH;
  local uiCentreV;

  -- Check the specified arguments are valid
  if ((type(name) == "string") and (name ~= "") and (frame ~= nil)) then
    -- Get info for the specified frame
    leftOffset       = math.max(frame:GetLeft(), 0);
    rightOffset      = math.max(UIParent:GetWidth()-frame:GetRight(), 0);
    topOffset        = math.max(UIParent:GetHeight()-frame:GetTop(), 0);
    botOffset        = math.max(frame:GetBottom(), 0);
    centreH, centreV = frame:GetCenter();

    -- Get centre of the UIParent
    uiCentreH, uiCentreV = UIParent:GetCenter();

    -- Initialise/reset the layout info for the specified name
    if (type(NglPtDB.layout) ~= "table") then
      NglPtDB.layout = {};
    end
    NglPtDB.layout[name] =
    {
      point  = "",
      x      = 0,
      y      = 0,
      width  = -1,
      height = -1,
    };
    current = NglPtDB.layout[name];

    -- Save the vertical positioning
    offset = math.abs(uiCentreV-centreV);
    if ((offset < topOffset) and (offset < botOffset)) then
      current.point = "C";
      current.y      = centreV-uiCentreV;
    elseif (topOffset < botOffset) then
      current.point = "T";
      current.y      = -topOffset;
    else
      current.point = "B";
      current.y      = botOffset;
    end

    -- Save the horizontal positioning
    offset = math.abs(uiCentreH-centreH);
    if ((offset < leftOffset) and (offset < rightOffset)) then
      current.point = current.point.."C";
      current.x      = centreH-uiCentreH;
    elseif (leftOffset < rightOffset) then
      current.point = current.point.."L";
      current.x      = leftOffset;
    else
      current.point = current.point.."R";
      current.x      = -rightOffset;
    end

    -- Save the size, if required
    if (saveSize) then
      current.width, current.height = frame:GetSize();
    end
  end

  return;
end

--
-- Function to hide the tutorial alert. If the frame specified matches the
-- current parent, the flag will be set that indicates the tutorial has been
-- seen.
--
function L.tutorialAlertHide(frame)
  -- Check the tutorial alert exists
  if (tutorialAlert ~= nil) then
    -- Set the flag for the alert, if specified
    if (tutorialAlert:GetParent() == frame) then
      NglPtDB.tutorialSeen = bit.bor((NglPtDB.tutorialSeen or 0),
        tutorialAlert.flag);
    end

    -- Hide the tutorial alert
    tutorialAlert:Hide();
  end

  return;
end

--
-- Function to show the tutorial alert
--
function L.tutorialAlertShow(parent, text, flag, direction, anchor, xOffset, yOffset)
  -- Local Variables
  local tutorialPoint = tutorialPoints[direction];

  -- Create the tutorial alert, if required
  if (tutorialAlert == nil) then
    tutorialAlert = CreateFrame("Frame", nil, UIParent,
      "NigglesPetTeamsTutorialAlertTemplate");
    tutorialAlert.close:SetScript("OnClick", tutorialAlertCloseOnClick);
    tutorialAlert.text:SetSpacing(4);
    SetClampedTextureRotation(tutorialAlert.arrows[1],  90);
    SetClampedTextureRotation(tutorialAlert.arrows[2], 270);
  end

  -- Position the tutorial alert
  anchor = (anchor or parent or UIParent);
  tutorialAlert:SetParent(parent);
  tutorialAlert:SetFrameStrata("FULLSCREEN_DIALOG");
  tutorialAlert:ClearAllPoints();
  tutorialAlert:SetPoint("CENTER", anchor);
  if (tutorialPoint ~= nil) then
    tutorialAlert:SetPoint(tutorialPoint[1], anchor, tutorialPoint[2],
      tutorialPoint[3]+(xOffset or 0),
      tutorialPoint[4]+(yOffset or 0));
  end

  -- Show the correct arrow for the specified direction
  for arrowIdx, arrow in ipairs(tutorialAlert.arrows) do
    arrow:SetShown(arrowIdx == direction);
  end

  -- Set the tutorial alert's text
  tutorialAlert.text:SetText(text or "");
  tutorialAlert:SetHeight(tutorialAlert.text:GetHeight()+42);

  -- Save the flag for the tutorial
  tutorialAlert.flag = (type(flag) == "number" and flag or 0);

  -- Show the tutorial alert
  tutorialAlert:Show();

  return;
end

--
-- Function to copy a specified number of UTF-8 characters (NOT bytes) from a
-- string. It validates each character and replaces any invalid ones with '?'.
--
function L.utf8ncpy(src, srcChars)
  -- Local Variables
  local charBytes;
  local charPos = 0;
  local dest = {};
  local destChars = 0;
  local srcLen;
  local srcPos = 1;
  local strByte = string.byte;
  local strSub = string.sub;
  local utf8Byte;
  local utf8IsValid;
  local validEnd = 0;
  local validStart = 1;

  -- Check the arguments are valid
  if ((type(src) ~= "string") or
      (type(srcChars) ~= "number") or
      (srcChars < 1)) then
    error("Invalid arguments.");
  end

  -- Validate and work out the byte position of specified number of characters
  srcLen = string.len(src);
  while ((srcPos <= srcLen) and (destChars < srcChars)) do
    -- Initialise some variables
    utf8Byte    = strByte(src, srcPos);
    utf8IsValid = true;

    -- Work out how many bytes the next UTF-8 character contains
    if (utf8Byte < 0x80) then
      utf8Len = 1;
    elseif ((utf8Byte >= 0xC2) and (utf8Byte <= 0xDF)) then
      utf8Len = 2;
    elseif ((utf8Byte >= 0xE0) and (utf8Byte <= 0xEF)) then
      utf8Len = 3;
    elseif ((utf8Byte >= 0xF0) and (utf8Byte <= 0xF4)) then
      utf8Len = 4;
    else
      utf8Len     = 1;
      utf8IsValid = false;
    end

    -- Check if the UTF-8 character is multi-byte
    if ((utf8IsValid) and (utf8Len > 1)) then
      -- Validate the 2nd byte of the UTF-8 character
      validRange = (utf8ValidRange[utf8Byte] or utf8ValidRange[0]);
      utf8Byte   = strByte(src, srcPos+1);
      if ((utf8Byte ~= nil) and
          (utf8Byte >= validRange[1]) and (utf8Byte <= validRange[2])) then
        -- Validate the remaining bytes of the UTF-8 character
        for tailPos = 3, utf8Len do
          utf8Byte = strByte(src, srcPos+tailPos-1);
          if ((utf8Byte == nil) or (utf8Byte < 0x80) or (utf8Byte > 0xBF)) then
            utf8IsValid = false;
            break;
          end
        end
      else
        utf8IsValid = false;
      end
    end

    srcPos = srcPos+utf8Len;
    if (utf8IsValid) then
      validEnd = srcPos-1;
    else
      -- Add any valid characters to the destination
      if (validStart <= validEnd) then
        dest[#dest+1] = strSub(src, validStart, validEnd);
      end

      -- Add a '?' to the destination replace the bad character
      dest[#dest+1] = "?";

      -- Reset the valid start and end
      validStart = srcPos;
      validEnd   = 0;
    end
    destChars = destChars+1;
  end

  -- Add any remaining valid characters to the destination
  if (validStart <= validEnd) then
    dest[#dest+1] = strSub(src, validStart, validEnd);
  end

  return table.concat(dest);
end

-------------------------------------------------------------------------------
--               G  L  O  B  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when a dropdown is shown or hidden. It is used to close
-- any other dropdown shown with this function when a new dropdown is shown.
--
function NigglesPetTeamDropdownOnShowHide(self)
  -- If the dropdown previously shown isn't the specified dropdown...
  if ((dropdownShown ~= nil) and (self ~= dropdownShown)) then
    -- ...hide that dropdown
    dropdownShown:Hide();
  end

  -- Clear the shown dropdown
  dropdownShown = (self:IsShown() and self or nil);

  -- Play a sound
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

  return;
end
