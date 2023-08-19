-- @version 0.1a
-- @author vlat456
-- @description Quick and dirty Scratchpad implementation for Reaper
-- This script is a subject of change in near future.
-- @provides functions.lua
--           globals.lua
--           gui.lua

local info = debug.getinfo(1, 'S');
SCRIPT_PATH = info.source:match [[^@?(.*[\/])[^\/]-$]]

dofile(SCRIPT_PATH .. "pickle.lua")
dofile(SCRIPT_PATH .. "functions.lua")
dofile(SCRIPT_PATH .. "gui.lua")

SCPTable = ReadSCPTable()
RTKinit()
