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
      "nix",
      "lua",
      "bash",
      "zsh",
      "javascript",
    },
    auto_install = true,
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
-- See note about 'mason.nvim' at the bottom of the file.
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
    Config.gh("mason-org/mason.nvim"),
    Config.gh("mason-org/mason-lspconfig.nvim"),
    Config.gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
    Config.gh("stevearc/conform.nvim"),
    Config.gh("mfussenegger/nvim-lint"),
  })

  -- =============================================================================
  -- 1. DEFINE PURE MASON TOOLS (No Nix tools here!)
  -- =============================================================================
  local mason_tools = {
    "lua-language-server",
    "typescript-language-server",
    "stylua",
    "shellcheck",
    "clangd",
    "gopls",
    "pyright",
    "rust-analyzer",
    "bash-language-server",
    "html-lsp",
    "lemminx",
    "marksman",
    "powershell-editor-services",
    "biome", -- LSP, Formatter and Linter for Javascript, TypeScript, JSON
    "zls",
  }

  -- =============================================================================
  -- 2. SETUP MASON & BINDINGS (Same loop logic as before)
  -- =============================================================================
  require("mason").setup()
  require("mason-tool-installer").setup({ ensure_installed = mason_tools, auto_install = true })

  local mason_registry = require("mason-registry")
  local mason_lsp_config_names = {}
  local formatters_by_ft = {}
  local linters_by_ft = {}

  -- DEFINE YOUR SKIP FILTERS (Indexed by filetype)
  -- Use this if multiple mason_tools are support a single language for same function
  local skip_formatters_by_ft = {
    lua = {},
    typescript = {},
  }
  local skip_linters_by_ft = {}

  for _, mason_name in ipairs(mason_tools) do
    if mason_registry.has_package(mason_name) then
      local p = mason_registry.get_package(mason_name)
      local categories = p.spec.categories or {}
      local languages = p.spec.languages or {}

      -- 1. Check for LSP
      if vim.tbl_contains(categories, "LSP") then
        local lspconfig_key = mason_name
        if p.spec and p.spec.neovim and p.spec.neovim.lspconfig then
          lspconfig_key = p.spec.neovim.lspconfig
        end
        table.insert(mason_lsp_config_names, lspconfig_key)
      end

      -- 2. Check for Formatter
      if vim.tbl_contains(categories, "Formatter") then
        for _, lang in ipairs(languages) do
          local ft = string.lower(lang)

          -- Check if this specific tool should be skipped for this filetype
          local skipped_tools = skip_formatters_by_ft[ft] or {}
          if vim.tbl_contains(skipped_tools, mason_name) then
            -- Log a quiet print statement or notify to confirm it was skipped
            -- print(string.format("[conform] Skipped matching %s for %s", mason_name, ft))
          else
            -- Check if another formatter already assigned for this language
            if formatters_by_ft[ft] then
              -- Create a readable string list of current formatters
              local current_list = table.concat(formatters_by_ft[ft], ", ")

              -- Trigger explicit notification warning snippet
              vim.notify(
                string.format(
                  '"%s" added to [%s] for language "%s" (Multiple formatters active!)',
                  mason_name,
                  current_list,
                  ft
                ),
                vim.log.levels.WARN,
                { title = "conform multiple formatter warning" }
              )
            end

            -- Initialize the nested array safely if it doesn't exist yet
            formatters_by_ft[ft] = formatters_by_ft[ft] or {}
            -- Append the tool name instead of overwriting the whole table
            table.insert(formatters_by_ft[ft], mason_name)
          end
        end
      end

      -- 3. Check for Linter
      if vim.tbl_contains(categories, "Linter") then
        for _, lang in ipairs(languages) do
          local ft = string.lower(lang)

          -- Check if this specific tool should be skipped for this filetype
          local skipped_tools = skip_linters_by_ft[ft] or {}
          if vim.tbl_contains(skipped_tools, mason_name) then
            -- Log a quiet print statement or notify to confirm it was skipped
            -- print(string.format("[nvim-lint] Skipped matching %s for %s", mason_name, ft))
          else
            -- Check if another linter already assigned for this language
            if linters_by_ft[ft] then
              -- Create a readable string list of current linters
              local current_list = table.concat(linters_by_ft[ft], ", ")

              -- Trigger explicit notification warning snippet
              vim.notify(
                string.format(
                  '"%s" added to [%s] for language "%s" (Multiple linters active!)',
                  mason_name,
                  current_list,
                  ft
                ),
                vim.log.levels.WARN,
                { title = "nvim-lint multiple linter warning" }
              )
            end

            -- Initialize the nested array safely if it doesn't exist yet
            linters_by_ft[ft] = linters_by_ft[ft] or {}
            -- Append the tool name instead of overwriting the whole table
            table.insert(linters_by_ft[ft], mason_name)
          end
        end
      end
    end
  end

  require("mason-lspconfig").setup({
    ensure_installed = mason_lsp_config_names,
    automatic_enable = true,
  })

  -- =============================================================================
  -- 3. NIX-SPECIFIC ENVIRONMENT SETUP (Completely Independent)
  -- =============================================================================

  -- Setup nixd, telling it to handle formatting using your Nix-installed nixfmt
  vim.lsp.enable("nixd")

  -- Tell Conform to use your Nix-installed nixfmt for Nix files
  formatters_by_ft["nix"] = { "nixfmt" }

  --== DEBUG
  -- vim.notify("LSPs: " .. vim.inspect(mason_lsp_config_names))
  -- vim.notify("Formatters: " .. vim.inspect(formatters_by_ft))
  -- vim.notify("Linters: " .. vim.inspect(linters_by_ft))

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
    },
  })

  -- =============================================================================
  -- 5. LINK NATIVE INDENTATION (=) TO CONFORM.NVIM
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
  local lint = require("lint")
  lint.linters_by_ft = linters_by_ft
  Config.new_autocmd("BufWritePost", nil, function()
    lint.try_lint()
  end)
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
