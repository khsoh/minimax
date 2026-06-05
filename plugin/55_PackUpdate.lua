-- Complete plugin names when typing :PackUpdate <Tab>
local function complete_plugins(arg_lead)
  -- 1. Grab all native plugin records safely
  local pack_data = (vim.pack and vim.pack.get) and vim.pack.get(nil, { info = false }) or {}

  -- 2. Extract string names into a plain array
  local plugin_names = vim
    .iter(pack_data)
    :map(function(item)
      return item.spec.name
    end)
    :totable()

  -- 3. Let mini.fuzzy do all the hard work!
  -- It fuzzy-matches arg_lead against plugin_names list and returns a clean, sorted string list
  return require("mini.fuzzy").filtersort(arg_lead, plugin_names)
end

-- Define the interactive PackUpdate user command
vim.api.nvim_create_user_command("PackUpdate", function(opts)
  local target_plugins = #opts.fargs > 0 and opts.fargs or nil
  local is_forced = opts.bang

  -- If using a bang (!), bypass the check and update forcefully immediately
  if is_forced then
    vim.notify("Force updating packages directly...", vim.log.levels.WARN)
    vim.pack.update(target_plugins, { force = true })
    return
  end

  -- Prompt text formatting
  local target_desc = target_plugins and table.concat(target_plugins, ", ") or "all plugins"
  local prompt = string.format("Stage update for %s? (Opens Audit Buffer)", target_desc)

  -- Native interactive prompt (1 = Yes, 2 = No)
  local choice = vim.fn.confirm(prompt, "&Yes\n&No", 2)
  if choice == 1 then
    vim.notify("Fetching changes and staging confirmation buffer...", vim.log.levels.INFO)
    -- Trigger standard update which opens the interactive confirmation tabpage
    vim.pack.update(target_plugins)
  else
    vim.notify("Update staging cancelled.", vim.log.levels.WARN)
  end
end, {
  desc = "Stage plugin updates with an interactive confirmation buffer audit",
  nargs = "*", -- Accepts zero or more plugin name arguments
  bang = true, -- Accepts a ! modifier to force the update bypass
  complete = complete_plugins, -- Hook tab-completion for plugin names
})
