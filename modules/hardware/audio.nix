# PipeWire audio stack
{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.pavucontrol ];
      services.dbus.enable = true;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
    };
}
