dofile(SCRIPT_PATH .. "globals.lua")

-- Setup package path locations to find rtk via ReaPack
local entrypath = ({ reaper.get_action_context() })[2]:match('^.+[\\//]')
package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)

function CreateSCPEntry(name, markerIdx, startTime, endTime, cursorPos, active)
	return { name, markerIdx, startTime, endTime, cursorPos, active }
end

function WriteSCPTable()
	local scratchPadStr = pickle(SCPTable)
	reaper.SetProjExtState(0, ScriptName, "SCPTable", scratchPadStr)
end

function ReadSCPTable()
	local SCPTable = {}
	local __, SCPTableStr = reaper.GetProjExtState(0, ScriptName, "SCPTable")
	if (SCPTableStr == "") then -- create project entry
		SCPTable[1] = CreateSCPEntry('Project', 'Project marker', 0, scratchPadTime, 0, true)
	else
		SCPTable = unpickle(SCPTableStr)
	end
	return SCPTable
end

function AddScratchPad(name)
	local slot
	for index, v in pairs(SCPTable) do -- look for first free slot
		if v == 0 then
			slot = index
			break
		end
		-- POSSIBLE BUG
		slot = index + 2 -- if no free slot found
	end

	local slotStart = scratchPadTime + ((slot - 1) * slotLength)
	local slotEnd = scratchPadTime + (((slot - 1) * slotLength) + slotLength) - slotGap
	local markerName = ScratchMarkerPrefix .. ': ' .. name
	local markerIdx = reaper.AddProjectMarker(0, true, slotStart, slotEnd, markerName, 0)
	SCPTable[slot] = CreateSCPEntry(name, markerIdx, slotStart, slotEnd, slotStart, false)
	WriteSCPTable()
	Jump(slot)
end

function DeleteScratchPad(slot)
	if (slot == 1) then return end -- never delete first (project) slot
	reaper.DeleteProjectMarker(0, SCPTable[slot][2], true)
	SCPTable[slot] = 0

	local slotCount = 0
	for _, v in pairs(SCPTable) do
		if v ~= 0 then
			slotCount = slotCount + 1
		end
	end
	if slotCount == 1 then -- no slots
		Jump(1)
	end
	WriteSCPTable()
end

function GetCurrentSlot()
	for k, v in pairs(SCPTable) do
		if v ~= 0 then
			if v[6] == true then return k end
		end
	end
	return 1 -- safety fallback, return project
end

local function isCursorInSlot(slot)
	local curPos = reaper.GetCursorPosition()
	local slotStart, slotEnd = GetSlotBoundary(slot)
	if (curPos >= slotStart) and (curPos <= slotEnd) then
		return true
	end
	return false
end

local function saveCursorPositionInSlot(slot)
	if (SCPTable[slot] ~= 0) then
		local curPos = reaper.GetCursorPosition()
		SCPTable[slot][5] = curPos
		WriteSCPTable()
	end
end

function ActivateSlot(slot)
	for _, v in pairs(SCPTable) do
		if v ~= 0 then
			v[6] = false -- unactivate everything
		end
	end
	SCPTable[slot][6] = true
end

function Jump(slot)
	if (GetCurrentSlot() == slot) then return end
	if (isCursorInSlot(GetCurrentSlot()) == true) then
		saveCursorPositionInSlot(GetCurrentSlot())
	end
	reaper.SetEditCurPos(SCPTable[slot][5], true, false)
	ActivateSlot(slot)
	WriteSCPTable()
end

function CheckSCPEmpty(tbl)
	for _, v in pairs(tbl) do
		if v ~= 0 then return true end
	end
	return false
end

function GetSlotBoundary(slot)
	local slotStart = SCPTable[slot][3]
	local slotEnd = SCPTable[slot][4]
	return slotStart, slotEnd
end

function getSlotItemsTimeMax(slot)
	local slotStart, slotEnd = GetSlotBoundary(slot)
	local maxTime = slotStart
	for t = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, t)
		for i = 0, reaper.CountTrackMediaItems(track) - 1 do
			local item = reaper.GetTrackMediaItem(track, i)
			local istart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
			local iend = istart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			if (istart >= slotStart and istart <= slotEnd) or (iend >= slotStart and iend <= slotEnd)
			then
				if iend >= maxTime then
					maxTime = iend
				end
			end
		end
	end
	return maxTime
end

function CopySelectedItemsToSlot(slot)
	if (slot == GetCurrentSlot()) then return end
	local items = GetSelectedItems()
	if (items == {}) then return end
	local minPosition = reaper.GetMediaItemInfo_Value(items[1], 'D_POSITION')
	local distance = 0

	for item = 1, #items do
		local position = reaper.GetMediaItemInfo_Value(items[item], 'D_POSITION')
		if (position <= minPosition) then minPosition = position end
	end
	distance = getSlotItemsTimeMax(slot) - minPosition;

	for item = 1, #items do
		local track = reaper.GetMediaItemTrack(items[item])
		local position = reaper.GetMediaItemInfo_Value(items[item], 'D_POSITION')
		CopyMediaItemToTrack(items[item], track, position + distance)
	end
	reaper.Main_OnCommand(40289, 0) --Item: Unselect all items
	--	reaper.SetEditCurPos(minPosition + distance, true, false)
end

--- https://forums.cockos.com/showthread.php?t=104319
--- Thx to daniellumertz
function GetSelectedItems() -- Not used it is here in case you need
	local list = {}
	local num = reaper.CountSelectedMediaItems(0)
	if num ~= 0 then
		for i = 0, num - 1 do
			list[i + 1] = reaper.GetSelectedMediaItem(0, i)
		end
	end
	return list
end

--- https://forums.cockos.com/showthread.php?t=104319
--- Thx to amagalma
function CopyMediaItemToTrack(item, track, position)
	local _, chunk = reaper.GetItemStateChunk(item, "", false)
	chunk = chunk:gsub("{.-}", "") -- Reaper auto-generates all GUIDs
	local new_item = reaper.AddMediaItemToTrack(track)
	reaper.PreventUIRefresh(1)
	reaper.SetItemStateChunk(new_item, chunk, false)
	reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", position)
	reaper.PreventUIRefresh(-1)
	return new_item
end
