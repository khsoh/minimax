-- 1. Locate the entry point symlink for pwsh
local pes_exepath = vim.fn.exepath("powershell-editor-services")

if pes_exepath == "" then
  vim.notify(
    "'powershell-editor-services' executable not found in path.  Please install 'powershell-editor-services'",
    vim.log.levels.WARN,
    { title = "LSP Configuration" }
  )
  return {} -- Stop execution immediately to prevent crashing
end

-- Get the real location of pwsh
local real_pes_path = vim.uv.fs_realpath(pes_exepath)

if not real_pes_path then
  vim.notify(
    "Failed to resolve the real storage path of 'powershell-editor-services' symlink",
    vim.log.levels.WARN,
    { title = "LSP Configuration" }
  )
  return {} -- Stop execution immediately to prevent crashing
end

-- Strip out trailing whitespace
real_pes_path = real_pes_path:gsub("%s+$", "")

-- Get the nix store root
local nix_store_root = real_pes_path:gsub("bin/powershell%-editor%-services$", "")

-- Please the lib path
local nix_bundle_path = nix_store_root .. "lib/powershell-editor-services"

---@type vim.lsp.Config
return {
  bundle_path = nix_bundle_path,

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
