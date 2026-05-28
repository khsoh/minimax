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
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git", "init.lua" },

  -- 1. DYNAMIC INITIALIZATION HOOK
  on_init = function(client)
    -- Tell Neovim this server will not handle formatting (stylua will be handling this)
    client.server_capabilities.documentFormattingProvider = false

    -- Smart check: If a project-local config file exists, stop here.
    -- This prevents overwriting custom paths for things like Love2D/Luau.
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end

    -- Inject Neovim defaults safely using a forced deep extend
    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        version = "LuaJIT",
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      workspace = {
        checkThirdParty = false,
        ignoreSubmodules = true,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
          "${3rd}/busted/library",
        },
      },
    })

    -- Notify the active background server process that the settings updated
    client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end,

  -- 2. BUFFER ATTACHMENT HOOK
  on_attach = function(client, buf_id)
    -- Optimize autocomplete trigger keys specifically for a clean mini.completion experience
    if client.server_capabilities.completionProvider then
      client.server_capabilities.completionProvider.triggerCharacters = { ".", ":", "#", "(" }
    end

    -- Drop any buffer-local keymaps (like 'gd' or 'K') directly below if needed
  end,

  -- 3. STATIC FALLBACK SETTINGS
  -- These settings are used when project-local config file (.luarc.json or .luarc.jsonc) exists.
  -- This causes early exit in on_init and hence the vim.tbl_deep_extend code will not be executed
  settings = {
    Lua = {
      -- Define runtime properties. Use 'LuaJIT', as it is built into Neovim.
      runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') },
      workspace = {
        -- Don't analyze code from submodules
        ignoreSubmodules = true,
        -- Add Neovim's methods for easier code writing
        library = { vim.env.VIMRUNTIME },
      },
      format = { enable = false }, -- Redundant safety rail to disable formatting
    },
  },
}
