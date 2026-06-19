import XCTest
@testable import Glossa

@MainActor
final class SubtitlePipelineTests: XCTestCase {
    func testEmitsSpeechChunkAfterThreeSeconds() {
        let pipeline = SubtitlePipeline()
        var chunks: [AudioChunk] = []
        pipeline.setChunkHandler { chunks.append($0) }

        for second in 0..<3 {
            let frame = AudioFrame(
                samples: Array(repeating: 0.1, count: 16_000),
                sampleRate: 16_000,
                channelCount: 1,
                capturedAt: Date(timeIntervalSince1970: TimeInterval(second + 1))
            )
            _ = pipeline.receive(frame: frame)
        }

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].duration, 3, accuracy: 0.001)
        XCTAssertEqual(chunks[0].sampleRate, 16_000)
    }

    func testDoesNotBufferSilence() {
        let pipeline = SubtitlePipeline()
        var chunks: [AudioChunk] = []
        pipeline.setChunkHandler { chunks.append($0) }

        for second in 0..<4 {
            let frame = AudioFrame(
                samples: Array(repeating: 0, count: 16_000),
                sampleRate: 16_000,
                channelCount: 1,
                capturedAt: Date(timeIntervalSince1970: TimeInterval(second + 1))
            )
            _ = pipeline.receive(frame: frame)
        }

        XCTAssertTrue(chunks.isEmpty)
        XCTAssertEqual(pipeline.bufferedAudioDuration, 0)
    }
}
