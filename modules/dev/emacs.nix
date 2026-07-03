{
  flake.modules.homeManager.dev =
    { config, pkgs, ... }:
    let
      doomConfigPath = "${config.home.homeDirectory}/dotfiles.nix/configs/doom";
    in
    {
      programs.emacs = {
        enable = true;
        extraPackages =
          epkgs: with epkgs; [
            vterm
            pdf-tools
            treesit-grammars.with-all-grammars
            mu4e
          ];
      };

      services.emacs = {
        enable = true;
        client.enable = true;
        defaultEditor = false;
      };

      # Home Manager enables emacs.service under default.target by default, which
      # starts the daemon as soon as the user manager comes up. On Wayland/Niri this
      # can be before the graphical session environment (WAYLAND_DISPLAY, NIRI_SOCKET,
      # etc.) exists. Start it with the graphical session instead.
      systemd.user.services.emacs = {
        Unit = {
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # Keep Doom linked directly to the checked-out dotfiles instead of copying it
      # through the Nix store, so edits are visible immediately.
      home.file.".config/doom" = {
        source = config.lib.file.mkOutOfStoreSymlink doomConfigPath;
        force = true;
      };

      home.packages = with pkgs; [
        # v term compile deps
        cmake
        gnumake
        libtool

        git
        ripgrep
        # Optional dependencies
        coreutils
        clang
      ];
    };
}
