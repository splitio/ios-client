//
//  HttpRequest.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//

import Foundation

// MARK: HttpDataRequest

protocol HttpRequest {

    typealias RequestCompletionHandler = () -> Void
    var identifier: Int { get }
    var url: URL { get set }
    var method: HttpMethod { get set }
    var parameters: HttpParameters? { get set }
    var headers: HttpHeaders { get set }
    var response: HTTPURLResponse? { get }
    var retryTimes: Int { get set }

    func setResponse(_ response: HTTPURLResponse)
    func send()
    func retry()
    func complete(withError error: Error?)
}

protocol HttpStreamRequestProtocol {
    var inputStream: InputStream? { get }
    func appendData(_ newData: Data)
}

class BaseHttpRequest: HttpRequest {

    var session: HttpSession
    var task: URLSessionTask?
    var request: URLRequest?
    var response: HTTPURLResponse?
    var error: Error?
    var retryTimes: Int = 0

//    var url: URL
//    var method: HttpMethod
    var parameters: HttpParameters?
//    var headers: HttpHeaders = [:]

    var requestCompletionHandler: RequestCompletionHandler?

    var identifier: Int {
        return task?.taskIdentifier ?? -1
    }

    init(session: HttpSession, url: URL, method: HttpMethod,
         parameters: HttpParameters? = nil, headers: HttpHeaders?) {
        self.session = session
        self.parameters = parameters
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    func send() {
        assertionFailure("Method not implemented")
    }

    func retry() {
        assertionFailure("Method not implemented")
    }

    func setResponse(_ response: HTTPURLResponse) {
        self.response = response
    }

    func complete(withError error: Error?) {
        self.error = error
        if let completionHandler = requestCompletionHandler {
            completionHandler()
        }
    }
}
