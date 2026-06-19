import Foundation

@MainActor
final class SubtitlePipeline {
    private(set) var bufferedAudioDuration: TimeInterval = 0
    private(set) var receivedFrameCount = 0

    func receive(frame: AudioFrame) {
        receivedFrameCount += 1
        bufferedAudioDuration += frame.duration

        if bufferedAudioDuration > 30 {
            bufferedAudioDuration = 0
        }
    }

    func reset() {
        bufferedAudioDuration = 0
        receivedFrameCount = 0
    }
}
