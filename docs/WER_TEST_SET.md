# Polish/English test set and WER (issue #13)

Status: **NOT MEASURED YET.** The agent that wrote this file works in a Linux container. It has no iPhone, no Mac and no recorded speech.
No WER number below is invented. Each result cell is empty until a person runs the procedure and fills it.
Do not close issue #13 until the tables are full and the answers to Q2 and Q5 are written.

## Test set

File: `Tools/WerScript/TestSet/sentences.tsv`. Each line is `id<TAB>group<TAB>reference text`.

| Group | Sentences | Content |
| --- | --- | --- |
| `polish` | 15 | Everyday Polish: numbers, dates, names of places, diacritics |
| `english` | 15 | The same topics in English |
| `mixed` | 15 | Polish sentences with English words (work and IT terms), and sentences that change language in the middle |

The sentences are written by us. They are a first set (45 sentences, about 450 words). Add more sentences before you trust a small WER difference.

## Record the speech

1. Read each sentence aloud at normal speed, in a quiet room, with the iPhone microphone. Use the same speaker for all runs.
2. Keep one audio file for each sentence. Name it with the id (`pl01.wav`, `mx07.wav`).
3. Use the same files for every engine, so the engines get the same input.

## Transcribe

Run each audio file through the engine and write the text to a tab-separated file: `id<TAB>text`, one line per sentence.
Do this for Parakeet v3 (`hyp-parakeet-v3.tsv`) and for Parakeet Ultra Q5 (`hyp-parakeet-ultra-q5.tsv`).
The engine must use automatic language detection (no language hint), because this is how the keyboard works.

## Compute the WER

```
swift run --package-path Tools/WerScript wer Tools/WerScript/TestSet/sentences.tsv hyp-parakeet-v3.tsv
```

The script prints one line for each group and the verdict for the Polish target:

```
polish: WER 7.31% (E errors, W words, N sentences)
english: WER ...
mixed: WER ...
Polish target (<= 9%): met
```

Rules of the script: text is made lower case, punctuation is dropped (an apostrophe or hyphen inside a word stays), and the WER is the word edit distance divided by the number of reference words, per group. A sentence with no line in the hypothesis file stops the script with an error.

## Results

| Engine | Polish WER (%) | English WER (%) | Mixed WER (%) | Polish target (9 %) met? |
| --- | --- | --- | --- | --- |
| Parakeet v3 | | | | |
| Parakeet Ultra (Q5) | | | | |

Reference values from other sources (not our test set): Parakeet v3 FLEURS-pl 7.31 % and 8.21 % (see `docs/PRD.md`, NFR5).

## Q2: does Parakeet v3 change the language in the middle of a sentence?

Answer: **not known yet.**
How to answer: in `hyp-parakeet-v3.tsv`, read each `mixed` line. Mark a sentence as a language change when the engine writes an English word in Polish spelling (or the reverse), for example "plik" written as "pleak". Write the count of marked sentences and two examples here.

| Mixed sentences | With wrong-language words | Examples |
| --- | --- | --- |
| 15 | | |

## Q5: is Parakeet Ultra (Q5) better for Polish than v3?

Answer: **not known yet.**
Compare the Polish WER and the mixed WER of the two engines in the table above. Ultra is better when its Polish WER is lower on the same recordings. Also note the model size on disk and the speed on the iPhone, because they decide if Ultra can replace v3.

## NFR5 verdict

Target: Polish WER of 9 % or less. Verdict: **open** (no measurement yet).
