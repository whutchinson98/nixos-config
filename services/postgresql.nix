# Persistent PostgreSQL; configuration and container lifecycle are declarative,
# while database files and the bootstrap password live outside the Nix store.
{
  flake.modules.nixos.services =
    { pkgs, ... }:
    let
      dataDir = "/var/lib/services/postgresql";
      passwordFile = "/var/lib/services/postgresql-secrets/password";
    in
    {
      systemd.tmpfiles.rules = [
        "d /var/lib/services 0755 root root -"
        # The container's postgres user must traverse this parent directory;
        # its entrypoint makes the actual PGDATA subdirectory private (0700).
        "d ${dataDir} 0755 root root -"
      ];

      systemd.services.postgresql-password = {
        description = "Initialize the PostgreSQL bootstrap password";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "services/postgresql-secrets";
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
        # Write atomically, and preserve the password on subsequent boots.
        script = ''
          if [ ! -e ${passwordFile} ]; then
            ${pkgs.openssl}/bin/openssl rand -hex 32 > ${passwordFile}.tmp
            mv ${passwordFile}.tmp ${passwordFile}
          fi
        '';
      };

      virtualisation.oci-containers.containers.postgresql = {
        # Stay on this major version until an explicit database migration.
        image = "docker.io/library/postgres:18";
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "postgres";
          POSTGRES_PASSWORD_FILE = "/run/secrets/postgresql-password";
          POSTGRES_INITDB_ARGS = "--auth-host=scram-sha-256";
        };
        volumes = [
          # PostgreSQL 18+ stores PGDATA in a versioned subdirectory here.
          "${dataDir}:/var/lib/postgresql"
          "${passwordFile}:/run/secrets/postgresql-password:ro"
        ];
        ports = [ "127.0.0.1:5432:5432" ];
        networks = [ "services" ];
        podman.sdnotify = "healthy";
        extraOptions = [
          "--health-cmd=pg_isready -h 127.0.0.1 -U postgres -d postgres"
          "--health-interval=10s"
          "--health-start-period=30s"
          "--health-retries=5"
          "--health-on-failure=kill"
        ];
      };

      systemd.services.podman-postgresql = {
        requires = [
          "podman-network-services.service"
          "postgresql-password.service"
        ];
        after = [
          "podman-network-services.service"
          "postgresql-password.service"
          "systemd-tmpfiles-setup.service"
        ];
        unitConfig.RequiresMountsFor = [
          dataDir
          "/var/lib/services/postgresql-secrets"
        ];
      };
    };
}
