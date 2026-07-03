# Planner-builder extension

Creates planner-generated plan files and dispatches plan tasks to builder agents.

## Commands

| Command | Purpose |
| --- | --- |
| `/plan-create <request>` | Run the `planner` agent in the background and write a plan file under `.pi/plans/`. Child-agent activity is shown in the status bar and streamed into the main message area while the run is active; the result or failure is posted when complete. |
| `/plan-build [plan-file] [T01,T02]` | Run `builder` agents for ready tasks in the background, one task at a time, and require each completed task to be committed with Jujutsu (`jj`). If no file is provided, the latest `.pi/plans/*.md` file is used. Child-agent activity is shown in the status bar and streamed into the main message area while the run is active; the result or failure is posted when complete. |
| `/plan-list` | List recent plan files. |

## Tools

| Tool | Purpose |
| --- | --- |
| `plan_file_create` | LLM-callable tool that runs a planner agent and saves a structured plan file. |
| `plan_file_build` | LLM-callable tool that runs builder agents against pending plan tasks, serializing them for atomic per-task `jj` commits. |
| `plan_file_list` | Lists recent plan files. |

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

`/plan-build` runs ready tasks in dependency order, one at a time, so each completed task can be committed atomically with Jujutsu. Dependent tasks wait until their dependencies have `Status: done`.

The extension sends system notifications through `system-notify` when `/plan-create` finishes creating a plan, after each `/plan-build` task is marked `done`, `failed`, or `blocked`, and when a full plan build finishes or fails.

Builder agents are instructed not to edit the plan file. The extension updates each task status to `in-progress`, then `done`, `failed`, or `blocked`, and appends a builder result log to the task block. Builders must inspect `jj status`, keep unrelated or plan-file status changes out of the commit (using a path/fileset-limited commit when needed), and create exactly one `jj commit` for the task before reporting `PLAN_TASK_RESULT: done`.

## Typical workflow

```text
/plan-create add Redis caching to the session store
/plan-list
/plan-build .pi/plans/20260507-180000Z-add-redis-caching-to-the-session-store.md
```

You can also ask naturally: "Use the planner to create a plan file, then have builder agents implement the tasks." The registered tools give the main agent the same workflow.
