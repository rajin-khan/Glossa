import Foundation

enum LocalModelDirectory {
    static func url() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport
            .appendingPathComponent("Glossa", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func cachedModelFolder(modelName: String) -> URL? {
        guard let base = try? url() else { return nil }
        let folder = base
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("whisperkit-coreml", isDirectory: true)
            .appendingPathComponent("openai_whisper-\(modelName)", isDirectory: true)
        return FileManager.default.fileExists(atPath: folder.path) ? folder : nil
    }
}
