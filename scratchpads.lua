-- Quick and dirty Scratchpad implementation for Reaper
-- This script is a subject of change in near future.

local info = debug.getinfo(1, 'S');
SCRIPT_PATH = info.source:match [[^@?(.*[\/])[^\/]-$]]

dofile(SCRIPT_PATH .. "functions.lua")
dofile(SCRIPT_PATH .. "gui.lua")

ReadSCPTable()
RTKinit()

local res, isInScratchPad = reaper.GetProjExtState(0, ScriptName, "SPA")
if (res == 0) then isInScratchPa4d = 0 else isInScratchPad = tonumber(isInScratchPad) end

local function returnToProject()
  local res, prevCurPos = reaper.GetProjExtState(0, ScriptName, "prevCurPos")
  if (res == 0) then prevCurPos = 0 else prevCurPos = tonumber(prevCurPos) end
  reaper.SetProjExtState(0, ScriptName, "SPA", 0)
  reaper.SetEditCurPos(prevCurPos, true, false)
end

local function createScratchPad(markerSlot)
  reaper.AddProjectMarker(0, 0, scratchPadTime, 0, scratchPadName, markerSlot + 1)
end

-- local function isScratchpadAvail()
--   local num = reaper.CountProjectMarkers(0)
--   for i = 0, num - 1 do
--     local ret, isRegion, _startPos, endPos, ScratchPrefix .. name, index = reaper.EnumProjectMarkers(i)
--     res = string.match(scratchPadName, name)
--     if res ~= nil then
--       return true, num
--     end
--   end
--   return false, num
-- end

-- if isInScratchPad == 1 then
--   returnToProject()
--   return
-- else
--   local scratchAvail, markerSlot = isScratchpadAvail()
--   if scratchAvail == true then
--     JumpToScratchPad()
--   else
--     createScratchPad(markerSlot)
--     JumpToScratchPad()
--   end
-- end
