# Configs

Directory to contain all configuration files for things I do not directly declare in nix.

- `nvim/` follows the home-manager source-link pattern in `modules/home/dev/neovim.nix`.
- `pi/agent/APPEND_SYSTEM.md` is linked to `~/.pi/agent/APPEND_SYSTEM.md` by `modules/home/dev/ai.nix`.
- `pi/agent/keybindings.json` is linked to `~/.pi/agent/keybindings.json` by `modules/home/dev/ai.nix`.
- `pi/agent/skills/` is linked to `~/.pi/agent/skills` by `modules/home/dev/ai.nix`.
- `pi/extensions/` is linked to `~/.pi/agent/extensions` by `modules/home/dev/ai.nix`.
