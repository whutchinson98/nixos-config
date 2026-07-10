# Olympus — AMD desktop
{ inputs, config, ... }:
{
  flake.nixosConfigurations.olympus = inputs.nixpkgs.lib.nixosSystem {
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
        tailscale
        podman
        gaming
        zsa-keyboard
      ])
      ++ [
        ./_hardware.nix
        {
          networking.hostName = "olympus";
          nixpkgs.hostPlatform = "x86_64-linux";

          dotfiles.tailscale.sshMode = true;

          # Steam's bundled 32-bit PulseAudio client crashes while enumerating this
          # AMD HDMI/DisplayPort audio device via pipewire-pulse. The system uses the
          # HyperX USB device as the default sink/source, so hide only this bad card
          # from WirePlumber/PipeWire instead of disabling audio globally.
          services.pipewire.wireplumber.extraConfig."99-disable-radeon-hdmi-audio" = {
            "monitor.alsa.rules" = [
              {
                matches = [
                  { "device.name" = "alsa_card.pci-0000_65_00.1"; }
                ];
                actions.update-props."device.disabled" = true;
              }
            ];
          };

          # Host-specific home config rides along in the host module
          home-manager.users.hutch.dconf.settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
            };
          };
        }
      ];
  };
}
