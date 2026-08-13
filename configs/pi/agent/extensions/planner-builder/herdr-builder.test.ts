import * as fs from "node:fs";
import { describe, expect, test } from "bun:test";
import {
  type HerdrCommandResult,
  type HerdrCommandRunner,
  parsePlanTaskResultMarker,
  runHerdrBuilder,
  type RunHerdrBuilderOptions,
} from "./herdr-builder";

type FakeStatus = "working" | "blocked" | "done" | "idle" | "unknown" | "unexpected";

interface AttemptScript {
  statuses: FakeStatus[];
  outputs: string[];
  initialStatus?: FakeStatus;
  missingAgentAt?: number;
  missingPaneAt?: number;
}

interface FakeRunnerOptions {
  scripts: AttemptScript[];
  onStart?: (args: readonly string[]) => void | Promise<void>;
  onCommand?: (args: readonly string[]) => void | Promise<void>;
}

class FakeHerdrRunner {
  readonly calls: string[][] = [];
  private readonly pollIndexes = new Map<number, number>();
  private startCount = 0;

  constructor(private readonly options: FakeRunnerOptions) {}

  readonly run: HerdrCommandRunner = async (rawArgs) => {
    const args = [...rawArgs];
    this.calls.push(args);
    await this.options.onCommand?.(args);

    const command = args.slice(0, 2).join(" ");
    if (command === "agent start") return await this.start(args);
    if (command === "agent focus" || command === "workspace focus") return jsonResult({ type: "ok" });
    if (command === "agent get") return this.getAgent(args[2] ?? "");
    if (command === "pane read") return this.readPane(args[2] ?? "");
    if (command === "pane run" || command === "pane send-keys" || command === "pane close") {
      return jsonResult({ type: "ok" });
    }
    throw new Error(`Unexpected fake Herdr command: ${args.join(" ")}`);
  };

  commands(command: string): string[][] {
    return this.calls.filter((args) => args.slice(0, 2).join(" ") === command);
  }

  private async start(args: readonly string[]): Promise<HerdrCommandResult> {
    const attempt = this.startCount;
    this.startCount += 1;
    this.pollIndexes.set(attempt, 0);
    await this.options.onStart?.(args);

    const script = this.script(attempt);
    return jsonResult({
      type: "agent_started",
      agent: {
        name: args[2],
        terminal_id: `terminal-${attempt + 1}`,
        pane_id: `pane-${attempt + 1}`,
        tab_id: `tab-${attempt + 1}`,
        workspace_id: "task-workspace",
        agent_status: script.initialStatus ?? "unknown",
      },
    });
  }

  private getAgent(terminalId: string): HerdrCommandResult {
    const attempt = idIndex(terminalId);
    const poll = this.pollIndexes.get(attempt) ?? 0;
    const script = this.script(attempt);
    if (script.missingAgentAt === poll) {
      return failure(`{"error":{"code":"agent_not_found","message":"${terminalId} not found"}}`);
    }

    return jsonResult({
      type: "agent_info",
      agent: {
        terminal_id: terminalId,
        pane_id: `pane-${attempt + 1}`,
        agent_status: sequenceValue(script.statuses, poll),
      },
    });
  }

  private readPane(paneId: string): HerdrCommandResult {
    const attempt = idIndex(paneId);
    const poll = this.pollIndexes.get(attempt) ?? 0;
    const script = this.script(attempt);
    if (script.missingPaneAt === poll) {
      return failure(`{"code":"pane_not_found","message":"${paneId} not found"}`);
    }

    this.pollIndexes.set(attempt, poll + 1);
    return success(sequenceValue(script.outputs, poll));
  }

  private script(attempt: number): AttemptScript {
    const script = this.options.scripts[attempt];
    if (!script) throw new Error(`No fake script for attempt ${attempt + 1}`);
    return script;
  }
}

function idIndex(id: string): number {
  const number = Number(id.match(/(\d+)$/)?.[1]);
  if (!number) throw new Error(`Fake id has no numeric suffix: ${id}`);
  return number - 1;
}

function sequenceValue<T>(values: T[], index: number): T {
  const value = values[Math.min(index, values.length - 1)];
  if (value === undefined) throw new Error("Fake sequence must not be empty.");
  return value;
}

function success(stdout = ""): HerdrCommandResult {
  return { exitCode: 0, stdout, stderr: "" };
}

function failure(stderr: string): HerdrCommandResult {
  return { exitCode: 1, stdout: "", stderr };
}

function jsonResult(result: Record<string, unknown>): HerdrCommandResult {
  return success(JSON.stringify({ id: "fake", result }));
}

function defaultOptions(fake: FakeHerdrRunner, overrides: Partial<RunHerdrBuilderOptions> = {}): RunHerdrBuilderOptions {
  return {
    runner: fake.run,
    cwd: "/workspace/task checkout",
    workspaceId: "task-workspace",
    sourceWorkspaceId: "source-workspace",
    agentName: "T01 builder",
    piArgv: ["pi", "--model", "openai/gpt-test"],
    prompt: "Implement T01.",
    runId: "test-run",
    monitor: {
      pollIntervalMs: 10,
      reportIntervalMs: 20,
      stuckTimeoutMs: 100,
      maxRestarts: 0,
    },
    sleep: async function sleep(): Promise<void> {},
    ...overrides,
  };
}

describe("parsePlanTaskResultMarker", () => {
  test("accepts only standalone markers outside prompt examples and returns the last marker", () => {
    const output = [
      "The prompt says PLAN_TASK_RESULT: blocked as an example.",
      "- PLAN_TASK_RESULT: failed",
      "```text",
      "PLAN_TASK_RESULT: blocked",
      "```",
      "PLAN_TASK_RESULT: failed extra text",
      "  PLAN_TASK_RESULT: failed  ",
      "work continued",
      "PLAN_TASK_RESULT: done",
    ].join("\n");

    expect(parsePlanTaskResultMarker(output)).toBe("done");
    expect(parsePlanTaskResultMarker("PLAN_TASK_RESULT: BLOCKED\n")).toBe("blocked");
    expect(parsePlanTaskResultMarker("prefix PLAN_TASK_RESULT: done")).toBeUndefined();
  });
});

describe("runHerdrBuilder", () => {
  test("starts Pi with literal argv and submits a mode-0600 prompt file after initial idle", async () => {
    const hostilePrompt = "quotes ' \"; $(touch /tmp/nope)\nPLAN_TASK_RESULT: failed";
    const hostileEnvironment = "name with spaces; $(echo unsafe)\nsecond line";
    let promptPath = "";
    const fake = new FakeHerdrRunner({
      scripts: [
        {
          statuses: ["idle", "working", "done"],
          outputs: ["Pi ready", "Pi working", "Finished\nPLAN_TASK_RESULT: done\n"],
        },
      ],
      onStart(args) {
        const separator = args.indexOf("--");
        const piArgs = args.slice(separator + 1);
        expect(args).not.toContain(hostilePrompt);
        expect(piArgs).toEqual([
          "/nix/store/pi binary/bin/pi",
          "--no-session",
          "--model",
          "provider/model;$(unsafe)",
          "--thinking",
          "xhigh",
          "--tools",
          "read,bash",
          "--no-extensions",
          "-e",
          "/tmp/max effort extension.ts",
          "--append-system-prompt",
          "/tmp/system prompt.md",
        ]);
      },
      onCommand(args) {
        if (args.slice(0, 2).join(" ") !== "pane run") return;
        const promptArgument = args[3] ?? "";
        expect(args.slice(0, 3)).toEqual(["pane", "run", "pane-1"]);
        expect(promptArgument.startsWith("@")).toBe(true);
        promptPath = promptArgument.slice(1);
        expect(fs.readFileSync(promptPath, "utf8")).toBe(hostilePrompt);
        expect(fs.statSync(promptPath).mode & 0o777).toBe(0o600);
      },
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        cwd: "/checkout/with spaces;$(unsafe)",
        piArgv: [
          "/nix/store/pi binary/bin/pi",
          "--no-session",
          "--model",
          "provider/model;$(unsafe)",
          "--thinking",
          "xhigh",
          "--tools",
          "read,bash",
          "--no-extensions",
          "-e",
          "/tmp/max effort extension.ts",
          "--append-system-prompt",
          "/tmp/system prompt.md",
        ],
        prompt: hostilePrompt,
        environment: { PI_SUBAGENT: "1", PI_SUBAGENT_NAME: hostileEnvironment },
      }),
    );

    const start = fake.commands("agent start")[0] ?? [];
    expect(start).toContain("/checkout/with spaces;$(unsafe)");
    expect(start).toContain(`PI_SUBAGENT_NAME=${hostileEnvironment}`);
    expect(start).not.toContain("sh");
    expect(start).not.toContain("-c");
    expect(fs.existsSync(promptPath)).toBe(false);
    expect(result.marker).toBe("done");
    expect(fake.commands("agent focus")).toEqual([["agent", "focus", "terminal-1"]]);
    expect(fake.commands("workspace focus")).toEqual([["workspace", "focus", "source-workspace"]]);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("rejects piped Pi modes before starting an agent", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["done"], outputs: ["unused"] }],
    });

    await expect(runHerdrBuilder(defaultOptions(fake, { piArgv: ["pi", "--mode", "json", "-p"] }))).rejects.toThrow(
      "native interactive mode",
    );
    expect(fake.calls).toHaveLength(0);
  });

  test("keeps a naturally completed pane alive for unseen done", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["idle", "working", "done"], outputs: ["ready", "working", "final output"] }],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("completed");
    expect(result.exitCode).toBe(0);
    expect(result.finalOutput).toBe("final output");
    expect(result.attempts[0]?.lastStatus).toBe("done");
    expect(fake.commands("pane send-keys")).toHaveLength(0);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("accepts done on the first poll after submission when completion races monitoring", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["idle", "done"], outputs: ["ready", "quick final output"] }],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("completed");
    expect(fake.commands("agent get")).toHaveLength(2);
    expect(fake.commands("pane run")).toHaveLength(1);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("accepts a viewed idle completion that races the first working poll when final output has a marker", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [
        {
          statuses: ["idle", "idle"],
          outputs: ["ready", "quick final output\nPLAN_TASK_RESULT: done\n"],
        },
      ],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("completed");
    expect(result.marker).toBe("done");
    expect(fake.commands("agent get")).toHaveLength(2);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("waits for initial idle and ignores startup output changes until monitoring observes work", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [
        {
          initialStatus: "working",
          statuses: ["working", "idle", "idle", "working", "idle"],
          outputs: ["", "Pi ready", "task prompt rendered", "working", "final output"],
        },
      ],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("completed");
    expect(result.attempts[0]?.lastStatus).toBe("idle");
    expect(fake.commands("agent get")).toHaveLength(5);
    expect(fake.commands("pane run")).toEqual([["pane", "run", "pane-1", expect.stringMatching(/^@/)]]);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("does not treat initial idle or unknown as completion and accepts viewed idle after blocked work", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [
        {
          statuses: ["idle", "unexpected", "blocked", "unknown", "idle"],
          outputs: ["Pi boot screen"],
        },
      ],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("completed");
    expect(result.attempts[0]?.lastStatus).toBe("idle");
    expect(fake.commands("agent get")).toHaveLength(5);
    expect(fake.commands("pane close")).toHaveLength(0);
  });

  test("changed recent-unwrapped output refreshes stuck activity", async () => {
    let currentTime = 0;
    const snapshots: string[] = [];
    const fake = new FakeHerdrRunner({
      scripts: [
        {
          statuses: ["idle", "working", "working", "working", "working", "done"],
          outputs: ["ready", "boot", "boot", "new tool output", "new tool output", "finished"],
        },
      ],
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        now: () => currentTime,
        sleep: async function sleep(milliseconds): Promise<void> {
          currentTime += milliseconds;
        },
        monitor: {
          pollIntervalMs: 10,
          reportIntervalMs: 20,
          stuckTimeoutMs: 30,
          maxRestarts: 0,
        },
        onSnapshot(snapshot) {
          snapshots.push(snapshot.progressMessage);
        },
      }),
    );

    expect(result.stopReason).toBe("completed");
    expect(result.finalOutput).toBe("finished");
    expect(fake.commands("pane read")[0]).toEqual([
      "pane",
      "read",
      "pane-1",
      "--source",
      "recent-unwrapped",
      "--lines",
      "1000",
    ]);
    expect(snapshots.some((message) => message.includes("monitor:"))).toBe(true);
  });

  test("cancellation sends Escape, closes the pane, and never restarts", async () => {
    let currentTime = 0;
    const controller = new AbortController();
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["idle", "working"], outputs: ["ready", "working"] }],
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        signal: controller.signal,
        now: () => currentTime,
        sleep: async function sleep(milliseconds): Promise<void> {
          currentTime += milliseconds;
          controller.abort();
        },
        monitor: {
          pollIntervalMs: 10,
          reportIntervalMs: 20,
          stuckTimeoutMs: 30,
          maxRestarts: 3,
        },
      }),
    );

    expect(result.stopReason).toBe("aborted");
    expect(result.exitCode).toBe(130);
    expect(fake.commands("agent start")).toHaveLength(1);
    expect(fake.commands("pane send-keys")).toEqual([["pane", "send-keys", "pane-1", "esc"]]);
    expect(fake.commands("pane close")).toEqual([["pane", "close", "pane-1"]]);
  });

  test("cancellation racing agent start still cleans up the new pane", async () => {
    const controller = new AbortController();
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["working"], outputs: ["working"] }],
      onStart() {
        controller.abort();
      },
    });

    const result = await runHerdrBuilder(defaultOptions(fake, { signal: controller.signal }));

    expect(result.stopReason).toBe("aborted");
    expect(fake.commands("agent focus")).toHaveLength(0);
    expect(fake.commands("pane send-keys")).toHaveLength(1);
    expect(fake.commands("pane close")).toHaveLength(1);
  });

  test("restarts only stuck attempts in the same workspace with unique names", async () => {
    let currentTime = 0;
    const fake = new FakeHerdrRunner({
      scripts: [
        { statuses: ["idle", "working"], outputs: ["ready", "attempt one"] },
        {
          statuses: ["idle", "working", "done"],
          outputs: ["ready", "attempt two", "complete\nPLAN_TASK_RESULT: failed"],
        },
      ],
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        now: () => currentTime,
        sleep: async function sleep(milliseconds): Promise<void> {
          currentTime += milliseconds;
        },
        monitor: {
          pollIntervalMs: 10,
          reportIntervalMs: 20,
          stuckTimeoutMs: 30,
          maxRestarts: 1,
        },
      }),
    );

    const starts = fake.commands("agent start");
    expect(starts).toHaveLength(2);
    expect(starts[0]?.[2]).not.toBe(starts[1]?.[2]);
    expect(starts.map((args) => args[args.indexOf("--workspace") + 1])).toEqual([
      "task-workspace",
      "task-workspace",
    ]);
    expect(result.stopReason).toBe("completed");
    expect(result.marker).toBe("failed");
    expect(result.restartCount).toBe(1);
    expect(result.attempts.map((attempt) => attempt.stopReason)).toEqual(["stuck", "completed"]);
    expect(fake.commands("pane send-keys")).toEqual([["pane", "send-keys", "pane-1", "esc"]]);
    expect(fake.commands("pane close")).toEqual([["pane", "close", "pane-1"]]);
  });

  test("reports stuck exhaustion after closing every superseded pane", async () => {
    let currentTime = 0;
    const fake = new FakeHerdrRunner({
      scripts: [
        { statuses: ["idle", "working"], outputs: ["ready", "unchanged one"] },
        { statuses: ["idle", "working"], outputs: ["ready", "unchanged two"] },
      ],
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        now: () => currentTime,
        sleep: async function sleep(milliseconds): Promise<void> {
          currentTime += milliseconds;
        },
        monitor: {
          pollIntervalMs: 10,
          reportIntervalMs: 20,
          stuckTimeoutMs: 30,
          maxRestarts: 1,
        },
      }),
    );

    expect(result.stopReason).toBe("stuck");
    expect(result.exitCode).toBe(124);
    expect(result.restartCount).toBe(1);
    expect(result.attempts).toHaveLength(2);
    expect(fake.commands("pane send-keys")).toHaveLength(2);
    expect(fake.commands("pane close")).toHaveLength(2);
  });

  test("fails promptly when the agent is missing without restarting", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["working"], outputs: ["unused"], missingAgentAt: 0 }],
    });

    const result = await runHerdrBuilder(
      defaultOptions(fake, {
        monitor: {
          pollIntervalMs: 10,
          reportIntervalMs: 20,
          stuckTimeoutMs: 30,
          maxRestarts: 2,
        },
      }),
    );

    expect(result.stopReason).toBe("missing-agent");
    expect(result.exitCode).toBe(1);
    expect(result.restartCount).toBe(0);
    expect(fake.commands("agent start")).toHaveLength(1);
    expect(fake.commands("pane close")).toHaveLength(1);
    expect(fake.commands("pane send-keys")).toHaveLength(0);
  });

  test("fails promptly when a pane is manually closed", async () => {
    const fake = new FakeHerdrRunner({
      scripts: [{ statuses: ["working"], outputs: ["unused"], missingPaneAt: 0 }],
    });

    const result = await runHerdrBuilder(defaultOptions(fake));

    expect(result.stopReason).toBe("missing-pane");
    expect(result.exitCode).toBe(1);
    expect(fake.commands("pane close")).toHaveLength(1);
    expect(fake.commands("pane send-keys")).toHaveLength(0);
  });
});
