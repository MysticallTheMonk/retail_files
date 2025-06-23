local _, ArenaAnalytics = ... -- Addon Namespace
local Search = ArenaAnalytics.Search;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local Helpers = ArenaAnalytics.Helpers;

-------------------------------------------------------------------------
-- Search Parsing Logic

function Search:CreateSymbolToken(symbol, isSeparator)
    assert(symbol)

    local newSymbolToken = {}
    newSymbolToken.transient = true;
    newSymbolToken.explicitType = "symbol";
    newSymbolToken.raw = symbol;
    newSymbolToken.isSeparator = isSeparator;
    
    return newSymbolToken;
end

local function ParseTokenString(raw)
    -- Remove all excluded characters using gsub  + " ( ) !
    local raw = raw and raw:gsub("[+\"()!]", "") or "";
    local value = "";
    
    -- Remove '-', if it's neither the first symbol nor directly following a colon.
    local lastChar = nil;
    for i=1, #raw do
        local char = raw:sub(i,i);

        if(char == '-') then
            if(lastChar and lastChar ~= ':') then
                value = value .. char;
            end
        else
            value = value .. char;
        end

        lastChar = char;
    end
    
    return Helpers:ToSafeLower(value);
end

function Search:CreateToken(raw, isExact)
    assert(raw);
    
    local newToken = {}
    local value = ParseTokenString(raw);
    local explicitType, tokenValue, noSpace = Search:GetTokenPrefixKey(value);

    if(raw == "") then
        explicitType = "empty";
    end
    
    newToken.explicitType = explicitType;
    newToken.value = tokenValue;
    newToken.exact = isExact or nil;
    newToken.noSpace = noSpace;
    newToken.raw = raw;

    if(newToken.explicitType == "alts") then
        -- Alt searches without a slash is just a simple name type
        if(not newToken.value:find('/', 1, true)) then
            newToken.explicitType = "name";
        end
    elseif(newToken.value:find('/', 1, true) ~= nil) then -- TODO: Add support for / as a generic 'or' for values?
        newToken.explicitType = "alts";
    elseif(newToken.explicitType ~= "name") then
        -- Check for keywords
        local typeKey, valueKey, noSpace = Search:FindSearchValueDataForToken(newToken);
        if(typeKey and valueKey) then
            newToken.noSpace = noSpace;
            newToken.explicitType = typeKey;
            newToken.value = valueKey;
        elseif(not newToken.explicitType and not newToken.value:find(' ', 1, true)) then
            -- Tokens without spaces fall back to name type
            newToken.explicitType = "name";
            newToken.noSpace = true;

            if(Search.isCommitting) then
                ArenaAnalytics:Log("Search: Forced fallback to name search type.");
            end
        end
    end

    -- Update transient state
    if(newToken.explicitType == "logical") then
        if(newToken.value == "not") then
            newToken.transient = true;
        end
    elseif(newToken.explicitType == "team") then
        newToken.transient = true;
    elseif(newToken.explicitType == "symbol") then
        newToken.transient = true;
    end
    
    -- Valid if it has a keyword or no spaces
    newToken.isValid = newToken.value and not newToken.noSpace or type(newToken.value) == "number" or not newToken.value:find(' ', 1, true);

    -- Sanitize value
    if(newToken.value) then
        newToken.value = Helpers:ToSafeNumber(newToken.value) or Helpers:ToSafeLower(newToken.value);
    end

    --ArenaAnalytics:Log("Created Token: ", newToken.explicitType, newToken.value, newToken.raw)
    return newToken;
end

function Search:SanitizeInput(input)
    if(not input or input == "") then
        return "";
    end

    local output = input:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "");
    output = output:gsub("%s%s+", ' ');

    if(input == " ") then
        return "";
    end

    return output;
end

local function SanitizeCursorPosition(input, oldCursorPosition)
    assert(input);

    if(oldCursorPosition == 0) then
        return 0;
    end

    if(oldCursorPosition == #input) then
        return nil;
    end

    local stringBeforeCursor = input:sub(1, oldCursorPosition);
    local sanitizedString = Search:SanitizeInput(stringBeforeCursor);

    return #sanitizedString;
end

local function CalculateScopeCursorIndex(currentDisplayLength, startIndex, endIndex, cursorIndex)
    if(cursorIndex >= startIndex and cursorIndex <= endIndex) then
        return currentDisplayLength + 13 + (cursorIndex - startIndex);
    end
end

local function IsPlayerSegmentSeparatorChar(char)
    return char == ',' or char == '.' or char == ';';
end

-- Process the input string for symbols: Double quotation marks, commas, parenthesis, spaces
function Search:ProcessInput(input, oldCursorPosition)
    local tokenizedSegments = {}

    -- Current
    local currentSegment = Search:GetEmptySegment();
    local currentToken = nil;
    local currentWord = "";
    local currentRaw = "";

    -- Whether a space has yet to be handled. Processed in CommitWord()
    local unhandledSpaces = 0;

    -- Caret Position Data
    local sanitizedCaretIndex = SanitizeCursorPosition(input, oldCursorPosition);
    local committedTokenRawLength = 0;
    local hasHandledCaret = nil;

    local isTokenNegated = false;

    local index = 1;

    local newCursorPosition = 0;
    local sanitizedInput = Search:SanitizeInput(input);

    if(sanitizedInput == "") then
        return tokenizedSegments;
    end

    ----------------------------------------
    -- internal functions

    local function HandleCaretPosition(token)
        assert(token and token.raw);
        
        if(not sanitizedCaretIndex) then
            return;
        end
        
        if(hasHandledCaret) then
            return;
        end

        -- Must be between the already total committed raw length and index
        if(sanitizedCaretIndex > index or sanitizedCaretIndex < committedTokenRawLength) then
            return;
        end

        local relativeCaretOffset = sanitizedCaretIndex - committedTokenRawLength;
        if(relativeCaretOffset <= #token.raw) then
            token.caret = relativeCaretOffset;
            hasHandledCaret = true;
        end
    end

    local function CommitUnhandledSpace()
        if(unhandledSpaces > 0) then
            -- Add space symbol token
            unhandledSpaces = max(0, unhandledSpaces - 1);
            local newSpaceToken = Search:CreateSymbolToken(' ');
            
            HandleCaretPosition(newSpaceToken);

            tinsert(currentSegment.tokens, newSpaceToken);
            committedTokenRawLength = committedTokenRawLength + #newSpaceToken.raw;
        end
    end

    local function CommitCurrentSegment()
        if(currentSegment and #currentSegment.tokens > 0) then
            tinsert(tokenizedSegments, currentSegment);
        end

        currentSegment = Search:GetEmptySegment();
    end

    local function CommitCurrentToken()
        if(currentToken and currentToken.raw and #currentToken.raw > 0) then
            currentToken.negated = isTokenNegated or nil;
            
            HandleCaretPosition(currentToken);
            
            -- Commit a real search token
            tinsert(currentSegment.tokens, currentToken);
            committedTokenRawLength = committedTokenRawLength + #currentToken.raw;
            
            CommitUnhandledSpace();
        end

        currentToken = nil;
        isTokenNegated = false;
    end

    local function CommitCurrentWord()
        currentWord = currentWord or "";

        if(currentToken and currentWord ~= "") then
            local combinedValue = currentToken.raw .. " " .. currentWord;
            local newCombinedToken = Search:CreateToken(combinedValue);
            
            if(newCombinedToken and newCombinedToken.isValid) then
                currentToken = newCombinedToken;
                unhandledSpaces = max(0, unhandledSpaces - 1);
                
                currentWord = ""; -- Already added to the token
            else
                CommitCurrentToken();
            end
        end

        -- Might have been added to token by now
        if(not currentToken and currentWord ~= "") then
            currentToken = Search:CreateToken(currentWord, false);

            -- Commit immediately if no space is allowed
            if(currentToken and currentToken.noSpace) then
                -- Commit new token immediately
                CommitCurrentToken();
            end
        end

        -- Reset current word
        currentWord = "";
    end

    ----------------------------------------
    -- Parse the sanitizedInput characters
    local lastChar = nil;
    while index <= #sanitizedInput do
        local char = sanitizedInput:sub(index, index);
        
        if char == '-'  and currentWord ~= "" and lastChar ~= ':' then -- Separator for name-realm
            currentWord = currentWord .. char;
        elseif char == '!' or char == '-' then -- Negated token
            if((currentWord == "" or lastChar == ':') and lastChar ~= '!' and lastChar ~= '-') then
                CommitCurrentToken();
                isTokenNegated = true;
            end
            currentWord = currentWord .. char;

        elseif char == ' ' then
            if(lastChar) then
                unhandledSpaces = unhandledSpaces + 1;

                if(IsPlayerSegmentSeparatorChar(lastChar)) then
                    CommitUnhandledSpace();
                end

                CommitCurrentWord();
            end

        elseif IsPlayerSegmentSeparatorChar(char) then -- comma, period or semicolon
            CommitCurrentWord();
            CommitCurrentToken();
            
            if(#currentSegment.tokens > 0) then
                -- Add the separator at the end of the segment
                currentToken = Search:CreateSymbolToken(char, true);
                CommitCurrentToken();
            end

            CommitCurrentSegment();

        elseif char == ":" then
            CommitCurrentToken()
            currentWord = currentWord .. char;

        elseif char == '"' then
            local endIndex, scope, isNegated = Search:ProcessScope(sanitizedInput, index, '"');
            if endIndex then
                if(lastChar ~= ':' and lastChar ~= '!' and lastChar ~= '-') then
                    CommitCurrentWord();
                end
                CommitCurrentToken();

                currentToken = Search:CreateToken(currentWord..scope, true);
                isTokenNegated = isNegated;
                currentWord = "";
                index = endIndex;

                -- Commit the new token immediately
                CommitCurrentToken();

            else -- Invalid scope
                currentWord = currentWord .. char;
            end

        elseif char == "(" then
            local endIndex, scope, isNegated = Search:ProcessScope(sanitizedInput, index, ')');
            if endIndex then
                if(lastChar ~= ':' and lastChar ~= '!' and lastChar ~= '-') then
                    CommitCurrentWord();
                end
                CommitCurrentToken();

                currentToken = Search:CreateToken(currentWord..scope, false);
                isTokenNegated = isNegated;
                currentWord = "";
                index = endIndex;

                -- Commit the new token immediately
                CommitCurrentToken();
            else -- Invalid scope
                currentWord = currentWord .. char;
            end

        elseif char == ")" then
            currentWord = currentWord .. char;

        elseif char == '/' then
            currentWord = currentWord .. char;

        else
            currentWord = currentWord .. char;
        end

        -- Prepare for next char
        lastChar = char;
        index = index + 1
    end
    
    ----------------------------------------
    -- Final commit for any remaining data

    CommitCurrentWord()
    CommitCurrentToken()
    CommitCurrentSegment()

    return tokenizedSegments;
end

function Search:ProcessScope(input, startIndex, endSymbol)    
    local endIndex, isNegated = nil, false;

    -- Add the scope opening char
    local scope = "";
    
    -- Loop fron next index
    local index = startIndex;
    while index <= #input do
        local char = input:sub(index, index);

        -- Add any char to the scope, except player segment separators
        if(not IsPlayerSegmentSeparatorChar(char)) then
            scope = scope .. char;
        end

        -- Check if the scope is over
        if char == endSymbol and index > startIndex then
            endIndex = index;
            break;
        elseif(IsPlayerSegmentSeparatorChar(char)) then
            break;
        end

        if(char == '!' or char == '-') and #scope <= 1 then
            isNegated = true;
        end

        index = index + 1;
    end

    return endIndex, scope, isNegated;
end