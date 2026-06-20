import AVFoundation
import XCTest
@testable import Glossa

final class MicrophoneBufferAnalyzerTests: XCTestCase {
    func testCapturesPlanarStereoAsMono() throws {
        let format = try XCTUnwrap(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48_000,
                channels: 2,
                interleaved: false
            )
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2))
        buffer.frameLength = 2
        let channels = try XCTUnwrap(buffer.floatChannelData)
        channels[0][0] = 1
        channels[1][0] = -1
        channels[0][1] = 0.5
        channels[1][1] = 0.25

        let batch = try XCTUnwrap(MicrophoneBufferAnalyzer.capture(from: buffer))

        XCTAssertEqual(batch.channelCount, 1)
        XCTAssertEqual(batch.samples.count, 2)
        XCTAssertEqual(batch.samples[0], 0, accuracy: 0.0001)
        XCTAssertEqual(batch.samples[1], 0.375, accuracy: 0.0001)
    }

    func testCapturesInterleavedStereoAsMono() throws {
        let format = try XCTUnwrap(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48_000,
                channels: 2,
                interleaved: true
            )
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2))
        buffer.frameLength = 2
        let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let interleaved = try XCTUnwrap(audioBuffers[0].mData?.assumingMemoryBound(to: Float.self))
        interleaved[0] = 1
        interleaved[1] = -1
        interleaved[2] = 0.5
        interleaved[3] = 0.25

        let batch = try XCTUnwrap(MicrophoneBufferAnalyzer.capture(from: buffer))

        XCTAssertEqual(batch.channelCount, 1)
        XCTAssertEqual(batch.samples.count, 2)
        XCTAssertEqual(batch.samples[0], 0, accuracy: 0.0001)
        XCTAssertEqual(batch.samples[1], 0.375, accuracy: 0.0001)
    }
}
