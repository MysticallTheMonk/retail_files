-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local strategyEditBoxUpdateCursorPos;

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to get the isHtml flag for a strategy edit box
--
local function strategyEditBoxGetIsHtml(self)
  return self.isHtml:GetChecked();
end

--
-- Function to get the text displayed by a strategy edit box
--
local function strategyEditBoxGetText(self)
  return self.editBox:GetText();
end

--
-- Function called when the HTML checkbutton is clicked. It toggles the type
-- of text for the pet team strategy.
--
local function strategyEditBoxIsHtmlOnClick(self, mouseButton)
  -- Set the type of text for the pet team strategy
  self.isHtml = self:GetChecked();

  -- Check if the strategy frame is displaying the strategy
  if ((self.previewFrame ~= nil) and (self.previewFrame:IsVisible())) then
    -- Show the Pet Team Strategy panel again
    self.previewFrame:ShowPreview(self.editBox:GetText(), self.isHtml);
  end
 
  -- Play the appropriate sound
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

  return;
end

--
-- Function called when the cursor's position changes in the Strategy edit box
--
local function strategyEditBoxOnCursorChanged(self, x, y, width, height)
  -- Update the cursor position displayed
  strategyEditBoxUpdateCursorPos(self, false);

  -- Perform the standard tasks for a scrolling editbox
  ScrollingEdit_OnCursorChanged(self, x, y, width, height);

  return;
end

--
-- Function called when the text changes in the Strategy edit box
--
local function strategyEditBoxOnTextChanged(self, userInput)
  -- Update the cursor position displayed
  strategyEditBoxUpdateCursorPos(self, true);

  -- Update the remaining characters left
  self.remaining:SetText(L.MAX_TEAM_STRAT_LEN-strlenutf8(self.text));

  -- Perform the standard tasks for a scrolling editbox
  ScrollingEdit_OnTextChanged(self, self:GetParent());

  return;
end

--
-- Function to set the isHtml flag for a strategy edit box
--
local function strategyEditBoxSetIsHtml(self, isHtml)
  -- Set the isHtml flag for the edit box
  self.isHtml:SetChecked(isHtml);

  return;
end

--
-- Function to set the text displayed by a strategy edit box
--
local function strategyEditBoxSetText(self, text)
  -- Set the text for the edit box
  self.editBox:SetText(text);
  self.editBox:SetCursorPosition(0);
  self.scroll:SetVerticalScroll(0);

  return;
end

--
-- Function called when a strategy edit box is resized
--
local function strategyEditBoxOnResize(self)
  -- Adjust the size of the edit box
  self.editBox:SetWidth(self.scroll:GetWidth());

  return;
end

--
-- Function to update the cursor position displayed by a strategy edit box
--
-- NOTE: Unfortunately the 'OnCursorChanged' script is called before the
--       'OnTextChanged' script, otherwise most of this function could be
--       part of the 'OnTextChanged' script.
--
strategyEditBoxUpdateCursorPos = function(self, refresh)
  -- Local Variables
  local byte;
  local cursorPos = self:GetCursorPosition();
  local newLinePos = self.newLinePos;
  local nextPos;
  local numLetters = 0;
  local numLines;
  local posHigh;
  local posLow = 1;
  local posMid;
  local strByte = string.byte;
  local strfind = string.find;
  local text = self.text;

  -- Check if the text needs refreshing
  if ((refresh) or (cursorPos > string.len(text))) then
    -- Get the text
    self.text = self:GetText();
    text      = self.text;

    -- Get the position for the start of each line
    numLines = 1;
    nextPos  = string.find(text, "\n", 1, true);
    while (nextPos ~= nil) do
      numLines = numLines+1;
      newLinePos[numLines] = nextPos;
      nextPos = string.find(text, "\n", nextPos+1, true);
    end
    self.numLines = numLines;
  else
    numLines = self.numLines;
  end

  -- Work out the cursor's position, if possible
  if (cursorPos <= string.len(text)) then
    -- Work out which line the cursor is on
    posHigh = self.numLines;
    while (posLow <= posHigh) do
      posMid = math.floor((posLow+posHigh)/2);
      if (cursorPos < newLinePos[posMid]) then
        if (posMid == 1) then
          break;
        else
          posHigh = posMid-1;
        end
      else
        if (posMid == numLines) then
          break;
        elseif (cursorPos >= newLinePos[posMid+1]) then
          posLow = posMid+1;
        else
          break;
        end
      end
    end
   
    -- Update the displayed line number, if required
    if (self.lineNo.value ~= posMid) then
      self.lineNo:SetText(posMid);
      self.lineNo.value = posMid;
    end

    -- Work out which column the cursor is in, allowing for UTF-8 characters
    -- NOTE: It is presumed that the text is a valid UTF-8 string, as it has
    --       been obtained from the Blizzard edit box.
    pos = newLinePos[posMid];
    while (pos < cursorPos) do
      numLetters = numLetters+1;
      pos = pos+1;
      byte = strByte(text, pos);
      if (byte > 127) then
        if (byte <= 223) then
          pos = pos+1;
        elseif (byte <= 239) then
          pos = pos+2;
        else
          pos = pos+3;
        end
      end
    end

    -- Update the displayed line number, if required
    if (self.colNo.value ~= numLetters) then
      self.colNo:SetText(numLetters);
      self.colNo.value = numLetters;
    end
  end

  return;
end

-------------------------------------------------------------------------------
--               G  L  O  B  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to create and initialise the Pet Team edit frame
--
function NigglesPetTeamStrategyEditBoxOnLoad(self)
  -- Local Variables
  local child;
  local name;

  -- Initialise the editbox
  child = self.scroll.editBox;
  child:SetMaxLetters(L.MAX_TEAM_STRAT_LEN);
  child.newLinePos = {0};
  child.numLines   = 1;
  child.lineNo     = self.lineNo;
  child.colNo      = self.colNo;
  child.remaining  = self.remaining;
  child.text       = "";
  child:SetScript("OnCursorChanged", strategyEditBoxOnCursorChanged);
  child:SetScript("OnTextChanged",   strategyEditBoxOnTextChanged);
  self.editBox = child;

  -- Initialise the Strategy HTML checkbox
  child = self.isHtml;
  child:SetText(L["HTML"]);
  child:SetPushedTextOffset(0, 0);
  child:GetFontString():SetPoint("LEFT", child, "RIGHT");
  child:SetHitRectInsets(0, -child:GetFontString():GetStringWidth(), 0, 0);
  child:SetScript("OnClick", strategyEditBoxIsHtmlOnClick);

  -- Set the localized text for some font strings
  child = self.lineNoLabel;
  child:SetText(L["Line:"]);
  child:SetWidth(child:GetStringWidth());
  child = self.colNoLabel;
  child:SetText(L["Col:"]);
  child:SetWidth(child:GetStringWidth());
  child = self.remainingLabel;
  child:SetText(L["Left:"]);
  child:SetWidth(child:GetStringWidth());

  -- Show the background of the scrollbar for the Strategy scroll frame
  name = self:GetName();
  if (name ~= nil) then
    _G[name.."ScrollScrollBarBG"]:Show();
    _G[name.."ScrollScrollBarBG"]:SetVertexColor(0, 0, 0, 0.75);
  end

  -- Add some function to the frame
  self.GetIsHtml = strategyEditBoxGetIsHtml;
  self.GetText   = strategyEditBoxGetText;
  self.SetIsHtml = strategyEditBoxSetIsHtml;
  self.SetText   = strategyEditBoxSetText;

  -- Add required script handlers
  self:SetScript("OnSizeChanged", strategyEditBoxOnResize);

  return;
end
