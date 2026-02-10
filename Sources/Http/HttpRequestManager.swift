//
//  HttpRequestManager.swift
//  Http
//

import Foundation

/// Tracks in-flight requests and dispatches URLSession delegate callbacks to them.
public protocol HttpRequestManager: Sendable {
    func addRequest(_ request: HttpRequest)
    func append(data: Data, to taskIdentifier: Int)
    func complete(taskIdentifier: Int, error: HttpError?)
    func set(responseCode: Int, to taskIdentifier: Int) -> Bool
    func destroy()
}

public final class DefaultHttpRequestManager: NSObject, @unchecked Sendable {
    private let requests = HttpRequestList()
    private let authChallengeHandler: (any HttpAuthChallengeHandler)?

    public init(authChallengeHandler: (any HttpAuthChallengeHandler)? = nil) {
        self.authChallengeHandler = authChallengeHandler
    }
}

// MARK: - URLSessionTaskDelegate
extension DefaultHttpRequestManager: URLSessionTaskDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let handler = authChallengeHandler {
            handler.handle(session: session, task: task, challenge: challenge, completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var httpError: HttpError?
        if let error = error as NSError? {
            switch error.code {
            case HttpCode.requestTimeOut:
                httpError = .requestTimeOut
            case -1005:
                httpError = .networkLost(code: -1005)
            default:
                httpError = .unknown(code: -1, message: error.localizedDescription)
            }
        }
        complete(taskIdentifier: task.taskIdentifier, error: httpError)
    }
}

// MARK: - URLSessionDataDelegate
extension DefaultHttpRequestManager: URLSessionDataDelegate {
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if let urlResponse = response as? HTTPURLResponse {
            _ = set(responseCode: urlResponse.statusCode, to: dataTask.taskIdentifier)
        }
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        append(data: data, to: dataTask.taskIdentifier)
    }
}

// MARK: - HttpRequestManager
extension DefaultHttpRequestManager: HttpRequestManager {
    public func set(responseCode: Int, to taskIdentifier: Int) -> Bool {
        if let request = requests.get(identifier: taskIdentifier) {
            request.setResponse(code: responseCode)
            return true
        }
        return false
    }

    public func complete(taskIdentifier: Int, error: HttpError?) {
        requests.get(identifier: taskIdentifier)?.complete(error: error)
    }

    public func addRequest(_ request: HttpRequest) {
        requests.set(request)
    }

    public func append(data: Data, to taskIdentifier: Int) {
        (requests.get(identifier: taskIdentifier) as? HttpDataReceivingRequest)?.notifyIncomingData(data)
    }

    public func destroy() {
        requests.clear()
    }
}
