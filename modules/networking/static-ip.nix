# Static IP configuration — parameterized per host via dotfiles.network
{
  flake.modules.nixos.static-ip =
    { config, lib, ... }:
    let
      cfg = config.dotfiles.network;
    in
    {
      options.dotfiles.network = {
        hostAddress = lib.mkOption {
          type = lib.types.str;
          description = "Static IP address for this host";
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = "enp1s0";
          description = "Primary network interface name";
        };
        gateway = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.1";
          description = "Default gateway";
        };
        nameservers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "1.1.1.1"
            "9.9.9.9"
          ];
          description = "DNS servers";
        };
      };

      config.networking = {
        # Static addressing replaces NetworkManager (base sets it mkDefault)
        networkmanager.enable = false;
        useDHCP = false;
        interfaces.${cfg.interface} = {
          ipv4.addresses = [
            {
              address = cfg.hostAddress;
              prefixLength = 24;
            }
          ];
        };
        defaultGateway = cfg.gateway;
        nameservers = cfg.nameservers;
      };
    };
}
