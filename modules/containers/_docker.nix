# Docker — rootless container runtime. Parked: the underscore prefix keeps
# import-tree from loading this file (podman with dockerCompat covers both
# machines). Rename to docker.nix and add `docker` to a host's module list to
# re-enable.
{
  flake.modules.nixos.docker =
    { pkgs, ... }:
    {
      users.groups.docker = { };
      environment.systemPackages = with pkgs; [
        docker
        docker-buildx
      ];
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
        rootless.enable = true;
      };
      users.users.hutch.extraGroups = [ "docker" ];
    };
}
