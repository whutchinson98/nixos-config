# User hutch — system account, Home Manager wiring, and home basics
{ inputs, config, ... }:
{
  # The system side owns the Home Manager integration: every module registered
  # under flake.modules.homeManager is imported for hutch on hosts that import
  # this module. Host-specific home tweaks go in the host file via
  # home-manager.users.hutch.
  flake.modules.nixos.hutch =
    { pkgs, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      users.users.hutch = {
        isNormalUser = true;
        description = "hutch";
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "disk"
          "storage"
          "input"
          "audio"
        ];
        shell = pkgs.fish;
      };

      home-manager.useGlobalPkgs = true;
      home-manager.users.hutch = {
        imports = builtins.attrValues config.flake.modules.homeManager;
        home.enableNixpkgsReleaseCheck = false;
      };
    };

  flake.modules.homeManager.hutch = {
    home.stateVersion = "25.05";
    home.file = { };
    home.sessionVariables = {
      EDITOR = "hx";
    };
    programs.home-manager.enable = true;
  };
}
