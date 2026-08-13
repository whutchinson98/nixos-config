# Headless server baseline — layered on top of base by server hosts
{
  flake.modules.nixos.server =
    { pkgs, ... }:
    {
      # NTP — media/K8s workloads are sensitive to clock skew
      services.chrony.enable = true;

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      networking.firewall.enable = true;

      environment.systemPackages = with pkgs; [
        htop
        jq
        just
        tmux
      ];
    };
}
