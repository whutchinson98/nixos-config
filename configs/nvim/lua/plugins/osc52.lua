---@type LazySpec
return {
  "ojroques/nvim-osc52",
  enabled = true,
  config = function() vim.keymap.set("v", "<leader>y", require("osc52").copy_visual) end,
}
