# Bitwarden — desktop app and CLI
{ config, ... }:
{
  flake.modules.nixos.bitwarden = {
    home-manager.users.hutch.imports = [ config.flake.modules.homeManager.bitwarden ];
  };
  flake.modules.homeManager.bitwarden =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
        bitwarden-cli
      ];
    };
}
