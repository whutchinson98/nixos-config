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
        wl-clipboard
        unzip
        zip
        gcc
        lxqt.lxqt-policykit
        pavucontrol
      ];
    };
}
