# VAD / endpointing selection (issue #8)

Decision: use the **Silero VAD** through FluidAudio (`VadManager`). Do not use Parakeet Realtime EOU 120M.
Facts checked on 2026-10-21 in the FluidAudio source (v0.17.7) and README.

## Comparison

| | Silero VAD (FluidAudio) | Parakeet Realtime EOU 120M |
| --- | --- | --- |
| Task | Speech or silence for each 256 ms chunk | Streaming ASR with end-of-utterance token |
| Languages | Language independent (acoustic) | English only (FluidAudio README) |
| Output | Speech probability per chunk | Text and an end-of-utterance event |
| Extra work | None. The segmenter decides with the probability | Runs a second ASR model; Parakeet TDT v3 already does the transcription |
| Model licence | MIT (snakers4/silero-vad; Core ML conversion `FluidInference/silero-vad-coreml`) | NVIDIA Open Model License |
| SDK licence | FluidAudio: Apache-2.0 | FluidAudio: Apache-2.0 |

## Reason

1. mowa must dictate Polish. The EOU model supports English only, so it cannot end a Polish utterance.
2. The mic release is the main cut. The VAD only has to find pauses and trim silence. A probability per chunk is enough, and the cut logic stays in our own pure code (`SpeechSegmenter`) that we can test on Linux.
3. EOU runs a second ASR model next to Parakeet TDT v3 (more memory and battery; see NFR3 and NFR8).
4. The MIT licence has no extra terms for the app.

## In the pipeline

`AudioEngineRecorder` (16 kHz mono samples) -> `SpeechPipeline` -> `SileroSpeechDetector` (probability per 4096 samples) -> `SpeechSegmenter` -> `SpeechSegment`.
When the recording stops, the stream ends and the pipeline cuts the open utterance. Defaults in `SegmenterConfig.standard`: start at 0.85, silence below 0.7, 2 silent chunks (512 ms) end an utterance, 1 chunk of pre-roll. Tune them on a device in T1.6.
