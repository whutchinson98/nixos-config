# Hutch pi agent package

User-scoped pi resources linked into `~/.pi/agent` by `modules/dev/ai.nix`.

This directory intentionally mirrors a pi package layout:

- `extensions/` — TypeScript extensions loaded by pi
- `skills/` — Agent skills, merged with the pinned `pi-subagents` skill by Nix
- `agents/` — Markdown definitions consumed by `nicobailon/pi-subagents` and planner-builder
- `prompts/` — Prompt templates, merged with the pinned `pi-subagents` templates by Nix
- `themes/` — Theme JSON files

The dashboard extension adds a custom header/footer, model/context/cost status, Jujutsu working-copy status, and a themed working spinner. Use `/dashboard off`, `/dashboard on`, or `/dashboard refresh` inside pi.

The file-search extension registers first-class `fd` and `rg` tools backed by Nix-provided `fd` and `ripgrep` binaries. It probes PATH for working executables instead of downloading fallback binaries.

The subagent adapter loads a Nix-pinned `nicobailon/pi-subagents` build with its runtime dependencies. It defaults to foreground execution and user-scoped agents, and includes upstream FleetView, workflow, supervisor, skill, and prompt support.
