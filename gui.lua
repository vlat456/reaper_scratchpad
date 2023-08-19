dofile(SCRIPT_PATH .. "functions.lua")

-- Loads rtk in the global scope, and, if missing, attempts to install using
-- ReaPack APIs.
function RTKinit(attempts)
  local ok
  ok, rtk = pcall(function() return require('rtk') end)
  if ok then
    -- Import worked. We can invoke the main function.
    return rtk.call(main)
  end
  local installmsg = 'Visit https://reapertoolkit.dev for installation instructions.'
  if not attempts then
    -- This is our first failed attempt, so prompt the user if they want us to install
    -- rtk via ReaPack automatically.
    if not reaper.ReaPack_AddSetRepository then
      -- The ReaPack extension isn't installed, so inform the user they need to do a
      -- manual install.
      return reaper.MB(
        'This script requires the REAPER Toolkit ReaPack. ' .. installmsg,
        'Missing Library',
        0 -- Ok
      )
    end
    -- Ask the user if they want us to install rtk
    local response = reaper.MB(
      'This script requires the REAPER Toolkit ReaPack. Would you like to automatically install it?',
      'Automatically install REAPER Toolkit ReaPack?',
      4 -- Yes/No
    )
    if response ~= 6 then
      -- User said no, we're done.
      return reaper.MB(installmsg, 'Automatic Installation Refused', 0)
    end
    -- User said yes, so add the ReaPack repository.
    local ok, err = reaper.ReaPack_AddSetRepository('rtk', 'https://reapertoolkit.dev/index.xml', true, 1)
    if not ok then
      return reaper.MB(
        string.format('Automatic install failed: %s.\n\n%s', err, installmsg),
        'ReaPack installation failed',
        0 -- Ok
      )
    end
    reaper.ReaPack_ProcessQueue(true)
  elseif attempts > 150 then
    -- After about 5 seconds we still couldn't find rtk, so give up.
    return reaper.MB(
      'Installation took too long. Assuming a ReaPack error occurred and giving up. ' .. installmsg,
      'ReaPack installation failed',
      0 -- Ok
    )
  end
  -- If we've made it this far we keep trying to load rtk
  reaper.defer(function() init((attempts or 0) + 1) end)
end

local function makeMenuItems(action)
  local items = {}
  if #SCPTable ~= 0 then
    for k, v in pairs(SCPTable) do
      if v ~= 0 then
        table.insert(items, { v[1], slot = k, id = action })
      end
    end
  end
  return items
end

function main()
  local rtk = require('rtk')

  local addWindow = rtk.Window { title = 'New scratchpad', halign = 'center', valign = 'center' }

  local entryBox = addWindow:add(rtk.HBox { padding = '15', halign = 'center', valign = 'center' })

  local addEntry = entryBox:add(rtk.Entry { placeholder = 'New scratchpad title', textwidth = 15, halign = 'center', valign =
  'center' })
  addEntry.keypress = function(self, event)
    if event.keycode == rtk.keycodes.ESCAPE then
      self:clear()
    elseif event.keycode == rtk.keycodes.ENTER then
    end
  end

  entryBox:add(rtk.Spacer { h = 0.1, w = 0.1, haligh = 'center', valign = 'center' })

  local addButton = entryBox:add(rtk.Button { label = 'Ok', halign = 'center', valign = 'center' })
  addButton.onclick = function()
    AddScratchPad(addEntry.value)
    addWindow:close()
  end

  local menu = rtk.NativeMenu()
  local jumpItems = makeMenuItems('jump')

  local menuItems = {}
  table.insert(menuItems, { 'Show debug', id = 'debug' })
  table.insert(menuItems, { 'New scratchpad', id = 'addWindow' })
  table.insert(menuItems, rtk.NativeMenu.static.SEPARATOR)
  ---table.insert(menuItems, { 'Jump to project', id = 'jumpProject' })
  table.insert(menuItems, { 'Jump to scratchpad:', disabled = true })
  for i = 1, #jumpItems do
    table.insert(menuItems, jumpItems[i])
  end
  table.insert(menuItems, rtk.NativeMenu.SEPARATOR)
  table.insert(menuItems,
    { 'Copy selected to pad', disabled = not CheckSCPEmpty(SCPTable), submenu = makeMenuItems('copy') })
  table.insert(menuItems,
    { 'Delete scratchpad', disabled = not CheckSCPEmpty(SCPTable), submenu = makeMenuItems('delete') })
  table.insert(menuItems, { 'Exit', id = 'exit' })
  menu:set(menuItems)

  menu:open_at_mouse():done(function(item)
    if not item then
      -- User clicked off of menu, nothing selected.
      return
    end
    if item.id == 'addWindow' then
      do
        addWindow:open()
        addEntry:focus()
      end
    elseif item.id == 'debug' then
      reaper.ShowConsoleMsg(pickle(SCPTable))
    elseif item.id == 'jump' then
      Jump(item.slot)
    elseif item.id == 'jumpProject' then
      Jump(0)
    elseif item.id == 'copy' then
      CopySelectedItemsToSlot(item.slot)
    elseif item.id == 'delete' then
      DeleteScratchPad(item.slot)
    elseif item.id == 'exit' then
      rtk.quit()
    end
  end)
end
