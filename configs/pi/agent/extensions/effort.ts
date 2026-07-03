import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const levels = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;
type Level = (typeof levels)[number];

function isLevel(value: string): value is Level {
  return (levels as readonly string[]).includes(value);
}

function nextLevel(current: string): Level {
  const index = levels.indexOf(current as Level);
  return levels[(index + 1) % levels.length];
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("effort", {
    description: "Set thinking effort: off|minimal|low|medium|high|xhigh",
    handler: async (args, ctx) => {
      const level = args.trim();

      if (!isLevel(level)) {
        ctx.ui.notify(
          `Usage: /effort ${levels.join("|")}. Current: ${pi.getThinkingLevel()}`,
          "warning",
        );
        return;
      }

      pi.setThinkingLevel(level);
      ctx.ui.notify(`Thinking level set to ${pi.getThinkingLevel()}`, "success");
    },
  });

  pi.registerCommand("effort-cycle", {
    description: "Cycle thinking effort",
    handler: async (_args, ctx) => {
      const next = nextLevel(pi.getThinkingLevel());
      pi.setThinkingLevel(next);
      ctx.ui.notify(`Thinking level set to ${pi.getThinkingLevel()}`, "success");
    },
  });

  pi.registerShortcut("ctrl+e", {
    description: "Cycle thinking effort",
    handler: async (ctx) => {
      const next = nextLevel(pi.getThinkingLevel());
      pi.setThinkingLevel(next);
      ctx.ui.notify(`Thinking level set to ${pi.getThinkingLevel()}`, "success");
    },
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (event.prompt.includes("#deep")) {
      pi.setThinkingLevel("high");
      ctx.ui.notify("Using high thinking for this prompt", "info");
    }

    if (event.prompt.includes("#quick")) {
      pi.setThinkingLevel("minimal");
      ctx.ui.notify("Using minimal thinking for this prompt", "info");
    }
  });
}
