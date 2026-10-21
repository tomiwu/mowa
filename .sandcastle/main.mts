// mowa Sandcastle loop: implement -> review -> check -> PR -> merge.
//
// For each iteration, the host does these steps:
//   1. Select the open issue with the "Sandcastle" label that has no open
//      "Blocked by #N" issue. Take the highest priority label, then the lowest number.
//   2. Create a sandbox on the branch "sandcastle/issue-<N>".
//   3. Run the implementer agent, then the reviewer agent.
//   4. Run the Linux checks in the sandbox: swift-format lint, `swift test` for logic
//      packages, and the local CRAP gate `scripts/crap-local.sh` (Packages/ and Tools/). The container cannot build iOS. The PR CI on
//      macOS (format, lint, build, test, crap) is the real gate.
//   5. If a check fails, run the fixer agent. Retry up to MAX_FIX_ATTEMPTS.
//   6. Push the branch, open a PR, wait for CI, squash-merge, close the issue.
// The loop stops when no issue is ready, or when an issue cannot pass.
//
// Two lanes run at the same time (see lanes.mts): lane "app" and lane "side" (spikes, scripts).
// Each lane works on 1 issue in its own worktree and branch, and writes .sandcastle/logs/lane-<name>.log.
// The merge is serialized: one lane at a time rebases its PR on the latest main, waits for green CI
// of the new head SHA, and merges with --match-head-commit. LANES=app runs only one lane.
//
// Usage:
//   MAX_ITERATIONS=10 npx tsx .sandcastle/main.mts                (default: Claude Code, Sonnet 5.5)
//   AGENT=cursor MAX_ITERATIONS=10 npx tsx .sandcastle/main.mts   (option: Cursor, Composer 2.5 Fast)
// If the Cursor agent fails because of credits or limits, the loop changes to Claude.

import * as sandcastle from "@ai-hero/sandcastle";
import { podman } from "@ai-hero/sandcastle/sandboxes/podman";
import { execFileSync, spawnSync } from "node:child_process";
import { appendFileSync, mkdirSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { prHeadSha, waitForCi } from "./ci.mts";
import { type Lane, LANES, laneOf, Mutex, worktreePath } from "./lanes.mts";

const MAX_ITERATIONS = Number(process.env.MAX_ITERATIONS ?? "10");
const MAX_FIX_ATTEMPTS = Number(process.env.MAX_FIX_ATTEMPTS ?? "3");
let agentName = (process.env.AGENT ?? "claude") === "cursor" ? "cursor" : "claude";
const CURSOR_MODEL = process.env.CURSOR_MODEL ?? "composer-2.5-fast";
const CLAUDE_MODEL = process.env.CLAUDE_MODEL ?? "claude-sonnet-5-5";
const IDLE_TIMEOUT_SECONDS = Number(process.env.IDLE_TIMEOUT_SECONDS ?? "1800");
const LIMIT_ERROR = /credit|quota|usage limit|rate limit|payment|out of (fast )?requests|insufficient/i;

function agent() {
  return agentName === "claude" ? sandcastle.claudeCode(CLAUDE_MODEL) : sandcastle.cursor(CURSOR_MODEL);
}

type RunOptions = Omit<Parameters<sandcastle.Sandbox["run"]>[0], "agent">;

// Run one agent phase. Change from Cursor to Claude if Cursor has no credits.
async function runPhase(sandbox: sandcastle.Sandbox, options: RunOptions) {
  try {
    const result = await sandbox.run({ idleTimeoutSeconds: IDLE_TIMEOUT_SECONDS, ...options, agent: agent() });
    if (agentName === "cursor" && !result.commits.length && logHasLimitError(options.name)) throw new Error("cursor limit");
    return result;
  } catch (error) {
    const text = `${error}`;
    if (agentName === "cursor" && (LIMIT_ERROR.test(text) || logHasLimitError(options.name))) {
      console.log(`Cursor failed (${text.slice(0, 200)}). Change to Claude Code and run again.`);
      agentName = "claude";
      return sandbox.run({ idleTimeoutSeconds: IDLE_TIMEOUT_SECONDS, ...options, agent: agent() });
    }
    throw error;
  }
}

function logHasLimitError(name?: string): boolean {
  try {
    const dir = ".sandcastle/logs";
    const files = readdirSync(dir).filter((f) => name && f.endsWith(`-${name}.log`))
      .map((f) => join(dir, f)).sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
    return files.length > 0 && LIMIT_ERROR.test(readFileSync(files[0], "utf8").slice(-4000));
  } catch {
    return false;
  }
}
const LABEL = "Sandcastle";
// Issues to skip, for example issues that must change .github/ (GH_TOKEN has no Workflows permission).
const SKIP = new Set((process.env.SKIP_ISSUES ?? "").split(",").filter(Boolean).map(Number));

const hooks = {
  sandbox: {
    onSandboxReady: [
      { command: "swift --version || true" },
    ],
  },
};

function sh(cmd: string, args: string[]): string {
  return execFileSync(cmd, args, { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] }).trim();
}

interface Issue { number: number; title: string; body: string; labels: { name: string }[] }

// Priority from labels. An issue without a priority label is medium.
const PRIORITY: Record<string, number> = {
  "priority: critical": 0, "priority: high": 1, "priority: medium": 2, "priority: low": 3,
};
function priority(issue: Issue): number {
  const values = issue.labels.map((l) => PRIORITY[l.name]).filter((v) => v !== undefined);
  return values.length ? Math.min(...values) : PRIORITY["priority: medium"];
}

function nextIssue(merged: Set<number>, lane: Lane, taken: Set<number>): Issue | undefined {
  const open: Issue[] = JSON.parse(
    sh("gh", ["issue", "list", "--state", "open", "--label", LABEL, "--limit", "100", "--json", "number,title,body,labels"]),
  );
  const openNumbers = new Set(open.map((i) => i.number).filter((n) => !merged.has(n)));
  open.splice(0, open.length, ...open.filter((i) => !merged.has(i.number) && !SKIP.has(i.number)));
  const ready = open.filter((i) => {
    const blockers = [...i.body.matchAll(/Blocked by\s+((?:#\d+[\s,and]*)+)/gi)]
      .flatMap((m) => [...m[1].matchAll(/#(\d+)/g)].map((n) => Number(n[1])));
    return blockers.every((b) => !openNumbers.has(b));
  });
  // Highest priority first, then lowest number. The loop reads the labels again before each iteration.
  ready.splice(0, ready.length, ...ready.filter((i) => laneOf(i) === lane && !taken.has(i.number)));
  ready.sort((a, b) => priority(a) - priority(b) || a.number - b.number);
  if (open.length && !ready.length) console.log(`[${lane}] No ready issue for this lane.`);
  // The issue list can be stale just after a merge. Check the state of the issue again.
  return ready.find((i) => sh("gh", ["issue", "view", String(i.number), "--json", "state", "--jq", ".state"]) === "OPEN");
}

// Collect the last lines of the log of each failed CI job of a PR.
function failedCiLog(url: string): string {
  const jobs = spawnSync("gh", ["pr", "checks", url, "--json", "name,state,link", "--jq",
    '.[] | select(.state == "FAILURE") | "\\(.name) \\(.link)"'], { encoding: "utf8" }).stdout.trim().split("\n").filter(Boolean);
  return jobs.map((line) => {
    const [name, link] = line.split(" ");
    const jobId = link?.match(/job\/(\d+)/)?.[1];
    const raw = jobId ? spawnSync("gh", ["api", "--allow-escape-sequences", `repos/{owner}/{repo}/actions/jobs/${jobId}/logs`], { encoding: "utf8" }).stdout : "";
    const clean = raw.replace(/\x1b\[[0-9;]*m/g, "").split("\n").filter((l) => !/Download|Checking https|Checked https/.test(l));
    return `## CI job ${name}\n${clean.slice(-150).join("\n")}`;
  }).join("\n");
}

// Linux checks only. SwiftLint runs only in the macOS CI (the Linux binary needs GLIBC 2.38; the image has 2.36). Each check runs only when its tool and config exist. CI on macOS is the gate.
async function check(sandbox: sandcastle.Sandbox, title: string, cmd: string): Promise<{ ok: boolean; log: string }> {
  const r = await sandbox.exec(`${cmd} > /tmp/check.log 2>&1; rc=$?; tail -n 150 /tmp/check.log; exit $rc`);
  return { ok: r.exitCode === 0, log: `## ${title}\n${r.stdout}\n` };
}

async function runChecks(sandbox: sandcastle.Sandbox): Promise<{ ok: boolean; log: string }> {
  const results = [
    await check(sandbox, "swift format lint (run `swift format format --in-place --recursive .` to fix)",
      "if [ -f .swift-format ]; then swift format lint --strict --recursive --parallel . ; fi"),
    await check(sandbox, "swift test (logic packages that build on Linux)",
      "for p in $(find Packages -maxdepth 2 -name Package.swift 2>/dev/null); do (cd $(dirname $p) && swift test) || exit 1; done"),
    await check(sandbox, "local CRAP gate (scripts/crap-local.sh: every function in Packages/ and Tools/ must have CRAP < 6)",
      "if [ -x scripts/crap-local.sh ]; then scripts/crap-local.sh; fi"),
  ];
  return { ok: results.every((r) => r.ok), log: results.map((r) => r.log).join("") };
}

const merged = new Set<number>();
const taken = new Set<number>();
const gitLock = new Mutex();   // git commands in the main checkout
const mergeLock = new Mutex(); // update the PR branch, wait for CI, merge: one lane at a time
let iterations = 0;
console.log(`Agent: ${agentName}`);
mkdirSync(".sandcastle/logs", { recursive: true });

function laneLog(lane: Lane, text: string) {
  const line = `[${lane}] ${text}`;
  console.log(line);
  appendFileSync(`.sandcastle/logs/lane-${lane}.log`, `${new Date().toISOString()} ${line}\n`);
}

// Remove the local worktree and branch of a merged PR. Only the loop's own worktrees.
function cleanUp(branch: string) {
  const path = worktreePath(branch);
  if (path) spawnSync("git", ["worktree", "remove", "--force", path]);
  spawnSync("git", ["worktree", "prune"]);
  spawnSync("git", ["branch", "-D", branch]);
}

// Run one issue from start to merge. Return false when the lane must stop.
async function runIssue(lane: Lane, issue: Issue): Promise<boolean> {
  const log = (text: string) => laneLog(lane, text);
  log(`=== Iteration ${iterations}/${MAX_ITERATIONS}: issue #${issue.number} ${issue.title} ===`);

  // Resume an open PR for this issue (for example after CI failed in an earlier run).
  const existing = JSON.parse(sh("gh", ["pr", "list", "--state", "open", "--json", "url,headRefName"]))
    .find((p: { headRefName: string }) => p.headRefName.startsWith(`sandcastle/issue-${issue.number}-`));
  const branch: string = existing?.headRefName ?? `sandcastle/issue-${issue.number}-${Date.now()}`;
  const args = { ISSUE: String(issue.number), BRANCH: branch };
  let passed = Boolean(existing);
  if (existing) {
    log(`Resume the open PR ${existing.url}.`);
    await gitLock.run(async () => {
      spawnSync("git", ["fetch", "origin", branch]);
      spawnSync("git", ["branch", "-f", branch, `origin/${branch}`]);
    });
  } else {
    const sandbox = await sandcastle.createSandbox({ branch, sandbox: podman(), hooks });
    try {
      const implement = await runPhase(sandbox, {
        name: "implementer", maxIterations: 1,
        promptFile: "./.sandcastle/implement-prompt.md", promptArgs: args,
      });
      if (!implement.commits.length) { log(`No commits for #${issue.number}. Stopping the lane.`); return false; }

      await runPhase(sandbox, {
        name: "reviewer", maxIterations: 1,
        promptFile: "./.sandcastle/review-prompt.md", promptArgs: args,
      });

      for (let attempt = 0; attempt <= MAX_FIX_ATTEMPTS; attempt++) {
        const result = await runChecks(sandbox);
        if (result.ok) { passed = true; break; }
        log(`Checks failed for #${issue.number} (attempt ${attempt}).`);
        if (attempt === MAX_FIX_ATTEMPTS) break;
        await runPhase(sandbox, {
          name: `fixer-${attempt + 1}`, maxIterations: 1,
          promptFile: "./.sandcastle/fix-prompt.md",
          promptArgs: { ...args, CHECK_LOG: result.log.slice(-12000) },
        });
      }
    } finally {
      await sandbox.close();
    }
  }

  if (!passed) {
    log(`Issue #${issue.number} cannot pass the checks. Stopping the lane.`);
    sh("gh", ["issue", "comment", String(issue.number), "--body",
      `Sandcastle stopped. The checks failed after ${MAX_FIX_ATTEMPTS} fix attempts. Branch: \`${branch}\`.`]);
    sh("git", ["push", "-f", "origin", branch]);
    return false;
  }

  if (!existing) sh("git", ["push", "-f", "origin", branch]);
  const url: string = existing ? existing.url : sh("gh", ["pr", "create", "--base", "main", "--head", branch,
    "--title", issue.title,
    "--body", `This PR implements #${issue.number}.\n\n${sh("git", ["log", "--reverse", "--format=%B", `main..${branch}`])}\n\nThe Linux checks pass (swift-format, swift test for logic packages, local CRAP gate). The macOS CI is the gate.\n\nCloses #${issue.number}`]);
  log(`PR: ${url}`);

  // Merge only when all GitHub Actions checks on the PR pass. waitForCi waits up to 30 minutes
  // for a run to start, because macOS runners are often queued.
  let mergedOk = false;
  for (let attempt = 0; attempt <= MAX_FIX_ATTEMPTS && !mergedOk; attempt++) {
    // One lane at a time: rebase on the latest main, wait for CI of the new head SHA, merge.
    const outcome = await mergeLock.run(async () => {
      spawnSync("gh", ["pr", "update-branch", url, "--rebase"], { stdio: "inherit" });
      await new Promise((r) => setTimeout(r, 10_000));
      const sha = prHeadSha(url);
      const ci = await waitForCi(branch, sha);
      log(`CI result for ${sha.slice(0, 7)}: ${ci}.`);
      if (ci === "success") {
        const ok = spawnSync("gh", ["pr", "merge", url, "--squash", "--delete-branch", "--match-head-commit", sha], { stdio: "inherit" }).status === 0;
        return { ci, sha, ok };
      }
      return { ci, sha, ok: false };
    });
    if (outcome.ok) { mergedOk = true; break; }
    if (outcome.ci === "success") continue; // The merge failed (for example main moved). Rebase again.
    if (outcome.ci !== "failure") { log(`No usable CI result for ${outcome.sha.slice(0, 7)} (${outcome.ci}). Do not run the fixer.`); break; }
    if (attempt === MAX_FIX_ATTEMPTS) break;
    // CI failed. Give the CI log to the fixer agent, push the fix, and wait for CI again.
    log(`CI failed for ${url}. Run the fixer (attempt ${attempt + 1}).`);
    await gitLock.run(async () => {
      spawnSync("git", ["fetch", "origin", branch]);
      spawnSync("git", ["branch", "-f", branch, `origin/${branch}`]);
    });
    const fixBox = await sandcastle.createSandbox({ branch, sandbox: podman(), hooks });
    try {
      await runPhase(fixBox, {
        name: `ci-fixer-${attempt + 1}`, maxIterations: 1,
        promptFile: "./.sandcastle/fix-prompt.md",
        promptArgs: { ...args, CHECK_LOG: failedCiLog(url).slice(-12000) },
      });
    } finally {
      await fixBox.close();
    }
    sh("git", ["push", "-f", "origin", branch]);
    if (sh("git", ["rev-parse", branch]) === outcome.sha) { log(`The fixer made no new commit. Stopping the lane.`); break; }
  }
  if (!mergedOk) {
    log(`CI failed or the merge failed for ${url}. Do not merge. Stopping the lane.`);
    return false;
  }
  const state = sh("gh", ["issue", "view", String(issue.number), "--json", "state", "--jq", ".state"]);
  if (state !== "CLOSED") sh("gh", ["issue", "close", String(issue.number), "--comment", `Merged in ${url}.`]);
  log(`Merged ${url}. Issue #${issue.number} is closed.`);
  await gitLock.run(async () => cleanUp(branch));
  merged.add(issue.number);
  return true;
}

async function runLane(lane: Lane): Promise<boolean> {
  while (iterations < MAX_ITERATIONS) {
    const pick = () => gitLock.run(async () => {
      sh("git", ["checkout", "main"]);
      sh("git", ["pull", "--rebase", "origin", "main"]);
      const found = nextIssue(merged, lane, taken);
      if (found) taken.add(found.number);
      return found;
    });
    let issue = await pick();
    if (!issue) {
      // The issue list can be stale just after a merge. Wait and try again one time.
      await new Promise((r) => setTimeout(r, 30_000));
      issue = await pick();
    }
    if (!issue) { laneLog(lane, "No ready issue for this lane. The lane stops."); return true; }
    iterations++;
    try {
      if (!(await runIssue(lane, issue))) return false;
    } catch (error) {
      laneLog(lane, `Error on #${issue.number}: ${`${error}`.slice(0, 500)}. Stopping the lane.`);
      return false;
    } finally {
      taken.delete(issue.number);
    }
  }
  return true;
}

const lanes = (process.env.LANES ?? LANES.join(",")).split(",").filter((l): l is Lane => (LANES as string[]).includes(l));
const results = await Promise.all(lanes.map((lane, i) =>
  // Start the second lane a little later, so that the two lanes do not pull main at the same time.
  new Promise((r) => setTimeout(r, i * 5_000)).then(() => runLane(lane))));
if (results.some((ok) => !ok)) process.exitCode = 1;
console.log("\nAll done.");
