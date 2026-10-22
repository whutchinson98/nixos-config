{
  flake.modules.homeManager.desktop = {
    programs.alacritty = {
      enable = true;
      settings = {
        terminal.shell.program = "fish";
        env = {
          TERM = "screen-256color";
        };

        window = {
          decorations = "none";
          # opacity = 0.9;
        };

        font = {
          size = 10;
          normal = {
            family = "GeistMono Nerd Font";
            style = "Regular";
          };
          bold = {
            family = "GeistMono Nerd Font";
            style = "Bold";
          };
          italic = {
            family = "GeistMono Nerd Font";
            style = "Italic";
          };
        };

        selection = {
          save_to_clipboard = true;
        };

        terminal = {
          osc52 = "CopyPaste";
        };

        keyboard = {
          bindings = [
            {
              key = "Space";
              mods = "Control";
              action = "ToggleViMode";
            }
          ];
        };

        # Gruvbox dark palette
        colors = {
          primary = {
            background = "#282828";
            foreground = "#ebdbb2";
          };

          cursor = {
            text = "#282828";
            cursor = "#ebdbb2";
          };

          vi_mode_cursor = {
            text = "#282828";
            cursor = "#fabd2f";
          };

          selection = {
            text = "CellForeground";
            background = "#504945";
          };

          normal = {
            black = "#282828";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#a89984";
          };

          bright = {
            black = "#928374";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
            white = "#ebdbb2";
          };
        };
      };
    };
  };
}
