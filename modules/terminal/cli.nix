# General CLI tools
{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        eza
        fzf
        just
        jq
        kubectl
        kubernetes-helm
        fluxcd
        hugo
      ];
    };
}
