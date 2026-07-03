---@type LazySpec
return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
      local harpoon = require("harpoon")
vim.keymap.set(
  "n",
  "<C-S-T>",
  function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "show harpoon quick menu" }
)

vim.keymap.set(
  "n",
  "<leader>h",
  function() harpoon:list():add() end,
  { desc = "add file" }
)

vim.keymap.set(
  "n",
  "<leader>jf",
  function() harpoon:list():select(1) end,
  { desc = "harpoon nav file 1" }
)

vim.keymap.set(
  "n",
  "<leader>jd",
  function() harpoon:list():select(2) end,
  { desc = "harpoon nav file 2" }
)

vim.keymap.set(
  "n",
  "<leader>js",
  function() harpoon:list():select(3) end,
  { desc = "harpoon nav file 3" }
)

vim.keymap.set(
  "n",
  "<leader>ja",
  function() harpoon:list():select(4) end,
  { desc = "harpoon nav file 4" }
)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set(
  "n",
  "<C-S-P>",
  function() harpoon:list():prev() end,
  { desc = "harpoon previous file" }
)

vim.keymap.set(
  "n",
  "<C-S-N>",
  function() harpoon:list():next() end,
  { desc = "harpoon next file" }
)
    end,
}
