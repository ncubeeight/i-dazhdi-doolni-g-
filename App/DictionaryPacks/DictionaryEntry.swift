import Foundation

/// A single term in an on-device dictionary pack.
struct DictionaryEntry: Codable, Equatable {
    var term: String
    var gloss: String
    var partOfSpeech: String?
    /// Example sentence in the term's own language.
    var exampleSentence: String?
    /// English translation of `exampleSentence`. Only meaningful alongside
    /// it — a pack that sets one should set both.
    var exampleSentenceTranslation: String?
}
