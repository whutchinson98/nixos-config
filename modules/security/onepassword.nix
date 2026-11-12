# 1Password — desktop app, CLI (including AWS credentials), and SSH agent
{ config, ... }:
{
  flake.modules.nixos.onepassword = {
    home-manager.users.hutch.imports = [ config.flake.modules.homeManager.onepassword ];

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "hutch" ];
    };
  };

  flake.modules.homeManager.onepassword =
    { config, ... }:
    {
      # Enable the SSH agent in 1Password's Settings > Developer and store
      # the existing authentication/signing keys as SSH Key items in the vault.
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".IdentityAgent = "~/.1password/agent.sock";
      };
    };
}
