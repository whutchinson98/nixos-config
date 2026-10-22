# AI coding agents and workspace management.
{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      # note: libnotify is part of desktop do not add here
      home.packages = with pkgs; [
        fd
        ripgrep
        codex
        claude-code
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      xdg.configFile."herdr/config.toml" = {
        force = true;
        text = ''
          onboarding = false

          [keys]
          split_vertical = "prefix+|"
        '';
      };
    };
}
