#!/usr/bin/env bun
/**
 * Statusline HUD for Claude Code.
 *
 * Reads the statusline JSON payload on stdin and prints a single ANSI line:
 *   Fable 5 │ ctx ███▌░░░░ 43% 86k │ 5h ████▉░░░ 61% │ ⎇ main* │ +12/-4 │ homelab
 *
 * Lives in .agents/hooks/ (shared agent config). Codex CLI cannot run
 * command-backed statuslines yet — see openai/codex#17827 / #20140; when
 * that ships, point its config at this same script.
 */
import { readFileSync } from "node:fs";
import { execSync } from "node:child_process";

const ESC = "\x1b[";
const RESET = `${ESC}0m`;
const dim = (s: string) => `${ESC}2m${s}${RESET}`;
const bold = (s: string) => `${ESC}1m${s}${RESET}`;
const color = (n: number, s: string) => `${ESC}38;5;${n}m${s}${RESET}`;
const pctColor = (p: number, s: string) =>
  color(p >= 80 ? 196 : p >= 60 ? 214 : 71, s);
const fmtTokens = (n: number) =>
  n >= 1_000_000
    ? `${(n / 1_000_000).toFixed(1)}M`
    : n >= 1_000
      ? `${Math.round(n / 1_000)}k`
      : `${n}`;
const bar = (pct: number, width = 8) => {
  const clamped = Math.min(100, Math.max(0, pct));
  const cells = (clamped / 100) * width;
  let full = Math.floor(cells);
  const eighths = Math.round((cells - full) * 8);
  let partial = "";
  if (eighths === 8) full += 1;
  else if (eighths > 0) partial = "▏▎▍▌▋▊▉"[eighths - 1];
  const empty = width - full - (partial ? 1 : 0);
  return (
    pctColor(clamped, "█".repeat(full) + partial) + dim("░".repeat(empty))
  );
};

try {
  let data: any = {};
  try {
    data = JSON.parse(readFileSync(0, "utf8"));
  } catch {
    /* no/garbled stdin: render what we can */
  }

  const seg: string[] = [];

  const model = data.model?.display_name ?? data.model?.id;
  if (model) seg.push(bold(color(45, model)));

  const cw = data.context_window;
  if (cw?.used_percentage != null) {
    const pct = Math.round(cw.used_percentage);
    const used =
      (cw.total_input_tokens ?? 0) + (cw.total_output_tokens ?? 0);
    seg.push(
      dim("ctx ") +
        bar(pct) +
        pctColor(pct, ` ${pct}%`) +
        (used ? dim(` ${fmtTokens(used)}`) : ""),
    );
  }

  const limit = (label: string, l: any, withBar = false) => {
    if (l?.used_percentage == null) return;
    const p = Math.round(l.used_percentage);
    seg.push(
      dim(`${label} `) +
        (withBar ? bar(p) + " " : "") +
        pctColor(p, `${p}%`),
    );
  };
  limit("5h", data.rate_limits?.five_hour, true);

  const dir = data.workspace?.current_dir ?? data.cwd ?? process.cwd();
  try {
    const git = (cmd: string) =>
      execSync(cmd, {
        cwd: dir,
        stdio: ["ignore", "pipe", "ignore"],
        timeout: 1_000,
      })
        .toString()
        .trim();
    const branch = git("git branch --show-current");
    if (branch) {
      const dirty = git("git status --porcelain") ? color(214, "*") : "";
      seg.push(color(110, `⎇ ${branch}`) + dirty);
    }
  } catch {
    /* not a git repo / git missing */
  }

  const added = data.cost?.total_lines_added ?? 0;
  const removed = data.cost?.total_lines_removed ?? 0;
  if (added || removed)
    seg.push(`${color(71, `+${added}`)}${dim("/")}${color(167, `-${removed}`)}`);

  const base = String(dir).split("/").filter(Boolean).pop();
  if (base) seg.push(color(180, base));

  console.log(seg.join(dim(" │ ")));
} catch {
  /* never crash the statusline */
}
