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
-- tree-sitter-manager is a tool to help manage the installation of language
-- syntax parsers to enhance the capabilities of tree-sitter
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  add({
    Config.gh("nvim-treesitter/nvim-treesitter-textobjects"),
    Config.gh("romus204/tree-sitter-manager.nvim"),
  })
  require("tree-sitter-manager").setup({
    -- Automatically build and installs the relevant binaries to parse syntax
    -- These are syntax parsers NOT LSPs
    ensure_installed = {
      "vim",
      "vimdoc",
      "nix",
      "lua",
      "bash",
      "zsh",
      "javascript",
      "applescript",
    },
    auto_install = true,

    languages = {
      applescript = {
        install_info = {
          -- The exact GitHub URL the manager will download:
          url = "https://github.com/waddie/tree-sitter-applescript",
          files = { "src/parser.c" },
          branch = "main",
          use_repo_queries = true,
        },

        filetype = "applescript",
      },
    },
  })
  -- 1. UNIFIED NATIVE TREESITTER SETTINGS
  Config.new_autocmd("FileType", "*", function(event)
    local lang = vim.treesitter.language.get_lang(event.match) or event.match
    if not lang or lang == "" then
      return
    end

    if vim.treesitter.query.get(lang, "highlights") then
      -- Start fast syntax highlighting
      pcall(vim.treesitter.start, event.buf, lang)

      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldenable = false
    end
  end)

  -- 2. INCREMENTAL SELECTION KEYMAPS (Overriding mini.ai Visual Mode Blocks)
  vim.keymap.set("n", "<CR>", function()
    vim.treesitter.incremental_selection.init()
  end, { desc = "Init treesitter selection" })

  vim.keymap.set("x", "<CR>", function()
    vim.treesitter.incremental_selection.node_incremental()
  end, { desc = "Increment selection" })

  vim.keymap.set("x", "<BS>", function()
    vim.treesitter.incremental_selection.node_decremental()
  end, { desc = "Decrement selection" })
end)

-- Language tools =============================================================
--
-- Support for LSPs, Linters and Formatters
--
-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
--
-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
--
-- Linting support is provided via nvim-lint package
--
now_if_args(function()
  add({
    Config.gh("neovim/nvim-lspconfig"), -- DO NOT REMOVE: This is needed by vim.lsp.enable() to provide the background database
    Config.gh("stevearc/conform.nvim"),
    Config.gh("mfussenegger/nvim-lint"),
    -- Config.gh("jmbuhr/otter.nvim"),
  })

  -- =============================================================================
  -- 1. DEFINE FORMATTERS AND LINTERS
  -- =============================================================================
  local formatters_by_ft = {
    css = { "prettier_project", "biome", stop_after_first = true },
    html = { "prettier_project", "biome", stop_after_first = true },
    json = { "prettier_project", "biome", stop_after_first = true },
    javascript = { "prettier_project", "biome", stop_after_first = true },
    typescript = { "prettier_project", "biome", stop_after_first = true },
    lua = { "stylua" },
    nix = { "injected", "nixfmt" },
    markdown = { "prettier_global" },
    python = { "ruff_format" },

    ---- NOTE: conform has been setup with default_format_opts.lsp_format = "fallback"
    --     so that LSP will be called as formatter if none is declared in this
    --     table.  The following filetypes will use LSP as formatter:
    --      = bash/zsh files: Fallback to bashls which calls shfmt automatically as a formatter
    --      = c/cpp files
    --      = powershell files
    --      = go files
    --      = rust files
    --      = zig files
    --      = XML files
  }
  local linters_by_ft = {
    json = { "biomejs" },
    javascript = { "biomejs" },
    typescript = { "biomejs" },
    python = { "ruff" },
  }
  local lint = require("lint")

  -- =============================================================================
  -- 2. LSPs
  -- =============================================================================
  local nix_lsps = {
    "lua_ls",
    "nixd",
    "bashls",
    "ts_ls",
    "marksman",
    "powershell_es",
    "pyright",
    "clangd",
    "gopls",
    "rust_analyzer",
    "zls",

    -- UNABLE TO WORK ON NIX DUE TO PATH ISSUES
    -- "html",     -- HTML server (vscode-html-language-server)
    -- "cssls",    -- CSS server (vscode-html-language-server)
    -- "jsonls",   -- JSON server (vscode-html-language-server)
    "lemminx",
    "superhtml", -- HTML
    "biome", -- HTML, CSS, JSON
  }
  -- Enabling the LSPs - need the nvim-lspconfig background database
  for _, server in ipairs(nix_lsps) do
    vim.lsp.enable(server)
  end

  --== DEBUG
  -- vim.notify("Formatters: " .. vim.inspect(formatters_by_ft))
  -- vim.notify("Linters: " .. vim.inspect(linters_by_ft))

  -- Setting up the formatters
  require("conform").setup({
    formatters_by_ft = formatters_by_ft,
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = "fallback",
    },
    formatters = {
      stylua = {
        -- Pass CLI arguments to force spaces instead of tabs
        args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
      },

      -- STRICT PROFILE for prettier - runs only if config files exist
      --   this is to avoid major conflicts with biome - we want to use
      --   biome by default especially in JS projects
      prettier_project = {
        -- Inherit everything from built-in prettier
        inherit = "prettier",
        -- Prettier will ONLY run if it finds one of these configuration files
        require_cwd = true,
        cwd = require("conform.util").root_file({
          ".prettierrc",
          ".prettierrc.json",
          ".prettierrc.yml",
          ".prettierrc.yaml",
          ".prettierrc.js",
          "prettier.config.js",
        }),
      },

      -- LOOSE PROFILE: Always runs everywhere (no root file constraints)
      prettier_global = {
        -- Inherit everything from built-in prettier, but explicitly disable cwd constraints
        inherit = "prettier",
        require_cwd = false,
      },

      biome = {
        -- Biome acts as the global safety net. It runs everywhere else!
        require_cwd = false,
      },
    },
  })

  -- =============================================================================
  -- 3. LINK NATIVE INDENTATION (=) TO CONFORM.NVIM
  -- =============================================================================

  -- Maps '=' in Visual/Selection mode to format just the selected block
  vim.keymap.set(
    "v",
    "=",
    "<Esc>:lua require('conform').format({ async = true, lsp_callback = true})<CR>",
    { desc = "Clean spaces range formatting", silent = true }
  )

  -- Maps '=' in Normal mode to format the entire active file
  vim.keymap.set("n", "=", function()
    require("conform").format({ async = true, lsp_fallback = true })
  end, { desc = "Format current buffer via Conform" })

  -- Setup Linters
  lint.linters_by_ft = linters_by_ft
  Config.new_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, nil, function()
    lint.try_lint()
  end)

  -- Setup otter
  -- vim.api.nvim_create_autocmd("FileType", {
  --   group = vim.api.nvim_create_augroup("OtterAutoActivate", { clear = true }),
  --   -- Specify all host files where you want embedded language support
  --   pattern = { "markdown", "bash", "zsh", "nix", "python", "go" },
  --   callback = function()
  --     -- Calling activate() with no arguments tells Otter to dynamically
  --     -- scan and load ALL injected languages it finds via Tree-sitter!
  --     require("otter").activate()
  --   end,
  -- })
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
