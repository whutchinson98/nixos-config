# Linux gaming stack — Steam, Proton, Wine, and helper tools. Importing the
# module turns the stack on; the dotfiles.gaming.* options remain for
# per-host variation within the aspect.
{
  flake.modules.nixos.gaming =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dotfiles.gaming;
    in
    {
      options.dotfiles.gaming = {
        steam = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Steam and Steam hardware support.";
          };

          remotePlay.openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open firewall ports for Steam Remote Play.";
          };

          dedicatedServer.openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open firewall ports for Steam dedicated servers.";
          };

          localNetworkGameTransfers.openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Open firewall ports for Steam local network game transfers.";
          };
        };

        proton.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Proton helpers and add GE-Proton to Steam.";
        };

        wine.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Wine and Winetricks.";
        };

        launchers.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install common non-Steam game launchers.";
        };

        performance.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GameMode and install performance/overlay helpers.";
        };

        controllerSupport.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install udev rules for Steam and common game controllers.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          example = lib.literalExpression "with pkgs; [ prismlauncher ]";
          description = "Additional gaming packages to install.";
        };
      };

      config = lib.mkMerge [
        {
          hardware.graphics = {
            enable = true;
            enable32Bit = true;
          };

          environment.systemPackages =
            lib.optionals cfg.proton.enable (
              with pkgs;
              [
                protontricks
                protonup-qt
              ]
            )
            ++ lib.optionals cfg.wine.enable (
              with pkgs;
              [
                wineWow64Packages.staging
                winetricks
              ]
            )
            ++ lib.optionals cfg.launchers.enable (
              with pkgs;
              [
                bottles
                heroic
                lutris
              ]
            )
            ++ lib.optionals cfg.performance.enable (
              with pkgs;
              [
                gamescope
                mangohud
              ]
            )
            ++ cfg.extraPackages;
        }

        (lib.mkIf cfg.steam.enable {
          programs.steam = {
            enable = true;
            package = pkgs.stable.steam;
            remotePlay.openFirewall = cfg.steam.remotePlay.openFirewall;
            dedicatedServer.openFirewall = cfg.steam.dedicatedServer.openFirewall;
            localNetworkGameTransfers.openFirewall = cfg.steam.localNetworkGameTransfers.openFirewall;
            extraCompatPackages = lib.optionals cfg.proton.enable [ pkgs.proton-ge-bin ];
          };
        })

        (lib.mkIf cfg.performance.enable {
          programs.gamemode.enable = true;
          programs.gamescope = {
            enable = true;
            capSysNice = true;
          };

          # Helpful for newer Proton titles and large-memory games.
          boot.kernel.sysctl."vm.max_map_count" = 2147483642;
        })

        (lib.mkIf cfg.controllerSupport.enable {
          hardware.steam-hardware.enable = true;
          services.udev.packages = [ pkgs.game-devices-udev-rules ];
        })
      ];
    };
}
