{
  flake.modules.homeManager.terminal = {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "will@thehutchery.com";
          name = "Hutch";
        };
        signing = {
          behavior = "own";
          sign-all = true;
          backend = "ssh";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENMDh7q29md/cAQWBp13Fk//buN4KiQIiwJze+rRj9P";
        };
        remotes = {
          origin = {
            auto-track-bookmarks = "glob:hutch/* | glob:whutchinson98/*";
          };
          upstream = {
            auto-track-bookmarks = "main";
          };
        };
      };
    };
  };
}
