-- Quick and dirty Scratchpad implementation for Reaper
-- This script is a subject of change in near future.


local scratchPadName = "SCRATCH"
local scriptName = "scratchpad"
local scratchPadTime = 7200  -- seconds from start

local res, isInScratchPad = reaper.GetProjExtState(0, scriptName, "SPA")
if (res == 0) then isInScratchPad = 0 else isInScratchPad = tonumber(isInScratchPad) end

function jumpToScratchPad()
  reaper.SetProjExtState(0, scriptName, "prevCurPos", reaper.GetCursorPosition())
  reaper.SetEditCurPos(scratchPadTime, true, false)
  reaper.SetProjExtState(0, scriptName, "SPA", 1)
end

function returnToProject() 
  local res, prevCurPos = reaper.GetProjExtState(0, scriptName, "prevCurPos")
  if (res == 0) then prevCurPos = 0 else prevCurPos = tonumber(prevCurPos) end
  reaper.SetProjExtState(0, scriptName, "SPA", 0)
  reaper.SetEditCurPos(prevCurPos, true, false)
end

function createScratchPad(markerSlot) 
   reaper.AddProjectMarker(0, 0, scratchPadTime, 0, scratchPadName, markerSlot + 1)
end

function isScratchpadAvail() 
  local num = reaper.CountProjectMarkers(0)
  for i = 0, num-1 do 
    local ret, isRegion, _startPos, endPos, name, index = reaper.EnumProjectMarkers(i)
    res = string.match(scratchPadName, name)
    if res ~= nil then
      return true, num
    end
  end
  return false, num
end


if isInScratchPad == 1 then
  returnToProject()
  return
else
  local scratchAvail, markerSlot = isScratchpadAvail()
  if scratchAvail == true then
    jumpToScratchPad()
  else
    createScratchPad(markerSlot)
    jumpToScratchPad()
  end
end


