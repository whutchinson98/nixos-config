# Laptop power management — s2idle suspend + lid close handling
{
  flake.modules.nixos.power = {
    # Lid close → suspend
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    # Kernel params for better s2idle on AMD
    boot.kernelParams = [
      "rtc_cmos.use_acpi_alarm=1"
    ];

    # Disable USB/XHC wake sources that cause spurious wakes during s2idle
    services.udev.extraRules = ''
      # Disable XHC (USB controller) wake sources to prevent s2idle battery drain
      SUBSYSTEM=="pci", ATTR{power/wakeup}=="enabled", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
    '';

    # Runtime power management for PCI devices
    powerManagement.enable = true;

    # Aggressive power saving during suspend via tmpfiles
    systemd.tmpfiles.rules = [
      # Enable runtime PM for all PCI devices
      "w /sys/bus/pci/devices/*/power/control - - - - auto"
      # Enable audio codec power management
      "w /sys/module/snd_hda_intel/parameters/power_save - - - - 1"
    ];
  };
}
