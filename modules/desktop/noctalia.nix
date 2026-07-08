{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { config, ... }:
    {
      # import the home manager module
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # configure options
      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        settings = {
          wallpaper = {
            enabled = true;
            directory = "${config.home.homeDirectory}/backgrounds";
            default.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            last.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            monitors = {
              DP-1.path = "${config.home.homeDirectory}/backgrounds/nord.png";
            };
          };

          # configure noctalia here
          bar = {
            density = "compact";
            position = "top";
            showCapsule = false;

            widgets = {
              left = [
                {
                  id = "ControlCenter";
                  useDistroLogo = true;
                }
                {
                  id = "Network";
                }
              ];
              center = [
                {
                  hideUnoccupied = false;
                  id = "Workspace";
                  labelMode = "none";
                }
              ];
              right = [
                {
                  alwaysShowPercentage = false;
                  id = "Battery";
                  warningThreshold = 30;
                }
                {
                  formatHorizontal = "HH:mm";
                  formatVertical = "HH mm";
                  id = "Clock";
                  useMonospacedFont = true;
                  usePrimaryColor = true;
                }
              ];
            };
          };
          colorSchemes.predefinedScheme = "Nord";
          location = {
            monthBeforeDay = true;
            name = "Ontario, Canada";
          };
        };
      };
    };
}
