import AVFoundation

enum AudioTranscoderError: LocalizedError {
    case exportFailed(String)
    case noAudioTrack

    var errorDescription: String? {
        switch self {
        case .exportFailed(let reason): return "Couldn't prepare the audio: \(reason)"
        case .noAudioTrack: return "That file doesn't seem to contain an audio track."
        }
    }
}

/// AVAudioFile opens Apple's own .m4a natively and reliably. For anything
/// else the user might import (a stray .mp3, or an .mp4 video with spoken
/// audio), we re-export to .m4a first rather than gamble on AVAudioFile
/// reading the original container directly.
enum AudioTranscoder {

    static func ensureM4A(at sourceURL: URL) async throws -> URL {
        if sourceURL.pathExtension.lowercased() == "m4a" {
            return sourceURL
        }

        let asset = AVURLAsset(url: sourceURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw AudioTranscoderError.noAudioTrack
        }

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioTranscoderError.exportFailed("Export session unavailable")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        do {
            try await export.export(to: outputURL, as: .m4a)
        } catch {
            throw AudioTranscoderError.exportFailed(error.localizedDescription)
        }

        return outputURL
    }
}
