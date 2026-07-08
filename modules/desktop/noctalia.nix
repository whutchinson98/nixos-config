{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { config, ... }:
    {
      # import the home manager module
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # configure options
      programs.noctalia-shell = {
        enable = true;
        settings = {
          wallpaper = {
            enabled = true;
            directory = "${config.home.homeDirectory}/backgrounds";
            default.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            last.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            monitors = {
              DP-1.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            };
          };
          appLauncher = {
            enableClipboardHistory = false;
            autoPasteClipboard = false;
            enableClipPreview = true;
            clipboardWrapText = true;
            enableClipboardSmartIcons = true;
            enableClipboardChips = true;
            clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
            clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
            position = "center";
            pinnedApps = [ ];
            sortByMostUsed = true;
            terminalCommand = "alacritty -e";
            customLaunchPrefixEnabled = false;
            customLaunchPrefix = "";
            viewMode = "list";
            showCategories = true;
            iconMode = "tabler";
            showIconBackground = false;
            enableSettingsSearch = true;
            enableWindowsSearch = true;
            enableSessionSearch = true;
            ignoreMouseInput = false;
            screenshotAnnotationTool = "";
            overviewLayer = false;
            density = "default";
          };
          shell = {
            font_family = "GeistMono Nerd Font";
            launch_apps_as_systemd_services = true;
            niri_overview_type_to_launch_enabled = true;
            polkit_agent = true;
            panel = {
              clipboard_placement = "attached";
              transparency_mode = "glass";
            };
          };
          notifications = {
            enabled = true;
            enableMarkdown = false;
            density = "default";
            monitors = [ ];
            location = "top_right";
            overlayLayer = true;
            backgroundOpacity = 1;
            respectExpireTimeout = false;
            lowUrgencyDuration = 3;
            normalUrgencyDuration = 8;
            criticalUrgencyDuration = 15;
            clearDismissed = true;
            saveToHistory = {
              low = true;
              normal = true;
              critical = true;
            };
            sounds = {
              enabled = false;
              volume = 0.5;
              separateSounds = false;
              criticalSoundFile = "";
              normalSoundFile = "";
              lowSoundFile = "";
              excludedApps = "discord,firefox,chrome,chromium,edge";
            };
            enableMediaToast = false;
            enableKeyboardLayoutToast = true;
            enableBatteryToast = true;
          };

          # configure noctalia here
          bar = {
            density = "compact";
            position = "top";
            showCapsule = false;

            widgets = {
              left = [
                {
                  id = "ControlCenter";
                  useDistroLogo = true;
                }
                {
                  id = "Network";
                }
              ];
              center = [
                {
                  hideUnoccupied = false;
                  id = "Workspace";
                  labelMode = "none";
                }
              ];
              right = [
                {
                  alwaysShowPercentage = false;
                  id = "Battery";
                  warningThreshold = 30;
                }
                {
                  formatHorizontal = "HH:mm";
                  formatVertical = "HH mm";
                  id = "Clock";
                  useMonospacedFont = true;
                  usePrimaryColor = true;
                }
                {
                  id = "Notifications";
                }
              ];
            };
          };
          colorSchemes.predefinedScheme = "Nord";
          location = {
            monthBeforeDay = true;
            name = "Ontario, Canada";
          };
        };
      };
    };
}
