import { randomBytes } from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export type PlanTaskResultMarker = "done" | "failed" | "blocked";
export type HerdrAgentStatus = "working" | "blocked" | "done" | "idle" | "unknown";
export type HerdrBuilderStopReason =
  | "completed"
  | "aborted"
  | "stuck"
  | "missing-agent"
  | "missing-pane"
  | "error";

export interface HerdrCommandResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

export type HerdrCommandRunner = (args: readonly string[]) => Promise<HerdrCommandResult>;

export interface HerdrBuilderMonitorOptions {
  enabled?: boolean;
  pollIntervalMs?: number;
  reportIntervalMs?: number;
  stuckTimeoutMs?: number;
  maxRestarts?: number;
}

export interface HerdrBuilderSnapshot {
  attempt: number;
  maxAttempts: number;
  agentName: string;
  status: HerdrAgentStatus;
  output: string;
  progressMessage: string;
  lastActivityAt: number;
}

export interface HerdrBuilderAttemptSummary {
  attempt: number;
  agentName: string;
  exitCode: number;
  stopReason: HerdrBuilderStopReason;
  terminalId?: string;
  paneId?: string;
  tabId?: string;
  workspaceId?: string;
  lastStatus: HerdrAgentStatus;
  lastProgress: string;
  errorMessage?: string;
  output: string;
}

export interface HerdrBuilderResult {
  exitCode: number;
  stopReason: HerdrBuilderStopReason;
  finalOutput: string;
  liveOutput: string;
  marker?: PlanTaskResultMarker;
  progressMessage: string;
  errorMessage?: string;
  restartCount: number;
  attempts: HerdrBuilderAttemptSummary[];
  terminalId?: string;
  paneId?: string;
  tabId?: string;
  workspaceId?: string;
}

export interface RunHerdrBuilderOptions {
  runner: HerdrCommandRunner;
  cwd: string;
  workspaceId: string;
  sourceWorkspaceId: string;
  agentName: string;
  piArgv: readonly string[];
  prompt: string;
  environment?: Readonly<Record<string, string>>;
  monitor?: HerdrBuilderMonitorOptions;
  signal?: AbortSignal;
  onSnapshot?: (snapshot: HerdrBuilderSnapshot) => void;
  tempDirectory?: string;
  runId?: string;
  now?: () => number;
  sleep?: (milliseconds: number, signal?: AbortSignal) => Promise<void>;
}

interface MonitorConfig {
  enabled: boolean;
  pollIntervalMs: number;
  reportIntervalMs: number;
  stuckTimeoutMs: number;
  maxRestarts: number;
}

interface StartedAgent {
  terminalId: string;
  paneId: string;
  tabId?: string;
  workspaceId?: string;
  status: HerdrAgentStatus;
}

interface AgentPollResult {
  missing: boolean;
  status: HerdrAgentStatus;
  errorMessage?: string;
}

interface PaneReadResult {
  missing: boolean;
  output: string;
  errorMessage?: string;
}

interface AttemptContext {
  options: RunHerdrBuilderOptions;
  monitor: MonitorConfig;
  promptPath: string;
  runId: string;
  attempt: number;
  maxAttempts: number;
  now: () => number;
  sleep: (milliseconds: number, signal?: AbortSignal) => Promise<void>;
}

const DEFAULT_POLL_INTERVAL_MS = 1_000;
const DEFAULT_REPORT_INTERVAL_MS = 30_000;
const DEFAULT_STUCK_TIMEOUT_MS = 15 * 60 * 1_000;
const MAX_AGENT_NAME_LENGTH = 96;

export function parsePlanTaskResultMarker(output: string): PlanTaskResultMarker | undefined {
  let marker: PlanTaskResultMarker | undefined;
  let fence: "```" | "~~~" | undefined;

  for (const rawLine of output.split(/\r?\n/)) {
    const line = rawLine.trim();
    const fenceMatch = line.match(/^(```|~~~)/);
    if (fenceMatch) {
      const delimiter = fenceMatch[1] as "```" | "~~~";
      if (!fence) fence = delimiter;
      else if (fence === delimiter) fence = undefined;
      continue;
    }
    if (fence) continue;

    const match = line.match(/^PLAN_TASK_RESULT:\s*(done|failed|blocked)$/i);
    if (match) marker = match[1]?.toLowerCase() as PlanTaskResultMarker;
  }

  return marker;
}

export async function runHerdrBuilder(options: RunHerdrBuilderOptions): Promise<HerdrBuilderResult> {
  validateOptions(options);

  const monitor = resolveMonitorConfig(options.monitor);
  const now = options.now ?? Date.now;
  const sleep = options.sleep ?? delay;
  const maxAttempts = monitor.enabled ? monitor.maxRestarts + 1 : 1;
  const runId = sanitizeName(options.runId ?? randomBytes(5).toString("hex"));
  const attempts: HerdrBuilderAttemptSummary[] = [];
  const promptDirectory = await fs.promises.mkdtemp(
    path.join(options.tempDirectory ?? os.tmpdir(), "pi-herdr-builder-"),
  );
  const promptPath = path.join(promptDirectory, "task-prompt.md");

  try {
    await fs.promises.writeFile(promptPath, options.prompt, { encoding: "utf8", flag: "wx", mode: 0o600 });
    await fs.promises.chmod(promptPath, 0o600);

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const summary = await runAttempt({
        options,
        monitor,
        promptPath,
        runId,
        attempt,
        maxAttempts,
        now,
        sleep,
      });
      attempts.push(summary);

      const shouldRestart =
        summary.stopReason === "stuck" && !options.signal?.aborted && attempt < maxAttempts;
      if (shouldRestart) continue;

      return resultFromAttempts(attempts);
    }
  } finally {
    await fs.promises.rm(promptDirectory, { recursive: true, force: true });
  }

  throw new Error("Herdr builder restart loop exited without a result.");
}

async function runAttempt(context: AttemptContext): Promise<HerdrBuilderAttemptSummary> {
  const { options, attempt, maxAttempts, monitor, now, sleep } = context;
  const agentName = uniqueAgentName(options.agentName, attempt, context.runId);
  const startedAt = now();
  let lastActivityAt = startedAt;
  let nextReportAt = startedAt + monitor.reportIntervalMs;
  let lastStatus: HerdrAgentStatus = "unknown";
  let output = "";
  let promptSubmitted = false;
  let observedWork = false;
  let started: StartedAgent | undefined;

  function progressMessage(message: string): string {
    return `${agentName} attempt ${attempt}/${maxAttempts}: ${message}`;
  }

  function emit(message: string): void {
    options.onSnapshot?.({
      attempt,
      maxAttempts,
      agentName,
      status: lastStatus,
      output,
      progressMessage: progressMessage(message),
      lastActivityAt,
    });
  }

  function finish(
    stopReason: HerdrBuilderStopReason,
    exitCode: number,
    message: string,
    errorMessage?: string,
  ): HerdrBuilderAttemptSummary {
    emit(message);
    return {
      attempt,
      agentName,
      exitCode,
      stopReason,
      terminalId: started?.terminalId,
      paneId: started?.paneId,
      tabId: started?.tabId,
      workspaceId: started?.workspaceId,
      lastStatus,
      lastProgress: progressMessage(message),
      errorMessage,
      output,
    };
  }

  try {
    if (options.signal?.aborted) {
      return finish("aborted", 130, "cancelled before the agent started.", "Builder run was aborted.");
    }

    const startResult = await options.runner(buildStartArgs(context, agentName));
    if (startResult.exitCode !== 0) {
      const errorMessage = commandFailure("herdr agent start", startResult);
      return finish("error", 1, "could not start the Pi pane.", errorMessage);
    }

    started = parseStartedAgent(startResult.stdout);
    lastStatus = started.status;

    if (options.signal?.aborted) {
      await cancelAndClosePane(options.runner, started.paneId);
      return finish("aborted", 130, "cancelled while the agent was starting.", "Builder run was aborted.");
    }

    const focusError = await focusAgentAndRestoreWorkspace(
      options.runner,
      started.terminalId,
      options.sourceWorkspaceId,
    );
    if (focusError) {
      await closePane(options.runner, started.paneId);
      return finish("error", 1, "could not focus the Pi pane and restore the source workspace.", focusError);
    }

    emit(`started in Herdr workspace ${options.workspaceId}.`);

    while (true) {
      if (options.signal?.aborted) {
        await cancelAndClosePane(options.runner, started.paneId);
        return finish("aborted", 130, "cancelled and closed the Pi pane.", "Builder run was aborted.");
      }

      const agent = await pollAgent(options.runner, started.terminalId);
      if (agent.missing) {
        await closePane(options.runner, started.paneId);
        return finish("missing-agent", 1, "agent pane disappeared.", agent.errorMessage);
      }

      const pane = await readPane(options.runner, started.paneId);
      if (pane.missing) {
        await closePane(options.runner, started.paneId);
        return finish("missing-pane", 1, "pane disappeared while the agent was running.", pane.errorMessage);
      }

      const polledAt = now();
      const statusChanged = agent.status !== lastStatus;
      if (statusChanged) {
        lastStatus = agent.status;
        lastActivityAt = polledAt;
        if (promptSubmitted && (lastStatus === "working" || lastStatus === "blocked")) observedWork = true;
      }

      const outputChanged = pane.output !== output;
      if (outputChanged) {
        output = pane.output;
        lastActivityAt = polledAt;
      }

      if (options.signal?.aborted) {
        await cancelAndClosePane(options.runner, started.paneId);
        return finish("aborted", 130, "cancelled and closed the Pi pane.", "Builder run was aborted.");
      }

      // Herdr's first idle state means the interactive Pi TUI is ready, not that the task completed.
      if (!promptSubmitted && (lastStatus === "idle" || lastStatus === "done")) {
        const submitResult = await options.runner(["pane", "run", started.paneId, `@${context.promptPath}`]);
        if (submitResult.exitCode !== 0) {
          const errorMessage = commandFailure("herdr pane run", submitResult);
          await closePane(options.runner, started.paneId);
          return finish("error", 1, "could not submit the task prompt to the Pi pane.", errorMessage);
        }

        promptSubmitted = true;
        observedWork = false;
        lastActivityAt = polledAt;
        nextReportAt = polledAt + monitor.reportIntervalMs;
        emit("Pi reached its initial idle prompt; submitted the task.");
        await sleep(monitor.pollIntervalMs, options.signal);
        continue;
      }

      const hasResultMarker = promptSubmitted && parsePlanTaskResultMarker(output) !== undefined;
      const completed =
        promptSubmitted &&
        (lastStatus === "done" || (lastStatus === "idle" && (observedWork || hasResultMarker)));
      if (completed) return finish("completed", 0, `completed with Herdr status ${lastStatus}.`);

      if (statusChanged || outputChanged) emit(`status ${lastStatus}; lifecycle or pane output activity observed.`);

      if (monitor.enabled && polledAt - lastActivityAt >= monitor.stuckTimeoutMs) {
        await cancelAndClosePane(options.runner, started.paneId);
        const errorMessage = `No Herdr status or pane output activity for ${monitor.stuckTimeoutMs}ms.`;
        return finish("stuck", 124, "stuck timeout reached; cancelled and closed the Pi pane.", errorMessage);
      }

      if (polledAt >= nextReportAt) {
        emit(`monitor: status ${lastStatus}; last activity ${polledAt - lastActivityAt}ms ago.`);
        nextReportAt = polledAt + monitor.reportIntervalMs;
      }

      await sleep(monitor.pollIntervalMs, options.signal);
    }
  } catch (error) {
    if (started) {
      if (options.signal?.aborted) await cancelAndClosePane(options.runner, started.paneId);
      else await closePane(options.runner, started.paneId);
    }

    const errorMessage = error instanceof Error ? error.message : String(error);
    if (options.signal?.aborted) {
      return finish("aborted", 130, "cancelled and closed the Pi pane.", "Builder run was aborted.");
    }
    return finish("error", 1, "Herdr command failed.", errorMessage);
  }
}

function buildStartArgs(context: AttemptContext, agentName: string): string[] {
  const { options } = context;
  const args = [
    "agent",
    "start",
    agentName,
    "--cwd",
    options.cwd,
    "--workspace",
    options.workspaceId,
  ];

  for (const [key, value] of Object.entries(options.environment ?? {}).sort(([left], [right]) => left.localeCompare(right))) {
    args.push("--env", `${key}=${value}`);
  }

  args.push("--no-focus", "--", ...options.piArgv);
  return args;
}

async function focusAgentAndRestoreWorkspace(
  runner: HerdrCommandRunner,
  terminalId: string,
  sourceWorkspaceId: string,
): Promise<string | undefined> {
  let errorMessage: string | undefined;

  try {
    const focus = await runner(["agent", "focus", terminalId]);
    if (focus.exitCode !== 0) errorMessage = commandFailure("herdr agent focus", focus);
  } catch (error) {
    errorMessage = error instanceof Error ? error.message : String(error);
  }

  try {
    const restore = await runner(["workspace", "focus", sourceWorkspaceId]);
    if (restore.exitCode !== 0) {
      const restoreError = commandFailure("herdr workspace focus", restore);
      errorMessage = errorMessage ? `${errorMessage}\n${restoreError}` : restoreError;
    }
  } catch (error) {
    const restoreError = error instanceof Error ? error.message : String(error);
    errorMessage = errorMessage ? `${errorMessage}\n${restoreError}` : restoreError;
  }

  return errorMessage;
}

async function pollAgent(runner: HerdrCommandRunner, terminalId: string): Promise<AgentPollResult> {
  const result = await runner(["agent", "get", terminalId]);
  if (result.exitCode !== 0) {
    const errorMessage = commandFailure("herdr agent get", result);
    if (isMissingError(result)) return { missing: true, status: "unknown", errorMessage };
    throw new Error(errorMessage);
  }

  const response = parseJsonObject(result.stdout, "herdr agent get");
  const resultObject = recordField(response, "result");
  const agent = resultObject ? recordField(resultObject, "agent") : undefined;
  if (!agent) {
    return { missing: true, status: "unknown", errorMessage: "herdr agent get returned no agent." };
  }

  return { missing: false, status: normalizeStatus(agent.agent_status ?? agent.status) };
}

async function readPane(runner: HerdrCommandRunner, paneId: string): Promise<PaneReadResult> {
  const result = await runner([
    "pane",
    "read",
    paneId,
    "--source",
    "recent-unwrapped",
    "--lines",
    "1000",
  ]);
  if (result.exitCode === 0) return { missing: false, output: result.stdout };

  const errorMessage = commandFailure("herdr pane read", result);
  if (isMissingError(result)) return { missing: true, output: "", errorMessage };
  throw new Error(errorMessage);
}

async function cancelAndClosePane(runner: HerdrCommandRunner, paneId: string): Promise<void> {
  await runIgnoringFailure(runner, ["pane", "send-keys", paneId, "esc"]);
  await closePane(runner, paneId);
}

async function closePane(runner: HerdrCommandRunner, paneId: string): Promise<void> {
  await runIgnoringFailure(runner, ["pane", "close", paneId]);
}

async function runIgnoringFailure(runner: HerdrCommandRunner, args: readonly string[]): Promise<void> {
  try {
    await runner(args);
  } catch {
    // Best-effort cleanup must not replace the attempt's original result.
  }
}

function parseStartedAgent(output: string): StartedAgent {
  const response = parseJsonObject(output, "herdr agent start");
  const result = recordField(response, "result");
  const agent = result ? recordField(result, "agent") : undefined;
  if (!agent) throw new Error("herdr agent start returned no agent.");

  const terminalId = stringField(agent, "terminal_id");
  const paneId = stringField(agent, "pane_id");
  if (!terminalId || !paneId) throw new Error("herdr agent start did not return terminal and pane ids.");

  return {
    terminalId,
    paneId,
    tabId: stringField(agent, "tab_id"),
    workspaceId: stringField(agent, "workspace_id"),
    status: normalizeStatus(agent.agent_status ?? agent.status),
  };
}

function resultFromAttempts(attempts: HerdrBuilderAttemptSummary[]): HerdrBuilderResult {
  const finalAttempt = attempts.at(-1);
  if (!finalAttempt) throw new Error("Herdr builder produced no attempt result.");

  return {
    exitCode: finalAttempt.exitCode,
    stopReason: finalAttempt.stopReason,
    finalOutput: finalAttempt.output,
    liveOutput: finalAttempt.output,
    marker: parsePlanTaskResultMarker(finalAttempt.output),
    progressMessage: finalAttempt.lastProgress,
    errorMessage: finalAttempt.errorMessage,
    restartCount: attempts.length - 1,
    attempts,
    terminalId: finalAttempt.terminalId,
    paneId: finalAttempt.paneId,
    tabId: finalAttempt.tabId,
    workspaceId: finalAttempt.workspaceId,
  };
}

function resolveMonitorConfig(options: HerdrBuilderMonitorOptions | undefined): MonitorConfig {
  const config: MonitorConfig = {
    enabled: options?.enabled ?? true,
    pollIntervalMs: options?.pollIntervalMs ?? DEFAULT_POLL_INTERVAL_MS,
    reportIntervalMs: options?.reportIntervalMs ?? DEFAULT_REPORT_INTERVAL_MS,
    stuckTimeoutMs: options?.stuckTimeoutMs ?? DEFAULT_STUCK_TIMEOUT_MS,
    maxRestarts: options?.maxRestarts ?? 1,
  };

  for (const [name, value] of [
    ["pollIntervalMs", config.pollIntervalMs],
    ["reportIntervalMs", config.reportIntervalMs],
    ["stuckTimeoutMs", config.stuckTimeoutMs],
  ] as const) {
    if (!Number.isFinite(value) || value <= 0) throw new Error(`${name} must be a positive number.`);
  }
  if (!Number.isInteger(config.maxRestarts) || config.maxRestarts < 0) {
    throw new Error("maxRestarts must be a non-negative integer.");
  }

  return config;
}

function validateOptions(options: RunHerdrBuilderOptions): void {
  if (!options.cwd) throw new Error("cwd is required.");
  if (!options.workspaceId) throw new Error("workspaceId is required.");
  if (!options.sourceWorkspaceId) throw new Error("sourceWorkspaceId is required.");
  if (!options.agentName) throw new Error("agentName is required.");
  if (options.piArgv.length === 0) throw new Error("piArgv must contain the Pi executable.");

  const piOptions = options.piArgv.slice(1);
  if (piOptions.some((argument) => argument === "-p" || argument === "--mode" || argument.startsWith("--mode="))) {
    throw new Error("piArgv must start Pi in its native interactive mode, without -p or --mode.");
  }

  for (const key of Object.keys(options.environment ?? {})) {
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) throw new Error(`Invalid environment variable name: ${key}`);
  }
}

function uniqueAgentName(baseName: string, attempt: number, runId: string): string {
  const suffix = `-attempt-${attempt}-${runId}`;
  const availableLength = Math.max(1, MAX_AGENT_NAME_LENGTH - suffix.length);
  return `${sanitizeName(baseName).slice(0, availableLength)}${suffix}`;
}

function sanitizeName(value: string): string {
  return value.replace(/[^A-Za-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "") || "builder";
}

function normalizeStatus(value: unknown): HerdrAgentStatus {
  if (value === "working" || value === "blocked" || value === "done" || value === "idle") return value;
  return "unknown";
}

function parseJsonObject(output: string, command: string): Record<string, unknown> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(output);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`${command} returned invalid JSON: ${message}`);
  }
  if (!isRecord(parsed)) throw new Error(`${command} returned a non-object JSON response.`);
  return parsed;
}

function recordField(record: Record<string, unknown>, key: string): Record<string, unknown> | undefined {
  const value = record[key];
  return isRecord(value) ? value : undefined;
}

function stringField(record: Record<string, unknown>, key: string): string | undefined {
  const value = record[key];
  return typeof value === "string" && value ? value : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isMissingError(result: HerdrCommandResult): boolean {
  const message = `${result.stderr}\n${result.stdout}`;
  return /(?:agent|pane)_not_found|not found|does not exist/i.test(message);
}

function commandFailure(command: string, result: HerdrCommandResult): string {
  const detail = (result.stderr || result.stdout).trim();
  return `${command} failed with exit code ${result.exitCode}${detail ? `: ${detail}` : "."}`;
}

async function delay(milliseconds: number, signal?: AbortSignal): Promise<void> {
  if (signal?.aborted) return;

  await new Promise<void>((resolve) => {
    const timer = setTimeout(finish, milliseconds);
    const abort = () => finish();

    function finish(): void {
      clearTimeout(timer);
      signal?.removeEventListener("abort", abort);
      resolve();
    }

    signal?.addEventListener("abort", abort, { once: true });
  });
}
