# Context

You work on mowa. mowa is an iOS app (Swift, SwiftUI, minimum iOS 26) for on-device dictation in Polish and English. A keyboard extension opens the main app. The main app records and transcribes with Parakeet TDT 0.6B v3 (FluidAudio), with WhisperKit as fallback.

You work in a Linux container. You cannot build or run the iOS app here. You have Swift for Linux (`swift`, `swift format`), `swiftlint-static` (SwiftLint without the SourceKit rules) and `lizard`. GitHub Actions on macOS runs the real checks after the host opens the PR: `format`, `lint`, `build`, `test`, `crap`.

## Your issue: #{{ISSUE}}

!`gh issue view {{ISSUE}} --json number,title,body,comments --jq '{number, title, body, comments: [.comments[].body]}'`

## Recent commits

!`git log --oneline -10`

# Task

Implement issue #{{ISSUE}} on branch `{{BRANCH}}`. Do only this issue.

1. Read the issue, `docs/PRD.md`, `docs/CODING_STANDARDS.md` and `docs/CI_PLAN.md`. Follow them.
2. Read the source files and tests that exist.
3. Use Red-Green-Refactor with Swift Testing. Write a failing test first. Put platform-free logic in Swift packages under `Packages/` so that `swift test` runs on Linux.
4. Read `CLAUDE.md`. Before each commit, run `scripts/precommit.sh --fix`. Fix all failures, and run it again until it passes. Do not commit when it fails. Code that imports UIKit, SwiftUI, AVFoundation or Core ML cannot build here: write it with care, and keep it small.
5. Make one git commit. Start the message with `RALPH: #{{ISSUE}}`. Write the task, the key decisions and the files changed. The host copies the commit messages into the PR description.

# Rules

- Write all code, comments and commit messages in English. Use ASD-STE100 Simplified Technical English.
- Use Swift 6 language mode, strict concurrency `complete`, warnings as errors, Xcode 26.6. If you add a package, use its latest stable version with Swift Package Manager. Do not use CocoaPods or Carthage.
- Obey the do-not-use list in `docs/CI_PLAN.md`.
- Every function must have a CRAP score less than 6. Keep functions small and tested.
- Run `scripts/crap-local.sh` before you finish. It runs the tests with coverage for each package under `Packages/` and `Tools/` and fails if a function has CRAP 6 or more. Fix each function that it lists: add tests, or split the function.
- Put platform-free logic (sample conversion, buffer math, voice activity probability, pipeline state, text rules) in a package under `Packages/` so that the local gate measures it. Code in `App/` and `Keyboard/` that uses AVFoundation, UIKit, SwiftUI or Core ML is measured only in the macOS CI: keep each such function very small (complexity 1 or 2, no loops, no `if`, no `switch`) and call into a package for the logic.
- lizard counts `if`, `guard`, `for`, `while`, `case`, `&&`, `||`, `??`, `?:`, and also `?` in optional types. Keep these out of large functions.
- Do not push. Do not open a PR. Do not close the issue. The host does these steps.
- Do not edit `docs/PRD.md` or `.sandcastle/`.
- You can edit `.github/workflows/ci.yml`. Keep the job ids `format`, `lint`, `build`, `test` and `crap`. Branch protection requires them. Do not skip a step when a file is missing. `scripts/crap.sh` always runs in the `crap` job.
- Do not leave commented-out code or TODO comments.
- If you cannot continue, write a comment on the issue with `gh issue comment {{ISSUE}}`. Explain the problem.

When you are done, output:

<promise>COMPLETE</promise>
