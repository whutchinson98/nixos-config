# Work specific programs I need frequently
{
  flake.modules.homeManager.terminal =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        namespace-cli
      ];
    };
}
