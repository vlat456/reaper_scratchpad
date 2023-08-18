dofile(SCRIPT_PATH .. "globals.lua")

-- Setup package path locations to find rtk via ReaPack
local entrypath = ({ reaper.get_action_context() })[2]:match('^.+[\\//]')
package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)

function WriteSCPTable()
	local scratchPadStr = pickle(SCPTable)
	reaper.SetProjExtState(0, ScriptName, "SCPTable", scratchPadStr)
end

function ReadSCPTable()
	local __, SCPTableStr = reaper.GetProjExtState(0, ScriptName, "SCPTable")
	if (SCPTableStr == "") then SCPTable[1] = nil else SCPTable = unpickle(SCPTableStr) end
end

function AddScratchPad(name)
	local slot = 1
	for k, v in ipairs(SCPTable) do
		if v == 0 then break end
		slot = slot + 1
	end
	local slotStart, slotEnd = MakeTimeFromSlot(slot)
	local markerName = ScratchMarkerPrefix .. ': ' .. name
	local markerIdx = reaper.AddProjectMarker(0, true, slotStart, slotEnd, markerName, 0)
	SCPTable[slot] = { name, markerIdx }
	WriteSCPTable()
	JumpToScratchPad(slot)
end

function DeleteScratchPad(slot)
	reaper.DeleteProjectMarker(0, SCPTable[slot][2], true)
	SCPTable[slot] = 0
	WriteSCPTable()
end

function JumpToScratchPad(slot)
	local slotStart, _ = MakeTimeFromSlot(slot)
	reaper.SetProjExtState(0, ScriptName, "prevCurPos", reaper.GetCursorPosition())
	reaper.SetEditCurPos(slotStart, true, false)
	reaper.SetProjExtState(0, ScriptName, "SPA", 1)
end

function CheckSCPEmpty(tbl)
	for _, v in ipairs(tbl) do
		if v ~= 0 then return true end
	end
	return false
end

function MakeTimeFromSlot(slot)
	local slotStart = scratchPadTime + ((slot - 1) * slotLength)
	local slotEnd = scratchPadTime + ((slot - 1) * slotLength) + slotLength
	return slotStart, slotEnd
end

-- https://gist.github.com/jrus/3197011
-- local random = math.random
-- local function uuid()
--   local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
--   return string.gsub(template, '[xy]', function(c)
--     local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
--     return string.format('%x', v)
--   end)
-- end

--------------------------------------------------------------------------------
-- Pickle table serialization - Steve Dekorte, http://www.dekorte.com, Apr 2000
--------------------------------------------------------------------------------
function pickle(t)
	return Pickle:clone():pickle_(t)
end

--------------------------------------------------------------------------------
Pickle = {
	clone = function(t)
		local nt = {}
		for i, v in pairs(t) do
			nt[i] = v
		end
		return nt
	end
}
--------------------------------------------------------------------------------
function Pickle:pickle_(root)
	if type(root) ~= "table" then
		error("can only pickle tables, not " .. type(root) .. "s")
	end
	self._tableToRef = {}
	self._refToTable = {}
	local savecount = 0
	self:ref_(root)
	local s = ""
	while #self._refToTable > savecount do
		savecount = savecount + 1
		local t = self._refToTable[savecount]
		s = s .. "{\n"
		for i, v in pairs(t) do
			s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
		end
		s = s .. "},\n"
	end
	return string.format("{%s}", s)
end

--------------------------------------------------------------------------------
function Pickle:value_(v)
	local vtype = type(v)
	if vtype == "string" then
		return string.format("%q", v)
	elseif vtype == "number" then
		return v
	elseif vtype == "boolean" then
		return tostring(v)
	elseif vtype == "table" then
		return "{" .. self:ref_(v) .. "}"
	else
		error("pickle a " .. type(v) .. " is not supported")
	end
end

--------------------------------------------------------------------------------
function Pickle:ref_(t)
	local ref = self._tableToRef[t]
	if not ref then
		if t == self then error("can't pickle the pickle class") end
		table.insert(self._refToTable, t)
		ref = #self._refToTable
		self._tableToRef[t] = ref
	end
	return ref
end

--------------------------------------------------------------------------------
-- unpickle
--------------------------------------------------------------------------------
function unpickle(s)
	if type(s) ~= "string" then
		error("can't unpickle a " .. type(s) .. ", only strings")
	end
	local gentables = load("return " .. s)
	local tables = gentables()
	for tnum = 1, #tables do
		local t = tables[tnum]
		local tcopy = {}
		for i, v in pairs(t) do tcopy[i] = v end
		for i, v in pairs(tcopy) do
			local ni, nv
			if type(i) == "table" then ni = tables[i[1]] else ni = i end
			if type(v) == "table" then nv = tables[v[1]] else nv = v end
			t[i] = nil
			t[ni] = nv
		end
	end
	return tables[1]
end

function getSlotItemsTimeMax(slot)
	local slotStart, slotEnd = MakeTimeFromSlot(slot)
	local maxTime = 0
	for t = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetSelectedTrack(0, t)
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
		return maxTime
	end
end

function CopySelectedItemsToSlot(slot)
	local items = GetSelectedItems()
	local slotStart, _ = MakeTimeFromSlot(slot)
	local minPosition = reaper.GetMediaItemInfo_Value(items[1], 'D_POSITION')

	for item = 1, #items do
		local position = reaper.GetMediaItemInfo_Value(items[item], 'D_POSITION')
		if (position <= minPosition) then minPosition = position end
	end
	local distance = slotStart - minPosition;

	for item = 1, #items do
		local track = reaper.GetMediaItemTrack(items[item])
		local position = reaper.GetMediaItemInfo_Value(items[item], 'D_POSITION')

		CopyMediaItemToTrack(items[item], track, position + distance)
	end
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
	--reaper.Main_OnCommand(40289, 0)--Item: Unselect all items
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
