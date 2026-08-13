# Development CLI tools
{ config, ... }:
{
  flake.modules.nixos.dev = {
    home-manager.users.hutch.imports = [ config.flake.modules.homeManager.dev ];
  };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nixd
        nixfmt
        doppler
        podman-compose
        sops
        age
        ssh-to-age
      ];
    };
}
