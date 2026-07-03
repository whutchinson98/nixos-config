# Agent Instructions

## Repo structure (dendritic pattern)

- This flake uses flake-parts + import-tree: every `.nix` file under `modules/` is auto-loaded as a flake-parts module. There are no import lists — creating a file registers it.
- Files are organized by feature (aspect), not by host. A feature's NixOS config and Home Manager config live in the same file, registered under `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`.
- Multiple files may contribute to the same module name (e.g. everything in `modules/terminal/` merges into `flake.modules.homeManager.terminal`).
- Hosts (`modules/hosts/<host>/host.nix`) compose named nixos modules; all registered homeManager modules are applied to the `hutch` user via `modules/users/hutch.nix`. Host-specific quirks stay inline in the host file.
- Files with a path component starting with `_` are ignored by import-tree — used for hardware configs (plain NixOS modules) and parked/disabled features.
- Use `pkgs.stable.<pkg>` for packages from nixpkgs-stable (overlay defined in `modules/base/nix.nix`).
- This repo is version-controlled with jujutsu (jj), not raw git. Use plain `mv`/`rm` for file operations and evaluate with `nix eval path:.#...` so results don't depend on the git index.

## Doom Emacs

- `configs/doom/config.org` is the source of truth for Doom Emacs configuration.
- Do not manually edit `configs/doom/config.el`; it is generated/tangled from `config.org` by Doom.
- When changing Doom config, update `configs/doom/config.org` only unless the user explicitly asks otherwise.
