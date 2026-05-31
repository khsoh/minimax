-- 1. Register the package blueprint with vim.pack globally
vim.pack.add { Config.gh 'iamcco/markdown-preview.nvim' }

-- 2. Bind everything to the filetype event to handle clean lazy loading
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    -- CRITICAL: Force Neovim to evaluate the plugin's internal scripts immediately
    vim.cmd 'packadd markdown-preview.nvim'

    -- Apply plugin configurations safely
    vim.g.mkdp_auto_start = 0

    -- Set the keymap locally strictly for this buffer
    vim.keymap.set('n', '<leader>bp', '<cmd>MarkdownPreviewToggle<cr>', {
      desc = 'Preview markdown',
      buffer = true, -- Attaches ONLY to active markdown files
    })
  end,
})

-- 3. Run the Node installer block once if missing
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  once = true,
  callback = function()
    if not vim.g.mkdp_node_installed then
      vim.fn['mkdp#util#install']()
      vim.g.mkdp_node_installed = true
    end
  end,
})
-- vim: ts=2 sts=2 sw=2 et
