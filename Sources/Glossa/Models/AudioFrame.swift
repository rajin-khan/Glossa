import Foundation

struct AudioFrame: Sendable {
    var samples: [Float]
    var sampleRate: Double
    var channelCount: Int
    var capturedAt: Date

    var duration: TimeInterval {
        guard sampleRate > 0, channelCount > 0 else { return 0 }
        return Double(samples.count) / sampleRate / Double(channelCount)
    }
}
