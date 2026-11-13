# Shared runtime for personal services. Every file in services/ contributes to
# this module; Forge imports it once to enable the whole stack.
{ config, ... }:
{
  flake.modules.nixos.services =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.nixos.podman ];

      virtualisation.oci-containers.backend = "podman";

      # Containers opt into this network with networks = [ "services" ].
      # Keep it across service restarts so other containers stay connected.
      systemd.services.podman-network-services = {
        description = "Shared network for personal services";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.podman}/bin/podman network create --ignore services";
        };
      };
    };
}
