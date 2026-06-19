import Foundation

struct SubtitlePipelineStats: Equatable, Sendable {
    var receivedFrameCount: Int
    var emittedChunkCount: Int
    var bufferedAudioDuration: TimeInterval
    var lastFrameDuration: TimeInterval
    var lastFrameLevel: Double
    var isSpeechActive: Bool
    var lastUpdated: Date?

    static let idle = SubtitlePipelineStats(
        receivedFrameCount: 0,
        emittedChunkCount: 0,
        bufferedAudioDuration: 0,
        lastFrameDuration: 0,
        lastFrameLevel: 0,
        isSpeechActive: false,
        lastUpdated: nil
    )
}
