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
          "git@github.com:whutchinson98/" = {
            insteadOf = "gh:";
          };
          "git@gitlab.com:hutchery/" = {
            insteadOf = "gl:";
          };
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
  };
}
