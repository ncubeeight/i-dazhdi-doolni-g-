import Foundation

/// Looks up terms in installed on-device dictionary packs — no LLM, no
/// network. This is the offline counterpart to WordGlossGenerator's
/// on-device-LLM gloss: for a language with an installed pack, this answers
/// instantly from a static dictionary instead of prompting the Foundation
/// Model, and works on devices/regions where that model is unavailable or
/// restricted.
///
/// Entries are loaded into memory per language and cached — fine at the
/// ~12,800-entry scale of the Navajo Translation Project pack this was
/// built for. If pack sizes grow much larger, swap the in-memory
/// dictionary below for an indexed on-disk store (e.g. SQLite) without
/// changing this type's interface.
final class DictionaryLookupService {
    static let shared = DictionaryLookupService()

    private var entriesByLanguage: [String: [String: DictionaryEntry]] = [:]

    private init() {}

    func isPackInstalled(forLanguageCode languageCode: String) -> Bool {
        DictionaryPackStore.load().contains { $0.languageCode == languageCode }
    }

    func lookup(term: String, languageCode: String) -> DictionaryEntry? {
        loadedTable(forLanguageCode: languageCode)[term.lowercased()]
    }

    /// Drops the in-memory cache for a language, e.g. after installing,
    /// removing, or re-importing a pack for it.
    func invalidateCache(forLanguageCode languageCode: String) {
        entriesByLanguage.removeValue(forKey: languageCode)
    }

    private func loadedTable(forLanguageCode languageCode: String) -> [String: DictionaryEntry] {
        if let cached = entriesByLanguage[languageCode] {
            return cached
        }
        guard let manifest = DictionaryPackStore.load().first(where: { $0.languageCode == languageCode }) else {
            return [:]
        }
        guard
            let url = try? DictionaryPackStore.contentsURL(forPackID: manifest.id),
            let data = try? Data(contentsOf: url),
            let contents = try? JSONDecoder().decode(DictionaryPackContents.self, from: data)
        else {
            return [:]
        }

        var table: [String: DictionaryEntry] = [:]
        for entry in contents.entries {
            table[entry.term.lowercased()] = entry
        }
        entriesByLanguage[languageCode] = table
        return table
    }
}
