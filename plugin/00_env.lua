-- Initialize the neovim environment

-- Prepend mason bin directory to PATH so all subsequent plugins can find its tools
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end
