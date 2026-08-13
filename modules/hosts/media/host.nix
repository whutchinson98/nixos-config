# Media — dedicated media server (Jellyfin + *arr stack), not a desktop
{ inputs, config, ... }:
{
  flake.nixosConfigurations.media = inputs.nixpkgs.lib.nixosSystem {
    modules =
      (with config.flake.modules.nixos; [
        base
        server
        hutch
        static-ip
        sops
        tailscale
        uptime-kuma
        media-stack
        nvidia
      ])
      ++ [
        ./_hardware.nix
        {
          networking.hostName = "media";
          nixpkgs.hostPlatform = "x86_64-linux";

          # hutch's login shell is fish; this host skips the full terminal
          # module, so enable the shell at the system level here
          programs.fish.enable = true;

          dotfiles.network = {
            hostAddress = "192.168.1.102";
            interface = "enp5s0";
          };

          dotfiles.tailscale = {
            sshMode = true;
            trusted = true;
          };

          # Two data disks pooled into /mnt/media via mergerfs
          fileSystems."/mnt/disk1" = {
            device = "/dev/disk/by-uuid/10e1b2c0-6ffb-4ac6-8bca-83c3ca708c3a";
            fsType = "ext4";
          };

          fileSystems."/mnt/disk2" = {
            device = "/dev/disk/by-uuid/744b4811-b7f2-48ab-803a-09a84912031d";
            fsType = "ext4";
          };

          fileSystems."/mnt/media" = {
            device = "/mnt/disk1:/mnt/disk2";
            fsType = "fuse.mergerfs";
            options = [
              "defaults"
              "allow_other"
              "use_ino"
              "category.create=mfs"
              "moveonenospc=true"
              "dropcacheonclose=true"
              "fsname=mergerfs"
            ];
            depends = [
              "/mnt/disk1"
              "/mnt/disk2"
            ];
          };
        }
      ];
  };
}
