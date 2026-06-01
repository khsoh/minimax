-- PackChanged and PackChangedPre event handlers must be added BEFORE any vim.pack.add
--
local peekUpdate = function()
  -- Compile the asset verbosely so failures show up in the messages buffer (:messages)
  vim.notify("Peek.nvim start compile", vim.log.levels.INFO)
  local path = vim.fn.stdpath("data") .. "/site/pack/core/opt/peek.nvim"
  vim.fn.system("zsh -l -c 'cd " .. path .. " && deno task build:fast'")
  vim.notify("Peek.nvim compiled successfully!", vim.log.levels.INFO)
end

Config.on_packchanged("peek.nvim", { "install", "update" }, peekUpdate, "peek.nvim install/update")

