-- listUpdates.lua

print("Checking for upstream repository updates...")

local status, packages = pcall(vim.pack.get, nil, { offline = false })

if not status or not packages or vim.tbl_isempty(packages) then
  vim.notify("Error: Could not retrieve plugin status from vim.pack.", vim.log.levels.ERROR)
  return
end

-- 1. Create a table to temporarily hold found updates
local update_lines = {}

for name, data in pairs(packages) do
  if data.rev and data.rev_to and data.rev ~= data.rev_to then
    local current = data.rev:sub(1, 7)
    local upstream = data.rev_to:sub(1, 7)
    
    -- Format and save the string for later printing
    table.insert(update_lines, string.format(" * %s (%s -> %s)", name, current, upstream))
  end
end

-- 2. Only print the header and the items if the table is NOT empty
if #update_lines > 0 then
  print("\n--- Plugins with Updates Available ---")
  for _, line in ipairs(update_lines) do
    print(line)
  end
  print("--------------------------------------\n")
else
  print("Everything is up to date!")
end

-- Exit headless instance cleanly
vim.cmd("qa!")
