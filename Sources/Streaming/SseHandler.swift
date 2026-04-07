import Foundation

public protocol SseHandler: AnyObject {
    func isConnectionConfirmed(message: [String: String]) -> Bool
    func handleIncomingMessage(message: [String: String])
    func reportError(isRetryable: Bool)
}
