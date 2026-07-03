# 1Password — desktop app, CLI, and SSH agent
{
  flake.modules.nixos.onepassword = {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "hutch" ];
    };
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
