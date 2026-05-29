-- checkUpdates.lua

-- Ensure vim.pack is ready
if not vim.pack or not vim.pack.get then
  io.stderr:write("Error: vim.pack engine not found. Ensure Neovim >= 0.12 is running.\n")
  os.exit(1)
end

-- Track if any updates are found globally
local changes_detected = false

-- Step 1: Trigger the update in the background (force = false generates the diff)
vim.pack.update()

-- Step 2: Use an autocmd to capture when the interactive audit buffer loads
vim.api.nvim_create_autocmd("FileType", {
  pattern = "packupdate", -- The native filetype used for vim.pack audit screens
  callback = function(ev)
    -- Allow the asynchronous LSP server a moment to finish printing the git logs
    vim.defer_fn(function()
      local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
      local current_plugin = "Unknown"
      
      print("\n=== PENDING PLUGIN UPDATES ===")
      
      for _, line in ipairs(lines) do
        -- Match headings identifying individual plugins
        local plugin_match = line:match("^##%s+(.+)")
        if plugin_match then
          current_plugin = plugin_match
        end
        
        -- Detect the bulleted git logs under each plugin heading
        -- (A '*' or '-' prefix implies new commits are waiting upstream)
        if line:match("^%s*[%*%-]%s+") then
          if current_plugin then
            print(string.format("[%s] New Update available:", current_plugin))
            current_plugin = nil -- Only print the plugin name header once
          end
          print("  " .. line:gsub("^%s*[%*%-]%s+", ""))
          changes_detected = true
        end
      end
      
      if not changes_detected then
        print("All plugins are fully up to date with upstream repositories.")
      end
      print("==============================\n")
      
      -- Force exit headless mode safely without saving or updating the lockfile
      vim.cmd("qa!")
    end, 1500) -- 1.5 second safety delay to let git data stream completely
  end
})
