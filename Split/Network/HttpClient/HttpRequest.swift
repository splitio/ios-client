//
//  HttpRequest.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//

import Foundation

protocol HttpRequest {
    typealias RequestCompletionHandler = (HttpResponse) -> Void
    typealias RequestErrorHandler = (HttpError) -> Void

    var identifier: Int { get }
    var url: URL { get set }
    var method: HttpMethod { get set }
    var parameters: HttpParameters? { get set }
    var headers: HttpHeaders { get set }
    var body: Data? { get }
    var responseCode: Int { get }

    func send()
    func setResponse(code: Int)
    func notifyIncomingData(_ data: Data)
    func complete(error: HttpError?)

}

// MARK: BaseHttpRequestWrapper
/// This classes will be renamed too
class BaseHttpRequest: HttpRequest {

    var body: Data?
    private (set) var responseCode: Int = 1
    var url: URL
    var method: HttpMethod
    var parameters: HttpParameters?
    var headers: HttpHeaders
    var session: HttpSessionWrapper
    var task: HttpTask?
    var error: Error?
    var retryTimes: Int = 0
    var requestCompletionHandler: RequestCompletionHandler?
    var requestErrorHandler: RequestErrorHandler?
    var urlRequest: URLRequest?

    var identifier: Int {
        return task?.identifier ?? -1
    }

    init(session: HttpSessionWrapper, url: URL, method: HttpMethod,
         parameters: HttpParameters? = nil, headers: HttpHeaders?, body: Data? = nil) throws {

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let parameters = parameters {
            components?.queryItems = parameters.map { key, value in URLQueryItem(name: key, value: "\(value)")}
        }
        guard let finalUrl = components?.url else {
            throw HttpError.couldNotCreateRequest(message: "Invalid URL")
        }

        // TODO checks this values
        self.url = finalUrl
        self.session = session
        self.parameters = parameters
        self.method = method
        self.headers = headers ?? HttpHeaders()
        self.body = body

        urlRequest = URLRequest(url: finalUrl)
        urlRequest?.httpMethod = method.rawValue
        if let headers = headers {
            for (key, value) in headers {
                urlRequest?.setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    func send() {
        task = session.startTask(with: self)
    }

    func setResponse(code: Int) {
        responseCode = code
    }

    func complete(error: HttpError?) {
        fatalError()
    }

    func notifyIncomingData(_ data: Data) {
        fatalError()
    }
}
