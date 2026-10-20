# PRD: mowa (iPhone dictation, Polish and English)

Status: Draft v1, 2026-10-20. Owner: Tomasz Wu. Language: ASD-STE100 Simplified Technical English.
Research base: `../research-v1.md`. Fact marks: a fact has a source link. "UNVERIFIED" means that we must do a check before we depend on it. "TARGET" is a value that we selected. It is not a measured fact.

## 1. Summary
mowa is an open-source iPhone app for voice dictation in Polish and English. It has a keyboard extension. When you push the microphone key, the keyboard opens the main app. The main app records the audio and makes the transcription on the device. Then the keyboard puts the text into the text field.

## 2. Problems to solve
1. Language changes in iOS dictation are difficult. The user must select the language manually, and it is not easy to use two languages in one sentence.
2. iOS dictation does not recognize Polish names well (people, places, technical terms).
3. Apple's new on-device API (SpeechTranscriber, iOS 26) does not support Polish. Thus an app cannot use the Apple model for Polish. Sources: https://antongubarenko.substack.com/p/ios-26-speechanalyzer-guide , https://developer.apple.com/forums/tags/speech

## 3. Goals
- G1: Automatic Polish/English recognition. The user does not select the language manually. The app supports two languages in one sentence.
- G2: A personal word list that makes the recognition of names and terms better.
- G3: All audio stays on the device. The app sends no audio to the network.
- G4: The app works in all apps through the keyboard.
- G5: Free macOS CI with a public repository. Every main build goes to TestFlight automatically.

## 4. Non-goals (v1)
- No cloud ASR. No user accounts. No analytics.
- No Android, macOS or Windows apps.
- No App Store release in v1 (TestFlight for personal use first).
- No full typing keyboard (letters) in v1. The keyboard has only dictation controls, space, delete, return and a globe key.
- No live meeting transcription, no file import, and no speaker labels.

## 5. User stories
- US1: As a user, I push the mic key in the mowa keyboard in any app. I speak and then I see the text in the field.
- US2: As a user, I speak Polish and English in one sentence, and both are correct. I do not select the language.
- US3: As a user, I add names ("Wrocław", "Kubernetes", "Zbigniew") to my word list, and the app writes them correctly.
- US4: As a user, I can turn on text clean-up (punctuation, filler words). It is off by default.
- US5: As a user, I see my history in the app. I can copy an item and delete an item or all items.
- US6: As a user, I can select the model (Parakeet or Whisper) and see the model size before the download.
- US7: As a developer, I push to main, CI runs build, test and lint, and the build goes to TestFlight.

## 6. Functional requirements
| ID | Requirement | Priority |
|---|---|---|
| FR1 | The keyboard extension shows a mic key. A tap on the mic key opens the main app with a URL scheme. The app starts the recording session and the user goes back to the host app. This is the Wispr Flow / KeyboardKit pattern (https://docs.wisprflow.ai/articles/2810989204-why-does-it-take-me-to-the-flow-app , https://keyboardkit.com/blog/2026/01/03/a-brand-new-keyboard-dictation-experience) | P0 |
| FR2 | The session stays active for a time that the user can set (TARGET default 5 min idle). Then the next dictations start from the keyboard and the app does not open again | P0 |
| FR3 | The main app records the audio in the background (audio background mode) and makes the transcription with Parakeet TDT 0.6B v3 through FluidAudio | P0 |
| FR4 | The app sends the result to the keyboard through a shared App Group container and Darwin notifications. The keyboard puts the text in with `textDocumentProxy.insertText` | P0 |
| FR5 | Automatic language ID. Parakeet v3 has language ID, punctuation and capitalization (https://huggingface.co/litert-community/parakeet-tdt-0.6b-v3). The behavior with two languages in one sentence is UNVERIFIED (see Q2) | P0 |
| FR6 | Personal word list: add, edit, delete, import/export (text). The method is UNVERIFIED: (a) a FluidAudio custom vocabulary/context-biasing feature, if it is available; (b) a WhisperKit prompt; (c) fuzzy text correction after the transcription. Spike T2.1 selects the method | P0 |
| FR7 | Whisper fallback through WhisperKit (MIT, https://github.com/argmaxinc/WhisperKit). The user can select it in Settings | P1 |
| FR8 | Model manager: download the model on first use, show the size and the progress, delete the model | P0 |
| FR9 | Local history (date, text, language, duration): list, copy, delete one item, delete all items. No audio is kept by default | P1 |
| FR10 | Optional clean-up with an on-device LLM. It is OFF by default. Candidate: Apple Foundation Models framework. Its Polish support is UNVERIFIED | P2 |
| FR11 | Onboarding: add the keyboard, turn on Full Access, and get the microphone permission in the main app (a keyboard cannot show permission dialogs, https://docs.wisprflow.ai/articles/7453988911-set-up-the-flow-keyboard-on-iphone) | P0 |
| FR12 | Keyboard controls: mic/stop, globe (next keyboard), space, delete, return. A status indicator shows "recording", "processing" or "no session" | P0 |

## 7. Non-functional requirements
- NFR1 Latency (TARGET): text shows in less than 1.5 s after the user releases the mic, for 10 s of speech on iPhone 15 or newer. Reference: FluidAudio gives about 190x real time on M4 Pro (https://github.com/FluidInference/FluidAudio/). No iPhone number was found. We must measure it (T1.6).
- NFR2 Memory, keyboard: no ML model and no audio in the extension. TARGET is less than 30 MB. The limit is not published. Sources give 48 MB to 60-70 MB (https://reactnative.dev/docs/app-extensions , https://docs.keyboardkit.com/documentation/keyboardkit/developer-memory-management/).
- NFR3 Memory, main app: Parakeet v3 int8 / Ultra encoder is about 595 MB (FluidAudio Models.md). We must measure the peak memory on the device and keep it below the iOS jetsam limit for background apps (value UNVERIFIED).
- NFR4 Privacy: no network calls except model downloads (Hugging Face) and opt-in crash logs (none in v1). The keyboard asks for Full Access only for the App Group/IPC. We must document the reason in the app. Excluded from history: secure text fields.
- NFR5 Accuracy (TARGET): Polish WER equal to or less than 9% on our test set. Reference: Parakeet v3 FLEURS-pl 7.31% (https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3), 8.21% (https://yapapp.cc/data/on-device-asr-benchmark/csv). Names from the word list: TARGET 90% or more correct.
- NFR6 Licenses: show the CC-BY-4.0 attribution for Parakeet v3 in the app and in the README (https://memoe.app/licenses). mowa code: MIT (proposed).
- NFR7 Platform: Swift, SwiftUI, minimum iOS 26. Xcode 26.6 (17F113), iOS 26.5 SDK: the default Xcode on the GitHub `macos-26` runner image (actions/runner-images macos-26-arm64 README, checked 2026-10-20). Use the newest Xcode that the runner image has.
- NFR8 Battery: do not record when no session is active. The session ends after the idle timeout.

## 8. Architecture
```
Host app text field
   ^ insertText
[MowaKeyboard extension]  -- URL scheme mowa://start --> [Mowa app]
   ^   App Group (shared container: results, word list, settings)   |
   +------------- Darwin notify "result-ready" <--------------------+
                                                                    |
   Mowa app: AudioSession (bg audio) -> VAD/segmenter -> ASR engine -> post-processing -> result
             ASR engine protocol: ParakeetEngine (FluidAudio) | WhisperEngine (WhisperKit)
             post-processing: word-list correction -> optional LLM clean-up (off)
             storage: SwiftData history (local), models in Application Support
```
Modules (Swift packages in one repo): `MowaCore` (protocols, word list, text post-processing; it can be tested on macOS), `MowaASR` (engines), `MowaShared` (App Group IPC), app target, keyboard target.
VAD/endpointing: FluidAudio VAD or Parakeet Realtime EOU 120M (NVIDIA Open Model License, https://memoe.app/licenses). The selection is in T1.4.

## 9. Repository, CI and delivery
- Public repo: `github.com/tomiwu/mowa`. Issues have the labels `P0`, `P1`, `P2`, and `blocked`.
- GitHub Actions on macOS runners. They are free for public repos (https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job). The `macos-26` image has Xcode 26.0.1 to 26.6; 26.6 is the default (checked 2026-10-20).
- Required checks on PRs: `build` (xcodebuild app + keyboard), `test` (unit tests, simulator), `lint` (SwiftLint + swift-format lint).
- On push to main: fastlane `upload_to_testflight` with an App Store Connect API key (.p8 key in repo secrets), with code signing through fastlane match or manual certificates. Fastlane docs are UNVERIFIED in this research (https://docs.fastlane.tools/actions/upload_to_testflight/).
- Apple Developer Program: paid account (99 USD/year, UNVERIFIED in this research, https://developer.apple.com/programs/).
- Work loop: Sandcastle loop with Claude Code. One issue gives one PR, and all checks must pass before the merge.

## 10. Milestones and tasks
### M0: Setup
- T0.1 [P0] Create the public repo tomiwu/mowa, MIT license, README, labels. Blocked by: none
- T0.2 [P0] Xcode project: app + keyboard targets, App Group, URL scheme, iOS 26 min. Blocked by: T0.1
- T0.3 [P0] CI workflow: build, test and lint (SwiftLint, swift-format), and make them required checks. Blocked by: T0.2, Q1
- T0.4 [P0] Signing + fastlane + App Store Connect API key secrets, and TestFlight upload on main. Blocked by: T0.2, the Apple account
### M1: Dictation end-to-end (Polish/English)
- T1.1 [P0] MowaShared: App Group store and Darwin notification IPC, with unit tests. Blocked by: T0.2
- T1.2 [P0] Keyboard UI (mic, globe, space, delete, return, status). Blocked by: T0.2
- T1.3 [P0] Main app: URL handler, background audio session, idle timeout. Blocked by: T0.2
- T1.4 [P0] VAD/endpointing selection and integration. Blocked by: T1.3
- T1.5 [P0] ParakeetEngine through FluidAudio + model manager (download, size, delete). Blocked by: T1.3
- T1.6 [P0] Measure the latency and memory on a real iPhone (NFR1, NFR3). Blocked by: T1.5, T0.4
- T1.7 [P0] Onboarding (keyboard, Full Access, microphone). Blocked by: T1.2, T1.3
- T1.8 [P0] Polish/English test set (with mixed sentences) and a WER script. Blocked by: T1.5
### M2: Personal word list
- T2.1 [P0] Spike: compare the biasing methods (FluidAudio vocabulary, Whisper prompt, fuzzy correction). Blocked by: T1.8
- T2.2 [P0] Word list UI + storage (shared with the keyboard). Blocked by: T1.1
- T2.3 [P0] Implement the selected method and measure the name accuracy (NFR5). Blocked by: T2.1, T2.2
### M3: History and fallback
- T3.1 [P1] History (SwiftData): list, copy, delete, delete all. Blocked by: T1.5
- T3.2 [P1] WhisperEngine through WhisperKit + model selection in Settings. Blocked by: T1.5
### M4: Clean-up and release preparation
- T4.1 [P2] Spike: on-device LLM clean-up (Foundation Models, Polish support). Blocked by: T1.5
- T4.2 [P2] Clean-up toggle (off by default). Blocked by: T4.1
- T4.3 [P2] Licenses screen (CC-BY-4.0 Parakeet, MIT WhisperKit, Apache-2.0 FluidAudio). Blocked by: T1.5
- T4.4 [P2] App Store preparation (privacy label, review notes about Full Access). Blocked by: M1-M3

## 11. Risks
| Risk | Effect | Mitigation |
|---|---|---|
| iOS stops background recording or changes keyboard rules (Wispr Flow has a help page for iOS 26.4: https://docs.wisprflow.ai/articles/6269634092-adapting-to-ios-26-4) | Main flow fails | Follow the KeyboardKit/Wispr pattern. Test on each iOS beta |
| Main app memory with a 0.6B model in background | App is stopped | Measure (T1.6). Use the Redux model (~220 MB, iOS 18+) as an option |
| Mixed Polish/English accuracy is not known | G1 fails | Test set T1.8. Whisper fallback |
| No good biasing method for names | G2 fails | Use fuzzy correction after the transcription as the minimum |
| App Review rejects Full Access/background audio | App Store delay | TestFlight first. Clear review notes |
| A new Xcode is not yet on the runner | CI cannot use it | Pin Xcode 26.6 with `xcode-select`; update when the image adds a newer one |

## 12. Open questions
- Q1: CLOSED. Xcode 26.6 is the default on `macos-26`. See docs/CI_PLAN.md.
- Q2: What is the WER of Parakeet v3 on mixed Polish/English sentences? Does it change the language in the middle of a sentence?
- Q3: Does FluidAudio have custom vocabulary/context biasing for Parakeet? UNVERIFIED.
- Q4: Does Apple Foundation Models support Polish? UNVERIFIED.
- Q5: Is Parakeet Ultra (FLEURS 24-language mean 11.67% vs 14.81% v3) better for Polish? Test it in T1.8.
- Q6: What are the background memory limits for the main app on iPhone 15/16? Measure them.
- Q7: Does DictationTranscriber support Polish on iOS 26/27 (as a zero-download fallback)? Test it at runtime.
