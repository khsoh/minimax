-- listUpdates.lua
-- IMPORTANT: For launchagent, stdout should only be written to if there are updates

-- Force all future print() calls directly to standard output
print = function(...)
  local args = { ... }
  for i, v in ipairs(args) do
    args[i] = tostring(v)
  end
  io.stdout:write(table.concat(args, "\t") .. "\n")
  io.stdout:flush()
end

local function checkPackages()
  -- Write to stderr stream
  io.stderr:write("Checking for upstream repository updates...\n")

  local status, packages = pcall(vim.pack.get, nil, { offline = false, info = true })

  if not status or not packages or vim.tbl_isempty(packages) then
    io.stderr:write("Error: Could not retrieve plugin status from vim.pack.\n")
    return
  end

  local remaining_packages = #packages

  if remaining_packages == 0 then
    vim.cmd("qa")
    return
  end

  for _, data in ipairs(packages) do
    local name = data.spec.name
    local version_spec = data.spec.version
    local remote_url = data.spec.src
    local local_rev = data.rev

    if version_spec == nil or type(version_spec) == "string" then
      -- Explicitly cast for the LSP to prevent 'string|vim.VersionRange' warnings
      local tgt_branch = (version_spec or "HEAD") ---@as string

      vim.system({ "git", "ls-remote", remote_url, tgt_branch }, { text = true }, function(obj)
        -- Ensure UI operations and state changes happen on the main thread
        if obj.code == 0 then
          local remote_rev = obj.stdout:match("^(%x+)")
          if remote_rev then
            -- Match the length of the local hash if it's a short SHA
            if #local_rev < #remote_rev then
              remote_rev = remote_rev:sub(1, #local_rev)
            end

            if local_rev ~= remote_rev then
              print(string.format("Update: %s/compare/%s...%s", remote_url, local_rev:sub(1, 8), tgt_branch))
            end
          else
            io.stderr:write(string.format("Could not parse remote revision for %s\n", name))
          end
        else
          io.stderr:write(string.format("Failed to fetch remote for %s\n", name))
        end

        -- Decrement the job counter
        remaining_packages = remaining_packages - 1
      end)
    else
      ---@diagnostic disable-next-line: undefined-field
      local local_version_str = data.version
      local range_requirement = tostring(version_spec)

      if not local_version_str then
        print(
          string.format(
            "Warning: %s requires a version matching (%s), but no local tag is resolved.",
            name,
            range_requirement
          )
        )
      else
        local is_valid = version_spec:has(local_version_str)
        if not is_valid then
          print(
            string.format(
              "Package %s installed version %s is outside version requirement %s",
              name,
              local_version_str,
              range_requirement
            )
          )
        end
      end

      -- Decrement the job counter
      remaining_packages = remaining_packages - 1
    end
  end

  -- Wait for up 15 seconds for jobs to finish - poll every 50ms
  vim.wait(15000, function()
    return remaining_packages == 0
  end, 50)

  io.stderr:write("listUpdates completed\n")
  vim.cmd("qa")
end

checkPackages()
