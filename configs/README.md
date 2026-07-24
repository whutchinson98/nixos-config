# Configs

Directory to contain all configuration files for things I do not directly declare in nix.

- `pi/agent/` is a pi-package-shaped resource tree linked into `~/.pi/agent` by `modules/dev/ai.nix`.
- `pi/agent/extensions/`, `skills/`, `agents/`, `prompts/`, and `themes/` are linked separately so mutable pi state such as sessions, auth, and settings stays unmanaged.
