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

        # Doom Nord palette
        colors = {
          primary = {
            background = "#2E3440";
            foreground = "#ECEFF4";
          };

          cursor = {
            text = "#2E3440";
            cursor = "#81A1C1";
          };

          vi_mode_cursor = {
            text = "#2E3440";
            cursor = "#88C0D0";
          };

          selection = {
            text = "CellForeground";
            background = "#434C5E";
          };

          normal = {
            black = "#2E3440";
            red = "#BF616A";
            green = "#A3BE8C";
            yellow = "#EBCB8B";
            blue = "#81A1C1";
            magenta = "#B48EAD";
            cyan = "#88C0D0";
            white = "#D8DEE9";
          };

          bright = {
            black = "#9099AB";
            red = "#C87880";
            green = "#B0C79D";
            yellow = "#EDD29C";
            blue = "#93AFCA";
            magenta = "#BF9EB9";
            cyan = "#99C9D7";
            white = "#F0F4FC";
          };
        };
      };
    };
  };
}
