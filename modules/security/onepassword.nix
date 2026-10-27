# 1Password — desktop app and CLI (including AWS credentials)
{
  flake.modules.nixos.onepassword = {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "hutch" ];
    };
  };
}
