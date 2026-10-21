// Lane rules for the Sandcastle loop. The loop runs up to 2 lanes at the same time.
//
// Lane "app": all issues that change the app, the Xcode project, the shared storage or the keyboard.
// Lane "side": spikes and script issues. An issue is "side" when its title starts with "Spike:"
// or it has the label "lane: side". These issues do not change the shared app files.
// Each lane takes 1 issue at a time. So 2 app issues never run at the same time.
// To move an issue to the other lane, add or remove the label "lane: side".

export type Lane = "app" | "side";
export const LANES: Lane[] = ["app", "side"];

export interface LaneIssue { number: number; title: string; labels: { name: string }[] }

export function laneOf(issue: LaneIssue): Lane {
  if (issue.labels.some((l) => l.name.toLowerCase() === "lane: side")) return "side";
  return /^spike:/i.test(issue.title.trim()) ? "side" : "app";
}

// Local worktree of a Sandcastle branch. The loop removes only its own worktrees.
export function worktreePath(branch: string): string | undefined {
  if (!/^sandcastle\/issue-\d+-\d+$/.test(branch)) return undefined;
  return `.sandcastle/worktrees/${branch.replace("/", "-")}`;
}

// A simple async lock. The lanes use it so that only one lane updates and merges a PR at a time.
export class Mutex {
  private tail: Promise<void> = Promise.resolve();
  async run<T>(fn: () => Promise<T>): Promise<T> {
    const previous = this.tail;
    let release!: () => void;
    this.tail = new Promise((r) => (release = r));
    await previous;
    try { return await fn(); } finally { release(); }
  }
}
