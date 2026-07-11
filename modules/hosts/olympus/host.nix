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
          home-manager.users.hutch.dotfiles = {
            aws.credentialProvider = "onepassword";
            jujutsu.sshSigning.enable = true;
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
