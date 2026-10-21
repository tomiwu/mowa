// mowa Sandcastle loop: implement -> review -> check -> PR -> merge.
//
// For each iteration, the host does these steps:
//   1. Select the open issue with the "Sandcastle" label that has no open
//      "Blocked by #N" issue. Take the highest priority label, then the lowest number.
//   2. Create a sandbox on the branch "sandcastle/issue-<N>".
//   3. Run the implementer agent, then the reviewer agent.
//   4. Run the Linux checks in the sandbox: swift-format lint and
//      `swift test` for logic packages. The container cannot build iOS. The PR CI on
//      macOS (format, lint, build, test, crap) is the real gate.
//   5. If a check fails, run the fixer agent. Retry up to MAX_FIX_ATTEMPTS.
//   6. Push the branch, open a PR, wait for CI, squash-merge, close the issue.
// The loop stops when no issue is ready, or when an issue cannot pass.
//
// Usage:
//   MAX_ITERATIONS=10 npx tsx .sandcastle/main.mts                (default: Claude Code, Sonnet 5.5)
//   AGENT=cursor MAX_ITERATIONS=10 npx tsx .sandcastle/main.mts   (option: Cursor, Composer 2.5 Fast)
// If the Cursor agent fails because of credits or limits, the loop changes to Claude.

import * as sandcastle from "@ai-hero/sandcastle";
import { podman } from "@ai-hero/sandcastle/sandboxes/podman";
import { execFileSync, spawnSync } from "node:child_process";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

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

function nextIssue(merged: Set<number>): Issue | undefined {
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
  ready.sort((a, b) => priority(a) - priority(b) || a.number - b.number);
  if (open.length && !ready.length) console.log("All open issues are blocked.");
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
  ];
  return { ok: results.every((r) => r.ok), log: results.map((r) => r.log).join("") };
}

const merged = new Set<number>();
console.log(`Agent: ${agentName}`);

for (let iteration = 1; iteration <= MAX_ITERATIONS; iteration++) {
  sh("git", ["checkout", "main"]);
  sh("git", ["pull", "--rebase", "origin", "main"]);
  let issue = nextIssue(merged);
  if (!issue) {
    // The issue list can be stale just after a merge. Wait and try again one time.
    await new Promise((r) => setTimeout(r, 30_000));
    issue = nextIssue(merged);
  }
  if (issue && merged.has(issue.number)) { console.log(`Issue #${issue.number} is already merged. Stopping.`); break; }
  if (!issue) { console.log("No ready issue. Stopping."); break; }
  console.log(`\n=== Iteration ${iteration}/${MAX_ITERATIONS}: issue #${issue.number} ${issue.title} ===\n`);

  // Resume an open PR for this issue (for example after CI failed in an earlier run).
  const existing = JSON.parse(sh("gh", ["pr", "list", "--state", "open", "--json", "url,headRefName"]))
    .find((p: { headRefName: string }) => p.headRefName.startsWith(`sandcastle/issue-${issue.number}-`));
  const branch: string = existing?.headRefName ?? `sandcastle/issue-${issue.number}-${Date.now()}`;
  const args = { ISSUE: String(issue.number), BRANCH: branch };
  let passed = Boolean(existing);
  if (existing) {
    console.log(`Resume the open PR ${existing.url}.`);
    spawnSync("git", ["fetch", "origin", branch]);
    spawnSync("git", ["branch", "-f", branch, `origin/${branch}`]);
  } else {
  const sandbox = await sandcastle.createSandbox({ branch, sandbox: podman(), hooks });
  try {
    const implement = await runPhase(sandbox, {
      name: "implementer", maxIterations: 1,
      promptFile: "./.sandcastle/implement-prompt.md", promptArgs: args,
    });
    if (!implement.commits.length) { console.log(`No commits for #${issue.number}. Stopping.`); break; }

    await runPhase(sandbox, {
      name: "reviewer", maxIterations: 1,
      promptFile: "./.sandcastle/review-prompt.md", promptArgs: args,
    });

    for (let attempt = 0; attempt <= MAX_FIX_ATTEMPTS; attempt++) {
      const result = await runChecks(sandbox);
      if (result.ok) { passed = true; break; }
      console.log(`Checks failed for #${issue.number} (attempt ${attempt}).`);
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
    console.log(`Issue #${issue.number} cannot pass the checks. Stopping the loop.`);
    sh("gh", ["issue", "comment", String(issue.number), "--body",
      `Sandcastle stopped. The checks failed after ${MAX_FIX_ATTEMPTS} fix attempts. Branch: \`${branch}\`.`]);
    sh("git", ["push", "-f", "origin", branch]);
    process.exitCode = 1;
    break;
  }

  if (!existing) sh("git", ["push", "-f", "origin", branch]);
  const url: string = existing ? existing.url : sh("gh", ["pr", "create", "--base", "main", "--head", branch,
    "--title", issue.title,
    "--body", `This PR implements #${issue.number}.\n\n${sh("git", ["log", "--reverse", "--format=%B", `main..${branch}`])}\n\nThe Linux checks pass (swift-format, swift test for logic packages). The macOS CI is the gate.\n\nCloses #${issue.number}`]);
  console.log(`PR: ${url}`);
  // Merge only when all GitHub Actions checks on the PR pass.
  let hasChecks = false;
  for (let wait = 0; wait < 12 && !hasChecks; wait++) {
    await new Promise((r) => setTimeout(r, 15_000));
    const probe = spawnSync("gh", ["pr", "checks", url], { encoding: "utf8" });
    hasChecks = !/no checks reported/i.test(`${probe.stdout}${probe.stderr}`);
  }
  if (!hasChecks) {
    console.log(`No CI checks started for ${url}. Do not merge. Stopping the loop.`);
    process.exitCode = 1;
    break;
  }
  // main requires the check "test" on an up-to-date branch. Update the branch and retry.
  let mergedOk = false;
  for (let attempt = 0; attempt <= MAX_FIX_ATTEMPTS && !mergedOk; attempt++) {
    spawnSync("gh", ["pr", "update-branch", url], { stdio: "inherit" });
    await new Promise((r) => setTimeout(r, 20_000));
    const watch = spawnSync("gh", ["pr", "checks", url, "--watch"], { stdio: "inherit", timeout: 30 * 60_000 });
    if (watch.status === 0) {
      mergedOk = spawnSync("gh", ["pr", "merge", url, "--squash", "--delete-branch"], { stdio: "inherit" }).status === 0;
      continue;
    }
    if (attempt === MAX_FIX_ATTEMPTS) break;
    // CI failed. Give the CI log to the fixer agent, push the fix, and wait for CI again.
    console.log(`CI failed for ${url}. Run the fixer (attempt ${attempt + 1}).`);
    spawnSync("git", ["fetch", "origin", branch]);
    spawnSync("git", ["branch", "-f", branch, `origin/${branch}`]);
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
  }
  if (!mergedOk) {
    console.log(`CI failed or the merge failed for ${url}. Do not merge. Stopping the loop.`);
    process.exitCode = 1;
    break;
  }
  const state = sh("gh", ["issue", "view", String(issue.number), "--json", "state", "--jq", ".state"]);
  if (state !== "CLOSED") sh("gh", ["issue", "close", String(issue.number), "--comment", `Merged in ${url}.`]);
  console.log(`Merged ${url}. Issue #${issue.number} is closed.`);
  spawnSync("git", ["branch", "-D", branch]);
  merged.add(issue.number);
}

console.log("\nAll done.");
