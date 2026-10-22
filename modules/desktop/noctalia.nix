{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { config, ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        settings = {
          shell = {
            font_family = "GeistMono Nerd Font";
            clipboard_enabled = false;
            niri_overview_type_to_launch_enabled = true;
            polkit_agent = true;

            panel = {
              clipboard_placement = "attached";
              transparency_mode = "glass";
            };

            launcher = {
              app_grid = false;
              pinned = [ ];
              sort_by_usage = true;
            };
          };

          wallpaper = {
            enabled = true;
            directory = "${config.home.homeDirectory}/backgrounds";
            default.path = "${config.home.homeDirectory}/backgrounds/nord.png";
          };

          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Nord";
          };

          notification = {
            enable_daemon = true;
            keep_dismissed_in_history = true;
            layer = "overlay";
            background_opacity = 1.0;
          };

          audio.enable_sounds = false;

          location = {
            auto_locate = false;
            address = "Ontario, Canada";
          };

          bar.main = {
            position = "top";
            capsule = false;
            scale = 0.9;
            start = [
              "control-center"
              "network"
            ];
            center = [ "workspaces" ];
            end = [
              "battery"
              "clock"
              "notifications"
            ];
          };

          widget = {
            workspaces = {
              show_labels = false;
              hide_when_empty = false;
            };
            clock = {
              format = "{:%Y-%m-%d %H:%M}";
              vertical_format = "{:%H\n%M}";
            };
          };
        };
      };
    };
}
