# mowa CI plan

Status: proposal for issues #3 (build, test, lint) and #4 (signing, fastlane, TestFlight). Facts checked on 2026-10-20.

## 1. Runner and tools

- Runner: `macos-26` (arm64). Free for a public repo.
- Xcode on the runner (actions/runner-images macos-26-arm64 README): 26.6 (default, 17F113), 26.5, 26.4.1, 26.3, 26.2, 26.1.1, 26.0.1. iOS SDK 26.5 and Simulator iOS 26.5 come with Xcode 26.5 and 26.6.
- Preinstalled: fastlane 2.241.0 (newest 2.241.1), SwiftFormat 0.63.1, xcbeautify 3.2.1, Ruby 3.4.11. **Not** preinstalled: SwiftLint.
- Pin Xcode in each job: `sudo xcode-select -s /Applications/Xcode_26.6.app`.

## 2. Jobs (`.github/workflows/ci.yml`, on `pull_request` and `push` to `main`)

| Job | Command (short) | Required check |
| --- | --- | --- |
| `format` | `xcrun swift-format lint --strict --recursive --parallel App Keyboard Sources Tests` | yes |
| `lint` | `swiftlint lint --strict --reporter github-actions-logging` | yes |
| `build` | `xcodebuild build-for-testing -scheme mowa -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \| xcbeautify` | yes |
| `test` | `xcodebuild test-without-building ... -enableCodeCoverage YES -resultBundlePath build/Tests.xcresult`; also `swift test --enable-code-coverage` for logic packages | yes |
| `crap` | `scripts/crap.sh build/Tests.xcresult` (fails if a function has CRAP >= 6) | yes |
| `testflight` | only on `push` to `main`, after all jobs pass: `bundle exec fastlane beta` | no (not on PRs) |

Notes:
- Check the exact simulator name with `xcrun simctl list devices available` in the first CI run; the name is not fixed here.
- Cache `~/Library/Developer/Xcode/DerivedData` and SPM `.build` with `actions/cache`.
- Do not download the Parakeet model in CI unit tests; tests use a fake `TranscriptionEngine`. One optional nightly job can run a real model test.

## 3. CRAP gate for Swift

What exists:
- No Swift CRAP tool was found (GitHub search "crap swift" and "swift crap coverage complexity": no results, 2026-10-20).
- Complexity per function: SwiftLint `cyclomatic_complexity` (only warns above a threshold, no full list), `lizard` (Python, supports Swift, prints CCN per function as CSV), or `swift-syntax` (exact, our own visitor).
- Coverage per function: `xcrun xccov view --report --json build/Tests.xcresult` gives per-function `lineCoverage`, `lineNumber`, and `executionCount` per file; `swift test --enable-code-coverage` gives llvm-cov JSON (`swift test --show-codecov-path`).

What we must write (`scripts/crap.sh` + a small Swift CLI `Tools/CrapGate`, about 200 lines):
1. Run `lizard --csv -l swift App Keyboard Sources` → file, function, start line, CCN.
2. Read `xccov` JSON → file, function, start line, line coverage (0..1).
3. Join on file + start line (function names in xccov are mangled or demangled differently, so the line is the key).
4. `CRAP = comp^2 * (1 - cov)^3 + comp`. A function with no coverage entry has cov = 0.
5. Print a CSV (same as crap4s) and exit 1 if any CRAP >= 6.
Later option: replace lizard with a swift-syntax visitor, so the tool has no Python. The gate tool itself must pass its own gate, as in crap4s.

Local gate (before push): `scripts/crap-local.sh` runs on Linux (the Sandcastle container) and on macOS. For each package under `Packages/` and `Tools/` it runs `swift test --enable-code-coverage`, reads the llvm-cov export JSON (`swift test --show-codecov-path`), runs lizard on the same folders, and calls `CrapGate --only-compiled`. CrapGate reads xccov JSON or llvm-cov JSON (it finds the format from the `type` field). For llvm-cov, the coverage of a function is the part of its code regions that ran. `--only-compiled` skips functions that have no coverage entry, because they are not compiled on this platform (for example `#if canImport(Darwin)`). The macOS `crap` job does not use this flag and also measures `App/` and `Keyboard/`. The Sandcastle loop runs the local gate before each push.

Result: with threshold 6, the gate fails when CRAP >= 6. Tomasz changed the threshold from 4 to 6 on 2026-10-21.

| Complexity | Coverage necessary to pass |
|---|---|
| 1 | always passes |
| 2 | more than 0% |
| 3 | more than 30.7% |
| 4 | more than 50% |
| 5 | more than 65.8% |
| 6 or more | always fails |

## 4. Signing and TestFlight

Method: App Store Connect API key + fastlane `match` (certificates and profiles in a private git repo, encrypted). Reason: one command on CI, and no manual Keychain work on the runner. Alternative: manual certificates as base64 secrets plus `xcodebuild -allowProvisioningUpdates` with the API key; it is simpler, but rotation is manual.

`fastlane beta` lane: `setup_ci` → `app_store_connect_api_key` → `match(type: "appstore", readonly: true)` → `increment_build_number(build_number: ENV["GITHUB_RUN_NUMBER"])` → `build_app(scheme: "mowa", export_method: "app-store")` → `upload_to_testflight(skip_waiting_for_build_processing: true)`.
Two targets need profiles: the app (`com.tomiwu.mowa`) and the keyboard extension (`com.tomiwu.mowa.keyboard`).

### Secrets (GitHub repo → Settings → Secrets → Actions)

| Secret | Content |
| --- | --- |
| `ASC_KEY_ID` | API key id |
| `ASC_ISSUER_ID` | issuer id |
| `ASC_KEY_P8` | content of the `.p8` file (base64) |
| `MATCH_GIT_URL` | private repo for certificates, for example `tomiwu/mowa-certs` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `user:token` with read access to that repo |
| `MATCH_PASSWORD` | encryption password for match |
| `APPLE_TEAM_ID` | 10-character team id |

### Manual steps for Tomasz

1. Enroll in the Apple Developer Program (99 USD per year) and wait for approval.
2. In the developer portal: create App IDs `com.tomiwu.mowa` and `com.tomiwu.mowa.keyboard`; create App Group `group.com.tomiwu.mowa` and enable it on both IDs.
3. In App Store Connect: create the app record "mowa" (bundle `com.tomiwu.mowa`); add yourself as an internal TestFlight tester.
4. In App Store Connect → Users and Access → Integrations: create a Team API key with the "App Manager" role; download the `.p8` (you can download it only one time).
5. Create the private repo `tomiwu/mowa-certs`. Run `fastlane match appstore` one time (on a Mac, or from CI with a one-time `readonly: false` run).
6. Add the secrets above.
7. On the iPhone: install TestFlight, accept the invite, and after install enable the keyboard in Settings → General → Keyboard → Keyboards, with "Allow Full Access" (needed for the App Group and to open the app).

## 5. Do not use

| Do not use | Reason |
| --- | --- |
| Apple `SpeechTranscriber` / `SpeechAnalyzer` as main engine | It does not support Polish (research-v1.md, Apple supported locales). |
| `SFSpeechRecognizer` server mode or any cloud ASR by default | Audio leaves the device; PRD says on-device first; cloud is an optional add-on only. |
| Microphone in the keyboard extension | Apple: custom keyboards have no microphone access. The keyboard opens the main app, which records (Wispr Flow does the same). |
| Large model in the keyboard extension | Extensions have a strict memory limit (Apple App Extension Programming Guide); Parakeet v3 needs about 0.6 GB. The model runs only in the main app. |
| CocoaPods, Carthage | CocoaPods trunk becomes read-only (CocoaPods blog, 2024 announcement); use Swift Package Manager only. |
| Force unwrap, `try!`, `as!`, IUO | Crash paths; SwiftLint and swift-format rules fail them. |
| Singletons (`static let shared`) in our code | Hidden global state; blocks tests and strict concurrency. |
| Combine, completion handlers, `ObservableObject` | async/await and `@Observable` are checked by the Swift 6 compiler. |
| `@unchecked Sendable`, `nonisolated(unsafe)` without a written reason | They turn off race checks. |
| `DispatchQueue` / GCD for new code | Use actors and tasks. |
| Third-party analytics, crash SDKs, ads | Dictated text is private; App Store privacy labels; no network by default. |
| Storyboards / XIB | SwiftUI only; text diffs review well. |
| Storing secrets or the `.p8` in the repo | Public repo; use GitHub secrets. |
| Two formatters at the same time | swift-format and SwiftFormat have different rules. |
| Model download in unit tests | Slow and flaky CI; use a fake engine. |

## 6. Open points

- Choose the CI simulator device name after the first run.
- Verify the exact `xccov` JSON field names in the first CI run before the `crap` job is required.
- CocoaPods read-only date: confirm the date on blog.cocoapods.org before the PR.

## Sandcastle lanes

The Sandcastle loop (`.sandcastle/main.mts`) runs 2 lanes at the same time. Each lane works on 1 issue in its own git worktree and branch, and writes its own log `.sandcastle/logs/lane-<name>.log`.

- Lane `app`: all issues that change the app, the Xcode project, the shared storage or the keyboard. Only 1 such issue runs at a time.
- Lane `side`: spikes and script issues. An issue is in this lane when its title starts with `Spike:` or it has the label `lane: side`.

To move an issue to the other lane, add or remove the label `lane: side`. Set `LANES=app` to run only one lane.

The merge is serialized. One lane at a time rebases its PR on the latest `main`, waits for green CI of the new head SHA, and merges with `--match-head-commit`. The loop waits up to 30 minutes for a CI run to start, because macOS runners are often queued. A queued run counts as pending, not as a failure. After the merge, the loop removes its own worktree with `git worktree remove --force`.
