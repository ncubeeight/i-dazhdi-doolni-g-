import SwiftUI

/// Small persisted app preferences, backed by UserDefaults via @AppStorage
/// in the views that read/write them. Centralizing the keys and the
/// encode/decode helpers here keeps every call site in sync.
enum AppSettings {
    static let enabledLanguagesKey = "enabledLanguagesRawValues"
    static let colorSchemeKey = "preferredColorSchemeRawValue"
    static let enabledMCPProvidersKey = "enabledMCPProviderRawValues"

    /// Decodes the comma-joined raw value @AppStorage stores. An empty or
    /// unparseable value means "everything enabled" — the default before
    /// the user has ever visited Settings.
    static func languages(from rawValue: String) -> Set<SupportedLanguage> {
        guard !rawValue.isEmpty else { return Set(SupportedLanguage.allCases) }
        let set = Set(rawValue.split(separator: ",").compactMap { SupportedLanguage(rawValue: String($0)) })
        return set.isEmpty ? Set(SupportedLanguage.allCases) : set
    }

    static func rawValue(from languages: Set<SupportedLanguage>) -> String {
        languages.map(\.rawValue).joined(separator: ",")
    }

    /// Unlike languages(from:), an empty/unparseable value here means "none
    /// connected" — connecting a cloud LLM provider must always be an
    /// explicit opt-in, never a default.
    static func mcpProviders(from rawValue: String) -> Set<MCPProvider> {
        Set(rawValue.split(separator: ",").compactMap { MCPProvider(rawValue: String($0)) })
    }

    static func rawValue(from providers: Set<MCPProvider>) -> String {
        providers.map(\.rawValue).joined(separator: ",")
    }
}

enum AppColorScheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
