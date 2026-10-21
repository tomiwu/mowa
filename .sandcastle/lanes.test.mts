import { test } from "node:test";
import assert from "node:assert/strict";
import { laneOf, Mutex, worktreePath } from "./lanes.mts";

const issue = (title: string, labels: string[] = []) => ({ number: 1, title, labels: labels.map((name) => ({ name })) });

test("a spike goes to the side lane", () => {
  assert.equal(laneOf(issue("Spike: compare the word list biasing methods")), "side");
});
test("the label lane: side moves an issue to the side lane", () => {
  assert.equal(laneOf(issue("WER script", ["lane: side"])), "side");
});
test("other issues go to the app lane", () => {
  assert.equal(laneOf(issue("Local history: list, copy, delete one item, delete all")), "app");
});
test("only the loop's own worktrees are removed", () => {
  assert.equal(worktreePath("sandcastle/issue-18-1792617602504"), ".sandcastle/worktrees/sandcastle-issue-18-1792617602504");
  assert.equal(worktreePath("main"), undefined);
  assert.equal(worktreePath("sandcastle/../x"), undefined);
});
test("the mutex runs one task at a time", async () => {
  const m = new Mutex();
  const order: string[] = [];
  const slow = m.run(async () => { order.push("a1"); await new Promise((r) => setTimeout(r, 20)); order.push("a2"); });
  const fast = m.run(async () => { order.push("b"); });
  await Promise.all([slow, fast]);
  assert.deepEqual(order, ["a1", "a2", "b"]);
});
