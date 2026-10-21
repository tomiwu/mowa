import { test } from "node:test";
import assert from "node:assert/strict";
import { ciDecision, classifyRuns, DEFAULT_CI_WAIT, type CiRun } from "./ci.mts";

const run = (id: number, sha: string, status: string, conclusion: string, workflowName = "CI"): CiRun =>
  ({ databaseId: id, headSha: sha, status, conclusion, workflowName });

test("ignores runs for an old SHA", () => {
  assert.equal(classifyRuns([run(1, "old", "completed", "failure")], "new").state, "missing");
});
test("pending while the new run is not complete", () => {
  assert.equal(classifyRuns([run(1, "old", "completed", "failure"), run(2, "new", "in_progress", "")], "new").state, "pending");
});
test("success and failure of the new run", () => {
  assert.equal(classifyRuns([run(2, "new", "completed", "success")], "new").state, "success");
  assert.equal(classifyRuns([run(2, "new", "completed", "failure")], "new").state, "failure");
});
test("a cancelled run is a rerun, not a failure", () => {
  assert.deepEqual(classifyRuns([run(3, "new", "completed", "cancelled")], "new"), { state: "cancelled", cancelledIds: [3] });
});
test("the newest run of a workflow wins after a rerun", () => {
  assert.equal(classifyRuns([run(3, "new", "completed", "cancelled"), run(4, "new", "completed", "success")], "new").state, "success");
});
test("a failure wins over a cancelled run in another workflow", () => {
  assert.equal(classifyRuns([run(3, "new", "completed", "cancelled", "A"), run(4, "new", "completed", "failure", "B")], "new").state, "failure");
});
test("a queued run is pending, not missing or failure", () => {
  assert.equal(classifyRuns([run(5, "new", "queued", "")], "new").state, "pending");
  assert.equal(classifyRuns([run(5, "new", "waiting", "")], "new").state, "pending");
});
test("wait for a run that is not started yet, up to 30 minutes", () => {
  assert.equal(ciDecision("missing", 20 * 60_000), "wait");
  assert.equal(ciDecision("missing", 31 * 60_000), "no-run");
  assert.equal(DEFAULT_CI_WAIT.startTimeoutMs, 30 * 60_000);
});
test("a queued run is never no-run", () => {
  assert.equal(ciDecision("pending", 60 * 60_000), "wait");
});
test("a cancelled run is started again", () => {
  assert.equal(ciDecision("cancelled", 0), "rerun");
});
