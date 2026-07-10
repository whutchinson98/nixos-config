# Zephyr — Framework 13 AMD laptop
{ inputs, config, ... }:
{
  flake.nixosConfigurations.zephyr = inputs.nixpkgs.lib.nixosSystem {
    modules =
      (with config.flake.modules.nixos; [
        base
        amd
        hutch
        terminal
        dev
        onepassword
        desktop
        audio
        bluetooth
        tailscale
        podman
        fingerprint
        power
      ])
      ++ [
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        ./_hardware.nix
        {
          networking.hostName = "zephyr";
          nixpkgs.hostPlatform = "x86_64-linux";

          services.fwupd.enable = true;
        }
      ];
  };
}
