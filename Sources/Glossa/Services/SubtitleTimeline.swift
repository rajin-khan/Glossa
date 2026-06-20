import Foundation

struct SubtitleTimelineSnapshot {
    let activeSubtitle: TranscriptSegment?
    let recentSegments: [TranscriptSegment]
}

@MainActor
final class SubtitleTimeline {
    private let maximumHistoryCount: Int
    private let retirementDelay: Duration
    private var activeSubtitle: TranscriptSegment?
    private var recentSegments: [TranscriptSegment] = []
    private var retirementTask: Task<Void, Never>?
    private var changeHandler: (@MainActor (SubtitleTimelineSnapshot) -> Void)?

    init(
        maximumHistoryCount: Int = 12,
        retirementDelay: Duration = .seconds(2.6)
    ) {
        self.maximumHistoryCount = maximumHistoryCount
        self.retirementDelay = retirementDelay
    }

    func setChangeHandler(_ handler: @escaping @MainActor (SubtitleTimelineSnapshot) -> Void) {
        changeHandler = handler
        publish()
    }

    func append(_ segment: TranscriptSegment) {
        retirementTask?.cancel()
        activeSubtitle = segment
        recentSegments.append(segment)

        if recentSegments.count > maximumHistoryCount {
            recentSegments.removeFirst(recentSegments.count - maximumHistoryCount)
        }

        publish()
        retireActiveSubtitle(matching: segment.id)
    }

    func clearActiveSubtitle() {
        retirementTask?.cancel()
        activeSubtitle = nil
        publish()
    }

    func clearAll() {
        retirementTask?.cancel()
        activeSubtitle = nil
        recentSegments.removeAll()
        publish()
    }

    private func retireActiveSubtitle(matching expectedID: UUID) {
        retirementTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: retirementDelay)
            guard !Task.isCancelled, activeSubtitle?.id == expectedID else { return }
            activeSubtitle = nil
            publish()
        }
    }

    private func publish() {
        changeHandler?(
            SubtitleTimelineSnapshot(
                activeSubtitle: activeSubtitle,
                recentSegments: recentSegments
            )
        )
    }
}
