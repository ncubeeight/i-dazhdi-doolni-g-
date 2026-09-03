import SwiftUI
import UniformTypeIdentifiers

/// Reached from Settings → "Fetch dictionary". Two ways to get a pack onto
/// the device — importing a file already on it, or downloading one of the
/// catalog entries from GitLab — kept on a separate screen from
/// LLMConnectionSettingsView on purpose, since the two have very different
/// privacy profiles: this path stays fully offline after (at most) one
/// upfront file fetch, the other requires an ongoing connection to a cloud
/// provider.
struct DictionaryPackSettingsView: View {
    @State private var installedPacks: [DictionaryPackManifest] = DictionaryPackStore.load()
    @State private var isPresentingImporter = false
    @State private var downloadingSourceIDs: Set<String> = []
    @State private var errorMessage: String?

    /// Catalog entries not already installed — once downloaded, a source
    /// moves from "Available to download" to "Installed" instead of
    /// appearing in both.
    private var availableSources: [RemoteDictionaryPackSource] {
        let installedIDs = Set(installedPacks.map(\.id))
        return DictionaryPackCatalog.availableSources.filter { !installedIDs.contains($0.id) }
    }

    var body: some View {
        Form {
            Section {
                Button {
                    isPresentingImporter = true
                } label: {
                    Label("Connect on-device dictionary", systemImage: "book.closed")
                }
            } footer: {
                Text("Import a dictionary pack file already on this device. Lookups run entirely offline — no network connection is made and no context is sent anywhere.")
            }

            if !availableSources.isEmpty {
                Section {
                    ForEach(availableSources) { source in
                        availableSourceRow(source)
                    }
                } header: {
                    Text("Available to download")
                } footer: {
                    Text("Nothing downloads automatically. Downloading fetches that dictionary once from GitLab over the network and stores it on this device — every lookup afterward runs fully offline, the same as an imported pack. If you're not specifically curious about one of these, there's no need to download it.")
                }
            }

            if !installedPacks.isEmpty {
                Section {
                    ForEach(installedPacks) { pack in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.displayName)
                            Text("\(pack.entryCount) entries · v\(pack.version) · \(pack.sourceDescription)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: removePacks)
                } header: {
                    Text("Installed")
                }
            }
        }
        .navigationTitle("Fetch Dictionary")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isPresentingImporter, allowedContentTypes: [.json]) { result in
            handleImportResult(result)
        }
        .alert("Couldn't add dictionary", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    @ViewBuilder
    private func availableSourceRow(_ source: RemoteDictionaryPackSource) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.displayName)
                Text(source.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if downloadingSourceIDs.contains(source.id) {
                ProgressView()
                    .controlSize(.small)
            } else if source.filePaths.isEmpty {
                Text("Not yet available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button("Download") {
                    Task { await download(source) }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let manifest = try DictionaryPackImporter.importPack(from: url)
                installedPacks = DictionaryPackStore.load()
                DictionaryLookupService.shared.invalidateCache(forLanguageCode: manifest.languageCode)
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func download(_ source: RemoteDictionaryPackSource) async {
        downloadingSourceIDs.insert(source.id)
        defer { downloadingSourceIDs.remove(source.id) }

        do {
            let manifest = try await GitLabDictionaryPackFetcher.download(source)
            installedPacks = DictionaryPackStore.load()
            DictionaryLookupService.shared.invalidateCache(forLanguageCode: manifest.languageCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removePacks(at offsets: IndexSet) {
        for index in offsets {
            let pack = installedPacks[index]
            DictionaryPackStore.remove(pack)
            DictionaryLookupService.shared.invalidateCache(forLanguageCode: pack.languageCode)
        }
        installedPacks = DictionaryPackStore.load()
    }
}

#Preview {
    NavigationStack {
        DictionaryPackSettingsView()
    }
}
