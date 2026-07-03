# Mako notifications + mako-tui manager
{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      services.mako = {
        enable = true;
        settings = {
          border-radius = 8;
          border-size = 2;
          padding = "12";
          margin = "12";
          font = "Noto Sans Mono 11";
          on-button-left = "invoke-default-action";
          on-button-right = "dismiss";
        };
      };

      home.packages = with pkgs; [
        inputs.mako-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
