{
  flake.modules.homeManager.terminal = {
    home.file."scripts" = {
      source = ../../configs/scripts;
      recursive = true;
      executable = true;
    };
  };
}
