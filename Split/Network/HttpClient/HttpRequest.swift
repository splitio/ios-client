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

protocol HttpDataReceivingRequest {
    func notifyIncomingData(_ data: Data)
}

// MARK: BaseHttpRequest
class BaseHttpRequest: HttpRequest {

    private (set) var responseCode: Int = 1
    private (set) var url: URL
    private (set) var body: Data?
    private (set) var method: HttpMethod
    private (set) var parameters: HttpParameters?
    private (set) var headers: HttpHeaders
    private (set) weak var session: HttpSession?
    private (set) var task: HttpTask?
    private (set) var error: Error?
    var requestQueue = DispatchQueue(label: "split-http-base-request", attributes: .concurrent)
    var completionHandler: RequestCompletionHandler?
    var errorHandler: RequestErrorHandler?
    private (set) var urlRequest: URLRequest?

    var identifier: Int {
        return task?.identifier ?? -1
    }

    init(session: HttpSession, url: URL, method: HttpMethod,
         parameters: HttpParameters? = nil, headers: HttpHeaders?, body: Data? = nil) throws {

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if let parameters = parameters {
            let initialQueryItems = components?.queryItems ?? []
            components?.queryItems?.removeAll()
            var queryItems: [String: Any] = initialQueryItems.reduce(into: [:], { (dict, item) in
                dict[item.name] = item.value
            })

            queryItems.merge(parameters.values) { (current, _) in current }

            var finalQueryItems: [URLQueryItem] = []
            // Use order array, otherwise default order
            let keys = parameters.order ?? Array(parameters.values.keys)
            for key in keys {
                if let value = parameters[key] {
                    var parsedValue = "\(value)"
                    if let array = value as? [Any] {
                        parsedValue = array.compactMap { "\($0)" }.joined(separator: ",")
                    }
                    finalQueryItems.append(URLQueryItem(name: key, value: parsedValue))
                }
            }

            components?.queryItems?.append(contentsOf: finalQueryItems)
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
        guard let session = self.session else { return }
        requestQueue.sync {
            task = session.startTask(with: self)
        }
    }

    func setResponse(code: Int) {
        responseCode = code
    }

    func complete(error: HttpError?) {
        Logger.e("Http Complete method should be implemented")
    }

    func notifyIncomingData(_ data: Data) {
        Logger.e("Http notifyIncomingData method should be implemented")
    }
}
