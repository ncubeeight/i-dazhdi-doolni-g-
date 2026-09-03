import SwiftUI

/// Reached from Settings → "Connect to your LLM". Lets a user opt into
/// cloud LLM providers via MCP.
///
/// Deliberately a separate screen from DictionaryPackSettingsView, and
/// deliberately opt-in (nothing selected by default, unlike the
/// languages-shown-on-import toggles, which default to "all on"): a
/// dictionary pack is a static file that never leaves the device, while
/// enabling a provider here means live network connectivity, that
/// provider's servers seeing whatever context is sent, availability that
/// depends on connectivity and region, and additional power/battery use
/// during a session. None of that should ever be an accidental default.
///
/// Not wired to an actual MCP client yet — this view only persists which
/// provider(s) the user has opted into. Connecting it to a real MCP
/// session per provider is follow-up work.
struct LLMConnectionSettingsView: View {
    @AppStorage(AppSettings.enabledMCPProvidersKey) private var enabledProvidersRaw: String = ""

    private var enabledProviders: Set<MCPProvider> {
        AppSettings.mcpProviders(from: enabledProvidersRaw)
    }

    var body: some View {
        Form {
            Section {
                ForEach(MCPProvider.allCases) { provider in
                    Toggle(provider.displayName, isOn: binding(for: provider))
                }
            } header: {
                Text("Cloud LLM providers (MCP)")
            } footer: {
                Text("Connecting a provider here sends your query to that company's servers over the network. Unlike the on-device dictionary, this requires connectivity, may not be available in every region, and can affect battery life during a session. Nothing is sent until you actively use a connected provider.")
            }
        }
        .navigationTitle("Connect to your LLM")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for provider: MCPProvider) -> Binding<Bool> {
        Binding(
            get: { enabledProviders.contains(provider) },
            set: { isOn in
                var current = enabledProviders
                if isOn {
                    current.insert(provider)
                } else {
                    current.remove(provider)
                }
                enabledProvidersRaw = AppSettings.rawValue(from: current)
            }
        )
    }
}

#Preview {
    NavigationStack {
        LLMConnectionSettingsView()
    }
}
