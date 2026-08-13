# flake-parts plumbing: flakeModules.modules provides the typed
# flake.modules.<class>.<name> option that lets many files contribute to the
# same named module (the dendritic pattern's merge point).
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
}
