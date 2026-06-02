-- ┌────────────────────┐
-- │ LSP config example │
-- └────────────────────┘
--
-- This file contains configuration of 'lua_ls' language server.
-- Source: https://github.com/LuaLS/lua-language-server
--
-- It is used by `:h vim.lsp.enable()` and `:h vim.lsp.config()`.
-- See `:h vim.lsp.Config` and `:h vim.lsp.ClientConfig` for all available fields.
--
-- This config is designed for Lua's activity around Neovim. It provides only
-- basic config and can be further improved.
return {
  -- Uses standard lspconfig workspace detection (safe for your handler loop)
  root_dir = require("lspconfig.util").root_pattern(".luarc.json", ".luarc.jsonc", ".git", "init.lua"),

  -- 1. BUFFER ATTACHMENT HOOK
  on_attach = function(client, bufnr)
    -- Explicitly disable LSP formatting so conform.nvim + stylua take priority
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false

    -- Optimize autocomplete trigger keys specifically for mini.completion
    if client.server_capabilities.completionProvider then
        client.server_capabilities.completionProvider.triggerCharacters = { ".", ":", "#", "(" }
    end

    -- Note: Feel free to add any buffer-local LSP keymaps right here
  end,

  -- 3. STATIC FALLBACK SETTINGS
  -- These settings are used when project-local config file (.luarc.json or .luarc.jsonc) exists.
  -- This causes early exit in on_init and hence the vim.tbl_deep_extend code will not be executed
  settings = {
    Lua = {
      -- Define runtime properties. Use 'LuaJIT', as it is built into Neovim.
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';')
      },
      workspace = {
        checkThirdParty = false,
        -- Don't analyze code from submodules
        ignoreSubmodules = true,
        -- Add Neovim's methods for easier code writing
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",     -- Add luv bindings support
          "${3rd}/busted/library",  -- Add busted testing framework support
        },
      },
      diagnostics = {
        -- Stops the server from complaining about the global 'vim' variable
        globals = { "vim" },
      },
      format = {
        enable = false,   -- Double safety rail to ensure lua_ls never formats
      },
    },
  },
}
