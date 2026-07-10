---
name: dendritic-nix
description: Use when the user asks about or wants to implement the "dendritic nix pattern", aspect-oriented Nix configuration, organizing Nix config by feature/aspect instead of hostname, or migrating to flake-parts modules. Also applies when discussing cross-platform Nix configs (NixOS + Darwin + Home Manager) in a single file.
version: 1.0.0
---

# Dendritic Nix Pattern

The dendritic pattern is an **aspect-oriented** approach to Nix configuration built on [flake-parts](https://flake.parts). Each `.nix` file provides configuration for the same **aspect** (feature/concern) across different configuration classes (NixOS, Darwin, Home Manager, etc.).

It is a configuration **pattern** — not a library or framework.

## Core Principle

Instead of organizing by host (`hosts/mira/default.nix`, `hosts/framework16/default.nix`), organize by **feature**. A single file like `modules/ssh.nix` contains the NixOS, Darwin, and Home Manager config for SSH all in one place.

## File Structure

- No mandatory directory structure
- Every `.nix` file is a **flake-parts module** — uniform semantics
- Files are auto-loaded (e.g., via `vic/import-tree`)
- Files with `/_` in their path are ignored by convention

```
modules/
├── ssh.nix           # SSH config across all platforms
├── vim.nix           # Editor config across all platforms
├── vic.nix           # User "vic" across all platforms
└── desktop/
    ├── basic.nix     # Basic desktop features
    └── advanced.nix  # Advanced desktop features (incremental)
```

## Module Pattern

Each file is a flake-parts module that defines config for multiple configuration classes:

```nix
{ inputs, config, ... }: let
  # Shared values — replaces specialArgs
  sharedPort = 2277;
in {
  flake.modules.nixos.aspect-name = {
    # NixOS system configuration
  };

  flake.modules.darwin.aspect-name = {
    # macOS system configuration
  };

  flake.modules.homeManager.aspect-name = {
    # Home Manager user configuration
  };

  perSystem = { pkgs, ... }: {
    # Per-system packages, devShells, etc.
  };
}
```

## Complete Example: SSH

```nix
# modules/ssh.nix
{ inputs, config, ... }: let
  scpPort = 2277;
in {
  flake.modules.nixos.ssh = {
    services.openssh = {
      enable = true;
      ports = [ scpPort ];
    };
    networking.firewall.allowedTCPPorts = [ scpPort ];
  };

  flake.modules.darwin.ssh = {
    # macOS built-in SSH server config
  };

  flake.modules.homeManager.ssh = {
    # ~/.ssh/config, authorized_keys, etc.
  };

  perSystem = { pkgs, ... }: {
    # Custom packages using SSH facilities
  };
}
```

## User Definition Example

```nix
# modules/vic.nix
let
  userName = "vic";
in {
  flake.modules.nixos.${userName} = {
    users.users.${userName} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  flake.modules.darwin.${userName} = {
    system.primaryUser = userName;
  };

  flake.modules.homeManager.${userName} = { pkgs, lib, ... }: {
    home.username = lib.mkDefault userName;
    home.homeDirectory = lib.mkDefault (
      if pkgs.stdenvNoCC.isDarwin
      then "/Users/${userName}"
      else "/home/${userName}"
    );
    home.stateVersion = lib.mkDefault "25.05";
  };
}
```

## Minimal flake.nix

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # other inputs...
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
```

## Dynamic Inputs (Optional)

With `vic/flake-file`, inputs can be declared per-module:

```nix
# modules/home/vim.nix
{ inputs, ... }: {
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim";
  flake.modules.homeManager.vim = {
    # config using inputs.nixvim
  };
}
```

## Key Advantages

1. **Feature closures**: Everything needed for a feature lives in one file
2. **No specialArgs**: Shared values use `let` bindings and flake-parts options
3. **Uniform file semantics**: Every `.nix` file is a flake-parts module
4. **Incremental features**: Add `feature/basic.nix` and `feature/advanced.nix` independently
5. **Cross-platform**: NixOS, Darwin, and Home Manager config coexist naturally

## Configuration Classes

Common classes used in `flake.modules.<class>`:
- `nixos` — NixOS system config
- `darwin` — macOS system config
- `homeManager` — Home Manager user config
- `nixvim` — Editor config
- Custom classes as needed

## When Helping Users

- When migrating an existing config: map each "feature" (SSH, users, desktop, etc.) to its own flake-parts module file
- Each module should define config for all relevant classes in one place
- Use `let` bindings for values shared across classes instead of `specialArgs`
- The pattern does NOT require flakes — see `vic/dendritic-unflake` for non-flake usage
- Tools like `vic/import-tree` and `vic/flake-file` are recommendations, not requirements
