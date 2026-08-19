# Planner-builder extension

Creates planner-generated plan files and dispatches each builder as a native interactive Pi TUI inside its Herdr-managed task workspace. Planner creation and optional verifier review keep their existing structured subprocess behavior.

## Commands

| Command | Purpose |
| --- | --- |
| `/plan-create <request>` | Run the `planner` agent using the model and effort currently selected in the main pi process, surface material planner questions through the parent pi UI, then write a plan file under `.pi/plans/`. Child-agent activity is shown in the status bar and streamed into the main message area while the run is active; the result or failure is posted when complete. |
| `/plan-build [--verify] [plan-file] [T01,T02]` | Run `builder` agents as native interactive Pi TUIs in monitored parallel Herdr-managed Jujutsu workspaces when tasks are independent, using the model and effort currently selected in the main pi process. The dashboard mirrors each builder pane while the workspace remains directly interactive. Each completed task must create one atomic commit, which is integrated serially onto the main workspace. Verifier review is skipped by default; pass `--verify` to run the unchanged structured `verifier` subprocess with the same selection and write `.pi/outputs/findings.html`. If no file is provided, the latest `.pi/plans/*.md` file is used. |
| `/plan-list` | List recent plan files. |

## Tools

| Tool | Purpose |
| --- | --- |
| `plan_file_create` | LLM-callable tool that runs a planner agent with the model and effort selected in the main pi process, surfaces material planner questions through the parent pi UI, and saves a structured plan file. |
| `plan_file_build` | LLM-callable tool that uses the `whutchinson98.jj-workspace.new-no-bookmark` Herdr plugin command to create task workspaces without Jujutsu bookmarks, starts a native interactive Pi builder pane for each ready task, mirrors pane output into the dashboard, cancels/restarts stuck attempts, and serially integrates atomic per-task `jj` commits. Set `runVerifier: true` to run the unchanged structured `verifier` subprocess with the same selection and write `.pi/outputs/findings.html`; the default is `false`. |
| `plan_file_list` | Lists recent plan files. |

## Planner questions

The `planner` agent normally uses upstream `pi-subagents`' `contact_supervisor` tool for decisions that materially affect scope, architecture, or implementation details. Planner-builder translates that tool to its private `ask_user` bridge for plan creation. The child planner process pauses while the planner-builder extension sends a system notification and switches the live dashboard to an interactive question view. The user can send a suggested choice or select `Write a different answer...` to type additional information, after which the same planner run resumes. Questions are recorded in the `plan_file_create` result details.

The planner is instructed to inspect the repository first and not ask questions the codebase can answer. If the run is non-interactive or the user cancels the question, the planner continues with the safest reasonable assumption and documents it in the plan.

## Live agent dashboard

`/plan-create`, `plan_file_create`, `/plan-build`, and `plan_file_build` open a full-screen interactive subagent navigator modeled after `davis7dotsh/my-pi-setup`. Planning shows the planner as a live agent; builds show one row per launched builder or verifier, including task id, title, status, agent, and model. Planner and verifier output still comes from their structured subprocesses. Builder detail views instead mirror the native Pi pane by polling up to 1,000 lines from Herdr's `recent-unwrapped` output, so the dashboard remains useful without replacing the live TUI. The navigator remains available after the run so results can be inspected.

| Key | Action |
| --- | --- |
| `j` / `k` or `Down` / `Up` | Select the next or previous agent in the main list; scroll output in an agent detail view. |
| `Enter`, `l`, or `Right` | Open the selected agent's detail view. |
| `h`, `Left`, or `Esc` | Return from an agent detail view to the main list. `Esc` closes the main list. |
| `g` / `G` | Jump to the top or bottom of an agent's output. |
| `q` | Close the navigator from either view. |
| `Alt+X` | Hide or restore the navigator. |

When an agent asks a question, the navigator temporarily switches to a response view. Use `j`/`k` or the arrow keys to select a suggested answer and `Enter` to send it. Select `Write a different answer...` to open the inline text input; `Enter` sends the custom answer, and `Esc` returns to the suggested choices or cancels a question with no choices.

The normal tool result also renders an all-agent summary in the transcript and continues to support Pi's global `Ctrl+O` tool expansion.

## Build options

`plan_file_build` accepts optional verification and watchdog controls:

- `runVerifier` (default `false`) runs the configured verifier agent after workspace integration when enabled.
- `verifierAgent` (default `"verifier"`) selects the verifier agent used when `runVerifier` is enabled.
- `builderMonitor` (default `true`) enables/disables stuck detection.
- `builderMonitorIntervalSeconds` (default `30`) controls status checks.
- `builderStuckTimeoutSeconds` (default `900`) cancels a builder attempt after this many seconds with no Herdr lifecycle change or pane-output change.
- `builderMaxRestarts` (default `1`) controls per-task restarts after a stuck cancellation; `0` cancels stuck runs without restarting.

Running `/plan-build --verify` against an already completed plan skips its done tasks and triggers only the optional verifier review.

## Herdr workspace integration

Plan builds must run inside a Herdr-managed pane (`HERDR_ENV=1`) with the enabled [`whutchinson98/herdr-plugin-jj-workspace`](https://github.com/whutchinson98/herdr-plugin-jj-workspace) plugin installed. For each ready task, the extension explicitly invokes the plugin's `whutchinson98.jj-workspace.new-no-bookmark` command, supplies the generated task workspace name through the command's wizard pane, and rebases the new empty working-copy commit onto the current integrated commit before starting the builder. The plugin performs `jj workspace add` and opens the checkout as a Herdr workspace without creating a Jujutsu bookmark. The extension never calls `jj workspace add` itself. Task workspace names combine the source workspace folder and task ID, so task `T01` launched from `macro-test-thing` is named `macro-test-thing-t01`.

Task checkout paths follow the plugin's `JJ_WORKSPACE_ROOT` setting (environment first, then the plugin config `.env`, then `~/.herdr/workspaces`). Successfully integrated task workspaces are closed in Herdr, forgotten in Jujutsu, and deleted. Failed, blocked, cancelled, stuck-exhausted, validation-failed, or conflicted task workspaces are retained in Herdr and on disk for inspection.

Install the plugin with:

```sh
herdr plugin install whutchinson98/herdr-plugin-jj-workspace
```

## Interactive builder panes

Only builders move into Herdr panes. The extension starts normal interactive `pi` with `herdr agent start` in the task checkout; it does not use `--mode json`, prompt mode, or piped terminal output for builders. Pi options are passed as literal argv entries after `--`, without the task prompt. The extension waits for Pi's initial `idle` state, then uses `herdr pane run` to submit a mode-0600 temporary file as a literal `@path`. This readiness handshake prevents Pi's startup screen from being mistaken for task completion, while quotes, newlines, spaces, and shell syntax in a plan never pass through shell interpolation. Temporary prompt and runtime files are removed after the attempt series.

At launch, the extension briefly focuses the new agent and then restores the source workspace. This makes the Pi pane the task workspace's remembered pane without stealing focus while parallel tasks start. Focus the task workspace in Herdr to see the complete native Pi TUI; use Pi's normal editor and keybindings to inspect live output, send steering text, or provide follow-up input. Switching back to the source workspace does not interrupt the builder.

The dashboard reads each builder pane with `herdr pane read --source recent-unwrapped --lines 1000`. Changed snapshots update the selected agent's output and refresh the stuck timer, but output changes alone do not prove the task started or completed. The pane remains the authoritative interactive view; the dashboard is a mirror and may contain only the most recent 1,000 unwrapped lines.

The managed `herdr-agent-state.ts` extension reports Pi lifecycle directly to Herdr. Retryable provider failures such as `WebSocket error` therefore remain active while Pi retries instead of producing a false terminal state; the monitor continues following the pane and sees the eventual settled completion.

Herdr lifecycle states are interpreted as follows:

| Herdr status | Planner-builder behavior |
| --- | --- |
| `working` | The native Pi process is active. Status changes and pane-output changes refresh the stuck timer. |
| `blocked` | The Pi process is still active and may be waiting for interaction. Focus the task workspace to inspect or respond; this is not by itself a final `blocked` task result. |
| `done` | Terminal completion for an agent whose finished state has not been viewed. |
| `idle` | The first `idle` means Pi is ready and triggers task submission. A later `idle` is accepted as completion only after a post-submission `working`/`blocked` state or a result marker has been observed. |

Cancelling a build sends Escape to each active builder and closes its pane. A stuck attempt is handled the same way when neither lifecycle status nor pane output changes before the timeout. If restarts remain, a uniquely named Pi pane starts in the same task workspace, preserving uncommitted work for the next attempt; otherwise the workspace is retained. Closing a builder pane manually is treated as a failed attempt rather than leaving the build waiting indefinitely.

On terminal completion, the extension extracts the last standalone `PLAN_TASK_RESULT: done`, `failed`, or `blocked` line from the final pane snapshot. Marker examples inside Markdown code fences are ignored. `failed` and `blocked` markers determine the task result; clean completion without a marker retains the existing success fallback, after which `done` still must pass the one-non-empty-commit validation. Naturally completed failed or blocked panes remain available in their retained workspaces. After a successful validation and serial integration, cleanup closes the entire Herdr task workspace, restores the source workspace, runs `jj workspace forget`, and deletes the checkout.

The planner and optional verifier continue as locally spawned structured JSON subprocesses rather than upstream subagent runs. Planner-builder's translated `ask_user` questions still use the interactive dashboard response view, and verifier review remains opt-in.

## Plan format

The planner is prompted to emit machine-readable builder tasks:

```markdown
## Builder Tasks

### Task T01: Short imperative title
Status: pending
Depends on: none
Files:
- path/to/file.ts
Instructions:
- Specific implementation instruction.
Verification:
- Exact command or manual check.

### Task T02: Follow-up task
Status: pending
Depends on: T01
Files:
- path/to/other-file.ts
Instructions:
- Specific implementation instruction.
Verification:
- Exact command or manual check.
```

`/plan-build` runs ready tasks in dependency order. Ready tasks with disjoint parsed `Files:` entries can run at the same time in separate Herdr-managed Jujutsu workspaces; tasks with unknown or overlapping file sets are held for a later wave. Dependent tasks wait until their dependencies have `Status: done`.

Each Herdr task workspace starts from the latest integrated main-workspace head. Builders create exactly one atomic commit in their dedicated workspace. The monitor checks each native Pi pane every 30 seconds by default, reports its Herdr status and time since lifecycle or output activity, cancels attempts that are inactive for 15 minutes by default, and restarts each stuck task once by default in the same workspace. After a builder reports `PLAN_TASK_RESULT: done` (or reaches the existing clean no-marker fallback), the main loop validates that exactly one non-empty task commit exists, rebases it onto the current integrated head, checks for conflicts, and then advances the main workspace to a fresh child of the final integrated head when the build finishes. Retained unsuccessful workspaces are never integrated automatically. After workspace integration finishes, the build ends without verifier review unless `runVerifier: true` or `/plan-build --verify` was used; when enabled, the `verifier` agent reviews `main..@` and writes `.pi/outputs/findings.html`.

The extension sends system notifications through `system-notify` when the planner asks a question, when `/plan-create` finishes creating a plan, after each `/plan-build` task is marked `done`, `failed`, or `blocked`, and when a full plan build finishes or fails.

Builder agents are instructed not to edit the plan file. The extension updates each task status to `in-progress`, then `done`, `failed`, or `blocked`, and appends a builder result log to the task block. Builders must inspect `jj status`, work only inside their assigned task workspace, and create exactly one `jj commit` for the task before reporting `PLAN_TASK_RESULT: done`.

## Typical workflow

```text
/plan-create add Redis caching to the session store
/plan-list
/plan-build .pi/plans/20260507-180000Z-add-redis-caching-to-the-session-store.md
/plan-build --verify .pi/plans/20260507-180000Z-add-redis-caching-to-the-session-store.md
```

You can also ask naturally: "Use the planner to create a plan file, then have builder agents implement the tasks." The registered tools give the main agent the same workflow.
