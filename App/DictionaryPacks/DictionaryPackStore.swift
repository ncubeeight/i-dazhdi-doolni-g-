import Foundation

/// Persists the list of installed dictionary packs' manifests — a JSON
/// index file in the app's own container, the same pattern
/// ImportedTextSampleStore/ImportedImageSampleStore use. Each pack's full
/// contents (manifest + entries) live alongside it as `<id>.json`, written
/// by DictionaryPackImporter and read by DictionaryLookupService.
enum DictionaryPackStore {
    private static let indexFileName = "dictionaryPacks.json"

    private static func indexURL() throws -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(indexFileName)
    }

    static func packsDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("DictionaryPacks", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// File a given pack's full contents (manifest + entries) are copied to on import.
    static func contentsURL(forPackID id: String) throws -> URL {
        try packsDirectory().appendingPathComponent("\(id).json")
    }

    static func load() -> [DictionaryPackManifest] {
        guard
            let url = try? indexURL(),
            let data = try? Data(contentsOf: url),
            let manifests = try? JSONDecoder().decode([DictionaryPackManifest].self, from: data)
        else { return [] }
        return manifests
    }

    static func save(_ manifests: [DictionaryPackManifest]) {
        guard let url = try? indexURL(), let data = try? JSONEncoder().encode(manifests) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func remove(_ manifest: DictionaryPackManifest) {
        var manifests = load()
        manifests.removeAll { $0.id == manifest.id }
        save(manifests)
        if let url = try? contentsURL(forPackID: manifest.id) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
