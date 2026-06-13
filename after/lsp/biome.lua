---@type vim.lsp.Config
return {
  workspace_required = false,

  on_attach = function(client, bufnr)
    -- 1. Look up standard file identifiers that belong to Prettier
    local prettier_markers = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.js",
      "prettier.config.js",
      "prettier.config.cjs",
      "prettier.config.mjs",
    }

    local has_prettier = vim.fs.find(prettier_markers, {
      path = vim.api.nvim_buf_get_name(bufnr),
      type = "file",
      limit = 1,
      upward = true,
    })[1]

    -- 2. If Prettier is present, disable Biome's formatting capabilities
    -- This ensures Neovim will never route a formatting request to Biome
    if has_prettier then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,

  root_dir = function(bufnr, on_dir)
    local root_markers = {
      "package-lock.json",
      "yarn.lock",
      "pnpm-lock.yaml",
      "bun.lockb",
      "biome.json",
      "biome.jsonc",
      ".git",
    }
    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
    on_dir(project_root)
  end,
}
