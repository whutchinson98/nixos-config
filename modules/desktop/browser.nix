# browser
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.firefox
      ];
    };
}
