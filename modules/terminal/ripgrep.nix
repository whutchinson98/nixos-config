{
  flake.modules.homeManager.terminal = {
    programs.ripgrep = {
      enable = true;
    };
    home.file.".ripgreprc" = {
      source = ../../configs/ripgrep/.ripgreprc;
    };
  };
}
