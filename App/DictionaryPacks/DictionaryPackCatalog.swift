import Foundation

/// Dictionary packs this app knows about and can fetch from GitLab on
/// request. Nothing here is bundled, pre-installed, or downloaded
/// automatically — each entry is a single explicit tap in Settings → Fetch
/// dictionary → "Available to download", for a user who's specifically
/// curious about that language. Most users installing the app should end up
/// with none of these downloaded.
///
/// Extending this to a new dual-language pack (e.g. Tamil–Gujarati, Latin–
/// English, Farsi–English) is adding one more `RemoteDictionaryPackSource`
/// entry — no other code changes, as long as the source either publishes a
/// {manifest, entries} JSON directly (`.dictionaryPackJSON`), or a new
/// parser is added alongside NavajoKitTrainingDataParser for its own format.
enum DictionaryPackCatalog {
    static let availableSources: [RemoteDictionaryPackSource] = [
        RemoteDictionaryPackSource(
            id: "nv-en-navajo-translation-project",
            displayName: "Navajo (Diné)",
            languageCode: "nv",
            summary: "~12,800 single-word and compound-word entries from the open-source Navajo Translation Project (NavajoKit). CC BY-SA 4.0 — attribution and share-alike terms apply.",
            gitLabProjectPath: "HullBreach/navajokit",
            // Confirmed directly against the real repo (2026-09-03):
            // Package.swift lists these as the package's bundled resources,
            // and both files share the TOKENS/LABELS/english header
            // NavajoKitTrainingDataParser expects (11,254 + 1,583 rows ≈
            // the ~12,800 the project advertises). NavajoKit also ships
            // NVClauses.csv/NVPassages.csv (example sentences/passages,
            // not single dictionary entries) — left out for now, not
            // because they're unusable, just a different shape than a
            // term/gloss dictionary entry.
            filePaths: [
                "Sources/NavajoKit/Resources/training_data/NVSingleWords.csv",
                "Sources/NavajoKit/Resources/training_data/NVCompoundWords.csv",
            ],
            format: .navajoKitTrainingCSV,
            ref: "main",
            version: "main",
            sourceDescription: "Navajo Translation Project (NavajoKit) — NVSingleWords.csv + NVCompoundWords.csv",
            license: "CC BY-SA 4.0 — Navajo Translation Project / NavajoKit (gitlab.com/HullBreach/navajokit)"
        )

        // Future dual-language packs go here, e.g.:
        // RemoteDictionaryPackSource(
        //     id: "ta-gu-...",
        //     displayName: "Tamil–Gujarati",
        //     languageCode: "ta",
        //     summary: "...",
        //     gitLabProjectPath: "...",
        //     filePaths: ["..."],
        //     format: .dictionaryPackJSON,
        //     ref: "main",
        //     version: "1.0.0",
        //     sourceDescription: "...",
        //     license: "..."
        // ),
    ]
}
