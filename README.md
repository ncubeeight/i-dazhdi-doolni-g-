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
  `RemoteDictionaryPackSource`). An installed pack is always one JSON file
  (`{manifest, entries}`); both import (file already on device) and
  download (fetched once from GitLab) funnel into the same
  `DictionaryPackImporter.importPack(from: Data)`, which is the only place
  a pack is validated and written to the app's own container. A remote
  source doesn't have to already be in that JSON shape — the catalog can
  declare a source's real format (`RemoteDictionaryPackFormat`) and
  `GitLabDictionaryPackFetcher` converts on the fly; the Navajo entry uses
  this to fetch NavajoKit's actual CSV training data and parse it
  (`NavajoKitTrainingDataParser`) rather than requiring a pre-converted copy.
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

The Navajo catalog entry is now real and downloadable — confirmed directly
against [gitlab.com/HullBreach/navajokit](https://gitlab.com/HullBreach/navajokit)
(the Swift package "NavajoKit," documented at
[hullbreach.gitlab.io/navajokit](https://hullbreach.gitlab.io/navajokit/documentation/nava)):
it fetches `NVSingleWords.csv` (11,254 entries) and `NVCompoundWords.csv`
(1,583 entries) — ≈12,837 total, matching the project's advertised
~12,800 — parses NavajoKit's real header schema
(`TOKENS,LABELS,english,...`, columns located by name since the two files
order them slightly differently), and builds the pack's manifest itself
(the CSVs carry no manifest of their own).

It also cross-references `NVClauses.csv` (short, already-translated example
sentences) against every fetched entry, filling in
`DictionaryEntry.exampleSentence`/`exampleSentenceTranslation` wherever a
term appears in one of its sentences (`NavajoKitSentenceParser` + the
enrichment step in `GitLabDictionaryPackFetcher`) — surfaced in the
tap-to-define popover (`TranscriptWordToken`) underneath the gloss.
`NVPassages.csv` was considered too but deliberately excluded: its rows are
full multi-sentence passages (thousands of characters each) with a
"Source" citation column instead of an English translation, so there's
nothing short or translated to pair a word with. `SamplePacks/navajo-sample-fixture.json`
still exists as a tiny, instant fixture for exercising the pipeline without
a network call.

*(How this got confirmed: `gitlab.com` is unreachable from the environment
this catalog was originally authored in, so a one-time GitHub Actions
mirror — `ncubeeight/navajokit-new` — was used to read the real repo
structure once. The app itself has no dependency on that mirror; its
catalog entry fetches straight from `gitlab.com` at runtime, same as any
other GitLab-hosted pack.)*

## License

This repository's own code is Apache License 2.0 (see `LICENSE`).

Dictionary data fetched or imported at runtime keeps **its own** license —
it is not relicensed as Apache 2.0 just by passing through this app. The
Navajo (Diné) pack fetched via Settings → Fetch dictionary is
**CC BY-SA 4.0**, per the Navajo Translation Project
([gitlab.com/HullBreach/navajokit](https://gitlab.com/HullBreach/navajokit)):
attribution is required, and any redistributed or adapted form of that
data must stay under a compatible ShareAlike license. `DictionaryPackManifest.license`
carries this per-pack for exactly that reason — check it before
redistributing any pack's contents.
