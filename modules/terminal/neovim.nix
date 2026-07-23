# Neovim — config lives in configs/nvim and is symlinked out of the store so
# edits are visible immediately without a rebuild
{
  flake.modules.homeManager.terminal =
    { config, pkgs, ... }:
    let
      nvimConfigPath = "${config.home.homeDirectory}/nixos-config/configs/nvim";
    in
    {
      programs.neovim = {
        enable = true;

        # Home Manager generates provider setup in init.lua. Load that via the
        # wrapper so it does not try to write ~/.config/nvim/init.lua inside the
        # linked nvim config directory.
        sideloadInitLua = true;

        withNodeJs = false;
        withPython3 = false;
        withRuby = false;
      };

      home.packages = with pkgs; [
        tree-sitter
      ];

      home.file.".config/nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink nvimConfigPath;
        force = true;
      };
    };
}
