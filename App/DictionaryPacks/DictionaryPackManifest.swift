import Foundation

/// Describes an importable, on-device dictionary pack. This is the metadata
/// a user (or, eventually, a pack picker/updater) needs before and after
/// installing one — deliberately shaped like a browser-extension language
/// pack manifest (id, language, version, entry count, license, source) so
/// the same format extends to future pack types without changing the
/// importer or store.
struct DictionaryPackManifest: Codable, Identifiable, Equatable {
    /// Stable identifier for the pack, e.g. "nv-en-navajo-translation-project".
    var id: String

    /// The language the pack's terms are written in, as a plain BCP-47-ish
    /// code (e.g. "nv" for Navajo/Diné) rather than `SupportedLanguage`.
    /// `SupportedLanguage` is scoped to what Apple's NaturalLanguage /
    /// SpeechAnalyzer frameworks recognize for transcription, which doesn't
    /// include Navajo — dictionary packs need to cover languages outside
    /// that list, so this stays a separate, unconstrained identifier.
    var languageCode: String

    var displayName: String
    var version: String
    var entryCount: Int
    var sourceDescription: String
    var license: String
    var checksumSHA256: String?
}

/// On-disk shape of a pack file: one JSON document containing both the
/// manifest and its entries, so import is a single-file pick rather than a
/// folder/zip with multiple security-scoped resources to juggle.
struct DictionaryPackContents: Codable {
    var manifest: DictionaryPackManifest
    var entries: [DictionaryEntry]
}
