local _, ArenaAnalytics = ... -- Addon Namespace
local Search = ArenaAnalytics.Search;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;

-------------------------------------------------------------------------
-- Search Colors

function Search:ColorizeInvalid(text)
    return text and "|cffFF0000" .. text .. "|r" or "";
end

function Search:ColorizeSymbol(text)
    return text and "|cff00ccff" .. text .. "|r" or "";
end

-- TODO: Add token specific colors
function Search:ColorizeToken(token)
    if(token == nil) then
        return "";
    end

    local type = token.explicitType;
    
    return token.raw and "|cffFFFFFF" .. token.raw .. "|r" or "";
end

-------------------------------------------------------------------------
-- Search Display

function Search:SetCurrentDisplay()
    assert(Search.current);
    local currentSegments = Search.current.segments or {};

    local newDisplay = "";
    local newCaretPosition = nil;

    -- Combine new display string from tokens
    for segmentIndex,segment in ipairs(currentSegments) do
        for tokenIndex,token in ipairs(segment.tokens) do
            local tokenDisplay, relativeCaretOffset = Search:GetTokenDisplay(token);

            if(relativeCaretOffset) then
                newCaretPosition = #newDisplay + relativeCaretOffset;
            end

            newDisplay = newDisplay .. tokenDisplay;
        end
    end

    Search.current.display = newDisplay;

    -- Update the searchBox
    local searchBox = ArenaAnalyticsScrollFrame.searchBox;
    if(searchBox) then
        searchBox:SetText(newDisplay);
        searchBox:SetCursorPosition(newCaretPosition or #newDisplay);
    else
        ArenaAnalytics:LogWarning("Mising search box");
    end
end

function Search:GetTokenDisplay(token)
    assert(token and token.raw);
    
    local display = "";
    local caretOffset = (token.caret == 0) and 0 or nil;

    local isExactScope = false;
    local isPartialScope = false;
    
    local lastChar = '';
    for i=1, #token.raw do
        local char = token.raw:sub(i,i);
        assert(char);

        if(char == '!') then
            if((lastChar == '' or lastChar == ':') and lastChar ~= '!' and lastChar ~= '-') then
                display = display .. Search:ColorizeSymbol(char);
            else
                display = display .. Search:ColorizeInvalid(char);
            end

        elseif(char == '-') then
            if(lastChar == '' or lastChar == ':') then
                display = display .. Search:ColorizeSymbol(char);
            elseif(lastChar == '!' or lastChar == '-') then
                display = display .. Search:ColorizeInvalid(char);
            else
                display = display .. char;
            end

        elseif(char == '"') then
            if(isExactScope) then
                display = display .. Search:ColorizeSymbol(char);
                isExactScope = false;
            elseif(Search:ProcessScope(token.raw, i, '"')) then
                isExactScope = true;
                display = display .. Search:ColorizeSymbol(char);
            else
                display = display .. Search:ColorizeInvalid(char);
            end

        elseif(char == '(') then
            if(Search:ProcessScope(token.raw, i, ')')) then
                isPartialScope = true;
                display = display .. Search:ColorizeSymbol(char);
            else
                display = display .. Search:ColorizeInvalid(char);
            end

        elseif(char == ')') then
            if(isPartialScope) then
                isPartialScope = false;
                display = display .. Search:ColorizeSymbol(char);
            else
                display = display .. Search:ColorizeInvalid(char);
            end

        elseif(char == '/') then
            display = display .. Search:ColorizeSymbol(char);

        elseif(char == '+') then
            display = display .. Search:ColorizeInvalid(char);

        else
            display = display .. char;
        end

        if(i and i == token.caret) then
            caretOffset = #display;
        end

        lastChar = char;
    end

    return display, caretOffset;
end
