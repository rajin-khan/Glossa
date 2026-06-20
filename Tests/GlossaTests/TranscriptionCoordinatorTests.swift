import XCTest
@testable import Glossa

@MainActor
final class TranscriptionCoordinatorTests: XCTestCase {
    func testForwardsServiceEventsAndModelPreparation() {
        let service = TranscriptionServiceSpy()
        let coordinator = TranscriptionCoordinator(provider: .debug, service: service)
        var receivedEvent: TranscriptionEvent?
        var receivedStatus: TranscriptionStatus?
        var receivedModelStatus: LocalModelStatus?

        coordinator.setTranscriptHandler { receivedEvent = $0 }
        coordinator.setStatusHandler { receivedStatus = $0 }
        coordinator.setModelStatusHandler { receivedModelStatus = $0 }

        XCTAssertEqual(receivedModelStatus, .downloaded(model: "spy"))

        coordinator.prepareModel()
        XCTAssertTrue(service.didPrepareModel)

        service.emitTranscript()
        XCTAssertEqual(receivedEvent?.text, "Hello")
        XCTAssertEqual(receivedEvent?.sourceLanguage, "en")
        XCTAssertEqual(receivedEvent?.isFinal, true)

        service.emitStatus(.ready(provider: "Spy"))
        XCTAssertEqual(receivedStatus, .ready(provider: "Spy"))
    }

    func testReportsUnavailableModelForProviderWithoutLocalModel() {
        let coordinator = TranscriptionCoordinator(
            provider: .debug,
            service: DebugTranscriptionService()
        )
        var receivedModelStatus: LocalModelStatus?

        coordinator.setModelStatusHandler { receivedModelStatus = $0 }
        XCTAssertEqual(receivedModelStatus, .unavailable)

        coordinator.prepareModel()
        XCTAssertEqual(receivedModelStatus, .unavailable)
    }
}

@MainActor
private final class TranscriptionServiceSpy: TranscriptionServing, LocalModelManaging {
    private var transcriptHandler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?
    private var modelStatusHandler: (@MainActor @Sendable (LocalModelStatus) -> Void)?
    private(set) var didPrepareModel = false

    func setTranscriptHandler(_ handler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?) {
        transcriptHandler = handler
    }

    func setStatusHandler(_ handler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?) {
        statusHandler = handler
    }

    func setModelStatusHandler(_ handler: (@MainActor @Sendable (LocalModelStatus) -> Void)?) {
        modelStatusHandler = handler
        handler?(.downloaded(model: "spy"))
    }

    func prepareModel() {
        didPrepareModel = true
    }

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        .ready(provider: "Spy")
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        .receiving(provider: "Spy", chunkCount: 1)
    }

    func stop() -> TranscriptionStatus {
        .stopped
    }

    func emitTranscript() {
        transcriptHandler?(
            TranscriptionEvent(
                text: "Hello",
                sourceLanguage: "en",
                isFinal: true
            )
        )
    }

    func emitStatus(_ status: TranscriptionStatus) {
        statusHandler?(status)
    }
}
