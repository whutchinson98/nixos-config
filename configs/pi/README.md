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

The `agent/extensions/subagent` extension registers `agent_list` and `subagent` tools so pi can list and spawn the agents in `agent/agents/`. Subagent runs open a full-screen bordered dashboard modeled after `davis7dotsh/my-pi-setup`, with every agent visible and a scrollable live-output view. Agents that opt into the `ask_user` tool can pause, send a system notification, and switch the dashboard to an interactive response view for suggested or custom answers before continuing.

The read-only `investigate` agent answers codebase questions with repository evidence and actionable next steps. Invoke it with `/investigate <question>` or by starting a request with `investigate`.

The `agent/extensions/planner-builder` extension registers `plan_file_create`, `plan_file_build`, and `plan_file_list` tools plus `/plan-create`, `/plan-build`, and `/plan-list` commands. It uses the model and effort selected in the main pi process when running the `planner`, `builder`, and optional `verifier` agents. During plan creation, the planner appears in the full-screen live dashboard and can pause to ask material scope or architecture questions in an interactive response view, then continue with the selected or custom answer. Planner execution and optional verifier review retain their existing locally spawned structured subprocess behavior.

The planner writes `.pi/plans/*.md` plan files, then builders implement ready independent task blocks in monitored parallel Herdr-managed Jujutsu workspaces created by the `whutchinson98.jj-workspace` plugin. Each builder runs as a native interactive Pi TUI in its task workspace, not as a piped JSON child process. Focus the task workspace in Herdr to see the live TUI and use normal Pi input to steer the builder or send follow-up text. The Vim-navigable dashboard mirrors up to 1,000 lines of each pane's `recent-unwrapped` output, so dashboard navigation and direct pane interaction are both available. Assigned prompts use mode-0600 temporary files: the extension starts Pi without a task, waits for its initial `idle` prompt, then submits the literal `@file` with `herdr pane run`, avoiding shell interpolation and startup/completion races.

Herdr `blocked` is treated as active and interactive. The initial `idle` triggers task submission rather than completion. An unseen completed pane reports `done`; a viewed completion can report `idle`, which is accepted only after post-submission `working`/`blocked` or a result marker is observed. Cancellation sends Escape and closes the active pane. Builders with no lifecycle or pane-output activity are considered stuck and can restart in a new pane in the same checkout. The last standalone, unfenced `PLAN_TASK_RESULT: done`, `failed`, or `blocked` marker determines task classification before atomic-commit validation and serial integration. Failed, blocked, cancelled, stuck-exhausted, validation-failed, and conflicted workspaces are retained for inspection; successful integration closes the Herdr workspace, forgets the Jujutsu workspace, and deletes the checkout. Verifier review is skipped by default; set `runVerifier: true` on `plan_file_build` or pass `--verify` to `/plan-build` to write `.pi/outputs/findings.html`.

After rebuilding home-manager/NixOS, run `/reload` inside pi to pick up changes. Use `/github-theme` or `/settings` to select the bundled `github-dark-default` theme.
