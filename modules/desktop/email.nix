# Email — neomutt/mu/isync with Proton Mail Bridge
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        neomutt
        protonmail-bridge
        mu
        isync
        msmtp
        gnutls
      ];

      # 1144 IMAP
      # 1026 SMTP
      systemd.user.services.protonmail-bridge = {
        Unit = {
          Description = "Proton Mail Bridge";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
