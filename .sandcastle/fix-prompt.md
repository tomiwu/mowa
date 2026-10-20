# Task

You work on mowa, issue #{{ISSUE}}, branch `{{BRANCH}}`. The checks failed: the local Linux checks, or the GitHub Actions CI on macOS (`format`, `lint`, `build`, `test`, `crap`). Fix the code so that all checks pass. You cannot run `xcodebuild` here, so read the CI log with care.

## Check output

```
{{CHECK_LOG}}
```

# Rules

- Find the cause of each failure. Fix the cause. Do not remove or weaken tests, lint rules, compiler settings or the CRAP threshold.
- If a function has CRAP 4 or more, make it smaller or add tests.
- Follow `docs/PRD.md`, `docs/CODING_STANDARDS.md` and `docs/CI_PLAN.md`.
- If the format check fails, run `swift format format --in-place --recursive .`. Do not format by hand.
- Run `swift test` for the packages that build on Linux.
- Keep the CI job ids `format`, `lint`, `build`, `test` and `crap`.
- Make one commit. Start the message with `RALPH: #{{ISSUE}} fix`. Use ASD-STE100 Simplified Technical English.
- Do not push. Do not open a PR. Do not close the issue.

When you are done, output:

<promise>COMPLETE</promise>
