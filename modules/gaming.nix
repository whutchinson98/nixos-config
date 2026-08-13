# Steam
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {

      environment.systemPackages = with pkgs; [
        protontricks
        protonup-qt
        wineWow64Packages.staging
        winetricks
      ];

      programs.steam = {
        enable = true;
        package = pkgs.stable.steam;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
    };
}
