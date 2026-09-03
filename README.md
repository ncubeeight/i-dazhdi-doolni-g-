# i'dazhdi'doolniłígíí

*(GitHub repo slug: `i-dazhdi-doolni-g-` — GitHub repository names only allow
ASCII letters, digits, hyphens, underscores, and periods, so the Diné name
above is carried in this README and the repo description instead.)*

Language support packs for learning — an extensible, **non-LLM** fork of
[Déjà Entendu](https://github.com/ncubeeight/deja-entendu).

## Why this fork exists

Déjà Entendu's mainline app leans on Apple's on-device Foundation Model LLM
for glossing and translation, which means its language support is capped by
whichever languages that model covers. This fork exists to add a second,
independent path: an **importable dictionary-pack architecture** so the app
can look up terms from a static, on-device dictionary — no LLM, no live
network call — starting with a Navajo (Diné) dictionary pack sourced from
the open-source Navajo Translation Project dataset (~12,800 entries).

This is a separate repository rather than a branch of `deja-entendu` for two
reasons:

1. **`deja-entendu` is in Apple App Store review.** Keeping this work in its
   own repo avoids any appearance of the reviewed codebase shifting
   mid-review.
2. **Independence for other developers.** Anyone who wants the
   extensible, non-LLM dictionary-pack approach — for Navajo or any other
   language — can build on this fork without being tied to
   `deja-entendu`'s future Apple Intelligence–specific features and
   constraints (useful for older devices, and for regions where on-device
   LLM use is restricted).

## Relationship to Déjà Entendu

This repository was forked from `deja-entendu`'s `main` branch. From here,
the two projects diverge: `deja-entendu` continues as the Apple
Intelligence–driven mainline; this fork adds the dictionary-pack import
architecture as an additional, LLM-independent lookup path.

## Status

Scaffolding in place:

- `App/DictionaryPacks/` — pack manifest format (`DictionaryPackManifest`,
  `DictionaryPackContents`), on-device store (`DictionaryPackStore`),
  importer (`DictionaryPackImporter`), in-memory lookup service
  (`DictionaryLookupService`), and a GitLab downloader
  (`GitLabDictionaryPackFetcher` + `DictionaryPackCatalog`,
  `RemoteDictionaryPackSource`). A pack is a single JSON file
  (`{manifest, entries}`); both import (file already on device) and
  download (fetched once from GitLab) funnel into the same
  `DictionaryPackImporter.importPack(from: Data)`, which is the only place
  a pack is validated and written to the app's own container.
- `App/LLMConnection/` — a separate, explicitly opt-in settings screen for
  connecting cloud LLM providers via MCP (Claude, Gemini, ChatGPT,
  Perplexity). Selection-only for now; not wired to an actual MCP client.
- Settings now leads with two entries above the language toggles: "Fetch
  dictionary" (on-device; at most one upfront network fetch per pack, then
  fully offline) and "Connect to your LLM" (cloud, requires an ongoing
  connection) — kept on separate screens because of their very different
  privacy/connectivity tradeoffs.
- Tap-to-define in imported transcripts checks an installed pack first,
  falling back to the on-device LLM gloss only when no pack covers that
  word's language (see `TranscriptWordToken` in
  `App/Pipeline/TranscriptionRunnerView.swift`).
- `App/DictionaryPacks/DictionaryPackCatalog.swift` lists dictionaries the
  app can fetch from GitLab under Settings → Fetch dictionary → "Available
  to download." **Nothing downloads automatically** — each entry needs an
  explicit tap, so installing the app doesn't hand every user a dictionary
  they didn't ask for. Adding another dual-language pack later (Tamil–
  Gujarati, Latin–English, Farsi–English, etc.) is one more catalog entry,
  no other code changes, as long as the source publishes its data in the
  same JSON shape.

Known gap: the Navajo Translation Project's real repository is confirmed —
[gitlab.com/HullBreach/navajokit](https://gitlab.com/HullBreach/navajokit)
(Swift package "NavajoKit," ~12,800-entry dictionary, documented at
[hullbreach.gitlab.io/navajokit](https://hullbreach.gitlab.io/navajokit/documentation/nava))
— but its catalog entry's `filePath` is deliberately left unset, because
gitlab.com couldn't be browsed from the environment this catalog was
written in to confirm the exact path to its dictionary data file, or
whether that data is already in `DictionaryPackContents`' JSON shape or
needs converting first. Until that's confirmed and set, the Navajo entry
shows as "Not yet available" rather than attempting a download that would
likely 404. `SamplePacks/navajo-sample-fixture.json` (a handful of
well-known words, imported via "Connect on-device dictionary") remains the
way to exercise the lookup/tap-to-define pipeline in the meantime.

## License

Apache License 2.0 (see `LICENSE`).
