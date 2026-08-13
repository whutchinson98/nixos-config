# Neovim — config lives in configs/nvim and is symlinked out of the store so
# edits are visible immediately without a rebuild
{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;

        withNodeJs = false;
        withPython3 = false;
        withRuby = false;

        extraPackages = with pkgs; [
          lua-language-server
          nixfmt
          nixd
          tree-sitter
          ripgrep
        ];
      };
    };
}
