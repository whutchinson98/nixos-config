# Notification Proxy
{ inputs, ... }:
{
  flake.modules.homeManager.terminal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      notificationProxy = inputs.notification-proxy.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.dotfiles.notificationProxy.startServer = lib.mkEnableOption "the notification proxy user service";

      config = {
        home.packages = [ notificationProxy ];

        systemd.user.services.notification-proxy = lib.mkIf config.dotfiles.notificationProxy.startServer {
          Unit = {
            Description = "Notification proxy server";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${notificationProxy}/bin/notification-proxy serve";
            Restart = "on-failure";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
