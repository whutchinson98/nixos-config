# Desktop GUI applications
{ inputs, ... }: {
  flake.modules.homeManager.desktop =
    { pkgs, lib, ... }:
    let
      macroDesktop = inputs.macro.packages.${pkgs.system}.tauri-desktop;
    in
    {
      home.packages = with pkgs; [
        macroDesktop
        notify
        signal-desktop
        bruno
        stable.spotify
        networkmanagerapplet
        obs-studio
        libnotify
        ledger-live-desktop
        dbeaver-bin
        proton-vpn-cli
        brightnessctl
      ];

      # Macro's Tauri deep-link plugin registers a user-local
      # app-handler.desktop using /proc/self/exe. Under Nix this resolves to
      # the unwrapped binary, bypassing the wrapper that supplies WebKit/GTK
      # runtime env. Keep that desktop id managed and pointed at the wrapped
      # executable, then make it the xdg default for macro:// links.
      xdg.dataFile."applications/app-handler.desktop" = {
        force = true;
        text = ''
          [Desktop Entry]
          Type=Application
          Name=macro
          Exec=${macroDesktop}/bin/app %u
          Terminal=false
          NoDisplay=true
          MimeType=x-scheme-handler/macro;
        '';
      };

      home.activation.setMacroSchemeHandler = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.xdg-utils}/bin/xdg-mime default app-handler.desktop x-scheme-handler/macro
      '';
    };
}
