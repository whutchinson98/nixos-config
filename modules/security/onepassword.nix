# 1Password — desktop app, CLI, and SSH agent
{ config, ... }:
{
  flake.modules.nixos.onepassword = {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "hutch" ];
    };
    home-manager.users.hutch.imports = [ config.flake.modules.homeManager.onepassword ];
  };

  flake.modules.homeManager.onepassword = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
