{
  flake.modules.homeManager.dev = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      config = {
        global = {
          warn_timeout = "1m";
        };
      };
    };
  };
}
