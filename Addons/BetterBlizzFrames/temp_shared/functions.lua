-- Taint/combat lockdown concerns, use own to avoid Show call especially
local FrameFadeManager = CreateFrame("Frame");
local fadeFrames = {};

function BBF.UIFrameFadeContains(frame)
	for i, fadeFrame in ipairs(fadeFrames) do
		if fadeFrame == frame then
			return true;
		end
	end
	return false;
end

function BBF.UIFrameFade_OnUpdate(self, elapsed)
	local index = 1;

	while fadeFrames[index] do
		local frame = fadeFrames[index];
		local fadeInfo = frame and frame.BBF_fadeInfo;

		if not frame or not fadeInfo then
			if frame then
				frame.BBF_fadeInfo = nil;
			end
			tDeleteItem(fadeFrames, frame);
		else
			fadeInfo.fadeTimer = (fadeInfo.fadeTimer or 0) + elapsed;

			if fadeInfo.fadeTimer < fadeInfo.timeToFade then
				if fadeInfo.mode == "IN" then
					frame:SetAlpha((fadeInfo.fadeTimer / fadeInfo.timeToFade) * (fadeInfo.endAlpha - fadeInfo.startAlpha) + fadeInfo.startAlpha);
				else -- "OUT"
					frame:SetAlpha(((fadeInfo.timeToFade - fadeInfo.fadeTimer) / fadeInfo.timeToFade) * (fadeInfo.startAlpha - fadeInfo.endAlpha) + fadeInfo.endAlpha);
				end
			else
				frame:SetAlpha(fadeInfo.endAlpha);

				if fadeInfo.fadeHoldTime and fadeInfo.fadeHoldTime > 0 then
					fadeInfo.fadeHoldTime = fadeInfo.fadeHoldTime - elapsed;
				else
					tDeleteItem(fadeFrames, frame);

					local finishedFunc = fadeInfo.finishedFunc;
					if finishedFunc then
						fadeInfo.finishedFunc = nil;
						finishedFunc(fadeInfo.finishedArg1, fadeInfo.finishedArg2, fadeInfo.finishedArg3, fadeInfo.finishedArg4);
					end

					frame.BBF_fadeInfo = nil;
				end
			end

			index = index + 1;
		end
	end

	if #fadeFrames == 0 then
		self:SetScript("OnUpdate", nil);
	end
end

function BBF.UIFrameFade(frame, fadeInfo)
	if not frame then
		return;
	end

	fadeInfo = fadeInfo or {};

	if not fadeInfo.mode then
		fadeInfo.mode = "IN";
	end

	if fadeInfo.mode == "IN" then
		if fadeInfo.startAlpha == nil then fadeInfo.startAlpha = 0 end
		if fadeInfo.endAlpha == nil then fadeInfo.endAlpha = 1 end
	elseif fadeInfo.mode == "OUT" then
		if fadeInfo.startAlpha == nil then fadeInfo.startAlpha = 1 end
		if fadeInfo.endAlpha == nil then fadeInfo.endAlpha = 0 end
	end

	frame.BBF_fadeInfo = fadeInfo;

	frame:SetAlpha(fadeInfo.startAlpha);
	--frame:Show();

	if not BBF.UIFrameFadeContains(frame) then
		tinsert(fadeFrames, frame);
	end

	FrameFadeManager:SetScript("OnUpdate", BBF.UIFrameFade_OnUpdate);
end

function BBF.UIFrameFadeIn(frame, timeToFade, startAlpha, endAlpha)
	BBF.UIFrameFade(frame, {
		mode = "IN",
		timeToFade = timeToFade,
		startAlpha = startAlpha,
		endAlpha = endAlpha,
	});
end

function BBF.UIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	BBF.UIFrameFade(frame, {
		mode = "OUT",
		timeToFade = timeToFade,
		startAlpha = startAlpha,
		endAlpha = endAlpha,
	});
end

function BBF.UIFrameFadeRemoveFrame(frame)
	tDeleteItem(fadeFrames, frame);
	if frame then
		frame.BBF_fadeInfo = nil;
	end
end

function BBF.UIFrameIsFading(frame)
	return frame and BBF.UIFrameFadeContains(frame) or false;
end