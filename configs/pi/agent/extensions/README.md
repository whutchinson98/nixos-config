# Pi extensions

Store pi extension source files here.

Pi will load these from `~/.pi/agent/extensions` once linked by Home Manager.

Examples:

```text
extensions/
├── my-extension.ts
└── larger-extension/
    ├── index.ts
    └── helpers.ts
```

Extension files should default-export a function that receives `ExtensionAPI`.

## Dashboard UI

`dashboard/` is the local adaptation of the UI ideas from `davis7dotsh/my-pi-setup`:

- gradient pi header
- two-line footer with cwd, model/effort, context usage, cost, tokens/sec, and Jujutsu status
- themed working spinner
- `/dashboard [on|off|refresh]`
- `/github-theme` to switch to the bundled `github-dark-default` theme

The VCS status is intentionally Jujutsu-based and does not call `git`.

## File search

`file-search/` registers first-class `fd` and `rg` tools. Unlike the upstream example, it does not download fallback binaries at startup; `fd` and `ripgrep` are installed by Nix in `modules/dev/ai.nix`. It probes all PATH candidates and uses the first executable that actually runs, so stale downloaded binaries under `~/.pi/agent/bin` do not shadow the Nix binaries.

## Workspace initialization

`initialize-workspace.ts` runs on Pi session startup. It searches from the session cwd up to the nearest `flake.nix`, normalizes the repository paths reported by `jj git remote list`, and continues only when at least one exactly matches a line in `~/workspace-repos`. For matching repositories on NixOS with `direnv` installed, it ensures `.envrc` contains `use flake` and `watch_file nix/*.nix`, then runs `direnv allow` from the flake root.

Planner-builder runs set `PI_SUBAGENT=1`, while upstream `pi-subagents` children set `PI_SUBAGENT_CHILD=1`. When this extension sees either environment variable and `nix` is available, it overrides only that agent process's `bash` tool with wrappers for `cargo`, `bun`, `npm`, `pnpm`, `go`, `just`, and `doppler`. Invocations of those commands run through `nix develop <flake-root> -c`; all other commands run directly. The main Pi process still uses its normal bash tool.

Builder agents opt in to loading extensions, so the startup hook and subagent-only command wrappers run inside the native interactive Pi process in the Herdr task pane rather than a piped builder subprocess.

## Herdr lifecycle integration

`herdr-agent-state.ts` vendors Herdr v0.7.4's official Pi integration. In Herdr-managed panes it reports authoritative Pi lifecycle state over the Herdr socket instead of relying on terminal-screen detection. Retryable provider failures, including `WebSocket error`, remain `working` during Pi's automatic retry grace period and become `blocked` rather than falsely reporting completion if no retry starts. A later retry returns to `working`, and only the completed run reports `idle`/`done`, allowing planner-builder to observe and integrate the actual result.

## Subagents

`subagent/` loads a Nix-pinned build of [`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents), including its npm dependencies, bundled agents, skill, and prompt templates.

| Tool | Purpose |
| --- | --- |
| `subagent` | Delegate to one agent, run a scripted multi-agent workflow, or manage active and retained runs. |
| `subagent_wait` | Wait for one or all background runs, or register a non-blocking completion wake-up. |

The extension supports foreground and background child sessions, WorkflowScript orchestration, FleetView, `/subagents-fleet`, steering and stopping active children, and `contact_supervisor`/`subagent_supervisor` coordination. This configuration sets `asyncByDefault: false`, disables missions initially, and patches the default discovery scope from `both` to `user`; project agents must be requested explicitly. The old top-level `tasks` and `chain` tool inputs, `agent_list`, `/agents`, and the per-call full-screen dashboard are no longer provided.

Local `planner` and `investigate` definitions use `contact_supervisor` for normal upstream runs. Planner-builder still uses the shared local agent discovery and question modules, and translates `contact_supervisor` to its private `ask_user` bridge so `/plan-create` retains direct suggested/custom-answer UI.

## Planner-builder workflow

`planner-builder/` registers:

| Tool | Purpose |
| --- | --- |
| `plan_file_create` | Run the `planner` agent with the model and effort selected in the main pi process, show its live output in the full-screen subagent dashboard, surface material planner questions through the parent UI, and save a structured plan file under `.pi/plans`. |
| `plan_file_build` | Use the `whutchinson98.jj-workspace.new-no-bookmark` Herdr plugin command to create task workspaces without Jujutsu bookmarks, run each `builder` as a native interactive Pi TUI for ready independent tasks in parallel, mirror pane output in a Vim-navigable dashboard, and serially integrate each atomic `jj` commit. Verifier review is skipped by default; set `runVerifier: true` to run the unchanged structured `verifier` subprocess with the same selection and write `.pi/outputs/findings.html`. |
| `plan_file_list` | List recent plan files. |

It also registers `/plan-create`, `/plan-build`, and `/plan-list`. Pass `--verify` to `/plan-build` to opt into verifier review. Plan builds must run inside Herdr with the enabled [`whutchinson98/herdr-plugin-jj-workspace`](https://github.com/whutchinson98/herdr-plugin-jj-workspace) plugin installed. The extension explicitly invokes `whutchinson98.jj-workspace.new-no-bookmark`, submits the generated name through its wizard pane, rebases the new empty working-copy commit onto the current integrated commit, and starts a normal interactive Pi process in each resulting task workspace. Focus a task workspace to inspect its native TUI and send steering or follow-up input. The main dashboard mirrors `recent-unwrapped` pane output while preserving direct interaction.

Builder prompts are transferred in mode-0600 temporary files without shell interpolation. Each Pi pane starts without a task; after Herdr reports its initial `idle`, the extension submits the literal `@path` with `herdr pane run`. Herdr `blocked` remains an active interactive state. Unseen `done` is terminal; a later viewed `idle` is terminal only after post-submission `working`/`blocked` or a result marker. Cancellation and stuck handling send Escape and close the active pane, and stuck restarts use a new pane in the same checkout. The last standalone, unfenced `PLAN_TASK_RESULT: done|failed|blocked` line classifies the completed task before commit validation.

Successfully integrated workspaces are closed, forgotten by Jujutsu, and deleted. Failed, blocked, cancelled, stuck-exhausted, validation-failed, or conflicted workspaces are retained for inspection; naturally completed failure panes remain interactive. Planner questions and optional verifier review retain their existing locally spawned structured subprocess behavior.

## Remote MCP extensions

`linear_mcp.ts` and `pulumi_mcp.ts` use the reusable helper in `mcp_bridge/bridge.ts` to start remote MCP servers. The bridge is lazy by default: startup only registers a small loader tool, and the remote MCP process is started/listed when the loader tool or reload command is used. Set `loadOnSessionStart: true` in a bridge config to opt back into eager loading. On Linux it uses the Nix/Home Manager `mcp-remote` command; on macOS and other platforms it uses `npx -y mcp-remote`.

Equivalent commands:

```text
# Linux / NixOS
mcp-remote https://mcp.linear.app/mcp
mcp-remote https://mcp.ai.pulumi.com/mcp

# macOS / other
npx -y mcp-remote https://mcp.linear.app/mcp
npx -y mcp-remote https://mcp.ai.pulumi.com/mcp
```

`modules/dev/ai.nix` installs `mcp-remote` as a Nix/Home Manager command wrapper for Linux/NixOS. The wrapper runs `npx -y mcp-remote` with Nix's `nodejs` in PATH.

Registered loader tools, tool prefixes, and commands:

| Extension | Loader tool | MCP tool prefix after load | Commands |
| --- | --- | --- | --- |
| `linear_mcp.ts` | `linear_mcp_load` | `linear_` | `/linear-mcp-status`, `/linear-mcp-reload` |
| `pulumi_mcp.ts` | `pulumi_mcp_load` | `pulumi_` | `/pulumi-mcp-status`, `/pulumi-mcp-reload` |

The first lazy load may require the OAuth flow that `mcp-remote` opens/prompts for.
