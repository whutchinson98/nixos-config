# Baseline system packages every host gets
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        vim
        wget
        curl
        git
        unzip
        zip
        gcc
      ];
    };
}
