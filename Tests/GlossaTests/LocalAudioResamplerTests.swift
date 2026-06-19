import XCTest
@testable import Glossa

final class LocalAudioResamplerTests: XCTestCase {
    func testDownmixesStereoAndResamplesToSixteenKilohertz() {
        let chunk = AudioChunk(
            samples: [1, -1, 0.5, 0.5, -0.5, -0.5],
            sampleRate: 48_000,
            channelCount: 2,
            averageLevel: 0.5,
            startedAt: .now,
            endedAt: .now
        )

        let samples = LocalAudioResampler.monoSamples(from: chunk, targetSampleRate: 16_000)

        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples[0], 0, accuracy: 0.0001)
    }

    func testKeepsSamplesWhenAlreadyMonoAtTargetRate() {
        let source: [Float] = [0.1, -0.2, 0.3]
        let chunk = AudioChunk(
            samples: source,
            sampleRate: 16_000,
            channelCount: 1,
            averageLevel: 0.2,
            startedAt: .now,
            endedAt: .now
        )

        XCTAssertEqual(
            LocalAudioResampler.monoSamples(from: chunk, targetSampleRate: 16_000),
            source
        )
    }
}
