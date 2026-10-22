# mowa coding standards

Scope: all Swift code in this repository (app, keyboard extension, packages, tests).
This is the Swift adaptation of `tomiwu/crap4s` docs/CODING_STANDARDS.md. Each rule has one reason.
Versions were checked on 2026-10-20 (GitHub releases and the `actions/runner-images` macos-26 README).

## 1. Design

1. **Keep each concern in its own Swift package target**: `AudioCapture`, `Transcription` (Parakeet/Whisper engines), `Vocabulary` (word list), `CleanUp`, `History`, `SharedStore` (App Group), `AppUI`, `KeyboardUI`. Reason: a change touches the smallest part, and logic targets build and test without the app.
2. **Compose the dictation flow from small steps**: record, transcribe, correct words, clean up (optional), store, insert. Reason: each step is easy to read and to test alone.
3. **Model the domain with `struct` and `enum`** (`Transcript`, `LanguageHint`, `VocabularyEntry`, `DictationState`), not raw `String`, `Int` or tuples. Reason: the compiler finds mix-ups.
4. **Use a `protocol` only where there are two or more real implementations, or a test double is necessary** (for example `TranscriptionEngine`: Parakeet and Whisper). Reason: abstraction has a cost.
5. **Inject dependencies through initializer parameters.** Do not use a DI framework and do not use singletons (`static let shared`) in our code. Reason: plain parameters keep tests simple and remove hidden global state.
6. **Keep side effects at the edges.** Only adapter types touch `AVAudioEngine`, files, the App Group, Core ML, and `UIApplication`. Core logic is pure functions. Reason: pure code needs no device to test.
7. **Write a unit test for each business rule** (word-list correction, language choice, clean-up rules, history order) with Swift Testing (`import Testing`, `@Test`, `#expect`). Reason: small tests find the exact failure.

## 2. Swift code

8. **Use Swift 6 language mode with complete strict concurrency** (see 4.1). Reason: data races become compile errors.
9. **Use `async`/`await`, actors and `AsyncStream`.** Do not use Combine or completion handlers in new code. Reason: one concurrency model that the compiler checks.
10. **Mark UI types `@MainActor`.** Make types that cross actors `Sendable`. Do not use `@unchecked Sendable` or `nonisolated(unsafe)` without a comment that gives the reason. Reason: these turn off the race checks.
11. **Do not use force unwrap (`!`), force `try!`, force cast (`as!`), or implicitly unwrapped optionals** outside tests. Reason: each one is a crash path. SwiftLint enforces this.
12. **Report errors with typed errors** (`throws(MowaError)` or `Result<T, MowaError>` with an `enum`). Reason: errors stay visible in types.
13. **Prefer `let`, value types, and immutable collections.** Use `var` only inside a function scope or an actor. Reason: no shared mutable state.
14. **Use `private` or `fileprivate` by default; make API `public` only in package targets that export it.** Reason: small surfaces.
15. **Use SwiftUI and the Observation framework (`@Observable`)**, not `ObservableObject`/`@Published`. Reason: less boilerplate, no Combine.
16. **Keep the CRAP score of every function below 6** (Tomasz changed the limit from 4 to 6 on 2026-10-21): small functions, few branches, high coverage. Reason: same project rule as crap4s.
    Run `scripts/precommit.sh` before each commit and push (Linux or macOS). It runs format, lint, the package builds with warnings as errors and `scripts/crap-local.sh`. See `CLAUDE.md`. It measures `Packages/` and `Tools/` with `swift test --enable-code-coverage`. Put platform-free logic in `Packages/`. Keep functions in `App/` and `Keyboard/` that use AVFoundation, UIKit or SwiftUI at complexity 1 or 2, because only the macOS CI measures them. Note: lizard also counts `?` in optional types and `??`.

## 3. Formatting

Tool: **swift-format** (Apple, `swiftlang/swift-format`, release 604.0.0 on 2026-09-16; it is also in the Xcode toolchain as `swift format`). Reason: it is the official formatter, it has no extra install, and it has a lint mode for CI.
Alternative: SwiftFormat (nicklockwood) 0.64.0 (2026-10-16), preinstalled on the runner as 0.63.1. We do not use two formatters; they disagree on rules.

Proposed `.swift-format` (JSON) in the repository root:

```json
{
  "version": 1,
  "lineLength": 100,
  "indentation": { "spaces": 4 },
  "respectsExistingLineBreaks": true,
  "lineBreakBeforeEachArgument": true,
  "rules": {
    "AllPublicDeclarationsHaveDocumentation": false,
    "NeverForceUnwrap": true,
    "NeverUseForceTry": true,
    "NeverUseImplicitlyUnwrappedOptionals": true,
    "OrderedImports": true,
    "UseLetInEveryBoundCaseVariable": true
  }
}
```

Check: `xcrun swift-format lint --strict --recursive --parallel Sources Tests App Keyboard`
Fix: `xcrun swift-format format --in-place --recursive --parallel Sources Tests App Keyboard`

## 4. Static checks

### 4.1 Compiler settings (Swift 6.x, Xcode 26.6)

In each `Package.swift` target and in the Xcode project build settings:

| Setting | Value | Reason |
| --- | --- | --- |
| `SWIFT_VERSION` / `swiftLanguageModes` | `6` | Swift 6 language mode |
| `SWIFT_STRICT_CONCURRENCY` | `complete` | all race checks (default in Swift 6 mode) |
| `SWIFT_TREAT_WARNINGS_AS_ERRORS` | `YES` | each warning is a CI failure (same as `-Werror` in crap4s) |
| `GCC_TREAT_WARNINGS_AS_ERRORS` | `YES` | same for C/ObjC code from dependencies built in-tree |
| `SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY` | `YES` | explicit `any` |
| `SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT` | `YES` | no import leaks |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` | explicit imports |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` (app target only) | Xcode 26 default for new apps |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` (app and keyboard UI targets only) | Xcode 26 default for new apps; logic packages stay `nonisolated` |
| `ENABLE_USER_SCRIPT_SANDBOXING` | `YES` | build scripts cannot touch files they do not declare |

Package targets: `swiftSettings: [.enableUpcomingFeature("ExistentialAny"), .enableUpcomingFeature("InternalImportsByDefault"), .enableUpcomingFeature("MemberImportVisibility")]`. Do not set `treatAllWarnings` in the app packages: Xcode builds local packages with `-suppress-warnings`, which conflicts with it. CI runs `swift test -Xswiftc -warnings-as-errors` for each package instead (`Tools/CrapGate` is a root package and keeps `treatAllWarnings`).
Note: the newest Swift release is 6.4.1 (2026-10-15). Use the Swift that comes with the newest stable Xcode on the CI runner, not a separate toolchain.

### 4.2 SwiftLint

SwiftLint 0.65.1 (2026-08-21). It is **not** preinstalled on the macos-26 runner, so pin it with the `SwiftLintBinary` SPM artifact or `brew install swiftlint` in CI. Check: `swiftlint lint --strict --reporter github-actions-logging`.
Proposed `.swiftlint.yml`:

```yaml
strict: true
included: [App, Keyboard, Sources, Tests]
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
  - discouraged_optional_boolean
  - fatal_error_message
  - first_where
  - empty_count
  - sorted_imports
  - unused_parameter
  - private_swiftui_state
  - prefer_self_in_static_references
disabled_rules: [trailing_comma, opening_brace]   # owned by swift-format
force_cast: error
force_try: error
cyclomatic_complexity: { warning: 3, error: 4 }
function_body_length: { warning: 30, error: 50 }
file_length: { warning: 300, error: 500 }
custom_rules:
  no_singleton:
    regex: 'static\s+(let|var)\s+shared\b'
    message: "Do not use singletons. Inject the dependency."
    severity: error
  no_combine:
    regex: '^import Combine'
    message: "Use async/await or AsyncStream, not Combine."
    severity: error
```

Disabled rules that swift-format owns avoid conflicts between the two tools.

## 5. CI gate

On each pull request, GitHub Actions runs: format, lint, build with warnings as errors, unit tests on the iOS simulator, and the CRAP gate (CRAP < 6 for every function). See `docs/CI_PLAN.md`. The Sandcastle loop merges a PR only when all required checks pass.
