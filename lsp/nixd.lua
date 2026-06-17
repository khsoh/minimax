---@type vim.lsp.Config
return {
  -- Commented out the default in nvim-lspconfig/lsp/nixd.lua
  -- cmd = { "nixd" },

  settings = {
    nixd = {
      nixpkgs = {
        -- Provides completion for packages and library functions
        expr = "import <nixpkgs> { }",
      },
      formatting = {
        -- Options: "alejandra", "nixfmt", or "nixpkgs-fmt"
        command = { "nixfmt" },
      },
      options = {
        -- 1. Evaluates nix-darwin options via your darwin channel
        ["nix-darwin"] = {
          expr = [[
            (import <darwin> {
              configuration = {
                imports = [ <home-manager/nix-darwin> ];
              };
            }).options
          ]],
        },
      },
    },
  },
}
