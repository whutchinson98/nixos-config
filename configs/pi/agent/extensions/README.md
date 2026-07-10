# Pi extensions

Store pi extension source files here.

Pi will load these from `~/.pi/agent/extensions` once linked by home-manager.

Examples:

```text
extensions/
├── my-extension.ts
└── larger-extension/
    ├── index.ts
    └── helpers.ts
```

Extension files should default-export a function that receives `ExtensionAPI`.

## Workspace initialization

`initialize-workspace.ts` runs on Pi session startup. It searches from the session cwd up to the nearest `flake.nix`; when found on NixOS with `direnv` installed, it ensures `.envrc` contains `use flake` and `watch_file nix/*.nix`, then runs `direnv allow` from the flake root.

Spawned agents set `PI_SUBAGENT=1`. When this extension sees that environment variable and `nix` is available, it overrides only that subprocess's `bash` tool so bash commands run through `nix develop <flake-root> -c bash -lc ...`. The main Pi process still uses its normal bash tool.

Builder agents opt in to loading extensions so this startup hook and subagent-only bash wrapper run inside spawned builder subprocesses.

## Subagents

`subagent/` registers:

| Tool | Purpose |
| --- | --- |
| `agent_list` | List agents discovered from `~/.pi/agent/agents` and, when requested, trusted project `.pi/agents` directories. |
| `subagent` | Spawn one or more agents in isolated `pi --mode json --no-session` subprocesses. |

Subagent subprocesses use `--no-extensions` by default unless an agent frontmatter sets `includeExtensions: true`; pass `includeExtensions` to the tool to override that behavior for a specific call.

It also registers `/agents [user|project|both]` for interactive discovery.

## Planner-builder workflow

`planner-builder/` registers:

| Tool | Purpose |
| --- | --- |
| `plan_file_create` | Run the `planner` agent with the model and effort selected in the main pi process and save a structured plan file under `.pi/plans`. |
| `plan_file_build` | Run `builder` agents with the model and effort selected in the main pi process for ready independent tasks in parallel Jujutsu workspaces, show all live agent outputs in a collapsible dashboard, serially integrate each atomic `jj` commit, then run `verifier` with the same selection to write `.pi/outputs/findings.html`. |
| `plan_file_list` | List recent plan files. |

It also registers `/plan-create`, `/plan-build`, and `/plan-list`.

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

`modules/home/dev/ai.nix` installs `mcp-remote` as a Nix/Home Manager command wrapper for Linux/NixOS. The wrapper runs `npx -y mcp-remote` with Nix's `nodejs` in PATH.

Registered loader tools, tool prefixes, and commands:

| Extension | Loader tool | MCP tool prefix after load | Commands |
| --- | --- | --- | --- |
| `linear_mcp.ts` | `linear_mcp_load` | `linear_` | `/linear-mcp-status`, `/linear-mcp-reload` |
| `pulumi_mcp.ts` | `pulumi_mcp_load` | `pulumi_` | `/pulumi-mcp-status`, `/pulumi-mcp-reload` |

The first lazy load may require the OAuth flow that `mcp-remote` opens/prompts for.
