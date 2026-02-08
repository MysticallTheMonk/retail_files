-- File: LibPleebug-1_Diagram.lua
-- Purpose: Timeline renderer for trace data (lanes = visible tree rows).


local LibStub = _G.LibStub
local MemDebug = LibStub and LibStub("LibPleebug-1", true)
if not MemDebug then return end

local Diagram = MemDebug.Diagram or {}
MemDebug.Diagram = Diagram


-- Per-holder texture pools so multiple diagrams don't stomp each other.
local function _getPool(parent)
  if not parent then return nil end
  local pool = parent.__pleebugDiagramPool
  if not pool then
    pool = {}
    parent.__pleebugDiagramPool = pool
  end
  return pool
end

local function _acquireTexture(parent)
  local pool = _getPool(parent)
  if not pool then return nil end

  parent.__pleebugDiagramPoolIndex = (parent.__pleebugDiagramPoolIndex or 0) + 1
  local idx = parent.__pleebugDiagramPoolIndex

  local t = pool[idx]
  if not t then
    t = parent:CreateTexture(nil, "ARTWORK")
    pool[idx] = t
  end

  t:ClearAllPoints()
  t:SetParent(parent)
  t:Show()
  return t
end

local function _releaseExtra(parent)
  local pool = _getPool(parent)
  if not pool then return end

  local used = parent.__pleebugDiagramPoolIndex or 0
  for i = used + 1, #pool do
    local t = pool[i]
    if t then t:Hide() end
  end
end


local function _getThemeColors()
  -- Library-safe theme:
  -- If the host provides MemDebug:GetThemeColors(), use it.
  -- Otherwise use sane defaults.
  if MemDebug and type(MemDebug.GetThemeColors) == "function" then
    local accent, line = MemDebug:GetThemeColors()
    if type(accent) == "table" and type(line) == "table" then
      return accent, line
    end
  end

  -- Defaults (white accent, light border)
  return { 1, 1, 1, 1 }, { 1, 1, 1, 1 }
end


local function _parentPath(path)
  if not path then return nil end
  return path:match("^(.*)%.")
end

-- holder: Frame
-- lanes: array of node.path strings (visible order)
-- events: array of { t = number, key = string }
-- now: number (current time)
-- windowSec: number
-- style: "tick" or "dot"
function Diagram:Render(holder, lanes, events, now, windowSec, style, startTime)

  if not holder or not holder.GetWidth or not holder.GetHeight then
    return
  end

  holder.__pleebugDiagramPoolIndex = 0

  local w = math.floor((holder:GetWidth() or 0) + 0.5)

  local h = math.floor((holder:GetHeight() or 0) + 0.5)
  if w < 20 or h < 20 then
    _releaseExtra(holder)
    return
  end


  windowSec = tonumber(windowSec) or 10
  if windowSec < 0.1 then windowSec = 0.1 end

  local series = lanes or {}
  local seriesCount = #series

  -- Fallback: if no lanes were provided (e.g. flat tree empty),
  -- derive visible series from the events themselves.
  if (not series or seriesCount < 1) and type(events) == "table" then
    series = {}
    local seen = {}
    for i = 1, #events do
      local e = events[i]
      local k = e and e.key
      if k and not seen[k] then
        seen[k] = true
        series[#series + 1] = k
      end
    end
    seriesCount = #series
  end

  if seriesCount < 1 then
    _releaseExtra(holder)
    return
  end



  -- Cap to avoid insane draw in dev mode (still "visible things", but keep it sane)
  local maxSeries = 20
  if seriesCount > maxSeries then
    seriesCount = maxSeries
  end

  local accent, line = _getThemeColors()
  local ar, ag, ab, aa = accent[1], accent[2], accent[3], accent[4] or 1
  local lr, lg, lb = line[1], line[2], line[3]

  local padL, padR = 8, 8
  local padT, padB = 8, 12
  local plotW = math.max(10, w - padL - padR)
  local plotH = math.max(10, h - padT - padB)

  -- Baseline (0)
  do
    local base = _acquireTexture(holder)
    base:SetColorTexture(lr, lg, lb, 0.25)
    base:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -(padT + plotH))
    base:SetSize(plotW, 1)
  end

  if not events or #events == 0 or not now then
    _releaseExtra(holder)
    return
  end



  local t0 = now - windowSec

  local fillMode = false
  startTime = tonumber(startTime)
  if startTime and startTime > 0 and now and (now - startTime) < windowSec then
    t0 = startTime
    fillMode = true
  end


  -- Index visible series
  local idx = {}
  for i = 1, seriesCount do
    idx[series[i]] = i
  end

  -- If events arrive with keys that don't exist in the lane list,
  -- put them in a catch-all bucket so the graph still renders.
  local otherKey = "(other)"
  local otherIndex = nil

  -- Bin values per pixel per series (dense arrays)
  -- PERF: dense bins remove pairs()+sort() and are usually much faster for rendering.
  local bins = holder.__pleebugBins
  local lastW = holder.__pleebugBinsW or 0

  if (not bins) or (bins.__sc ~= seriesCount) or (lastW ~= plotW) then
    bins = { __sc = seriesCount }
    for i = 1, seriesCount do
      local b = {}
      for x = 1, plotW do
        b[x] = 0
      end
      bins[i] = b
    end
    holder.__pleebugBins = bins
    holder.__pleebugBinsW = plotW
  else
    for i = 1, seriesCount do
      local b = bins[i]
      for x = 1, plotW do
        b[x] = 0
      end
    end
  end


  local isCpu = (style == "cpu")

  local function bump(si, xPix, value)
    local b = bins and bins[si]
    if not b then return end

    local cur = b[xPix]
    if cur == nil then
      cur = 0
    end

    if value then
      -- IMPORTANT:
      -- CPU mode should represent "peak ms in this time slice" (MAX), not SUM.
      -- Otherwise multiple calls that land in the same pixel exaggerate peaks and
      -- won't match per-function max stats in the list view.
      if isCpu then
        if value > cur then
          b[xPix] = value
        else
          b[xPix] = cur
        end
      else
        b[xPix] = cur + value
      end
    else
      b[xPix] = cur + 1
    end
  end



  for i = 1, #events do
    local e = events[i]
    local t = e and e.t
    local key = e and e.key
    if t and key and t >= t0 then
      local frac = (t - t0) / windowSec
      if frac >= 0 and frac <= 1 then
        local xPix = math.floor(frac * (plotW - 1) + 0.5) + 1
        if xPix < 1 then xPix = 1 end
        if xPix > plotW then xPix = plotW end

        local v = e.v
        local useValue = (type(v) == "number" and v > 0)

        if isCpu then
          -- CPU mode MUST NOT propagate to parents.
          -- Doing so duplicates ms into category rows and exaggerates peaks.
          local si = idx[key]
          if not si then
            -- Leaf key missing from lanes: bucket into "(other)"
            if not otherIndex then
              if seriesCount < maxSeries then
                seriesCount = seriesCount + 1
                otherIndex = seriesCount
                idx[otherKey] = otherIndex

                -- Ensure the bin exists and is initialized to plotW zeros
                local bb = {}
                for x = 1, plotW do
                  bb[x] = 0
                end
                bins[otherIndex] = bb
              else
                otherIndex = 1 -- hard fallback
              end
            end
            si = otherIndex
          end
          if si then bump(si, xPix, useValue and v or nil) end
        else
          -- Count leaf and parents so categories also pulse (non-CPU timelines)
          local p = key
          while p do
            local si = idx[p]
            if not si and p == key then
              -- Leaf key missing from lanes: bucket into "(other)"
              if not otherIndex then
                if seriesCount < maxSeries then
                  seriesCount = seriesCount + 1
                  otherIndex = seriesCount
                  idx[otherKey] = otherIndex

                  -- Ensure the bin exists and is initialized to plotW zeros
                  local bb = {}
                  for x = 1, plotW do
                    bb[x] = 0
                  end
                  bins[otherIndex] = bb
                else
                  otherIndex = 1 -- hard fallback
                end
              end
              si = otherIndex
            end
            if si then bump(si, xPix, useValue and v or nil) end
            p = _parentPath(p)
          end
        end



      end
    end
  end

  -- Find global max per-slice count
  local maxCount = 0
  for si = 1, seriesCount do
    local b = bins[si]
    for _, v in pairs(b) do
      if v > maxCount then maxCount = v end
    end
  end

  if maxCount <= 0 then
    _releaseExtra(holder)
    return
  end

  local maxY
  if style == "cpu" then
    -- CPU mode: use a tight scale around the actual ms values
    maxY = maxCount * 1.1
    if maxY < 0.05 then
      maxY = 0.05
    end
  else
    -- Count/tick mode: tight scale so small values keep good resolution
    maxY = maxCount * 1.1
    if maxY < 1 then
      maxY = 1
    end
  end


  local baselineY = padT + plotH


  local function hFor(count)
    local v = count / maxY
    if v < 0 then v = 0 end
    if v > 1 then v = 1 end
    return math.floor(v * plotH + 0.5)
  end

  -- Axis labels + Y grid + Title + X ticks
  if not holder._yMax then
    holder._yMax   = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder._y0     = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder._xLeft  = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder._xRight = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder._title  = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

    holder._xTicks = {}
    holder._xTickLabels = {}
  end


  local function fmtY(v)
    if style == "cpu" then
      if v >= 10 then
        return string.format("%.1f", v)
      elseif v >= 1 then
        return string.format("%.2f", v)
      else
        return string.format("%.3f", v)
      end
    end
    return tostring(math.floor((tonumber(v) or 0) + 0.5))
  end

  holder._yMax:ClearAllPoints()
  holder._yMax:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -padT)
  holder._yMax:SetText(fmtY(maxY))

  holder._y0:ClearAllPoints()
  holder._y0:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -(baselineY - 10))
  holder._y0:SetText("0")

  holder._xLeft:ClearAllPoints()
  holder._xLeft:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -(baselineY + 2))

  holder._xRight:ClearAllPoints()
  holder._xRight:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -padR, -(baselineY + 2))

  if fillMode then
    holder._xLeft:SetText("0s")
    holder._xRight:SetText(string.format("%ds", windowSec))
  else
    holder._xLeft:SetText(string.format("-%ds", windowSec))
    holder._xRight:SetText("0s")
  end

  -- Title (small, centered)
  holder._title:ClearAllPoints()
  holder._title:SetPoint("TOP", holder, "TOP", 0, -2)
  local tText = holder.__pleebugTitleText
  if type(tText) ~= "string" or tText == "" then
    tText = (style == "cpu") and "CPU (ms)" or "Event calls"
  end
  holder._title:SetText(tText)

  -- X-axis intermediate ticks + vertical gridlines
  local function ensureXTick(i)
    local t = holder._xTicks[i]
    if not t then
      t = holder:CreateTexture(nil, "ARTWORK")
      holder._xTicks[i] = t
    end
    t:ClearAllPoints()
    t:SetParent(holder)
    t:Show()
    return t
  end

  local function ensureXLabel(i)
    local fs = holder._xTickLabels[i]
    if not fs then
      fs = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      holder._xTickLabels[i] = fs
      fs:SetJustifyH("CENTER")
    end
    fs:ClearAllPoints()
    fs:SetParent(holder)
    fs:Show()
    return fs
  end

  local xUsed = 0
  local xDiv = 4
  for i = 1, xDiv - 1 do
    local frac = i / xDiv
    local x = padL + math.floor(frac * plotW + 0.5)

    xUsed = xUsed + 1
    local g = ensureXTick(xUsed)
    g:SetColorTexture(lr, lg, lb, 0.10)
    g:SetPoint("TOPLEFT", holder, "TOPLEFT", x, -padT)
    g:SetSize(1, plotH)

    local fs = ensureXLabel(xUsed)
    fs:SetPoint("TOP", holder, "TOPLEFT", x, -(baselineY + 2))

    local sec = windowSec * frac
    if fillMode then
      fs:SetText(string.format("%.0fs", sec))
    else
      fs:SetText(string.format("-%.0fs", (windowSec - sec)))
    end
  end

  for i = xUsed + 1, #holder._xTicks do
    if holder._xTicks[i] then holder._xTicks[i]:Hide() end
  end
  for i = xUsed + 1, #holder._xTickLabels do
    if holder._xTickLabels[i] then holder._xTickLabels[i]:Hide() end
  end


  -- Y-axis intermediate values + faint gridlines (1/4, 2/4, 3/4)
  holder._yTicks = holder._yTicks or {}
  holder._yTickLabels = holder._yTickLabels or {}

  local function ensureYTick(i)
    local t = holder._yTicks[i]
    if not t then
      t = holder:CreateTexture(nil, "ARTWORK")
      holder._yTicks[i] = t
    end
    t:ClearAllPoints()
    t:SetParent(holder)
    t:Show()
    return t
  end

  local function ensureYLabel(i)
    local fs = holder._yTickLabels[i]
    if not fs then
      fs = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      holder._yTickLabels[i] = fs
    end
    fs:ClearAllPoints()
    fs:SetParent(holder)
    fs:Show()
    return fs
  end

  local nDiv = 4
  local used = 0
  for i = 1, nDiv - 1 do
    local frac = i / nDiv
    local y = padT + plotH - math.floor(frac * plotH + 0.5)
    local val = maxY * frac

    used = used + 1
    local g = ensureYTick(used)
    g:SetColorTexture(lr, lg, lb, 0.12)
    g:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -y)
    g:SetSize(plotW, 1)

    local fs = ensureYLabel(used)
    fs:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -(y - 2))
    fs:SetText(fmtY(val))
  end

  -- CPU reference gridlines (16.7ms / 33.3ms)
  if style == "cpu" and maxY and maxY > 0 then
    local refs = { 16.6667, 33.3333 }
    for i = 1, #refs do
      local ms = refs[i]
      if ms > 0 and ms < maxY then
        local frac = ms / maxY
        if frac > 0 and frac < 1 then
          local y = padT + plotH - math.floor(frac * plotH + 0.5)

          used = used + 1
          local g = ensureYTick(used)
          g:SetColorTexture(lr, lg, lb, 0.20)
          g:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -y)
          g:SetSize(plotW, 1)

          local fs = ensureYLabel(used)
          fs:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -(y - 2))
          fs:SetText(string.format("%.1f", ms))
        end
      end
    end
  end


  for i = used + 1, #holder._yTicks do
    if holder._yTicks[i] then holder._yTicks[i]:Hide() end
  end
  for i = used + 1, #holder._yTickLabels do
    if holder._yTickLabels[i] then holder._yTickLabels[i]:Hide() end
  end




  -- Optional CPU reference line (frame budget from target FPS)
  -- Only drawn for CPU timeline mode.
  if style == "cpu" then
    local cpu = MemDebug and MemDebug.CPU
    local ms = cpu and cpu.GetRefBudgetMs and cpu:GetRefBudgetMs() or nil
    if ms and maxY and maxY > 0 then
      local frac = ms / maxY
      if frac > 0 and frac < 1 then
        local y = padT + plotH - math.floor(frac * plotH + 0.5)
        local g = _acquireTexture(holder)
        g:SetColorTexture(1, 1, 1, 0.22)
        g:SetPoint("TOPLEFT", holder, "TOPLEFT", padL, -y)
        g:SetSize(plotW, 1)
      end
    end
  end


  -- Draw series as pulse monitor bars (grow UP from baseline)
  local styleMode = (style == "dot") and "dot" or "tick"

  for si = 1, seriesCount do
    local key = series[si]
    local b = bins[si]

    local styleRec = nil
    if MemDebug and MemDebug.GetSeriesStyle and type(key) == "string" then
      styleRec = MemDebug:GetSeriesStyle(key)
    end

    if styleRec and styleRec.enabled == false then
      -- Skip hidden series
    else
      local baseAlpha = 0.12 + (0.55 * (si / seriesCount))

      local cr, cg, cb = ar, ag, ab
      if styleRec and type(styleRec.r) == "number" and type(styleRec.g) == "number" and type(styleRec.b) == "number" then
        cr, cg, cb = styleRec.r, styleRec.g, styleRec.b
      end

    -- Sparse draw: only draw pixels that actually have data.

    -- PERF: Coalesce contiguous x pixels into segments (far fewer textures).
    if styleMode == "dot" then
      for x, c in pairs(b) do
        c = tonumber(c) or 0
        if c > 0 then
          local hh = hFor(c)
          if hh < 1 then hh = 1 end

          local px = padL + (x - 1)
          local topY = baselineY - hh

          local aa = math.min(1.0, 0.2 + (c / 40))

          -- Small square dot
          local d = _acquireTexture(holder)
          d:SetColorTexture(cr, cg, cb, baseAlpha * aa)
          d:SetPoint("TOPLEFT", holder, "TOPLEFT", px - 1, -topY - 1)
          d:SetSize(2, 2)
        end
      end
    else
      -- PERF: dense scan (1..plotW), no pairs(), no sort()
      local runStartX, runEndX, runHH, runMaxC


      local function flushRun()
        if not runStartX then return end

        local px = padL + (runStartX - 1)
        local topY = baselineY - runHH

        local aa = math.min(1.0, 0.2 + ((runMaxC or 0) / 40))

        local bar = _acquireTexture(holder)
        bar:SetColorTexture(cr, cg, cb, baseAlpha * aa)
        bar:SetPoint("TOPLEFT", holder, "TOPLEFT", px, -topY)
        bar:SetSize((runEndX - runStartX + 1), runHH)

        runStartX, runEndX, runHH, runMaxC = nil, nil, nil, nil
      end

      for x = 1, plotW do
        local c = tonumber(b[x]) or 0
        if c > 0 then
          local hh = hFor(c)
          if hh < 1 then hh = 1 end

          if (not runStartX) then
            runStartX, runEndX, runHH, runMaxC = x, x, hh, c
          else
            if x == (runEndX + 1) and hh == runHH then
              runEndX = x
              if c > runMaxC then runMaxC = c end
            else
              flushRun()
              runStartX, runEndX, runHH, runMaxC = x, x, hh, c
            end
          end
        end
      end

      flushRun()

    end

    end
  end


  ----------------------------------------------------------------
  -- CPU overlay: ms-per-frame line on top of the same timeline

  ----------------------------------------------------------------
  _releaseExtra(holder)
end


