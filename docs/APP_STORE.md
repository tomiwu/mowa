# App Store preparation (issue #21)

Status: **DRAFT. The numbers are not measured yet.** The agent that wrote this file has no iPhone.
The PRD says there is no App Store release in v1 (TestFlight first). Use this file when the release decision is made.

## Privacy label (App Store Connect, "App Privacy")

| Question | Answer | Reason |
| --- | --- | --- |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data** | Audio and text stay on the device. The app has no server and no analytics. |
| Tracking | No | No advertising ID, no third-party SDK that tracks. |
| Data linked to the user | None | Nothing leaves the device. |
| Crash logs | None sent by the app | Apple's own crash reports (opt-in by the user in iOS settings) are not collected by us. |

Facts behind the answers:

- Audio is processed on the device by Parakeet TDT 0.6B v3 (FluidAudio) or by WhisperKit. No audio is kept by default.
- The history (date, text, language, duration) is in SwiftData on the device. The user can delete one item or all items.
- The only network use is the download of the speech model from Hugging Face. The request has no user data.
- Optional clean-up uses Apple Foundation Models on the device. It is off by default.
- The keyboard extension has no network code. Its Full Access flag is used for the App Group only (see below).

Privacy policy: App Store Connect needs a privacy policy URL. The text is: "mowa does not collect, send or share your audio or text. All dictation runs on your iPhone. The app connects to the network only to download the speech model."

## Review notes (paste in "App Review Information > Notes")

mowa is a dictation keyboard for Polish and English. All speech recognition runs on the device.

**How to test**

1. Open mowa. Do the onboarding: allow the microphone.
2. Settings > General > Keyboard > Keyboards > Add New Keyboard > "mowa keyboard". Turn on "Allow Full Access".
3. Open any app with a text field (Notes). Switch to the mowa keyboard and tap the mic key.
4. mowa opens for a short time and starts to record. Go back to Notes with the back link at the top left of the screen. Speak, then tap the mic key again. The text shows in the field.
5. The speech model downloads on the first start. Use a Wi-Fi connection for this step.

**Why the keyboard needs Full Access (`RequestsOpenAccess`)**

- A keyboard extension cannot use the microphone. The main app records the audio and transcribes it.
- The keyboard and the main app share the result through an App Group container. A keyboard can read and write the shared container only with Full Access.
- The keyboard has no network code. It does not send what the user types or says. Full Access is not used to log keystrokes or to send data to a server.
- The app explains this in the onboarding screen before the user turns it on. The keyboard works as a basic keyboard without Full Access, but dictation does not work.
- Text fields with secure input (passwords) are not saved in the history.

**Why the app uses background audio (`UIBackgroundModes: audio`)**

- The user starts a dictation from the keyboard in another app. iOS does not let the keyboard record, so the main app records.
- After the main app opens, the user goes back to the host app. The app must keep the audio session active in the background so that the recording continues and the next dictations start from the keyboard without opening the app again.
- The app records only while the user has started a dictation. The session ends after an idle time that the user sets in Settings (default 5 minutes). The microphone indicator of iOS shows when the app records.
- The app does not play audio in the background and does not record without a user action.

**Other notes**

- The microphone usage text: "mowa records your voice on this device to turn it into text."
- Open source licenses of the models and libraries are in Settings > Licenses.

## Targets and known limits

The targets are from `docs/PRD.md`. Fill the last column when a person measures on a device.

| Target | Value | Status | Known limit or evidence |
| --- | --- | --- | --- |
| NFR1 latency | Text shows in less than 1.5 s after the mic release, 10 s of speech, iPhone 15 or newer | Not measured | Procedure and tables: `docs/DEVICE_MEASUREMENTS.md`. Known limit until measured: the first dictation after a model install compiles the Core ML model and is slower. |
| NFR2 keyboard memory | Less than 30 MB | Not measured | The keyboard has no ML model and no audio. The iOS limit is not published (sources: 48 MB to 70 MB). |
| NFR3 main app memory | Peak below the background jetsam limit | Not measured | Parakeet v3 is about 595 MB on disk. If the peak is too high, use the Redux model (about 220 MB). See `docs/DEVICE_MEASUREMENTS.md`. |
| NFR5 Polish WER | 9 % or less on our test set | Not measured on the app | Reference only: Parakeet v3 FLEURS-pl 7.31 %. Test set and script: `docs/WER_TEST_SET.md`. |
| NFR5 names | 90 % or more correct with the word list | Not measured on a device | Method comparison: `docs/BIASING_METHODS.md`. |

Rule for the release: if a target is not met when the measurements are done, write the real number and the limit in this table and in the App Store description. Do not submit with a target that is "not measured".

## Checklist before submission

- [ ] The tables in `docs/DEVICE_MEASUREMENTS.md` are full.
- [ ] The table above has a real value in each row.
- [ ] The privacy policy is online and its URL is in App Store Connect.
- [ ] The privacy label in App Store Connect matches the first table.
- [ ] The review notes are pasted. A short screen recording of the flow in step 3 and 4 is attached.
