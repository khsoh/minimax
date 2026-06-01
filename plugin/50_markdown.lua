-- Declare and download the plugin via Neovim 0.12's native pack manager
vim.pack.add { Config.gh 'toppair/peek.nvim' }

-- Configure the behavior of Peek
local peek = require("peek")

peek.setup({
  auto_load = true,        -- Smart-load preview when opening markdown
  close_on_bdelete = true, -- Shut preview when buffer is wiped
  syntax = true,           -- Toggle code block syntax highlighting
  theme = "dark",          -- Browser styling target
  app = "browser",         -- "browser" forces your default system web browser
})

-- Map a shortcut to toggle the browser layout window for markdown file
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown", -- Triggers exclusively when entering a markdown workspace context
  callback = function(ev)
    -- Map the key strictly to the buffer that just loaded (ev.buf)
    vim.keymap.set("n", "<leader>bp", function()
      local current_buf = vim.api.nvim_get_current_buf()

      -- Case 1: The preview is not active
      if not peek.is_open() then
        peek.open()
        vim.b[current_buf].peek_previewing = true

      -- Case 2: The preview is globally active AND it belongs to this specific document
      elseif vim.b[current_buf].peek_previewing then
        peek.close()
        vim.b[current_buf].peek_previewing = false

      -- Case 3: The preview is globally active, but belongs to a different buffer
      else
        -- Clean up variable markers across all other buffer frames cleanly
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            vim.b[buf].peek_previewing = false
          end
        end

        peek.open() -- Shift the active web tab focus to the current workspace document
        vim.b[current_buf].peek_previewing = true

      end
      -- Case 1: The preview is globally active AND it belongs to this specific document
      -- if peek.is_open() and vim.b[current_buf].peek_previewing then
      --   peek.close()
      --   vim.b[current_buf].peek_previewing = false
      --
      -- -- Case 2: The preview is globally active, but belongs to a different buffer
      -- elseif peek.is_open() then
      --   -- Clean up variable markers across all other buffer frames cleanly
      --   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      --     if vim.api.nvim_buf_is_valid(buf) then
      --       vim.b[buf].peek_previewing = false
      --     end
      --   end
      --
      --   peek.open() -- Shift the active web tab focus to the current workspace document
      --   vim.b[current_buf].peek_previewing = true
      --
      -- -- Case 3: The preview environment is completely dead/closed
      -- else
      --   peek.open()
      --   vim.b[current_buf].peek_previewing = true
      -- end
    end, {
      buffer = ev.buf, -- Crucial: Makes the shortcut buffer-local, keeping other filetypes clean
      desc = "Toggle Markdown Browser Preview" 
    })
  end,
})

