---@type vim.lsp.Config
return {
  filetypes = { "sh", "bash", "zsh" },
  -- Leverage settings to tell the underlying server how to process files
  settings = {
    bashIde = {
      -- Include zsh files cleanly in the analysis patterns
      globPattern = "*@(.sh|.inc|.bash|.command|.zsh|.zshrc)",
    },
  },
}
