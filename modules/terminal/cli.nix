# General CLI tools
{ inputs, ... }:
{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        inputs.notification-proxy.packages.${pkgs.system}.default
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
