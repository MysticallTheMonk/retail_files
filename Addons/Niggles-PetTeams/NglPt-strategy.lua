-------------------------------------------------------------------------------
--               G  L  O  B  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                 L  O  C  A  L     V  A  R  I  A  B  L  E  S
-------------------------------------------------------------------------------

local addonName, L = ...;

local petTeamsFiltered = setmetatable({[0] = 0},
{
  __index = function(table, key)
    table[key] = {};
    return table[key];
  end
});

local strategyEditFrame;

-------------------------------------------------------------------------------
--                  L  O  C  A  L     C  L  A  S  S  E  S
-------------------------------------------------------------------------------

--
-- Class for parsing and rendering simple HTML
--
local NigglesPetTeamsHtmlClass =
{
  -----------------------------------------------------------------------------
  --             C  L  A  S  S     V  A  R  I  A  B  L  E  S
  -----------------------------------------------------------------------------

  -- Valid HTML tags for this class
  --
  validTags =
  {
    ["body"] =
    {
      children      =
      {
        h1 = true, h2 = true, h3 = true, h4   = true, p  = true, pre  = true,
        ol = true, ul = true, b  = true, span = true, br = true, text = true,
      },
      isInline      = false,
      defaultStyles =
      {
        color        = "#ffffff",
        fontFamily   = "GameFontHighlight",
        marginBottom = 0,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 0,
        textAlign    = "left",
      },
    },
    ["h1"] =
    {
      children      = {b = true, span = true, br = true, text = true,},
      isInline      = false,
      defaultStyles =
      {
        color        = "#ffd100",
        fontFamily   = "QuestFont_Super_Huge",
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
        textAlign    = "left",
      },
    },
    ["h2"] =
    {
      children      = {b = true, span = true, br = true, text = true,},
      isInline      = false,
      defaultStyles =
      {
        color        = "#ffd100",
        fontFamily   = "QuestFont_Huge",
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
        textAlign    = "left",
      },
    },
    ["h3"] =
    {
      children      = {b = true, span = true, br = true, text = true,},
      isInline      = false,
      defaultStyles =
      {
        color        = "#ffd100",
        fontFamily   = "QuestFont_Large",
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
        textAlign    = "left",
      },
    },
    ["h4"] =
    {
      children      = {b = true, span = true, br = true, text = true,},
      isInline      = false,
      defaultStyles =
      {
        color        = "#ffd100",
        fontFamily   = "GameFontNormal",
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
        textAlign    = "left",
      },
    },
    ["p"] =
    {
      children = {b = true, span = true, br = true, text = true,},
      isInline = false,
      defaultStyles =
      {
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
      },
    },
    ["pre"] =
    {
      children = {b = true, span = true, br = true, text = true,},
      isInline = false,
      defaultStyles =
      {
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
        textAlign    = "left",
      },
    },
    ["ul"] =
    {
      children      = {li = true,},
      isInline      = false,
      defaultStyles =
      {
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
      },
      preChildren = function(self, element, indent)
        -- Local Variables
        local lastFontString = self:fontStringsGetLast();

        -- Measure the bullet for each list item
        self.measure:SetFontObject(self.specialStyles["ul"].fontFamily);
        self.measure:SetText(" \226\151\143 ");

        -- Incorporate ul's top margin into last font string's bottom margin
        if (lastFontString ~= nil) then
          lastFontString.marginBottom = math.max(lastFontString.marginBottom,
            element.styles.marginTop);
        end

        return "", indent+math.ceil(self.measure:GetStringWidth());
      end,
      preChild = function(self, element, childIdx, child, indent, childIndent)
        local fontString = self:fontStringsSetNext(" \226\151\143 ", indent,
          "BOTTOM", child.styles, self.specialStyles["ul"]);
        fontString:SetPoint("RIGHT", self.frame, "LEFT", childIndent, 0);
        return "TOP";
      end,
      postChildren = function(self, element, indent)
        -- Local Variables
        local lastFontString = self:fontStringsGetLast();

        -- Incorporate ul's bottom margin into last font string's bottom margin
        if (lastFontString ~= nil) then
          lastFontString.marginBottom = math.max(lastFontString.marginBottom,
            element.styles.marginBottom);
        end

        return "";
      end
    },
    ["ol"] =
    {
      children      = {li = true,},
      isInline      = false,
      defaultStyles =
      {
        marginBottom = 5,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 5,
      },
      preChildren = function(self, element, indent)
        -- Local Variables
        local childIndent = 0;
        local children = element.children;
        local lastFontString = self:fontStringsGetLast();
        local measure = self.measure;
        local width;

        -- Measure the number text for each list item
        for childIdx = 1, #(element.children) do
          measure:SetFontObject(children[childIdx].styles.fontFamily);
          measure:SetText(" "..childIdx..": ");
          width = math.ceil(measure:GetStringWidth());
          if (width > childIndent) then
            childIndent = width;
          end
        end

        -- Incorporate ol's top margin into last font string's bottom margin
        if (lastFontString ~= nil) then
          lastFontString.marginBottom = math.max(lastFontString.marginBottom,
            element.styles.marginTop);
        end

        return "", childIndent+indent;
      end,
      preChild = function(self, element, childIdx, child, indent, childIndent)
        local fontString = self:fontStringsSetNext(childIdx..". ", indent,
          "BOTTOM", child.styles, self.specialStyles["ol"]);
        fontString:SetPoint("RIGHT", self.frame, "LEFT", childIndent, 0);
        return "TOP";
      end,
      postChildren = function(self, element, indent)
        -- Local Variables
        local lastFontString = self:fontStringsGetLast();

        -- Incorporate ol's bottom margin into last font string's bottom margin
        if (lastFontString ~= nil) then
          lastFontString.marginBottom = math.max(lastFontString.marginBottom,
            element.styles.marginBottom);
        end

        return "";
      end
    },
    ["li"] =
    {
      children      =
      {
        h1 = true, h2 = true, h3   = true, h4 = true, p    = true, ol = true,
        ul = true, b  = true, span = true, br = true, text = true,
      },
      isInline      = false,
      defaultStyles =
      {
        marginBottom = 0,
        marginLeft   = 0,
        marginRight  = 0,
        marginTop    = 0,
      },
    },
    ["b"] =
    {
      children      = {b = true, span = true, br = true, text = true,},
      isInline      = true;
      defaultStyles =
      {
        color = "#ffd100",
      },
      preChildren  = function(self, element, indent)
        return "|cff"..string.sub(element.styles.color, 2), indent;
      end,
      postChild = function(self, element, childIdx, child, indent, childIndent)
        return (child.tag ~= "text" and
          ("|cff"..string.sub(element.styles.color, 2)) or "");
      end,
      postChildren = function(self, element, indent)
        return "|r";
      end,
    },
    ["span"] =
    {
      children = {b = true, span = true, br = true, text = true,},
      isInline = true;
      -- Pre/post-child(ren) functions initialised on first 'New'
    },
    ["br"] =
    {
      children = {},
      isInline = true,
      preChildren = function(self, element, indent)
        return "\n";
      end,
    },
    ["text"] =
    {
      children    = {},
      isInline    = true,
      preChildren = function(self, element, indent)
        if (self:hasAncestor(element, "pre")) then
          return self.src:sub(element.posStart, element.posEnd):
            gsub("|", "||"), indent;
        else
          return self.src:sub(element.posStart, element.posEnd):
            gsub("|", "||"):gsub("%s+", " "), indent;
        end
      end,
    },
  };

  --
  -- Valid Attributes
  --
  validAttributes =
  {
    ["style"] =
      function(self, element, styles)
        -- Local Variables
        local stylesPos = 1;
        local nextStyle;
        local nextStyleValue;
        local stylesLen = string.len(styles);
        local nextStyleStart;
        local nextStyleEnd;

        -- Process the element's styles
        while (stylesPos < stylesLen) do
          -- Extract the next style
          nextStyleStart, nextStyleEnd, nextStyle, nextStyleValue =
            string.find(styles, "^%s*([%w-]+)%s*:%s*([^;]*)%s*;", stylesPos);
          if (nextStyleStart == nil) then
            nextStyleStart, nextStyleEnd, nextStyle, nextStyleValue =
              string.find(styles, "^%s*([%w-]+)%s*:%s*([^;]*)%s*$", stylesPos);
          end

          -- Check a style could be extracted
          if (nextStyleStart ~= nil) then
            -- Check the style is valid and supported
            if (self.validStyles[nextStyle] ~= nil) then
              -- Update the element's styles
              (self.validStyles[nextStyle])(self, element.styles,
                nextStyleValue);
            end
            stylesPos = nextStyleEnd+1;
          else
            stylesPos = stylesLen;
          end
        end

        return;
      end,
  };

  --
  -- Valid Styles
  --
  validStyles =
  {
    ["color"] =
      function(self, elementStyles, color)
        if (string.find(color, "^#%x%x%x%x%x%x$") ~= nil) then
          elementStyles.color = color;
        end
        return;
      end,
    ["font-family"] =
      function(self, elementStyles, font)
        if ((_G[font] ~= nil) and
            (type(_G[font].GetObjectType) == "function") and
            (_G[font]:GetObjectType() == "Font")) then
          elementStyles.fontFamily = font;
        end
        return;
      end,
    ["text-align"] =
      function(self, elementStyles, align)
        align = string.lower(align);
        if ((align == "left") or (align == "center") or (align == "right")) then
          elementStyles.textAlign = align;
        end
        return;
      end,
  };

  --
  -- Special styles for certain HTML tags
  --
  specialStyles =
  {
    ["error"] =
    {
      color      = "#ff0000",
      fontFamily = "GameFontHighlight",
      textAlign  = "left",
    },
    ["ol"] =
    {
      textAlign  = "right",
    },
    ["plainText"] =
    {
      color      = "#ffffff",
      fontFamily = "GameFontHighlight",
      textAlign  = "left",
    },
    ["ul"] =
    {
      fontFamily = "ChatFontSmall",
      textAlign  = "right",
    },
  };

  --
  -- HTML entities
  --
  htmlEntities =
  {
    ["&amp;"]   = "&",
    ["&gt;"]    = ">",
    ["&lt;"]    = "<",
    ["&nbsp;"]  = " ",
    ["&quote;"] = "\"",
  };

  -----------------------------------------------------------------------------
  --          I  N  T  E  R  N  A  L     F  U  N  C  T  I  O  N  S
  -----------------------------------------------------------------------------

  --
  -- Method to free all used font strings
  --
  fontStringsFreeAll = function(self)
    -- Local Variables
    local fontStrings = self.fontStrings;

    -- Hide all used font strings
    for idx = self.usedFontStrings, 1, -1 do
      fontStrings[idx]:Hide();
    end

    -- Reset the number of used font strings
    self.usedFontStrings = 0;

    return;
  end;

  --
  -- Method used to get the last font string used
  --
  fontStringsGetLast = function(self)
    return self.fontStrings[self.usedFontStrings];
  end;

  --
  -- Method used to set the next available font string used to
  -- display the HTML. If all the existing font strings have been used then
  -- new font strings will be created as needed.
  --
  fontStringsSetNext = function(self, text, indent, attach, styles, specialStyles)
    -- Local Variables
    local color;
    local fontString;
    local prevFontString = self.fontStrings[self.usedFontStrings];
    local usedStrings = self.usedFontStrings+1;

    -- Make sure the special styles are valid
    specialStyles = (type(specialStyles) == "table" and specialStyles or
      self.emptyTable);

    -- Create a new font string, if required
    if (usedStrings > #(self.fontStrings)) then
      -- Create a new font string
      fontString = self.frame:CreateFontString();
      fontString:SetFontObject("GameFontHighlight");
      fontString:SetJustifyV("top");
      fontString:SetNonSpaceWrap(false);
      fontString:SetMaxLines(2048);

      -- Add the font string to the list
      fontString.prev = self.fontStrings[#(self.fontStrings)];
      self.fontStrings[#(self.fontStrings)+1] = fontString;
    else
      fontString = self.fontStrings[usedStrings];
    end

    -- Position the font string
    color = (specialStyles.color or styles.color);
    fontString:SetJustifyH(specialStyles.textAlign or styles.textAlign);
    fontString:SetFontObject(specialStyles.fontFamily or styles.fontFamily);
    fontString:SetTextColor(
      (tonumber(string.sub(color, 2, 3), 16)/255),
      (tonumber(string.sub(color, 4, 5), 16)/255),
      (tonumber(string.sub(color, 6, 7), 16)/255));
    fontString:ClearAllPoints();
    if (usedStrings == 1) then
      fontString:SetPoint("TOP", self.frame, "TOP", 0, 0);
    elseif (attach == "TOP") then
      fontString:SetPoint("TOP", prevFontString, attach, 0, 0);
    else
      fontString:SetPoint("TOP", prevFontString, attach, 0,
        -math.max(styles.marginTop, prevFontString.marginBottom));
    end
    fontString:SetPoint("LEFT", indent, 0);
    fontString:SetPoint("RIGHT", self.frame);
    fontString.marginBottom = styles.marginBottom;

    -- Set the font string's text
    fontString:SetText(string.gsub(text, "&%w+;", self.htmlEntities));

    -- Update the number of used font strings
    self.usedFontStrings = usedStrings;

    return fontString;
  end;

  --
  -- Method called when the frame used to display the HTML changes size.
  -- It works out the correct height for the frame, based on the position of
  -- the last font string used.
  --
  frameOnSizeChanged = function(frame)
    -- Local Variables
    local self = frame.object;
    local fontString;

    -- Force font strings to recalculate their heights by setting their width
    for idx = 1, self.usedFontStrings do
      fontString = self.fontStrings[idx];
      fontString:SetWidth(fontString:GetWidth());
    end

    return;
  end;

  --
  -- Method called via the HTML object's frame to set the displayed HTML
  --
  frameSetHTML = function(frame, html)
    (frame.object):SetHTML(html);
    return;
  end;

  --
  -- Method called via the HTML object's frame to set the displayed text
  --
  frameSetText = function(frame, text)
    (frame.object):SetText(text);
    return;
  end;

  --
  -- Method to check if an element has an ancestor with a specified tag
  --
  hasAncestor = function(self, element, ancestorTag)
    -- Local Variables
    local ancestor = element.parent;
 
    -- Search the element's ancestors for an element with the specified tag
    while ((ancestor ~= nil) and (ancestor.tag ~= ancestorTag)) do
      ancestor = ancestor.parent;
    end
 
    return ((ancestor ~= nil) and (ancestor.tag == ancestorTag));
  end;

  --
  -- Method to parse a source string containing HTML and create a
  -- tree of elements. This function is recursive.
  --
  parse = function(self, parent, elementTag, elementAttrs, isClosed)
    -- Local Variables
    local child;
    local childTag;
    local children;
    local element;
    local endMarker;
    local errorMsg;
    local nextAttrs;
    local nextTag;
    local nextTagEnd;
    local nextTagInfo;
    local nextTagStart;
    local numChildren = 0;
    local numChildren = 0;
    local prevChild = nil;
    local stripTrailing;
    local styles;
    local tagInfo = self.validTags[elementTag];
    local tagOpen = not isClosed;
    local textEnd;
    local textStart;
    local validChildren = self.validTags[elementTag].children;
    local voidMarker;

    -- Initialise the element
    element =
    {
      tag      = elementTag,
      parent   = parent,
      children = {},
      isInline = tagInfo.isInline,
    };
    children = element.children;

    -- Initialise the element's styles
    if (parent ~= nil) then
      styles = setmetatable({}, {__index = parent.styles});
    else
      styles = {};
    end
    if (tagInfo.defaultStyles ~= nil) then
      for style, value in pairs(tagInfo.defaultStyles) do
        styles[style] = value;
      end
    end
    element.styles = styles;

    -- Check if there are any attributes to process
    if ((elementAttrs ~= nil) and (elementAttrs ~= "")) then
      -- Process the element's attributes
      self:processAttrs(element, elementAttrs);
    end

    -- Process all text and tags until the element's end tag is reached
    while ((tagOpen) and (self.srcPos < self.srcLen)) do
      -- Find the next tag
      nextTagStart, nextTagEnd, endMarker, nextTag, nextAttrs, voidMarker =
        string.find(self.src, "<(/?)([%w]+)(.-)(/?)>\n?", self.srcPos);
      nextTag = (nextTag and string.lower(nextTag) or nextTag);
      if (nextTagStart == nil) then
        if (elementTag == "body") then
          -- Handle any trailing text and then consider the body tag closed
          nextTagStart = self.srcLen+1;
          nextTagEnd   = self.srcLen+1;
          endMarker    = "/";
          voidMarker   = "";
          nextTag      = elementTag;
          nextTagInfo  = self.validTags[nextTag];
          nextAttrs    = "";
        else
          self:setError(self.srcLen, L["HtmlErrMissingEnd"]);
          break;
        end
      else
        -- Get the info for the next tag
        nextTagInfo = self.validTags[nextTag];
        if (nextTagInfo == nil) then
          self:setError(nextTagStart, L["HtmlErrUnknownTag"]);
          break;
        end
      end

      -- Check if there is any text preceding the next tag
      if (nextTagStart > self.srcPos) then
        -- Skip leading and trailing whitespaces, if required
        if (self.stripLeading) then
          textStart = string.find(self.src, "%S", self.srcPos);
        else
          textStart = self.srcPos;
        end
        if (not nextTagInfo.isInline) then
          textEnd =
            (string.find(self.src, "%s*<", textStart) or nextTagStart)-1;
        else
          textEnd = nextTagStart-1;
        end

        -- Check if there is some text to display
        if (textEnd >= textStart) then
          -- Check text is permitted
          if (validChildren.text) then
            -- Add the text as a child of the element
            numChildren = numChildren+1;
            children[numChildren] =
            {
              tag      = "text",
              parent   = element,
              posStart = textStart;
              posEnd   = textEnd;
              isInline = true,
            };
            self.stripLeading =
              (string.find(self.src, "^%s", nextTagStart-1) ~= nil);
          else
            self:setError(self.srcPos, L["HtmlErrUnexpectedText"]);
            break;
          end
        end
      end

      -- Process the next tag
      prevChild   = children[numChildren];
      self.srcPos = nextTagEnd+1;
      if (endMarker == "/") then
        if (voidMarker == "/") then
          self:setError(nextTagStart, L["HtmlErrMalformedTag"]);
          break;
        elseif (nextTag ~= elementTag) then
          self:setError(nextTagStart, L["HtmlErrWrongEndTag"]);
          break;
        elseif (nextAttrs ~= "") then
          self:setError(nextTagStart, L["HtmlErrAttrsInEndTag"]);
          break;
        else
          -- Set the flag that indicates the current element is now closed
          tagOpen = false;

          -- If the element isn't in-line...
          if (not element.isInline) then
            -- ...strip any leading spaces from the next text encountered
            self.stripLeading = true;
          end
        end
      elseif (voidMarker == "/") then
        if (next(self.validTags[nextTag].children) ~= nil) then
          self:setError(nextTagStart, L["HtmlErrInvalidVoidTag"]);
          break;
        elseif (validChildren[nextTag] == nil) then
          self:setError(nextTagStart, L["HtmlErrTagNotPermitted"]);
          break;
        else
          child = self:parse(element, nextTag, nextAttrs, true);
          if (child ~= nil) then
            numChildren           = numChildren+1;
            children[numChildren] = child;
            self.stripLeading     = true;
          else
            -- Any error will have already been set
            break;
          end
        end
      else
        -- Check the next tag is permitted as a child of the current element
        if (validChildren[nextTag] == nil) then
          self:setError(nextTagStart, L["HtmlErrTagNotPermitted"]);
          break;
        elseif (next(self.validTags[nextTag].children) == nil) then
          self:setError(nextTagStart, L["HtmlErrVoidTag"]);
          break;
        else
          child = self:parse(element, nextTag, nextAttrs, false);
          if (child ~= nil) then
            numChildren           = numChildren+1;
            children[numChildren] = child;
          else
            -- Any error will have already been set
            break;
          end
        end
      end
    end

    return (self.error.message == "" and element or nil);
  end;

  --
  -- Method to process the attributes for an element
  --
  processAttrs = function(self, element, attributes)
    -- Local Variables
    local _;
    local attrsLen = string.len(attributes);
    local attrsPos = 1;
    local nextAttrStart;
    local nextAttrEnd;
    local equals;
    local quote;
    local nextAttr;
    local nextAttrValue;

    -- Process all the attributes
    while (attrsPos < attrsLen) do
      -- Try to extract the name of the next attribute
      nextAttrStart, nextAttrEnd, nextAttr, equals, quote =
        string.find(attributes, "^%s*(%w+)%s*(=?)%s*(['\"]?)", attrsPos);
      if (nextAttrStart == nil) then
        -- Silently ignore all remaining attributes
        break;
      end

      -- Check if the next attribute is an empty attribute
      if ((equals == "") and (quote == "")) then
        nextAttrValue = nil;
        attrsPos      = nextAttrEnd+1;
      elseif (equals == "=") then
        -- Check if the next attribute's value is unquoted
        if (quote == "") then
          -- Extract the attribute's value
          _, nextAttrEnd, nextAttrValue =
            string.find(attributes, "^([^%s\"'=<>]*)%s*", nextAttrEnd+1);
          if (nextAttrEnd ~= nil) then
            attrsPos = nextAttrEnd+1;
          else
            -- Silently ignore all remaining attributes
            break;
          end
        elseif ((quote == "'") or (quote == '"')) then
          _, nextAttrEnd, nextAttrValue =
            string.find(attributes, "^([^"..quote.."]*)"..quote,
              nextAttrEnd+1);
          if (nextAttrEnd ~= nil) then
            attrsPos = nextAttrEnd+1;
          else
            -- Silently ignore all remaining attributes
            break;
          end
        else
          -- Silently ignore all remaining attributes
          break;
        end
      else
        -- Silently ignore all remaining attributes
        break;
      end

      -- Process the attribute, if it's valid
      if (nextAttr ~= nil) and (self.validAttributes[nextAttr] ~= nil) then
        (self.validAttributes[nextAttr])(self, element, nextAttrValue);
      end
    end

    return;
  end;

  --
  -- Method to render a tree of HTML elements. This function is recursive.
  --
  render = function(self, element, indent, attach)
    -- Local Variables
    local children = (element.children or self.emptyTable);
    local childIdx = 1;
    local childIndent = indent;
    local fontString;
    local tagInfo = self.validTags[element.tag];
    local text = "";

    -- Perform any pre-children work
    if (tagInfo.preChildren ~= nil) then
      text, childIndent = tagInfo.preChildren(self, element, indent);
    end

    -- Process all the element's children
    while (childIdx <= #children) do
      -- Check if the next child is in-line
      if (children[childIdx].isInline) then
        -- Process the in-line children
        while ((childIdx <= #children) and
               (children[childIdx].isInline)) do
          if (tagInfo.preChild ~= nil) then
            text = text..tagInfo.preChild(self, element, childIdx,
              children[childIdx]);
          end
          text = text..self:render(children[childIdx], childIndent, attach);
          if (tagInfo.postChild ~= nil) then
            text = text..tagInfo.postChild(self, element, childIdx,
              children[childIdx]);
          end
          childIdx = childIdx+1;
        end
      end

      -- Output any text from the in-line children
      if ((not element.isInline) and (text ~= "")) then
        self:fontStringsSetNext(text, childIndent, attach, element.styles);
        text   = "";
        attach = "BOTTOM";
      end

      -- Check if the next child is block
      if ((childIdx <= #children) and
          (not children[childIdx].isInline)) then
        -- Process the block children
        while ((childIdx <= #children) and
               (not children[childIdx].isInline)) do
          if (tagInfo.preChild ~= nil) then
            attach = tagInfo.preChild(self, element, childIdx,
              children[childIdx], indent, childIndent);
          end
          self:render(children[childIdx], childIndent, attach);
          childIdx = childIdx+1;
          attach = "BOTTOM";
          if (tagInfo.postChild ~= nil) then
            attach = tagInfo.postChild(self, element, childIdx,
              children[childIdx], indent, childIndent);
          end
        end
      end
    end

    -- Perform any post-children work
    if (tagInfo.postChildren ~= nil) then
      text = text..tagInfo.postChildren(self, element, indent);
    end

    return text;
  end;

  --
  -- Method to set an error that has occurred, including the position in the
  -- HTML source.
  --
  setError = function(self, position, message)
    -- Local Variables
    local errorPos;
    local errorLine = 1;
    local errorLinePos = 0;
    local newlinePos;

    -- Work out the line the error is on
    newLinePos = string.find(self.src, "\n");
    while ((newLinePos ~= nil) and (newLinePos < position)) do
      errorLine    = errorLine+1;
      errorLinePos = newLinePos;
      newLinePos   = string.find(self.src, "\n", newLinePos+1);
    end

    -- Save the error message
    self.error.message = message;
    self.error.line    = errorLine;
    self.error.column  =
      strlenutf8(string.sub(self.src, errorLinePos, position));

    return;
  end;

  -----------------------------------------------------------------------------
  --                 C  L  A  S  S     M  E  T  H  O  D  S
  -----------------------------------------------------------------------------

  --
  -- Method to get the frame used to display the HTML
  --
  GetFrame = function(self)
    return self.frame;
  end;

  --
  -- Method to create a new instance of the HTML frame
  --
  New = function(self)
    -- Finish initialising the class, if required
    if (self.validTags.span.preChildren == nil) then
      self.validTags.span.preChildren  = self.validTags.b.preChildren;
      self.validTags.span.postChild    = self.validTags.b.postChild;
      self.validTags.span.postChildren = self.validTags.b.postChildren;
    end

    -- Create the new object
    local object = setmetatable(
      {
        error = {},
        src             = "",
        srcPos          = 0,
        srLen           = 0,
        fontStrings     = {},
        usedFontStrings = 0,
        frame           = nil,
        emptyTable      = {},
      },
      self);

    -- Set the object's metatable to use the default class values
    self.__index = self;
    setmetatable(object, self);

    -- Create the visual components used to display the HTML
    if (self.frame == nil) then
      -- Create the frame used to display the HTML
      object.frame = CreateFrame("Frame", nil, UIParent, nil);
      object.frame:SetSize(10, 1);
      object.frame.object  = object;
      object.frame.SetHTML = object.frameSetHTML;
      object.frame.SetText = object.frameSetText;
      object.frame:SetScript("OnSizeChanged", object.frameOnSizeChanged);

      -- Create the font string used to measure text
      object.measure = object.frame:CreateFontString();
      object.measure:SetSize(256, 1);
      object.measure:SetFontObject("GameFontHighlight");
      object.measure:Hide();
    end

    return object.frame;
  end;

  --
  -- Method to set the HTML displayed by the frame
  --
  SetHTML = function(self, text)
    -- Local Variables
    local fontString;

    -- Initialise the HTML source
    self.src          = text;
    self.srcPos       = 1;
    self.srcLen       = string.len(self.src);
    self.stripLeading = false;

    -- Clear any error
    self.error.message = "";

    -- Free all the used font strings
    self:fontStringsFreeAll();

    -- Parse the HTML and then render it
    self.elements = self:parse(nil, "body", nil, false);
    if (self.elements ~= nil) then
      self:render(self.elements, 0, "BOTTOM");
    end

    -- Display any error message. if required
    if (self.error.message ~= "") then
      self:fontStringsFreeAll();
      fontString = self:fontStringsSetNext(format(L["HtmlErrFormat"],
        self.error.line, self.error.column, self.error.message),
        0, nil, self.specialStyles["error"]);
    end

    -- Show the used font strings
    for idx = 1, self.usedFontStrings do
      self.fontStrings[idx]:Show();
    end

    -- Recalculate the size of the HTML frame
    self.frameOnSizeChanged(self.frame);

    return;
  end;

  --
  -- Method to set the plain text displayed by the frame
  --
  SetText = function(self, text)
    -- Save the text
    self.src = text;

    -- Clear any error
    self.error.message = "";

    -- Free all the used font strings
    self:fontStringsFreeAll();

    -- Display the text
    local fontString = self:fontStringsSetNext(text, 0,
      "TOP", self.specialStyles["plainText"]);
    fontString:Show();

    -- Recalculate the size of the HTML frame
    self.frameOnSizeChanged(self.frame);

    return;
  end;
};

-------------------------------------------------------------------------------
--              L  O  C  A  L     D  E  F  I  N  I  T  I  O  N  S
-------------------------------------------------------------------------------

local strategyEditFrameCancelOnClick;
local strategyEditFrameOnHide;
local strategyEditFrameOnMoveResize;
local strategyEditFrameOnShow;
local strategyEditFramePreviewOnClick;
local strategyEditFrameSaveOnClick;

-------------------------------------------------------------------------------
--                 L  O  C  A  L     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when the 'Edit' button is clicked. It will display the 
-- Pet Team Strategy Edit frame.
-- 
local function editButtonOnClick(self, mouseButton)
  -- Local Variables
  local child;
  local teamInfo = NigglesPetTeamStrategy.teamInfo;
  local level;

  -- Check if the 'Strategy Edit' frame has already been created
  if (strategyEditFrame == nil) then
    -- Create the 'Strategy Edit' frame
    strategyEditFrame = CreateFrame("Frame", "NigglesPetTeamStrategyEdit", 
      NigglesPetTeamStrategy, "NigglesPetTeamStrategyEditTemplate");

    -- Set the frame's portrait and title
    SetPortraitToTexture(strategyEditFrame.PortaitContainer.portrait,
      "Interface\\Icons\\PetJournalPortrait");
    strategyEditFrame.TitleContainer.TitleText:SetText(
      L["PetTeamStrategyEdit"]);

    -- Set the buttons' level to be above the (non-clipped) scroll child */
    level = strategyEditFrame.strategy.editBox:GetFrameLevel()+1;
    strategyEditFrame.cancel:SetFrameLevel(level);
    strategyEditFrame.preview:SetFrameLevel(level);
    strategyEditFrame.save:SetFrameLevel(level);

    -- Set/hook scripts for the frame's children
    strategyEditFrame.cancel:SetScript("OnClick",
      strategyEditFrameCancelOnClick);
    strategyEditFrame.preview:SetScript("OnClick",
      strategyEditFramePreviewOnClick);
    strategyEditFrame.save:SetScript("OnClick",
      strategyEditFrameSaveOnClick);
    strategyEditFrame.dragButton:HookScript("OnMouseUp",
      strategyEditFrameOnMoveResize);

    -- Set scripts for the frame
    strategyEditFrame:SetScript("OnHide", strategyEditFrameOnHide);
    strategyEditFrame:SetScript("OnShow", strategyEditFrameOnShow);
  end

  -- Make sure the frame will appear above its parent
  strategyEditFrame:SetFrameStrata(NigglesPetTeamStrategy:GetFrameStrata());
  strategyEditFrame:SetFrameLevel(NigglesPetTeamStrategy:GetFrameLevel()+10);

  -- Show the 'Strategy Edit' frame
  strategyEditFrame.strategy:SetText(teamInfo.strategy);
  strategyEditFrame.strategy:SetIsHtml(teamInfo.isHtml);
  strategyEditFrame:Show();

  return;
end

--
-- Function called when the mouse enters the 'Edit' button.
-- 
local function editButtonOnEnter(self, mouseButton)
  -- Display the tooltip for the button
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
  GameTooltip:SetText(L["EditStrategy"], 1, 1, 1);
  GameTooltip:Show();

  return;
end

--
-- Function called when the 'Close' button in the Strategy panel is clicked.
-- It makes sure the Strategy Edit panel is closed 
--
local function petTeamStrategyCloseOnClick(self)
  -- Hide the Strategy Edit panel, if required
  if ((strategyEditFrame ~= nil) and (strategyEditFrame:IsShown())) then
    HideUIPanel(strategyEditFrame);
  end

  -- Hide the Strategy panel
  HideParentPanel(self);

  return;
end;

--
-- Function to process registered events for the Pet Team Strategy frame
--
local function petTeamStrategyOnEvent(self, event, ...)
  -- Process the event
  if (event == "PET_BATTLE_CLOSE") then
    -- Make sure the strategy edit frame isn't shown
    if ((self.layoutName == "battle") and 
        ((strategyEditFrame == nil)  or (not strategyEditFrame:IsShown()))) then
      -- Clear the team being displayed
      self.teamInfo = nil;

      -- Hide the frame
      self:Hide(); 
    end
  end

  return;
end

--
-- Function called when the Pet Team Strategy frame is moved or resized
--
local function petTeamStrategyOnMoveResize(self)
  -- Save the layout for the Pet Team Strategy frame
  L.layoutSave(self:GetParent().layoutName, self:GetParent(), true);

  return;
end

--
-- Function called when the Pet Team Strategy frame is shown or hidden
--
local function petTeamStrategyOnShowHide(self)
  -- Restore the frame's layout, if required
  if (self:IsShown()) then
    L.layoutRestore(self.layoutName, self, true);
  end

  -- Update the state of the micro button
  if (self:IsShown()) then
    NigglesPetBattleButton:SetPushed();
  else
    NigglesPetBattleButton:SetNormal();
  end

  -- Play the appropriate sound
  PlaySound(self:IsShown() and SOUNDKIT.IG_CHARACTER_INFO_OPEN or
    SOUNDKIT.IG_CHARACTER_INFO_CLOSE);

  return;
end

-- 
-- Function called when the 'Cancel' button is clicked in Strategy Edit frame
--
strategyEditFrameCancelOnClick = function(self, mouseButton)
  -- Hide the Strategy Edit frame
  strategyEditFrame:Hide();

  return
end

-- 
-- Function called when the Strategy Edit frame is hidden
--
strategyEditFrameOnHide = function(self)
  -- Local Variables
  local frame = NigglesPetTeamStrategy;

  -- Check if the pet battle has ended
  if (not C_PetBattles.IsInBattle()) then
    HideUIPanel(frame);
  else
    -- Update the strategy displayed in the Strategy frame
    L.petTeamStrategyShow(frame:GetParent(), frame.layoutName, frame.teamInfo);
  end

  return;
end

--
-- Function called when the Strategy Edit frame is moved by dragging the drag
-- button
--
strategyEditFrameOnMoveResize = function(self)
  -- Save the layout for the Pet Team Strategy frame
  L.layoutSave("strategyEdit", self:GetParent(), false);

  return;
end

strategyEditFrameOnShow = function(self)
  -- Restore the frame's layout, if required
  L.layoutRestore("strategyEdit", self, false);

  return;
end

-- 
-- Function called when the 'Preview' button is clicked in Strategy Edit frame
--
strategyEditFramePreviewOnClick = function(self, mouseButton)
  -- Local Variables
  local text = strategyEditFrame.strategy:GetText();

  -- Preview the strategy in the strategy frame
  if (strategyEditFrame.strategy:GetIsHtml()) then
    NigglesPetTeamStrategy.scrollFrame.html:SetHTML(text);
  else
    NigglesPetTeamStrategy.scrollFrame.html:SetHTML(
      "<pre>"..text:gsub("<", "&lt;").."</pre>");
  end

  return;
end

-- 
-- Function called when the 'Save' button is clicked in Strategy Edit frame
--
strategyEditFrameSaveOnClick = function(self, mouseButton)
  -- Save the pet team's strategy
  L.petTeamSaveStrategy(strategyEditFrame.strategy:GetText(),
    strategyEditFrame.strategy:GetIsHtml(), NigglesPetTeamStrategy.teamInfo);

  -- Hide the Strategy Edit frame
  strategyEditFrame:Hide();

  return;
end

--
-- Function called when a button is clicked in the Team dropdown list.
--
local function teamDropDownButtonOnClick(button, userData)
  -- Local Variables
  local frame = NigglesPetTeamStrategy;
  local teamInfo = button.teamInfo;
  local teamName;
  local teamSubName;

  -- Check the button has a pet team associated with it
  if (teamInfo ~= nil) then
    -- Save the pet team being displayed
    frame.teamInfo = teamInfo;

    -- Update the team drop down button
    teamName, teamSubName = L.petTeamGetNames(teamInfo);
    if (teamSubName ~= nil) then
      teamName = teamName..NORMAL_FONT_COLOR_CODE.." - "..teamInfo.name.."|r";
    end
    frame.team:SetText(teamName);

    -- Update the strategy displayed in the Strategy frame
    L.petTeamStrategyShow(frame:GetParent(), frame.layoutName, frame.teamInfo);
  end

  return;
end

--
-- Function called when a button is entered in the Team dropdown list.
--
local function teamDropDownButtonOnEnter(button, userData)
  -- Local Variables
  local teamName;
  local teamSubName;

  -- Display a tooltip for the button, if required
  if ((button:GetFontString():IsTruncated()) and 
      (button.teamInfo ~= nil)) then
    teamName, teamSubName = L.petTeamGetNames(button.teamInfo);
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:ClearLines();
    GameTooltip:SetMinimumWidth(150, true);
    GameTooltip:AddLine(teamName, HIGHLIGHT_FONT_COLOR.r,
      HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true);
    if (teamSubName ~= nil) then
      GameTooltip:AddLine(teamSubName, NORMAL_FONT_COLOR.r,
        NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
  end

  return;
end

--
-- Function to update the list in the Team dropdown
--
local function teamDropDownListUpdate(scrollFrame)
  -- Local Variables
  local filteredIdx;
  local filteredInfo;
  local offset;
  local owner;
  local numTeams = petTeamsFiltered[0];
  local selectedTeam = NigglesPetTeamStrategy.teamInfo;

  -- Initialise some variable
  offset = HybridScrollFrame_GetOffset(scrollFrame);

  -- Update the buttons in the scroll frame
  for buttonIdx, button in ipairs(scrollFrame.buttons) do
    -- Work out which filtered pet team the button is for
    filteredIx = buttonIdx+offset;
    if (filteredIx <= numTeams) then
      filteredInfo    = petTeamsFiltered[filteredIx];
      button.teamInfo = filteredInfo.teamInfo;
      if (button.teamInfo ~= nil) then
        button:SetText(filteredInfo.name);
        button:Enable();
        if (button.teamInfo == selectedTeam) then
          button:LockHighlight();
        else
          button:UnlockHighlight();
        end
      else
        button:SetText("");
        button:Disable();
        button:UnlockHighlight();
      end
      button:Show();
    else
      button:Hide();
    end
  end

  -- Update the scroll frame's range
  HybridScrollFrame_Update(scrollFrame,
    numTeams*scrollFrame.buttons[1]:GetHeight(), scrollFrame:GetHeight());

  -- Hide the game tooltip, if required
  owner = GameTooltip:GetOwner();
  if ((GameTooltip:IsVisible()) and
      (owner ~= nil) and
      (owner:GetParent() ~= nil) and
      (owner:GetParent():GetParent() == scrollFrame)) then
    GameTooltip_Hide();
  end

  return;
end

--
-- Function called when the text changes in the search box in the Team
-- drop down. It filters the teams listed in the scroll frame.
--
local function teamDropDownOnTextChanged(searchText, userData)
  -- Local variables
  local numFiltered = 0;
  local teamInfo;
  local petTeams = NglPtDB.petTeams;
  local opponentId = userData;
  local numOppMatches = 0;
  local teamName;
  local teamSubName;

  -- Add all teams that match the search text to the filtered list
  for teamIdx = 1, #petTeams do
    -- Assign some info to more convenient variables
    teamInfo = petTeams[teamIdx]
    teamName, teamSubName = L.petTeamGetNames(teamInfo);
    if (teamSubName ~= nil) then
      teamName = teamName..NORMAL_FONT_COLOR_CODE.." - "..teamInfo.name.."|r";
    end

    -- Ensure the team's name matches any search string
    if ((searchText == "") or
        (string.find(string.lower(teamName), searchText, 1, true) ~= nil)) then
      -- Add the team to the filtered list
      numFiltered = numFiltered+1;
      petTeamsFiltered[numFiltered].teamInfo = teamInfo;
      petTeamsFiltered[numFiltered].name     = teamName;
      if (teamInfo.opponentId == opponentId) then
        petTeamsFiltered[numFiltered].rank = 1;
        numOppMatches = numOppMatches+1;
      else
        petTeamsFiltered[numFiltered].rank = 3;
      end
    end
  end

  -- Add a divider if there are any teams for the opponent
  if ((numOppMatches > 0) and (numOppMatches < numFiltered)) then
    numFiltered = numFiltered+1;
    petTeamsFiltered[numFiltered].teamInfo = nil;
    petTeamsFiltered[numFiltered].rank     = 2;
  end

  -- Save the number of filtered pet teams
  petTeamsFiltered[0] = numFiltered;

  -- Set the rank of any elements after the last filtered one
  for idx = numFiltered+1, #petTeamsFiltered do
    petTeamsFiltered[idx].rank = 4;
  end

  -- Sort the filtered pet teams
  table.sort(petTeamsFiltered,
    function(first, second)
      if (first.rank ~= second.rank) then
        return first.rank < second.rank;
      else
        return first.name < second.name;
      end
    end);

  return 1;
end

--
-- Function called when the Team drop down button is clicked
--
local function teamDropDownOnClick(self, mouseButton)
  -- Show/hide the search drop down for the opponent
  if ((L.searchDropDown:GetParent() ~= self) or
      (not L.searchDropDown:IsShown())) then
    L.searchDropDown:SetParent(self);
    L.searchDropDown:SetCallbacks(teamDropDownListUpdate,
      teamDropDownButtonOnEnter, teamDropDownButtonOnClick,
      teamDropDownOnTextChanged,
      L.petTeamOpponentByPetSpecies(
        C_PetBattles.GetPetSpeciesID(2, 1),
        C_PetBattles.GetPetSpeciesID(2, 2),
        C_PetBattles.GetPetSpeciesID(2, 3)));
    L.searchDropDown:Show();
  else
    L.searchDropDown:Hide();
  end

  return;
end

-------------------------------------------------------------------------------
--                 A  D  D  O  N     F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function to get the Pet Team Strategy frame's parent
--
function L.petTeamStrategyGetParent()
  return ((NigglesPetTeamStrategy ~= nil) and
            NigglesPetTeamStrategy:GetParent() or nil);
end

--
-- Function to hide the Pet Team Strategy frame
--
function L.petTeamStrategyHide()
  -- Hide the Pet Team Strategy frame
  if (NigglesPetTeamStrategy ~= nil) then
    NigglesPetTeamStrategy:Hide();
  end

  return;
end

--
-- Function to check if the Pet Team Strategy frame is shown
--
function L.petTeamStrategyIsShown()
  return ((NigglesPetTeamStrategy ~= nil) and
          (NigglesPetTeamStrategy:IsShown()));
end

--
-- Function called when a pet team is deleted. It checks if the currently
-- displayed strategy is for the deleted team's strategy and resets the panel
-- if so.
--
function L.petTeamStrategyOnDelete(teamInfo)
  -- Check if the currently displayed strategy is from the deleted team
  if ((NigglesPetTeamStrategy ~= nil) and
      (NigglesPetTeamStrategy.teamInfo == teamInfo)) then
    -- Clear the strategy panel
    NigglesPetTeamStrategy.team:SetText("");
    NigglesPetTeamStrategy.scrollFrame.html:SetText("");
  end

  return;
end

--
-- Function to show the Pet Team Strategy panel
--
function L.petTeamStrategyShow(parent, layoutName, teamInfo)
  -- Local Variables
  local frame;
  local lastEdited = "";
  local teamName;
  local teamSubName;

  -- Hide the Strategy Edit frame, if required
  if (strategyEditFrame ~= nil) then
    strategyEditFrame:Hide();
  end

  -- Check if the Pet Team Strategy frame exists
  if (NigglesPetTeamStrategy == nil) then
    -- Create the Pet Team Strategy frame
    CreateFrame("Frame", "NigglesPetTeamStrategy", nil,
      "NigglesPetTeamStrategyTemplate");

    -- Add the frame to the list of frames closed by ESC
    tinsert(UISpecialFrames, "NigglesPetTeamStrategy");
  end
  frame = NigglesPetTeamStrategy;

  -- Set the frame's parent and layout
  frame:SetParent(parent);
  frame:SetFrameStrata(layoutName == "battle" and "MEDIUM" or "FULLSCREEN");
  frame:SetFrameLevel(4);
  frame.layoutName = layoutName;

  -- Show/Hide children, based on the layout
  frame.team:SetShown(layoutName ~= "preview");
  frame.edit:SetShown(layoutName ~= "preview");

  -- Check which mode the frame is being used in
  if (layoutName ~= "preview") then
    -- Try to find a suitable team to display
    if (frame.teamInfo ~= nil) then
      teamInfo = frame.teamInfo;
    else
      -- Search for a pet team with the current opponent and load out
      teamInfo = L.petTeamByCurrentBattle();
    end

    -- Work out the team name
    if (teamInfo ~= nil) then
      teamName, teamSubName = L.petTeamGetNames(teamInfo);
      if (teamSubName ~= nil) then
        teamName = teamName..NORMAL_FONT_COLOR_CODE.." - "..teamInfo.name.."|r";
      end
    else
      teamName = L["Select"];
    end

    -- Initialise the drop down button for selecting pet teams
    frame.team:SetText(teamName);
    frame.team:Show();
  end
  frame.teamInfo = teamInfo;

  -- Hide the search drop down, if it is being displayed for this frame
  if (L.searchDropDown:GetParent() == frame.team) then
    L.searchDropDown:Hide();
  end

  -- Initialise the HTML frame
  frame = NigglesPetTeamStrategy.scrollFrame;
  frame:SetVerticalScroll(0);
  if (teamInfo == nil) then
    frame.html:SetHTML("");
  else
    -- Create the last edited string, if available
    if ((layoutName ~= "preview") and (teamInfo.editTime > 0)) then
      lastEdited = format(L["LastEditedFormat"],
        date("%Y-%m-%d", teamInfo.editTime),
        L.buildGetString(teamInfo.editPatch));
    end
  
    -- Set the HTML displayed
    if (teamInfo.isHtml) then
      frame.html:SetHTML(teamInfo.strategy..lastEdited);
    else
      frame.html:SetHTML("<pre>"..teamInfo.strategy:gsub("<", "&lt;")..
        "</pre>"..lastEdited);
    end
  end

  -- Show the Pet Team Strategy
  NigglesPetTeamStrategy:Show();

  return;
end

--
-- Function to toggle the visibility of the Pet Team Strategy frame
--
function L.petTeamStrategyToggle(parent, layoutName, teamInfo)
  -- Show/hide the Pet Team Strategy frame
  if ((NigglesPetTeamStrategy == nil) or
      (not NigglesPetTeamStrategy:IsShown())) then
    L.petTeamStrategyShow(parent, layoutName, teamInfo)
  else
    NigglesPetTeamStrategy:Hide();
  end

  return;
end

-------------------------------------------------------------------------------
--                G  L  O  B  A  L    F  U  N  C  T  I  O  N  S
-------------------------------------------------------------------------------

--
-- Function called when the Niggles Pet Team Strategy frame is loaded.
--
function NigglesPetTeamStrategyOnLoad(self)
  -- Local Variables
  local child;
  local scrollFrame = NigglesPetTeamStrategyScrollFrame;

  -- Set the frame's portrait and title
  SetPortraitToTexture(self.PortraitContainer.portrait,
    "Interface\\Icons\\PetJournalPortrait");
  self.TitleContainer.TitleText:SetText(L["PetTeamStrategy"]);

  -- Initialise the 'Close' button
  self.CloseButton:SetScript("OnClick", petTeamStrategyCloseOnClick);

  -- Initialise the team drop down
  child = self.team;
  child:SetScript("OnClick", teamDropDownOnClick);
  child.label:SetText(L["Team"]);

  -- Initialise the edit button
  child = self.edit;
  child:SetScript("OnClick", editButtonOnClick);
  child:SetScript("OnEnter", editButtonOnEnter);
  child.icon:SetTexture("Interface\\BUTTONS\\UI-OptionsButton");
  child.icon:SetTexCoord(0, 1, 0, 1);

  -- Create the HTML object and frame
  child = NigglesPetTeamsHtmlClass:New();
  child:SetParent(scrollFrame);
  child:SetPoint("TOPLEFT", scrollFrame);
  child:SetPoint("RIGHT", scrollFrame);
  scrollFrame:SetScrollChild(child);
  scrollFrame.html = child;

  -- Initialise the resize button
  self.resizeButton:SetFrameLevel(self.scrollFrame.html:GetFrameLevel()+2);

  -- Set/hook script handlers
  self:SetScript("OnShow", petTeamStrategyOnShowHide);
  self:SetScript("OnHide", petTeamStrategyOnShowHide);
  self:SetScript("OnEvent", petTeamStrategyOnEvent);
  self:RegisterEvent("PET_BATTLE_CLOSE");
  self.dragButton:HookScript("OnMouseUp", petTeamStrategyOnMoveResize);
  self.resizeButton:HookScript("OnMouseUp", petTeamStrategyOnMoveResize);

  -- Show the background of the scrollbar for the scroll frame
  NigglesPetTeamStrategyScrollFrameScrollBarBG:Show();
  NigglesPetTeamStrategyScrollFrameScrollBarBG:SetVertexColor(0, 0, 0, 0.75);

  return;
end
