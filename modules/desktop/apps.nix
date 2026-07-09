# Desktop GUI applications
{ inputs, ... }: {
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        inputs.macro.packages.${pkgs.system}.tauri-desktop
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
