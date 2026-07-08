# Niri desktop environment — Wayland compositor. System side enables the
# compositor + polkit; home side carries the full niri configuration.
# (Niri is launched from fish loginShellInit on TTY1 — see terminal/fish.nix.)
{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    programs.niri.enable = true;
    security.polkit.enable = true;
  };

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      imports = [
        inputs.niri.homeModules.niri
      ];

      home.packages = with pkgs; [
        swaylock
        fuzzel
        xwayland-satellite
        inputs.nirijump.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      programs.niri = {
        package = pkgs.niri.overrideAttrs (old: {
          doCheck = false;
        });

        settings = {
          input = {
            keyboard = {
              xkb.options = "caps:escape";
              numlock = true;
            };

            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };

          outputs = {
            "DP-1" = {
              mode = {
                width = 2560;
                height = 1440;
                refresh = 144.006;
              };
            };
          };

          layout = {
            gaps = 16;
            center-focused-column = "never";

            preset-column-widths = [
              { proportion = 0.33333; }
              { proportion = 0.5; }
              { proportion = 0.66667; }
            ];

            default-column-width = {
              proportion = 0.5;
            };

            focus-ring = {
              enable = true;
              width = 4;
            };

            border = {
              enable = false;
            };
          };

          spawn-at-startup = [
            { command = [ "xwayland-satellite" ]; }
            { command = [ "lxqt-policykit-agent" ]; }
            { command = [ "1password" ]; }
            # { command = [ "zen-beta" ]; }
            # { command = [ "alacritty" ]; }
          ];

          environment = {
            DISPLAY = ":0";
          };

          screenshot-path = "~/screenshots/%Y-%m-%d %H-%M-%S.png";

          switch-events = {
            lid-close.action.spawn = [
              "sh"
              "-c"
              "niri msg output eDP-1 off"
            ];
            lid-open.action.spawn = [
              "sh"
              "-c"
              "niri msg output eDP-1 on"
            ];
          };

          workspaces = {
            "01-browser" = {
              name = "browser";
            };
            "02-code" = {
              name = "code";
            };
            "03-chat" = {
              name = "chat";
            };
            "04-recording" = {
              name = "recording";
            };
            "05-misc" = {
              name = "misc";
            };
          };

          debug = {
            honor-xdg-activation-with-invalid-serial = true;
          };

          window-rules = [
            {
              matches = [ { app-id = "^nirijump$"; } ];
              open-floating = true;
              default-column-width.fixed = 800;
              default-window-height.fixed = 500;
            }
            {
              matches = [ { app-id = "^mako-tui$"; } ];
              open-floating = true;
              default-column-width.fixed = 800;
              default-window-height.fixed = 500;
            }
            {
              matches = [ { app-id = "Alacritty"; } ];
              open-on-workspace = "code";
            }
            {
              matches = [ { app-id = "Emacs"; } ];
              open-on-workspace = "code";
            }
            {
              matches = [ { app-id = "zen"; } ];
              open-on-workspace = "browser";
            }
            {
              matches = [ { app-id = "Brave-browser"; } ];
              open-on-workspace = "browser";
            }
            {
              matches = [ { app-id = "com.obsproject.Studio"; } ];
              open-on-workspace = "recording";
            }
            {
              matches = [ { app-id = "signal"; } ];
              open-on-workspace = "chat";
              open-focused = true;
            }
            {
              matches = [ { app-id = "discord"; } ];
              open-on-workspace = "chat";
              open-focused = true;
            }
            {
              matches = [ { app-id = "Proton Mail"; } ];
              open-on-workspace = "chat";
              open-focused = true;
            }
            {
              matches = [ { app-id = "Spotify"; } ];
              open-on-workspace = "misc";
              open-focused = true;
            }
          ];

          binds = {
            "Super+O".action.toggle-overview = { };
            "Mod+Shift+Slash".action.show-hotkey-overlay = { };
            "Mod+E".action.spawn = [
              "emacsclient"
              "-c"
              "-n"
              "-a"
              ""
            ];
            "Mod+Alt+E".action.spawn = [
              "sh"
              "-lc"
              "systemctl --user restart emacs.service"
            ];
            "Mod+T".action.spawn = [ "alacritty" ];
            "Mod+P".action.spawn = [ "fuzzel" ];
            "Mod+N".action.spawn = [
              "alacritty"
              "--class"
              "nirijump"
              "-e"
              "nirijump"
            ];
            "Mod+M".action.spawn = [
              "alacritty"
              "--class"
              "mako-tui"
              "-e"
              "mako-tui"
            ];
            "Super+Alt+L".action.spawn = [ "swaylock" ];
            "Mod+Q".action.close-window = { };
            "Mod+H".action.focus-column-left = { };
            "Mod+J".action.focus-window-down = { };
            "Mod+K".action.focus-window-up = { };
            "Mod+L".action.focus-column-right = { };

            "Mod+Ctrl+H".action.move-column-left = { };
            "Mod+Ctrl+J".action.move-window-down = { };
            "Mod+Ctrl+K".action.move-window-up = { };
            "Mod+Ctrl+L".action.move-column-right = { };

            "Mod+1".action.focus-workspace = "browser";
            "Mod+2".action.focus-workspace = "code";
            "Mod+3".action.focus-workspace = "chat";
            "Mod+4".action.focus-workspace = "recording";
            "Mod+5".action.focus-workspace = "misc";
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            "Mod+Shift+1".action.move-column-to-workspace = "browser";
            "Mod+Shift+2".action.move-column-to-workspace = "code";
            "Mod+Shift+3".action.move-column-to-workspace = "chat";
            "Mod+Shift+4".action.move-column-to-workspace = "recording";
            "Mod+Shift+5".action.move-column-to-workspace = "misc";
            "Mod+Shift+6".action.move-column-to-workspace = 6;
            "Mod+Shift+7".action.move-column-to-workspace = 7;
            "Mod+Shift+8".action.move-column-to-workspace = 8;
            "Mod+Shift+9".action.move-column-to-workspace = 9;

            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
            "Mod+Ctrl+Left".action.focus-monitor-left = { };
            "Mod+Ctrl+Right".action.focus-monitor-right = { };

            "Mod+C".action.center-column = { };
            "Mod+F".action.maximize-column = { };
            "Mod+Shift+F".action.fullscreen-window = { };
            "Mod+B".action.screenshot = { };
            "XF86MonBrightnessUp".action.spawn = [
              "brightnessctl"
              "set"
              "+5%"
            ];
            "XF86MonBrightnessDown".action.spawn = [
              "brightnessctl"
              "set"
              "5%-"
            ];
            "XF86AudioRaiseVolume".action.spawn = [
              "wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "5%+"
            ];
            "XF86AudioLowerVolume".action.spawn = [
              "wpctl"
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "5%-"
            ];
            "XF86AudioMute".action.spawn = [
              "wpctl"
              "set-mute"
              "@DEFAULT_AUDIO_SINK@"
              "toggle"
            ];

            "Mod+Shift+E".action.quit = { };
          };
        };
      };
    };
}
