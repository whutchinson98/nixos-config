-- ---@type LazySpec
-- return {
--     "hrsh7th/nvim-cmp",
--     event = 'InsertEnter',
--     dependencies = {
--       'hrsh7th/cmp-nvim-lsp',
--       'hrsh7th/cmp-buffer',
--       'hrsh7th/cmp-path',
--       'hrsh7th/cmp-cmdline',
--     },
--     config = function()
--      local cmp = require('cmp')
--     cmp.setup({
--         snippet = {
--           expand = function(args)
--           end,
--         },
--         window = {
--           -- completion = cmp.config.window.bordered(),
--           -- documentation = cmp.config.window.bordered(),
--         },
--         mapping = cmp.mapping.preset.insert({
--           ['<C-b>'] = cmp.mapping.scroll_docs(-4),
--           ['<C-f>'] = cmp.mapping.scroll_docs(4),
--           ['<C-Space>'] = cmp.mapping.complete(),
--           ['<C-e>'] = cmp.mapping.abort(),
--           ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
--         }),
--         sources = cmp.config.sources({
--           { name = 'nvim_lsp' },
--           -- { name = 'supermaven' },
--         }, {
--           { name = 'buffer' },
--         })
--       })
--
--       -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
--       -- cmp.setup.cmdline({ '/', '?' }, {
--       --   mapping = cmp.mapping.preset.cmdline(),
--       --   sources = {
--       --     { name = 'buffer' }
--       --   }
--       -- })
--
--       -- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
--       -- cmp.setup.cmdline(':', {
--       --   mapping = cmp.mapping.preset.cmdline(),
--       --   sources = cmp.config.sources({
--       --     { name = 'path' }
--       --   }, {
--       --     { name = 'cmdline' }
--       --   }),
--       --   matching = { disallow_symbol_nonprefix_matching = false }
--       -- })
--     end
-- }

return {
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = { 'rafamadriz/friendly-snippets' },

  -- use a release tag to download pre-built binaries
  version = '1.*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = { preset = 'default' },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono'
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = { documentation = { auto_show = false } },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path' },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust" }
  },
  opts_extend = { "sources.default" }
}
