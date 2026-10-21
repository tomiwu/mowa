# Word list biasing methods (issue #18)

Decision: use **(a) FluidAudio custom vocabulary** (CTC keyword spotting and rescoring) as the main method, with **(c) fuzzy correction** as the fallback.
Facts checked on 2026-10-21 in the FluidAudio source (`Documentation/ASR/CustomVocabulary.md`, main branch) and the WhisperKit source (`Configurations.swift`, main branch).

Status: **NAME ACCURACY NOT MEASURED YET.** The agent that wrote this file works in a Linux container. It has no iPhone, no Mac, no recorded speech and no engine. No accuracy number below is invented. Each result cell is empty until a person runs the procedure. Do not close issue #18 until the table is full and the decision is confirmed (or changed) by the numbers.

## Q3: does FluidAudio have custom vocabulary / context biasing for Parakeet?

Answer: **yes, with a limit.** FluidAudio has a CTC-based custom vocabulary (NVIDIA "CTC-based Word Spotter", arXiv:2406.07096). The ASR text is not biased inside the decoder. The system works after the decoding:

1. Parakeet TDT transcribes the audio as usual.
2. A separate CTC model scores each word list term against the audio (dynamic programming over CTC log-probabilities).
3. `VocabularyRescorer` replaces words in the transcript with the term when the text is similar and the audio supports the term.

| Fact | Value |
| --- | --- |
| Works with Parakeet TDT 0.6B v3 | Yes. Use the "separate CTC encoder" approach: the 0.6B models have no CTC head |
| Extra model | Parakeet CTC 110M, 97.5 MB download |
| Extra memory | About 64 MB (130 MB peak against 66 MB without it, FluidAudio figures on iPhone 17 Pro) |
| Speed | 26x real time (FluidAudio figure) |
| Quality (FluidAudio figure) | 99.4% dictionary recall on English earnings calls |
| Thresholds | Set by vocabulary size in `ContextBiasingConstants.rescorerConfig(forVocabSize:)` |

Limit for mowa: the published numbers are for English. The CTC 110M model is an English model (the name and the benchmarks are English). Its tokens may not fit Polish names like "Wrocław" or "Zbigniew". Q3b (new, open): does the CTC 110M model spot Polish terms? The procedure below answers it.

## Methods

| | (a) FluidAudio vocabulary | (b) WhisperKit prompt | (c) Fuzzy correction |
| --- | --- | --- | --- |
| Works with | Parakeet v3 (main engine) | Whisper only (fallback engine) | Any engine |
| How | CTC spotter and rescorer after the TDT decoding | `DecodingOptions.promptTokens`: the word list as text before the decoder starts | Our own code: replace a word that is close to a term (edit distance, phonetic key) |
| Uses the audio | Yes | Yes (soft hint to the decoder) | No (text only) |
| Extra download and memory | 97.5 MB and about 64 MB | None | None |
| Needs the Whisper fallback | No | Yes: the main engine does not use it | No |
| Platform-free logic that `swift test` can run on Linux | Only the glue (word list to vocabulary) | Only the prompt text | All of it |
| Main risk | English CTC model with Polish names; false replacements of short terms | Prompt is a hint, not a rule; long lists use up the decoder context; only helps in the fallback path | Wrong replacement of a normal word; cannot fix a word that sounds different |

## Reason for the decision

1. Parakeet v3 is the main engine (PRD). Only (a) and (c) work there. (b) helps only in the fallback path, so it cannot be the only method.
2. (a) is the only method that uses the audio for the main engine. (c) sees only the text.
3. The cost of (a) is acceptable: 97.5 MB and about 64 MB of memory. Load the CTC model only when the word list is not empty and unload it after the transcription (FluidAudio advice). Check the memory in the main app with the device protocol (`docs/DEVICE_MEASUREMENTS.md`, NFR3 and NFR8).
4. (c) is the minimum fallback (PRD risk table). If the CTC model does not spot Polish terms (Q3b) or the memory is too high, ship (c). It needs no model and runs on Linux in the tests.
5. (b) is optional later work for the Whisper engine (T3.2). It does not replace (a) or (c).

## Procedure to fill the numbers

Name accuracy = names written correctly / names spoken, in percent. A name is correct when the exact word (same letters, same case, same diacritics) is in the output.

1. Choose 20 names and terms: 10 Polish ("Wrocław", "Zbigniew", "Gdynia", ...) and 10 English or IT terms ("Kubernetes", "GitHub", ...). Add each to the word list.
2. Write 40 sentences, two for each name. Add them to a new file with the same format as `Tools/WerScript/TestSet/sentences.tsv`, or use the `mixed` group. Record them as in `docs/WER_TEST_SET.md`.
3. Transcribe the same audio files four times and count the correct names for each run:
   - baseline: Parakeet v3 with no biasing;
   - (a): Parakeet v3 with `VocabularyBoostingSession` (CTC 110M) and the word list;
   - (b): WhisperKit with `promptTokens` made from the word list (no language hint);
   - (c): baseline text with a fuzzy correction. Use a prototype: a word is replaced when its edit distance to a term is at most 1 for terms up to 6 letters, and at most 2 for longer terms.
4. Count the wrong replacements too: words that were right in the baseline and are wrong now. Run the WER script on the normal test set for each method. The WER must not go up by more than 0.5 points.
5. Measure the extra memory and time of (a) on the device.

## Results

| Method | Polish names (%) | English terms (%) | All names (%) | Wrong replacements | WER change (points) |
| --- | --- | --- | --- | --- | --- |
| Baseline (Parakeet v3) | | | | | |
| (a) FluidAudio vocabulary | | | | | |
| (b) WhisperKit prompt | | | | | |
| (c) Fuzzy correction | | | | | |

Target (NFR5): 90% or more of the names from the word list are correct.

## Confirm or change the decision

- Keep (a) when its "all names" value is 90% or more and the Polish names are not worse than (c).
- Use (c) as the method when (a) is below (c) on Polish names, when (a) makes more wrong replacements than it fixes, or when the memory is too high.
- When no method reaches 90%, ship (c), tell the user about the limit, and open a new issue.

## Implementation (issue #20)

Method (c), fuzzy correction, is in the app now: `WordCorrector` (`Packages/MowaCore`). `DictationRelay` reads the word list from the App Group store and corrects each transcript before it goes to the history and the keyboard. Method (a) needs a device (CTC model, Polish test, memory) and is not built yet.

Rules: the comparison ignores case and diacritics. The first letter must be the same. A term of up to 3 letters must match exactly. A term of 4 to 6 letters allows 1 edit. A longer term allows 2 edits. A term of several words matches the same number of words that are separated by spaces.

### Measured result

| Test | Cases | Correct | Result |
| --- | --- | --- | --- |
| Unit test `nameAccuracyReachesTarget`: 14 typical wrong spellings of 4 names, text only | 14 | 14 | 100% |

This is a text test on Linux. It is **not** the NFR5 measurement. The accuracy on real speech (Parakeet output for 40 recorded sentences, procedure above) is **not measured yet**: this container has no audio and no device. Fill the "(c) Fuzzy correction" row of the table above and keep NFR5 open until a person runs the procedure.
