# Podman — daemonless container runtime
{
  flake.modules.nixos.podman =
    { pkgs, ... }:
    {
      users.users.hutch.extraGroups = [ "podman" ];

      environment.systemPackages = with pkgs; [
        buildah
        skopeo
      ];

      home-manager.users.hutch.xdg.configFile."containers/containers.conf".text = ''
        [engine]
        compose_warning_logs = false
      '';

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
}
