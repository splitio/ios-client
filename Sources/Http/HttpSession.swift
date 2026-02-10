//
//  HttpSession.swift
//  Http
//

import Foundation

/// Abstraction over URLSession for testability.
public protocol HttpSession: AnyObject, Sendable {
    func startTask(with request: HttpRequest) -> HttpTask?
    func finalize()
}

public class DefaultHttpSession: HttpSession, @unchecked Sendable {
    public var urlSession: URLSession

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func startTask(with request: HttpRequest) -> HttpTask? {
        guard let request = request as? BaseHttpRequest else { return nil }
        guard let task = createSessionTask(request: request, body: request.body) else { return nil }
        task.resume()
        return HttpDataTask(sessionTask: task)
    }

    private func createSessionTask(request: BaseHttpRequest, body: Data?) -> URLSessionTask? {
        guard let urlRequest = request.urlRequest else { return nil }
        if request.method.isUpload, let body = body {
            return urlSession.uploadTask(with: urlRequest, from: body)
        }
        return urlSession.dataTask(with: urlRequest)
    }

    public func finalize() {
        urlSession.invalidateAndCancel()
    }
}
