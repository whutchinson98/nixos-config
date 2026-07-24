import type { ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import {
  type Component,
  Container,
  matchesKey,
  Spacer,
  Text,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@mariozechner/pi-tui";

const DEFAULT_MAXIMUM_VIEW_LINES = 24;

export type AgentDisplayStatus =
  | "starting"
  | "running"
  | "integrating"
  | "pending"
  | "in-progress"
  | "done"
  | "failed"
  | "blocked";

export interface PlanBuildAgentDetails {
  id: string;
  title: string;
  agent: string;
  model?: string;
  status: AgentDisplayStatus;
  output: string;
  progress?: string;
  exitCode?: number;
  workspaceName?: string;
  workspacePath?: string;
  restartCount?: number;
}

export interface PlanBuildDashboardData {
  path: string;
  agents: PlanBuildAgentDetails[];
}

type DashboardView = "list" | "detail";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

export function isPlanBuildDetails(value: unknown): value is PlanBuildDashboardData {
  return isRecord(value) && typeof value.path === "string" && Array.isArray(value.agents);
}

function isActiveAgentStatus(status: AgentDisplayStatus): boolean {
  return status === "starting" || status === "running" || status === "integrating" || status === "in-progress";
}

function styledAgentStatus(status: AgentDisplayStatus, theme: Theme): string {
  switch (status) {
    case "done":
      return theme.fg("success", status);
    case "failed":
      return theme.fg("error", status);
    case "blocked":
      return theme.fg("warning", status);
    case "starting":
    case "running":
    case "integrating":
    case "in-progress":
      return theme.fg("accent", status);
    default:
      return theme.fg("muted", status);
  }
}

function styledAgentMarker(status: AgentDisplayStatus, theme: Theme): string {
  switch (status) {
    case "done":
      return theme.fg("success", "■");
    case "failed":
      return theme.fg("error", "■");
    case "blocked":
      return theme.fg("warning", "■");
    case "starting":
    case "running":
    case "integrating":
    case "in-progress":
      return theme.fg("accent", "●");
    default:
      return theme.fg("muted", "□");
  }
}

function styledAgentModel(model: string | undefined, theme: Theme): string {
  return model ? ` ${theme.fg("muted", `[${model}]`)}` : "";
}

function compactText(text: string, maxLength: number): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, Math.max(0, maxLength - 3))}...`;
}

function wrapOutput(text: string, width: number): string[] {
  if (!text.trim() || width <= 0) return [];

  return text
    .replace(/\r/g, "")
    .split("\n")
    .flatMap((line) => (line ? wrapTextWithAnsi(line, width) : [""]));
}

function wrapOutputTail(text: string, width: number, limit: number): { lines: string[]; omitted: number } {
  const lines = wrapOutput(text, width);
  const omitted = Math.max(0, lines.length - limit);
  return { lines: lines.slice(-limit), omitted };
}

function joinColumns(left: string, right: string, width: number, minimumLeftWidth = 20): string {
  if (!right || width <= minimumLeftWidth + 2) return truncateToWidth(left, width, "");

  const maximumRightWidth = Math.max(1, width - Math.min(minimumLeftWidth, width) - 2);
  const rightColumn = truncateToWidth(right, maximumRightWidth, "");
  const leftColumn = truncateToWidth(left, Math.max(1, width - visibleWidth(rightColumn) - 2), "");
  const spacing = " ".repeat(Math.max(2, width - visibleWidth(leftColumn) - visibleWidth(rightColumn)));
  return truncateToWidth(`${leftColumn}${spacing}${rightColumn}`, width, "");
}

export function renderPlanBuildDetails(details: PlanBuildDashboardData, expanded: boolean, theme: Theme): Component {
  const container = new Container();
  const active = details.agents.filter((agent) => isActiveAgentStatus(agent.status)).length;
  const done = details.agents.filter((agent) => agent.status === "done").length;
  const failed = details.agents.filter((agent) => agent.status === "failed" || agent.status === "blocked").length;
  const summary = [active ? `${active} active` : "", done ? `${done} done` : "", failed ? `${failed} attention` : ""]
    .filter(Boolean)
    .join(" · ");

  container.addChild(
    new Text(
      `${theme.fg("toolTitle", theme.bold("Plan build"))} ${theme.fg("accent", details.path)}${summary ? theme.fg("muted", ` · ${summary}`) : ""}`,
      0,
      0,
    ),
  );

  for (const agent of details.agents) {
    container.addChild(new Spacer(1));
    container.addChild(
      new Text(
        `${theme.fg("muted", "── ")}${theme.fg("accent", agent.id)} ${theme.fg("toolTitle", agent.agent)}${styledAgentModel(agent.model, theme)} ${styledAgentStatus(agent.status, theme)}\n${theme.fg("dim", agent.title)}`,
        0,
        0,
      ),
    );

    if (agent.progress) container.addChild(new Text(theme.fg("muted", compactText(agent.progress, 180)), 0, 0));

    const lineLimit = expanded ? 40 : 3;
    const output = wrapOutputTail(agent.output, 120, lineLimit);
    if (output.omitted > 0) container.addChild(new Text(theme.fg("dim", `... ${output.omitted} earlier output lines`), 0, 0));
    if (output.lines.length > 0) container.addChild(new Text(theme.fg("toolOutput", output.lines.join("\n")), 0, 0));
  }

  if (!details.agents.length) container.addChild(new Text(theme.fg("muted", "Preparing agents..."), 0, 0));
  return container;
}

export class PlanBuildDashboard {
  private details?: PlanBuildDashboardData;
  private selectedIndex = 0;
  private view: DashboardView = "list";
  private detailScrollOffset = 0;
  private detailMaximumScrollOffset = 0;
  private detailPageSize = 1;
  private detailFollowsTail = true;
  private requestRender?: () => void;
  private finishView?: () => void;
  private error?: string;

  constructor(private readonly initialPath: string) {}

  update(details: PlanBuildDashboardData): void {
    const selectedId = this.selectedAgent()?.id;
    this.details = details;
    this.error = undefined;

    if (selectedId) {
      const nextIndex = details.agents.findIndex((agent) => agent.id === selectedId);
      if (nextIndex >= 0) this.selectedIndex = nextIndex;
      else this.view = "list";
    }
    this.selectedIndex = Math.max(0, Math.min(this.selectedIndex, Math.max(0, details.agents.length - 1)));
    this.requestRender?.();
  }

  fail(error: string): void {
    this.error = error;
    this.requestRender?.();
  }

  isVisible(): boolean {
    return this.finishView !== undefined;
  }

  close(): void {
    const finish = this.finishView;
    this.finishView = undefined;
    this.requestRender = undefined;
    finish?.();
  }

  createComponent(
    theme: Theme,
    requestRender: () => void,
    finishView: () => void,
    maximumViewLines: () => number = () => DEFAULT_MAXIMUM_VIEW_LINES,
  ): Component & { dispose(): void } {
    this.requestRender = requestRender;
    this.finishView = finishView;

    return {
      render: (width) => this.render(width, theme, Math.max(1, maximumViewLines())),
      handleInput: (data) => this.handleInput(data),
      invalidate: () => {},
      dispose: () => this.detach(),
    };
  }

  detach(): void {
    this.requestRender = undefined;
    this.finishView = undefined;
  }

  private selectedAgent(): PlanBuildAgentDetails | undefined {
    return this.details?.agents[this.selectedIndex];
  }

  private select(offset: number): void {
    const agents = this.details?.agents ?? [];
    if (agents.length === 0) return;

    this.selectedIndex = (this.selectedIndex + offset + agents.length) % agents.length;
    this.requestRender?.();
  }

  private openSelectedAgent(): void {
    if (!this.selectedAgent()) return;

    this.view = "detail";
    this.detailScrollOffset = 0;
    this.detailMaximumScrollOffset = 0;
    this.detailFollowsTail = true;
    this.requestRender?.();
  }

  private showAgentList(): void {
    this.view = "list";
    this.requestRender?.();
  }

  private scrollDetail(offset: number): void {
    if (offset < 0) this.detailFollowsTail = false;
    this.detailScrollOffset = Math.max(0, Math.min(this.detailScrollOffset + offset, this.detailMaximumScrollOffset));
    if (this.detailScrollOffset === this.detailMaximumScrollOffset) this.detailFollowsTail = true;
    this.requestRender?.();
  }

  private handleInput(data: string): void {
    if (matchesKey(data, "alt+x") || matchesKey(data, "ctrl+c") || data === "q") {
      this.close();
      return;
    }

    if (this.view === "detail") {
      if (data === "h" || matchesKey(data, "left") || matchesKey(data, "escape")) {
        this.showAgentList();
      } else if (data === "j" || matchesKey(data, "down")) {
        this.scrollDetail(1);
      } else if (data === "k" || matchesKey(data, "up")) {
        this.scrollDetail(-1);
      } else if (data === "g" || matchesKey(data, "home")) {
        this.detailFollowsTail = false;
        this.detailScrollOffset = 0;
        this.requestRender?.();
      } else if (data === "G" || matchesKey(data, "end")) {
        this.detailFollowsTail = true;
        this.detailScrollOffset = this.detailMaximumScrollOffset;
        this.requestRender?.();
      } else if (matchesKey(data, "pageDown") || matchesKey(data, "ctrl+d")) {
        this.scrollDetail(this.detailPageSize);
      } else if (matchesKey(data, "pageUp") || matchesKey(data, "ctrl+u")) {
        this.scrollDetail(-this.detailPageSize);
      }
      return;
    }

    if (data === "j" || matchesKey(data, "down")) {
      this.select(1);
    } else if (data === "k" || matchesKey(data, "up")) {
      this.select(-1);
    } else if (data === "l" || matchesKey(data, "right") || matchesKey(data, "enter")) {
      this.openSelectedAgent();
    } else if (matchesKey(data, "escape")) {
      this.close();
    }
  }

  private render(width: number, theme: Theme, maximumViewLines: number): string[] {
    if (width <= 0) return [];
    if (this.view === "detail" && this.selectedAgent()) return this.renderAgentDetail(width, theme, maximumViewLines);
    return this.renderAgentList(width, theme, maximumViewLines);
  }

  private renderAgentList(width: number, theme: Theme, maximumViewLines: number): string[] {
    const details = this.details;
    const agents = details?.agents ?? [];
    const active = agents.filter((agent) => isActiveAgentStatus(agent.status)).length;
    const done = agents.filter((agent) => agent.status === "done").length;
    const attention = agents.filter((agent) => agent.status === "failed" || agent.status === "blocked").length;
    const path = details?.path ?? this.initialPath;
    const lines: string[] = [];
    const push = (line: string) => lines.push(truncateToWidth(line, width, ""));
    const fixedLineCount = 5 + Number(Boolean(this.error)) + Number(agents.length === 0);
    const maximumVisibleAgents = Math.max(1, maximumViewLines - fixedLineCount);
    const selectionPosition = agents.length > maximumVisibleAgents ? ` · ${this.selectedIndex + 1}/${agents.length}` : "";

    push(theme.fg("borderAccent", "─".repeat(width)));
    push(joinColumns(theme.fg("accent", theme.bold("Subagents")), theme.fg("dim", path), width, 14));
    push(
      theme.fg(
        "muted",
        `agents · ${done}/${agents.length} done${active ? ` · ${active} active` : ""}${attention ? ` · ${attention} attention` : ""}${selectionPosition}`,
      ),
    );

    if (this.error) push(theme.fg("error", `Build error: ${this.error}`));
    if (agents.length === 0) push(theme.fg("muted", "  Preparing builder agents..."));

    const firstVisibleIndex = Math.max(
      0,
      Math.min(this.selectedIndex - Math.floor(maximumVisibleAgents / 2), agents.length - maximumVisibleAgents),
    );
    const lastVisibleIndex = Math.min(firstVisibleIndex + maximumVisibleAgents, agents.length);

    for (let index = firstVisibleIndex; index < lastVisibleIndex; index++) {
      const agent = agents[index];
      const selected = index === this.selectedIndex;
      const selector = selected ? theme.fg("accent", "›") : " ";
      const id = selected ? theme.fg("accent", theme.bold(agent.id)) : theme.fg("accent", agent.id);
      const title = selected ? theme.fg("toolTitle", theme.bold(agent.title)) : theme.fg("toolTitle", agent.title);
      const left = `${selector} ${styledAgentMarker(agent.status, theme)} ${id} ${title}`;
      const right = `${theme.fg("muted", agent.agent)} · ${styledAgentStatus(agent.status, theme)}${styledAgentModel(agent.model, theme)}`;
      push(joinColumns(left, right, width, 24));
    }

    push(theme.fg("dim", "j/k or ↑/↓ navigate · enter/l/→ open · esc/q close · Alt+X toggle"));
    push(theme.fg("borderMuted", "─".repeat(width)));
    return lines;
  }

  private renderAgentDetail(width: number, theme: Theme, maximumViewLines: number): string[] {
    const agent = this.selectedAgent();
    if (!agent) return this.renderAgentList(width, theme, maximumViewLines);

    const lines: string[] = [];
    const push = (line: string) => lines.push(truncateToWidth(line, width, ""));
    const outputWidth = Math.max(1, width - 2);
    const output = wrapOutput(agent.output, outputWidth);
    const fixedLineCount = 6 + Number(Boolean(agent.progress)) + Number(Boolean(agent.workspaceName));
    const maximumOutputLines = Math.max(1, maximumViewLines - fixedLineCount - 2);
    this.detailPageSize = Math.max(1, maximumOutputLines - 1);
    this.detailMaximumScrollOffset = Math.max(0, output.length - maximumOutputLines);
    if (this.detailFollowsTail) this.detailScrollOffset = this.detailMaximumScrollOffset;
    else this.detailScrollOffset = Math.min(this.detailScrollOffset, this.detailMaximumScrollOffset);

    const visibleOutput = output.slice(this.detailScrollOffset, this.detailScrollOffset + maximumOutputLines);
    const earlierLines = this.detailScrollOffset;
    const laterLines = Math.max(0, output.length - this.detailScrollOffset - visibleOutput.length);

    push(theme.fg("borderAccent", "─".repeat(width)));
    push(`${theme.fg("accent", "‹ Subagents")} ${theme.fg("muted", "/")} ${theme.fg("accent", theme.bold(agent.id))}`);
    push(theme.fg("toolTitle", theme.bold(agent.title)));
    push(
      `${styledAgentMarker(agent.status, theme)} ${theme.fg("toolTitle", agent.agent)} · ${styledAgentStatus(agent.status, theme)}${styledAgentModel(agent.model, theme)}`,
    );
    if (agent.progress) push(theme.fg("muted", compactText(agent.progress, Math.max(40, width))));
    if (agent.workspaceName) push(theme.fg("dim", `workspace ${agent.workspaceName}`));

    if (earlierLines > 0) push(theme.fg("dim", `  ... ${earlierLines} earlier output lines`));
    if (visibleOutput.length === 0) {
      push(theme.fg("dim", isActiveAgentStatus(agent.status) ? "  (waiting for output)" : "  (no output)"));
    } else {
      for (const outputLine of visibleOutput) push(`  ${theme.fg("toolOutput", outputLine)}`);
    }
    if (laterLines > 0) push(theme.fg("dim", `  ... ${laterLines} later output lines`));

    push(theme.fg("dim", "j/k or ↑/↓ scroll · g/G top/bottom · h/←/esc back · q close"));
    push(theme.fg("borderMuted", "─".repeat(width)));
    return lines;
  }
}

export function showPlanBuildDashboard(ctx: ExtensionContext, dashboard: PlanBuildDashboard): void {
  if (ctx.mode !== "tui" || dashboard.isVisible()) return;

  void ctx.ui
    .custom<void>(
      (tui, theme, _keybindings, done) =>
        dashboard.createComponent(
          theme,
          () => tui.requestRender(),
          () => done(undefined),
          () => Math.max(1, Math.floor(tui.terminal.rows * 0.8) - 1),
        ),
      {
        overlay: true,
        overlayOptions: {
          anchor: "bottom-center",
          width: "100%",
          maxHeight: "80%",
        },
      },
    )
    .catch((error) => {
      ctx.ui.notify(`Planner-builder dashboard failed: ${error instanceof Error ? error.message : String(error)}`, "error");
    })
    .finally(() => dashboard.detach());
}

export function hidePlanBuildDashboard(_ctx: ExtensionContext, dashboard: PlanBuildDashboard): void {
  dashboard.close();
}
