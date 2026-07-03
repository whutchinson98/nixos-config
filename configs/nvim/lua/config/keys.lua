-- Navigate between panes using Ctrl + hjkl
-- vim.keymap.set(
--   "n",
--   "<C-h>",
--   "<C-w>h",
--   { desc = "move to left pane" }
-- )
--
-- vim.keymap.set(
--   "n",
--   "<C-j>",
--   "<C-w>j",
--   { desc = "move to bottom pane" }
-- )
--
-- vim.keymap.set(
--   "n",
--   "<C-k>",
--   "<C-w>k",
--   { desc = "move to top pane" }
-- )
--
-- vim.keymap.set(
--   "n",
--   "<C-l>",
--   "<C-w>l",
--   { desc = "move to right pane" }
-- )

-- Create vertical split
vim.keymap.set(
  "n",
  "<leader>sl",
  ":vsplit<CR>",
  { desc = "create vertical split" }
)

vim.keymap.set(
  "n",
  "<leader>c",
  ":bdelete<CR>",
  { desc = "close current buffer" }
)

-- TODO: yank
