# Media stack — nixarr services, Caddy reverse proxy, firewall, and directory
# structure. Secrets: cloudflare_api_token from secrets/media.yaml (sops);
# the WireGuard config lives on-host at /data/secrets/wireguard.conf.
{ inputs, ... }:
let
  domain = "thehutchery.media";
  tlsConfig = ''
    tls {
      dns cloudflare {env.CF_API_TOKEN}
      resolvers 1.1.1.1
    }
  '';
  proxiedServices = {
    jellyfin = 8096;
    jellyseerr = 5055;
    radarr = 7878;
    sonarr = 8989;
    bazarr = 6767;
    prowlarr = 9696;
    sabnzbd = 6336;
    transmission = 9091;
    uptime = 3001;
  };
in
{
  flake.modules.nixos.media-stack =
    { pkgs, config, ... }:
    {
      imports = [ inputs.nixarr.nixosModules.default ];

      # mergerfs pool mounts (declared per-host) need FUSE
      boot.supportedFilesystems = [ "fuse" ];

      sops = {
        defaultSopsFile = ../../secrets/media.yaml;
        secrets.cloudflare_api_token = { };
      };

      services.flaresolverr.enable = true;

      nixarr = {
        enable = true;
        mediaDir = "/mnt/media";
        stateDir = "/data/.state/nixarr";

        vpn = {
          enable = true;
          wgConf = "/data/secrets/wireguard.conf";
          vpnTestService.enable = true;
        };

        jellyfin.enable = true;
        jellyseerr.enable = true;

        bazarr.enable = true;
        radarr.enable = true;
        sonarr.enable = true;
        prowlarr.enable = true;

        sabnzbd = {
          enable = true;
          vpn.enable = true;
        };

        transmission = {
          enable = true;
          vpn.enable = true;
          extraSettings = {
            rpc-bind-address = "0.0.0.0";
            rpc-whitelist-enabled = false;
            rpc-host-whitelist-enabled = false;
          };
        };
      };

      # Service users share the media group for pool access; jellyfin also
      # needs the GPU for transcoding
      users.users.jellyfin.extraGroups = [
        "video"
        "render"
        "media"
      ];
      users.users.radarr.extraGroups = [ "media" ];
      users.users.sonarr.extraGroups = [ "media" ];
      users.users.transmission.extraGroups = [ "media" ];
      users.users.sabnzbd.extraGroups = [ "media" ];

      # Caddy reverse proxy — routes subdomains to local services with
      # automatic HTTPS via Cloudflare DNS challenge
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
          hash = "sha256-Olz4W84Kiyldy+JtbIicVCL7dAYl4zq+2rxEOUTObxA=";
        };

        virtualHosts = builtins.listToAttrs (
          builtins.map (name: {
            name = "${name}.${domain}";
            value.extraConfig = ''
              reverse_proxy localhost:${toString proxiedServices.${name}}
              ${tlsConfig}
            '';
          }) (builtins.attrNames proxiedServices)
        );
      };

      sops.templates."caddy-env".content = ''
        CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}
      '';

      systemd.services.caddy.serviceConfig.EnvironmentFile =
        config.sops.templates."caddy-env".path;

      systemd.tmpfiles.rules = [
        "d /mnt/media 0775 root media -"
        "d /mnt/media/downloads 0775 root media -"
        "d /mnt/media/movies 0775 root media -"
        "d /mnt/media/tv 0775 root media -"
      ];

      environment.systemPackages = with pkgs; [
        mergerfs
      ];

      networking.firewall.allowedTCPPorts = [
        443 # HTTPS (Caddy)
        8096 # Jellyfin
        5055 # Jellyseerr
        7878 # Radarr
        8989 # Sonarr
        6767 # Bazarr
        9696 # Prowlarr
        6336 # SABnzbd
        9091 # Transmission
        8191 # FlareSolverr
      ];
    };
}
