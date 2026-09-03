import Foundation

/// A dictionary pack the app knows how to fetch from GitLab, listed under
/// Settings → Fetch dictionary → "Available to download". Distinct from an
/// installed DictionaryPackManifest: this describes where to get a pack,
/// not a pack that's already on the device.
struct RemoteDictionaryPackSource: Identifiable {
    /// Matches the `id` the resulting DictionaryPackManifest will have once
    /// downloaded, so DictionaryPackSettingsView can tell whether this
    /// source is already installed.
    var id: String

    var displayName: String
    var languageCode: String
    var summary: String

    /// GitLab namespace/project, e.g. "HullBreach/navajokit".
    var gitLabProjectPath: String

    /// Path to the pack's JSON file ({manifest, entries}, see
    /// DictionaryPackContents) within that repository. `nil` means this
    /// source is listed but not yet downloadable — its exact file path
    /// hasn't been confirmed against the upstream repo yet.
    var filePath: String?

    /// Branch or tag to fetch from.
    var ref: String

    var sourceDescription: String
    var license: String

    /// GitLab's repository-files API, which serves a single file's raw
    /// content by project + path + ref — the documented, stable way to
    /// fetch one file from a public GitLab project without cloning it.
    /// `nil` whenever `filePath` hasn't been set yet.
    var downloadURL: URL? {
        guard let filePath else { return nil }
        let project = Self.gitLabIDEncode(gitLabProjectPath)
        let file = Self.gitLabIDEncode(filePath)
        var components = URLComponents(string: "https://gitlab.com/api/v4/projects/\(project)/repository/files/\(file)/raw")
        components?.queryItems = [URLQueryItem(name: "ref", value: ref)]
        return components?.url
    }

    /// GitLab's API requires the project path and file path to each be a
    /// single percent-encoded path segment (a literal "/" inside either one
    /// must become %2F) — everything outside RFC 3986's "unreserved" set
    /// gets encoded, matching GitLab's own documented example.
    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    private static func gitLabIDEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? value
    }
}
