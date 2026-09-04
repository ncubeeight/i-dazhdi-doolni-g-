import Foundation

/// Parses NavajoKit's clause-level training data (`NVClauses.csv`) into
/// short example sentences usable for `DictionaryEntry.exampleSentence`.
///
/// Confirmed header (2026-09-03, read directly from the real file):
/// `TOKENS,LABELS,English,Match?,Count`. Unlike the word-list CSVs
/// (NavajoKitTrainingDataParser), here TOKENS and LABELS are themselves
/// comma-joined lists — one sub-field per word or punctuation mark in the
/// sentence — and English is the whole clause's translation, not a single
/// word's gloss.
///
/// `NVPassages.csv` shares the TOKENS/LABELS shape but its third column is
/// "Source" (a citation, not a translation) and each row is a full
/// multi-sentence passage (thousands of characters) rather than one short
/// clause — too long to show as a single word's example sentence, and with
/// no English text to pair it with, so it's deliberately not parsed here.
enum NavajoKitSentenceParser {
    struct Sentence {
        let navajo: String
        let english: String
        let tokens: [String]
    }

    static func parseSentences(fromCSV csv: String) -> [Sentence] {
        let lines = NavajoKitTrainingDataParser.splitLines(csv)
        guard let headerLine = lines.first else { return [] }

        let headers = NavajoKitTrainingDataParser.splitCSVRow(headerLine)
        guard
            let tokensIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("TOKENS") == .orderedSame }),
            let labelsIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("LABELS") == .orderedSame }),
            let englishIndex = headers.firstIndex(where: { $0.caseInsensitiveCompare("english") == .orderedSame })
        else {
            return []
        }

        var sentences: [Sentence] = []
        for line in lines.dropFirst() {
            let fields = NavajoKitTrainingDataParser.splitCSVRow(line)
            guard tokensIndex < fields.count, labelsIndex < fields.count, englishIndex < fields.count else { continue }

            let tokens = NavajoKitTrainingDataParser.splitCSVRow(fields[tokensIndex]).map { $0.trimmingCharacters(in: .whitespaces) }
            let labels = NavajoKitTrainingDataParser.splitCSVRow(fields[labelsIndex]).map { $0.trimmingCharacters(in: .whitespaces) }
            let english = fields[englishIndex].trimmingCharacters(in: .whitespaces)

            // A handful of source rows use an inconsistent embedded-comma
            // escape (a literal comma written as an adjacent `"",""` pair)
            // that throws off this row's token/label count. Skip rather
            // than risk reconstructing a garbled example sentence from one
            // of those — the well-formed majority is plenty to draw from.
            guard !tokens.isEmpty, tokens.count == labels.count, !english.isEmpty else { continue }

            var navajo = ""
            for (token, label) in zip(tokens, labels) {
                guard !token.isEmpty else { continue }
                if label.caseInsensitiveCompare("Punct") == .orderedSame {
                    navajo += token
                } else {
                    navajo += navajo.isEmpty ? token : " \(token)"
                }
            }
            guard !navajo.isEmpty else { continue }

            sentences.append(Sentence(navajo: navajo, english: english, tokens: tokens))
        }
        return sentences
    }
}
