{
  flake.modules.homeManager.terminal = {
    programs.git = {
      enable = true;
      settings = {
        user = {
          email = "will@thehutchery.com";
          name = "Hutch";
        };
        url = {
          "git@github.com:macro-inc/" = {
            insteadOf = "macro:";
          };
          "git@gitlab.com:hutchery/" = {
            insteadOf = "me:";
          };
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
  };
}
