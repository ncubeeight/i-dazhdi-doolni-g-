# Sample dictionary packs

Not part of the app bundle — these are fixtures for exercising the import →
on-device lookup → tap-to-define pipeline (`App/DictionaryPacks/`,
`TranscriptWordToken` in `App/Pipeline/TranscriptionRunnerView.swift`).

## `navajo-sample-fixture.json`

Six well-known, widely published Navajo (Diné) words/phrases — **not** the
Navajo Translation Project's ~12,800-entry dataset. It exists to prove the
pipeline end to end, not to be studied from. Swap it for a real pack sourced
from the Navajo Translation Project's GitLab data before relying on it.

## Trying it in the Simulator

1. Build and run the app.
2. Drag `navajo-sample-fixture.json` onto the Simulator window (this adds
   it to the Simulator's Files app), or AirDrop it to a device.
3. In the app: **Settings → Fetch dictionary → Connect on-device
   dictionary**, then pick the file from Files.
4. Import some Navajo text via **Samples → import text**, declaring the
   language as **Navajo (Diné)**, then tap one of the sample words (e.g.
   `yá'át'ééh`) — the popover should show the gloss instantly, labeled
   "On-device dictionary," with no network or on-device-model call.
5. Tap a word *not* in the fixture to confirm the fallback still reaches
   `WordGlossGenerator`'s on-device model path, labeled "On-device model."

## Pack file format

```json
{
  "manifest": {
    "id": "unique-pack-id",
    "languageCode": "nv",
    "displayName": "Human-readable name",
    "version": "1.0.0",
    "entryCount": 123,
    "sourceDescription": "Where this came from",
    "license": "License name",
    "checksumSHA256": null
  },
  "entries": [
    { "term": "word", "gloss": "short English gloss", "partOfSpeech": "noun", "exampleSentence": null }
  ]
}
```

`languageCode` must match the target language's
`SupportedLanguage.dictionaryPackLanguageCode` (see
`App/Transcription/SupportedLanguage.swift`) for lookups to find it —
`"nv"` for Navajo.
