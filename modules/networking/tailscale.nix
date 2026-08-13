# Tailscale VPN — hosts import this module; sshMode stays an option for
# per-host variation within the aspect
{
  flake.modules.nixos.tailscale =
    { config, lib, ... }:
    let
      cfg = config.dotfiles.tailscale;
    in
    {
      options.dotfiles.tailscale.sshMode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Tailscale SSH with --operator=hutch";
      };

      config.services.tailscale = {
        enable = true;
        useRoutingFeatures = if cfg.sshMode then "both" else "client";
        extraUpFlags = lib.optionals cfg.sshMode [
          "--ssh"
          "--operator=hutch"
        ];
      };
    };
}
