# Bootloader and kernel
{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      # mkDefault so hosts pinned to another kernel (e.g. nvidia) can override
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.configurationLimit = 5;
    };
}
