# On-device LLM clean-up with Foundation Models (issue #16)

Decision: **do not continue** with Foundation Models as the clean-up engine for Polish. English-only clean-up stays possible, but T4.2 must not ship it as a Polish and English feature. This decision is provisional until a person runs the procedure below on a device.

Status: **NOT MEASURED YET.** The agent that wrote this file works in a Linux container. It has no iPhone, no Mac and no Apple framework. No test result below is invented. Each result cell is empty until a person fills it. Do not close issue #16 until the tables are full and the decision is confirmed (or changed) by the results.

Facts checked on 2026-10-21 from web sources (not from a device):

- Apple documents `SystemLanguageModel.supportedLanguages` and `supportsLocale(_:)`. The list is read at runtime ([SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel.md)).
- A developer forum post lists Polish among the device languages where the model is unavailable ([forum thread 805378](https://developer.apple.com/forums/thread/805378)). It is a user report, not an official list, and it can be old.
- Launch-era sources list ten languages for the speech APIs and none is Polish ([Addpipe](https://blog.addpipe.com/apple-speechanalyzer-api/)). They can be out of date.

## Q4: does Apple Foundation Models support Polish?

Answer: **probably not, not confirmed.** Public sources give no evidence that Polish is supported. Apple can add languages in a new OS version, so the final answer comes from the device check below.

Two limits apply even when `supportsLocale` says yes:

1. The model must be available on the device (Apple Intelligence on, model downloaded). `SystemLanguageModel.default.availability` can be unavailable. The clean-up must then do nothing.
2. A forum report says the check uses the device language, not the language of the text. A user with a Polish device language can be blocked for English text too. The keyboard user base for mowa includes such users.

### Procedure

Run on a device with iOS 26 or later and Apple Intelligence on.

1. Log `SystemLanguageModel.default.availability`, `supportedLanguages` and `supportsLocale(Locale(identifier: "pl_PL"))`. Repeat with the device language set to English and to Polish.
2. Take 20 raw Parakeet outputs from the test set (`docs/WER_TEST_SET.md`): 10 Polish, 10 English. Choose outputs with no punctuation, filler words ("yyy", "eee", "no więc", "um", "like"), and wrong case.
3. Run each text through `LanguageModelSession` with the instruction: "Add punctuation and capital letters. Remove filler words. Do not change, add or translate any other word. Return only the text."
4. Count for each language:
   - **Meaning kept:** the output has the same words, apart from removed fillers (a person checks).
   - **Punctuation correct:** a person gives pass or fail.
   - **Fillers removed:** fillers removed / fillers in the input.
   - **Bad output:** refusal, translation, a guardrail error, an answer to the text (the model treats the dictation as a question), or an added word.
   - **Time:** seconds for a text of 30 words.
5. Check the mixed Polish/English sentences from the test set. Check that the model does not translate.

### Results

| Language | Supported (`supportsLocale`) | Meaning kept | Punctuation correct | Fillers removed | Bad outputs | Time (s) |
| --- | --- | --- | --- | --- | --- | --- |
| English | | | | | | |
| Polish | | | | | | |
| Mixed | | | | | | |

## Q7: does DictationTranscriber support Polish on iOS 26 and later?

Answer: **not confirmed.** Apple documents `DictationTranscriber.supportedLocales` (all locales, also those to download) and `installedLocales` ([DictationTranscriber](https://developer.apple.com/documentation/speech/dictationtranscriber.md)). One source says it has the same languages as the old on-device `SFSpeechRecognizer` and serves as the fallback for languages that `SpeechTranscriber` does not support. The old Siri dictation supports Polish, so a yes is likely, but this is a guess until the runtime check.

### Procedure

1. Log `DictationTranscriber.supportedLocales` and `installedLocales`. Check for `pl_PL` and `en_US`. Also log `SpeechTranscriber.supportedLocales`.
2. If `pl_PL` is supported, install it with `AssetInventory` and record the download size and the time.
3. Transcribe the Polish files of the test set. Run the WER script. Compare with Parakeet v3.
4. Record the result for each OS version that you test.

### Results

| OS version | `pl_PL` in `supportedLocales` | Installed without download | Download size | Polish WER (%) | English WER (%) |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

If Polish is supported, DictationTranscriber is a zero-extra-model fallback for the engine protocol (it uses a system asset, not an app download). If not, the Whisper fallback (T3.2) stays the only fallback.

## Recommendation

**Do not continue** with Foundation Models for Polish clean-up. Reasons:

1. No source shows Polish support. The FR10 feature is P2 and off by default, so the risk of a wrong output in Polish is not worth the work.
2. The availability depends on Apple Intelligence and on the device language. The feature would not work for part of the users.
3. The LLM can change the words (translate, answer, add text). For dictation this is worse than missing punctuation.
4. Parakeet TDT v3 already writes punctuation and capital letters. The gain is mostly filler word removal, which a small rule list can do on Linux with `swift test`.

Next steps:

- Run the procedures above. Confirm the decision when the Polish row shows Foundation Models is unsupported or bad.
- Change the decision to **continue** only when Polish is supported and the Polish row has no bad outputs and the meaning is kept in all 10 texts.
- Change T4.2 to a rule-based clean-up (filler word list for Polish and English). Use Foundation Models only for English, behind `supportsLocale` and `availability` checks, and only when the English row passes.
