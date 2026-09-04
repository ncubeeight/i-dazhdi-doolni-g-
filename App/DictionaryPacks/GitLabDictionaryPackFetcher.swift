import Foundation

enum GitLabFetchError: LocalizedError {
    case sourceNotYetAvailable
    case network(underlying: Error)
    case httpStatus(Int)
    case invalidTextEncoding
    /// Fetched fine, decoded as text fine, but yielded zero usable rows —
    /// carries enough of what was actually received to diagnose why
    /// (wrong ref, an HTML error/redirect page instead of raw content, a
    /// header this parser doesn't recognize, etc.) without needing to
    /// reproduce the fetch elsewhere.
    case emptyParseResult(path: String, byteCount: Int, snippet: String)

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
        case .emptyParseResult(let path, let byteCount, let snippet):
            return "Fetched \(path) (\(byteCount) bytes) but found zero usable rows. First bytes received: \(snippet)"
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
                let parsed = try NavajoKitTrainingDataParser.parseEntries(fromCSV: csv)
                guard !parsed.isEmpty else {
                    throw GitLabFetchError.emptyParseResult(path: path, byteCount: data.count, snippet: Self.snippet(of: csv))
                }
                entries.append(contentsOf: parsed)
            }

            if !source.exampleSentenceFilePaths.isEmpty {
                var sentences: [NavajoKitSentenceParser.Sentence] = []
                for path in source.exampleSentenceFilePaths {
                    guard let url = source.downloadURL(forPath: path) else {
                        throw GitLabFetchError.sourceNotYetAvailable
                    }
                    let data = try await fetchData(from: url)
                    guard let csv = String(data: data, encoding: .utf8) else {
                        throw GitLabFetchError.invalidTextEncoding
                    }
                    let parsed = NavajoKitSentenceParser.parseSentences(fromCSV: csv)
                    guard !parsed.isEmpty else {
                        throw GitLabFetchError.emptyParseResult(path: path, byteCount: data.count, snippet: Self.snippet(of: csv))
                    }
                    sentences.append(contentsOf: parsed)
                }
                entries = enrichWithExampleSentences(entries, sentences: sentences)
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

    /// Matches each entry's term against the sentences it appears in
    /// (first match wins — one representative example is enough) and fills
    /// in exampleSentence/exampleSentenceTranslation where found. Entries
    /// with no matching sentence are returned unchanged.
    private static func enrichWithExampleSentences(
        _ entries: [DictionaryEntry],
        sentences: [NavajoKitSentenceParser.Sentence]
    ) -> [DictionaryEntry] {
        guard !sentences.isEmpty else { return entries }

        var sentenceIndexByToken: [String: Int] = [:]
        for (index, sentence) in sentences.enumerated() {
            for token in sentence.tokens {
                let key = token.lowercased()
                guard !key.isEmpty, sentenceIndexByToken[key] == nil else { continue }
                sentenceIndexByToken[key] = index
            }
        }

        return entries.map { entry in
            guard let sentenceIndex = sentenceIndexByToken[entry.term.lowercased()] else { return entry }
            var enriched = entry
            enriched.exampleSentence = sentences[sentenceIndex].navajo
            enriched.exampleSentenceTranslation = sentences[sentenceIndex].english
            return enriched
        }
    }

    /// A short, alert-friendly preview of fetched text that couldn't be
    /// parsed — flags a leading byte-order mark explicitly (otherwise
    /// invisible, and a real way this could silently break header
    /// matching) and makes line breaks visible instead of collapsing them.
    private static func snippet(of text: String, maxLength: Int = 200) -> String {
        var result = String(text.prefix(maxLength))
        if result.hasPrefix("\u{FEFF}") {
            result = "[starts with a UTF-8 BOM] " + result.dropFirst()
        }
        result = result.replacingOccurrences(of: "\r\n", with: "⏎")
        result = result.replacingOccurrences(of: "\n", with: "⏎")
        result = result.replacingOccurrences(of: "\r", with: "␍")
        return result
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
