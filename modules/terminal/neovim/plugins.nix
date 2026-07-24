{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      programs.neovim.plugins = [
        pkgs.vimPlugins.friendly-snippets
        pkgs.vimPlugins.gruvbox-nvim
        pkgs.vimPlugins.nvim-lspconfig
        pkgs.vimPlugins.nvim-web-devicons
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.which-key-nvim
        (pkgs.vimPlugins.nvim-treesitter.withPlugins (parsers: [
          parsers.lua
          parsers.vim
          parsers.rust
          parsers.typescript
        ]))

        {
          plugin = pkgs.vimPlugins.blink-cmp;
          type = "lua";
          config = ''
            require("blink.cmp").setup({
              keymap = { preset = "default" },
              appearance = {
                nerd_font_variant = "mono",
              },
              completion = {
                documentation = { auto_show = false },
              },
              sources = {
                default = { "lsp", "path" },
              },
              fuzzy = { implementation = "prefer_rust" },
            })
          '';
        }

        {
          plugin = pkgs.vimPlugins.harpoon2;
          type = "lua";
          config = ''
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
          '';
        }

        {
          plugin = pkgs.vimPlugins.lualine-nvim;
          type = "lua";
          config = ''
            require("lualine").setup({
              options = {
                icons_enabled = true,
                theme = "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                  statusline = {},
                  winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                always_show_tabline = true,
                globalstatus = false,
                refresh = {
                  statusline = 1000,
                  tabline = 1000,
                  winbar = 1000,
                  refresh_time = 16,
                  events = {
                    "WinEnter",
                    "BufEnter",
                    "BufWritePost",
                    "SessionLoadPost",
                    "FileChangedShellPost",
                    "VimResized",
                    "Filetype",
                    "CursorMoved",
                    "CursorMovedI",
                    "ModeChanged",
                  },
                },
              },
              sections = {
                lualine_a = { "filename" },
                lualine_b = {},
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
              },
              inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {},
              },
              tabline = {},
              winbar = {},
              inactive_winbar = {},
              extensions = {},
            })
          '';
        }

        {
          plugin = pkgs.vimPlugins.mini-icons;
          type = "lua";
          config = ''
            require("mini.icons").setup({})
          '';
        }

        {
          plugin = pkgs.vimPlugins.oil-nvim;
          type = "lua";
          config = ''
            require("oil").setup()

            vim.keymap.set(
              "n",
              "-",
              "<CMD>Oil<CR>",
              { desc = "toggle oil" }
            )
          '';
        }

        {
          plugin = pkgs.vimPlugins.nvim-osc52;
          type = "lua";
          config = ''
            vim.keymap.set("v", "<leader>y", require("osc52").copy_visual)
          '';
        }

        {
          plugin = pkgs.vimPlugins.telescope-nvim;
          type = "lua";
          config = ''
            require("telescope").setup({
              defaults = {
                file_ignore_patterns = { "^%.direnv/" },
              },
            })

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
            vim.keymap.set("n", "<leader>fw", builtin.live_grep, { desc = "Telescope live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
          '';
        }

        {
          plugin = pkgs.vimPlugins.nord-nvim;
          type = "lua";
          config = ''
            vim.cmd("colorscheme nord")
            vim.cmd(":hi statusline guibg=NONE")
          '';
        }
      ];
    };
}
