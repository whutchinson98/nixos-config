# Development CLI tools
{
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
