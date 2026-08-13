# sops-nix — age-encrypted secrets under secrets/ (keys declared in .sops.yaml)
{ inputs, ... }:
{
  flake.modules.nixos.sops =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # Each host's age key lives on the machine, outside the repo
      sops.age.keyFile = "/etc/age/key.txt";

      environment.systemPackages = with pkgs; [
        age
        sops
        ssh-to-age
      ];
    };
}
