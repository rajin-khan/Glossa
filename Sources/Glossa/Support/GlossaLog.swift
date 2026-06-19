import OSLog

enum GlossaLog {
    private static let subsystem = "com.rajin.glossa"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let capture = Logger(subsystem: subsystem, category: "Capture")
    static let transcription = Logger(subsystem: subsystem, category: "Transcription")
    static let translation = Logger(subsystem: subsystem, category: "Translation")
}
