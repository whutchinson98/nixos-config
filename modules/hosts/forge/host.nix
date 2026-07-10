# Forge — Mini PC server
{ inputs, config, ... }:
{
  flake.nixosConfigurations.forge = inputs.nixpkgs.lib.nixosSystem {
    modules =
      (with config.flake.modules.nixos; [
        base
        amd
        hutch
        terminal
        dev
        tailscale
        podman
      ])
      ++ [
        ./_hardware.nix
        {
          networking.hostName = "forge";
          nixpkgs.hostPlatform = "x86_64-linux";

          services.openssh.enable = true;

          dotfiles.tailscale.sshMode = true;
          dotfiles.tmux.prefix = "C-b";

          home-manager.users.hutch = {
            dotfiles.aws.credentialProvider = "default-chain";

            programs.ssh = {
              enable = true;
            };
          };
        }
      ];
  };
}
