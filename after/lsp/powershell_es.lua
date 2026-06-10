local base_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
local clean_bundle_path = vim.fs.normalize(base_path)
---@type vim.lsp.Config
return {
  bundle_path = clean_bundle_path,

  -- Crucial: Prevents slow profile startups from blocking the Neovim attachment loop
  init_options = {
    enableProfileLoading = false,
  },

  settings = {
    powershell = {
      codeFormatting = {
        Preset = "OTBS",
      },
    },
  },
}
