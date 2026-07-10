# Pi

Configuration and extension sources for [pi](https://github.com/badlogic/pi-mono).

Pi reads agent-level prompt additions from `~/.pi/agent/APPEND_SYSTEM.md`, keybinding overrides from `~/.pi/agent/keybindings.json`, auto-discovers global skills from `~/.pi/agent/skills`, auto-discovers global agents from `~/.pi/agent/agents`, and auto-discovers global extensions from `~/.pi/agent/extensions`. The home-manager module at `modules/home/dev/ai.nix` links `configs/pi/agent/APPEND_SYSTEM.md`, `configs/pi/agent/keybindings.json`, `configs/pi/agent/skills`, `configs/pi/agent/agents`, and `configs/pi/agent/extensions` there, the same way the Neovim module links `configs/nvim` into `~/.config/nvim`.

Add skills as directories containing `SKILL.md` under `agent/skills/`.

Add agents as markdown files with frontmatter under `agent/agents/`.

Add extensions as either:

- `extensions/my-extension.ts`
- `extensions/my-extension/index.ts` for multi-file extensions

The `agent/extensions/subagent` extension registers `agent_list` and `subagent` tools so pi can list and spawn the agents in `agent/agents/`.

The `agent/extensions/planner-builder` extension registers `plan_file_create`, `plan_file_build`, and `plan_file_list` tools plus `/plan-create`, `/plan-build`, and `/plan-list` commands. It uses the model and effort selected in the main pi process when running the `planner`, `builder`, and `verifier` agents. The planner writes `.pi/plans/*.md` plan files, then builders implement ready independent task blocks in monitored parallel Jujutsu workspaces. A live dashboard shows every builder and verifier output with per-agent collapse controls while the extension cancels/restarts stuck attempts, serially integrates each atomic task commit onto the main workspace, and runs `verifier` to write `.pi/outputs/findings.html`.

After rebuilding home-manager/NixOS, run `/reload` inside pi to pick up changes.
