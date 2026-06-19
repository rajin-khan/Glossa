import Foundation
import WhisperKit

@main
struct GlossaModelPrep {
    static func main() async throws {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let downloadBase = applicationSupport
            .appendingPathComponent("Glossa", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        try FileManager.default.createDirectory(at: downloadBase, withIntermediateDirectories: true)

        print("Preparing Glossa's local multilingual tiny model...")
        let modelFolder = try await WhisperKit.download(
            variant: "tiny",
            downloadBase: downloadBase
        ) { progress in
            let percent = Int(progress.fractionCompleted * 100)
            print("Download: \(percent)%")
        }

        print("Loading and prewarming Core ML model...")
        let config = WhisperKitConfig(
            model: "tiny",
            modelFolder: modelFolder.path,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: false
        )
        let whisperKit = try await WhisperKit(config)
        print("Glossa local model is ready at \(modelFolder.path)")

        if CommandLine.arguments.count > 1 {
            let audioPath = CommandLine.arguments[1]
            print("Transcribing smoke-test audio at \(audioPath)...")
            let audio = try AudioProcessor.loadAudioAsFloatArray(fromPath: audioPath)
            let options = DecodingOptions(
                verbose: false,
                task: .transcribe,
                language: nil,
                usePrefillPrompt: false,
                detectLanguage: true,
                skipSpecialTokens: true,
                withoutTimestamps: true
            )
            let results = await whisperKit.transcribe(audioArrays: [audio], decodeOptions: options)
            guard let result = results.first.flatMap({ $0 })?.first else {
                throw SmokeTestError.noTranscription
            }
            print("Detected language: \(result.language)")
            print("Transcript: \(result.text.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }
}

private enum SmokeTestError: LocalizedError {
    case noTranscription

    var errorDescription: String? {
        "WhisperKit returned no transcription for the smoke-test audio."
    }
}
