import Foundation

/// How a RemoteDictionaryPackSource's file(s) are shaped, and therefore how
/// GitLabDictionaryPackFetcher needs to turn them into a DictionaryPackContents.
enum RemoteDictionaryPackFormat {
    /// The file already is one JSON document matching DictionaryPackContents
    /// — fetched as-is and handed straight to DictionaryPackImporter.
    case dictionaryPackJSON

    /// One or more CSVs following NavajoKit's training_data schema (see
    /// NavajoKitTrainingDataParser) — fetched and parsed into entries, then
    /// wrapped in a manifest this app constructs itself, since the upstream
    /// CSVs carry no manifest of their own.
    case navajoKitTrainingCSV
}

/// A dictionary pack the app knows how to fetch from GitLab, listed under
/// Settings → Fetch dictionary → "Available to download". Distinct from an
/// installed DictionaryPackManifest: this describes where to get a pack,
/// not a pack that's already on the device.
struct RemoteDictionaryPackSource: Identifiable {
    /// Matches the `id` the resulting DictionaryPackManifest will have once
    /// downloaded, so DictionaryPackSettingsView can tell whether this
    /// source is already installed.
    var id: String

    var displayName: String
    var languageCode: String
    var summary: String

    /// GitLab namespace/project, e.g. "HullBreach/navajokit".
    var gitLabProjectPath: String

    /// Paths (within that repository) to the file(s) backing this pack.
    /// Empty means this source is listed but not yet downloadable — its
    /// file path(s) haven't been confirmed against the upstream repo yet.
    /// For `.dictionaryPackJSON` this holds exactly one path. For
    /// `.navajoKitTrainingCSV` it can hold several same-schema CSVs
    /// (e.g. single words + compound words), concatenated into one pack.
    var filePaths: [String]

    var format: RemoteDictionaryPackFormat

    /// Optional additional CSVs (same `.navajoKitTrainingCSV` schema, but
    /// clause-level: see NavajoKitSentenceParser) to cross-reference against
    /// the entries from `filePaths` and fill in `DictionaryEntry.exampleSentence`
    /// / `exampleSentenceTranslation` wherever a term appears in one of
    /// their sentences. Empty means no enrichment — the resulting entries
    /// just won't have example sentences. Ignored for `.dictionaryPackJSON`.
    var exampleSentenceFilePaths: [String] = []

    /// Branch or tag to fetch from.
    var ref: String

    /// Version string for the resulting DictionaryPackManifest. For
    /// `.navajoKitTrainingCSV` there's no upstream version to read (the
    /// CSVs don't carry one), so this is just `ref` by convention —
    /// "whatever this branch currently has."
    var version: String

    var sourceDescription: String
    var license: String

    /// GitLab's repository-files API, which serves a single file's raw
    /// content by project + path + ref — the documented, stable way to
    /// fetch one file from a public GitLab project without cloning it.
    func downloadURL(forPath path: String) -> URL? {
        let project = Self.gitLabIDEncode(gitLabProjectPath)
        let file = Self.gitLabIDEncode(path)
        var components = URLComponents(string: "https://gitlab.com/api/v4/projects/\(project)/repository/files/\(file)/raw")
        components?.queryItems = [URLQueryItem(name: "ref", value: ref)]
        return components?.url
    }

    /// GitLab's API requires the project path and file path to each be a
    /// single percent-encoded path segment (a literal "/" inside either one
    /// must become %2F) — everything outside RFC 3986's "unreserved" set
    /// gets encoded, matching GitLab's own documented example.
    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    private static func gitLabIDEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? value
    }
}
