import Foundation

struct SubtitlePipelineStats: Equatable, Sendable {
    var receivedFrameCount: Int
    var bufferedAudioDuration: TimeInterval
    var lastFrameDuration: TimeInterval
    var lastUpdated: Date?

    static let idle = SubtitlePipelineStats(
        receivedFrameCount: 0,
        bufferedAudioDuration: 0,
        lastFrameDuration: 0,
        lastUpdated: nil
    )
}
