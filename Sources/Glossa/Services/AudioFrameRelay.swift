import Foundation

final class AudioFrameRelay: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@MainActor @Sendable (AudioFrame) -> Void)?

    func setHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func emit(_ frame: AudioFrame) {
        lock.lock()
        let handler = handler
        lock.unlock()

        guard let handler else { return }
        Task { @MainActor in
            handler(frame)
        }
    }
}
