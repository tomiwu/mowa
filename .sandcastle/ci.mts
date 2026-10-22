// CI helpers for the Sandcastle loop. The loop must read the CI result of the current head SHA only.
import { spawnSync } from "node:child_process";

export interface CiRun { databaseId: number; headSha: string; status: string; conclusion: string; workflowName: string }
export type CiState = "missing" | "pending" | "success" | "failure" | "cancelled";

// Classify the CI runs for one head SHA. Runs for other SHAs are ignored.
// Use the newest run of each workflow, because a rerun makes a new attempt of the same workflow.
export function classifyRuns(runs: CiRun[], sha: string): { state: CiState; cancelledIds: number[] } {
  const latest = new Map<string, CiRun>();
  for (const r of runs.filter((r) => r.headSha === sha).sort((a, b) => a.databaseId - b.databaseId)) {
    latest.set(r.workflowName, r);
  }
  const current = [...latest.values()];
  if (!current.length) return { state: "missing", cancelledIds: [] };
  if (current.some((r) => r.status !== "completed")) return { state: "pending", cancelledIds: [] };
  const cancelledIds = current.filter((r) => r.conclusion === "cancelled").map((r) => r.databaseId);
  // Only "success" passes. Every other conclusion (failure, timed_out, action_required, neutral,
  // skipped, stale, startup_failure) blocks the merge. A cancelled run is started again.
  if (current.some((r) => r.conclusion !== "success" && r.conclusion !== "cancelled")) {
    return { state: "failure", cancelledIds };
  }
  if (cancelledIds.length) return { state: "cancelled", cancelledIds };
  return { state: "success", cancelledIds: [] };
}

export function prHeadSha(url: string): string {
  return spawnSync("gh", ["pr", "view", url, "--json", "headRefOid", "--jq", ".headRefOid"], { encoding: "utf8" }).stdout.trim();
}

function listRuns(branch: string): CiRun[] {
  const r = spawnSync("gh", ["run", "list", "--branch", branch, "--event", "pull_request", "--limit", "30",
    "--json", "databaseId,headSha,status,conclusion,workflowName"], { encoding: "utf8" });
  try { return JSON.parse(r.stdout || "[]"); } catch { return []; }
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export interface CiWaitOptions { timeoutMs: number; pollMs: number; startTimeoutMs: number; maxReruns: number }
// macOS runners are often queued for 6 to 20 minutes. A run that is not started yet ("missing")
// or is queued ("pending") is not a failure. Wait 30 minutes for a run to show, and 90 minutes in total.
export const DEFAULT_CI_WAIT: CiWaitOptions = { timeoutMs: 90 * 60_000, pollMs: 30_000, startTimeoutMs: 30 * 60_000, maxReruns: 2 };

// Decide what to do with one CI state. "wait" means: poll again later.
export function ciDecision(state: CiState, elapsedMs: number, opts: CiWaitOptions = DEFAULT_CI_WAIT): "success" | "failure" | "no-run" | "rerun" | "wait" {
  if (state === "success" || state === "failure") return state;
  if (state === "cancelled") return "rerun";
  if (state === "missing" && elapsedMs > opts.startTimeoutMs) return "no-run";
  return "wait";
}

// Wait until the CI runs for this exact SHA exist and complete. A cancelled run is started again
// (up to maxReruns times). It is not a failure of the code and does not use a fixer attempt.
export async function waitForCi(branch: string, sha: string, opts: CiWaitOptions = DEFAULT_CI_WAIT): Promise<"success" | "failure" | "timeout" | "no-run"> {
  const start = Date.now();
  let reruns = 0;
  console.log(`Wait for the CI of ${sha.slice(0, 7)} on ${branch}.`);
  while (Date.now() - start < opts.timeoutMs) {
    const { state, cancelledIds } = classifyRuns(listRuns(branch), sha);
    const decision = ciDecision(state, Date.now() - start, opts);
    if (decision === "success" || decision === "failure" || decision === "no-run") return decision;
    if (decision === "rerun") {
      if (reruns >= opts.maxReruns) return "failure";
      reruns++;
      console.log(`CI run was cancelled for ${sha.slice(0, 7)}. Start it again (${reruns}/${opts.maxReruns}).`);
      for (const id of cancelledIds) spawnSync("gh", ["run", "rerun", String(id)], { stdio: "inherit" });
    }
    await sleep(opts.pollMs);
  }
  return "timeout";
}
