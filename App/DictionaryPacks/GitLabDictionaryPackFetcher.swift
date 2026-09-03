import Foundation

enum GitLabFetchError: LocalizedError {
    case sourceNotYetAvailable
    case network(underlying: Error)
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .sourceNotYetAvailable:
            return "This dictionary isn't available to download yet."
        case .network(let underlying):
            return "Couldn't reach GitLab: \(underlying.localizedDescription)"
        case .httpStatus(let code):
            return "GitLab returned an unexpected response (HTTP \(code))."
        }
    }
}

/// Downloads one dictionary pack's JSON file from GitLab and hands the
/// bytes to DictionaryPackImporter — the only network call in the
/// dictionary-pack path, made once, only when a user explicitly taps
/// Download on a catalog entry. Nothing the user looks up is ever sent
/// anywhere: this fetches a public, static file and nothing else, and
/// every lookup afterward runs from the on-device copy DictionaryPackImporter
/// wrote, same as a locally-imported pack.
enum GitLabDictionaryPackFetcher {
    static func download(_ source: RemoteDictionaryPackSource) async throws -> DictionaryPackManifest {
        guard let url = source.downloadURL else {
            throw GitLabFetchError.sourceNotYetAvailable
        }

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

        return try DictionaryPackImporter.importPack(from: data)
    }
}
