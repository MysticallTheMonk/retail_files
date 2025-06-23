-- list of frames to hide/show go here (not actually hidden, just alpha set to 0)
local frames = {MultiBarLeft}
local yoff = 10 -- threshold where cursor going below will show bars
local wait = 0.1 -- seconds to wait between checks for cursor position

local shown
local f = CreateFrame("Frame")
f.timer = 0
f:SetScript("OnUpdate",function(self,elapsed)
  f.timer = f.timer + elapsed
  if f.timer > wait then
    f.timer = 0
    local show = select(2,GetCursorPosition())<yoff
    if show~=shown then
      shown = show
      for _,frame in ipairs(frames) do
        frame:SetAlpha(show and 1 or 0)
      end
    end
  end
end)