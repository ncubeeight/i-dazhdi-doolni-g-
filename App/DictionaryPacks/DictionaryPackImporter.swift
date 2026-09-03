import Foundation

enum DictionaryPackImportError: LocalizedError {
    case couldNotAccessSecurityScopedResource
    case invalidFormat(String)
    case alreadyInstalled(String)
    case couldNotWriteFile(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .couldNotAccessSecurityScopedResource:
            return "iOS didn't grant access to that file. Try picking it again."
        case .invalidFormat(let reason):
            return "That doesn't look like a dictionary pack: \(reason)."
        case .alreadyInstalled(let name):
            return "\(name) is already installed."
        case .couldNotWriteFile(let underlying):
            return "Couldn't save that dictionary pack: \(underlying.localizedDescription)"
        }
    }
}

/// Validates dictionary-pack bytes and installs them: copies the full
/// contents into the app's own container and registers the manifest in
/// DictionaryPackStore. Import is the only place pack files get parsed —
/// DictionaryLookupService trusts the copy it made here and never
/// re-validates it.
///
/// Two things can hand this bytes: a file the user picked (already on
/// their device — their own download, AirDrop, or a pack they built) or
/// GitLabDictionaryPackFetcher's one-time download of a catalog entry.
/// Either way, `importPack(from: Data)` is the single point where bytes
/// become an installed pack — no network call happens in this type itself.
enum DictionaryPackImporter {

    static func importPack(from sourceURL: URL) throws -> DictionaryPackManifest {
        // Files handed to us via .fileImporter are "security-scoped" — we must
        // bracket access, and the URL becomes unusable once we stop accessing it.
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() } }

        guard didStartAccessing || FileManager.default.isReadableFile(atPath: sourceURL.path) else {
            throw DictionaryPackImportError.couldNotAccessSecurityScopedResource
        }

        guard let data = try? Data(contentsOf: sourceURL) else {
            throw DictionaryPackImportError.couldNotAccessSecurityScopedResource
        }

        return try importPack(from: data)
    }

    static func importPack(from data: Data) throws -> DictionaryPackManifest {
        let contents: DictionaryPackContents
        do {
            contents = try JSONDecoder().decode(DictionaryPackContents.self, from: data)
        } catch {
            throw DictionaryPackImportError.invalidFormat(error.localizedDescription)
        }

        guard !contents.manifest.id.isEmpty, !contents.entries.isEmpty else {
            throw DictionaryPackImportError.invalidFormat("it's missing an id or has no entries")
        }

        var installed = DictionaryPackStore.load()
        if installed.contains(where: { $0.id == contents.manifest.id }) {
            throw DictionaryPackImportError.alreadyInstalled(contents.manifest.displayName)
        }

        do {
            let destination = try DictionaryPackStore.contentsURL(forPackID: contents.manifest.id)
            try data.write(to: destination, options: .atomic)
        } catch {
            throw DictionaryPackImportError.couldNotWriteFile(underlying: error)
        }

        installed.append(contents.manifest)
        DictionaryPackStore.save(installed)

        return contents.manifest
    }
}
