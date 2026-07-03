# Nix daemon settings, garbage collection, and the pkgs.stable overlay
{ inputs, ... }:
{
  flake.modules.nixos.base = {
    nix.settings.download-buffer-size = 536870912; # 512 MB (default is 64 MB)
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nixpkgs.config.allowUnfree = true;

    # Stable nixpkgs as pkgs.stable — replaces the pkgs-stable specialArg
    nixpkgs.overlays = [
      (_final: prev: {
        stable = import inputs.nixpkgs-stable {
          localSystem = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];

    system.stateVersion = "25.05";
  };
}
