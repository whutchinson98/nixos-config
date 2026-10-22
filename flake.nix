{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    nirijump = {
      url = "git+https://gitlab.com/hutchery/nirijump";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    notification-proxy = {
      url = "github:whutchinson98/notification-proxy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-subagents = {
      url = "github:nicobailon/pi-subagents/71ba8a56e5e3a4be29f16472e823a72cebf3247c";
      flake = false;
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      # Pinned: newer revs break eval when transmission.vpn is enabled with
      # the default peerPort = null (null openVPNPorts entry)
      url = "github:nix-media-server/nixarr/7cc521933dc6800ae81ecfc91fe36237476e4ffb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ (inputs.import-tree ./modules) ];

      systems = [ "x86_64-linux" ];

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt
            just
          ];
        };
      };
    };
}
