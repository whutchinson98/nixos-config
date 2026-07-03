# Forge CLIs — GitHub, GitLab, Codeberg
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gh
        gh-dash
        diffnav
        glab
        codeberg-cli
      ];
    };
}
