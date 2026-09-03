import Foundation

enum NavajoKitParseError: LocalizedError {
    case missingRequiredColumns

    var errorDescription: String? {
        switch self {
        case .missingRequiredColumns:
            return "This CSV doesn't have the columns NavajoKit's training data is expected to have (TOKENS, LABELS, english)."
        }
    }
}

/// Parses NavajoKit's training_data CSV format into DictionaryEntry values.
/// Confirmed directly against gitlab.com/HullBreach/navajokit (2026-09-03),
/// via a one-time GitHub mirror used only to read the real files — this
/// parser itself talks to neither; GitLabDictionaryPackFetcher fetches
/// straight from GitLab at runtime.
///
/// Two files share this schema (column order differs slightly between
/// them, so columns are located by header name, not position):
///
/// - `NVSingleWords.csv` header: TOKENS,LABELS,english,validated,proper,
///   subject-person,subject-plural,object-person,object-plural,infinitive,
///   aspect,v0..v9 (Navajo verb position-class slots),stem,suffix,notes
/// - `NVCompoundWords.csv` header: TOKENS,LABELS,english,part-of-speech,
///   subject-person,subject-plural,object-person,object-plural,infinitive,
///   proper,prefix,stem,suffix,notes,Match?,Count
///
/// Only TOKENS/LABELS/english are used here. NavajoKit's own NVWord models
/// far richer morphology (aspect, subject/object inflection, the v0–v9
/// position-class slots, stem/suffix) — real data this parser deliberately
/// leaves on the table, since this app's DictionaryEntry only needs a
/// term/gloss/part-of-speech for tap-to-define. A fuller morphological
/// breakdown is a possible future enhancement, not attempted here.
///
/// Licensed CC BY-SA 4.0 by the Navajo Translation Project — any pack built
/// from this data carries that same attribution/ShareAlike obligation;
/// see DictionaryPackManifest.license on the resulting pack.
enum NavajoKitTrainingDataParser {
    static func parseEntries(fromCSV csv: String) throws -> [DictionaryEntry] {
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard let headerLine = lines.first else { return [] }

        let headers = splitCSVRow(headerLine)
        guard
            let tokensIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("TOKENS") == .orderedSame }),
            let englishIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("english") == .orderedSame })
        else {
            throw NavajoKitParseError.missingRequiredColumns
        }
        let labelsIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("LABELS") == .orderedSame })

        var entries: [DictionaryEntry] = []
        for line in lines.dropFirst() {
            let fields = splitCSVRow(line)
            guard tokensIndex < fields.count, englishIndex < fields.count else { continue }

            let term = fields[tokensIndex].trimmingCharacters(in: .whitespaces)
            let gloss = fields[englishIndex].trimmingCharacters(in: .whitespaces)
            guard !term.isEmpty, !gloss.isEmpty else { continue }

            let partOfSpeech = labelsIndex.flatMap { index -> String? in
                guard index < fields.count else { return nil }
                let value = fields[index].trimmingCharacters(in: .whitespaces)
                return value.isEmpty ? nil : value
            }

            entries.append(DictionaryEntry(term: term, gloss: gloss, partOfSpeech: partOfSpeech, exampleSentence: nil))
        }
        return entries
    }

    /// Quote-aware comma split — a field wrapped in "..." may itself contain
    /// commas (NavajoKit's compound-word TOKENS field does exactly this, to
    /// represent morpheme breaks, e.g. `"á,dahojiiłʼaah"`) or escaped ("")
    /// quotes. Same RFC 4180 shape NavajoKit's own
    /// NVDataFormatter.splitRecord(fromCsv:) handles — reimplemented here
    /// rather than depending on the NavajoKit package for one function.
    private static func splitCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var isInsideQuotes = false

        let chars = Array(row)
        var index = 0
        while index < chars.count {
            let char = chars[index]
            switch char {
            case "\"":
                if isInsideQuotes {
                    if index + 1 < chars.count, chars[index + 1] == "\"" {
                        current.append("\"")
                        index += 1
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    isInsideQuotes = true
                }
            case ",":
                if isInsideQuotes {
                    current.append(char)
                } else {
                    fields.append(current)
                    current = ""
                }
            default:
                current.append(char)
            }
            index += 1
        }
        fields.append(current)
        return fields
    }
}
