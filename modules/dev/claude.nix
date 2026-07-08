# Claude Code — user-level config (settings.json with permissions, etc) lives
# in configs/claude. Every entry in that folder is symlinked into ~/.claude/
# out of the store so edits — including ones Claude Code writes itself — land
# in the repo without a rebuild. Only the file *list* is baked at eval time:
# adding a new file to configs/claude needs a rebuild to create its link.
{
  flake.modules.homeManager.dev =
    { config, lib, ... }:
    let
      claudeConfigPath = "${config.home.homeDirectory}/nixos-config/configs/claude";
      entries = builtins.attrNames (builtins.readDir ../../configs/claude);
    in
    {
      home.file = lib.listToAttrs (
        map (name: {
          name = ".claude/${name}";
          value = {
            source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigPath}/${name}";
            force = true;
          };
        }) entries
      );
    };
}
