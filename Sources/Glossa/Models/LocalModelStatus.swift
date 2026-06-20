import Foundation

enum LocalModelStatus: Equatable, Sendable {
    case notPrepared
    case downloaded(model: String)
    case downloading(progress: Double)
    case loading
    case ready(model: String)
    case unavailable
    case failed(String)

    var label: String {
        switch self {
        case .notPrepared:
            "Not prepared"
        case .downloaded(let model):
            "Downloaded · \(model)"
        case .downloading(let progress):
            "Downloading · \(Int(progress * 100))%"
        case .loading:
            "Loading Core ML model"
        case .ready(let model):
            "Ready · \(model)"
        case .unavailable:
            "Not used by this provider"
        case .failed(let message):
            message
        }
    }

    var progress: Double? {
        if case .downloading(let progress) = self {
            return progress
        }
        return nil
    }

    var canPrepare: Bool {
        switch self {
        case .notPrepared, .downloaded, .failed:
            true
        case .downloading, .loading, .ready, .unavailable:
            false
        }
    }

    var preparationActionTitle: String {
        switch self {
        case .notPrepared:
            "Download Model"
        case .downloaded:
            "Load Model"
        case .failed:
            "Try Again"
        case .downloading, .loading, .ready, .unavailable:
            "Prepare Model"
        }
    }
}
