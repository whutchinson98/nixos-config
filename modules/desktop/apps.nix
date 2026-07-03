# Desktop GUI applications
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        notify
        signal-desktop
        bruno
        stable.spotify
        networkmanagerapplet
        obs-studio
        libnotify
        ledger-live-desktop
        dbeaver-bin
        proton-vpn-cli
        brightnessctl
      ];
    };
}
