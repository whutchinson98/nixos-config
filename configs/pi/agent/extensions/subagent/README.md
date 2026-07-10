# Subagent extension

Adds tools that let pi discover and spawn the markdown agents in `~/.pi/agent/agents`.

## Tools

- `agent_list` lists discovered agents.
- `subagent` runs one agent, parallel agents, or a sequential chain in isolated `pi --mode json --no-session` subprocesses.

Default scope is user agents only (`~/.pi/agent/agents`). Project agents from `.pi/agents` are opt-in with `agentScope: "project"` or `"both"`; interactive sessions ask for confirmation before running project-local agents.

Subagent subprocesses pass `--no-extensions` by default to avoid recursive agent tools and side effects from other extensions. Set `includeExtensions: true` when a delegated agent explicitly needs extension-provided tools.

An agent can include `ask_user` in its frontmatter tool allowlist to pause and surface a material question through the parent pi UI. The subagent extension injects only the isolated question bridge into that subprocess, waits for the user's answer, and resumes the same agent run. In parallel mode, questions are presented one at a time. Non-interactive runs tell the agent to proceed with and document a safe assumption.

## Commands

- `/agents [user|project|both]` shows discovered agents in the UI.

## Agent files

Agents are markdown files with frontmatter:

```markdown
---
name: planner
description: Architecture and implementation planning
tools: read,grep,find,ls,ask_user
model: claude-sonnet-4-5
---

System prompt for the delegated agent.
```

The existing agents live in `configs/pi/agent/agents` and are linked by Home Manager to `~/.pi/agent/agents`.
