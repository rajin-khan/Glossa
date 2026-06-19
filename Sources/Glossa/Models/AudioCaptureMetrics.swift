import Foundation

struct AudioCaptureMetrics: Equatable, Sendable {
    var level: Double
    var peak: Double
    var sampleCount: Int
    var bufferCount: Int
    var sampleRate: Double
    var channelCount: Int
    var lastUpdated: Date?

    static let idle = AudioCaptureMetrics(
        level: 0,
        peak: 0,
        sampleCount: 0,
        bufferCount: 0,
        sampleRate: 0,
        channelCount: 0,
        lastUpdated: nil
    )
}
