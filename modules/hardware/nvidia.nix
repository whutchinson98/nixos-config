# NVIDIA graphics — proprietary driver
{
  flake.modules.nixos.nvidia =
    { config, pkgs, ... }:
    {
      # The stable NVIDIA driver lags linuxPackages_latest; stay on the
      # default kernel (base sets latest via mkDefault)
      boot.kernelPackages = pkgs.linuxPackages;

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics.enable = true;

      hardware.nvidia = {
        open = false;
        modesetting.enable = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };
}
