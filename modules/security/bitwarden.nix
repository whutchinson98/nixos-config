# Bitwarden — desktop app, CLI, and SSH agent
{ config, ... }:
{
  flake.modules.nixos.bitwarden = {
    home-manager.users.hutch.imports = [ config.flake.modules.homeManager.bitwarden ];
  };
  flake.modules.homeManager.bitwarden =
    { config, pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
        bitwarden-cli
      ];

      # Enable the SSH agent in Bitwarden's desktop settings and store the
      # existing authentication/signing keys in the vault.
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".IdentityAgent = "~/.bitwarden-ssh-agent.sock";
      };
    };
}
