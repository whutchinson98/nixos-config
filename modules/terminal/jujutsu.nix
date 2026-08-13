{
  flake.modules.homeManager.terminal =
    { config, lib, ... }:
    {
      options.dotfiles.jujutsu.sshSigning.enable = lib.mkEnableOption "SSH commit signing for Jujutsu";

      config.programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            email = "will@thehutchery.com";
            name = "Hutch";
          };
          remotes = {
            origin = {
              auto-track-bookmarks = "glob:hutch/* | glob:whutchinson98/*";
            };
            upstream = {
              auto-track-bookmarks = "main";
            };
          };
        }
        // lib.optionalAttrs config.dotfiles.jujutsu.sshSigning.enable {
          signing = {
            behavior = "own";
            sign-all = true;
            backend = "ssh";
            key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENMDh7q29md/cAQWBp13Fk//buN4KiQIiwJze+rRj9P";
          };
        };
      };
    };
}
