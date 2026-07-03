# Bluetooth support — BlueZ with Wayland-friendly GUI/TUI managers
{
  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    let
      bluetooth-manager = pkgs.writeShellApplication {
        name = "bluetooth-manager";
        runtimeInputs = with pkgs; [
          bluetuith
          overskride
        ];
        text = ''
          if [ -n "''${WAYLAND_DISPLAY:-}''${DISPLAY:-}" ]; then
            exec overskride "$@"
          fi

          exec bluetuith "$@"
        '';
      };
    in
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            ControllerMode = "dual";
            Experimental = true;
            FastConnectable = true;
          };
          Policy.AutoEnable = true;
        };
      };

      services.dbus.enable = true;
      services.upower.enable = true;

      environment.systemPackages = with pkgs; [
        bluetooth-manager
        bluetuith
        bluez
        bluez-tools
        overskride
      ];
    };
}
