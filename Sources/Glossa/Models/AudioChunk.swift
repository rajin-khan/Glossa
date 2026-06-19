import Foundation

struct AudioChunk: Sendable {
    var samples: [Float]
    var sampleRate: Double
    var channelCount: Int
    var averageLevel: Double
    var startedAt: Date
    var endedAt: Date

    var duration: TimeInterval {
        guard sampleRate > 0, channelCount > 0 else { return 0 }
        return Double(samples.count) / sampleRate / Double(channelCount)
    }
}
