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

## Licenses

- mowa code: MIT. See [LICENSE](LICENSE).
- Parakeet TDT 0.6B v3 model: CC-BY-4.0, by NVIDIA.
- FluidAudio: Apache-2.0. WhisperKit: MIT.

See [docs/PRD.md](docs/PRD.md) for the full requirements.
