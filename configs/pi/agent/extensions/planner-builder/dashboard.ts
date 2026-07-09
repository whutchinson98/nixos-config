import type { ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import { type Component, Container, Spacer, Text, truncateToWidth, wrapTextWithAnsi } from "@mariozechner/pi-tui";

const PLAN_BUILD_DASHBOARD_WIDGET = "planner-builder-dashboard";
const DASHBOARD_OUTPUT_LINE_LIMIT = 8;

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

function compactText(text: string, maxLength: number): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, Math.max(0, maxLength - 3))}...`;
}

function wrapOutputTail(text: string, width: number, limit: number): { lines: string[]; omitted: number } {
  if (!text.trim() || width <= 0) return { lines: [], omitted: 0 };

  const lines = text.replace(/\r/g, "").split("\n");
  const wrapped = lines.flatMap((line) => (line ? wrapTextWithAnsi(line, width) : [""]));
  const omitted = Math.max(0, wrapped.length - limit);
  return { lines: wrapped.slice(-limit), omitted };
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
        `${theme.fg("muted", "── ")}${theme.fg("accent", agent.id)} ${theme.fg("toolTitle", agent.agent)} ${styledAgentStatus(agent.status, theme)}\n${theme.fg("dim", agent.title)}`,
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
  private readonly collapsedAgentIds = new Set<string>();
  private requestRender?: () => void;
  private error?: string;

  constructor(private readonly initialPath: string) {}

  update(details: PlanBuildDashboardData): void {
    const selectedId = this.selectedAgent()?.id;
    this.details = details;
    this.error = undefined;

    if (selectedId) {
      const nextIndex = details.agents.findIndex((agent) => agent.id === selectedId);
      if (nextIndex >= 0) this.selectedIndex = nextIndex;
    }
    this.selectedIndex = Math.max(0, Math.min(this.selectedIndex, Math.max(0, details.agents.length - 1)));
    this.requestRender?.();
  }

  fail(error: string): void {
    this.error = error;
    this.requestRender?.();
  }

  select(offset: number): string | undefined {
    const agents = this.details?.agents ?? [];
    if (agents.length === 0) return undefined;

    this.selectedIndex = (this.selectedIndex + offset + agents.length) % agents.length;
    this.requestRender?.();
    return this.selectedAgent()?.id;
  }

  toggleSelected(): { id: string; collapsed: boolean } | undefined {
    const selected = this.selectedAgent();
    if (!selected) return undefined;

    if (this.collapsedAgentIds.has(selected.id)) this.collapsedAgentIds.delete(selected.id);
    else this.collapsedAgentIds.add(selected.id);
    this.requestRender?.();
    return { id: selected.id, collapsed: this.collapsedAgentIds.has(selected.id) };
  }

  createComponent(theme: Theme, requestRender: () => void): Component {
    this.requestRender = requestRender;
    return {
      render: (width) => this.render(width, theme),
      invalidate: () => {},
    };
  }

  detach(): void {
    this.requestRender = undefined;
  }

  private selectedAgent(): PlanBuildAgentDetails | undefined {
    return this.details?.agents[this.selectedIndex];
  }

  private render(width: number, theme: Theme): string[] {
    if (width <= 0) return [];

    const details = this.details;
    const agents = details?.agents ?? [];
    const active = agents.filter((agent) => isActiveAgentStatus(agent.status)).length;
    const done = agents.filter((agent) => agent.status === "done").length;
    const attention = agents.filter((agent) => agent.status === "failed" || agent.status === "blocked").length;
    const path = details?.path ?? this.initialPath;
    const lines: string[] = [];
    const push = (line: string) => lines.push(truncateToWidth(line, width, ""));

    push(theme.fg("borderAccent", "─".repeat(width)));
    push(`${theme.fg("accent", theme.bold("PLAN BUILD"))} ${theme.fg("muted", path)}`);
    push(
      theme.fg(
        "dim",
        `${active} active · ${done} done · ${attention} attention · Alt+K/J select · Alt+O collapse · Alt+X hide`,
      ),
    );

    if (this.error) push(theme.fg("error", `Build error: ${this.error}`));
    if (agents.length === 0) push(theme.fg("muted", "Preparing builder agents..."));

    for (let index = 0; index < agents.length; index++) {
      const agent = agents[index];
      const selected = index === this.selectedIndex;
      const collapsed = this.collapsedAgentIds.has(agent.id);
      const selector = selected ? theme.fg("accent", ">") : " ";
      const fold = collapsed ? theme.fg("muted", "[+]") : theme.fg("accent", "[-]");
      push(
        `${selector} ${fold} ${theme.fg("accent", agent.id)} ${theme.fg("toolTitle", agent.agent)} ${styledAgentStatus(agent.status, theme)} ${theme.fg("dim", agent.title)}`,
      );

      if (agent.progress) push(`    ${theme.fg("muted", compactText(agent.progress, Math.max(40, width - 4)))}`);
      if (collapsed) continue;

      const outputWidth = Math.max(1, width - 4);
      const output = wrapOutputTail(agent.output, outputWidth, DASHBOARD_OUTPUT_LINE_LIMIT);
      if (output.omitted > 0) push(`    ${theme.fg("dim", `... ${output.omitted} earlier output lines`)}`);
      if (output.lines.length === 0) {
        push(`    ${theme.fg("dim", isActiveAgentStatus(agent.status) ? "(waiting for output)" : "(no output)")}`);
        continue;
      }
      for (const outputLine of output.lines) push(`    ${theme.fg("toolOutput", outputLine)}`);
    }

    push(theme.fg("borderMuted", "─".repeat(width)));
    return lines;
  }
}

export function showPlanBuildDashboard(ctx: ExtensionContext, dashboard: PlanBuildDashboard): void {
  if (ctx.mode !== "tui") return;

  dashboard.detach();
  ctx.ui.setWidget(PLAN_BUILD_DASHBOARD_WIDGET, (tui, theme) =>
    dashboard.createComponent(theme, () => tui.requestRender()),
  );
}

export function hidePlanBuildDashboard(ctx: ExtensionContext, dashboard: PlanBuildDashboard): void {
  dashboard.detach();
  ctx.ui.setWidget(PLAN_BUILD_DASHBOARD_WIDGET, undefined);
}
