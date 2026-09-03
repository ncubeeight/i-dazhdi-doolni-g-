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
/// entry — no other code changes, as long as the source publishes its data
/// in the {manifest, entries} JSON shape DictionaryPackContents expects
/// (see SamplePacks/README.md for the exact format).
enum DictionaryPackCatalog {
    static let availableSources: [RemoteDictionaryPackSource] = [
        RemoteDictionaryPackSource(
            id: "nv-en-navajo-translation-project",
            displayName: "Navajo (Diné)",
            languageCode: "nv",
            summary: "~12,800 entries from the open-source Navajo Translation Project.",
            gitLabProjectPath: "HullBreach/navajokit",
            // Left unset deliberately: gitlab.com is unreachable from the
            // environment this catalog was authored in, so the exact path
            // to the dictionary data file inside this repo (and whether
            // NavajoKit — a Swift package built for in-app translation —
            // already publishes it in DictionaryPackContents' JSON shape,
            // or needs a conversion step first) couldn't be confirmed.
            // Once confirmed, set this to that path, e.g.
            // "Sources/NavajoKit/Resources/dictionary.json", and
            // downloadURL will start resolving.
            filePath: nil,
            ref: "main",
            sourceDescription: "Navajo Translation Project (NavajoKit)",
            license: "See gitlab.com/HullBreach/navajokit for license terms"
        )

        // Future dual-language packs go here, e.g.:
        // RemoteDictionaryPackSource(
        //     id: "ta-gu-...",
        //     displayName: "Tamil–Gujarati",
        //     languageCode: "ta",
        //     summary: "...",
        //     gitLabProjectPath: "...",
        //     filePath: "...",
        //     ref: "main",
        //     sourceDescription: "...",
        //     license: "..."
        // ),
    ]
}
