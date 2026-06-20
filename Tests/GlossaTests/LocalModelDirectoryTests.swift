import XCTest
@testable import Glossa

final class LocalModelDirectoryTests: XCTestCase {
    func testRecognizesOnlyCompleteCachedModels() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlossaModelDirectoryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: base) }

        let modelFolder = base
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("whisperkit-coreml", isDirectory: true)
            .appendingPathComponent("openai_whisper-tiny", isDirectory: true)
        try FileManager.default.createDirectory(at: modelFolder, withIntermediateDirectories: true)

        XCTAssertNil(LocalModelDirectory.cachedModelFolder(modelName: "tiny", baseDirectory: base))

        for directory in ["AudioEncoder.mlmodelc", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"] {
            try FileManager.default.createDirectory(
                at: modelFolder.appendingPathComponent(directory),
                withIntermediateDirectories: true
            )
        }
        for file in ["config.json", "generation_config.json"] {
            try Data("{}".utf8).write(to: modelFolder.appendingPathComponent(file))
        }

        XCTAssertEqual(
            LocalModelDirectory.cachedModelFolder(modelName: "tiny", baseDirectory: base),
            modelFolder
        )
    }
}
