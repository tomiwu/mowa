# mowa

mowa is an iOS app (Swift, SwiftUI, iOS 26 or later) for on-device dictation in Polish and English.

A keyboard extension opens the main app. The main app records the speech and transcribes it with Parakeet TDT 0.6B v3 (FluidAudio). WhisperKit is the fallback.

## Goals

- Recognize Polish and English automatically. The user does not select the language. One sentence can contain both languages.
- Keep a personal word list that improves the recognition of names and terms.
- Keep all audio on the device. The app sends no audio to the network.
- Work in all apps through the keyboard.
- Use free macOS CI with a public repository. Every main build goes to TestFlight automatically.

## Non-goals (v1)

- No cloud speech recognition, no user accounts and no analytics.
- No Android, macOS or Windows apps.
- No App Store release. v1 is for personal use through TestFlight.
- No full typing keyboard. The keyboard has only dictation controls, space, delete, return and a globe key.
- No live meeting transcription, no file import and no speaker labels.

## Privacy

- All audio stays on the device.
- The app makes no network calls, except model downloads from Hugging Face.
- v1 has no analytics and no crash logs.
- The keyboard asks for Full Access only to share data with the app through the App Group.
- Secure text fields are not saved in the history.

## Signing and TestFlight

Every push to `main` runs the `testflight` job after `format`, `lint`, `build`, `test` and `crap` pass. The job runs `bundle exec fastlane beta` (see `fastlane/Fastfile`). The lane signs with fastlane `match` (read-only) and uploads the build to TestFlight. The build number is the GitHub run number.

The app (`com.tomiwu.mowa`) and the keyboard (`com.tomiwu.mowa.keyboard`) each need an App Store profile. Both use the App Group `group.com.tomiwu.mowa`. No secret is in the repository.

One-time set-up by the owner:

1. Enroll in the Apple Developer Program.
2. In the developer portal, create the two App IDs and the App Group. Enable the group on both IDs.
3. In App Store Connect, create the app record "mowa". Add yourself as an internal TestFlight tester.
4. In App Store Connect, Users and Access, Integrations, create a Team API key with the App Manager role. Download the `.p8` file.
5. Create the private repository `tomiwu/mowa-certs`. Run `fastlane match appstore` one time.
6. Add the repository secrets in the table below.
7. On the iPhone, install TestFlight, accept the invite and enable the keyboard with Full Access.

| Secret | Content |
| --- | --- |
| `ASC_KEY_ID` | API key id |
| `ASC_ISSUER_ID` | API issuer id |
| `ASC_KEY_P8` | Content of the `.p8` file, base64 |
| `MATCH_GIT_URL` | URL of the private certificates repository |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `user:token` with read access to that repository |
| `MATCH_PASSWORD` | Encryption password for match |
| `APPLE_TEAM_ID` | 10-character team id |

If a secret is missing, the job stops at the first step. The error names each missing secret (`scripts/check_secrets.sh`).

## Licenses

- mowa code: MIT. See [LICENSE](LICENSE).
- Parakeet TDT 0.6B v3 model: CC-BY-4.0, by NVIDIA. mowa uses the model without changes. Source: [nvidia/parakeet-tdt-0.6b-v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3). License: [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).
- Whisper large-v3 turbo model: MIT, by OpenAI.
- FluidAudio: Apache-2.0, by Fluid Inference. WhisperKit: MIT, by Argmax, Inc.

The app shows the same list in Settings (Licenses).

See [docs/PRD.md](docs/PRD.md) for the full requirements.
