-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
-- now_if_args(function()
--   -- Define hook to update tree-sitter parsers after plugin is updated
--   local ts_update = function()
--     vim.cmd("TSUpdate")
--   end
--   Config.on_packchanged("nvim-treesitter", { "update" }, ts_update, ":TSUpdate")
--
--   add({
--     Config.gh("nvim-treesitter/nvim-treesitter"),
--     Config.gh("nvim-treesitter/nvim-treesitter-textobjects"),
--   })
--
--   -- Define languages which will have parsers installed and auto enabled
--   -- After changing this, restart Neovim once to install necessary parsers. Wait
--   -- for the installation to finish before opening a file for added language(s).
--   local languages = {
--     -- These are already pre-installed with Neovim. Used as an example.
--     "lua",
--     "vimdoc",
--     "markdown",
--     -- OVERRIDES ======================
--     -- 'bash',
--     "c",
--     -- "diff",
--     -- "html",
--     -- "luadoc",
--     "markdown_inline",
--     "vim",
--     -- END OVERRIDES ==================
--     -- Add here more languages with which you want to use tree-sitter
--     -- To see available languages:
--     -- - Execute `:=require('nvim-treesitter').get_available()`
--     -- - Visit 'SUPPORTED_LANGUAGES.md' file at
--     --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
--   }
--   local isnt_installed = function(lang)
--     return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
--   end
--   local to_install = vim.tbl_filter(isnt_installed, languages)
--   if #to_install > 0 then
--     require("nvim-treesitter").install(to_install)
--   end
--
--   -- Enable tree-sitter after opening a file for a target language
--   local filetypes = {}
--   for _, lang in ipairs(languages) do
--     for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
--       table.insert(filetypes, ft)
--     end
--   end
--   local ts_start = function(ev)
--     vim.treesitter.start(ev.buf)
--   end
--   Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
-- end)
now_if_args(function()
  -- 1. UNIFIED NATIVE TREESITTER SETTINGS
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function(event)
      local lang = vim.treesitter.language.get_lang(event.match) or event.match
      if not lang or lang == "" then return end

      if vim.treesitter.query.get(lang, "highlights") then
        pcall(vim.treesitter.start, event.buf, lang)

        vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()"
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldenable = false
      end
    end,
  })

  -- 2. INCREMENTAL SELECTION KEYMAPS (Overriding mini.ai Visual Mode Blocks)
  vim.keymap.set('n', '<CR>', function()
    vim.treesitter.incremental_selection.init()
  end, { desc = 'Init treesitter selection' })

  vim.keymap.set('x', '<CR>', function()
    vim.treesitter.incremental_selection.node_incremental()
  end, { desc = 'Increment selection' })

  vim.keymap.set('x', '<BS>', function()
    vim.treesitter.incremental_selection.node_decremental()
  end, { desc = 'Decrement selection' })
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
now_if_args(function()
  add({
    Config.gh("neovim/nvim-lspconfig"),
    Config.gh("mason-org/mason.nvim"),
    Config.gh("mason-org/mason-lspconfig.nvim"),
    Config.gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  -- NOTE: Enclose the language server name in [ ] if it includes a '-' character
  local servers = {
    clangd = {},
    gopls = {},
    pyright = {},
    ["rust-analyzer"] = {},
    ["bash-language-server"] = {
      cmd = { "bash-language-server", "start" },
      filetypes = { "sh", "bash", "zsh" },
      root_markers = { ".git" },
    },
    -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    ["html-lsp"] = { filetypes = { "html", "twig", "hbs" } },
    marksman = {},
    ["powershell-editor-services"] = {
      bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
      settings = { powershell = { codeFormatting = { Preset = "OTBS" } } },
    },
    biome = {},
    zls = {},
    ["tree-sitter-cli"] = {},

    ["typescript-language-server"] = {
      cmd = { "typescript-language-server", "--stdio" },
      -- root_markers is the new standard in 0.11+ replacing root_dir
      root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
      -- Optional: add filetypes if you want to be explicit
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    },

    stylua = {}, -- Used to format Lua code

    ["lua-language-server"] = {},

    ["eslint-lsp"] = {},
    ["eslint_d"] = {},
    ["prettierd"] = {},
    lemminx = {
      filetypes = { "xml", "xsd", "xsl", "xslt", "svg", "mobileconfig" },
    },
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require("mason").setup({})

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  -- Only ask Mason to install servers that are present in registry
  local ensure_installed = vim.tbl_keys(servers or {})
  require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

  -- Add other LSPs that are NOT installed by mason-tool-installer
  --   but have to be configured and enabled by vim.lsp
  servers = vim.tbl_deep_extend("force", servers, {
    nixd = {}
  })


  local registry = require("mason-registry")

  for name, server in pairs(servers) do
    local lsp_name = name

    -- Query Mason to get package
    local p_status, p = pcall(registry.get_package, name)
    if p_status and p and p.spec and p.spec.neovim then
      lsp_name = p.spec.neovim.lspconfig or name
    end

    vim.lsp.config(lsp_name, server)
    vim.lsp.enable(lsp_name)
  end
  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
  -- vim.lsp.enable({
  --   -- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
  -- })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add({ Config.gh("stevearc/conform.nvim") })

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require("conform").setup({
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        nix = true,
        js = true,
        lua = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = "fallback",
    },
    -- Map of filetype to formatters
    -- Make sure that necessary CLI tool is available
    formatters_by_ft = {
      javascript = { "prettierd", stop_after_first = true },
      nix = { "nixfmt" },
      lua = { "stylua" },
    },
    formatters = {
      stylua = {
        -- Pass CLI arguments to force spaces instead of tabs
        args = { "--quote-style", "Preserve", "--indent-type", "Spaces", "--indent-width", "2", "-" },
      },
    },
  })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
  add({ Config.gh("rafamadriz/friendly-snippets") })
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
-- now_if_args(function()
--   add({ 'https://github.com/mason-org/mason.nvim' })
--   require('mason').setup()
-- end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
-- Config.now(function()
--  -- Install only those that you need
--  add({
--    'https://github.com/sainnhe/everforest',
--    'https://github.com/Shatur/neovim-ayu',
--    'https://github.com/ellisonleao/gruvbox.nvim',
--  })
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)
