# Latency and memory on a real iPhone (issue #12)

Status: **NOT MEASURED YET.** The agent that wrote this file works in a Linux container and has no iPhone.
No number below is invented. Each result cell is empty until a person runs the procedure on a device and fills it.
Do not close issue #12 until the tables are full and the verdicts are set.

## Targets

| ID | Target | Source |
| --- | --- | --- |
| NFR1 | Text shows in less than 1.5 s after the mic release, for 10 s of speech, on iPhone 15 or newer | `docs/PRD.md` |
| NFR3 | Peak memory of the main app in the background is below the jetsam limit | `docs/PRD.md` |
| Q6 | Measure the background memory limit on iPhone 15 and iPhone 16 | `docs/PRD.md` |

## Facts known before the measurement

- Parakeet TDT 0.6B v3 int8 / Ultra encoder: about 595 MB on disk (FluidAudio Models.md).
- Redux model (fallback if memory is too high): about 220 MB, iOS 18+.
- FluidAudio speed on M4 Pro: about 190x real time. This is not an iPhone number.
- The jetsam limit for a background app is UNVERIFIED. Measure it (Q6).

## Equipment

| Item | Value |
| --- | --- |
| Devices | iPhone 15, iPhone 16 (record the exact model) |
| iOS version | |
| Build | Release configuration, installed with Xcode 26.6, no debugger attached |
| Model | Parakeet TDT 0.6B v3 (first run), Redux (only if NFR3 fails) |
| Phone state | Not in Low Power Mode, battery above 50 %, room temperature, model already downloaded |
| Test speech | One recording of 10 s of speech, read aloud, once in Polish and once in English |

## Procedure: latency (NFR1)

1. Do a warm-up dictation first. Ignore it. The first run compiles the Core ML model.
2. Start the dictation from the keyboard. Speak the test text for 10 s. Release the mic.
3. Latency = time from the mic release (the stop event in the app) to the time the text is saved in the shared store.
   Read both times with `os_signpost` or `Logger` time stamps, or with the Instruments "Points of Interest" track.
4. Do 10 runs for each language. Write the median and the worst run.
5. Do the runs again with a cold start (the app was ended and the model is not in memory). Write them as a separate row.
6. Also write the time until the text shows in the text field of the host app. It is the number the user sees.

| Device | Language | Start | Runs | Median (s) | Worst (s) | Under 1.5 s? |
| --- | --- | --- | --- | --- | --- | --- |
| iPhone 15 | Polish | warm | 10 | | | |
| iPhone 15 | English | warm | 10 | | | |
| iPhone 15 | Polish | cold | 10 | | | |
| iPhone 16 | Polish | warm | 10 | | | |
| iPhone 16 | English | warm | 10 | | | |
| iPhone 16 | Polish | cold | 10 | | | |

## Procedure: memory (NFR3, Q6)

1. Open the main app with Xcode Instruments (Allocations and "Memory" in the Activity Monitor template). Use the footprint value (`phys_footprint`), not the resident size.
2. Do the same dictation as above with the app in the background (the keyboard opened it, the user went back to the host app).
3. Write the footprint after the model load, at idle, and the peak during the transcription.
4. Find the jetsam limit: in Xcode, run `os_proc_available_memory()` in the background and log it. The limit is the footprint plus the available memory.
   Also look for "jetsam" events in the device log (Settings > Privacy > Analytics Data, `JetsamEvent-*.ips`).
5. Keep the app in the background for 10 minutes with the model loaded. Check that iOS did not stop the app.

| Device | Model | Footprint after load (MB) | Idle (MB) | Peak (MB) | Background limit (MB) | Stopped by jetsam? | Peak below limit? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| iPhone 15 | Parakeet v3 | | | | | | |
| iPhone 16 | Parakeet v3 | | | | | | |
| iPhone 15 | Redux (only if needed) | | | | | | |
| iPhone 16 | Redux (only if needed) | | | | | | |

## Verdicts

| Target | Met? | Evidence |
| --- | --- | --- |
| NFR1 latency under 1.5 s for 10 s of speech | not measured | |
| NFR3 peak memory below the background limit | not measured | |
| Q6 background limit known for iPhone 15 and 16 | not measured | |

## Recommendation

Fill this section after the measurement. Use these rules:

- NFR1 not met on warm runs: first check the VAD settings in `SegmenterConfig.standard` (see `docs/VAD_SELECTION.md`) and the cut of the last chunk, then check the compute units of the Core ML model, then think about the Redux model or WhisperKit tiny as the first pass.
- NFR3 not met: test the Redux model (about 220 MB) on both phones, run the memory and latency tables again for it, and compare the word error rate on the Polish test text. Unload the model when the app goes to the background for a long time.
- Both targets met: write "no change" and keep Parakeet TDT 0.6B v3.
