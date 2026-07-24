# Pi

Configuration and extension sources for [pi](https://github.com/badlogic/pi-mono).

Pi reads agent-level prompt additions from `~/.pi/agent/APPEND_SYSTEM.md`, keybinding overrides from `~/.pi/agent/keybindings.json`, auto-discovers global skills from `~/.pi/agent/skills`, auto-discovers global agents from `~/.pi/agent/agents`, auto-discovers global extensions from `~/.pi/agent/extensions`, and auto-discovers themes from `~/.pi/agent/themes`. The home-manager module at `modules/dev/ai.nix` links the managed resources from `configs/pi/agent` into `~/.pi/agent` without owning mutable pi state such as sessions, auth, or settings.

Add skills as directories containing `SKILL.md` under `agent/skills/`.

Add agents as markdown files with frontmatter under `agent/agents/`.

Add extensions as either:

- `extensions/my-extension.ts`
- `extensions/my-extension/index.ts` for multi-file extensions

`agent/package.json` gives the directory a pi-package-like shape while Home Manager still links each resource class separately.

The `agent/extensions/dashboard` extension is inspired by [davis7dotsh/my-pi-setup](https://github.com/davis7dotsh/my-pi-setup): it installs a custom gradient header, two-line footer, model/context/cost telemetry, Jujutsu working-copy status, a themed working spinner, and `/dashboard` plus `/github-theme` commands.

The `agent/extensions/file-search` extension registers first-class `fd` and `rg` tools. The binaries are provided by Nix (`fd` and `ripgrep` in `modules/dev/ai.nix`) rather than downloaded at pi startup.

The `agent/extensions/subagent` extension registers `agent_list` and `subagent` tools so pi can list and spawn the agents in `agent/agents/`. Agents that opt into the `ask_user` tool can pause, send a system notification, and surface material questions through the parent pi UI before continuing.

The read-only `investigate` agent answers codebase questions with repository evidence and actionable next steps. Invoke it with `/investigate <question>` or by starting a request with `investigate`.

The `agent/extensions/planner-builder` extension registers `plan_file_create`, `plan_file_build`, and `plan_file_list` tools plus `/plan-create`, `/plan-build`, and `/plan-list` commands. It uses the model and effort selected in the main pi process when running the `planner`, `builder`, and optional `verifier` agents. During plan creation, the planner can pause to ask the user material scope or architecture questions through the parent pi UI, then continue with the answer. The planner writes `.pi/plans/*.md` plan files, then builders implement ready independent task blocks in monitored parallel Jujutsu workspaces. A live dashboard shows every launched agent with per-agent collapse controls while the extension cancels/restarts stuck attempts and serially integrates each atomic task commit onto the main workspace. Verifier review is skipped by default; set `runVerifier: true` on `plan_file_build` or pass `--verify` to `/plan-build` to write `.pi/outputs/findings.html`.

After rebuilding home-manager/NixOS, run `/reload` inside pi to pick up changes. Use `/github-theme` or `/settings` to select the bundled `github-dark-default` theme.
