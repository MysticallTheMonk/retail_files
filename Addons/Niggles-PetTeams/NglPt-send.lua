-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local receiverInfo =
{
  delay      = 0.5,
  timeout    = 30,
  chunkSize  = 200,
  chunkIdx   = -1,
  numChunks  = 0,
  data       = nil,
  dataLen    = 0,
  isComplete = false,
  timer      = nil,
};

local senderMax   = 16;
local senderCount = 0;
local senderInfo  = {};

local receivedTeams =
{
  maxSize    = 64,
  sequenceId = 0
};

local processMsgFuncs = {};

local petTeamSendFrame;

local petTeamLink =
{
  format = "|cff80ec70|Hitem:%s:::::::%d:|h["..
    "|TInterface\\MINIMAP\\ObjectIcons:0:0:0:1:256:256:96:128:127:159|t"..
    "%s]|h|r",
  itemId = "999788084"; -- '999'+'NPT' as ASCII codes
};
local senderLinkFormat  = "[%s|Hplayer:%s|h%s|h|r]";

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local sendPetTeamIncrementStatus;
local sendPetTeamSetStatus;
local receivedTeamProcess;
local receiverSendMsg;
local receiverSendDataChunk;

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to send a pet team to a recipient
--
local function petTeamSend()
  -- Local Variables
  local _;
  local name = strtrim(petTeamSendFrame.recipient.editBox:GetText());
  local realmName;
  local statusBar = petTeamSendFrame.recipient.statusBar;

  -- Make sure the name is a full name, so it can match the sender
  if (string.find(name, "^[^-]+-[^-]+$") == nil) then
    _, realmName = UnitFullName("player");
    name = name.."-"..realmName;
  end

  -- Save the recipient
  if (strtrim(name) ~= "")  then
    -- Encode the pet team
    receiverInfo.name = name;
    receiverInfo.data = L.petTeamEncode(receiverInfo.teamInfo);
    if (receiverInfo.data ~= nil) then
      receiverInfo.dataLen    = strlen(receiverInfo.data);
      receiverInfo.chunkIdx   = 0;
      receiverInfo.numChunks  = math.ceil(receiverInfo.dataLen/
        receiverInfo.chunkSize);
      receiverInfo.isComplete = false;
      statusBar:SetMinMaxValues(0, 1+receiverInfo.numChunks+1);
      sendPetTeamSetStatus(L["StatusConnecting"], 0);
      receiverSendMsg("VQY", true);
    else
      sendPetTeamSetStatus(L["StatusEncodeFailed"], -1);
    end
  end

  return;
end

--
-- Function called when the 'Send/Cancel' button is clicked
--
local function petTeamSendButtonOnClick(self, mouseButton)
  -- Process the click, based on the button's state
  if (self.isCancel == true) then
    sendPetTeamSetStatus(L["StatusCancelled"], -1);
  else
    petTeamSend(self, mouseButton);
  end

  return;
end

--
-- Function to process the enter key for the 'Name' edit box
--
local function petTeamSendNameOnEnter(self)
  -- Check if the AutoComplete functionality should process the event
  if (not AutoCompleteEditBox_OnEnterPressed(self)) then
    petTeamSend();
  end

  return;
end

--
-- Function called when the 'Send Pet Team' frame is shown or hidden
--
local function petTeamSendOnShowHide(self)
  -- Restore the frame's layout, if required
  if (self:IsShown()) then
    L.layoutRestore(self.layoutName, self, false);
  end

  -- Play the appropriate sound
  PlaySound(self:IsShown() and SOUNDKIT.IG_CHARACTER_INFO_OPEN or
    SOUNDKIT.IG_CHARACTER_INFO_CLOSE);

  return;
end

--
-- Function to process 'BSY' messages
--
processMsgFuncs["BSY"] = function(sender, channel, data)
  -- Check the message is from the expected sender and has the right ID
  if (strcmputf8i(sender, receiverInfo.name) == 0) then
    sendPetTeamSetStatus(format(L["StatusBusy"], sender), -1);
  end

  return isProcessed, nil;
end

--
-- Function to process 'CFM' messages
--
processMsgFuncs["CFM"] = function(sender, channel, data)
  -- Local Variables
  local isSuccessful = (data == "1");
  
  -- Check the message is from the expected sender
  if (strcmputf8i(sender, receiverInfo.name) == 0) then
    if (isSuccessful) then
      sendPetTeamSetStatus(L["StatusDone"], 0xFFFF);
    else
      sendPetTeamSetStatus(L["StatusDecodeFailed"], -1);
    end
  end

  return isProcessed, nil;
end

--
-- Function to process 'CQY' messages
--
processMsgFuncs["CQY"] = function(sender, channel, data)
  -- Local Variables
  local _;
  local currentInfo = senderInfo[sender];
  local response;
  local senderClassId = tonumber(data);

  -- Check the sender has sent data and their class ID is valid
  if ((currentInfo ~= nil) and
      (GetClassInfo(senderClassId) ~= nil) and
      (senderClassId >= 1) and
      (senderClassId <= GetNumClasses())) then
    -- Save the sender's class name
    _, currentInfo.className = GetClassInfo(senderClassId);
    
    -- Process the data sent
    response = receivedTeamProcess(sender);
  end

  return (response ~= nil), response;
end

--
-- Function to process 'DSD' message. It checks if the message is the first
-- from the sender and initialises a table for the sender if so. It then
-- stores the data from the sender until the end of the data is reached.
--
processMsgFuncs["DSD"] = function(sender, channel, data)
  -- Local Variables
  local _;
  local currentInfo = senderInfo[sender];
  local dataSegment;
  local isProcessed = false;
  local response;
  local sendSeqIdx;

  -- Extract info from the data
  _, _, sendSeqIdx, dataSegment = string.find(data, "^(%d+):(.*)$");
  sendSeqIdx = tonumber(sendSeqIdx);

  -- Check the expected info could be extracted
  if ((sendSeqIdx ~= nil) and (dataSegment ~= nil)) then
    -- Check if the message is the first for a team
    if (sendSeqIdx == 1) then
      -- Create info for the sender or wipe existing data
      if ((currentInfo == nil) and (strsub(dataSegment, 1, 1) == "{")) then
        if (senderCount < senderMax) then
          senderInfo[sender] = {seqIdx = 0, data = {}};
          senderCount = senderCount+1;
          currentInfo = senderInfo[sender];
        else
          response = "BSY";
        end
      elseif (currentInfo ~= nil) then
        currentInfo.seqIdx = 0;
        wipe(currentInfo.data);
      end
    end

    -- Check there is info for the sender and the sequence index is valid
    if ((currentInfo ~= nil) and (sendSeqIdx == currentInfo.seqIdx+1)) then
      -- Add the data to the sender info
      currentInfo.data[sendSeqIdx] = dataSegment;
      currentInfo.seqIdx = sendSeqIdx;
    end
    isProcessed = true;
  end

  return isProcessed, response;
end

--
-- Function to process 'VER' messages. It notifies the panel used to
-- send teams
--
-- WARNING: The format of the 'VER' message should NOT be changed
--
processMsgFuncs["VER"] = function(sender, channel, data)
  -- Local Variables
  local _;
  local addonVersion;
  local dataVersion;
  local isProcessed = false;

  -- Extract info from the data
  _, _, addonVersion, dataVersion = string.find(data, "^([^:]*):([^:]*)$");
  dataVersion = tonumber(dataVersion);

  -- Check the message is from the expected sender and has the right ID
  if (strcmputf8i(sender, receiverInfo.name) == 0) then
    -- Check the sender's addon version numbers are identical
    if ((addonVersion ~= C_AddOns.GetAddOnMetadata(L.ADDON_FOLDER_NAME,
          "Version")) or
        (dataVersion ~= L.importExportGetVersion())) then
      sendPetTeamSetStatus(L["StatusIncompatible"], -1);
    else
      receiverSendDataChunk();
    end
    isProcessed = true;
  end

  return isProcessed, nil;
end

--
-- Function to process 'VQY' messages. It responds with the addon's
-- versions
--
-- WARNING: The format of the 'VER' message should NOT be changed
--
processMsgFuncs["VQY"] = function(sender, channel, data)
  -- Send the addon's version and the import/export version
  return true, "VER:"..C_AddOns.GetAddOnMetadata(L.ADDON_FOLDER_NAME,
    "Version")..":"..L.importExportGetVersion();
end

--
-- Function to process a received pet team
--
receivedTeamProcess = function(sender)
  -- Local Variables
  local _;
  local chatFrame;
  local chatId;
  local currentInfo = senderInfo[sender];
  local isAdded = false;
  local notification;
  local response;
  local senderColor = "";
  local senderId = strlower(sender);
  local sequenceId;
  local teamInfo = {};
  local teamName;
  local teamSubname
  local whisperInfo = ChatTypeInfo["WHISPER"];

  -- Check the sender has info
  if (currentInfo ~= nil) then
    -- Initialise the info for the pet team
    L.petTeamCopy(nil, teamInfo);

    -- Decode the pet team
    if (L.petTeamDecode(table.concat(currentInfo.data), teamInfo) == nil) then
      -- Clear info that isn't valid for the receiver
      teamInfo.category = 0;
     
      -- Add the pet team to the received team queue
      sequenceId = receivedTeams.sequenceId+1;
      receivedTeams[sequenceId-receivedTeams.maxSize] = nil;
      receivedTeams[sequenceId] = teamInfo;
      receivedTeams.sequenceId = sequenceId;

      -- Work out what colour to use for the sender's name
      if (whisperInfo.colorNameByClass) then
        senderColor = "|c"..RAID_CLASS_COLORS[currentInfo.className].colorStr;
      end

      -- Create the notification
      teamName, teamSubName = L.petTeamGetNames(teamInfo);
      notification = format(L["StatusNotify"],
        format(senderLinkFormat, senderColor, sender,
          Ambiguate(sender, "none")),
        format(petTeamLink.format, petTeamLink.itemId, sequenceId,
          teamName..(teamSubName ~= nil and " - " or "")..(teamSubName or "")));

      -- Add the notification to any appropriate chat frames
      for _, current in pairs(CHAT_FRAMES) do
        chatFrame = _G[current];
        chatId = chatFrame:GetID();
        if (((chatId >= 1) and 
             (chatId <= NUM_CHAT_WINDOWS) and 
             (tContains({GetChatWindowMessages(chatId)}, "WHISPER"))) or
            ((chatFrame.privateMessageList ~= nil) and
             (chatFrame.privateMessageList[senderId] == true) and
             (chatFrame.chatType == "WHISPER"))) then
          -- Add the notification the chat frame
          chatFrame:AddMessage(notification, whisperInfo.r, whisperInfo.g,
            whisperInfo.b, whisperInfo.id);
          isAdded = true;
        end
      end
      
      -- If the message hasn't been added to any chat frame...
      if (not isAdded) then
        -- ...add it to the default chat frame
        DEFAULT_CHAT_FRAME:AddMessage(notification, whisperInfo.r,
          whisperInfo.g, whisperInfo.b, whisperInfo.id);
      end
      
      -- Play a sound to alert the player
      PlaySound(SOUNDKIT.TELL_MESSAGE);

      -- Set the response
      response = "CFM:1";
    else
      response = "CFM:0";
    end

    -- Remove the sender's info
    senderInfo[sender] = nil;
    senderCount = senderCount-1;
  end

  return response;
end

--
-- Function called when an expected response isn't received from the receiver
-- in a reasonable time.
--
local function receiverNoConfirmation()
  -- Remove the timer
  receiverInfo.timer = nil;

  -- Update the status
  if (not receiverInfo.isComplete) then
    sendPetTeamSetStatus(L["StatusNoConfirmation"], -1);
  end

  return;
end

--
-- Function called when an expected response isn't received from the receiver
-- in a reasonable time.
--
local function receiverNoResponse()
  -- Remove the timer
  receiverInfo.timer = nil;

  -- Update the status
  if (not receiverInfo.isComplete) then
    sendPetTeamSetStatus(L["StatusNoResponse"], -1);
    receiverInfo.isComplete = true;
  end

  return;
end

--
-- Function to send a data chunk receiver
--
receiverSendDataChunk = function()
  -- Local Variables
  local chunkIdx = receiverInfo.chunkIdx;
  local chunkSize = receiverInfo.chunkSize;

  -- Check the send hasn't been cancelled
  if (not receiverInfo.isComplete) then
    -- Send the next chunk of data
    if (chunkIdx < receiverInfo.numChunks) then
      -- Update the status
      sendPetTeamIncrementStatus(format(L["StatusSending"], chunkIdx+1,
        receiverInfo.numChunks));
     
      -- Send the message
      receiverSendMsg(
        format("DSD:%d:%s", chunkIdx+1,
          strsub(receiverInfo.data, 1+(chunkIdx*chunkSize),
            ((chunkIdx+1)*chunkSize))), false);
      receiverInfo.chunkIdx = chunkIdx+1;
    end

    -- Check if there is more data to be sent
    if (receiverInfo.chunkIdx < receiverInfo.numChunks) then
      -- Set a timer to send the next chunk in a short while
      C_Timer.After(receiverInfo.delay, receiverSendDataChunk);
    else
      -- Update the status
      sendPetTeamIncrementStatus(L["StatusConfirmation"]);

      -- Send a confirmation request
      local _, _, classId = UnitClass("player");
      receiverSendMsg("CQY:"..classId, true);
    end
  end

  return;
end

--
-- Function to send an addon message to the receiver
--
receiverSendMsg = function(message, responseExpected)
  -- Send the message, appending the response ID
  C_ChatInfo.SendAddonMessage(L.ADDON_MSG_PREFIX, message, "WHISPER",
    receiverInfo.name);

  -- Check if a response is expected
  if (responseExpected) then
    -- Set a timer for a timeout
    receiverInfo.timer = C_Timer.NewTimer(receiverInfo.timeout,
      receiverNoResponse);
  end

  return;
end

--
-- Function to update the status bar in the 'Send Pet Team' panel
--
sendPetTeamIncrementStatus = function(statusMsg)
  -- Update the status bar by one step
  sendPetTeamSetStatus(statusMsg, 
    petTeamSendFrame.recipient.statusBar:GetValue()+1);

  return;
end

--
-- Function to update the status bar in the 'Send Pet Team' panel
--
sendPetTeamSetStatus = function(statusMsg, step)
  -- Local Variables
  local _;
  local frame = petTeamSendFrame.recipient;
  local numSteps = 0;
  local statusBar = petTeamSendFrame.recipient.statusBar;

  -- Update the status bar
  statusBar.label:SetText(statusMsg);
  if (step >= 0) then
    statusBar:SetStatusBarColor(0.0, 1.0, 0.0);
    statusBar:SetValue(step);
    _, numSteps = statusBar:GetMinMaxValues();
  else
    statusBar:SetStatusBarColor(1.0, 1.0, 0.0);
    statusBar:SetMinMaxValues(0, 1);
    statusBar:SetValue(0);
    statusBar:SetValue(1);
  end

  -- Change the text for the 'Send/Cancel' button
  frame.send.isCancel = ((step >= 0) and (step < numSteps));
  frame.send:SetText(frame.send.isCancel and CANCEL or L["Send"]);
  
  -- Enable/disable the edit box
  frame.editBox:SetEnabled(not frame.send.isCancel);

  -- Update the 'isComplete' flag
  receiverInfo.isComplete = not frame.send.isCancel;

  return
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when a hyperlink is clicked in a chat frame. It checks if
-- an item hyperlink has been clicked. If so and it is the dummy item used
-- to indicate
--
function L.chatHyperlinkOnShow(self, link, text, button)
  -- Local variables
  local linkType;
  local itemId;
  local sequenceId;

  -- Check if the link is for a pet team
  _, _, linkType, itemId, sequenceId =
    string.find(link, "([^:]*):(%d+):::::::(%d):");
  if ((linkType == "item") and (itemId == petTeamLink.itemId)) then
    -- Hide the item reference tooltip
	  HideUIPanel(ItemRefTooltip);

    -- Check if the pet team is still in the received team queue
    sequenceId = tonumber(sequenceId);
    if (receivedTeams[sequenceId] ~= nil) then
      -- Show the Pet Journal, if required
      if ((CollectionsJournal == nil) or
			    (not CollectionsJournal:IsShown()) or
          (PanelTemplates_GetSelectedTab(CollectionsJournal) ~= 2)) then
        ToggleCollectionsJournal(2);
      end

      -- Create a pet team for the received pet team
      L.petTeamEdit(nil, receivedTeams[sequenceId]);
    else
      StaticPopup_Show("NIGGLES_PETTEAMS_WARNING", L["PetTeamNotAvailable"]);
    end
  end

  return;
end

--
-- Function to process an addon message.
--
function L.sendProcessMessage(prefix, message, channel, sender, ...)
  -- Check the prefix matches the addon's
  if ((prefix == L.ADDON_MSG_PREFIX) and
      (channel == "WHISPER") and
      (sender ~= nil) and (sender ~= "")) then
    -- Local Variables
    local msgType;
    local msgData;
    local isProcessed = false;

    -- Get the message type and data
    if (strlen(message) == 3) then
      msgType = message;
    else
      _, _, msgType, msgData = string.find(message, "^([^:]*):(.*)$");
    end

    -- Call the function to process the message
    if ((msgType ~= nil) and (processMsgFuncs[msgType] ~= nil)) then
      isProcessed, response = processMsgFuncs[msgType](sender, channel,
        msgData);
    end

    -- Cancel any timeout timer if the message was successfully processed
    if ((isProcessed) and (receiverInfo.timer ~= nil)) then
      receiverInfo.timer:Cancel();
      receiverInfo.timer = nil;
    end

    -- Send a response, if required
    if (response ~= nil) then
      C_ChatInfo.SendAddonMessage(L.ADDON_MSG_PREFIX, response, channel,
        sender);
    end
  end

  return;
end

--
-- Function to hide the 'Send Pet Team' frame
--
function L.petTeamSendHide()
  -- Hide the Import/Export frame, if required
  if (petTeamSendFrame ~= nil) then
    petTeamSendFrame:Hide();
  end

  return
end

--
-- Function to send a pet team to another character
--
function L.petTeamSendShow(teamInfo)
  -- Local Variables
  local frame = petTeamSendFrame;

  -- Save the pet team to be sent
  receiverInfo.teamInfo = teamInfo;

  -- Create the 'Send Pet Team' frame, if required
  if (frame == nil) then
    -- Create the frame
    frame = CreateFrame("Frame", "NigglesPetTeamSend", NigglesPetTeams,
      "NigglesPetTeamSendTemplate");
    frame.TitleContainer.TitleText:SetText(L["PetTeamSend"]);
    frame.layoutName = "send";
    petTeamSendFrame = frame;

    -- Set the frame's portrait
    SetPortraitToTexture(frame.PortraitContainer.portrait,
      "Interface\\Icons\\PetJournalPortrait");

    -- Remove the highlight for the button used to display the pet team
    frame.petTeam.button:Disable();

    -- Set the layer of the status bar's texture
    frame.recipient.statusBar:GetStatusBarTexture():SetDrawLayer("BORDER");
     
    -- Set labels
    frame.petTeam.title:SetText(L["Pet Team"]);
    frame.recipient.title:SetText(L["Recipient"]);
    frame.recipient.label:SetText(L["Name"]..":");
    frame.recipient.send:SetText(L["Send"]);

    -- Hook script handlers
    frame.dragButton:HookScript("OnMouseUp",
      function(frame)
        L.layoutSave(frame:GetParent().layoutName, frame:GetParent(), false);
        return;
      end);
     
    -- Set the frame's scripts
    frame:SetScript("OnShow", petTeamSendOnShowHide);
    frame:SetScript("OnHide", petTeamSendOnShowHide);
    frame.recipient.editBox:SetScript("OnEnterPressed", petTeamSendNameOnEnter);
    frame.recipient.send:SetScript("OnClick", petTeamSendButtonOnClick);
  end

  -- Initialise the frame
  L.petTeamButtonSet(frame.petTeam.button, teamInfo, true);
  frame.recipient.send:SetText(L["Send"]);
  frame.recipient.send:SetEnabled(
    strlen(strtrim(frame.recipient.editBox:GetText())) >= 2);
  frame.recipient.statusBar:SetValue(0);
  frame.recipient.statusBar.label:SetText("");

  -- Hide other panels
  L.petTeamImportExportHide();
  L.petTeamEditFrameHide()
  StaticPopup_Hide("NIGGLES_PETTEAMS_WARNING");

  -- Show the frame
  frame:Show();
  frame.recipient.editBox:SetFocus();

  return;
end
