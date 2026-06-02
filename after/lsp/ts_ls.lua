return {
  -- Uses standard lspconfig workspace lookup helpers
  root_dir = require("lspconfig.util").root_pattern( "package.json", "tsconfig.json", "jsconfig.json", ".git"),
}
