# Planner-builder extension

Creates planner-generated plan files and dispatches plan tasks to builder agents.

## Commands

| Command | Purpose |
| --- | --- |
| `/plan-create <request>` | Run the `planner` agent on `anthropic/claude-fable-5` using the currently selected effort, then write a plan file under `.pi/plans/`. Child-agent activity is shown in the status bar and streamed into the main message area while the run is active; the result or failure is posted when complete. |
| `/plan-build [plan-file] [T01,T02]` | Run `builder` agents on `openai-codex/gpt-5.5` using the currently selected effort in monitored parallel Jujutsu workspaces when tasks are independent, require each completed task to create one atomic commit, integrate commits serially onto the main workspace, then run the `verifier` agent to write `.pi/outputs/findings.html`. If no file is provided, the latest `.pi/plans/*.md` file is used. Child-agent activity is shown in the status bar and streamed into the main message area while the run is active; the builder watchdog periodically reports no-output status, cancels stuck attempts, and restarts them up to the configured limit. The result or failure is posted when complete. |
| `/plan-list` | List recent plan files. |

## Tools

| Tool | Purpose |
| --- | --- |
| `plan_file_create` | LLM-callable tool that runs a planner agent on `anthropic/claude-fable-5` with the selected effort and saves a structured plan file. |
| `plan_file_build` | LLM-callable tool that runs builder agents on `openai-codex/gpt-5.5` with the selected effort against pending plan tasks in monitored parallel workspaces, cancels/restarts stuck builder attempts, serially integrates atomic per-task `jj` commits, then runs the `verifier` agent to write `.pi/outputs/findings.html`. |
| `plan_file_list` | Lists recent plan files. |

## Builder watchdog options

`plan_file_build` accepts optional watchdog controls:

- `builderMonitor` (default `true`) enables/disables stuck detection.
- `builderMonitorIntervalSeconds` (default `30`) controls status checks.
- `builderStuckTimeoutSeconds` (default `900`) cancels a builder attempt after this many seconds with no child-agent output.
- `builderMaxRestarts` (default `1`) controls per-task restarts after a stuck cancellation; `0` cancels stuck runs without restarting.

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

`/plan-build` runs ready tasks in dependency order. Ready tasks with disjoint parsed `Files:` entries can run at the same time in separate Jujutsu workspaces; tasks with unknown or overlapping file sets are held for a later wave. Dependent tasks wait until their dependencies have `Status: done`.

Each task workspace starts from the latest integrated main-workspace head. Builders create exactly one atomic commit in their dedicated workspace. A builder watchdog runs as part of `/plan-build`: it checks each running builder attempt every 30 seconds by default, reports how long the attempt has gone without child-agent output, cancels attempts that are silent for 15 minutes by default, and restarts each stuck task once by default. The restarted builder continues in the same task workspace and is instructed to inspect existing changes before proceeding. After a builder reports `PLAN_TASK_RESULT: done`, the main loop validates that exactly one non-empty task commit exists, rebases it onto the current integrated head, checks for conflicts, and then advances the main workspace to a fresh child of the final integrated head when the build finishes. Failed, blocked, or conflicted task workspaces are kept on disk for inspection. After workspace integration finishes, the `verifier` agent reviews `main..@` and writes `.pi/outputs/findings.html`.

The extension sends system notifications through `system-notify` when `/plan-create` finishes creating a plan, after each `/plan-build` task is marked `done`, `failed`, or `blocked`, and when a full plan build finishes or fails.

Builder agents are instructed not to edit the plan file. The extension updates each task status to `in-progress`, then `done`, `failed`, or `blocked`, and appends a builder result log to the task block. Builders must inspect `jj status`, work only inside their assigned task workspace, and create exactly one `jj commit` for the task before reporting `PLAN_TASK_RESULT: done`.

## Typical workflow

```text
/plan-create add Redis caching to the session store
/plan-list
/plan-build .pi/plans/20260507-180000Z-add-redis-caching-to-the-session-store.md
```

You can also ask naturally: "Use the planner to create a plan file, then have builder agents implement the tasks." The registered tools give the main agent the same workflow.
