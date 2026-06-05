--
-- Undotree setup
--

-- Load Neovim 0.12 optional built-in undotree module
vim.cmd("packadd nvim.undotree")

-- Enable mini.bracketed with default targets (including [u and ]u for linear undo jumps)
require("mini.bracketed").setup({
  -- You can leave this blank to enable all bracketed features, or explicitly configure targets
  undo = { suffix = "u", options = {} },
})

-- Map a clean visual toggle shortcut for Neovim 0.12's native visual undo graph
vim.keymap.set("n", "<leader>u", "<cmd>Undotree<CR>", { desc = "Toggle Native Undo Tree" })
