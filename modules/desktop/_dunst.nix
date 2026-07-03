# Dunst notifications — unused (mako is active, see notifications.nix).
# Underscore prefix keeps import-tree from loading this file.
{
  flake.modules.homeManager.desktop = {
    services.dunst.enable = true;
  };
}
