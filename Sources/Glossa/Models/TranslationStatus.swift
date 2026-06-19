import Foundation

enum TranslationStatus: Equatable, Sendable {
    case idle
    case preparing(target: String)
    case ready
    case translating(target: String)
    case unavailable(String)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Translation Idle"
        case .preparing(let target):
            "Preparing \(target)"
        case .ready:
            "Apple Translation Ready"
        case .translating(let target):
            "Translating to \(target)"
        case .unavailable(let detail):
            detail
        case .failed(let detail):
            detail
        }
    }
}
