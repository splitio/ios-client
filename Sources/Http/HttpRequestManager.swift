//  HttpRequestManager
//  Created by Javier L. Avrudsky on 08/07/2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation
#if !COCOAPODS
import Logging
#endif

///
/// Stores sent requests in a list
/// and updates them by calling corresponding handler
/// when a delegate method from URLTask or URLSession is called
public protocol HttpRequestManager {
    func addRequest(_ request: HttpRequest)
    func append(data: Data, to taskIdentifier: Int)
    func complete(taskIdentifier: Int, error: HttpError?)
    func set(responseCode: Int, to taskIdentifier: Int) -> Bool
    func destroy()
}

public final class DefaultHttpRequestManager: NSObject, @unchecked Sendable {
    private let requests = HttpRequestList()
    private let authenticator: HttpAuthenticator?

    private let pinChecker: TlsPinChecker?

    private let notificationHandler: HttpNotificationHandler?

    public init(authenticator: HttpAuthenticator? = nil,
         pinChecker: TlsPinChecker?,
         notificationHandler: HttpNotificationHandler?) {
        self.authenticator = authenticator
        self.pinChecker = pinChecker
        self.notificationHandler = notificationHandler
    }
}

// MARK: HttpRequestManager - URLSessionTaskDelegate
extension DefaultHttpRequestManager: URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        // If doing certificate pinning and a custom authenticator is implemented
        // the pin checker has priority
        if let pinChecker = self.pinChecker {
            Logger.v("Checking pinned credentials")
            checkPins(pinChecker: pinChecker,
                      session: session,
                      taskId: task.taskIdentifier,
                      challenge: challenge,
                      completionHandler: completionHandler)
            return
        }

        if let authenticator = self.authenticator {
            Logger.v("Triggering external HTTPS authentication handler")
            authenticator.authenticate(session: session,
                                       challenge: challenge,
                                       completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        var httpError: HttpError?
        if let error = error as NSError? {
            Logger.v("HTTP Error: \(error)")
            switch error.code {
            case HttpCode.requestTimeOut:
                httpError = HttpError.requestTimeOut
            case -1005:
                httpError = HttpError.networkLost(code: -1005)
            default:
                httpError = HttpError.unknown(code: -1, message: error.localizedDescription)
            }
        }
        complete(taskIdentifier: task.taskIdentifier, error: httpError)
    }
}

// MARK: URLSessionDataDelegate
extension DefaultHttpRequestManager: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession,
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

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        append(data: data, to: dataTask.taskIdentifier)
    }
}

extension DefaultHttpRequestManager: HttpRequestManager {
    public func set(responseCode: Int, to taskIdentifier: Int) -> Bool {
        if let request = requests.get(identifier: taskIdentifier) {
            request.setResponse(code: responseCode)
            return true
        }
        return false
    }

    public func complete(taskIdentifier: Int, error: HttpError?) {
        if let request = requests.get(identifier: taskIdentifier) {
            request.complete(error: error)
        }
    }

    public func addRequest(_ request: HttpRequest) {
        requests.set(request)
    }

    public func append(data: Data, to taskIdentifier: Int) {
        if let request = requests.get(identifier: taskIdentifier) as? HttpDataReceivingRequest {
            request.notifyIncomingData(data)
        }
    }

    public func destroy() {
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
    func checkPins(pinChecker: TlsPinChecker,
                   session: URLSession,
                   taskId: Int,
                   challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // Validate the server trust using the PinValidator
        var checkResult = pinChecker.check(credential: challenge)
        var finalStatus: CertificatePinningStatus
        
        switch checkResult {
            case .success:
                guard let serverTrust = challenge.protectionSpace.serverTrust else {
                    // This shouldn't happen
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    finalStatus = .failed
                    checkResult = .unavailableServerTrust
                    break
                }
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                finalStatus = .success
            
            case .error, .invalidChain, .credentialNotPinned, .spkiError, .invalidCredential, .invalidParameter, .unavailableServerTrust:
                notificationHandler?.notifyPinningFailure(host: challenge.protectionSpace.host)
                completionHandler(.cancelAuthenticationChallenge, nil)
                finalStatus = .failed

            case .noServerTrustMethod, .noPinsForDomain:
                completionHandler(.performDefaultHandling, nil)
                finalStatus = .defaultHandling
        }
        
        // Finally we trigger the complete-status handler (host, success/fail, reason)
        notificationHandler?.notifyPinningStatus(
            CertificatePinningCompleteStatus(host: challenge.protectionSpace.host,
                                             status: finalStatus,
                                             reason: checkResult.description))
    }
}
