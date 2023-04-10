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

    init(authententicator: SplitHttpsAuthenticator? = nil) {
        self.authenticator = authententicator
    }
}

// MARK: HttpRequestManager - URLSessionTaskDelegate
extension DefaultHttpRequestManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        var httpError: HttpError?
        if let error = error as NSError? {
            switch error.code {
            case HttpCode.requestTimeOut:
                httpError = HttpError.requestTimeOut
            default:
                httpError = HttpError.unknown(code: -1, message: error.localizedDescription)
            }
        }
        complete(taskIdentifier: task.taskIdentifier, error: httpError)
    }
}

// MARK: URLSessionDataDelegate
extension DefaultHttpRequestManager: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
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

// MARK: UrlSessionDelegate
extension DefaultHttpRequestManager: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let authenticator = self.authenticator {
            Logger.v("Triggering external HTTPS authentication handler")
            authenticator.authenticate(session: session,
                                       challenge: challenge,
                                       completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
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
