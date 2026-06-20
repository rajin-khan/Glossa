import XCTest
@testable import Glossa

@MainActor
final class SubtitleTimelineTests: XCTestCase {
    func testHistoryKeepsOnlyTheConfiguredNumberOfLines() {
        let timeline = SubtitleTimeline(maximumHistoryCount: 3)
        var latestSnapshot: SubtitleTimelineSnapshot?
        timeline.setChangeHandler { latestSnapshot = $0 }

        for index in 0..<5 {
            timeline.append(makeSegment(index: index))
        }

        XCTAssertEqual(latestSnapshot?.recentSegments.count, 3)
        XCTAssertEqual(latestSnapshot?.recentSegments.first?.translatedText, "Translation 2")
        XCTAssertEqual(latestSnapshot?.recentSegments.last?.translatedText, "Translation 4")
    }

    func testActiveSubtitleRetiresAfterTheConfiguredDelay() async throws {
        let timeline = SubtitleTimeline(retirementDelay: .milliseconds(20))
        var latestSnapshot: SubtitleTimelineSnapshot?
        timeline.setChangeHandler { latestSnapshot = $0 }

        timeline.append(makeSegment(index: 1))
        XCTAssertNotNil(latestSnapshot?.activeSubtitle)

        try await Task.sleep(for: .milliseconds(45))
        XCTAssertNil(latestSnapshot?.activeSubtitle)
        XCTAssertEqual(latestSnapshot?.recentSegments.count, 1)
    }

    private func makeSegment(index: Int) -> TranscriptSegment {
        TranscriptSegment(
            sourceText: "Source \(index)",
            translatedText: "Translation \(index)",
            sourceLanguage: "Test",
            isFinal: true
        )
    }
}
