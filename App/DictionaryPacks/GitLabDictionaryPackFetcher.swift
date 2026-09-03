import Foundation

enum GitLabFetchError: LocalizedError {
    case sourceNotYetAvailable
    case network(underlying: Error)
    case httpStatus(Int)
    case invalidTextEncoding

    var errorDescription: String? {
        switch self {
        case .sourceNotYetAvailable:
            return "This dictionary isn't available to download yet."
        case .network(let underlying):
            return "Couldn't reach GitLab: \(underlying.localizedDescription)"
        case .httpStatus(let code):
            return "GitLab returned an unexpected response (HTTP \(code))."
        case .invalidTextEncoding:
            return "GitLab returned data that couldn't be read as text."
        }
    }
}

/// Downloads one dictionary pack's file(s) from GitLab and turns them into
/// an installed pack — the only network calls in the dictionary-pack path,
/// made once, only when a user explicitly taps Download on a catalog
/// entry. Nothing the user looks up is ever sent anywhere: this fetches
/// public, static files and nothing else, and every lookup afterward runs
/// from the on-device copy DictionaryPackImporter wrote, same as a
/// locally-imported pack.
enum GitLabDictionaryPackFetcher {
    static func download(_ source: RemoteDictionaryPackSource) async throws -> DictionaryPackManifest {
        guard !source.filePaths.isEmpty else {
            throw GitLabFetchError.sourceNotYetAvailable
        }

        switch source.format {
        case .dictionaryPackJSON:
            guard source.filePaths.count == 1, let url = source.downloadURL(forPath: source.filePaths[0]) else {
                throw GitLabFetchError.sourceNotYetAvailable
            }
            let data = try await fetchData(from: url)
            return try DictionaryPackImporter.importPack(from: data)

        case .navajoKitTrainingCSV:
            var entries: [DictionaryEntry] = []
            for path in source.filePaths {
                guard let url = source.downloadURL(forPath: path) else {
                    throw GitLabFetchError.sourceNotYetAvailable
                }
                let data = try await fetchData(from: url)
                guard let csv = String(data: data, encoding: .utf8) else {
                    throw GitLabFetchError.invalidTextEncoding
                }
                entries.append(contentsOf: try NavajoKitTrainingDataParser.parseEntries(fromCSV: csv))
            }

            let manifest = DictionaryPackManifest(
                id: source.id,
                languageCode: source.languageCode,
                displayName: source.displayName,
                version: source.version,
                entryCount: entries.count,
                sourceDescription: source.sourceDescription,
                license: source.license,
                checksumSHA256: nil
            )
            let contents = DictionaryPackContents(manifest: manifest, entries: entries)
            let contentsData = try JSONEncoder().encode(contents)
            return try DictionaryPackImporter.importPack(from: contentsData)
        }
    }

    private static func fetchData(from url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw GitLabFetchError.network(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw GitLabFetchError.httpStatus(http.statusCode)
        }

        return data
    }
}
