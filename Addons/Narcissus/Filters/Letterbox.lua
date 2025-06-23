local FadeFrame = NarciAPI_FadeFrame;

--------------------------------------
-----------Letterbox Filter-----------
--------------------------------------
local function UpdateLetterboxSize()
    local frame = Narci_FullScreenMask;
	local scale = UIParent:GetEffectiveScale();
	local Width, Height = GetScreenWidth()*scale, GetScreenHeight()*scale;

    --Constant--
    local ratio = NarcissusDB.LetterboxRatio or 2;
	local croppedHeight = Width/ratio;	--2.35/2/1.8
	local speed = 50;
	------------
	
	local maskHeight = math.floor((Height - croppedHeight)/2 - 0.5);
	if maskHeight > 0 then
		frame.BottomMask:SetHeight(maskHeight);
		frame.TopMask:SetHeight(maskHeight);
	else
		frame.BottomMask:Hide();
		frame.TopMask:Hide();
		Narci_LetterboxButton:Disable();
		Narci_LetterboxButton:Hide();
		return false;
	end

	------------
	local offsetY = maskHeight + 1;
    local t = math.floor(10*(maskHeight / speed) + 0.5)/10;	--1.6
    
	frame.BottomMask.animIn.StartPosition:SetOffset(0, -offsetY);
	frame.BottomMask.animIn.Translation:SetOffset(0, offsetY);
	frame.BottomMask.animIn.Translation:SetDuration(t);
    frame.BottomMask.animOut.Translation:SetOffset(0, -offsetY);
    frame.BottomMask.animOut.Translation:SetDuration(0.5);
	frame.TopMask.animIn.StartPosition:SetOffset(0, offsetY);
	frame.TopMask.animIn.Translation:SetOffset(0, -offsetY);
	frame.TopMask.animIn.Translation:SetDuration(t);
    frame.TopMask.animOut.Translation:SetOffset(0, offsetY);
    frame.TopMask.animOut.Translation:SetDuration(0.5);
    ------------
    if ratio == 2.35 then
        Narci_LetterboxButton.Arrow:SetTexCoord(0, 0.25, 0.5, 1);
    else
        Narci_LetterboxButton.Arrow:SetTexCoord(0.25, 0.5, 0.5, 1);
	end
	
	return true;
end

function Narci_LetterboxButton_OnClick(self)
	local value
    if NarcissusDB.LetterboxRatio == 2.35 then
		value = 2;
    else
		value = 2.35;
    end
	NarcissusDB.LetterboxRatio = value;
	UpdateLetterboxSize();

	local settingsButton = NarciAPI.GetSettingsButtonByDBKey("LetterboxRatio");
	if settingsButton then
		settingsButton:SetValue(value);
	end
end


do
	local _, addon = ...

	function addon.SettingFunctions.UpdateLetterboxSize(ratio, db)
		UpdateLetterboxSize();
    end
end