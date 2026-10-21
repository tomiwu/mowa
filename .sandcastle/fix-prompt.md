# Task

You work on mowa, issue #{{ISSUE}}, branch `{{BRANCH}}`. The checks failed: the local Linux checks, or the GitHub Actions CI on macOS (`format`, `lint`, `build`, `test`, `crap`). Fix the code so that all checks pass. You cannot run `xcodebuild` here, so read the CI log with care.

## Check output

```
{{CHECK_LOG}}
```

# Rules

- Find the cause of each failure. Fix the cause. Do not remove or weaken tests, lint rules, compiler settings or the CRAP threshold.
- If a function has CRAP 6 or more, make it smaller or add tests.
- Follow `docs/PRD.md`, `docs/CODING_STANDARDS.md` and `docs/CI_PLAN.md`.
- If the format check fails, run `swift format format --in-place --recursive .`. Do not format by hand.
- Run `swift test` for the packages that build on Linux.
- Run `scripts/crap-local.sh` before you finish. It runs the tests with coverage for each package under `Packages/` and `Tools/` and fails if a function has CRAP 6 or more. Fix each function that it lists: add tests, or split the function.
- Put platform-free logic (sample conversion, buffer math, voice activity probability, pipeline state, text rules) in a package under `Packages/` so that the local gate measures it. Code in `App/` and `Keyboard/` that uses AVFoundation, UIKit, SwiftUI or Core ML is measured only in the macOS CI: keep each such function very small (complexity 1 or 2, no loops, no `if`, no `switch`) and call into a package for the logic.
- lizard counts `if`, `guard`, `for`, `while`, `case`, `&&`, `||`, `??`, `?:`, and also `?` in optional types. Keep these out of large functions.
- If the CI `crap` job lists a function in `App/` or `Keyboard/`, move its logic into a package with tests, or split it until each part has complexity 1 or 2.
- Keep the CI job ids `format`, `lint`, `build`, `test` and `crap`.
- Make one commit. Start the message with `RALPH: #{{ISSUE}} fix`. Use ASD-STE100 Simplified Technical English.
- Do not push. Do not open a PR. Do not close the issue.

When you are done, output:

<promise>COMPLETE</promise>
