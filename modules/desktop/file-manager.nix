# Nautilus + rclone bisync of ~/org with Proton Drive
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    let
      rcloneBin = "${pkgs.rclone}/bin/rclone";

      syncOrgProton = pkgs.writeShellScriptBin "sync-org-proton" ''
        set -euo pipefail

        mkdir -p "$HOME/org" "$HOME/.local/state"

        ${rcloneBin} mkdir protondrive:org
        ${rcloneBin} bisync "$HOME/org" protondrive:org \
          --create-empty-src-dirs \
          --recover \
          --resilient \
          --conflict-resolve newer \
          --conflict-loser pathname \
          --log-file "$HOME/.local/state/rclone-org-bisync.log" \
          --log-level INFO
      '';

      initOrgProtonBisync = pkgs.writeShellScriptBin "init-org-proton-bisync" ''
        set -euo pipefail

        mkdir -p "$HOME/org" "$HOME/.local/state"

        ${rcloneBin} mkdir protondrive:org
        ${rcloneBin} bisync "$HOME/org" protondrive:org \
          --resync \
          --resync-mode newer \
          --create-empty-src-dirs \
          --recover \
          --resilient \
          --conflict-resolve newer \
          --conflict-loser pathname \
          --log-file "$HOME/.local/state/rclone-org-bisync.log" \
          --log-level INFO
      '';
    in
    {
      home.packages = with pkgs; [
        nautilus
        pkgs.rclone
        syncOrgProton
        initOrgProtonBisync
      ];

      systemd.user.services.rclone-org-bisync = {
        Unit = {
          Description = "Bisync ~/org with Proton Drive";
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${syncOrgProton}/bin/sync-org-proton";
        };
      };

      systemd.user.timers.rclone-org-bisync = {
        Unit = {
          Description = "Run rclone org bisync every 10 minutes";
        };

        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "10min";
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
}
