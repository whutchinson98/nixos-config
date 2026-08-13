# NetworkManager — mkDefault so static-ip server hosts can opt out
{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      networking.networkmanager.enable = lib.mkDefault true;
    };
}
