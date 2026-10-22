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
        # Keep Steam's runtime libraries aligned with the system graphics drivers.
        package = pkgs.steam;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
    };
}
