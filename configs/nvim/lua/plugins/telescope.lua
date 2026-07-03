---@type LazySpec
return {
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      require('telescope').setup({
        defaults = {
          file_ignore_patterns = { "^%.direnv/" },
        },
      })

      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fw', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
    end,
  },
}
