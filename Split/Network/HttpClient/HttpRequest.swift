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
    var url: URL { get }
    var method: HttpMethod { get }
    var parameters: HttpParameters? { get }
    var headers: HttpHeaders { get }
    var body: Data? { get }
    var responseCode: Int { get }

    func send()
    func setResponse(code: Int)
    func notifyIncomingData(_ data: Data)
    func complete(error: HttpError?)

}

// MARK: BaseHttpRequest
class BaseHttpRequest: HttpRequest {

    private (set) var responseCode: Int = 1
    private (set) var url: URL
    private (set) var body: Data?
    private (set) var method: HttpMethod
    private (set) var parameters: HttpParameters?
    private (set) var headers: HttpHeaders
    private (set) var session: HttpSession
    private (set) var task: HttpTask?
    private (set) var error: Error?
    var requestCompletionHandler: RequestCompletionHandler?
    var requestErrorHandler: RequestErrorHandler?
    private (set) var urlRequest: URLRequest?

    var identifier: Int {
        return task?.identifier ?? -1
    }

    init(session: HttpSession, url: URL, method: HttpMethod,
         parameters: HttpParameters? = nil, headers: HttpHeaders?, body: Data? = nil) throws {

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let parameters = parameters {
            components?.queryItems = parameters.map { key, value in URLQueryItem(name: key, value: "\(value)")}
        }
        guard let finalUrl = components?.url else {
            throw HttpError.couldNotCreateRequest(message: "Invalid URL")
        }

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
