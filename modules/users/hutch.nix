# User hutch — system account, Home Manager wiring, and home basics
{ inputs, config, ... }:
{
  # The system side owns the Home Manager integration and imports hutch's
  # baseline home config. Other NixOS features attach their corresponding Home
  # Manager modules when a host imports them. Host-specific home tweaks go in
  # the host file via home-manager.users.hutch.
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
        imports = [ config.flake.modules.homeManager.hutch ];
        home.enableNixpkgsReleaseCheck = false;
      };
    };

  flake.modules.homeManager.hutch = {
    home.stateVersion = "25.05";
    home.file = { };
    home.sessionVariables = {
      EDITOR = "nvim";
    };
    programs.home-manager.enable = true;
  };
}
