# Subagent extension

This directory adapts the pinned [`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents) package for this Nix-managed Pi configuration.

- `index.ts` loads the upstream extension from `./upstream`.
- `config.json` keeps top-level runs foreground by default and disables durable missions initially.
- `modules/dev/ai.nix` builds commit `71ba8a56e5e3a4be29f16472e823a72cebf3247c` with its npm dependencies, installs it as `./upstream`, and exposes its bundled skill and prompts.
- The upstream default agent scope is patched from `both` to `user`; project agents must be requested explicitly.

The extension provides the `subagent` and `subagent_wait` tools, packaged agents, scripted multi-agent workflows, background runs, FleetView, `/subagents-fleet`, and supervisor communication. Multi-agent calls use `workflowScript`; the previous top-level `tasks` and `chain` input shapes are no longer supported.

Local `planner` and `investigate` agents use upstream's `contact_supervisor` tool for normal delegation. Planner-builder keeps its dedicated interactive dashboard and translates `contact_supervisor` back to its private `ask_user` bridge when creating plans.

After rebuilding Home Manager/NixOS, run `/reload` or start a new Pi session. Use `/subagents-doctor` to check the installation and `/subagents-guide` for the bundled reference.
