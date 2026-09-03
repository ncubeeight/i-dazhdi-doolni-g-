import SwiftUI
import UniformTypeIdentifiers

/// Reached from Settings → "Fetch dictionary". Its one job is importing an
/// on-device dictionary pack (e.g. Navajo/Diné) — kept on a separate screen
/// from LLMConnectionSettingsView on purpose, since the two have very
/// different privacy profiles: this path is fully offline, the other
/// requires network connectivity to a cloud provider.
struct DictionaryPackSettingsView: View {
    @State private var installedPacks: [DictionaryPackManifest] = DictionaryPackStore.load()
    @State private var isPresentingImporter = false
    @State private var importErrorMessage: String?

    var body: some View {
        Form {
            Section {
                Button {
                    isPresentingImporter = true
                } label: {
                    Label("Connect on-device dictionary", systemImage: "book.closed")
                }
            } footer: {
                Text("Import a dictionary pack file onto this device. Lookups run entirely offline — no network connection is made and no context is sent anywhere.")
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
        .alert("Couldn't import dictionary", isPresented: .constant(importErrorMessage != nil), actions: {
            Button("OK") { importErrorMessage = nil }
        }, message: {
            Text(importErrorMessage ?? "")
        })
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let manifest = try DictionaryPackImporter.importPack(from: url)
                installedPacks = DictionaryPackStore.load()
                DictionaryLookupService.shared.invalidateCache(forLanguageCode: manifest.languageCode)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
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
