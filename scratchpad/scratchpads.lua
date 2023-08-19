-- @version 0.1a
-- @author vlat456
-- @description Quick and dirty Scratchpad implementation for Reaper
-- @changelog Initial alpha release
-- @provides
-- functions.lua
-- globals.lua
local info = debug.getinfo(1, 'S');
SCRIPT_PATH = info.source:match [[^@?(.*[\/])[^\/]-$]]

dofile(SCRIPT_PATH .. "pickle.lua")
dofile(SCRIPT_PATH .. "functions.lua")
dofile(SCRIPT_PATH .. "gui.lua")

SCPTable = ReadSCPTable()
RTKinit()
