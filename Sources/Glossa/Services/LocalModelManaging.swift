import Foundation

@MainActor
protocol LocalModelManaging: AnyObject {
    func setModelStatusHandler(_ handler: (@MainActor @Sendable (LocalModelStatus) -> Void)?)
    func prepareModel()
}
