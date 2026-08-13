# Uptime Kuma — self-hosted uptime monitoring; importing the module enables it
{
  flake.modules.nixos.uptime-kuma =
    { config, lib, ... }:
    let
      cfg = config.dotfiles.uptime-kuma;
    in
    {
      options.dotfiles.uptime-kuma.port = lib.mkOption {
        type = lib.types.port;
        default = 3001;
        description = "Port for Uptime Kuma web UI";
      };

      config = {
        services.uptime-kuma = {
          enable = true;
          settings.PORT = toString cfg.port;
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
      };
    };
}
