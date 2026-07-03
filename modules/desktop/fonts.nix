{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      # Font rendering configuration
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "GeistMono Nerd Font" ];
          sansSerif = [ "Montserrat" ];
          serif = [ "Alegreya" ];
        };
      };

      home.packages = with pkgs; [
        alegreya
        montserrat
        nerd-fonts.geist-mono
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        font-awesome # for icons
      ];
    };
}
