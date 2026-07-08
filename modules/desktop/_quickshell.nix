# QuickShell status bar + reload-on-wake/hotplug watcher
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.quickshell ];

      xdg.configFile."quickshell/shell.qml".source = ../../configs/quickshell/shell.qml;

      systemd.user.services.quickshell = {
        Unit = {
          Description = "QuickShell status bar";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.quickshell}/bin/quickshell";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      systemd.user.services.quickshell-reload = {
        Unit = {
          Description = "Reload QuickShell on wake or display change";
          After = [
            "quickshell.service"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.writeShellScript "quickshell-reload" ''
            LOCKFILE="/tmp/quickshell-reload.lock"

            do_restart() {
              (
                ${pkgs.util-linux}/bin/flock -xn 200 || exit 0
                sleep 2
                ${pkgs.systemd}/bin/systemctl --user restart quickshell.service
                sleep 3
              ) 200>"$LOCKFILE"
            }

            # Sleep/wake monitor
            ${pkgs.dbus}/bin/dbus-monitor --system \
              "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" 2>/dev/null | \
              while IFS= read -r line; do
                if [[ "$line" == *"boolean false"* ]]; then
                  do_restart
                fi
              done &

            # Display hotplug monitor
            ${pkgs.systemd}/bin/udevadm monitor --property --subsystem-match=drm 2>/dev/null | \
              while IFS= read -r line; do
                if [[ "$line" == *"HOTPLUG=1"* ]]; then
                  do_restart
                fi
              done &

            wait
          ''}";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
