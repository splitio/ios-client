//
//  HttpRequestManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

///
/// Stores sent requests in a list
/// and updates them by calling corresponding handler
/// when a delegate method from URLTask or URLSession sis called
protocol HttpRequestManager {
    func addRequest(_ request: HttpRequest)
    func append(data: Data, to taskIdentifier: Int)
    func complete(taskIdentifier: Int, error: HttpError?)
    func set(responseCode: Int, to taskIdentifier: Int) -> Bool
    func destroy()
}

class DefaultHttpRequestManager: NSObject {
    private var requests = HttpRequestList()
    private var authenticator: SplitHttpsAuthenticator?

    private let pinChecker: TlsPinChecker?

    private let notificationHelper: NotificationHelper?

    init(
        authententicator: SplitHttpsAuthenticator? = nil,
        pinChecker: TlsPinChecker?,
        notificationHelper: NotificationHelper?) {
        self.authenticator = authententicator
        self.pinChecker = pinChecker
        self.notificationHelper = notificationHelper
    }
}

// MARK: HttpRequestManager - URLSessionTaskDelegate

extension DefaultHttpRequestManager: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?)
            -> Void) {
        // If doing certificate pinning and a custom authenticator is implemented
        // the pin checker has priority
        if let pinChecker = pinChecker {
            Logger.v("Checking pinned credentials")
            checkPins(
                pinChecker: pinChecker,
                session: session,
                taskId: task.taskIdentifier,
                challenge: challenge,
                completionHandler: completionHandler)
            return
        }

        if let authenticator = authenticator {
            Logger.v("Triggering external HTTPS authentication handler")
            authenticator.authenticate(
                session: session,
                challenge: challenge,
                completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var httpError: HttpError?
        if let error = error as NSError? {
            Logger.v("HTTP Error: \(error)")
            switch error.code {
            case HttpCode.requestTimeOut:
                httpError = HttpError.requestTimeOut
            case -1005:
                httpError = HttpError.clientRelated(code: 400, internalCode: -1)
            default:
                httpError = HttpError.unknown(code: -1, message: error.localizedDescription)
            }
        }
        complete(taskIdentifier: task.taskIdentifier, error: httpError)
    }
}

// MARK: URLSessionDataDelegate

extension DefaultHttpRequestManager: URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let urlResponse = response as? HTTPURLResponse {
            if set(responseCode: urlResponse.statusCode, to: dataTask.taskIdentifier) {
                completionHandler(.allow)
            } else {
                completionHandler(.allow)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        append(data: data, to: dataTask.taskIdentifier)
    }
}

extension DefaultHttpRequestManager: HttpRequestManager {
    func set(responseCode: Int, to taskIdentifier: Int) -> Bool {
        if let request = requests.get(identifier: taskIdentifier) {
            request.setResponse(code: responseCode)
            return true
        }
        return false
    }

    func complete(taskIdentifier: Int, error: HttpError?) {
        if let request = requests.get(identifier: taskIdentifier) {
            request.complete(error: error)
        }
    }

    func addRequest(_ request: HttpRequest) {
        requests.set(request)
    }

    func append(data: Data, to taskIdentifier: Int) {
        if let request = requests.get(identifier: taskIdentifier) as? HttpDataReceivingRequest {
            request.notifyIncomingData(data)
        }
    }

    func destroy() {
        requests.clear()
    }
}

// MARK: Certificate pinning

// Handle certificate pinning result
extension DefaultHttpRequestManager {
    /// Authenticates the session with a URL authentication challenge.
    /// - Parameters:
    ///   - session: The URL session.
    ///   - challenge: The URL authentication challenge.
    ///   - completionHandler: The completion handler to call with the authentication disposition and credential.
    func checkPins(
        pinChecker: TlsPinChecker,
        session: URLSession,
        taskId: Int,
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Validate the server trust using the PinValidator
        let checkResult = pinChecker.check(credential: challenge)
        switch checkResult {
        case .success:
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                // This shouldn't happen
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .credentialNotPinned, .error, .invalidChain, .invalidCredential,
             .invalidParameter, .spkiError, .unavailableServerTrust:
            notificationHelper?.post(
                notification: .pinnedCredentialValidationFail,
                info: challenge.protectionSpace.host as AnyObject)
            completionHandler(.cancelAuthenticationChallenge, nil)

        case .noPinsForDomain, .noServerTrustMethod:
            completionHandler(.performDefaultHandling, nil)
            return
        }
    }
}
