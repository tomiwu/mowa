# mowa: rules for coding agents

mowa is an iOS dictation app (Swift 6, SwiftUI, iOS 26). Read `docs/CODING_STANDARDS.md` for all code rules.

## Before you commit or push (required)

1. Run `scripts/precommit.sh --fix`.
2. If a check fails, fix the cause and run the script again.
3. Commit or push only when the script ends with "all local checks passed".

Do not skip this step. Do not weaken a test, a lint rule, a compiler setting or the CRAP threshold to make a check pass.

The script runs these checks:

| Check | Command | CI job |
| --- | --- | --- |
| Format | `swift format lint --strict --recursive .` | `format` |
| Lint | `swiftlint lint --strict` (static binary on Linux) | `lint` |
| Build with warnings as errors | `swift build --build-tests -Xswiftc -warnings-as-errors` for each package in `Packages/` and `Tools/` | `test` |
| Tests and coverage | `swift test --enable-code-coverage` for each package | `test` |
| CRAP < 6 | `scripts/crap-local.sh` | `crap` |

## What the Linux container cannot check

The macOS CI is the only check for these items:

- The Xcode build of `App/` and `Keyboard/` (`xcodebuild`), and the simulator tests.
- CRAP scores of functions in `App/` and `Keyboard/`.
- Code that compiles only on Apple platforms (UIKit, SwiftUI, AVFoundation, Core ML, `os`). On Linux, `#if` removes this code, so Linux does not compile it.
- Apple availability errors. For example, `os_proc_available_memory()` is available on iOS but not on macOS. The CI runs the package tests on macOS too.
- SwiftLint rules that need SourceKit (`custom_rules`, `statement_position`).

Thus, for Apple-only code:

- Guard each Apple-only API with the correct condition, for example `#if os(iOS)` and not only `#if canImport(Darwin)`.
- Make sure each test passes on Linux, macOS and the iOS simulator. Do not expect a real device value (for example free memory) in a test.
- Keep each function in `App/` and `Keyboard/` very small (complexity 1 or 2). Put the logic in a package under `Packages/` with tests.
