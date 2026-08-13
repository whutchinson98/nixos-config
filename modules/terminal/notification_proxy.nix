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
      options.dotfiles.notificationProxy = {
        startServer = lib.mkEnableOption "the notification proxy user service";
        listenAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:50051";
          description = "Socket address on which the notification proxy service listens";
        };
      };

      config = {
        home.packages = [ notificationProxy ];

        systemd.user.services.notification-proxy = lib.mkIf config.dotfiles.notificationProxy.startServer {
          Unit = {
            Description = "Notification proxy server";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${notificationProxy}/bin/notification-proxy serve --listen ${config.dotfiles.notificationProxy.listenAddress}";
            Restart = "on-failure";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
