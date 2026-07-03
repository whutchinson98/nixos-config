# Fingerprint reader support
{
  flake.modules.nixos.fingerprint = {
    services.fprintd.enable = true;

    security.pam.services.polkit-1.fprintAuth = true;
  };
}
