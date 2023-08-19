-- Quick and dirty Scratchpad implementation for Reaper
-- This script is a subject of change in near future.

local info = debug.getinfo(1, 'S');
SCRIPT_PATH = info.source:match [[^@?(.*[\/])[^\/]-$]]

dofile(SCRIPT_PATH .. "pickle.lua")
dofile(SCRIPT_PATH .. "functions.lua")
dofile(SCRIPT_PATH .. "gui.lua")

SCPTable = ReadSCPTable()
RTKinit()
