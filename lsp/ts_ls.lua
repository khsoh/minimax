-- lsp/ts_ls.lua

return {
  settings = {
    -- The typescript-language-server binary looks for diagnostics
    -- at the root level of settings, not under javascript/typescript blocks.
    diagnostics = {
      ignoredCodes = { 80001 },
    },
  },
}
