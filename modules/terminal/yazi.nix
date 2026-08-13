{
  flake.modules.homeManager.terminal = {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
    };
  };
}
