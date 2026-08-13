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

      options.dotfiles.tailscale.trusted = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Trust the tailscale0 interface in the firewall (server hosts)";
      };

      config.services.tailscale = {
        enable = true;
        useRoutingFeatures = if cfg.sshMode then "both" else "client";
        extraUpFlags = lib.optionals cfg.sshMode [
          "--ssh"
          "--operator=hutch"
        ];
      };

      config.networking.firewall = lib.mkIf cfg.trusted {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ 41641 ]; # Tailscale WireGuard port
      };
    };
}
