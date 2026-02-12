//
//  HttpRequest.swift
//  Http
//
//  Created by Javier L. Avrudsky on 5/23/18.
//

import Foundation
#if !COCOAPODS
import Logging
#endif

public protocol HttpRequest: Sendable {
    typealias RequestCompletionHandler = (HttpResponse) -> Void
    typealias RequestErrorHandler = (HttpError) -> Void

    var identifier: Int { get }
    var url: URL { get }
    var method: HttpMethod { get }
    var parameters: HttpParameters? { get }
    var headers: HttpHeaders { get }
    var body: Data? { get }
    var responseCode: Int { get }
    var pinnedCredentialFail: Bool { get }

    func send()
    func setResponse(code: Int)
    func notifyIncomingData(_ data: Data)
    func complete(error: HttpError?)
    func notifyPinnedCredentialFail()

}

public protocol HttpDataReceivingRequest {
    func notifyIncomingData(_ data: Data)
}

// MARK: BaseHttpRequest
public class BaseHttpRequest: HttpRequest, @unchecked Sendable {

    public private(set) var responseCode: Int = 1
    public private(set) var url: URL
    public private(set) var body: Data?
    public private(set) var method: HttpMethod
    public private(set) var parameters: HttpParameters?
    public private(set) var headers: HttpHeaders
    private(set) weak var session: HttpSession?
    private(set) var task: HttpTask?
    private(set) var error: Error?
    public private(set) var pinnedCredentialFail: Bool = false

    var requestQueue = DispatchQueue(label: "split-http-base-request", attributes: .concurrent)
    var completionHandler: RequestCompletionHandler?
    var errorHandler: RequestErrorHandler?
    private(set) var urlRequest: URLRequest?

    public var identifier: Int {
        task?.identifier ?? -1
    }

    public init(session: HttpSession, url: URL, method: HttpMethod,
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
            let keys = parameters.order ?? Array(queryItems.keys)
            for key in keys {
                if let value = queryItems[key] {
                    var parsedValue = "\(value)"
                    if let array = value as? [Any] {
                        parsedValue = array.compactMap { "\($0)" }.joined(separator: ",")
                    }
                    finalQueryItems.append(URLQueryItem(name: key, value: parsedValue))
                }
            }

            components?.queryItems = finalQueryItems
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

    public func send() {
        guard let session = self.session else { return }
        requestQueue.sync {
            task = session.startTask(with: self)
        }
    }

    public func setResponse(code: Int) {
        responseCode = code
    }

    public func complete(error: HttpError?) {
        Logger.e("Http Complete method should be implemented")
    }

    public func notifyIncomingData(_ data: Data) {
        Logger.e("Http notifyIncomingData method should be implemented")
    }

    public func notifyPinnedCredentialFail() {
        pinnedCredentialFail = true
    }
}
