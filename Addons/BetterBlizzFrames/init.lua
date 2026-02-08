-- :)

BetterBlizzFramesDB = BetterBlizzFramesDB or {}
BBF = BBF or {}
BBA = BBA or {}

BBF.ICON_NAME = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames"

-- Initialize locale table (will be populated by locale files)
BBF.L = BBF.L or {}

SLASH_BBFRL1 = "/RL"
SlashCmdList["BBFRL"] = function()
    ReloadUI()
end

function BBF.Print(msg, noColon)
	if msg then
		local suffix = noColon and " " or ": "
		print(BBF.ICON_NAME .. suffix .. msg)
	end
end

local gameVersion = select(1, GetBuildInfo())
BBF.isMidnight = gameVersion:match("^12")
BBF.isRetail = gameVersion:match("^11")
BBF.isMoP = gameVersion:match("^5%.")
BBF.isTBC = gameVersion:match("^2%.")
BBF.isEra = gameVersion:match("^1%.")

local function CreateOverlayFrame(frame)
    frame.bbfOverlayFrame = CreateFrame("Frame", nil, frame)
    frame.bbfOverlayFrame:SetFrameStrata("DIALOG")
    frame.bbfOverlayFrame:SetSize(frame:GetSize())
    frame.bbfOverlayFrame:SetAllPoints(frame)

    hooksecurefunc(frame, "SetFrameStrata", function()
        frame.bbfOverlayFrame:SetFrameStrata("DIALOG")
    end)
end

CreateOverlayFrame(PlayerFrame)
CreateOverlayFrame(TargetFrame)
if FocusFrame then
    CreateOverlayFrame(FocusFrame)
end