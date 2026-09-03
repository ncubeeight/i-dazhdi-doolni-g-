import Foundation

/// A single term in an on-device dictionary pack.
struct DictionaryEntry: Codable, Equatable {
    var term: String
    var gloss: String
    var partOfSpeech: String?
    var exampleSentence: String?
}
