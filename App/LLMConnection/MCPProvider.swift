import Foundation

/// A cloud LLM provider a user can connect via MCP from
/// LLMConnectionSettingsView. Kept entirely separate from
/// DictionaryPackManifest/SupportedLanguage — this isn't a language or a
/// dictionary, it's a choice of remote service, with the network
/// dependency and privacy tradeoffs that implies.
enum MCPProvider: String, CaseIterable, Codable, Identifiable {
    case claude
    case gemini
    case chatGPT
    case perplexity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .gemini: "Gemini"
        case .chatGPT: "ChatGPT"
        case .perplexity: "Perplexity"
        }
    }
}
